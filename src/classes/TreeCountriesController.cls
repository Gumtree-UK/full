Global public class TreeCountriesController {
    public String lineItemId{get;set;}
    public String targetId{get;set;}
    public String sessionId { get; set;}
    public String checkedNodes { get; set;}
    public String fromId {get; set;}
    public String hideId{get;set;}
    public TreeCountriesController(){
     sessionId = UserInfo.getSessionId();
     lineItemId = ApexPages.currentPage().getParameters().get('id');
     targetId = ApexPages.currentPage().getParameters().get('targetId');
     fromId = ApexPages.currentPage().getParameters().get('fromId'); 
     hideId=ApexPages.currentPage().getParameters().get('hidId'); 
     checkedNodes='';
     List<TargetingCountryAssociation__c> lstCountries=[Select  t.Country__c From TargetingCountryAssociation__c t where t.Targeting__c=:targetId];
            if(lstCountries.size()>0){
                for(TargetingCountryAssociation__c tct:lstCountries){
                checkedNodes=checkedNodes+tct.Country__c+',';
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
        System.debug('++++++++++++++++++'+sChecked);
        Set<String> sChk = new Set<String>(sChecked.split(','));
       // String keyValueString='';    
        Map<String,Country__c> mChkCities = new Map<String,Country__c>();
        List<Country__c> lstChkCities=[Select c.Id From Country__c c Where c.Id In :sChk];
        
        if(lstChkCities.size()>0){          
            for(Country__c c : lstChkCities){  
                mChkCities.put(c.Id, c);    
            }
        }
        //All objects that are checked in the tree have to be related to the targeting record.
        List<TargetingCountryAssociation__c> lstTgCities = new List<TargetingCountryAssociation__c>();
            
        //for deletion of tree nodes changed to unchecked status from opp lineitem
        Set<String> assoNotToDelete = new Set<String>();

        //for lower than top level nodes
        for(String chk : sChk){
            if(chk == '' || mChkCities.get(chk) == null) continue;      
                TargetingCountryAssociation__c tca = new TargetingCountryAssociation__c(Targeting__c = targetId ,Country__c  =chk , TargetCountry__c  = targetId + chk);
                lstTgCities.add(tca);
                assoNotToDelete.add(tca.TargetCountry__c);        
        }
    
        
        if(!lstTgCities.isEmpty()){
           
            upsert lstTgCities TargetCountry__c;
            
        }

        delete [Select Id From TargetingCountryAssociation__c Where Targeting__c= :targetId And TargetCountry__c Not In :assoNotToDelete ];
          
        
          return  targetId+'#'+strValue;
    }
     public static testmethod void testProduct_QuickCreate(){
        Country__c coun=new Country__c(Name='testcountry');
        insert coun;
        
    
        Targeting__c t = new Targeting__c(Description__c = 'TargetingTreeProduct');
        insert t;
        TargetingCountryAssociation__c  tac = new TargetingCountryAssociation__c (Targeting__c = t.Id, Country__c  = coun.Id,TargetCountry__c  = t.Id+''+coun.Id);
        insert tac;
        Test.startTest();
                 
                String str = '/apex/TreeCountriesPage2?fromId=&targetId='+t.Id ;
                PageReference pageRef = new PageReference(str);
                Test.setCurrentPage(pageRef);
                        TreeCountriesController contr = new TreeCountriesController();
                     
                        TreeCountriesController.apexSaveHandler((coun.id+','+coun.id),(t.id+''),'','');
                        
             Test.stopTest();   
               
                
        }
}