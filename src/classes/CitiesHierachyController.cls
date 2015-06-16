global public class CitiesHierachyController {
  public String lineItemId{get;set;}
    public String targetId{get;set;}
    public String sessionId { get; set;}
    public String checkedNodes { get; set;}
    public String fromId {get; set;}
    public String hideId{get;set;} 
    public String cntryChecked{get;set;}
    public String statExist{get;set;}
    public String statAll{get;set;}
    public String existCNT{get;set;}
    public String checkedStat{get;set;}
    private Map<String,Set<id>> mCityBystat;
    public CitiesHierachyController (){
     sessionId = UserInfo.getSessionId();
     lineItemId = ApexPages.currentPage().getParameters().get('lineItemId');
     targetId = ApexPages.currentPage().getParameters().get('targetId');
     fromId = ApexPages.currentPage().getParameters().get('fromId'); 
     hideId=ApexPages.currentPage().getParameters().get('hidId'); 
     checkedNodes='';
     cntryChecked='';
     statExist='';
     statAll='';
     existCNT='';
     checkedStat='';
     
     mCityBystat=new Map<String,Set<id>>(); 
            
       Set<String> existstate=new Set<String>();
       Set<String> cnt=new Set<String>();
       
       Map<String,String> mCheckedSt=new Map<string,string>();
     String st='';       
         if(targetId != ''){
            List<TargetingCityAssociation__c> lstCities=new List<TargetingCityAssociation__c>();

              for( TargetingCityAssociation__c c: [Select Id,City__c,City__r.State_Region__c,City__r.id,City__r.Country__c From TargetingCityAssociation__c Where Targeting__c = :targetId  ]){                
                lstCities.add(c);                
                 cnt.add(c.City__r.Country__c);
                 //group associate city with it's state region
                 if(c.City__r.State_Region__c!=null){
            if(!mCityBystat.containsKey(c.City__r.State_Region__c)){
              Set<id> sId=new Set<id>();
              sId.add(c.id);
              mCityBystat.put(c.City__r.State_Region__c,sId);
            }else{
              mCityBystat.get(c.City__r.State_Region__c).add(c.id);
            }   
          }           
              }
              if(!lstCities.isEmpty()){
            
                for(TargetingCityAssociation__c c: lstCities){
                   if(c.City__r.State_Region__c==null){
               checkedNodes = checkedNodes + '\''+ c.City__r.id +'\',';
             }else{
               if(!mCheckedSt.containsKey(c.City__r.State_Region__c)){
                 
                   if(!checkedStatExist(c.City__r.State_Region__c)){
                     checkedNodes = checkedNodes + '\''+ c.City__r.id +'\',';
                     existstate.add(c.City__r.State_Region__c);                     
                   }else{
                     mCheckedSt.put(c.City__r.State_Region__c,c.City__r.id);
                   }
                   }else{
                 continue;
               }
             }
                }
              }
            
            
            

      
      set<String> sStat=mCheckedSt.keySet();
      for(String key:sStat){
        checkedStat=checkedStat+ '\''+mCheckedSt.get(key)+'\',';
      }
      
      if(checkedStat != ''){
        checkedStat = '(' + checkedStat.substring(0,checkedStat.length()-1) + ')';
      }
                    
            if(checkedNodes != ''){
        checkedNodes = '(' + checkedNodes.substring(0,checkedNodes.length()-1) + ')';
      }
            System.debug('>>><<<<<<<<<<><><><><'+checkedStat);
            System.debug('>>><<<<<<<<<<><12><><><'+checkedNodes);
      //group state that have cities over and less than 100 
           Map<string,Integer> mState=new Map<string,Integer>();
           if(existstate.size()>0){
               for(City__c c:[Select c.State_Region__c, c.Name From City__c c where c.State_Region__c in:existstate]){
                     if(!mState.containsKey(c.State_Region__c)){
                     mState.put(c.State_Region__c,1);
                     }else{
                       Integer count=mState.get(c.State_Region__c);
                       mState.put(c.State_Region__c,count+1);
                     }
               }
           }
           
           //mark states with city over and less than 100
           for(String s:mState.keySet()){ 
               Integer count=mState.get(s);
               if(count>100){
                 statExist=statExist+s+',';
               }
               statAll=statAll+s+',';
           }
           if(cnt.size()>0){
             for(String s:cnt){
               existCNT=existCNT+s+',';
             }
           }
           
           //mark checked country 
            List<TargetingCountryAssociation__c> lstCountries=[Select  t.Country__c From TargetingCountryAssociation__c t where t.Targeting__c=:targetId];
            if(lstCountries.size()>0){
              for(TargetingCountryAssociation__c tct:lstCountries){
              cntryChecked=cntryChecked+tct.Country__c+',';
              }
            }
         }
     
    }
   
   //compare amount of city in a state with cityassociation 
    private Boolean checkedStatExist(String state){
    
    Integer citysize=[Select count() From City__c c where c.State_Region__c=:state ];
    
    if(citysize>0){
      set<id> sid=mCityBystat.get(state);  
        if(!sid.isEmpty()){
          if(sid.size()==citysize){
            return true; 
          }else{
            return false;
          }
        }else{
          return false;}
      }else{
        return false;
      }
    return null;      
    }
    
     webService static String apexSaveHandler(String sChecked,String lineItemId , String targetId,String checkState){
        
        //Connect Targeting__c to the line item by putting the id in the lookup field "Targeting__c" in line items.
        if(targetId == ''){
            Targeting__c t = new Targeting__c(Description__c = 'Tar_LineItemId ' + lineItemId , TempBinder__c=true );
            insert t;
            targetId = t.Id;
        }
    
        
        String strValue='';
        set<String> sState=new Set<String>(checkState.split(','));
     
        if(sState.size()>0){
          sState.remove('');
        }

        List<City__c> lstctcheckstate=[Select c.Id From City__c c Where c.State_Region__c in :sState ];
        if(lstctcheckstate.size()>0){
          for(City__c c : lstctcheckstate){
            sChecked=sChecked+','+c.id; 
              
          }
        }
    
                       
        Set<String> sChk = new Set<String>(sChecked.split(','));
        
        Map<String,City__c> mChkCities = new Map<String,City__c>();
        
        List<City__c> lstChkCities=[Select c.Id,c.Name From City__c c Where c.Id In :sChk];
        
        if(lstChkCities.size()>0){
          for(City__c c : lstChkCities){
              strValue=strValue+c.Name+',';
              mChkCities.put(c.Id, c);
  
          }
        }
        //All objects that are checked in the tree have to be related to the targeting record.
        List<TargetingCityAssociation__c> lstTgCities = new List<TargetingCityAssociation__c>();
            
        //for deletion of tree nodes changed to unchecked status from opp lineitem
        Set<String> assoNotToDelete = new Set<String>();

        //for lower than top level nodes
        for(String chk : sChk){
            if(chk == '' || mChkCities.get(chk) == null) continue;      
                TargetingCityAssociation__c tca = new TargetingCityAssociation__c(Targeting__c = targetId ,City__c  =chk , targetcity__c  = targetId + chk);
                lstTgCities.add(tca);
                assoNotToDelete.add(tca.targetcity__c);        
        }
    
        
        if(!lstTgCities.isEmpty()){
           
            upsert lstTgCities targetcity__c;
            
        }

    if(lineItemId!=''){
        List<OpportunityLineItem> li = [Select o.City_Description__c From OpportunityLineItem o Where Id = :lineItemId];
           // li.Targeting__c = targetId;
           if(li.size()>0){
            li.get(0).City_Description__c=strValue;
            update li;
           }
        }
        delete [Select Id From TargetingCityAssociation__c Where Targeting__c= :targetId And targetcity__c Not In :assoNotToDelete ];
          
    return  targetId+'#'+strValue;
     }
     public static testmethod void testProduct_QuickCreate(){
       Country__c coun=new Country__c(Name='testcountry');
       insert coun;
        City__c c1 = new City__c(Name = 'Test',Country__c=coun.Id);
        insert c1;
        City__c c2 = new City__c(Name = 'Test1',Country__c=coun.id);
        insert c2;
        Country__c coun1=new Country__c(Name='testcountry');
       insert coun1;
        City__c c3 = new City__c(Name = 'Test1',Country__c=coun1.id,State_Region__c='teststate');
        insert c3;
    
        Targeting__c t = new Targeting__c(Description__c = 'TargetingTreeProduct' );
        insert t;
        TargetingCityAssociation__c tac = new TargetingCityAssociation__c(Targeting__c = t.Id, City__c  = c1.Id,targetcity__c  = t.Id+''+c1.Id);
        insert tac;
        Test.startTest();
                 
                String str = '/apex/CitiesHeirachyPage?fromId=&targetId='+t.Id ;
                PageReference pageRef = new PageReference(str);
                Test.setCurrentPage(pageRef);
                        CitiesHierachyController contr = new CitiesHierachyController();
                        contr.mCityBystat=new Map<string,Set<id>>();
                        contr.mCityBystat.put('teststate',new set<id>{c3.id});
                        contr.checkedStatExist('teststate');
                        CitiesHierachyController.apexSaveHandler((c1.id+','+c2.id),(t.id+''),'','');
                        
             Test.stopTest();   
               
                
        }
}