/*

Change log;
- 2015-05-21 - GTCRM-2028 - SOX controls: Signed contract attached on opportunity level

*/

@isTest(SeeAllData=true)
public with sharing class OppStage2DeletePackageTest {
    
    private static Opportunity opp1;
    private static OpportunityLineItem oli1;
    
    private static void setupData(){
        
        Contact con1=new Contact( LastName='Test Contact 1', Email='test1@test.com');
        insert con1;  
                      
        //create account
        Account acc = new Account(Name='Test Account 1', Primary_contact__c = con1.id,
                                  BillingStreet='81 Melton Road,', 
                                  BillingState='Nottingham', 
                                  BillingPostalCode='NG2 6EN', 
                                  BillingCountry='GB', 
                                  BillingCity='West Bridgford');
        insert acc;
        
        //get standard price book========
        Pricebook2 pb = [select id from Pricebook2 where IsStandard = true limit 1];  
        
        
        // create product========== 
        Product2 p1 = new Product2( name='Test Product 1');
        insert p1;
        
        
        // create pricebookentry==========
        PricebookEntry pbe1 = new PricebookEntry(Pricebook2Id=pb.id,Product2Id=p1.id, UnitPrice=0.9,isActive=true); 
        insert pbe1; 
         
        // create an opportunity==========
        opp1 = new Opportunity( name='Test Opp 1', 
                                AccountId=acc.id, 
                                CloseDate=Date.valueOf('2013-4-13'), 
                                P_O_Number__c = '123', 
                                // 2015-05-21 - GTCRM-2028 - SOX controls: Signed contract attached on opportunity level
                                Signed_contract_attached__c = true);
        opp1.StageName = OppStage2DeletePackage.OPP_STAGE_BOOKING;
        insert opp1; 
        
        // add line item========================
        oli1 = new OpportunityLineItem(
                            PricebookEntryId = pbe1.id,//contain p1
                            OpportunityId = opp1.id,
                            from_Date__c=Date.valueOf('2013-4-13'),
                            until_Date__c=Date.valueOf('2014-4-13'),
                            Billing_category__c=ExcelReportHelper.BILL_CAT_FIXPRICE,
                            Quantity=555,
                            TotalPrice=999);
        insert oli1;
    } 
     
    private static testMethod void testBatch(){ 
        setupData();
        
        // Test trigger on opp update stage booking to lost 
        opp1.StageName = OppStage2DeletePackage.OPP_STAGE_LOST;
        update opp1;
        System.assert([select isOppLost__c from OpportunityLineItem where id = :oli1.id][0].isOppLost__c); 
        
        // Test batch
        Test.StartTest();
        OppStage2DeletePackage batch = new OppStage2DeletePackage(); // for coverage
        batch = new OppStage2DeletePackage(oli1.id+'');
        
        Database.executeBatch(batch);
        Test.StopTest();
        System.assert([select isOppLost__c from OpportunityLineItem where id = :oli1.id][0].isOppLost__c == false); 
    }
    
    

}