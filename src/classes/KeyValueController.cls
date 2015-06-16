global with Sharing class KeyValueController {
    public String lineItemId{get;set;}
    public String targetId{get;set;}
    public String sessionId { get; set;}
    public String checkedNodes { get; set;}
    public String fromId {get; set;}
    public String avaiKV {get;set;}
    public String kvString {get;set;}
     
    
    public KeyValueController (){
      avaiKV = '';
        sessionId   = UserInfo.getSessionId();
        lineItemId   = ApexPages.currentPage().getParameters().get('id');
        targetId   = ApexPages.currentPage().getParameters().get('targetId');
        fromId     = ApexPages.currentPage().getParameters().get('fromId');
        avaiKV     = ApexPages.currentPage().getParameters().get('avaiKV');
        kvString   = ApexPages.currentPage().getParameters().get('kvString');
        
        if(avaiKV != null && avaiKV != ''){
        
          String tmp = '';
          for(String str: avaiKV.split(';')){
            tmp += '\'' + str + '\','; 
          }
          tmp = '(' + tmp.substring(0, tmp.length()-1) + ')';
          
          avaiKV = tmp;
        }
        
        checkedNodes=',';
        //System.debug('*********************************************lineItem'+lineItemId);
        //System.debug('*********************************************lineItem'+targetId);
         if(targetId != ''){
            List<TargetingKeyValueAssociation__c> lstkey=[ Select DART_KeyValue__c,Operator__c  From TargetingKeyValueAssociation__c Where Targeting__c = :targetId];
            if(lstkey.size()>0){
              for( TargetingKeyValueAssociation__c tca: lstkey){
                  checkedNodes = checkedNodes + ',' +tca.DART_KeyValue__c+'@'+tca.Operator__c;
              }
            }
         }
    }
     
     webService static String apexSaveHandler(String sChecked,String lineItemId , String targetId,String strValue){
        
        //Connect Targeting__c to the line item by putting the id in the lookup field "Targeting__c" in line items.
        if(targetId == ''){
            Targeting__c t = new Targeting__c(Description__c = 'Tar_LineItemId ' + lineItemId);
            insert t;
            targetId = t.Id;
        }       
        
        /*String keyValue=strValue;    
        Set<String> sChk = new Set<String>(sChecked.split(','));
        // String keyValueString=''; 
        Map<string,string> mchk=new Map<string,string>();
        for(String strchk:sChk){
            String[] setc=strchk.split('&');
           if(setc.size()>=2){
            mchk.put(setc[0],setc[1]);
           }
        }
        Set<String> dartId=mchk.keySet();
        */
        
        //----------- Select Dart keyValue by Keyword --------------
        
        String EXP_GETKEYVALUE = '(\\(.*?=(.*?)\\))';
      String EXP_GETKEY = '(\\((.*?)\\=.*?)\\)';
        
        List<String> lstKeyVals = new List<String>();
        
    Matcher matcherKeyValue = Pattern.compile(EXP_GETKEYVALUE).matcher(strValue);          
    while (matcherKeyValue.find()){
      lstKeyVals.add(matcherKeyValue.group(2));
    }
        
        
        Set<String> kv = new Set<String>();
            
    for(String s: lstKeyVals){
      //kv.add('%' + s + '%');
      kv.add(s);
    }
        
        
        //List<DART_KeyValue_2__c> lstDart = new List<DART_KeyValue_2__c>([select id, Node_ID__c,Node_ID__r.Key__c, Name, Key_Value__c from DART_KeyValue_2__c where Key_Value__c like : kv ]);
    //Map<String, List<DART_KeyValue_2__c>> mapNodeDart = new Map<String, List<DART_KeyValue_2__c>>();
    //List<DART_KeyValue_2__c> dartkey=[Select d.Node_ID__c, d.Key_Value__c, d.Key_Value_Name__c From DART_KeyValue_2__c d Where d.Id In :dartId];
        
        //Map<String,DART_KeyValue_2__c> mDartKey = new Map<String,DART_KeyValue_2__c>();
        
        Map<String, String> mDartKey = new Map<String, String>();
        //List<DART_KeyValue_2__c> dartkey=[Select d.Node_ID__c, d.Key_Value__c, d.Key_Value_Name__c, d.Node_ID__r.Key__c From DART_KeyValue_2__c d Where Key_Value__c like : kv];
        List<DART_KeyValue_2__c> dartkey=[Select d.Node_ID__c, d.Key_Value__c, d.Key_Value_Name__c, d.Node_ID__r.Key__c From DART_KeyValue_2__c d Where Key_Value__c IN : kv];
     
    System.debug('>>>>>>>>>>>>>>>>> dartSize: ' + dartkey.size());
    
        // Mapping key+keyValue and NodeId to get unique record with parent's key and child's KeyValue 
    Map<String,String> mapKeyNodeDartId = new Map<String,String>();
    
    
    //Map<String, List<DART_KeyValue_2__c>> mapNodeDart = new Map<String, List<DART_KeyValue_2__c>>();
    
    Map<String, List<KeyValueDTO>> mapNodeDart = new Map<String, List<KeyValueDTO>>();
    
    List<KeyValueDTO> lstDTO = new List<KeyValueDTO>();
    
    for(DART_KeyValue_2__c d : dartkey){
      if(!mapNodeDart.containsKey(d.Node_ID__c)){
        //mapNodeDart.put(d.Node_ID__c, new List<DART_KeyValue_2__c>());
        mapNodeDart.put(d.Node_ID__c, new List<KeyValueDTO>());
      }
      
      
      //lstDTO.add(dtokey);
      //mapNodeDart.get(d.Node_ID__c).add(d);
      mapNodeDart.get(d.Node_ID__c).add(new KeyValueDTO(d.Id, d.Key_Value__c));
      mapKeyNodeDartId.put(d.Node_ID__r.Key__c+''+d.Key_Value__c, d.Node_ID__c+'');
    } 
    
    system.debug('\n\nmapNodeDart.keySet() = ' + mapNodeDart.keySet() + '\n');
        
        List<String> lstKeys = new List<String>(); 
         
        Matcher matcherKeys= Pattern.compile(EXP_GETKEY).matcher(strValue.replace('((', '('));          
    while (matcherKeys.find()){
      lstKeys.add(matcherKeys.group(2));
    }
        
        
    Integer i=0; 
      
    for(String strTmp : lstKeys){
      String newK = strTmp+lstKeyVals.get(i);
      String nodeId =mapKeyNodeDartId.get(newK);// newK= parentKey+keyvalue of child
        if(mapNodeDart.containsKey(nodeId)){
          //for(DART_KeyValue_2__c d : mapNodeDart.get(nodeId)){
          for(KeyValueDTO d : mapNodeDart.get(nodeId)){
            //if(d.Key_Value__c.contains(lstKeyVals.get(i))){
            if(d.DARTKeyValue.contains(lstKeyVals.get(i))){
              mDartKey.put(d.dartKeyId, d.dartKeyId);
            }
          }
        }
      
      i++;
    } 
         
         
        System.debug('\n\n ======== mDartKey : ' + mDartKey); 

        /*if(dartkey.size()>0){
        
          for(DART_KeyValue_2__c d : dartkey){
              
              mDartKey.put(d.Id, d);
              //String op=mchk.get(d.Id);
              //keyValueString=keyValueString+d.Key_Value__c+ ' ' +op+ ' ' ;
          }
        }
        */
        //All objects that are checked in the tree have to be related to the targeting record.
        List<TargetingKeyValueAssociation__c> lstored = new List<TargetingKeyValueAssociation__c>();
            
        //for deletion of tree nodes changed to unchecked status from opp lineitem
        Set<String> assoNotToDelete = new Set<String>();

        //for lower than top level nodes
        /*for(String chk : dartId){
            if(chk == '' || mDartKey.get(chk) == null) continue;      
                TargetingKeyValueAssociation__c tca = new TargetingKeyValueAssociation__c(Targeting__c = targetId ,DART_KeyValue__c  =chk ,Operator__c=mchk.get(chk), targetkeyvalue__c = targetId + chk);
                lstored.add(tca);
                assoNotToDelete.add(tca.targetkeyvalue__c);
            
        }
        */
        
        for(String chk: mDartKey.keySet()){
        //ex_key = opli.Targeting__c + s;  //Targeting + DART KeyValue
        TargetingKeyValueAssociation__c tca = new TargetingKeyValueAssociation__c(Targeting__c = targetId ,DART_KeyValue__c  =chk , Operator__c='OR', targetkeyvalue__c = targetId + chk);
        lstored.add(tca);
        assoNotToDelete.add(tca.targetkeyvalue__c);
    }
        
        
        
        if(!lstored.isEmpty()){
           
            upsert lstored targetkeyvalue__c;
            
        }
/*         OpportunityLineItem li = [Select o.Targeting__c From OpportunityLineItem o Where Id = :lineItemId];
            li.Targeting__c = targetId;
//            li.KeyValueString__c=keyValue;
            update li;
            */
        delete [Select Id From TargetingKeyValueAssociation__c Where Targeting__c= :targetId And targetkeyvalue__c Not In :assoNotToDelete ];
     return  targetId+'#'+strValue;
    }
    
    public class KeyValueDTO{
      String dartKeyId;// {get; set;}
      String dartKeyValue;// {get; set;}
      public KeyValueDTO(String dartKeyId, String dartKeyValue){
        this.dartKeyId = dartKeyId;
        this.dartKeyValue = dartKeyValue;
      }
    }
     
     
    
    
    static testmethod void test(){
      
      List<Profile> p = [select id from profile Where Name='System Administrator'];
    if(p.size()==0) return;

    User u = new User(alias = 'stantd', email='test@gmail.com.tst',
    emailencodingkey='UTF-8', lastname='Testing', languagelocalekey='en_US',
    localesidkey='en_US', profileid = p.get(0).Id,timezonesidkey='America/Los_Angeles', username='testUsr@gmail.com.tst');
    
    System.runAs(u) {
    test.startTest();
      DART_KeyValue_2__c kV1=new DART_KeyValue_2__c(Key_Value__c='tK',Key__c='key1',Key_Value_Name__c='testKeyname');
      insert kV1;
      DART_KeyValue_2__c kV2=new DART_KeyValue_2__c(Key_Value__c='01',Key_Value_Name__c='testKeyname1',Node_ID__c=kV1.id);
        insert kV2;
        DART_KeyValue_2__c kV3=new DART_KeyValue_2__c(Key_Value__c='02',Key_Value_Name__c='testKeyname2',Node_ID__c=kV1.id);
        insert kV3;
        
        Targeting__c t = new Targeting__c(Description__c = 'TargetingTreeProduct');
          insert t;
        KeyValueController kvc=new KeyValueController();
        //KeyValueController.apexSaveHandler((kV1.id+'&OR'+','+kV2.id+'&OR'),'',(t.id+''),'');
        KeyValueController.apexSaveHandler((kV1.id+'&OR'+','+kV2.id+'&OR'),'',(t.id+''), '(('+kV1.Key__c+'='+kV2.Key_Value__c+')('+kV1.Key__c+'='+kV3.Key_Value__c+'))');
      test.stopTest();
    }
    }
    
}