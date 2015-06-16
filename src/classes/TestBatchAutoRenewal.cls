/**
 * This class contains unit tests for validating the behavior of BatchAutoRenewal
 * @createdDate: 13-May-2013
 * @author: Sopha Pum
 
Change log;
- 2015-05-21 - GTCRM-2028 - SOX controls: Signed contract attached on opportunity level

 */
@isTest(seeAllData=true)
private class TestBatchAutoRenewal {
    private static OpportunityLineItem opli;
    
    static void initData(){
        PricebookEntry pbe = [select Id, Pricebook2Id, Product2Id from PricebookEntry where IsActive=true and Pricebook2.IsActive=true and Product2.IsActive=true limit 1];
        Product2 pro = [Select Auto_renewal__c From Product2 Where Id =: pbe.Product2Id];
        pro.Auto_renewal__c = true;
        update pro;
        
        Contact con = new Contact ( FirstName = 'abc',
                                    LastName = 'abc',
                                    Email = 'steven@gumtree.com',
                                    Phone ='123'
                                    );
        insert con;
        
        Account acc = new Account(  Name = 'Test Account3445',
                                    BillingStreet = 'Test Street', 
                                    BillingState = 'ON', 
                                    BillingPostalCode = 'M8X 1E1', 
                                    BillingCountry = 'CA', 
                                    BillingCity = 'Test City',
                                    Primary_contact__c = con.id,
                                    Finance_contact__c = con.id
                                    );
        insert acc;
        
        Opportunity opp = new Opportunity(  Name = 'Test Opp565566', 
                                            StageName = 'Booking',
                                            Payment_Method__c = 'PayPal',
                                            P_O_Number__c = '123',
                                            CloseDate = System.today().addDays(10),
                                            AccountId = acc.Id,
                                            Pricebook2Id = pbe.Pricebook2Id, 
                                            BillingFrequency__c = 'One Invoice',
                                            // 2015-05-21 - GTCRM-2028 - SOX controls: Signed contract attached on opportunity level
                                            Signed_contract_attached__c = true);
        insert opp;
        
        opli = new OpportunityLineItem( //from_Date__c = System.today(),
                                        from_Date__c = System.today().addMonths(-1) ,
                                        //until_Date__c = System.today().addDays(1),
                                        until_Date__c = System.today(), 
                                        Net_Net_Net__c = 10, 
                                        UnitPrice = 200,
                                        Site_s__c = 'Canada',
                                        Quantity = 10,
                                        PricebookEntryId = pbe.Id,
                                        OpportunityId = opp.Id,
                                        Length_months__c = 1,
                                        Billing_Category__c = 'CPA');
        insert opli;
                                        
    }
    static testMethod void myUnitTest() { 
        initData();
        
        Test.startTest();
            SchAutoRenewal sch = new SchAutoRenewal(opli.Id);
            sch.execute(null);
        Test.stopTest();
        
        List<OpportunityLineItem> lstOplis = [Select Id, until_Date__c, Revenue2__c, OpportunityId From OpportunityLineItem Where id =: opli.Id];
        //System.assertEquals(System.today().addDays(1).addMonths(1), lstOplis.get(0).until_Date__c, 'Batch ran update product end date by add 1 month.');
        
        List<Revenue_Schedule2__c> lstRS = [Select Id,Month__c, Auto_renew_month__c From Revenue_Schedule2__c Where Revenue2__c =: lstOplis.get(0).Revenue2__c order by Month__c  DESC limit 1];
   //     System.assertEquals(System.today().addMonths(1).toStartOfMonth(), lstRS.get(0).Datum__c, 'create 1 additional revenue schedule');
   //     System.assertEquals(true, lstRS.get(0).Auto_renew_month__c, 'For every new RS record added using batch logic, the checkbox “auto-renew month” needs to be set on the RS record');
        
        List<Opportunity> lstOpp = [Select id, StageName From Opportunity Where id=: lstOplis.get(0).OpportunityId];
    //    System.assertEquals('Booking (Auto-renewal)', lstOpp.get(0).StageName, '4.    When an auto-renewal takes place (an extra revenue schedule is created), the stage of the opportunity should be changed to “Booking (Auto-renewal)”');
    }
}