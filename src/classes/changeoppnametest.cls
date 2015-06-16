@isTest
private class changeoppnametest{
  static testMethod void changeOppName() {

    // testet auch copyLastOpportunitiesAgencyToAccount
    Account acc1 = new Account(
      Name='Customer1',BillingStreet='Street1',
      BillingCity='City1',BillingCountry='GB',
      BillingPostalCode='abc1');
      
    insert acc1;
     
    Account acc2 = new Account(
      Name='Agency1',BillingStreet='Street2',
      BillingCity='City2',BillingCountry='GB',
      BillingPostalCode='abc2');
      
    insert acc2;

    Contact con = new Contact();
      con.LastName='TestContact';
      con.AccountId=acc1.Id;
      con.Fax='1234567';
      con.Email='Test@test.com';
      con.MobilePhone='1346975';
    
    insert con;
    
    acc1.Primary_Contact__c = con.id;
    acc1.Finance_Contact__c = con.id;
    
    update acc1;
    
    acc2.Primary_Contact__c = con.id;
    acc2.Finance_Contact__c = con.id;
    
    update acc2;

    Site__c site = new Site__c(
      Name='Testsite');

    Product2 prod = new Product2(
      Name='ApexTestProd',
      IsActive=true,
      Site__c=site.id);

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
      Agency__c=acc2.id,
      AccountId=acc1.id,
      Campaign_Name__c='Campaign',
      StageName='gebucht',
      CloseDate=System.today(),
      Pricebook2Id=pb.Id);

    insert opp;

    OpportunityLineItem oli = new OpportunityLineItem(
      OpportunityId=opp.Id,
      Quantity=100,
      TotalPrice=100.0,
      from_Date__c=System.today(),
      until_Date__c=System.today(),
      PricebookEntryId=pbe.Id);

    insert oli;
    
    update opp;
    
  }
}