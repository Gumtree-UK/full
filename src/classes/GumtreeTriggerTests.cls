/**

Change log;
- 2015-05-21 - GTCRM-2028 - SOX controls: Signed contract attached on opportunity level

 */
@isTest (seeAllData=true)
private class GumtreeTriggerTests {

  static testmethod void testRemoteOppBookingTrigger() {
        
    Account acct = new Account();
    acct.Name = 'foobar';
//    acct.AccountNumber = '5341234';
    acct.BillingStreet = 'abc';
    acct.BillingCity = 'abc';
    acct.BillingCountry ='GB';
    acct.BillingPostalCode = 'abc';
    acct.Account_Status__c = 'Closed';
    acct.Account_Migrated__c = true;
    insert acct;
    
    Contact cnct = new Contact();
    cnct.AccountId = acct.id;
    cnct.Email = 'foo@bar.com';
    cnct.FirstName = 'Roger';
    cnct.LastName = 'Ramjet';
    insert cnct;

    Opportunity opp = new Opportunity();
    opp.Name = 'foop';
    opp.RecordTypeId = '01220000000YY7Y';
    opp.StageName = 'Contract';
    opp.P_O_Number__c = '1';
    opp.AccountId = acct.id;
    opp.CloseDate = Date.today();
    opp.Primary_Contact__c = cnct.id;
    // 2015-05-21 - GTCRM-2028 - SOX controls: Signed contract attached on opportunity level
    opp.Signed_contract_attached__c = true;
    insert opp;
    
    OpportunityLineItem oli = new OpportunityLineItem();
    oli.PricebookEntryId = '01u20000000i7kBAAQ';
    oli.Quantity = 100;
    oli.from_Date__c = Date.today();
    oli.until_Date__c = Date.today();
    oli.Adjusted_credits__c = 123;
    oli.OpportunityId = opp.id;
    oli.TotalPrice = 100.00;
    insert oli;

    // gumtree_remote_opp_booking_trigger
    opp.StageName = 'Booking';
    update opp;
    
    // gumtree_remote_opli_trigger
    oli.from_Date__c = Date.today().addDays(1);
    update oli;    
  }

  static testmethod void testRemoteAccountInsertTrigger() {
    
    Account acct = new Account();
    acct.RecordTypeId = '012200000005MbL';
    acct.Name = 'foobar';
    acct.AccountNumber = '5341234';
    acct.BillingStreet = 'abc';
    acct.BillingCity = 'abc';
    acct.BillingCountry ='GB';
    acct.BillingPostalCode = 'abc';
    acct.Account_Status__c = 'Closed';
    acct.Account_Migrated__c = true;
    insert acct;
    
  }

  static testmethod void testRemoteAccountTrigger() {
    
    //Create test data
    Account acct = new Account();
    acct.RecordTypeId = '012200000005MbL';
    acct.Name = 'foobar';
    acct.BillingStreet = 'abc';
    acct.BillingCity = 'abc';
    acct.BillingCountry ='GB';
    acct.BillingPostalCode = 'abc';
    acct.Account_Status__c = 'Closed';
    acct.Account_Migrated__c = true;
    insert acct;
    
    //Set primary contact
    Contact cnct = new Contact();
    cnct.AccountId = acct.id;
    cnct.Email = 'foo@bar.com';
    cnct.FirstName = 'Roger';
    cnct.LastName = 'Ramjet';
    insert cnct;
    
    //Start Test add primary contact to account
    Test.startTest();
    
    acct.Primary_contact__c = cnct.Id;
    update acct;
    
    Test.stopTest();
    
    //Start Test update Account with primary contact but no account number
    /*Test.startTest();
    
    acct.BillingStreet = '123';
    update acct;
    
    Test.stopTest();
    
    //Add account number
    acct.AccountNumber = '5341234';
    
    //Start Test update Account with primary contact and account number
    Test.startTest();
    
    acct.BillingStreet = 'asd';
    update acct;
    
    Test.stopTest();
    
    //Start Test change Account number
    Test.startTest();
    
    acct.AccountNumber = '123456';
    update acct;
    
    Test.stopTest();
    
    
    //Set primary contact
    Contact cnct2 = new Contact();
    cnct2.AccountId = acct.id;
    cnct2.Email = 'foo2@bar.com';
    cnct2.FirstName = 'Roger';
    cnct2.LastName = 'Ramjet';
    insert cnct2;
    
    acct.Account_Migrated__c = false;
    update acct;
    
    //Start Test update Account with new primary contact and account number and non-migrated
    Test.startTest();
    
    acct.BillingStreet = 'asd';
    acct.Primary_contact__c = cnct2.Id;
    update acct;
    
    Test.stopTest();*/
    
  }

  static testmethod void testRemoteAccountTriggerUpdateWithNoAccountNumber() {
    
    //Create test data
    Account acct = new Account();
    acct.RecordTypeId = '012200000005MbL';
    acct.Name = 'foobar';
    acct.BillingStreet = 'abc';
    acct.BillingCity = 'abc';
    acct.BillingCountry ='GB';
    acct.BillingPostalCode = 'abc';
    acct.Account_Status__c = 'Closed';
    acct.Account_Migrated__c = true;
    insert acct;
    
    //Set primary contact
    Contact cnct = new Contact();
    cnct.AccountId = acct.id;
    cnct.Email = 'foo@bar.com';
    cnct.FirstName = 'Roger';
    cnct.LastName = 'Ramjet';
    insert cnct;
    
    acct.Primary_contact__c = cnct.Id;
    update acct;
    
    //Start Test update Account with primary contact but no account number
    Test.startTest();
    
    acct.BillingStreet = '123';
    update acct;
    
    Test.stopTest();
    
  }

  static testmethod void testRemoteAccountTriggerUpdateWithAccountNumber() {
    
    //Create test data
    Account acct = new Account();
    acct.RecordTypeId = '012200000005MbL';
    acct.Name = 'foobar';
    acct.BillingStreet = 'abc';
    acct.BillingCity = 'abc';
    acct.BillingCountry ='GB';
    acct.BillingPostalCode = 'abc';
    acct.Account_Status__c = 'Closed';
    acct.Account_Migrated__c = true;
    insert acct;
    
    //Set primary contact
    Contact cnct = new Contact();
    cnct.AccountId = acct.id;
    cnct.Email = 'foo@bar.com';
    cnct.FirstName = 'Roger';
    cnct.LastName = 'Ramjet';
    insert cnct;
    
    acct.Primary_contact__c = cnct.Id;
    acct.BillingStreet = '123';
    acct.AccountNumber = '5341234';
    update acct;
    
    //Start Test update Account with primary contact and account number
    Test.startTest();
    
    acct.BillingStreet = 'asd';
    update acct;
    
    Test.stopTest();
    
  }

  static testmethod void testRemoteAccountTriggerUpdateChangeAccountNumber() {
    
    //Create test data
    Account acct = new Account();
    acct.RecordTypeId = '012200000005MbL';
    acct.Name = 'foobar';
    acct.BillingStreet = 'abc';
    acct.BillingCity = 'abc';
    acct.BillingCountry ='GB';
    acct.BillingPostalCode = 'abc';
    acct.Account_Status__c = 'Closed';
    acct.Account_Migrated__c = true;
    insert acct;
    
    //Set primary contact
    Contact cnct = new Contact();
    cnct.AccountId = acct.id;
    cnct.Email = 'foo@bar.com';
    cnct.FirstName = 'Roger';
    cnct.LastName = 'Ramjet';
    insert cnct;
    
    acct.Primary_contact__c = cnct.Id;
    acct.BillingStreet = '123';
    acct.AccountNumber = '5341234';
    update acct;
    
    //Start Test update Account with primary contact and account number
    Test.startTest();
    
    acct.AccountNumber = '123456';
    update acct;
    
    Test.stopTest();
    
  }

  static testmethod void testRemoteAccountTriggerUpdateChangePrimaryContact() {
    
    //Create test data
    Account acct = new Account();
    acct.RecordTypeId = '012200000005MbL';
    acct.Name = 'foobar';
    acct.BillingStreet = 'abc';
    acct.BillingCity = 'abc';
    acct.BillingCountry ='GB';
    acct.BillingPostalCode = 'abc';
    acct.Account_Status__c = 'Closed';
    acct.Account_Migrated__c = true;
    insert acct;
    
    //Set primary contact
    Contact cnct = new Contact();
    cnct.AccountId = acct.id;
    cnct.Email = 'foo@bar.com';
    cnct.FirstName = 'Roger';
    cnct.LastName = 'Ramjet';
    insert cnct;
    
    acct.Primary_contact__c = cnct.Id;
    acct.BillingStreet = '123';
    acct.AccountNumber = '5341234';
    update acct;
    
    //Set primary contact
    Contact cnct2 = new Contact();
    cnct2.AccountId = acct.id;
    cnct2.Email = 'foo2@bar.com';
    cnct2.FirstName = 'Roger';
    cnct2.LastName = 'Ramjet';
    insert cnct2;
    
    //Start Test update Account with primary contact and account number
    Test.startTest();
    
    acct.Primary_contact__c = cnct2.Id;
    acct.BillingStreet = 'asd';
    update acct;
    
    Test.stopTest();
    
  }

  static testmethod void testRemoteContactTrigger() {
    
    //Create test data
    Account acct = new Account();
    acct.Name = 'foobar';
//    acct.AccountNumber = '5341234';
    acct.BillingStreet = 'abc';
    acct.BillingCity = 'abc';
    acct.BillingCountry ='GB';
    acct.BillingPostalCode = 'abc';
    acct.Account_Status__c = 'Closed';
    acct.Account_Migrated__c = true;
    insert acct;
    
    Contact cnct = new Contact();
    cnct.AccountId = acct.id;
    cnct.Email = 'foo@bar.com';
    cnct.FirstName = 'Roger';
    cnct.LastName = 'Ramjet';
    insert cnct;
    
    acct.AccountNumber = '5341234';
    acct.Name = 'newName';
    acct.Primary_contact__c = cnct.Id;
    update acct;
    
    Account acct2 = new Account();
    acct2.Name = 'new account';
    acct2.AccountNumber = '5341235';
    acct2.BillingStreet = 'abc';
    acct2.BillingCity = 'abc';
    acct2.BillingCountry ='GB';
    acct2.BillingPostalCode = 'abc';
    acct2.Account_Status__c = 'Closed';
    acct2.Account_Migrated__c = true;
    insert acct2;
    
    //Start Test
    Test.startTest();
    
    cnct.AccountId = acct2.id;
    update cnct;
    
    cnct.Email = 'new@email.com';
    update cnct;
    
    Test.stopTest();
  }

  static testmethod void testRemoteOpliDelTrigger() {
        
    Account account = new Account();
    account.Name = 'foobar';
    account.AccountNumber = '5341234';
    account.BillingStreet = 'abc';
    account.BillingCity = 'abc';
    account.BillingCountry ='GB';
    account.BillingPostalCode = 'abc';
    account.Account_Status__c = 'Closed';
    account.Account_Migrated__c = true;
    insert account;

    Contact cnct = new Contact();
    cnct.AccountId = account.id;
    cnct.Email = 'foo@bar.com';
    cnct.FirstName = 'Roger';
    cnct.LastName = 'Ramjet';
    insert cnct;

    account.Primary_contact__c = cnct.Id;
    account.AccountNumber = '5341245';
    update account;
    
    Opportunity opportunity = new Opportunity();
    opportunity.AccountId = account.Id;
    opportunity.StageName = 'stage name';
    opportunity.Name = 'opp name';
    opportunity.CloseDate = Date.valueOf('1983-04-20 11:00:00');
    opportunity.P_O_Number__c = '123';
    // 2015-05-21 - GTCRM-2028 - SOX controls: Signed contract attached on opportunity level
    opportunity.Signed_contract_attached__c = true;
    insert opportunity;
    
    //create pricebook
    Pricebook2 pbook = [select id from Pricebook2 where IsStandard = true limit 1];
    
    Product2 product2 = new Product2();
    product2.Name = 'prod 2';
    insert product2;
    
    //create pricebook entry
    PricebookEntry pricebookEntry = new PricebookEntry(Pricebook2Id = pbook.Id, Product2Id = product2.Id, UnitPrice = 10000, IsActive = true, UseStandardPrice = false);
    insert pricebookEntry;
    
    OpportunityLineItem opportunityLineItem = new OpportunityLineItem();
    opportunityLineItem.OpportunityId = opportunity.Id;
    opportunityLineItem.Quantity = 10;
    opportunityLineItem.UnitPrice = 10;
    opportunityLineItem.PricebookEntryId = pricebookEntry.Id;
    insert opportunityLineItem;
    
    Test.startTest();
    
    delete opportunityLineItem;
    
    Test.stopTest();
  }
  
}