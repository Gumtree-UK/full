/**
    Targeting Configurator with flex implementation
    In Product Search, where all the Line item information can be entered through different tabs, 
    a new tab that contains the new “Targeting Configurator”. 
**/
global with sharing class ContentStructure {
    public String fromId {get; set;}
    public String targetId { get; set;}
    public String sessionId { get; set;}
    public String checkedNodes { get; set;}
    public String reopenedNodes { get;set;}
    
    //SP. 30-Sep-2011
    public String availableId   {get;set;}
    
    
    //Load all content to make reopened tree 
    private Map<String,Content__c> mContentOrg;
    
    public String lineItemId {get;set;}
    
    public ContentStructure (){
        availableId = '';
        lineItemId = ApexPages.currentPage().getParameters().get('lineItemId');
        sessionId = UserInfo.getSessionId(); 
        fromId = ApexPages.currentPage().getParameters().get('fromId');
        targetId = ApexPages.currentPage().getParameters().get('targetId');
        String productId = ApexPages.currentPage().getParameters().get('proId');
        
        //get available site related to product
        for(Available_Site__c str : [select available_Site__c from Available_Site__c where Product__c =: productId]){
            if(str.available_Site__c != null) availableId += '\'' + str.available_Site__c + '\',';
        }
        if(availableId != ''){
            availableId = '(' + availableId.substring(0,availableId.length()-1) + ')';
        }
        
        checkedNodes = '';
        reopenedNodes = '';
        Set<String> chkIds = new Set<String>();
        Set<String> sParChk = new Set<String>();
        //case of reopening tree
        if(targetId != ''){
            for( TargetingContentAssociation__c tca: [ Select TargetingContent__c, TargetingContent__r.Site_Content_Category__c From TargetingContentAssociation__c Where Targeting__c = :targetId]){
               
                checkedNodes = checkedNodes + ',' + tca.TargetingContent__c;
                
                chkIds.add(tca.TargetingContent__c);
                
                sParChk.add(tca.TargetingContent__r.Site_Content_Category__c);
            }
            if(!chkIds.isEmpty()){
                
                
                mContentOrg = new Map<String,Content__c>([Select c.Id , c.Site_Content_Category__c  From Content__c c]);
                Set<String> sPath = new Set<String>();
                for(String s : sParChk){
                    retrieveRelativeChecked(s, sPath);
                }
                sParChk.addAll(sPath);
                for(String s : sParChk){
                    reopenedNodes = reopenedNodes + '\''+ s +'\','; 
                }
                if(reopenedNodes != ''){
                    reopenedNodes = '(' + reopenedNodes.substring(0,reopenedNodes.length()-1) + ')';
                }
            }
        }
    }
    
    
    //return set storing id of node startFromToTop untill top 
    private void retrieveRelativeChecked(String startFromToTop,Set<String> sPath){
        if(startFromToTop == null) return;
        sPath.add(startFromToTop);
        retrieveRelativeChecked(mContentOrg.get(startFromToTop).Site_Content_Category__c,sPath);
    }
    
    
    
    //set Targeting Text from checked node to leaf
    public static String tarText = '';
    public static void setTarString(String chkid, Map<String,Content__c> mContentChk){
        Content__c content = mContentChk.get(chkid);
        for(Content__c c : mContentChk.values()){
            if(c.Site_Content_Category__c == content.Id){
                tarText = tarText + c.DartName__c +', ';
                setTarString(c.Id, mContentChk);
            }
        }
    }
    
    
    //assign children of parent to a Set 
    public static Set<String> dartzoneChildren = new Set<String>();
    public static void setNodeChildren(Set<String> sId){
        Set<String> sChild = new Set<String>();
        for(Content__c c : [Select Id From Content__c Where Site_Content_Category__c In: sId]){
            dartzoneChildren.add(c.Id);
            sChild.add(c.Id);
        }
        if(!sChild.isEmpty()) setNodeChildren(sChild);
    }
    
    //webService save all checked nodes gathering from flex tree 
    webService static String apexSaveHandler(String sChecked, String sGrayed , String topIds , String targetId, String lineItemId){
        String DART_ZONE_TYPE = 'Dart - Zone';
        Set<String> sChk = new Set<String>(sChecked.split(','));
        Set<String> sGry = new Set<String>(sGrayed.split(','));
        Set<String> sTopIds = new Set<String>(topIds.split(','));
        Map<String,Content__c> mContent = new Map<String,Content__c>();
        Set<String> sdartzone = new Set<String>();
                
        //Connect Targeting__c to the line item by putting the id in the lookup field "Targeting__c" in line items.
        if(targetId == ''){
            Targeting__c t = new Targeting__c(TempBinder__c = true, Description__c = 'TargetingTreeProduct');
            insert t;
            targetId = t.Id;
            System.debug('======================================================targetId:' + targetId);
        }       
        
        //Get all content__c checked and grey
        for(Content__c c : [Select Site_Content_Category__c ,DartName__c, Id, Type__c  From Content__c Where Id In :sChk Or Id In :sGry Or Id In :sTopIds]){
            if(c.Type__c == DART_ZONE_TYPE) sdartzone.add(c.Id);
            mContent.put(c.Id, c);
        }
        
        //dartzoneChildren : Get all children of checked content which type = DART - Zone
        setNodeChildren(sdartzone);
        for(Content__c c : [Select Site_Content_Category__c ,DartName__c, Id, Type__c  From Content__c Where Id In :dartzoneChildren]){
            mContent.put(c.Id, c);
        }
        
        //All objects that are checked in the tree have to be related to the targeting record.
        List<TargetingContentAssociation__c> lstored = new List<TargetingContentAssociation__c>();
        
        
        //for deletion of tree nodes changed to unchecked status
        Set<String> assoNotToDelete = new Set<String>();
        
        //for top level nodes
        for(String contentId :sTopIds ){
            if(contentId == '') continue;
            if(sChk.contains(contentId)){
                tarText = tarText+ mContent.get(contentId).DartName__c +', ' ;
                TargetingContentAssociation__c tca = new TargetingContentAssociation__c(Targeting__c = targetId ,TargetingContent__c = contentId , Target_Content_Key__c = targetId + contentId);
                lstored.add(tca);
                assoNotToDelete.add(tca.Target_Content_Key__c);
            }
        }
        
        Set<String> savedChk = new Set<String>();
        //for lower than top level nodes
        for(String chk : sChk){
            Content__c con = mContent.get(chk);
            if(chk == '' || con == null) continue;
            if(sGry.contains(con.Site_Content_Category__c)){
                tarText = tarText+ mContent.get(chk).DartName__c +', ' ;
                if(con.Type__c == DART_ZONE_TYPE ){
                    //Select Underneath incase tree not expands
                    setTarString(con.Id, mContent);
                    System.debug('----------'+tarText);
                }
                if(savedChk.contains(chk)) continue;
                TargetingContentAssociation__c tca = new TargetingContentAssociation__c(Targeting__c = targetId ,TargetingContent__c = chk , Target_Content_Key__c = targetId + chk);
                lstored.add(tca);
                assoNotToDelete.add(tca.Target_Content_Key__c);
                savedChk.add(chk);
            }
        }
        
        //store dart-zone children
        for(String child : dartzoneChildren){
            if(savedChk.contains(child)) continue;
            TargetingContentAssociation__c tca = new TargetingContentAssociation__c(Targeting__c = targetId ,TargetingContent__c = child , Target_Content_Key__c = targetId + child);
            lstored.add(tca);
            assoNotToDelete.add(tca.Target_Content_Key__c);
        }
        
        if(tarText != ''){
            tarText = tarText + '.';
            tarText = tarText.replace(', .','.');
        }
        if(!lstored.isEmpty()){
            upsert lstored Target_Content_Key__c;
        }
        delete [Select Id From TargetingContentAssociation__c Where Targeting__c= :targetId And Target_Content_Key__c Not In :assoNotToDelete ];
        if(lineItemId != ''){
            OpportunityLineItem oppLI = [ Select Targeting__c,Rich_Line_Description__c From OpportunityLineItem Where Id =: lineItemId];
            oppLI.Rich_Line_Description__c = tarText ;
            oppLI.Targeting__c = targetId;
            update oppLI;
        }
        
        return targetId + '#' + tarText;
        
    }
    
    
    public static testmethod void testContentStructure(){
        Content__c c1 = new Content__c(DartName__c = 'Top');
        insert c1;
        Content__c c2 = new Content__c(DartName__c = 'ChildTop', Type__c = 'DART - Zone' ,Site_Content_Category__c= c1.Id);
        insert c2;
        Content__c c3 = new Content__c(DartName__c = 'Child2', Type__c = 'DART - Zone' ,Site_Content_Category__c= c2.Id);
        insert c3;
        
        Targeting__c t = new Targeting__c(Description__c = 'TargetingTreeProduct');
        insert t;
        TargetingContentAssociation__c tca = new TargetingContentAssociation__c(Targeting__c = t.Id, TargetingContent__c = c1.Id,Target_Content_Key__c = t.Id+''+c1.Id);
        insert tca;
        
        Account acc = new Account(Name='Test Account Quote',BillingStreet='12345',BillingCity='Test',Phone='12456796',
                                        BillingCountry='GB',BillingPostalCode='134697', BillingState='test', ShippingStreet='TestShippingStreet', ShippingPostalCode='TestShippingCode', ShippingCity='TestShippingCity', ShippingCountry='TestShippingCountry');        
        insert acc;
        
        Contact con = new Contact(LastName='LastName', Email='email@email.com');
        insert con;
        
        acc.Primary_contact__c = con.id;
        acc.Finance_contact__c = con.id;
        update acc;
      
        Product2 p = new product2(name='Test Product');
        insert p;
        Pricebook2 stdPb = [select Id from Pricebook2 where isStandard=true limit 1];
        
        PricebookEntry pbe = new PricebookEntry(pricebook2id=stdPb.id, product2id=p.id, unitprice=1.0, isActive=true);
        insert pbe;
        
        Opportunity o = new Opportunity(AccountId=acc.Id,name='Test Opportunity', stageName='Open', CloseDate=Date.newInstance(2006,10,10));
        insert o;
        
        OpportunityLineItem oli = new OpportunityLineItem(
            opportunityid           = o.id, 
            pricebookentryid        = pbe.id,
            unitprice               = 1.5, 
            quantity                = 2.0
        );
        insert oli;
        
        Test.startTest();
                 
                String str = '/apex/ContentHierarchyPage?fromId=&targetId='+t.Id ;
                PageReference pageRef = new PageReference(str);
                Test.setCurrentPage(pageRef);
                        ContentStructure contr = new ContentStructure();
                        ContentStructure.apexSaveHandler((c2.Id+','), (c1.Id+','),  (c1.Id+','), t.Id, oli.Id);
             Test.stopTest();   
               
                
        }
}