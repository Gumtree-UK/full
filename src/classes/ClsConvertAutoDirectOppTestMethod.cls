/*

Change log;
- 2015-05-21 - GTCRM-2028 - SOX controls: Signed contract attached on opportunity level

*/

@isTest(seeAllData=true)
public class ClsConvertAutoDirectOppTestMethod {
    public static testMethod void testClsConvertAutoDirectOpp(){
        Profile p=[Select Id From Profile Where Name='System Administrator' or Name='Systemadministrator' Limit 1];
        User u=new User(Username='testUser1@boco.com',LastName='testLastName1',Email='testEmail1@boco.com',Alias='test1',CommunityNickname='testCommun1',
                        TimeZoneSidKey='Pacific/kiritimati',LocaleSidKey='ar',EmailEncodingKey='UTF-8',ProfileId=p.Id,LanguageLocaleKey='en_US');
        
        insert u;             
        System.runAs(u){  
            Map<String,String> mapRecordType = ClsConvertAutoDirectOpp.getRecordType();  
            Account acc = new Account(  Name = 'Test Account234222',
                                  BillingStreet = 'Test Street', 
                                  BillingState = 'ON', 
                                  BillingPostalCode = 'M8X 1E1', 
                                  BillingCountry = 'CA', 
                                  BillingCity = 'Test City'
                                  );
          insert acc;         

          // 2015-05-21 - GTCRM-2028 - SOX controls: Signed contract attached on opportunity level
          Opportunity  opp1 = new Opportunity(P_O_Number__c = '1', Payment_Method__c ='Indirect', name='Test 1',Agency__c= acc.id, closeDate= system.today(), stageName='test',RecordTypeId =mapRecordType.get(ClsConvertAutoDirectOpp.AUTOS_APPROVED_RECORDTYPE), Signed_contract_attached__c = true);
          insert opp1;

          // 2015-05-21 - GTCRM-2028 - SOX controls: Signed contract attached on opportunity level
          Opportunity  opp = new Opportunity(P_O_Number__c = '1', Opportunity__c=opp1.id ,name='Test', closeDate= system.today(), stageName='test', Signed_contract_attached__c = true);
          insert opp;  
                              
          Product2  pro = new Product2 (name ='test test test', Length_months__c=3);
          insert pro;  
                    
          Product2  pro1 = new Product2 (name ='test produc1', Length_months__c=3);
          insert pro1;             
                      
          PriceBook2 pb2Standard = [select Id from Pricebook2 where isStandard=true];                      
          PricebookEntry pbe = new PricebookEntry(Pricebook2Id= pb2Standard.Id, Product2Id=pro.Id, UnitPrice=99, isActive=true);
          insert pbe;
                
          PricebookEntry pbe1 = new PricebookEntry(Pricebook2Id= pb2Standard.Id, Product2Id=pro1.Id, UnitPrice=99, isActive=true);
          insert pbe1;
                      
          List<OpportunityLineItem> lstItem = new List<OpportunityLineItem>();
          lstItem.add( new OpportunityLineItem( PriceBookEntryId=pbe.Id,OpportunityId=opp.id,from_Date__c= system.today(), until_Date__c= system.today() + 90, Quantity = 20, TotalPrice = 20000));
          lstItem.add( new OpportunityLineItem( PriceBookEntryId=pbe1.Id,OpportunityId=opp1.id,from_Date__c= system.today(), until_Date__c= system.today() + 90, Quantity = 20, TotalPrice = 20000));                  
          insert lstItem;            
                 
          Test.startTest();                         
                String oppId= ClsConvertAutoDirectOpp.cloneOpportunity(opp1.id);                                            
                opp.Is_Converted__c = true;
                opp.stagename = ClsBookingOppUpdate.ST_BOOKING;                   
                update opp;
          Test.stopTest();
        }
    }
}