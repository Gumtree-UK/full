/**
*
*@Author : SPP
*@Date : 08/15/2014
*@Business : 

See EchoSignServicesBatch
 */
 
 @isTest(SeeAllData=true)
private class EchoSignServicesBatch_Test {

    static testMethod void myUnitTest() {
            // use one existing account
            Account acc = new Account();
            acc.Name = 'Test Account 1'; 
            acc.BillingStreet = 'Fake Street';
            acc.BillingCity = 'Fake City';
            acc.BillingState = 'London';
            acc.BillingPostalCode = '123'; 
            acc.BillingCountry = 'GB';
            insert acc;
        
            // new contact
            Contact con=new Contact();
            con.LastName='TestContact';
            con.AccountId=acc.Id;
            con.Fax='1234567';
            con.Email='Test@test.com';
            con.MobilePhone='1346975';

            insert con;
    
            Product2 prod = new Product2(
                Name='ApexTestProd',
                IsActive=true);
            insert prod;
    
            Pricebook2 pb = [select Id from Pricebook2 where IsStandard=true limit 1];
    
            PricebookEntry pbe = new PricebookEntry(
                UseStandardPrice=false,
                Product2Id=prod.Id,
                Pricebook2Id=pb.Id,
                UnitPrice=1.00,
                IsActive=true);
            insert pbe;
    
            Opportunity opp = new Opportunity(
                Name='Test Opp',
                Probability=100,
                StageName='Contract',
                CloseDate=System.today(),
                Payment_Method__c='Direct Debit',
              //  RecordTypeId = '012g00000004TUSAA2',
                RecordTypeId = '012w0000000QBzr',
                Primary_Contact__c = con.Id,
                Approval_Status__c =true,
                Pricebook2Id=pb.Id);
                
            insert opp;
            
             Set<Id> oppIds = new Set<Id>();
             oppIds.add(opp.Id);
             
             String sessionId = UserInfo.getSessionId();
             
        Test.StartTest();
        Database.executeBatch(new EchoSignServicesBatch(oppIds,sessionId));
        Test.StopTest();
    }
}