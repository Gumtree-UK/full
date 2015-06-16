/**
 * R #2596: DFP > SFDC Integration - Targeting import (GTCRM-609)
 * Following options,
 * 1) DFP Sync
 * 2) Need to create a button (Update from DFP) on the Opp line item
 * 
 * Change Log: Sochanra Yos - 28-04-2014: Removed TargetingAssociation City/Count and replace 
 *                                       to use with TargetingGeographyAssociation
 * Change log: SUY Sreymol 07/05/2014 : Should able to update the record from DFP into SF records with the same value (e.g. ~value, ~value*, value*).
 *
 * Change Log: Sochanra Yos - 11-06-2014: Adding new TargetingAssociation Device & Connection
 
Change log:
 -2014-08-12 - GTCRM-1213 - Remove copy adops@gumtree.com in to email 
 -2014-12-03   GTCRM-1584-Apex classes with Test Code Coverage below 75%  
 
 Change Log: Bunhor @20-Feb-2015: Move SOQL out of loop, add class TooManyLevelException, and edit 3 recursive methods to throw exception in case 5 levels.
 
 */
global class SyncDFPLineItem {
    // Mapping from its credential to related Line Items, for scheduler would be null
    public Map<String, List<OpportunityLineItem>> mItems = new Map<String, List<OpportunityLineItem>>();
    public SyncDFPLineItem(){}
    
    public void processSync(AdServer_Login__c processingCredential){
    	System.debug('=========================Limits.getQueries() 111=======' + Limits.getQueries());
        //Query DFP Records
        List<DARTObject.IDARTObjectLineItemPage> ldartRecords = requestDFPRecords(processingCredential);
        System.debug('=========================Limits.getQueries() 222=======' + Limits.getQueries());
        system.debug('ldartRecords:>>>>>>>>>>>' + ldartRecords);   
        //All records from DFP
        Map<String, DARTObject.IDARTObjectLineItemPage> mDartObj = new Map<String, DARTObject.IDARTObjectLineItemPage>();
        Map<String, OpportunityLineItem> dfpLineitem = new Map<String, OpportunityLineItem>();
        Map<Decimal, Geography__c> mGeography = new Map<Decimal, Geography__c>();
        Map<String, Content__c> mContent = new Map<String, Content__c>();
        Map<String, DART_KeyValue_2__c> mKeyVal = new Map<String, DART_KeyValue_2__c>();
        Map<Decimal, Connection__c> mConnection = new Map<Decimal, Connection__c>();
        Map<Decimal, Devices__c> mDevice = new Map<Decimal, Devices__c>();
        
        Set<Decimal> dartkeyIds = new Set<Decimal>();
        for(DARTObject.IDARTObjectLineItemPage dartObj : ldartRecords){   
            OpportunityLineItem lineItem = dartObj.getOppLineItem();
            mDartObj.put(lineItem.Ad_Id__c, dartObj);
            dfpLineitem.put(lineItem.Ad_Id__c, lineItem);
            for(TargetingGeographyAssociation__c tarGeography : dartObj.getlTargetingGeographyAssociation())
                mGeography.put(Decimal.valueOf(tarGeography.TargetGeography__c), new Geography__c());
            for(TargetingContentAssociation__c tarContent : dartObj.getlTargetingContentAssociation())
                mContent.put(tarContent.Target_Content_Key__c, new Content__c());
            for(TargetingKeyValueAssociation__c tarKeyVal : dartObj.getlTargetingKeyValueAssociation()){
                mKeyVal.put(tarKeyVal.targetkeyvalue__c, new DART_KeyValue_2__c()); 
                dartkeyIds.add(Decimal.valueOf(tarKeyVal.targetkeyvalue__c));
            } 
            for(TargetingConnectionAssociation__c tarConnection : dartObj.getlTargetingConnectionAssociation())
            {
                mConnection.put(Decimal.valueOf(tarConnection.TargetConnection__c), new Connection__c());
            }
            for(TargetingDeviceAssociation__c tarDevice : dartObj.getlTargetingDeviceAssociation())
            {
                mDevice.put(Decimal.valueOf(tarDevice.TargetDevice__c), new Devices__c());
            }  
                
        }
        System.debug('=========================Limits.getQueries() 333=======' + Limits.getQueries());
        Map<String, DART6_CUSTOMTARGETINGSERVICE.CustomTargetingKey> mKey = new Map<String, DART6_CUSTOMTARGETINGSERVICE.CustomTargetingKey>();
        Map<String, DART6_CUSTOMTARGETINGSERVICE.CustomTargetingValue> mValue = new Map<String, DART6_CUSTOMTARGETINGSERVICE.CustomTargetingValue>();
        requestKeyValueDetails(mKeyVal.keySet(), mKey, mValue, processingCredential);
        
        //Check unmatching ad Id 
        if(mItems.get(processingCredential.Id) != null){
            for(OpportunityLineItem sfLineitem : mItems.get(processingCredential.Id)){
                if(dfpLineitem.containsKey(sfLineitem.Ad_Id__c)) continue;
                mIdError.put(sfLineitem.Id, new ExceptionGroup.DARTException('Ad Id does not match to any DFP LineItems'));
            }
        }
        
        //Loading Countries, Cities, Contents
        String audienceSegId = '';
        Set<String> geoNodeIds = new Set<String>();
        for(Geography__c g : [Select Id, Dart_ID__c, Node_Id__c, Name, Type__c From Geography__c Where Dart_ID__c IN : mGeography.keySet()])
        {
            mGeography.put(g.Dart_ID__c, g);
            if(g.Node_Id__c !=null) geoNodeIds.add(g.Node_Id__c);
        }
        System.debug('=========================Limits.getQueries() 444=======' + Limits.getQueries());
        getNodeGeoParentIds(geoNodeIds, 0);
        existGeoParIds.addAll(geoNodeIds);
        
        for(Content__c c : [Select Id, Name, DartName__c From Content__c Where Name IN: mContent.keySet()]) 
            mContent.put(c.Name, c);
        for(DART_KeyValue_2__c k : [Select Id, Name, Dart6_ValueId__c, Dart6_KeyId__c, Node_ID__r.Name, Key__c, Key_Value_Name__c From DART_KeyValue_2__c Where (ftxt_Dart6_ValueId__c IN: mKeyVal.keySet() OR Dart6_KeyId__c IN: dartkeyIds OR Name =: DART6_KeyValueController.KV_TYPE_AudienceSegment)]){    //Site__c =: processingCredential.Site__c AND 
            if(k.Dart6_ValueId__c != null ) mKeyVal.put(String.valueOf(k.Dart6_ValueId__c), k);
            if(k.Dart6_KeyId__c != null && k.Dart6_ValueId__c == null) mKeyVal.put(String.valueOf(k.Dart6_KeyId__c), k);
            if(k.Name == DART6_KeyValueController.KV_TYPE_AudienceSegment){
                audienceSegId = k.Key__c;
                mKeyVal.put(audienceSegId, k);
            }
        }
        
        Set<String> devNodeIds = new Set<String>();
        Set<String> connNodeIds = new Set<String>();
        
        for(Connection__c c : [Select Id, Dart_ID__c, Node_Id__c, Name, DFP_API_Name__c From Connection__c Where Dart_ID__c IN : mConnection.keySet()])
        {
            mConnection.put(c.Dart_ID__c, c);
            if(c.Node_Id__c !=null) connNodeIds.add(c.Node_Id__c);
        }
        for(Devices__c d : [Select Id, Dart_ID__c, Node_Id__c, Name, DFP_API_Name__c From Devices__c Where Dart_ID__c IN : mDevice.keySet()])
        {
            mDevice.put(d.Dart_ID__c, d);
            if(d.Node_Id__c !=null) devNodeIds.add(d.Node_Id__c);
        } 
        
        System.debug('=========================Limits.getQueries() 555=======' + Limits.getQueries());
        getNodeDeviceParentIds(devNodeIds, 0);
        existDevParIds.addAll(devNodeIds);
        System.debug('=========================Limits.getQueries() 666=======' + Limits.getQueries());
        getNodeConnParentIds(connNodeIds, 0);
        existConParIds.addAll(connNodeIds);

        system.debug('>>>>>> ldartRecords :' + ldartRecords);
        system.debug('>>>>>> mKeyVal :' + mKeyVal);
        system.debug('>>>>>> mKey :' + mKey);
        system.debug('>>>>>> mValue :' + mValue);
        
        createMissingSFKeyValue(ldartRecords, mKeyVal, mKey, mValue, processingCredential, audienceSegId);
        
        //Fix id line item from dfp to sf
        List<OpportunityLineItem> sfLineitem = [Select Ad_Id__c, Targeting__c From OpportunityLineItem Where Ad_Id__c IN: dfpLineitem.keySet()];
        for(OpportunityLineItem lineItem : sfLineitem){
            if(!dfpLineitem.containsKey(lineItem.Ad_Id__c)) continue;
            dfpLineitem.get(lineItem.Ad_Id__c).Id = lineItem.Id;
            dfpLineitem.get(lineItem.Ad_Id__c).Targeting__c = lineItem.Targeting__c;
            successLineItemIds.add(lineItem.Id);
        }
        //Ensure updated record is in salesforce
        for(String lineItemAdId : dfpLineitem.keySet()){
            if(dfpLineitem.get(lineItemAdId).Id == null) dfpLineitem.remove(lineItemAdId);
        }
        
        //Upsert Targeting
        Map<String, Targeting__c> mLineTargetings = new Map<String, Targeting__c>();
        Map<String, Targeting__c> targetingsToUpsert = new Map<String, Targeting__c>();
        for(OpportunityLineItem lineItem : dfpLineitem.values()){
            DARTObject.IDARTObjectLineItemPage dartObj = mDartObj.get(lineItem.Ad_Id__c);
            Targeting__c targeting = dartObj.getTargeting();
            if(lineItem.Targeting__c != null) targeting.Id = lineItem.Targeting__c;
            mLineTargetings.put(lineItem.Ad_Id__c, targeting);
            targetingsToUpsert.put(targeting.Id, targeting);
        }
        upsert targetingsToUpsert.values();
        System.debug('=========================Limits.getQueries() 777=======' + Limits.getQueries());
        Map<String, TargetingContentAssociation__c> dfpTargetContent = new Map<String, TargetingContentAssociation__c>();
        Map<String, TargetingGeographyAssociation__c> dfpTargetGeography = new Map<String, TargetingGeographyAssociation__c>();
        Map<String, TargetingKeyValueAssociation__c> dfpTargetKeyVal = new Map<String, TargetingKeyValueAssociation__c>();
        Map<String, TargetingConnectionAssociation__c> dfpTargetConnection = new Map<String, TargetingConnectionAssociation__c>();
        Map<String, TargetingDeviceAssociation__c> dfpTargetDevice = new Map<String, TargetingDeviceAssociation__c>();
        
        String targetSep = ', ';
        //Update LineItem
        
        // Bunhor @20-Feb-15: move soql from loop. lstGeoParent, lstConParent, and lstDevParent 
        Geography__c[] lstGeoParent = [Select Id, Dart_ID__c, Name, Type__c From Geography__c Where Id IN : existGeoParIds];
        Connection__c[] lstConParent = [Select Id, Dart_ID__c, Name, DFP_API_Name__c From Connection__c Where Id IN : existConParIds];
        Devices__c[] lstDevParent = [Select Id, Dart_ID__c, Name, DFP_API_Name__c From Devices__c Where Id IN : existDevParIds];
        
        for(OpportunityLineItem lineItem : dfpLineitem.values()){
            lineItem.Targeting__c = mLineTargetings.get(lineItem.Ad_Id__c).Id;
            lineItem.Rich_Line_Description__c = '';
            lineItem.Countries_Description__c = '';
            lineItem.City_Description__c = '';
            lineItem.Connection_Targeting__c = '';
            lineItem.Device_Targeting__c = '';
            
            //Update Targeting Options
            DARTObject.IDARTObjectLineItemPage dartObj = mDartObj.get(lineItem.Ad_Id__c);
            
            for(TargetingGeographyAssociation__c tarGeography : dartObj.getlTargetingGeographyAssociation())
            {
                Geography__c geography = mGeography.get(Decimal.valueOf(tarGeography.TargetGeography__c));
                if(geography.Id == null) continue;
                tarGeography.Targeting__c = lineItem.Targeting__c;
                tarGeography.Geography__c = geography.Id;
                tarGeography.TargetGeography__c = tarGeography.Targeting__c + '' + tarGeography.Geography__c;
                tarGeography.Deleted__c = false;
                dfpTargetGeography.put(tarGeography.TargetGeography__c, tarGeography);
                if('COUNTRY'.equals(geography.Type__c)) lineItem.Countries_Description__c += geography.Name + targetSep;
                else lineItem.City_Description__c += geography.Name + targetSep;
            }
            
            // Create Association parent node 
            for(Geography__c geo :lstGeoParent)
            {   
                TargetingGeographyAssociation__c tarGeo = new TargetingGeographyAssociation__c();
                tarGeo.Targeting__c = lineItem.Targeting__c;
                tarGeo.Geography__c = geo.Id;
                tarGeo.TargetGeography__c = lineItem.Targeting__c + '' + geo.Id;
                tarGeo.Deleted__c = false;
                dfpTargetGeography.put(tarGeo.TargetGeography__c, tarGeo);
                if('COUNTRY'.equals(geo.Type__c)) lineItem.Countries_Description__c += geo.Name + targetSep;
                else lineItem.City_Description__c += geo.Name + targetSep; 
            }
            
            for(TargetingContentAssociation__c tarContent : dartObj.getlTargetingContentAssociation()){
                Content__c content = mContent.get(tarContent.Target_Content_Key__c);
                if(content.Id == null) continue;
                tarContent.Targeting__c = lineItem.Targeting__c;
                tarContent.TargetingContent__c = content.Id;
                tarContent.Target_Content_Key__c = tarContent.Targeting__c + '' + tarContent.TargetingContent__c;
                tarContent.Deleted__c = false;
                dfpTargetContent.put(tarContent.Target_Content_Key__c, tarContent);
                lineItem.Rich_Line_Description__c += content.DartName__c + targetSep;
            }
            for(TargetingKeyValueAssociation__c tarKeyVal : dartObj.getlTargetingKeyValueAssociation()){
                DART_KeyValue_2__c keyVal = mKeyVal.get(tarKeyVal.targetkeyvalue__c);
                if(keyVal.Id == null) continue;
                tarKeyVal.Targeting__c = lineItem.Targeting__c;
                tarKeyVal.DART_KeyValue__c = keyVal.Id;
                tarKeyVal.Deleted__c = false;
                tarKeyVal.targetkeyvalue__c = tarKeyVal.Targeting__c + '' + tarKeyVal.DART_KeyValue__c;
                dfpTargetKeyVal.put(tarKeyVal.targetkeyvalue__c, tarKeyVal);
            }
            for(TargetingConnectionAssociation__c tarConn : dartObj.getlTargetingConnectionAssociation())
            {
                Connection__c conn = mConnection.get(Decimal.valueOf(tarConn.TargetConnection__c));
                if(conn.Id == null) continue;
                tarConn.Targeting__c = lineItem.Targeting__c;
                tarConn.Connection__c = conn.Id;
                tarConn.TargetConnection__c = tarConn.Targeting__c + '' + tarConn.Connection__c;
                tarConn.Deleted__c = false;
                dfpTargetConnection.put(tarConn.TargetConnection__c, tarConn);
                lineItem.Connection_Targeting__c += conn.Name + targetSep;
            }

            // Connection parent
            for(Connection__c conn : lstConParent)
            {
                TargetingConnectionAssociation__c tarConn = new TargetingConnectionAssociation__c();
                tarConn.Targeting__c = lineItem.Targeting__c;
                tarConn.Connection__c = conn.Id;
                tarConn.TargetConnection__c = lineItem.Targeting__c + '' + conn.Id;
                tarConn.Deleted__c = false;
                dfpTargetConnection.put(tarConn.TargetConnection__c, tarConn);
                lineItem.Connection_Targeting__c += conn.Name + targetSep;
                
            }
            
            for(TargetingDeviceAssociation__c tarDev : dartObj.getlTargetingDeviceAssociation())
            {
                Devices__c dev = mDevice.get(Decimal.valueOf(tarDev.TargetDevice__c));
                if(dev.id == null) continue;
                tarDev.Targeting__c = lineItem.Targeting__c;
                tarDev.Device__c = dev.Id;
                tarDev.TargetDevice__c = tarDev.Targeting__c + '' + tarDev.Device__c;
                tarDev.Deleted__c = false;
                dfpTargetDevice.put(tarDev.TargetDevice__c, tarDev);
                lineItem.Device_Targeting__c += dev.Name + targetSep;
                
            }
            
            // Device parent
            for(Devices__c dev :lstDevParent)
            {   
                TargetingDeviceAssociation__c tarDev = new TargetingDeviceAssociation__c();
                tarDev.Targeting__c = lineItem.Targeting__c;
                tarDev.Device__c = dev.Id;
                tarDev.TargetDevice__c = lineItem.Targeting__c + '' + dev.Id;
                tarDev.Deleted__c = false;
                dfpTargetDevice.put(tarDev.TargetDevice__c, tarDev);
                lineItem.Device_Targeting__c += dev.Name + targetSep;
            }
            
            if(lineItem.Rich_Line_Description__c != '') lineItem.Rich_Line_Description__c = lineItem.Rich_Line_Description__c.substring(0, lineItem.Rich_Line_Description__c.length() - 2) + '.';
            if(lineItem.City_Description__c != '') lineItem.City_Description__c = lineItem.City_Description__c.substring(0, lineItem.City_Description__c.length() - 2) + '.';
            if(lineItem.Countries_Description__c != '') lineItem.Countries_Description__c = lineItem.Countries_Description__c.substring(0, lineItem.Countries_Description__c.length() - 2) + '.';
            String keyValStr = getKeyValueTargetingString(dartObj.getCustomCriteriaSet(), mKeyVal);
            lineItem.AdKeywords__c = keyValStr;
            lineItem.KeyValueString__c = keyValStr; 
            if(lineItem.Connection_Targeting__c != '') lineItem.Connection_Targeting__c = lineItem.Connection_Targeting__c.substring(0, lineItem.Connection_Targeting__c.length() - 2) + '.';
            if(lineItem.Device_Targeting__c != '') lineItem.Device_Targeting__c = lineItem.Device_Targeting__c.substring(0, lineItem.Device_Targeting__c.length() - 2) + '.';
        }
        System.debug('=========================Limits.getQueries() 888=======' + Limits.getQueries());
        update dfpLineitem.values();
        System.debug('=========================Limits.getQueries() 999=======' + Limits.getQueries()); 
        
        upsert dfpTargetGeography.values() TargetGeography__c;
        upsert dfpTargetContent.values() Target_Content_Key__c;
        upsert dfpTargetKeyVal.values() targetkeyvalue__c;
        upsert dfpTargetConnection.values() TargetConnection__c;
        upsert dfpTargetDevice.values() TargetDevice__c;
        System.debug('=========================Limits.getQueries() 101010=======' + Limits.getQueries());
        
        //Set TargetingXAssociation__c to inactive other than deleting records
        
        List<TargetingGeographyAssociation__c> lInactiveGeographyAss = [Select Id, Deleted__c From TargetingGeographyAssociation__c Where TargetGeography__c NOT IN: dfpTargetGeography.keySet() AND Targeting__c IN: mLineTargetings.values()];
        for(TargetingGeographyAssociation__c tarGeo : lInactiveGeographyAss)
        {
            tarGeo.Deleted__c = true;
        }
        delete lInactiveGeographyAss;
        
        List<TargetingContentAssociation__c> lInactiveContentAss = [Select Id, Deleted__c From TargetingContentAssociation__c Where Target_Content_Key__c NOT IN: dfpTargetContent.keySet() AND Targeting__c IN: mLineTargetings.values()];
        for(TargetingContentAssociation__c tarAss : lInactiveContentAss){
            tarAss.Deleted__c = true;
        }
        delete lInactiveContentAss;
        List<TargetingKeyValueAssociation__c> lInactiveKeyValueAss = [Select Id, Deleted__c From TargetingKeyValueAssociation__c Where targetkeyvalue__c NOT IN: dfpTargetKeyVal.keySet() AND Targeting__c IN: mLineTargetings.values()];
        for(TargetingKeyValueAssociation__c tarAss : lInactiveKeyValueAss){
            tarAss.Deleted__c = true;
        }
        delete lInactiveKeyValueAss;
        
        List<TargetingConnectionAssociation__c> lInactiveConnectionAss = [Select Id, Deleted__c From TargetingConnectionAssociation__c Where TargetConnection__c NOT IN:dfpTargetConnection.keySet() AND Targeting__c IN : mLineTargetings.values()];
        for(TargetingConnectionAssociation__c tarConn : lInactiveConnectionAss)
        {
            tarConn.Deleted__c = true;
        }
        delete lInactiveConnectionAss;
        
        List<TargetingDeviceAssociation__c> lInactiveDeviceAss = [Select Id, Deleted__c From TargetingDeviceAssociation__c Where TargetDevice__c NOT IN:dfpTargetDevice.keySet() AND Targeting__c IN : mLineTargetings.values()];
        for(TargetingDeviceAssociation__c tarDev : lInactiveDeviceAss)
        {
            tarDev.Deleted__c = true;   
        }
        delete lInactiveDeviceAss;
        
        // For debugging
        //String debugText = ldartRecords.size() + '\n----\n';
        //for(DARTObject.IDARTObjectLineItemPage dartObj : ldartRecords){
        //  debugText += dartObj.getOppLineItem() + '\n----\n';
        //  debugText += dartObj.getTargeting() + '\n----\n';
        //  debugText += dartObj.getlTargetingCityAssociation() + '\n----\n';
        //  debugText += dartObj.getlTargetingCountryAssociation() + '\n----\n';
        //  debugText += dartObj.getlTargetingContentAssociation() + '\n----\n';
        //}
        //debugText = '';
        //for(String kess : mKeyVal.keySet()){
        //  debugText += kess + '==' + mKeyVal.get(kess) +  '\n';
        //}
        // insert new Document(Name='TestFull', Body=Blob.valueOf(debugText), FolderId=UserInfo.getUserId());
    }
    
    private void requestKeyValueDetails(Set<String> keyValIds, Map<String, DART6_CUSTOMTARGETINGSERVICE.CustomTargetingKey> mKey,Map<String, DART6_CUSTOMTARGETINGSERVICE.CustomTargetingValue> mValue, AdServer_Login__c processingCredential){
        if(keyValIds.isEmpty()) return;
     //   String authToken = DARTUtil.getRequestToken(processingCredential.Name);  old version
        String netWorkId = processingCredential.Network_ID__c;
       
        /***
        DART6_CUSTOMTARGETINGSERVICE.Authentication authen = new DART6_CUSTOMTARGETINGSERVICE.Authentication();
        authen.Authentication_Type= DARTUtil.AUTHENTICATION_TYPE;
        authen.token=authToken;
        authen.type_x=DARTUtil.AUTHENTICATION_TYPE;   ***/ //Old Version
        
        String authToken = DARTUtil.getAccessToken(processingCredential); // new version 201411
        
        DART6_CUSTOMTARGETINGSERVICE.SoapRequestHeader header = new DART6_CUSTOMTARGETINGSERVICE.SoapRequestHeader();      
        header.applicationName='CustomTargetingService';
        header.networkCode= netWorkId;
       // header.authentication = authen;
       
        Map<String,String> inputHttpHeaders_x = new Map<String, String>();     // new version 201411
        inputHttpHeaders_x.put('Authorization', 'Bearer '+authToken);          // new version 201411 
    
        DART6_CUSTOMTARGETINGSERVICE.CustomTargetingServiceInterfacePort customTagetingService = new DART6_CUSTOMTARGETINGSERVICE.CustomTargetingServiceInterfacePort();
        customTagetingService.RequestHeader = header;
        customTagetingService.inputHttpHeaders_x = inputHttpHeaders_x;       // new version 201411
        
        DART6_CUSTOMTARGETINGSERVICE.Statement filterStatementValue = new DART6_CUSTOMTARGETINGSERVICE.Statement();
        filterStatementValue.query = 'WHERE id IN'+DARTUtil.generateIds(keyValIds);
        DART6_CUSTOMTARGETINGSERVICE.CustomTargetingValuePage pageValResult = customTagetingService.getCustomTargetingValuesByStatement(filterStatementValue);
        for(DART6_CUSTOMTARGETINGSERVICE.CustomTargetingValue result: pageValResult.results){
            mValue.put(String.valueOf(result.id), result);
        }
        
        DART6_CUSTOMTARGETINGSERVICE.Statement filterStatementKey = new DART6_CUSTOMTARGETINGSERVICE.Statement();
        filterStatementKey.query = 'WHERE id IN'+DARTUtil.generateIds(keyValIds);
        DART6_CUSTOMTARGETINGSERVICE.CustomTargetingKeyPage pageKeyResult = customTagetingService.getCustomTargetingKeysByStatement(filterStatementKey);
        for(DART6_CUSTOMTARGETINGSERVICE.CustomTargetingKey result: pageKeyResult.results){
            mKey.put(String.valueOf(result.id), result);
        }
    }
    
    Set<String> existDevParIds = new Set<String>();
    private void getNodeDeviceParentIds(Set<String> devIds, Integer level)
    {
    	if(level>=5) throw new TooManyLevelException('==== The Device have more than 5 level. ===='); 
    	
        Set<String> parIds = new Set<String>();
        for(Devices__c d :[Select Id, Name, Node_ID__c From Devices__c where id IN:devIds and Node_ID__c!=null])
        { 
                parIds.add(d.Node_ID__c);
                existDevParIds.add(d.Node_ID__c); 
        }
        if(!parIds.isEmpty()) getNodeDeviceParentIds(parIds, level++);
    }
    
    Set<String> existGeoParIds = new Set<String>();
    private void getNodeGeoParentIds(Set<String> geoIds, Integer level)
    {
    	if(level>=5) throw new TooManyLevelException('==== The Device have more than 5 level. ===='); 
    	
        Set<String> parIds = new Set<String>();
        for(Geography__c g :[Select Id, Node_ID__c From Geography__c where id IN:geoIds and Node_ID__c!=null])
        {    
	        parIds.add(g.Node_ID__c);
	        existGeoParIds.add(g.Node_ID__c);
             
        }
        if(!parIds.isEmpty()) getNodeGeoParentIds(parIds, level++);
    }
    
    Set<String> existConParIds = new Set<String>();
    private void getNodeConnParentIds(Set<String> conIds, Integer level)
    {
    	if(level>=5) throw new TooManyLevelException('==== The Device have more than 5 level. ===='); 
    	
        Set<String> nodeIds = new Set<String>();
        for(Connection__c c :[Select Id, Name, Node_ID__c, Dart_Id__c From Connection__c where Id IN:conIds and Node_ID__c!=null])
        { 
            nodeIds.add(c.Node_ID__c);
            existConParIds.add(c.Node_ID__c); 
        }
        if(!nodeIds.isEmpty())getNodeConnParentIds(nodeIds, level++);
    }
    
    private List<DARTObject.IDARTObjectLineItemPage> requestDFPRecords(AdServer_Login__c processingCredential){
        List<OpportunityLineItem> sfLineitem = mItems.get(processingCredential.Id);
        String filterQuery = 'WHERE ';
        if(sfLineitem == null || sfLineitem.isEmpty()){
            //Create filter for lastModifiedDateTime = today
            Date todayDate = System.today().addDays(-1);
            filterQuery += 'lastModifiedDateTime >= \'' + todayDate.year() + '-' + todayDate.month() + '-' + todayDate.day() + 'T00:00:00\'';
        }else{
            //Create filter for Selected records
            for(OpportunityLineItem lineItem : sfLineitem){
                if(lineItem.Ad_Id__c == null) continue;
                filterQuery += 'id = \'' + lineItem.Ad_Id__c + '\' OR ';
            }
            filterQuery = filterQuery.substring(0, filterQuery.length() - 4);
        }   
        //For Debugging
        //filterQuery = 'WHERE id = \'43297870\'';
        //orderId
        
        //if(test.isRunningTest()){
        //	filterQuery = 'WHERE id = \'43297870\'';
        //}
        
        String dartVersion = processingCredential.RecordType.Name;
        HTTPWrapper.IGenericRequest dartRequest = FactoryDARTRequest.getInstance().createDartLineItemPageRequest(processingCredential, filterQuery);
        DART6Parser.IDartParser dartParser = FactoryParser.getInstance().createLineItemPageParser(dartVersion);
        DARTObject.IDARTConnector dartCon = FactoryConnector.getInstance().createConnector(dartVersion, dartRequest, dartParser);
        dartCon.connect();
        String invokedMethod = dartRequest.getInvokedMethod();          
        return (List<DARTObject.DARTLineItemPage>) dartCon.getDartObjects();
        //return lstReturn;
    }
    
    /**
     * Scheduler calls
     */
    public static void startScheduler(){
        List<AdServer_Login__c> ladLog = [SELECT RecordType.name,Name,Login_URL__c, User_Name__c, Password__c, Network_ID__c, Client_ID__c, Client_Secret__c, Refresh_Token__c, Site__c FROM AdServer_Login__c WHERE  Active__c=true AND isDeleted=false AND Site__r.Country__c = 'UK'];
        if(Test.isRunningTest()){
            ladLog = [SELECT RecordType.name,Name,Login_URL__c, User_Name__c, Password__c, Network_ID__c, Client_ID__c, Client_Secret__c, Refresh_Token__c, Site__c FROM AdServer_Login__c WHERE  Id =: TestDARTCodeCoverage.testDATA.listLogin[1].Id];
        }
        // Execute Batch
        BatchSyncDFPLineItem batch = new BatchSyncDFPLineItem(ladLog);
        Database.executeBatch(batch, 1);
    }
    
    /**
     * Button calls
     */
    public Boolean processMore {get; set;}
    public Boolean errorOccured {get; set;}
    public String infoMsg {get; set;}
    public static final Integer MAX_SERVERS = 1;
    private Integer noProcessedAdLog = 0;
    private List<AdServer_Login__c> ladLog;
    public String opportunityId {get; set;}
    private String adName = '';
    private Boolean returnToOpp = false;
    
    /**
     * Freeze the screen as we do from the delivery import button to ensure the user knows then it is completed
     */
    public PageReference evaluateServerList(){
        opportunityId = Encodingutil.urlDecode(ApexPages.currentPage().getParameters().get('oppId'), 'UTF-8');
        String recIds = Encodingutil.urlDecode(ApexPages.currentPage().getParameters().get('recIds'), 'UTF-8');
        List<String> lineItemIds = recIds != '' ? recIds.split(',') : new List<String>();
        mItems = new Map<String, List<OpportunityLineItem>>();
        ladLog = new List<AdServer_Login__c>();
        List<OpportunityLineItem> lineItems;
        try{
            lineItems = lineItemIds.size() > 0 
                ? [Select Ad_Id__c, Targeting__c, PricebookEntry.Product2.RecordType.Name, PriceBookEntry.Product2.Site__r.Country__c, Id From OpportunityLineItem Where Id IN: lineItemIds AND PriceBookEntry.Product2.Site__r.Country__c = 'UK'] //'IE'
                : [Select Ad_Id__c, Targeting__c, PricebookEntry.Product2.RecordType.Name, PriceBookEntry.Product2.Site__r.Country__c, Id From OpportunityLineItem Where OpportunityId =: opportunityId AND PriceBookEntry.Product2.Site__r.Country__c = 'UK']; //'IE'
            for(OpportunityLineItem item : lineItems){
                if(item.Ad_Id__c == null){
                    mIdError.put(item.Id, new ExceptionGroup.DARTException('Missing Ad Id'));
                    continue;
                }
                AdServer_Login__c credential = DARTUtil.getCredential(item.PricebookEntry.Product2.RecordType.Name,item.PriceBookEntry.Product2.Site__r.Country__c);
                if(!mItems.containsKey(credential.Id)){
                    ladLog.add(credential);
                    mItems.put(credential.Id, new List<OpportunityLineItem>());
                }
                mItems.get(credential.Id).add(item);
            }
            return pollProcessSync();
        }catch(Exception ex){
            for(OpportunityLineItem lineItem : lineItems){
                mIdError.put(lineItem.Id, ex);
            }
            infoMsg = 'Error: ' + ex+'\n'+ex.getStackTraceString();
            returnToOpp = true;
            //stop screen on error put this to execute
            //errorOccured =  true;
        }
        return null;
    }
    
    private List<Id> successLineItemIds = new List<Id>();
    private Map<String, Exception> mIdError = new Map<String, Exception>();
    public final static String TEMPLETE_NAME = 'UpdateLineItemFromDFPTemplate';
    
    /**
     * Alert result on update Button is finished to opp Owner, and adops
     */
    private void alertResult(){
        //This query is matching fields in generateTableLineItemPage()
        List<OpportunityLineItem> lineItems = [Select PriceBookEntry.Product2.Name, Description, Period__c From OpportunityLineItem Where Id IN: successLineItemIds];
        Opportunity opp = [Select Id, Name, Owner.Name, Owner.Email From Opportunity Where id =: opportunityId]; 
        List<EmailTemplate> emailTemplate = [select Id, Subject, HtmlValue, Body from EmailTemplate Where Name=: TEMPLETE_NAME limit 1];
        // Email send to opportunity owner if there is no email template found.
        String htmlBody = 'Dear ' + opp.Owner.Name + 
                          '<br/><br/> There is no EmailTemplate name '+ TEMPLETE_NAME+ 'found.';   
        if(!emailTemplate.isEmpty()){
            // prepare to send email
            htmlBody = emailTemplate.get(0).HtmlValue;
            htmlBody = htmlBody.replace('###', DARTUtil.generateTableLineItemPage(lineItems))
                            .replace('{!opp.Name}', opp.Name)
                            .replace('{!opp.Owner}', opp.Owner.Name+'')
                            .replace('{!opp.Id}', DARTUtil.URL_INSTANCE+'/'+opp.Id)
                            .replace('$$$', DARTUtil.generateTableLineItemPageError(mIdError))
                            .replace('#$',(lineItems.isEmpty()?'There is no Update Request.':''));
        }
        //DARTUtil.sendMail(new List<String>{'yos.sochanra@gmail.com', 'sochanra.yos@gaea-sys.com'}, null, 'Update Targeting Options From DFP', 'Opportunity Owner', htmlBody); 
        //Email send to opportunity owner. Also auto copy adops@gumtree.com in to email
        //DARTUtil.sendMail(new List<String>{opp.Owner.Email}, new List<String>{'adops@gumtree.com'}, 'Update Targeting Options From DFP', 'Gumtree Robot', htmlBody);
        //2014-08-12 - GTCRM-1213 - Remove copy adops@gumtree.com in to email 
        DARTUtil.sendMail(new List<String>{opp.Owner.Email}, new List<String>{'operations@gumtree.com'}, 'Update Targeting Results', 'Gumtree Robot', htmlBody);
    }
    
    /**
     * Polling for multi Servers
     */
    public PageReference pollProcessSync(){
        if(returnToOpp){
            alertResult();
            return new PageReference('/' + opportunityId);
        }
        Integer c = 0;
        AdServer_Login__c credential;
        try{
            while(noProcessedAdLog < ladLog.size()){
                credential = ladLog[noProcessedAdLog];
                adName = credential.Name + ' ';
                processSync(credential);
                noProcessedAdLog++;
                c++;
                if(c == MAX_SERVERS) break;
            }
            processMore = noProcessedAdLog < ladLog.size();
            infoMsg = 'Processing for server(s): ' + adName;
            returnToOpp = !processMore;
        }catch(Exception ex){
            for(OpportunityLineItem lineItem : mItems.get(credential.Id)){
                mIdError.put(lineItem.Id, ex);
            }
            infoMsg = 'Error: ' + ex+'\n'+ex.getStackTraceString();
            returnToOpp = true;
            //errorOccured =  true;
        }
        return null;
    }
    
    /**
     * Response from DFP may not contain in SF, we need to create them in SF
     */
    private void createMissingSFKeyValue(List<DARTObject.IDARTObjectLineItemPage> ldartRecords, Map<String, DART_KeyValue_2__c> mKeyVal, Map<String, DART6_CUSTOMTARGETINGSERVICE.CustomTargetingKey> mKey, Map<String, DART6_CUSTOMTARGETINGSERVICE.CustomTargetingValue> mValue, AdServer_Login__c processingCredential, String audienceSegId){
        Map<String, DART_KeyValue_2__c> lupsertKey = new Map<String, DART_KeyValue_2__c>(); 
        String debugText = '';
        for(DARTObject.IDARTObjectLineItemPage dartItem : ldartRecords){
            DART6_FORECASTSERVICE.CustomCriteriaSet ccs = dartItem.getCustomCriteriaSet();
            if(ccs.children == null) continue;
            for(DART6_FORECASTSERVICE.CustomCriteriaNode node : ccs.children){
                if(node.children == null) continue;
                for(DART6_FORECASTSERVICE.CustomCriteriaNode node2 : node.children){
                    if(node2.keyId != null){ system.debug('>>>>>>> node2.keyId : ' + node2.keyId);
                        //debugText += '!mKeyVal.containsKey(String.valueOf(node2.keyId)) = ' + !mKeyVal.containsKey(String.valueOf(node2.keyId));
                        DART6_CUSTOMTARGETINGSERVICE.CustomTargetingKey dfpKey = mKey.get(String.valueOf(node2.keyId));
                        if(dfpKey == null) continue;
                        //debugText+=dfpKey.type_x; 
                        DART_KeyValue_2__c dartKV = mKeyVal.get(String.valueOf(node2.keyId));
                        if(dartKV.Id == null){
                            dartKV.Name =  DARTUtil.strNotNull(dfpKey.displayName) == '' ? dfpKey.name : dfpKey.displayName;
                            dartKV.Key__c = dfpKey.name;
                            dartKV.Key_Value_Name__c = dfpKey.displayName;
                            dartKV.Active__c = true;
                            dartKV.Dart6_KeyId__c = node2.keyId;
                            dartKV.Key_Value__c = dfpKey.name;
                            dartKV.Site__c = processingCredential.Site__c;
                            dartKV.Key_ValueType_FreeForm__c = 'FREEFORM' == dfpKey.type_x;
                            lupsertKey.put(String.valueOf(node2.keyId), dartKV);
                            mKeyVal.put(String.valueOf(node2.keyId), dartKV);
                        }
                    }
                }
            }
            
        }
        if(!lupsertKey.isEmpty()) upsert lupsertKey.values();
        
        Map<String, DART_KeyValue_2__c> lupsertValue = new Map<String, DART_KeyValue_2__c>();  
        system.debug('>>>>>>>> mValue : '+ mValue);  
        for(DARTObject.IDARTObjectLineItemPage dartItem : ldartRecords){
            DART6_FORECASTSERVICE.CustomCriteriaSet ccs = dartItem.getCustomCriteriaSet();
            if(ccs.children == null) continue; 
            for(DART6_FORECASTSERVICE.CustomCriteriaNode node : ccs.children){
                if(node.children == null) continue;
                for(DART6_FORECASTSERVICE.CustomCriteriaNode node2 : node.children){
                    if(node2.valueIds != null){
                    	system.debug('>>>>>>>> node2.keyId : '+node2.keyId);
                        DART6_CUSTOMTARGETINGSERVICE.CustomTargetingKey dfpKey = mKey.get(String.valueOf(node2.keyId));
                        if(dfpKey == null) continue;
                        if('FREEFORM' == dfpKey.type_x){
                            for(Long valueId : node2.valueIds ){
                            	system.debug('>>>>>>>> valueId : '+valueId);
                                DART6_CUSTOMTARGETINGSERVICE.CustomTargetingValue dfpValue = mValue.get(String.valueOf(valueId));
                                DART_KeyValue_2__c dartKV = mKeyVal.get(String.valueOf(valueId));
                                if(dartKV.Id == null){
                                    dartKV.Name = DARTUtil.strNotNull(dfpValue.displayName) == '' ? dfpValue.name : dfpValue.displayName;
                                    //SUY Sreymol 07/05/2014 : #3207-Should able to update the record from DFP into SF records with the key values that contains the hash strings(e.g: ~values, ~values*, or value*)
                                    //dartKV.Key_Value_Name__c = dfpValue.name;
                                    dartKV.Key_Value_Name__c = DART6_KeyValueController.toUIName('',dfpValue.name,dfpValue.matchType);
                                    //-------------------07/05/2014------------------//
                                    dartKV.Active__c = true;
                                    dartKV.Dart6_ValueId__c = valueId;
                                    dartKV.Key_Value__c = dfpValue.name;
                                    dartKV.Dart6_KeyId__c = node2.keyId;
                                    dartKV.Node_ID__c = mKeyVal.get(String.valueOf(dfpValue.customTargetingKeyId)).Id;
                                    dartKV.Site__c = processingCredential.Site__c;
                                    lupsertValue.put(String.valueOf(valueId), dartKV);
                                    mKeyVal.put(String.valueOf(valueId), dartKV);
                                }
                            }
                        }
                    }
                    /* We don't need create audience segment values
                    if(node2.audienceSegmentIds != null){
                        for(Long audSegId : node2.audienceSegmentIds){
                            DART6_CUSTOMTARGETINGSERVICE.CustomTargetingValue dfpValue = mValue.get(String.valueOf(audSegId));
                            DART_KeyValue_2__c dartKV = mKeyVal.get(String.valueOf(audSegId));
                            dartKV.Name = String.valueOf(audSegId);
                            dartKV.Key_Value_Name__c = String.valueOf(audSegId);
                            //dartKV.Name = dfpValue.displayName;
                            //dartKV.Key_Value_Name__c = dfpValue.Name;
                            dartKV.Active__c = true;
                            dartKV.Dart6_ValueId__c = audSegId;
                            dartKV.Key_Value__c = String.valueOf(audSegId);
                            dartKV.Site__c = processingCredential.Site__c;
                            dartKV.Node_ID__c = mKeyVal.get(audienceSegId).Id;
                            mKeyVal.put(String.valueOf(audSegId), dartKV);
                            lupsertValue.put(String.valueOf(audSegId), dartKV);
                        }
                    }*/
                }
            }
            if(!lupsertValue.isEmpty()) upsert lupsertValue.values();
        }
    }
    
    /**
     * Build keyvalue String based on CustomCriteriaSet
     */
    private String getKeyValueTargetingString(DART6_FORECASTSERVICE.CustomCriteriaSet ccs, Map<String, DART_KeyValue_2__c> mKeyVal){
            String keyValStr = '';
            if(ccs.children == null) return keyValStr;
            String strLvl2 = '';
            for(DART6_FORECASTSERVICE.CustomCriteriaNode node : ccs.children){
                if(node.children == null) continue;
                String strLvl3 = '';
                for(DART6_FORECASTSERVICE.CustomCriteriaNode node2 : node.children){
                    String audKeyVal = '';
                    Integer valueSize = 0;
                    if(node2.valueIds != null){
                        valueSize = node2.valueIds.size();
                        for(Long valueId : node2.valueIds ){
                            audKeyVal += '(' + mKeyVal.get(String.valueOf(node2.keyId)).Key__c + (node2.operator == 'IS' ? '=' : '!=') + mKeyVal.get(String.valueOf(valueId)).Key_Value_Name__c + ') or ';
                        }
                    }
                    if(node2.audienceSegmentIds != null){
                        valueSize = node2.audienceSegmentIds.size();
                        for(Long audSegId : node2.audienceSegmentIds ){
                            audKeyVal += '(' + DART6_KeyValueController.KV_TYPE_AudienceSegment + (node2.operator == 'IS' ? '=' : '!=') + String.valueOf(audSegId)  + ') or ';
                        }
                    }
                    if(audKeyVal != '') audKeyVal = audKeyVal.substring(0, audKeyVal.length() - ' or '.length());
                    strLvl3 += (valueSize > 1 ? '(' + audKeyVal + ')' : audKeyVal ) + (' ' + node.logicalOperator + ' ');
                }
                if(strLvl3 != '') strLvl3 = strLvl3.substring(0, strLvl3.length() - (' ' + node.logicalOperator + ' ').length());
                strLvl2 += (node.children.size() > 1 ? '(' + strLvl3 + ')' :  strLvl3)  + (' ' + ccs.logicalOperator + ' ');
            }
            if(strLvl2 != '') strLvl2 = strLvl2.substring(0, strLvl2.length() - (' ' + ccs.logicalOperator + ' ').length());
            keyValStr = ccs.children.size() > 1 ? '(' + strLvl2 + ')' :  strLvl2;
            return keyValStr;
    }
    
    /** Bunhor @20-Fen-15: Since soql on Geography__c, Connection__c or Devices__c uses recursived method */
    public class TooManyLevelException extends Exception{}
}