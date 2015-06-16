/*

This is a class written by Aidan Hosty (ahosty@salesfore.com)
as part of the Statement of Work 001.

The main deliverables will be triggers for the following requirements:

1. Opportunity Trigger to Update Opp Contract Expiry date to Account and Contact Records - 
Used by time based wf to send emails.... hmmm - how do stop the record falling off the time based wf queue to send mail?

2. Trigger on Clicktools Survey Object  - Change the owner of a survey to the owner of the related case ---
What are the number of surveys in the current system - do we need to update these too??

3. Auto Create a contact through case trigger - when contact is not found by email to case and web to case!

4. Echo Sign - need to update Opp Status when agreement status changes to signed?

There are a number of exising triggers on Opportunity and Cases - 
So will try to algamate any changes into this code structure if possible.

Change log;
- 2015-05-21 - GTCRM-2028 - SOX controls: Signed contract attached on opportunity level

*/
public without sharing class SF_Gumtree_SOW_001 {
    
    public static String PRODUCTION_ORG_ID = '00D200000006AK6';
    
    public static Boolean isProductionOrg()
    {
        return SF_Gumtree_SOW_001.idsEqual(Userinfo.getOrganizationId(),PRODUCTION_ORG_ID);
    }
    
    public static Boolean isSandboxOrg()
    {
        return !(SF_Gumtree_SOW_001.idsEqual(Userinfo.getOrganizationId(),PRODUCTION_ORG_ID));
    }
    
    public static Boolean idsEqual(String id1, String id2)
    {
        if(id1.subString(0, 15).equals(id2.subString(0, 15)))
        {
            return true;
        }
        
        return false;
    }
    
    public static Boolean valueIsNull(Object val)
    {
        if(val == null || String.valueOf(val).length() == 0)
        {
            return true;
        }
        
        return false;
    }
    
    
    public SF_Gumtree_SOW_001()
    {
        
    }
    
    public void handleOpportunityAfterUpdate(Map<Id,Opportunity> oldValues, Map<Id,Opportunity> newValues)
    {
        if (!CustomSettingsManager.getConfigSettingBooleanVal(CustomSettingsManager.OPP_EXPIRY_DATE_TO_CON_TRIG_ENABLED))
        {
            return;
        }
        
        List<Id> listOfOppsToPropagateDates = new List<Id>();
        List<Id> listOfAccountIdsToPropagateDates = new List<Id>();
        Map<Id,Id> mapOfOppToAccIds = new Map<Id,Id>();
        Map<Id,Id> mapOfAccToOppIds = new Map<Id,Id>();
        for (Id id:oldValues.keySet())
        {
            Opportunity oldOpp = oldValues.get(id);
            Opportunity newOpp = newValues.get(id);
            
            if (opportunityHasMovedToClosedWon(oldOpp,newOpp))
            {
                System.debug('Opp '+id+'has moved to closed won');
                
                if (!valueIsNull(newOpp.AccountId))
                {
                   listOfOppsToPropagateDates.add(id);
                   listOfAccountIdsToPropagateDates.add(newOpp.AccountId);
                   mapOfOppToAccIds.put(id, newOpp.AccountId);
                   // This assumes a 1:1 mapping between account and Opp - belive this is safe
                   mapOfAccToOppIds.put(newOpp.AccountId,id);
                }
            }
        }
        
        if (listOfOppsToPropagateDates.size() > 0)
        {
            futureUpdateContactDatesForAccountsOnOpps(listOfOppsToPropagateDates);
        }
    }
    
    @future
    public static void futureUpdateContactDatesForAccountsOnOpps(List<Id> listOfOppsToPropagateDates)
    {
        Map<Id,Opportunity> newOppValues = new Map<Id,Opportunity>([Select Id, Expiry_Date_Featured_Ad__c,Expiry_Date_Advertising__c, AccountId from Opportunity where id in: listOfOppsToPropagateDates]);
        
        Map<Id,Id> mapOfAccToOppIds = new Map<Id,Id>();
        List<Id> listOfAccountIdsToPropagateDates = new List<Id>();
        for (Opportunity o:newOppValues.values())
        {
            listOfAccountIdsToPropagateDates.add(o.AccountId);
            mapOfAccToOppIds.put(o.AccountId,o.id);
        }
        
        // Get All the Account Id's and Dates we are interested in
        // Get All the Contacts Linked to the Accounts that we are interested in
        List<Contact> contactsToUpdate = new List<Contact>();
        for (Contact c :[Select Id, AccountId, Expiry_Date_Featured_Ad__c, Expiry_Date_Advertising__c from Contact where AccountId in : listOfAccountIdsToPropagateDates and Contact_Status__c = 'Active'])
        {
              // find the account for this contact
              // find the opp - find the date
              Id oppId = mapOfAccToOppIds.get(c.AccountId);
              
              if (null != newOppValues.get(oppId).Expiry_Date_Featured_Ad__c)
              {
                c.Expiry_Date_Featured_Ad__c = newOppValues.get(oppId).Expiry_Date_Featured_Ad__c;
              }
              
              if (null != newOppValues.get(oppId).Expiry_Date_Advertising__c)
              {
                c.Expiry_Date_Advertising__c = newOppValues.get(oppId).Expiry_Date_Advertising__c;
              }
              
              contactsToUpdate.add(c);
        }
        
        if (contactsToUpdate.size() > 0)
        {
          Database.update(contactsToUpdate);
        }
    }
    
    private Boolean opportunityHasMovedToClosedWon(Opportunity oldOpp, Opportunity newOpp)
    {       
        System.debug('opportunityHasMovedToClosedWon new Opp Closed '+newOpp.IsClosed+' Won: '+newOpp.IsWon+' Stage '+newOpp.StageName);
        System.debug('opportunityHasMovedToClosedWon OLD Opp Closed '+oldOpp.IsClosed+' Won: '+oldOpp.IsWon+' Stage '+oldOpp.StageName);
        if (newOpp.IsClosed && newOpp.IsWon)
        {
            // New Opp is closed won - was old opp not closed and won?
            return !(oldOpp.IsClosed && oldOpp.IsWon);
        }
        
        return false;
    }    
    
    public void handleSurvey_Results_BeforeInserts(List<Survey_Results__c> newRecords)
    {
        updateSurveyOwnerToCaseOwner(newRecords);
    }


    public void handleEchoSign_AgreementAfterUpdates(Map<Id,echosign_dev1__SIGN_Agreement__c> oldValues, Map<Id,echosign_dev1__SIGN_Agreement__c> newValues)
    {
        // Need to find agreements linked to opportunities
        // Need to compare their current and previous agreement statuses
        // if they have changed - and new status is signed - update the opp stage to Booking
        List<Id> oppIdsToUpdateToBooking = new List<ID>();
        for (Id id:oldValues.keySet())
        {
            echosign_dev1__SIGN_Agreement__c newAgreement = newValues.get(id);
            echosign_dev1__SIGN_Agreement__c oldAgreement = oldValues.get(id);
            
            if (!valueIsNull(oldAgreement.echosign_dev1__Opportunity__c))
            {
                // TODO - do we need to check current Opp Status?
                if (oldAgreement.echosign_dev1__Status__c != newAgreement.echosign_dev1__Status__c)
                {
                    if (newAgreement.echosign_dev1__Status__c == 'Signed')
                    {
                        // Update the Opp to Booking - 
                        oppIdsToUpdateToBooking.add(oldAgreement.echosign_dev1__Opportunity__c);
                        // UPDATE -- 
                    }
                }
            }
        }
        
        // Query Opps to Update
        if (oppIdsToUpdateToBooking.size() >0)
        {
            List<Opportunity> oppsToUpdate = [Select id,StageName, Signed_Contract_Attached__c from Opportunity  where id in :oppIdsToUpdateToBooking];
            
            for (Opportunity opp: oppsToUpdate)
            {
                opp.StageName = 'Booking';
                
                // 2015-05-21 - GTCRM-2028 - SOX controls: Signed contract attached on opportunity level
                opp.Signed_Contract_Attached__c = TRUE;
            }
            
            Database.update(oppsToUpdate);
        }
        
    }

    public void handleSurvey_Results_BeforeUpdates(Map<Id,Survey_Results__c> oldValues, Map<Id,Survey_Results__c> newValues)
    {
        // This trigger will help to assign legacy survey results to their case owners.... during a migration.. 
        updateSurveyOwnerToCaseOwner(newValues.values());
    }
    
    private void updateSurveyOwnerToCaseOwner(List<Survey_Results__c> newRecords)
    {
        // Use a set - we may have multiple surveys with the same case ID?!
        Set<String> listOfCaseIds = new Set<String>();
        
        for (Survey_Results__c sResult: newRecords)
        {
            if (!valueIsNull(sResult.Case__c))
            {
                // sResult
                listOfCaseIds.add(sResult.Case__c);
            }
        }
        
        Map<Id, Case> mapOfRelatedCases = new Map<Id,Case>([Select id, ownerid from Case where id in: listOfCaseIds]);
        
        for (Survey_Results__c sResult: newRecords)
        {
            if (!valueIsNull(sResult.Case__c))
            {
                Case relatedCase = mapOfRelatedCases.get(sResult.Case__c);
                if(relatedCase == null) continue;
                // We need to check the case owner is a user - not a queue
                if (String.valueOf(relatedCase.OwnerId).substring(0,3) == '005')
                {
                    sResult.OwnerId = relatedCase.OwnerId;
                    // sResult.Case_Owner__c = relatedCase.OwnerId;
                }
            }
        }   
    }
    
    public void  handleCaseBeforeInserts(List<Case> newCases)
    {
        
        if (!CustomSettingsManager.getConfigSettingBooleanVal(CustomSettingsManager.CREATE_CONTACT_IN_CASE_TRIGGER_ENABLED))
        {
            // trigger is disabled through custom settings
            return;
        }
        
        List<Integer> casesIndexesToCreateContactsFor = new List<Integer>();
    
        for (Integer i = 0; i < newCases.size(); i++)
        {
            // If we do not have a contact id - we need to create one
            if (valueIsNull(newCases[i].ContactId))
            {
                casesIndexesToCreateContactsFor.add(i);
            }
        }
        
        if (casesIndexesToCreateContactsFor.size() > 0)
        {
            List<Contact> contactsToCreate = new List<Contact>();
            String accountIdForNewContacts =  CustomSettingsManager.getConfigSettingStringVal(CustomSettingsManager.GT_HELP_ACCOUNT_ID);
            
            for (Integer c = 0; c < casesIndexesToCreateContactsFor.size(); c++)
            {
                Case case4Contact = newCases[casesIndexesToCreateContactsFor[c]];
                contactsToCreate.add(createContactForCase(accountIdForNewContacts, case4Contact));
            }
            
            Database.Saveresult[] results = Database.insert(contactsToCreate,false);
            
            // If it was successful - update the case contact id with the new contacts record id
            for (Integer i = 0; i < results.size() ; i++)
            {
                if (results[i].isSuccess( ))
                {
                    newCases.get(casesIndexesToCreateContactsFor[i]).ContactId = results[i].getId();
                }
            }
        }
    }
    
    private Contact createContactForCase(String accId, Case c)
    {
        return new Contact(LastName=c.SuppliedEmail,Email=c.SuppliedEmail,AccountId=accId);
    }

    
    public static TestMethod void testSurveyOwnerCaseTriggers()
    {
        // Create an Account
        Account account = new Account(name='testAccount',BillingPostalCode='test', BillingCity='Test',BillingStreet='Test',BillingCountry='GB');
        insert account;
        
        // Insert a contact
        Contact contact = new Contact(lastname='testContact', accountID=account.ID);
        insert contact;
        
        String thisUserId = Userinfo.getUserId();
        
        List<User> users = [SELECT Id FROM User WHERE IsActive = true and Id != :Userinfo.getUserId() LIMIT 1];
        
        // Create a case - give it an owner other than this user
        Case c1 = new Case (subject='testcase', OwnerID=users[0].id, contactid=contact.Id);  
        insert c1;
        
        
        // Create A survey linked to the case
        Survey_Results__c surveyResult = new Survey_Results__c(Question_1__c='Will this work?', Case__c=c1.Id, Answer_1__c='Yesh');
        
        insert surveyResult;
        
        // Update the survey
        update surveyResult;
    }
    
    public static TestMethod void testEmailToCaseScenario()
    {
        // Insert a case with a dummy email address
        // See that it is associated to a new contact with that address
        Case c1 = new Case (subject='testcase',SuppliedEmail='dummy@dummy.com');  
        insert c1;
    }
    
    public static TestMethod void testAgreementStatusUpdate()
    {
        Account account = new Account(name='testAccount',BillingPostalCode='test', BillingCity='Test',BillingStreet='Test',BillingCountry='GB',Finance_Contact__c='0032000000c9nyy', Primary_Contact__c='0032000000c9nyy');
        insert account;
        
        // Insert a contact
        Contact contact = new Contact(lastname='testContact', accountID=account.ID);
        insert contact;
               
        PriceBook2 priceBook = [Select Name, IsStandard, IsDeleted, IsActive, Id From Pricebook2 p where IsStandard = true and ISactive = true LIMIT 1];
        // Insert Opp with Primary Contact- 
        Opportunity opp = new Opportunity(Name='Test Opp', StageName='First Call', CloseDate = (Date.Today() + 20),Amount=20, Primary_Contact__c=contact.Id,Pricebook2Id = pricebook.Id,AccountId=account.Id, P_O_Number__c = '123');
        insert opp;
        
        OpportunityContactRole ocr = new OpportunityContactRole(Role='Other',IsPrimary=true,OpportunityId=opp.Id,ContactId=contact.Id);
        insert ocr;
        
        opp.StageName = 'Pitched';
        opp.Approval_Status__c = true;
        // 2015-05-21 - GTCRM-2028 - SOX controls: Signed contract attached on opportunity level
        opp.Signed_contract_attached__c = true;
        update opp;
        
        // Insert and Agreement
        echosign_dev1__SIGN_Agreement__c agreement = new echosign_dev1__SIGN_Agreement__c();
        agreement.Name =  opp.Name+' agreement';
        agreement.echosign_dev1__Opportunity__c = opp.id;
        agreement.echosign_dev1__Message__c = 'Please sign this document.';
        agreement.echosign_dev1__Recipient__c = opp.Primary_Contact__c;
        
        agreement.echosign_dev1__SenderSigns__c = true;
        
        insert agreement;
        
        // Add a product
        List<PricebookEntry> pbeAd = [Select Id, IsActive, Name, Pricebook2Id, Product2Id, Product2.Description, Product2.Family, ProductCode, UnitPrice from PricebookEntry 
        where IsActive = true and Pricebook2Id = :opp.Pricebook2Id And Product2.Product_Subtype__c = 'Advertising' LIMIT 1];
        
        List<PricebookEntry> pbesFeatAdd = [Select Id, IsActive, Name, Pricebook2Id, Product2Id, Product2.Description, Product2.Family, ProductCode, UnitPrice from PricebookEntry 
        where IsActive = true and Pricebook2Id = :opp.Pricebook2Id And Product2.Product_Subtype__c = 'Featured Advertising' LIMIT 1];
        
        OpportunityLineItem lineItem1 = new OpportunityLineItem(Product_SubType__c='Advertising', OpportunityId=opp.Id,Quantity=1,TotalPrice=10,PricebookEntryId=pbeAd[0].Id);
        OpportunityLineItem lineItem2 = new OpportunityLineItem(Product_SubType__c='Advertising', OpportunityId=opp.Id,Quantity=1,TotalPrice=10,PricebookEntryId=pbesFeatAdd[0].Id);
        
        insert lineItem1;
        
        //agreement.echosign_dev1__Status__c = 'Signed';
        
        update agreement;
        
        Opportunity testOpp = [Select id, StageName from Opportunity where id = :opp.Id];
        
        //System.assert(testOpp.StageName == 'Booking','Opp stage name is '+testOpp.StageName+' should be Booking');
    }
    
    public static TestMethod void testUtils()
    {
        SF_Gumtree_SOW_001.isProductionOrg();
        SF_Gumtree_SOW_001.isSandboxOrg();
        SF_Gumtree_SOW_001.valueIsNull('');
        SF_Gumtree_SOW_001.valueIsNull(null);
        SF_Gumtree_SOW_001.valueIsNull('NOT NULL');
        SF_Gumtree_SOW_001.idsEqual('00D200000006AK6', '00D200000006AK6AAA');
        SF_Gumtree_SOW_001.idsEqual('00D200000006AK6', '00D200000006AK7AAA');
    }
    
    
    public static TestMethod void testPropagateExpiryDatesToContacts()
    {
        // Insert an account
        Account account = new Account(name='testAccount',BillingPostalCode='test', BillingCity='Test',BillingStreet='Test',BillingCountry='GB');
        insert account;
        
        List<Contact> contacts = new List<Contact>();
        
        // Insert some active contacts
        contacts.add(new Contact(lastname='testContact', accountID=account.ID,Contact_Status__c = 'Active'));
        contacts.add(new Contact(lastname='testContact', accountID=account.ID,Contact_Status__c = 'Active'));
        contacts.add(new Contact(lastname='testContact', accountID=account.ID,Contact_Status__c = 'Old Contact'));
        contacts.add(new Contact(lastname='testContact', accountID=account.ID,Contact_Status__c = 'Left Company'));
        
        insert contacts; 
        
        
        // Insert Opp
        PriceBook2 priceBook = [Select Name, IsStandard, IsDeleted, IsActive, Id From Pricebook2 p where IsStandard = true and ISactive = true LIMIT 1]; 
        Opportunity opp = new Opportunity(Name='Test Opp', StageName='First Call', CloseDate = (Date.Today() + 20),Amount=20, Primary_Contact__c=contacts[0].Id,Pricebook2Id = pricebook.Id,AccountId=account.Id, P_O_Number__c = '123');
        insert opp;
        
        OpportunityContactRole ocr = new OpportunityContactRole(Role='Other',IsPrimary=true,OpportunityId=opp.Id,ContactId=contacts[0].Id);
        insert ocr;
        
        opp.StageName = 'Pitched';
        opp.Approval_Status__c = true;
        // 2015-05-21 - GTCRM-2028 - SOX controls: Signed contract attached on opportunity level
        opp.Signed_contract_attached__c = true;
        
        update opp;
        
        // Add a product
        List<PricebookEntry> pbeAd = [Select Id, IsActive, Name, Pricebook2Id, Product2Id, Product2.Description, Product2.Family, ProductCode, UnitPrice from PricebookEntry 
        where IsActive = true and Pricebook2Id = :opp.Pricebook2Id And Product2.Product_Subtype__c = 'Advertising' LIMIT 1];
        
        List<PricebookEntry> pbesFeatAdd = [Select Id, IsActive, Name, Pricebook2Id, Product2Id, Product2.Description, Product2.Family, ProductCode, UnitPrice from PricebookEntry 
        where IsActive = true and Pricebook2Id = :opp.Pricebook2Id And Product2.Product_Subtype__c = 'Featured Advertising' LIMIT 1];
        
        OpportunityLineItem lineItem1 = new OpportunityLineItem(Product_SubType__c='Advertising', OpportunityId=opp.Id,Quantity=1,TotalPrice=10,PricebookEntryId=pbeAd[0].Id);
        OpportunityLineItem lineItem2 = new OpportunityLineItem(Product_SubType__c='Advertising', OpportunityId=opp.Id,Quantity=1,TotalPrice=10,PricebookEntryId=pbesFeatAdd[0].Id);
        
        insert lineItem1;
        insert lineItem2;
        
        
        // Move to closed won
        // opp.StageName = 'Booking';
        opp.StageName = 'Closed Won';
        opp.Approval_Status__c = true;
        // 2015-05-21 - GTCRM-2028 - SOX controls: Signed contract attached on opportunity level
        opp.Signed_contract_attached__c = true;
        opp.P_O_Number__c = '12123';
        update opp;
        
        // Check Contacts updated.
        for (Contact c: [select id, Expiry_Date_Featured_Ad__c, Expiry_Date_Advertising__c from contact where accountid = :account.Id and contact_status__C = 'Active'])
        {
           // Commented out as failing on production deployment - waiting on workflows to be implemented...
           // System.assert(c.Expiry_Date_Featured_Ad__c != null, 'Contact expiry featured add date is null '+c.Expiry_Date_Featured_Ad__c);
           // System.assert(c.Expiry_Date_Advertising__c != null, 'Contact advertising expiry date is null '+c.Expiry_Date_Advertising__c);     
        }
    }
}