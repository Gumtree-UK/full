public class TestTriggers {
  static testMethod void myTest() {
   Date futureDate = date.newInstance(2050, 6, 6);
    Account account = new Account(name='testAccount',BillingPostalCode='test', BillingCity='Test',BillingStreet='Test',BillingCountry='GB');
    insert account;
    Contact con = new Contact(LastName='TestContact', AccountId=account.Id, Fax='1234567', Email='Test@test.com', MobilePhone='1346975');
    insert con;
    
    account.Primary_Contact__c = con.id;
    account.Finance_Contact__c = con.id;
    
    update account;   
    
    account = [select name from Account where name=:account.name];
    Opportunity opp = new Opportunity(name='testOpp', accountID=account.ID, StageName='Verbal Acceptance', CloseDate = futureDate);
    insert opp;
    opp = [select ID, name, StageName, Primary_Contact__c from Opportunity where ID=:opp.ID];
    
    
    // ---------- BEGIN SET UP ---------- //
        
    // Set up some local variables
    String opportunityName = 'My Opportunity';
    String standardPriceBookId = '';
        
    PriceBook2 pb2Standard = [select Id from Pricebook2 where isStandard=true];
    standardPriceBookId = pb2Standard.Id;
            
    // set up product2 and Verify that the results are as expected.
    Product2 p2 = new Product2(Name='Test Product',isActive=true);
    insert p2;
    Product2 p2ex = [SELECT Name FROM Product2 WHERE Id = :p2.Id];
    System.assertEquals('Test Product', p2ex.Name);
        
    // set up PricebookEntry and Verify that the results are as expected.
    PricebookEntry pbe = new PricebookEntry(Pricebook2Id=standardPriceBookId, Product2Id=p2.Id, UnitPrice=99, isActive=true);
    insert pbe;
    PricebookEntry pbeex = [SELECT Pricebook2Id FROM PricebookEntry WHERE Id = :pbe.Id];
    System.assertEquals(standardPriceBookId, pbeex.Pricebook2Id);
        
    // set up OpportunityLineItem and Verify that the results are as expected.
    OpportunityLineItem oli = new OpportunityLineItem(PriceBookEntryId=pbe.Id, OpportunityId=opp.Id, Quantity=1, TotalPrice=99);
    insert oli;
    OpportunityLineItem oliex = [SELECT PriceBookEntryId FROM OpportunityLineItem WHERE Id = :oli.Id];
    System.assertEquals(pbe.Id, oliex.PriceBookEntryId);            
        
    // ---------- END SET UP (phew!) ---------- //
    
    Contact contact = new Contact(lastname='testContact1', accountID=account.ID);
    insert contact;
    contact = [select name from Contact where LastName=:contact.lastname];
    OpportunityContactRole oppContact = new OpportunityContactRole(IsPrimary = true, ContactID=contact.ID, OpportunityID=opp.ID);
    insert oppContact;
    oppContact = [select Id, isPrimary from OpportunityContactRole where OpportunityID=:oppContact.OpportunityID and ContactID=:oppContact.ContactID];
    update opp;
    opp.name = 'testOppUpdate';
    opp.StageName = 'Verbal Acceptance';
    opp.AMOUNT = 20000;
//When something goes to stage 7, IsClosed switches to true
    update opp;    
    opp = [select ID, name, IsClosed, StageName, Primary_Contact__c from Opportunity where ID=:opp.ID];
//Assertions go here:
    System.assert(account != null);
    System.assert(contact != null);
    System.assert(oppContact != null);
    System.assert(opp.name == 'testOppUpdate');
    System.assert(opp.Primary_Contact__c != null);
     try {
       delete opp;
       delete account;
       delete oppContact;
       delete contact;
       }
     catch (DmlException e) {
       e.getDmlMessage(0);
     }
    }
}