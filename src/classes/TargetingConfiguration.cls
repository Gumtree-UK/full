public with sharing class TargetingConfiguration {
    public List<DTOItem> listTopLevelKey{get;set;}
    public String selectedKey{get;set;} 
    public Boolean isTakeOverDes{get;set;}
    public String lineDesc{get;set;}
    public String savelstName{get;set;}
    public String saveTargetingJson{get;set;}   
    public List<DTOSaveKeyValue> lstSaveTargeting{get;set;}
    public TargetingConfiguration(){
       targetId = Apexpages.currentPage().getParameters().get('targetId');      
        initKeyValue();
        isTakeOverDes = false;
        isHaveLv2 = false;
        isSaveError = false;
    }
    
    private String siteId;

    
    //for control is tree select or not on page
    private void convertDTOTreItemToJson(){
        jsonObject=   JSON.serialize(lstItem);  
    } 
    
    public String jsonObject{ get;set; }
    public List<DTOItem> lstItem{get;set;}  
    public Boolean isHaveItem{
      get{
        return !lstItem.isEmpty();
      }
      set;
    }
    private void initKeyValue(){
        
        try{
            saveTargetingJson='[]';
            lstItem = new List<DTOItem>();
            convertDTOTreItemToJson();
            lstSaveTargeting = new List<DTOSaveKeyValue>();
            listChildKey = new List<DTOItem>();
            listTopLevelKey = new List<DTOItem>();
            lstLateCri = new List<DTOItem>();
            String proId = Apexpages.currentPage().getParameters().get('proId');
            if( proId== null ){
                ApexPages.Message lastNameMsg = new ApexPages.Message(ApexPages.Severity.Error, 'Invalid product id.');
                ApexPages.addMessage(lastNameMsg);
                return;
            }   
             String oppItemId =  Apexpages.currentPage().getParameters().get('oppItemId'); 
              if(  oppItemId<> null || oppItemId !='' ){                
                 List<OpportunityLineItem> lstOppItem=[Select id,Description From OpportunityLineItem where id=: oppItemId ];
                  if( !lstOppItem.isEmpty() ){
                   lineDesc = lstOppItem.get( 0 ).Description  ;
                  }                  
              }
             
               if(  targetId<> null || targetId !='' ){   
                   Map<String,List<TargetingKeyValueAssociation__c>> mapchildKeys = new Map<String,List<TargetingKeyValueAssociation__c>>();
                   Map<String,TargetingKeyValueAssociation__c> mapParentKeys = new Map<String,TargetingKeyValueAssociation__c>();
                    for( TargetingKeyValueAssociation__c tg:[Select DART_KeyValue__r.Node_ID__c, DART_KeyValue__r.Key__c, DART_KeyValue__r.Key_Value__c, DART_KeyValue__r.Key_Value_Name__c, DART_KeyValue__c From TargetingKeyValueAssociation__c  where Targeting__c=: targetId ]){
                      if( tg.DART_KeyValue__r.Node_ID__c == null ){
                        mapParentKeys.put( tg.DART_KeyValue__c , tg);
                      }else{
                        String key = tg.DART_KeyValue__r.Node_ID__c;
                        if( !mapchildKeys.containskey(key) ){
                          mapchildKeys.put(key, new List<TargetingKeyValueAssociation__c>());
                        }
                        mapchildKeys.get( key ).add(tg);
                      }
                    }
                    Map<String,Set<String>> mapLv2Parents = new Map<String,Set<String>>();
                    for(DART_KeyValue_2__c keylv2:[Select  Id,Node_ID__c From DART_KeyValue_2__c where Node_ID__c In : mapParentKeys.keySet() ]){
                      String key = keylv2.Node_ID__c;
                      if( !mapLv2Parents.containskey(key) ) mapLv2Parents.put(key, new Set<String>());
                      mapLv2Parents.get(key).add( keylv2.id);                      
                    }
                    
                    for(TargetingKeyValueAssociation__c val: mapParentKeys.values() ){
                      String key = val.DART_KeyValue__c;                      
                      DTOItem dto = new DTOItem( val.DART_KeyValue__r.Key_Value_Name__c ,val.DART_KeyValue__c ,val.DART_KeyValue__r.Key__c);                    
                      //case lv1
                      if( mapchildKeys.containskey(key) ){
                        for(TargetingKeyValueAssociation__c childVal : mapchildKeys.get(key)){
                          dto.lstChild.add( new DTOItem( childVal.DART_KeyValue__r.Key_Value_Name__c ,childVal.DART_KeyValue__c ,childVal.DART_KeyValue__r.Key_Value__c) );                        
                        }
                      }
                      //case lv2
                      if( mapLv2Parents.containskey(key) ){
                        for(String childKey : mapLv2Parents.get(key)  ){
                          if( !mapchildKeys.containskey( childKey ) )continue;
                          for(TargetingKeyValueAssociation__c childValLv2 : mapchildKeys.get( childKey )){
                              dto.lstChild.add( new DTOItem( childValLv2.DART_KeyValue__r.Key_Value_Name__c ,childValLv2.DART_KeyValue__c ,childValLv2.DART_KeyValue__r.Key_Value__c) );
                            
                          }
                        }
                      }
                      
                      
                      lstItem.add( dto );
                    }
                    convertDTOTreItemToJson();
               }
             
            List<Product2> lstProduct = [Select site__c,Available_Key_Values__c From Product2 where Available_Key_Values__c<> null and Id =: proId];            
            if( lstProduct.isEmpty() ){
                ApexPages.Message lastNameMsg = new ApexPages.Message(ApexPages.Severity.Error, 'No Key Values available for this product.');
                ApexPages.addMessage(lastNameMsg);
                return;
            }
            
            List<String> lstAvailableKey = lstProduct.get(0).Available_Key_Values__c.split(';');   
            siteId =  lstProduct.get(0).site__c;         
            for(DART_KeyValue_2__c val : [Select Key__c, Id, Key_Value_Name__c From DART_KeyValue_2__c where Node_ID__c=null and Key__c<> null and Name IN : lstAvailableKey  order by Name] ){
                listTopLevelKey.add(new DTOItem( val.Key_Value_Name__c,val.Id,val.Key__c));
            }   
            
            if( targetId <> null || targetId !=''){ 
                for(TargetingKeyValueAssociation__c val:[select id,DART_KeyValue__r.Key_Value__c,DART_KeyValue__r.Key_Value_Name__c from TargetingKeyValueAssociation__c where Targeting__c=:targetId   order by LastModifiedDate DESC limit 5]){
                    lstLateCri.add(new DTOItem(   val.DART_KeyValue__r.Key_Value_Name__c ,val.Id,val.DART_KeyValue__r.Key_Value__c));
                    
                }
            }
            String oppId =  Apexpages.currentPage().getParameters().get('oppId');
            if( oppId == null || oppId =='' ) return;
            List<Opportunity> lstOpp = [Select AccountId From Opportunity where id =:oppId and AccountId <> null  ];
            if( !lstOpp.isEmpty() ){
                String accId = lstOpp.get(0).AccountId;
                Integer i=0;
                for(Saved_KV_Targeting__c val: [Select KV_ID__c,Name, id,KV_string__c  From Saved_KV_Targeting__c where Advertiser__c = : accId and Site__c = :siteId order by createdDate DESC limit 5 ]){
                    lstSaveTargeting.add( new DTOSaveKeyValue( i,val.name, val.id , val.KV_string__c,val.KV_ID__c) );
                    i++;
                }   
                saveTargetingJson = JSON.serialize( lstSaveTargeting );         
            }
                
         }catch(Exception e){
             ApexPages.Message lastNameMsg = new ApexPages.Message(ApexPages.Severity.Error, e.getMessage()+'>>'+e.getStackTraceString());
             ApexPages.addMessage(lastNameMsg);
        }
    }   
    
    public List<DTOItem> lstLateCri{get;set;} 
    public List<DTOItem> listChildKey{get;set;}
    
    public Boolean isHaveLv2{       
        set;
        get;
    }
    //call from page when key value have changed
    public void getChildValue(){
        try{
            isHaveLv2 = false;
            listChildKey = new List<DTOItem>();
            List<DTOItem> lstAllChilds =  new List<DTOItem>();
            if( selectedKey== null || selectedKey=='')return;
            Set<String> setKeyId = new Set<String>();
            for(DART_KeyValue_2__c val : [Select Key_Value__c, Id, Key_Value_Name__c From DART_KeyValue_2__c where Node_ID__c=: selectedKey and Key_Value__c<> null  order by Name] ){
                //listChildKey.add(new DTOItem( val.Key_Value_Name__c ,val.Id,val.Key_Value__c));
                lstAllChilds.add(new DTOItem( val.Key_Value_Name__c ,val.Id,val.Key_Value__c));
                setKeyId.add(val.id);
            }
            Map<String,List<DTOItem>> mapListDtoItem = new Map<String,List<DTOItem>>();
            for(DART_KeyValue_2__c val : [Select Key_Value__c, Id, Key_Value_Name__c,Node_ID__c From DART_KeyValue_2__c where Node_ID__c In: setKeyId and Key_Value__c<> null  order by Node_ID__c,Name] ){
               String key = val.Node_ID__c;
               isHaveLv2 = true;
               if( !mapListDtoItem.containskey(key ) )  mapListDtoItem.put(key, new List<DTOItem>());
               mapListDtoItem.get(Key).add( new DTOItem( val.Key_Value_Name__c ,val.Id,val.Key_Value__c) );
               
            }
             if( !mapListDtoItem.isEmpty() ){
                for(DTOItem dto: lstAllChilds){
                    String key = dto.id;
                    if( mapListDtoItem.containskey( key )){
                        dto.lstChild = mapListDtoItem.get( key );
                    }
                }
             }
           
           //HCS 14.07.2014 
           //Fixed 
           //- IF > 1000 records in a Key then the tree crashes  
            if( !lstAllChilds.isEmpty() ){
            	Integer ITEMS_LIMIT = 100;
            	Integer i =0;
            	Map<Integer,List<DTOItem>> mapAllChilds = new Map<Integer,List<DTOItem>>();
            	for(DTOItem dto: lstAllChilds){
            		if( !mapAllChilds.containskey(i) ) mapAllChilds.put(i, new List<DTOItem>());            		
            		mapAllChilds.get(i).add(dto);
            		if( mapAllChilds.get(i).size() == ITEMS_LIMIT ){
            			i++;
            		}            	 	
            	}
            	
            	for(Integer key: mapAllChilds.keySet()){
            		DTOItem dto = new DTOItem( 'Name'+key ,'Id'+key ,'value'+key);
            		dto.lstChild = mapAllChilds.get(key);
            		listChildKey.add( dto);
            	}
            }
            
         }catch(Exception e){
             ApexPages.Message lastNameMsg = new ApexPages.Message(ApexPages.Severity.Error, e.getMessage()+'>>'+e.getStackTraceString());
             ApexPages.addMessage(lastNameMsg);
        }
        
    }
    public String targetId{get;set;} 
    public Boolean isSaveError{get;set;}
    public void saveRecords(){
        try{
          isSaveError = false;
            String oppId =  Apexpages.currentPage().getParameters().get('oppId');
            String oppItemId =  Apexpages.currentPage().getParameters().get('oppItemId');           
            if( oppId == null  || oppId ==''  ){
                ApexPages.Message lastNameMsg = new ApexPages.Message(ApexPages.Severity.Error, 'Invalid opportunity ');
                ApexPages.addMessage(lastNameMsg);
                return;
            }
            List<Opportunity> lstOpp = [Select AccountId From Opportunity where id =:oppId and AccountId <> null  ];
            if( !lstOpp.isEmpty()){
                //section save new targeting list
                String accId = lstOpp.get(0).AccountId;
                List<Saved_KV_Targeting__c> lstItemToSave = new List<Saved_KV_Targeting__c>();
                List<DTOSaveKeyValue> lstSaveTargetTmp = (List<DTOSaveKeyValue>)JSON.deserialize(saveTargetingJson,List<TargetingConfiguration.DTOSaveKeyValue>.class);
                Set<String> setValidTargeting = new Set<String>();
                for(DTOSaveKeyValue dto :lstSaveTargetTmp ){                    
                    if( dto.id <> null ){
                        setValidTargeting.add(dto.id);
                        continue;
                    }
                    lstItemToSave.add( new Saved_KV_Targeting__c(  name = dto.label , Advertiser__c= accId , KV_string__c = dto.keyVal,KV_ID__c=dto.keyValueId, Site__c = siteId ) );
                }
                if( !lstSaveTargeting.isEmpty()  ){
                    Set<String> setTargetingToDel = new Set<String>();
                    for(DTOSaveKeyValue dto: lstSaveTargeting ){
                        if(dto.id <> null && !setValidTargeting.contains( dto.id )  ){
                            setTargetingToDel.add( dto.id );
                        }
                    }
                    if( !setTargetingToDel.isEmpty() ){
                        delete [select id from Saved_KV_Targeting__c where id In : setTargetingToDel and  Advertiser__c= :accId];                       
                    }
                }
                if( !lstItemToSave.isEmpty() )insert lstItemToSave;
            }       
            
            //save line Description to line Item
            if( isTakeOverDes &&  ( oppItemId<> null || oppItemId !='' )  ){
                List<OpportunityLineItem> lstOppItem=[Select id,Description From OpportunityLineItem where id=: oppItemId ];
                if( !lstOppItem.isEmpty() ){
                  if( lineDesc <> null && lineDesc.length()>255){
                    lineDesc = lineDesc.substring(0, 254);
                  }
                  
                    lstOppItem.get( 0 ).Description = lineDesc;
                    update lstOppItem;
                }
                    
            }
            lstItem = (List<DTOItem>)JSON.deserialize(jsonObject,List<TargetingConfiguration.DTOItem>.class);
            if( !lstItem.isEmpty() ){
                if( targetId == null || targetId==''){           
                    Targeting__c t = new Targeting__c(TempBinder__c = true);
                    insert t;
                    targetId = t.Id;                
                }               
                //All objects that are checked in the tree have to be related to the targeting record.
                List<TargetingKeyValueAssociation__c> lstored = new List<TargetingKeyValueAssociation__c>();            
                //for deletion of tree nodes changed to unchecked status from opp lineitem
                Set<String> assoNotToDelete = new Set<String>();        
                for(DTOItem item: lstItem){
                    String keyValId = item.id;
                    keyValId = keyValId.trim();
                    TargetingKeyValueAssociation__c tca = new TargetingKeyValueAssociation__c(Targeting__c = targetId ,DART_KeyValue__c   = keyValId , Operator__c= 'OR', targetkeyvalue__c = targetId + keyValId );
                    lstored.add(tca);
                     assoNotToDelete.add(tca.targetkeyvalue__c);
                     if( item.lstChild <> null && !item.lstChild.isEmpty() ){
                        for(DTOItem childItem: item.lstChild ){
                            if( childItem.id == null )continue;
                            String childKeyValuId = childItem.id;
                            childKeyValuId = childKeyValuId.trim();
                            TargetingKeyValueAssociation__c tcChild = new TargetingKeyValueAssociation__c(Targeting__c = targetId ,DART_KeyValue__c   = childKeyValuId , Operator__c= 'OR', targetkeyvalue__c = targetId + childKeyValuId );
                            lstored.add(tcChild);
                             assoNotToDelete.add(tcChild.targetkeyvalue__c);
                        }
                     }
                   
                }           
                if(!lstored.isEmpty()){           
                    upsert lstored targetkeyvalue__c;            
                }
                delete [Select Id From TargetingKeyValueAssociation__c Where Targeting__c= :targetId And targetkeyvalue__c Not In :assoNotToDelete ];               
            }       
                    
         }catch(Exception e){
             ApexPages.Message lastNameMsg = new ApexPages.Message(ApexPages.Severity.Error, e.getMessage()+'>>'+e.getStackTraceString());
             ApexPages.addMessage(lastNameMsg);
             isSaveError = true;
        }       
    }
    
   
   
    public class DTOItem{
        public String label{get;set;}
        public String id{get;set;} 
        public String key{get;set;} 
        public List<DTOItem> lstChild{get;set;} 
        public DTOItem (String label,String id,String key ){
            this.id = id;
            this.label = label;
            this.key = key; 
            this.lstChild = new List<DTOItem>();        
        }
        
    }
    
    public class DTOSaveKeyValue{
        public String label{get;set;}
        public String keyVal{get;set;}
        public Integer pos{get;set;}
        public String id{get;set;}
        public String keyValueId{get;set;}
        public DTOSaveKeyValue(Integer pos,String label,String id,String keyVal,String keyValueId){
            this.label = label;
            this.keyVal = keyVal;
            this.pos = pos;
            this.id = id;
            this.keyValueId = keyValueId;
        }
        
    }
    
}