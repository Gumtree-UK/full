/**
 Manage Key id and value Id by the keyvalue association.
 - Seach the value in dfp if exist then return with id
 - Create new free-form value in dfp if not exist
 - Save the newly created value id(s) to DART_KeyValue_2__c
 
 NK: 31/1/2013
    DFP format:
     (
        (key1=val1 OR val2) AND (key2=val1 OR val2 OR val3)
        )
        OR <---- SET,first level. must be 'OR'
        (
        (key1=val1) AND (key2=val1) AND (key3=val1 OR val2)
    )----------------^ --------------^  Second level. Must be AND
        
    ((key1=val1 OR val2) AND (key2=val1 OR val2 OR val3)) OR ((key1=val1) AND (key2=val1) AND (key3=val1 OR val2))
    
Change Log : SUY Sreymol 06/05/2014 
		- #3207 - Should able to submit the kw values with the hash strings at the end (e.g. ~value, ~value*, value*)   
    
*/ 
public with sharing class DART6_KeyValueController extends DARTObject.AbstractDARTController{
    //free-form values to be created (predefined-key id provied)
    String token,networkId;
    Map<String,DART6_CUSTOMTARGETINGSERVICE.CustomTargetingValue> mapTobeCreatedValues;
    Map<String,DART6_CUSTOMTARGETINGSERVICE.CustomTargetingValue> mapAllKeyValues;
    
    
    Map<String,DART_KeyValue_2__c> mapAllKeyAudSegs;
     
    
    List<DARTEvaluator.CustomCriteriaSet> listEvalCrit;
    
    //store the object that does not have dart6 valueId; so after created freeform value in dfp, save the dartid back to this object for future use
    Map<String,DART_KeyValue_2__c> mapValueObject2BeUpdated = new Map<String,DART_KeyValue_2__c>();
    Map<String,DART_KeyValue_2__c> mapValueObject2BeCreated = new Map<String,DART_KeyValue_2__c>();
    
    Map<String,String> mapDfpId_Key = new Map<String,String>();//dfpkeyId to keyname
    Set<String> setV = new Set<String>(); //all value names
    
    set<String> setAllValueNotFreeform = new set<String>();
    
    //NK:21/03/2013
    public static final String KV_TYPE_AudienceSegment = 'Audience Segment'; //Audience Segment
    
    private DART6_KeyValueController(String token,String networkId)
    {
        this.token = token;
        this.networkId = networkId;
        
        mapTobeCreatedValues = new Map<String,DART6_CUSTOMTARGETINGSERVICE.CustomTargetingValue>();
        mapAllKeyValues = new Map<String,DART6_CUSTOMTARGETINGSERVICE.CustomTargetingValue>();
        mapAllKeyAudSegs = new Map<String,DART_KeyValue_2__c>();
    }
    
    /** Constructor:
    // @param: targetingId : DartKeyValue2 will be selected from targeting association via this id
    @param: siteAuto	: to make this search deliver only one result we need another identifier (KeyValue only in this product)
    @param: dart5Form   : old dart keyvalue form to be converted to dart6
    @param: token       : google token after login
    @param: networkId   : network id to be processed
    
    */
    public DART6_KeyValueController(String siteAuto, String dart5Form,String token,String networkId)
    {
        this(token,networkId);
        

        try
        {
            if(dart5Form=='')
            {
              listEvalCrit = new List<DARTEvaluator.CustomCriteriaSet>();
              return;
            }
            listEvalCrit =  DARTEvaluator.convertToCritSet( dart5Form ); 
        }catch(Exception ex){throw new ExceptionGroup.DARTKeyValueException('Unsupported or Invalid Keyvalue String format: '+dart5Form);}
        
         // for pure oldform string without targeting Id
        Set<String> setK = new Set<String>();
        
        for(DARTEvaluator.CustomCriteriaSet cs: listEvalCrit)
        {
            for(DARTEvaluator.Condition con: cs.getCriterion())
            {
                setK.add(con.getParameter());
                setV.add(con.getValue());
                
            }
            
        }
        System.debug('>>>>>>>>>>setK:'+setK);
        System.debug('>>>>>>>>>>setV:'+setV);
        
        System.debug('>>>>>>>>>>siteAuto:' + siteAuto);
     
        Map<String,DART_KeyValue_2__c> mapK = new Map<String,DART_KeyValue_2__c>(); //for Key only,key: car 
        Map<String,DART_KeyValue_2__c> mapV = new Map<String,DART_KeyValue_2__c>(); //for Value only,key: car_bmw
        Map<String,DART_KeyValue_2__c> mapKeyNotFreeform = new Map<String,DART_KeyValue_2__c>();
        Map<String,DART_KeyValue_2__c> mapKeyFreeform = new Map<String,DART_KeyValue_2__c>();


        
 		
 		String soql='Select d.Key__c, d.Dart6_KeyId__c, d.Dart6_ValueId__c, d.Key_ValueType_FreeForm__c, d.Key_Value__c, '+
 					'(Select Key__c, Key_Value_Name__c, Dart6_KeyId__c, Key_Value__c, Site__c ,Dart6_ValueId__c, Node_ID__r.Key_ValueType_FreeForm__c From DART_KeyValues_2__r '+
 					' Where Key_Value__c IN:setV) '+
 					' From DART_KeyValue_2__c d Where Key_Value__c IN:setK AND Key_Value__c <>: KV_TYPE_AudienceSegment ';
 		
 		for(DART_KeyValue_2__c kvff : Database.query(soql + ' '))  //AND Site__c=:siteAuto PN: Only one Site for now  //' WHERE Node_ID__r.Key__c IN:setK' AND Node_ID__r.Site_auto__=:siteAuto])
            
 		{
 			
 			// Mapping all child of each parent
 			for(DART_KeyValue_2__c kvChild : kvff.DART_KeyValues_2__r)
 			{
 				//simple kv
	 			String strKeyVal = (kvff.Key__c+'_'+kvChild.Key_Value__c);
	    		mapV.put(strKeyVal,kvChild);  //k: key_value, value to indentify the which value belong to which key. in case same name value in the different key
	    		
	    		
	    		if(kvff.Key_ValueType_FreeForm__c==false)
	            {
	            	mapKeyNotFreeform.put(kvChild.Key_Value__c, kvff);
	            	setAllValueNotFreeform.add(kvChild.Key_Value__c);
	 			}
	 			else
	 			{
	 				mapKeyFreeform.put(kvChild.Key_Value__c, kvff);
	 			}
	 			
	 			
	 			
	    		
 			}
 			
 			mapK.put(kvff.Key__c,kvff); 
            mapDfpId_Key.put(kvff.Dart6_KeyId__c+'',kvff.Key__c); //dfpId -> Keyname
 			
 			
 		}
 		
         //the the sfid and existing dart Id
        for(DART_KeyValue_2__c kv2 : [Select d.Key__c, d.Dart6_KeyId__c, d.Dart6_ValueId__c, d.Key_ValueType_FreeForm__c, d.Key_Value__c,
 							    (Select Key__c, Key_Value_Name__c, Dart6_KeyId__c, Key_Value__c, Dart6_ValueId__c, Node_ID__r.Key_ValueType_FreeForm__c From DART_KeyValues_2__r
 					             Where Key_Value__c IN:setV)
 					             From DART_KeyValue_2__c d Where Key_Value__c IN:setK])
            //WHERE Node_ID__r.Key__c IN:setK AND Key_Value__c IN: setV
            //WHERE Id in (SELECT DARTKeyValue__c From TargetingKeyValueAssociation__c where Targeting__c=:targetingId) //need this?
        {
            //System.debug('>>>>>>>>>>kv2:'+kv2.Id+',-> '+kv2.Node_ID__r.Key__c+'-->'+kv2.Key_Value__c);
            
          
            //TODO: AudienceSegment ?
            // AudiencdSegment => Node_ID__r.Name
           
  			// Mapping all child of each parent (AudienceSegment)
 			for(DART_KeyValue_2__c kvChild : kv2.DART_KeyValues_2__r)
 			{
 				//TODO: AudienceSegment ?
	            //AudiencdSegment => Node_ID__r.Name
	            
	            String strKeyVal = (kv2.Key__c+'_'+kvChild.Key_Value__c).trim();
	      		if(KV_TYPE_AudienceSegment.equals(kv2.Key_Value__c))
	      		{
	      			mapAllKeyAudSegs.put(strKeyVal ,kvChild);
	      		}
 			}
             
        }
        
        //setAllValueNotFreeform
        System.debug('>>>>>>>>>>setAllValueNotFreeform:'+setAllValueNotFreeform);
  		System.debug('>>>>>>>>>>mapKeyFreeform:'+mapKeyFreeform);
  		System.debug('>>>>>>>>>>mapKeyNotFreeform:'+mapKeyNotFreeform);
        System.debug('>>>>>>>>>>listEvalCrit:'+listEvalCrit);
        System.debug('>>>>>>>>>>mapK:'+mapK);
        System.debug('>>>>>>>>>>mapV:'+mapV);
        System.debug('>>>>>>>>>>mapDfpId_Key:'+mapDfpId_Key);
        System.debug('>>>>>>>>>>mapAllKeyAudSegs: ' + mapAllKeyAudSegs);
        
        DARTObject.IValidator kvValidator = new KVValidator(mapK,mapV,mapKeyNotFreeform,setAllValueNotFreeform,mapAllKeyAudSegs); 
        
        //find if value has dart6 id yet - then add to list to create in dfp
        for(DARTEvaluator.CustomCriteriaSet cs: listEvalCrit)
        {
            for(DARTEvaluator.Condition con: cs.getCriterion())
            {
                //for error: may not Possible - just in case
                kvValidator.checkError(con);

                if(!KV_TYPE_AudienceSegment.equals(con.getParameter()))
                { 
	                //error(s) occure NO NEED to process next step, because this will be thrown after finishing loop
	                if(kvValidator.isError())continue;
	                
	                DART6_CUSTOMTARGETINGSERVICE.CustomTargetingValue tmp = new DART6_CUSTOMTARGETINGSERVICE.CustomTargetingValue();
                    
                	tmp.customTargetingKeyId = mapK.get(con.getParameter()).Dart6_KeyId__c.longValue();
                	
                	//SUY Sreymol 06/05/2014 - get matchType to dfp
                	tmp.matchType = findMatchType(con.getParameter(),con.getValue());
                	system.debug('values :>>>>>>>>>> ' + con.getValue());
                	system.debug('tmp.matchType :>>>>>>>>>>>>>> ' + tmp.matchType);
					
					//clear the spcecial char, we use tmp.matchType instead
					tmp.name = con.getValue().replace('~','').replace('*','');
                	//----------06/05/2014 --------------//
                	
	                //no dart6value Id yet, need to create this in dfp
	                if(mapV.get(con.getParameter()+'_'+con.getValue()) != null)
	                { 
		                if(mapV.get(con.getParameter()+'_'+con.getValue()).Dart6_ValueId__c==null)
		                {
		                	
		                    //tmp.name = con.getValue();// SUY Sreymol 06/05/2014 - clear the spcecial char, we use tmp.matchType instead
		                    //tmp.displayName = ?
		                    setV.add(con.getValue()); //for first query
		                    system.debug('setV :>>>>>>>>>>>>>> ' + setV);
		                    mapTobeCreatedValues.put((tmp.customTargetingKeyId+'_'+con.getValue()),tmp); //this will be seding to dfp
		                    
		                    //will save dart6 id back after created in dfp.
		                    //key: DART_KeyValue_2__c.Id, value: DART_KeyValue_2__c
		                    //mapValueObject2BeUpdated.put(mapV.get(tmp.customTargetingKeyId+'_'+con.getValue()).Id,mapV.get(tmp.customTargetingKeyId+'_'+con.getValue()));
		                    
		                    mapValueObject2BeUpdated.put(con.getParameter()+'_'+con.getValue(), mapV.get(con.getParameter()+'_'+con.getValue())); 
		                    
		                }
		                else//dart6value id already existed, no need to create in dfp. so keep it in a map for next step use
		                {
		                    tmp.id = mapV.get(con.getParameter()+'_'+con.getValue()).Dart6_ValueId__c.longValue();
		                    //key = dart6Id_value: 12345665_v11230
		                    mapAllKeyValues.put(mapK.get(con.getParameter()).Key__c+'_'+con.getValue(),tmp); 
		                }
	                }
	                else  // else create new value in dfp & sf
	                {
	                	//System.debug('========value: ' + con.getValue()+'========key: ' + con.getParameter());
	                	if((mapK.get(con.getParameter())).Key_ValueType_FreeForm__c==true && !mapKeyFreeform.containsKey(con.getValue()))
						{
							//System.debug('>>>>>>>>>>>>>>>>>>>>>>>> valueTobeCreateNew: ' + mapKeyFreeform.get(con.getValue()));
							//tmp.name = con.getValue(); // SUY Sreymol 06/05/2014 - clear the spcecial char, we use tmp.matchType instead
		                    //tmp.displayName = ?
		                    setV.add(con.getValue()); //for first query
		                    
		                    mapTobeCreatedValues.put(tmp.customTargetingKeyId+'_'+con.getValue(),tmp); //this will be seding to dfp
		                    
		                    // Create new KeyValue2
		                    
		                    DART_KeyValue_2__c kv2 = new DART_KeyValue_2__c(
		    					Node_ID__c=mapK.get(con.getParameter()).Id,
		    					Name=con.getValue(),
		    					Key_Value__c=con.getValue(),
		    					Key_Value_Name__c=con.getValue(),
		    					Active__c=true
		    				);
		                    
		                    mapValueObject2BeCreated.put(con.getValue(), kv2);
		                    mapAllKeyValues.put(mapK.get(con.getParameter()).Key__c+'_'+con.getValue(),tmp); 
						}
            		}	
                }
            }
        }
        
        //System.debug('>>>>>>>>>>>>>>>>------------- setV: ' + setV);
        System.debug('>>>>>>>>>>mapTobeCreatedValues:'+mapTobeCreatedValues);
        System.debug('>>>>>>>>>>mapValueObject2BeCreated:'+mapValueObject2BeCreated);
        System.debug('>>>>>>>>>>mapAllKeyValues:'+mapAllKeyValues);
        System.debug('>>>>>>>>>>mapValueObject2BeUpdated:'+mapValueObject2BeUpdated);
        if(kvValidator.isError()){throw new ExceptionGroup.DARTKeyValueException('ERROR: '+kvValidator.getListError());}
    }
    
    public Boolean isNeedToCreate()
    {
        return !mapTobeCreatedValues.isEmpty();
    }
    /** send values to create free form value at dart6 */
    public void searchCreateDFPFreeFormValues()
    {      
        DART6_CUSTOMTARGETINGSERVICE.SoapRequestHeader header = new DART6_CUSTOMTARGETINGSERVICE.SoapRequestHeader();
          
        header.applicationName='CustomTargetingService';
        header.networkCode= networkId;
        
        Map<String,String> inputHttpHeaders_x = new Map<String, String>();    //new version 201411
        inputHttpHeaders_x.put('Authorization', 'Bearer '+ token);            //new version 201411 
    
        DART6_CUSTOMTARGETINGSERVICE.CustomTargetingServiceInterfacePort customTagetingService = new DART6_CUSTOMTARGETINGSERVICE.CustomTargetingServiceInterfacePort();
        customTagetingService.RequestHeader = header;
        customTagetingService.inputHttpHeaders_x = inputHttpHeaders_x;
        
        try
        {
            //1)- search in dfp, if values already exist in dfp then get those Ids
            DART6_CUSTOMTARGETINGSERVICE.Statement filterStatement = new DART6_CUSTOMTARGETINGSERVICE.Statement();
            filterStatement.query = 'WHERE customTargetingKeyId IN'+DARTUtil.generateIds(mapDfpId_Key.keySet())+
                                    ' AND name IN'+DARTUtil.generateIds(setV);  
            

            //clear the matchtype char ~ and * :Sreymol 07/05/2014
			filterStatement.query = filterStatement.query.replace('~','').replace('*','');
			//-------07/05/2014---------------//
            System.debug('>>>>>>>>>>filterStatement.query:'+filterStatement.query);
        
            DART6_CUSTOMTARGETINGSERVICE.CustomTargetingValuePage pageResult = customTagetingService.getCustomTargetingValuesByStatement(filterStatement);
            System.debug('>>>>>>>>>>pageResult :'+pageResult.results);
            invokedMethod = 'getCustomTargetingValuesByStatement, ';
            if(pageResult.totalResultSetSize>0)
            {
                //in case value already existed in dfp, but no dfp id in sf
                
                assignDFPIdsToSF(pageResult.results);
                
            }
            //System.debug('>>>>>>>>>>pageResult.results size:'+pageResult.totalResultSetSize+'>>>>'+pageResult.results);
            
            
            
            //2)- create free form value if not yet existed in dfp
            if(!mapTobeCreatedValues.isEmpty())
            {
                DART6_CUSTOMTARGETINGSERVICE.CustomTargetingValue[] values = customTagetingService.createCustomTargetingValues(mapTobeCreatedValues.values());
                invokedMethod += 'createCustomTargetingValues';
                //put all new created value into the main map for KeyValueTargeting construction
                assignDFPIdsToSF(values);
            }
            
            //mapTobeCreatedValues is obsoleted from here
        }
        catch(System.CalloutException cex){
           throw new ExceptionGroup.DARTException(DARTUtil.extractMessage(cex.getMessage()));
        }catch(Exception ex)
        {throw new ExceptionGroup.DARTException('' + ex.getMessage());}
    }
    
    private void assignDFPIdsToSF(DART6_CUSTOMTARGETINGSERVICE.CustomTargetingValue[] values)
    {
        //System.debug('>>>>>>>>>>mapTobeCreatedValues111:'+mapTobeCreatedValues);
        //System.debug('>>>>>>>>>>mapAllKeyValues555555 : '+mapAllKeyValues);
        //System.debug('>>>>>>>>>>mapValueObject2BeUpdated:'+mapValueObject2BeUpdated);
        //System.debug('>>>>>>>>>>mapDfpId_Key:'+mapDfpId_Key);
        
        System.debug('\n\n>>>>>>>>>>222222222222 values:'+values);
        
        for(DART6_CUSTOMTARGETINGSERVICE.CustomTargetingValue valRes: values)
        {
            
            //assign the newly created dfp id of free form value to DART_KeyValue_2__c for future use
            String key = mapDfpId_Key.get(valRes.customTargetingKeyId+'');
            System.debug('>>>>>>>>>>:k:'+key+':valRes>>>'+valRes.name);
            
            // SUY Sreymol 06/05/2014 - to get the name of the Key Value string name that match with the matchType (e.g ~value, value*, ~value*, value)
            //BROAD BROAD_PREFIX PREFIX EXACT
			String uiName = toUIName(key,valRes.name,valRes.matchType);
			//System.debug('>>>>>valRes.name:' + valRes.name + '>>>>> valRes.matchType: ' + valRes.matchType);
            //System.debug('=====>Key_rev : '+valRes.customTargetingKeyId+'_'+uiName+': valRes>>>>' + valRes);
            
            //mapAllKeyValues.put(key+'_'+valRes.name,valRes);
            
            // SUY Sreymol 06/05/2014 
            //mapAllKeyValues.put(key+'_'+valRes.name, valRes); 
            mapAllKeyValues.put((key+'_'+uiName), valRes);
            //---------------06/05/2014----------------//
            
            //if same value found in dfp after query, remove them from the list tobecreated to avoid duplicate
            // when calling createCustomTargetingValues
            // SUY Sreymol 06/05/2014
            //mapTobeCreatedValues.remove(valRes.customTargetingKeyId+'_'+valRes.name); 
            mapTobeCreatedValues.remove(valRes.customTargetingKeyId+'_'+uiName);
            
            /*
            if(mapValueObject2BeCreated.containsKey(valRes.name))
            {
            	mapValueObject2BeCreated.get(valRes.name).Dart6_ValueId__c = valRes.id;
            }
            */
            
            if(mapValueObject2BeCreated.containsKey(uiName))
            {
            	mapValueObject2BeCreated.get(uiName).Dart6_ValueId__c = valRes.id;
            }
            //---------------06/05/2014----------------//
            
            //assign dpf value id to SF if available
            if(!mapValueObject2BeUpdated.containsKey(key+'_'+valRes.name))continue;
            mapValueObject2BeUpdated.get(key+'_'+valRes.name).Dart6_ValueId__c = valRes.id;
        }
        //System.debug('>>>>>>>>>>mapTobeCreatedValues2222:'+mapTobeCreatedValues);
        //System.debug('>>>>>>>>>>mapValueObject2BeCreated:'+mapValueObject2BeCreated);
        //System.debug('>>>>>>>>>>mapAllKeyValues222:'+mapAllKeyValues);
        //System.debug('>>>>>>>>>>mapValueObject2BeUpdated222:'+mapValueObject2BeUpdated);
    }
    
    /**@return a list of CustomCriteriaSet */
    public override List<DARTObject.IDARTGenericObject> getListDart()
    {
        List<DART6_FORECASTSERVICE.CustomCriteriaSet> listCritSet = new List<DART6_FORECASTSERVICE.CustomCriteriaSet>();
            
        for(DARTEvaluator.CustomCriteriaSet cs: listEvalCrit)
        {
            DART6_FORECASTSERVICE.CustomCriteriaSet critSet1 = new DART6_FORECASTSERVICE.CustomCriteriaSet();
            critSet1.logicalOperator = 'AND';   //Second level is always AND
            critSet1.type_x = 'CustomCriteriaSet';  //set 1
            
            DART6_FORECASTSERVICE.CustomCriteriaNode[] childrenN = new List<DART6_FORECASTSERVICE.CustomCriteriaNode>();
            //------***------//
            
            
            
            for(DARTEvaluator.Condition con: cs.getCriterion())
            {
            	if(!KV_TYPE_AudienceSegment.equals(con.getParameter()))
            	{
            		DART6_FORECASTSERVICE.CustomCriteria crit1a = new DART6_FORECASTSERVICE.CustomCriteria();
            		
	                DART6_CUSTOMTARGETINGSERVICE.CustomTargetingValue val = mapAllKeyValues.get(con.getParameter()+'_'+con.getValue());
	                
	                crit1a.keyId = val.customTargetingKeyId; //70630;
	                crit1a.valueIds = new Long[]{val.Id}; //new Long[]{Long.ValueOf('43594068070'),Long.valueOf('43594069630')};
	                crit1a.operator = 'IS';
	                crit1a.type_x = 'CustomCriteria';   //crit 1 of set1
	                childrenN.add(crit1a);
            	}
                else{
                	//childrenAS = new List<DART6_FORECASTSERVICE.AudienceSegmentCriteria>();
	                DART_KeyValue_2__c audSegKey =  mapAllKeyAudSegs.get(con.getParameter()+'_'+con.getValue());
	                DART6_FORECASTSERVICE.AudienceSegmentCriteria ads = new DART6_FORECASTSERVICE.AudienceSegmentCriteria();
	                
	                ads.audienceSegmentIds = new Long[]{Long.valueOf(audSegKey.Dart6_ValueId__c+'')};
	                ads.operator = 'IS';
	                ads.type_x = 'AudienceSegmentCriteria';  //CustomCriteriaNode
					childrenN.add(ads);
                }
            }
            critSet1.children = childrenN; //add to set 1
            listCritSet.add(critSet1);
            
            
        }
        
        if(listCritSet.isEmpty())
        {
            return new List<DART6_FORECASTSERVICE.CustomCriteriaSet>();
        }
        DART6_FORECASTSERVICE.CustomCriteriaSet customCriteriaSet1 = new DART6_FORECASTSERVICE.CustomCriteriaSet();
        customCriteriaSet1.logicalOperator = 'OR';// Top level is always OR. dartObjForecast.getKeyWKV();
        customCriteriaSet1.children = listCritSet;  //list crit set
        //customCriteriaSet1.type_x = 'CustomCriteriaNode';
        
        listDartObjects  = new List<DART6_FORECASTSERVICE.CustomCriteriaSet>{customCriteriaSet1};  

                            
      return listDartObjects;
    } 
    
    
    
    public void createObjectKeyVal()
    {

		insert mapValueObject2BeCreated.values();
    }
    
    public Boolean isCreateNewKv()
    {
    	return !mapValueObject2BeCreated.isEmpty();
    }
    
    public void updateDart6ValueIds()
    {
        
        update mapValueObject2BeUpdated.values();
    }
    
    //SUY Sreymol 6/4/20114 
    //mapMT_Head.get(MT_BROAD)
	public static final String MT_BROAD = 'BROAD'; 	//~myvalue
	public static final String MT_PREFIX = 'PREFIX';//myvalue*
	public static final String MT_EXACT = 'EXACT';	//myvalue
	public static final String MT_BROAD_PREFIX = 'BROAD_PREFIX'; ////~myvalue*
	
	//This change should have only been done for keywords, so all values where yoou add "kw=" as key. It seems to work for all now, so also e.g. for "uz=". Please adjust it to work only for "kw="
		
	public static Map<String,String> mapMT_Head0 = new Map<String,String>{MT_BROAD=>'~',MT_PREFIX=>'',MT_EXACT=>'',MT_BROAD_PREFIX=>'~'};
	public static Map<String,String> mapMT_Tail0 = new Map<String,String>{MT_BROAD=>'',MT_PREFIX=>'*',MT_EXACT=>'',MT_BROAD_PREFIX=>'*'};
	
	public static Map<String,String> mapMT_Head = new Map<String,String>{MT_BROAD=>'~',MT_EXACT=>'',MT_BROAD_PREFIX=>'~'};
	public static Map<String,String> mapMT_Tail = new Map<String,String>{MT_BROAD=>'',MT_EXACT=>'',MT_BROAD_PREFIX=>'*'};
	//
	
	/** UI Name value with special char ~ or * 
		DFP doese not store that char
		enum matchtype BROAD BROAD_PREFIX PREFIX EXACT
	*/
	public static String toUIName(String k,String valName,String matchType)
	{
		/*if('kw'==k)
		{
			return  (mapMT_Head.get(matchType)+valName+mapMT_Tail.get(matchType)); //for key=kv 
		}else*/
			
			return  (mapMT_Head0.get(matchType)+valName+mapMT_Tail0.get(matchType)); //the rest, use old logic
	}
	
	/* Idnentify the MatchType by the value name */
	private String findMatchType(String k,String valName)
	{
		/*if('kw'==k)
		{
			return (valName.startsWith('~') && valName.endsWith('*'))?MT_BROAD_PREFIX:(valName.startsWith('~')?MT_BROAD:valName.endsWith('*')?MT_BROAD_PREFIX:MT_EXACT); //for key=kv 
		}else*/
		
			return (valName.startsWith('~') && valName.endsWith('*'))?MT_BROAD_PREFIX:(valName.startsWith('~')?MT_BROAD:valName.endsWith('*')?MT_PREFIX:MT_EXACT); //the rest, use old logic
		
	 
	}
    
    //-----------------6/4/20114---------------------///
    
    public class KVValidator implements DARTObject.IValidator{
        List<String> listErr;
        
        Set<String> listMissingKeys = new Set<String>();  
        Set<String> listMissingValues = new Set<String>();  
        Set<String> listMissingKeyDart6Id = new Set<String>();  
        set<String> listKeyNotFreeform = new Set<String>();
        set<String> listMissingValIdAdtSeg = new set<String>();
        
        Map<String,DART_KeyValue_2__c> mapK;
        Map<String,DART_KeyValue_2__c> mapV;
        Map<String,DART_KeyValue_2__c> mapKeyNotFreeform;
        Set<String>setAllValueNotFreeform;
        Map<String,DART_KeyValue_2__c> mapAllKeyAudSegs;

        public KVValidator(Map<String,DART_KeyValue_2__c> mapK,Map<String,DART_KeyValue_2__c> mapV, Map<String,DART_KeyValue_2__c> mapKeyNotFreeform,Set<String>setAllValueNotFreeform,Map<String,DART_KeyValue_2__c> mapAllKeyAudSegs)
        {
            this.mapK = mapK;
            this.mapV = mapV;
            this.mapKeyNotFreeform = mapKeyNotFreeform;
            this.setAllValueNotFreeform = setAllValueNotFreeform;
            this.mapAllKeyAudSegs = mapAllKeyAudSegs;
  
            listErr = new List<String>();
        }
        public void checkError(Object o)
        {
            DARTEvaluator.Condition con = (DARTEvaluator.Condition)o;
            
            if(mapK.get(con.getParameter()) !=null)
            {
	            if(!(setAllValueNotFreeform).contains(con.getValue()) && (mapK.get(con.getParameter())).Key_ValueType_FreeForm__c==false) // 
	            {
	                listMissingValues.add(con.getValue());
	                listKeyNotFreeform.add(con.getParameter());
	            }
	            
	            if(mapK.containsKey(con.getParameter()) && mapK.get(con.getParameter()).Dart6_KeyId__c==null && (!DART6_KeyValueController.KV_TYPE_AudienceSegment.equals(con.getParameter())))
	            {
	                listMissingKeyDart6Id.add(con.getParameter());
	            }
            }
            
            if(!mapK.containsKey(con.getParameter()) && (!DART6_KeyValueController.KV_TYPE_AudienceSegment.equals(con.getParameter())))
            { 
                listMissingKeys.add(con.getParameter());
            }
            
            if(mapAllKeyAudSegs.containsKey(con.getParameter()+'_'+con.getValue()) && mapAllKeyAudSegs.get(con.getParameter()+'_'+con.getValue()).Dart6_ValueId__c == null)
            {
            	listMissingValIdAdtSeg.add(con.getValue());
            }
            
        }
        
        
        
        public List<String> getListError()
        {
            if(!listMissingKeys.isEmpty())
            {
                listErr.add('\n\rKey(s) not found in the KeyValue2:'+listMissingKeys);
            }
            if(!listMissingValues.isEmpty())
            {
                listErr.add('\n\rValue(s) not found in KeyValue2:'+listMissingValues+' \n\r And not a free-form value for Key(s):'+listKeyNotFreeform);
            }
            if(!listMissingKeyDart6Id.isEmpty())
            {
                listErr.add('\n\rPredefined DFP Dart6Key Id not found:'+listMissingKeyDart6Id);
            }
            if(!listMissingValIdAdtSeg.isEmpty())
            {
            	listErr.add('\n\rPredefined DFP Dart6Value Id not found in Audience Segment:'+listMissingValIdAdtSeg);
            }
            
            return listErr;
        }
        public Boolean isError()
        {
            return (!listMissingKeys.isEmpty() || !listMissingValues.isEmpty() || !listMissingKeyDart6Id.isEmpty() || !listMissingValIdAdtSeg.isEmpty());
        }
    
    }
    
    static testMethod void testKV()
    {   
        TestDataGenerator testDATA = new TestDataGenerator();
        
        
        
        /* ================================== Test KeyValue Free-Form & Audience Segment================================= */     
        
    	testDATA.createCredential();
        testDATA.createTargetingHierarchy();
        testDATA.createAccount();
        testDATA.createAdvertiser();
		testDATA.createOpp(testDATA.lstAcc.get(0));
		testDATA.createOppTeamMember(testDATA.opp.id);
		testDATA.createNewOppItemsDart(testDATA.opp.id,2,DARTUtil.DART6,testDATA.targetting[0].Id);
		List<OpportunityLineItem> items =testDATA.getOppItem(testDATA.opp.id, new Set<String>{testDATA.lstLineItems.get(0).id});
        testDATA.createTargetingKVHierarchy();
       	Test.startTest();
        
        String token = 'DQAAAIYAAADrtubcdIuc0bz-CksXJh6v';
        String kv = '(((kw=test*) OR (kw=~test)) OR (car=humnner))';//Sreymol 08/05/2014'((car=hummer)) OR ((car=bmw) OR (car=tico) OR (car=vigo) OR (color=red) OR (color=white) OR (Audience Segment=Aud1) OR (Audience Segment=Aud2))';
        String nw = '18823133';
        String siteAuto = items.get(0).PricebookEntry.Product2.Site__r.Id;
        
        DART6_KeyValueController ctrl = new DART6_KeyValueController(siteAuto,kv,token,nw);
        if(ctrl.isNeedToCreate()) 
        {
          ctrl.searchCreateDFPFreeFormValues();
          ctrl.updateDart6ValueIds();
          System.assertEquals(testDATA.keyvalues[1].Dart6_ValueId__c,22222,'dfp value id must be assigned to sf record');
          List<DART6_FORECASTSERVICE.CustomCriteriaSet> listCrit = (List<DART6_FORECASTSERVICE.CustomCriteriaSet>)ctrl.getListDart();
          System.assertEquals(listCrit.size(),1,'1 CustomCriteriaSet for targeting');
          System.assertEquals(listCrit[0].children.size(),3,'3 CustomCriteriaSet expected: (kw=test*) OR (kw=~test) OR (car=humnner)');
	      //System.assertEquals(listCrit[0].children.size(),8,'8 CustomCriteriaSet expected: (car=hummer)  OR  (car=bmw) OR (car=tico) OR (car=vigo) OR (color=red) OR (color=white) OR (Audience Segment=Aud1) OR (Audience Segment=Aud2)');
        }
        
        
        // In case (Key value: Free-form) and no KeyValue in sf & need to created
        if(ctrl.isCreateNewKv())
        {
        	
        	ctrl.createObjectKeyVal();
        	System.assertEquals(testDATA.keyvalues[4].Dart6_ValueId__c,66666,'dfp value id must be assigned to sf record');
        	
        	
        }
        
        String kv2 = '((car=hummer)) OR ((carx=bmw))';
        
        try
        {
            DART6_KeyValueController ctrl2 = new DART6_KeyValueController(siteAuto,kv2,token,nw);
            
        }catch(ExceptionGroup.DARTKeyValueException dex)
        {
            System.assert(dex.getMessage().contains('Key(s) not found'),'Key(s) not found in the TargetingKeyValueAssociations:{carx}');
            System.assert(dex.getMessage().contains('carx'));
        }
         
         //String f9 = '((loc=Aberdeen*) OR (loc=Bath*) OR (loc=Belfast*) OR (loc=Birmingham*)) AND ((pos=bottom) OR (pos=top))';
        //DART6_KeyValueController ctrl3 = new DART6_KeyValueController(tgt,f9,token,nw);
        
        Test.stopTest(); 
        
        
    }   
        
        
        
        /* =================================== Test keyValue2 with TargetingAssociation ====================================
        Test.startTest();
        
        String token = 'DQAAAIYAAADrtubcdIuc0bz-CksXJh6v';
        String kv = '((car=hummer)) OR ((car=bmw))';
        String nw = '18823133';
        String tgt = dataGen.targetting[0].Id;
        DART6_KeyValueController ctrl = new DART6_KeyValueController(tgt,kv,token,nw);
        
        if(ctrl.isNeedToCreate()) 
        {
          ctrl.searchCreateDFPFreeFormValues();
          ctrl.updateDart6ValueIds();
          System.assertEquals(dataGen.keyvalues[1].Dart6_ValueId__c,22222,'dfp value id must be assigned to sf record');
          
          List<DART6_FORECASTSERVICE.CustomCriteriaSet> listCrit = (List<DART6_FORECASTSERVICE.CustomCriteriaSet>)ctrl.getListDart();
          
           System.assertEquals(listCrit.size(),1,'1 CustomCriteriaSet for targeting');
           System.assertEquals(listCrit[0].children.size(),2,'2 CustomCriteriaSet expected: (car=hummer)  OR  (car=bmw)');
        }
        
        String kv2 = '((car=hummer)) OR ((carx=bmw))';
        
        try
        {
            DART6_KeyValueController ctrl2 = new DART6_KeyValueController(tgt,kv2,token,nw);
            
        }catch(ExceptionGroup.DARTKeyValueException dex)
        {
            System.assert(dex.getMessage().contains('Key(s) not found'),'Key(s) not found in the TargetingKeyValueAssociations:{carx}');
            System.assert(dex.getMessage().contains('carx'));
        }
         
         //String f9 = '((loc=Aberdeen*) OR (loc=Bath*) OR (loc=Belfast*) OR (loc=Birmingham*)) AND ((pos=bottom) OR (pos=top))';
        //DART6_KeyValueController ctrl3 = new DART6_KeyValueController(tgt,f9,token,nw);
        
        Test.stopTest();
        
       
    }
    */
    
    /*customTargeting**************************************************************************
                
                DART6_FORECASTSERVICE.CustomCriteriaSet critSet1 = new DART6_FORECASTSERVICE.CustomCriteriaSet();
                critSet1.logicalOperator = 'AND';   //Second level is always AND
                critSet1.type_x = 'CustomCriteriaSet';  //set 1
                
                DART6_FORECASTSERVICE.CustomCriteriaSet critSet2 = new DART6_FORECASTSERVICE.CustomCriteriaSet();
                critSet2.logicalOperator = 'AND'; //Second level is always ANDOR will return error: <message>[CustomTargetingError.INVALID_TARGETING_EXPRESSION @ targeting.customTargeting.targeting.customTargeting; trigger:'OR(CustomTargetingValuePeblAdapter{id=43594115110, key name=carmodel, value name=skoda-yeti, match type=EXACT, status=ACTIVE},CustomTargetingValuePeblAdapter{id=43594115350, key name=carmodel, value name=kia-sportage, match type=EXACT, status=ACTIVE})']</message>
                critSet2.type_x = 'CustomCriteriaSet';  //set 2
                
                DART6_FORECASTSERVICE.CustomCriteria crit1a = new DART6_FORECASTSERVICE.CustomCriteria();
                crit1a.keyId = 70630;
                crit1a.valueIds = new Long[]{Long.ValueOf('43594068070'),Long.valueOf('43594069630')};
                crit1a.operator = 'IS';
                crit1a.type_x = 'CustomCriteria';   //crit 1 of set1
                
                DART6_FORECASTSERVICE.CustomCriteria crit1b = new DART6_FORECASTSERVICE.CustomCriteria();
                crit1b.keyId = 70630;
                crit1b.valueIds = new Long[]{Long.ValueOf('43594111870'),Long.valueOf('43594114750'),Long.valueOf('43594115470'),Long.valueOf('43594115830')};
                crit1b.operator = 'IS';
                crit1b.type_x = 'CustomCriteria';   //crit 2 of set1
                
                critSet1.children = new DART6_FORECASTSERVICE.CustomCriteria[]{crit1a,crit1b}; //add to set 1
                
                //---                           
                DART6_FORECASTSERVICE.CustomCriteria crit2a = new DART6_FORECASTSERVICE.CustomCriteria();
                crit2a.keyId = 71110;
                crit2a.valueIds = new Long[]{Long.ValueOf('43594115110'),Long.valueOf('43594115350')};
                crit2a.operator = 'IS';
                crit2a.type_x = 'CustomCriteria';   //crit 1 of set 2
                
                DART6_FORECASTSERVICE.CustomCriteria crit2b = new DART6_FORECASTSERVICE.CustomCriteria();
                crit2b.keyId = 71110;
                crit2b.valueIds = new Long[]{Long.ValueOf('43594115710'),Long.valueOf('43594116070'),Long.valueOf('43594116430'),Long.valueOf('43594137790')};
                crit2b.operator = 'IS';
                crit2b.type_x = 'CustomCriteria';   //crit 2 of set 2
                
                
                critSet2.children = new DART6_FORECASTSERVICE.CustomCriteria[]{crit2a,crit2b};
                
                
                listDartObjects.add(critSet1); //crit set 1
                listDartObjects.add(critSet2);  //crit seet 2
                
                
                DART6_FORECASTSERVICE.CustomCriteriaSet customCriteriaSet1 = new DART6_FORECASTSERVICE.CustomCriteriaSet();
                customCriteriaSet1.logicalOperator = 'OR';// Top level is always OR. dartObjForecast.getKeyWKV();
                customCriteriaSet1.children = listDartObjects;  //list crit set
                customCriteriaSet1.type_x = 'CustomCriteriaNode';
                
                //end customTargeting************************************************************************** */

}