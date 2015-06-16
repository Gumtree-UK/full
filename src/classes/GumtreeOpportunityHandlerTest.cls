/**

Change log;
- 2015-05-21 - GTCRM-2028 - SOX controls: Signed contract attached on opportunity level

 */
@isTest(seeAllData=true)
private class GumtreeOpportunityHandlerTest {

    public static testMethod void testHandleOpportunity() {
        
        List<Opportunity> opportunities = createOpportunities('01220000000YY7Y', '01220000000Disx');
        Opportunity oldOpportunity = opportunities.get(0);
        Opportunity newOpportunity = opportunities.get(1);

        GumtreeOpportunityHandler handler = new GumtreeOpportunityHandler(oldOpportunity, newOpportunity);
        handler.handleOpportunityUpdate();
        
    }
    
    public static testMethod void isGumtreeRecordType() {
        List<Opportunity> opportunities = createOpportunities('01220000000YY7Y', '01220000000Disx');
        Opportunity oldOpportunity = opportunities.get(0);
        Opportunity newOpportunity = opportunities.get(1);

        GumtreeOpportunityHandler handler = new GumtreeOpportunityHandler(oldOpportunity, newOpportunity);
        Boolean isGumtreeRecordType = handler.isGumtreeRecordType();
        System.assertEquals(true, isGumtreeRecordType);
    }
    
    public static testMethod void isNotGumtreeRecordType() {
        List<Opportunity> opportunities = createOpportunities('01220000000Y83P', '01220000000Disx');
        Opportunity oldOpportunity = opportunities.get(0);
        Opportunity newOpportunity = opportunities.get(1);

        GumtreeOpportunityHandler handler = new GumtreeOpportunityHandler(oldOpportunity, newOpportunity);
        Boolean isGumtreeRecordType = handler.isGumtreeRecordType();
        System.assertEquals(false, isGumtreeRecordType);
    }
    
    private static List<Opportunity> createOpportunities(String oppRecordType, String accRecordType) {
        List<Opportunity> opportunities = new List<Opportunity>{};

        Opportunity oldOpportunity = new Opportunity();
        oldOpportunity.Name = 'Opportunity Name';
        oldOpportunity.StageName = 'Not Booking';
        oldOpportunity.CloseDate = date.newinstance(2012, 10, 10);
        oldOpportunity.RecordTypeId = oppRecordType;
        upsert oldOpportunity;
        Opportunity newOpportunity = new Opportunity();
        newOpportunity.Name = 'Opportunity Name';
        newOpportunity.StageName = 'Booking';
        newOpportunity.CloseDate = date.newinstance(2012, 10, 10);
        newOpportunity.RecordTypeId = oppRecordType;
        newOpportunity.P_O_Number__c = '123';
        // 2015-05-21 - GTCRM-2028 - SOX controls: Signed contract attached on opportunity level
        newOpportunity.Signed_contract_attached__c = true;
        upsert newOpportunity;
        

        // Create test product to add to oppty later
        Product2 newProduct = new Product2();
        newProduct.Name = 'Test Widget';
        newProduct.Family = 'Widgets';
        newProduct.Product_Subtype__c = 'Advertising';
        insert newProduct;

        // Create a pricebook
        Pricebook2 pb = new Pricebook2();
        pb.Name = 'Custom Pricebok';
        pb.IsActive = TRUE;
        insert pb;
        
        // Create pricebook entry
        PricebookEntry pbe = new PricebookEntry();
        pbe.IsActive = TRUE;
        pbe.Pricebook2Id = [SELECT Id FROM Pricebook2 WHERE IsStandard = TRUE LIMIT 1].Id;
        pbe.Product2Id = newProduct.Id;
        pbe.UnitPrice = 5555;
        pbe.UseStandardPrice = FALSE;
        insert pbe;
        
        OpportunityLineItem oli = new OpportunityLineItem();
        oli.OpportunityId = newOpportunity.Id;
        oli.Adjusted_credits__c = 1;
        oli.Quantity = 10;
        oli.TotalPrice = 5 * 5555;
        oli.PricebookEntryId = pbe.Id;
        oli.from_Date__c = date.newinstance(2011, 10, 10);
        oli.until_Date__c = date.newinstance(2013, 10, 10);
        upsert oli;
        
        Contact primaryContact = new Contact();
        primaryContact.FirstName = 'david';
        primaryContact.LastName = 'david';
        primaryContact.Email = 'davidsmith@gumtree.com';
        primaryContact.Phone = 'david';
        upsert primaryContact;
        
        Account newAccount = new Account();
        newAccount.Name = 'as';
        newAccount.Password__c = 'ds';
        newAccount.BillingStreet = 'ds';
        newAccount.BillingCity = 'ds';
        newAccount.BillingCountry = 'GB';
        newAccount.BillingPostalCode = 'ds';
        newAccount.AccountNumber = '123455';
        newAccount.Primary_contact__c = primaryContact.Id;
        newAccount.Account_Status__c = 'Not Active';
        newAccount.RecordTypeId = accRecordType;
        upsert newAccount;
        
        oldOpportunity.AccountId = newAccount.Id;
        newOpportunity.AccountId = newAccount.Id;
        
        update oldOpportunity;
        update newOpportunity;
        
        opportunities.add(oldOpportunity);
        opportunities.add(newOpportunity);
        
        return opportunities;
    }
}