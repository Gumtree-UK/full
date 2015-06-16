/*
Change log:

- 2013-07-19 - GTCRM-352 - Motors account type added
- 2013-09-25 - GTCRM-352 - Remove changes made as integration is now complete
- 2014-01-16 - GTCRM-729 - Update GT integration test classes to improve deployment 
- 2015-05-21 - GTCRM-2028 - SOX controls: Signed contract attached on opportunity level

*/

public with sharing class GumtreeAccountHandler {
    
    private Account oldAccount;
    private Account newAccount;
    private GumtreeUtilsInterface utils;
    
    public GumtreeAccountHandler(Account oldAccount, Account newAccount) {
        this.newAccount = newAccount;
        this.oldAccount = oldAccount;
        this.utils = GumtreeUtils.getGumtreeUtilsInterface();
    }
    
    public GumtreeAccountHandler(Account oldAccount, Account newAccount, GumtreeUtilsInterface utils) {
        this.newAccount = newAccount;
        this.oldAccount = oldAccount;
        this.utils = utils;
    }
    
    public void updateAccount() {
                                     
        if ((newAccount.AccountNumber == null || newAccount.AccountNumber == '') 
               && newAccount.AccountNumber == oldAccount.AccountNumber
               && newAccount.Primary_contact__c != null
               && newAccount.Fiqas_Account_Synced__c == oldAccount.Fiqas_Account_Synced__c) {
                
            Boolean needsAccountNumber = false;
            
//  GTCRM-352 - Remove account creation before package for motors
//            if (newAccount.RecordTypeId == '012W00000004QtZ' || newAccount.RecordTypeId == '012200000002Lwv' || newAccount.RecordTypeId == '012200000002LlM' || newAccount.RecordTypeId == '01220000000Q8xS' || newAccount.RecordTypeId == '012w0000000QA3A') {  
            if (newAccount.RecordTypeId == '012W00000004QtZ' || newAccount.RecordTypeId == '012200000002Lwv') {
                // Pets account - GTBTC-127
                needsAccountNumber = true;
            } else {
                // For agency accounts
                for (Account acc : [SELECT Id,
                                        (SELECT Id
                                            FROM Opportunities
                                            WHERE StageName='Booking')
                                        FROM Account 
                                        WHERE Id IN 
                                            (SELECT AccountFromId
                                                FROM AccountPartner
                                                WHERE AccountToId = :newAccount.Id)]) {
                    if (acc.Opportunities != null && acc.Opportunities.size() > 0) {
                        needsAccountNumber = true;
                        break;
                    }
    
                }
            }
            
            if (needsAccountNumber) {
                //The account has no account number so it should not have been created in Gumtree yet
                //The account has a primary contact so it should now be created in Gumtree
                createAccount(utils, newAccount);
            }
                
        } else if (newAccount.AccountNumber != null  && newAccount.AccountNumber != '' 
                && newAccount.Primary_contact__c != null
                && newAccount.AccountNumber == oldAccount.AccountNumber
                && newAccount.Fiqas_Account_Synced__c == oldAccount.Fiqas_Account_Synced__c
                && (newAccount.Primary_contact__c != oldAccount.Primary_Contact__c
                    || accountDetailsChanged())) {
            
            //Account has been updated with something Gumtree cares about
            Contact newPrimaryContact = utils.getAccountPrimaryContact(newAccount);
            //Account newAccountWithPrimaryContact = getAccountWithPrimaryContactPopulated(newAccount);
            String oldUserJson = null;
            String oldUserEmail = null;
            String accountJson = null;
            String newUserJson = null;
            
            //a couple of ifs to avoid unnecessary queries
            if (newAccount.Primary_contact__c != oldAccount.Primary_Contact__c) {
                Contact oldPrimaryContact = utils.getAccountPrimaryContact(oldAccount);
                oldUserEmail = oldPrimaryContact.Email;
                oldUserJson = utils.buildUpdateUserJson(oldPrimaryContact);
                newUserJson = utils.buildUpdateUserJson(newPrimaryContact);
            }
            if (accountDetailsChanged()) {
                accountJson = utils.buildAccountJSON(newAccount, newPrimaryContact.Email, null);
            }
            
            String accountStatus = newAccount.Account_Status__c == 'Active' ? 'Y' : 'N';
            updateAccountFutureCall(oldUserJson, oldUserEmail, newUserJson, accountJson, newAccount.Id,
                                    newAccount.AccountNumber, 
                                    newAccount.Name, 
                                    newAccount.Password__c, 
                                    newPrimaryContact.FirstName, 
                                    newPrimaryContact.LastName,
                                    newPrimaryContact.Email, 
                                    newPrimaryContact.Phone, 
                                    accountStatus, 
                                    newAccount.BillingStreet, 
                                    newAccount.BillingCity, 
                                    newAccount.BillingPostalCode);    
        }
        
    }
    
    // Create the given account in Bushfire
    public static void createAccount(GumtreeUtilsInterface utils, Account account) {

        Contact accountPrimaryContact = utils.getAccountPrimaryContact(account);
        String accountJson = utils.buildAccountJson(account, accountPrimaryContact.Email, null);
        String userJson = utils.buildUpdateUserJson(accountPrimaryContact);
        String accountStatus = 'Y';
        createAccountFutureCall(accountJson,
                                userJson, 
                                account.Id, 
                                account.Name, 
                                account.Password__c, 
                                accountPrimaryContact.FirstName, 
                                accountPrimaryContact.LastName,
                                accountPrimaryContact.Email, 
                                accountPrimaryContact.Phone, 
                                accountStatus, 
                                account.BillingStreet, 
                                account.BillingCity, 
                                account.BillingPostalCode);
    }

    // Get a suitable candidate for use as primary contact
    public static String getSuitablePrimaryContact(Account account) {

        // look for any contacts marked as Primary
        Contact[] contacts = [SELECT Id,Primary_Contact__c,AccountID FROM Contact WHERE Primary_Contact__c=true AND AccountID = :account.Id];
        if (contacts.size() > 0) {
            return contacts[0].id;
        } else {
            // look for financial or other contacts
            if (account.Finance_contact__c != null) {
                return account.Finance_contact__c;
            } else {
                Contact[] other_contacts = [SELECT Id,AccountID FROM Contact WHERE AccountID = :account.Id];
                if (other_contacts.size() > 0) {        
                    return other_contacts[0].id;
                }
            }
        }
        return null;
    }

    /*
     * I know these 2 methods aren't great but there are 3 rules which cause this:
     * 1. You can only pass primitives to a future method
     * 2. You can only make callout's in a future call
     * 3. You cannot call a future method from within a future method
     */
    @future(callout=true)
    private static void updateAccountFutureCall(String oldUserJson, String oldUserEmail, String newUserJson, String accountJson, Id accountId,String accountNumber,String accountName,String password,String contactFirstname,String contactLastname,String contactEmail,String contactPhone,String accountActive,String billingStreet,String billingCity,String billingPostcode) {
        GumtreeAPIInterface api = GumtreeAPI.getGumtreeAPIInstance();

        if (oldUserJson != null) {
            api.updateUser(oldUserJson, oldUserEmail);
            api.updateUser(newUserJson, contactEmail);
        }
        if (accountJson != null) {
            api.updateAccount(accountId, accountJson);
        }
        api.logErrors();
    }
    
    @future(callout=true)
    private static void createAccountFutureCall(String accountJson, String userJson, Id accountId,String accountName,String password,String contactFirstname,String contactLastname,String contactEmail,String contactPhone,String accountActive,String billingStreet,String billingCity,String billingPostcode) {
        GumtreeAPIInterface api = GumtreeAPI.getGumtreeAPIInstance();
        try {
            api.createAccount(accountId, accountJson, userJson, contactEmail);
    
        } catch (GumtreeCalloutException e) {
            //what to do?
    
        }
        api.logErrors();
    }


    /*private String buildUpdateUserJson(Account account) {
        JSONGenerator gen = JSON.createGenerator(true);

        gen.writeStartObject();
        GumtreeUtilsInterface utils = GumtreeUtils.getGumtreeUtilsInterface();
        utils.writeStringFieldToJson(gen, 'first_name', account.Primary_contact__r.FirstName);
        utils.writeStringFieldToJson(gen, 'last_name', account.Primary_contact__r.LastName);
        utils.writeStringFieldToJson(gen, 'contact_phone', account.Primary_contact__r.Phone);
        utils.writeBooleanFieldToJson(gen, 'opt_in_marketing', false);
        
        List<Long> accountNumbers = utils.getAccountNumbers(account.Primary_contact__r);
        utils.writeObjectToJson(gen, 'account_ids', accountNumbers);
        
        gen.writeEndObject();
        
        return gen.getAsString();
    }*/
    
    private String getPrimaryContactEmail(Account account) {
        Account acc_fc = [SELECT Id, Primary_contact__r.Email FROM Account where ID = :account.Id ];
        return acc_fc.Primary_contact__r.Email;
    }
    
    private String getFinanceContactEmail(Account account) {
        Account acc_fc = [SELECT Id, Finance_contact__r.Email FROM Account where ID = :account.Id ];
        return acc_fc.Finance_contact__r.Email;
    }

    /*
     * Can't find a way to load custom relationship data directly from the acc object
     */
    private Account getAccountWithPrimaryContactPopulated(Account account) {
        Account acc_fc = [SELECT Id, 
                         Primary_contact__r.FirstName, 
                         Primary_contact__r.LastName, 
                         Primary_contact__r.Email,
                         Primary_contact__r.Phone
                        FROM Account where ID = :account.Id ];
        return acc_fc;
    }
    
    private Boolean accountDetailsChanged() {
        return newAccount.Name != oldAccount.Name
        || newAccount.Password__c != oldAccount.Password__c
        || newAccount.BillingStreet != oldAccount.BillingStreet
        || newAccount.BillingCity != oldAccount.BillingCity
        || newAccount.BillingPostalCode != oldAccount.BillingPostalCode
        || newAccount.Account_Status__c != oldAccount.Account_Status__c
        || newAccount.UpdateAccount__c != oldAccount.UpdateAccount__c
        || newAccount.Client_Type__c != oldAccount.Client_Type__c
        || newAccount.Account_Migrated__c != oldAccount.Account_Migrated__c;
    }
   
    @istest(SeeAllData=true)  
    public static void testCreateAccount() {
        if (Gumtree_Settings__c.getInstance('Webservice') == null) {
            upsert new Gumtree_Settings__c(Name = 'Webservice', SetupOwnerId=UserInfo.getOrganizationId());
        }
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
        newAccount.Primary_contact__c = primaryContact.Id;
        upsert newAccount;
        Account oldAccount = new Account();
        oldAccount.Name = 'as1';
        oldAccount.Password__c = 'ds';
        oldAccount.BillingStreet = 'ds';
        oldAccount.BillingCity = 'ds';
        oldAccount.BillingCountry = 'GB';
        oldAccount.BillingPostalCode = 'ds';
        oldAccount.Primary_contact__c = primaryContact.Id;
        upsert oldAccount;
        GumtreeUtilsMock utils = new GumtreeUtilsMock();
        utils.addContactToMap(primaryContact, oldAccount);
        utils.addContactToMap(primaryContact, newAccount);
        GumtreeAccountHandler handler = new GumtreeAccountHandler(oldAccount, newAccount, utils);
        handler.updateAccount();
    }
    
    @istest(SeeAllData=true)
    public static void testUpdateAccount() {
        if (Gumtree_Settings__c.getInstance('Webservice') == null) {
            upsert new Gumtree_Settings__c(Name = 'Webservice', SetupOwnerId=UserInfo.getOrganizationId());
        }
        
        Contact primaryContact = new Contact();
        primaryContact.FirstName = 'david';
        primaryContact.LastName = 'david';
        primaryContact.Email = 'davidsmith@gumtree.com';
        primaryContact.Phone = 'david';
        upsert primaryContact;
        
        Account newAccount = new Account();
        newAccount.Name = 'as';
        newAccount.AccountNumber = '123abc';
        newAccount.Password__c = 'ds';
        newAccount.BillingStreet = 'ds';
        newAccount.BillingCity = 'ds';
        newAccount.BillingCountry = 'GB';
        newAccount.BillingPostalCode = 'ds';
        newAccount.Primary_contact__c = primaryContact.Id;
        upsert newAccount;
        
        Account oldAccount = new Account();
        oldAccount.AccountNumber = '123abc';
        oldAccount.Name = 'as1';
        oldAccount.Password__c = 'ds';
        oldAccount.BillingStreet = 'dsold';
        oldAccount.BillingCity = 'ds';
        oldAccount.BillingCountry = 'GB';
        oldAccount.BillingPostalCode = 'ds';
        oldAccount.Primary_contact__c = primaryContact.Id;
        upsert oldAccount;
        
        GumtreeUtilsMock utils = new GumtreeUtilsMock();
        utils.addContactToMap(primaryContact, oldAccount);
        utils.addContactToMap(primaryContact, newAccount);
       
        GumtreeAccountHandler handler = new GumtreeAccountHandler(oldAccount, newAccount, utils);
        handler.updateAccount();
    }
    
    @istest(SeeAllData=true)
    public static void testUpdateAccountNoAccountNumberOpportunityInBooking() {
        if (Gumtree_Settings__c.getInstance('Webservice') == null) {
            upsert new Gumtree_Settings__c(Name = 'Webservice', SetupOwnerId=UserInfo.getOrganizationId());
        }
        if (Config_Settings__c.getAll().get(CustomSettingsManager.OPP_EXPIRY_DATE_TO_CON_TRIG_ENABLED) == null) {
            Config_Settings__c setting = new Config_Settings__c(Name = CustomSettingsManager.OPP_EXPIRY_DATE_TO_CON_TRIG_ENABLED, SetupOwnerId=UserInfo.getOrganizationId());
            System.debug(setting);
            upsert setting;
        }
        
        Contact primaryContact = new Contact();
        primaryContact.FirstName = 'david';
        primaryContact.LastName = 'david';
        primaryContact.Email = 'davidsmith@gumtree.com';
        primaryContact.Phone = 'david';
        upsert primaryContact;
        
        Account newAccount = new Account();
        newAccount.Name = 'as';
        newAccount.AccountNumber = null;
        newAccount.Password__c = 'ds';
        newAccount.BillingStreet = 'ds';
        newAccount.BillingCity = 'ds';
        newAccount.BillingCountry = 'GB';
        newAccount.BillingPostalCode = 'ds';
        newAccount.Primary_contact__c = primaryContact.Id;
        upsert newAccount;
        
        Account oldAccount = new Account();
        oldAccount.AccountNumber = null;
        oldAccount.Name = 'as1';
        oldAccount.Password__c = 'ds';
        oldAccount.BillingStreet = 'dsold';
        oldAccount.BillingCity = 'ds';
        oldAccount.BillingCountry = 'GB';
        oldAccount.BillingPostalCode = 'ds';
        oldAccount.Primary_contact__c = primaryContact.Id;
        upsert oldAccount;
             
        Account subAccount = new Account();
        subAccount.AccountNumber = null;
        subAccount.Name = 'sub account';
        subAccount.Password__c = 'ds';
        subAccount.BillingStreet = 'dsold';
        subAccount.BillingCity = 'ds';
        subAccount.BillingCountry = 'GB';
        subAccount.BillingPostalCode = 'ds';
        subAccount.Primary_contact__c = primaryContact.Id;
        upsert subAccount;
        
        GumtreeUtilsMock utils = new GumtreeUtilsMock();
        utils.addContactToMap(primaryContact, oldAccount);
        utils.addContactToMap(primaryContact, newAccount);
        utils.addContactToMap(primaryContact, subAccount);
        
        Partner accPartner = new Partner(AccountToId = newAccount.Id, AccountFromId = subAccount.Id, Role = 'Advertiser');
        upsert accPartner;
        
        
        Opportunity opp = new Opportunity();
        opp.AccountId = subAccount.Id;
        opp.Name = 'Test Booking Opportunity';
        opp.StageName = 'Booking';
        opp.CloseDate = date.newinstance(2050, 1, 1);
        opp.P_O_Number__c = '123';
        // 2015-05-21 - GTCRM-2028 - SOX controls: Signed contract attached on opportunity level
        opp.Signed_contract_attached__c = true;
        upsert opp;
        
        GumtreeAccountHandler handler = new GumtreeAccountHandler(oldAccount, newAccount, utils);
        handler.updateAccount();
    }
    
    @istest(SeeAllData=true)
    public static void testGetPrimaryContactEmail() {
        Contact primaryContact = new Contact();
        primaryContact.FirstName = 'david';
        primaryContact.LastName = 'david';
        primaryContact.Email = 'davidsmith@gumtree.com';
        primaryContact.Phone = 'david';
        upsert primaryContact;
        Account newAccount = new Account();
        newAccount.Name = 'as';
        newAccount.AccountNumber = '123abc';
        newAccount.Password__c = 'ds';
        newAccount.BillingStreet = 'ds';
        newAccount.BillingCity = 'ds';
        newAccount.BillingCountry = 'GB';
        newAccount.BillingPostalCode = 'ds';
        newAccount.Primary_contact__c = primaryContact.Id;
        upsert newAccount;
        GumtreeAccountHandler handler = new GumtreeAccountHandler(null, newAccount);
        handler.getPrimaryContactEmail(newAccount);
    }
    
    @istest(SeeAllData=true)
    public static void testGetFinanceContactEmail() {
        Contact financeContact = new Contact();
        financeContact.FirstName = 'david';
        financeContact.LastName = 'david';
        financeContact.Email = 'davidsmith@gumtree.com';
        financeContact.Phone = 'david';
        upsert financeContact;
        Account newAccount = new Account();
        newAccount.Name = 'as';
        newAccount.AccountNumber = '123abc';
        newAccount.Password__c = 'ds';
        newAccount.BillingStreet = 'ds';
        newAccount.BillingCity = 'ds';
        newAccount.BillingCountry = 'GB';
        newAccount.BillingPostalCode = 'ds';
        newAccount.Finance_contact__c = financeContact.Id;
        upsert newAccount;
        GumtreeAccountHandler handler = new GumtreeAccountHandler(null, newAccount);
        handler.getFinanceContactEmail(newAccount);
    }
}