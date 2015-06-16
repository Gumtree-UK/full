/**
 * Change log:
 * - CPN 9-Jan-2015: Fix method getAccountPrimaryContact() as it was failing for Account with no contacts
 */
public with sharing class GumtreeUtils implements GumtreeUtilsInterface{
    
    public static GumtreeUtilsInterface getGumtreeUtilsInterface() {
        /*if (Test.isRunningTest()) {
            GumtreeUtilsMock mock = new GumtreeUtilsMock();
            mock.setStatusCode(200);
            return mock;
        }*/
        return new GumtreeUtils();
    }

    public Boolean isAccountMigrated(Account acc) {
        return true;
    }
        
    public Boolean isAccountMigrated(String accountNum) {
        return true;
    }
        
    public Boolean isAccountMigrated(Id accountId) {
        return true;
    }
    
    public GumtreeRemoteInterface remote(Account acc) {
        return new GumtreeAPI();
    }
    
    public GumtreeRemoteInterface remote(String accountId) {
        return new GumtreeAPI();
    }
    
    public Boolean getBooleanFromJson(String key, String jsonContent) {
        Boolean result;
        JSONParser parser = JSON.createParser(jsonContent);
        while (parser.nextToken() != null) {
            if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) && 
                (parser.getText() == key)) {
                parser.nextToken();
                result = parser.getBooleanValue();
            }
        }
        return result;
    }
    
    public String getStringFromJson(String key, String jsonContent) {
        String result = null;
        JSONParser parser = JSON.createParser(jsonContent);
        while (parser.nextToken() != null) {
            if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) && 
                (parser.getText() == key)) {
                parser.nextToken();
                result = parser.getText();
            }
        }
        return result;
    }
    
    /*
     * null handling for writing string fields to json
     */ 
    public void writeStringFieldToJson(JSONGenerator gen, String key, String value) {
        if(value == null) {
            value = '';
        }
        gen.writeStringField(key, value);
        
    }
    
    /*
     * null handling for writing boolean fields to json
     */ 
    public void writeBooleanFieldToJson(JSONGenerator gen, String key, Boolean value) {
        if(value == null) {
            value = false;
        }
        gen.writeBooleanField(key, value);
    }
    
    /*
     * null handling for writing Lists to json
     */ 
    public void writeListToJson(JSONGenerator gen, String key, Object value) {
        if(value == null) {
            gen.writeFieldName(key);
            gen.writeStartArray();
            gen.writeEndArray();
            return;
        }
        gen.writeObjectField(key, value);
    }
    
    /*
     * null handling for writing Objects to json
     */ 
    public void writeObjectToJson(JSONGenerator gen, String key, Object value) {
        if(value == null) {
            return;
        }
        gen.writeObjectField(key, value);
    }
    
    /*
     * Get a list of Account Ids for a particular contact email
     */
    public List<String> getAccountIds(String email) {
        List<String> accountIds = new List<string>();
        List<Account> accounts = getAccounts(email);
        if(null == accounts) {
            return null;
        }
        for (Account account : accounts) {
            if(account.Id != null) {
                accountIds.add(account.Id);
            }
        }
        if(accountIds.size() < 1) {
            return null;
        }
        return accountIds;
    }
    
    /*
     * Get a list of Account Ids for a particular contact
     */
    public List<String> getAccountIds(Contact contactToUpdate) {
        List<String> accountIds = new List<string>();
        List<Account> accounts = getAccounts(contactToUpdate);
        if(null == accounts) {
            return null;
        }
        for (Account account : accounts) {
            if(account.Id != null) {
                accountIds.add(account.Id);
            }
        }
        if(accountIds.size() < 1) {
            return null;
        }
        return accountIds;
    }
    
    /*
     * Get a list of Account Numbers for a particular contact
     */
    public List<Long> getAccountNumbers(Contact contactToUpdate) {
        List<Long> accountNumbers = new List<Long>();
        List<Account> accounts = getAccounts(contactToUpdate);
        if(null == accounts) {
            return null;
        }
        for (Account account : accounts) {
            if(account.AccountNumber != null) {
                accountNumbers.add(Long.valueOf(account.AccountNumber));
            }
        }
        if(accountNumbers.size() < 1) {
            return null;
        }
        return accountNumbers;
    }
    
    /*
     * Get a list of Account for a particular contact email
     */
    public List<Account> getAccounts(Contact contactToUpdate) {
        return getAccounts(contactToUpdate.Email);
    }
    
    /*
     * Get a list of Account for a particular contact
     */
    public List<Account> getAccounts(String email) {
        if(email == null || email == '') {
            return null;
        }
        List<String> accountIds = new List<string>();
        //This will be implemented when all users are migrated to bushfire so we can start using a many-to-many relationship properly
        /*List<Contact> contacts = [SELECT AccountId FROM Contact WHERE Email = :contactToUpdate.Email];
        for (Contact contact : contacts) {
            if(contact.AccountId != null) {
                accountIds.add(contact.AccountId);
            }
        }*/
        //This is here because we have to use primary contact for now and have a one-to-many relationship for user-account§
        List<Account> accounts = [SELECT Id, AccountNumber, Account_Migrated__c FROM Account WHERE Primary_contact__r.Email = :email];
        return accounts;
    }

    public String buildUpdateUserJson(Contact primaryContact) {
        JSONGenerator gen = JSON.createGenerator(true);

        gen.writeStartObject();
        GumtreeUtilsInterface utils = GumtreeUtils.getGumtreeUtilsInterface();
        utils.writeStringFieldToJson(gen, 'first_name', primaryContact.FirstName);
        utils.writeStringFieldToJson(gen, 'last_name', primaryContact.LastName);
        utils.writeStringFieldToJson(gen, 'phone', primaryContact.Phone);
        utils.writeBooleanFieldToJson(gen, 'opt_in_marketing', false);
        
        List<Long> accountNumbers = utils.getAccountNumbers(primaryContact);
        utils.writeListToJson(gen, 'account_ids', accountNumbers);
        
        gen.writeEndObject();
        
        return gen.getAsString();
    }
    
    /*
     * Get the primary contact details for an account.  This can be used if the account is the trigger.old account
     */
    public Contact getAccountPrimaryContact(Account account) {
        List<Contact> contacts = [SELECT Id, 
                         FirstName, 
                         LastName, 
                         Email,
                         Phone
                        FROM Contact where ID = :account.Primary_contact__c ];
        if(!contacts.isEmpty()) return contacts[0];
        return null;
    }
    
    public String buildAccountJSON(Account account, String primaryContactEmail, String financeContactEmail) {
        JSONGenerator gen = JSON.createGenerator(true);
        
        gen.writeStartObject(); 
        writeStringFieldToJson(gen, 'id', account.AccountNumber);
        writeStringFieldToJson(gen, 'name', account.Name);
        writeStringFieldToJson(gen, 'description', 'Salesforce Account');
        writeStringFieldToJson(gen, 'address1', account.BillingStreet);
        writeStringFieldToJson(gen, 'postcode', account.BillingPostalCode);
        writeStringFieldToJson(gen, 'city', account.BillingCity);
        writeStringFieldToJson(gen, 'county', account.BillingState);
        writeStringFieldToJson(gen, 'country', account.BillingCountry);
        writeStringFieldToJson(gen, 'account_status', getBushfireAccountStatus(account));
        gen.writeBooleanField('pro', true);
        if (primaryContactEmail != null) {
            writeStringFieldToJson(gen, 'primary_email', primaryContactEmail);
        }
        if (financeContactEmail != null) {
            writeStringFieldToJson(gen, 'finance_email', financeContactEmail);
        }
        if ('Estate Agent'.equals(account.Client_Type__c) || 'Commercial Agent'.equals(account.Client_Type__c)) {
            gen.writeBooleanField('force_post_as_agency', true);
        }
        gen.writeEndObject();
        
        return gen.getAsString();
    }   
    
    private String getBushfireAccountStatus(Account account) {
        String status = account.Account_Status__c;
        if (status == 'Suspended - Bad Debt') {
            return 'SUSPENDED';
        }
        if (status == 'Closed') {
            return 'CLOSED';
        }
        if (status == 'Collection Agency') {
            return 'COLLECTION_AGENCY';
        }
        return 'ACTIVE';
    }   

    public String buildPackageJSON(String userId,String salesforceId,String salesforceCode,Date startDate,Date endDate,Integer initialCredits,Integer adjustedCredits) {
        JSONGenerator gen = JSON.createGenerator(true);
        
        gen.writeStartObject();     
        writeStringFieldToJson(gen, 'account_id', userId);
        writeStringFieldToJson(gen, 'salesforce_product_id', salesforceCode);
        writeStringFieldToJson(gen, 'salesforce_id', salesforceId);
        gen.writeDateField('start_date', startDate);
        gen.writeDateField('end_date', endDate);
        gen.writeNumberField('initial_credits', initialCredits);
        gen.writeNumberField('adjusted_credits', adjustedCredits);
        gen.writeEndObject();
        
        return gen.getAsString();
    }
    
    static testmethod void testUtils() {
        GumtreeUtilsInterface utils = new GumtreeUtils();
        Account acct1 = new Account();
        acct1.Name = 'foobar';
        acct1.Account_Migrated__c = true;
        acct1.AccountNumber = '123458';
        acct1.BillingStreet = 'abc';
        acct1.BillingCity = 'abc';
        acct1.BillingCountry ='GB';
        acct1.BillingPostalCode = 'abc';
        insert acct1;       
        System.assert(utils.isAccountMigrated(acct1));
        System.assertEquals(utils.remote(acct1) instanceof GumtreeAPI, true);
    }
    
    static testmethod void testGetInstance() {
        //for improved coverage
        GumtreeUtils.getGumtreeUtilsInterface();
    }
    
    static testmethod void testGetBooleanFromJson() {
        String json = '{"boolkey":true}';
        GumtreeUtils utils = new GumtreeUtils();
        Boolean result = utils.getBooleanFromJson('boolkey', json);
        System.assertEquals(true, result);
    }
    
    static testmethod void testGetStringFromJson() {
        String json = '{"stringkey":"test string"}';
        GumtreeUtils utils = new GumtreeUtils();
        String result = utils.getStringFromJson('stringkey', json);
        System.assertEquals('test string', result);
    }
    
    static testmethod void testWriteStringFieldToJson() {
        
        GumtreeUtils utils = new GumtreeUtils();
        
        JSONGenerator gen = JSON.createGenerator(true);
        gen.writeStartObject(); 
        utils.writeStringFieldToJson(gen, 'id', 'testId');
        utils.writeStringFieldToJson(gen, 'nullkey', null);
        gen.writeEndObject();
        String result = gen.getAsString();
        result = result.replaceAll('\n', '').replaceAll('\r', '').replaceAll(' ','');
        
        System.assertEquals('{"id":"testId","nullkey":""}', result);
    }
    
    static testmethod void testWriteBooleanFieldToJson() {
        
        GumtreeUtils utils = new GumtreeUtils();
        
        JSONGenerator gen = JSON.createGenerator(true);
        gen.writeStartObject(); 
        utils.writeBooleanFieldToJson(gen, 'id', true);
        utils.writeBooleanFieldToJson(gen, 'nullkey', null);
        gen.writeEndObject();
        String result = gen.getAsString();
        result = result.replaceAll('\n', '').replaceAll('\r', '').replaceAll(' ','');
        
        System.assertEquals('{"id":true,"nullkey":false}', result);
    }
    
    static testmethod void testWriteListFieldToJson() {
        
        List<String> strings = new List<String>();
        strings.add('hello');
        strings.add('there');
        
        GumtreeUtils utils = new GumtreeUtils();
        
        JSONGenerator gen = JSON.createGenerator(true);
        gen.writeStartObject(); 
        utils.writeObjectToJson(gen, 'strings', strings);
        utils.writeObjectToJson(gen, 'nullkey', null);
        gen.writeEndObject();
        String result = gen.getAsString();
        result = result.replaceAll('\n', '').replaceAll('\r', '').replaceAll(' ','');
        
        System.assertEquals('{"strings":["hello","there"]}', result);
    }
    
    static testmethod void testWriteObjectFieldToJson() {
        
        List<String> strings = new List<String>();
        strings.add('hello');
        strings.add('there');
        
        GumtreeUtils utils = new GumtreeUtils();
        
        JSONGenerator gen = JSON.createGenerator(true);
        gen.writeStartObject(); 
        utils.writeObjectToJson(gen, 'strings', strings);
        utils.writeObjectToJson(gen, 'nullkey', null);
        gen.writeEndObject();
        String result = gen.getAsString();
        result = result.replaceAll('\n', '').replaceAll('\r', '').replaceAll(' ','');
        
        System.assertEquals('{"strings":["hello","there"]}', result);
    }
    
    static testMethod void testGetAccountIds() {
        Contact primaryContact = new Contact();
        primaryContact.FirstName = 'david';
        primaryContact.LastName = 'david';
        primaryContact.Email = 'davidsmithGU@gumtree.com';
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
        
        GumtreeUtils utils = new GumtreeUtils();
        List<String> accountIds = utils.getAccountIds(primaryContact);
        
        System.assertEquals(1, accountIds.size());
        System.assertEquals(newAccount.Id, accountIds.get(0));
        
        accountIds = utils.getAccountIds(primaryContact.Email);
        
        System.assertEquals(1, accountIds.size());
        System.assertEquals(newAccount.Id, accountIds.get(0));
    }
    
    static testMethod void testGetAccountIdsNoEmail() {
        Contact primaryContact = new Contact();
        primaryContact.FirstName = 'david';
        primaryContact.LastName = 'david';
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
        
        GumtreeUtils utils = new GumtreeUtils();
        List<String> accountIds = utils.getAccountIds(primaryContact);
        
        System.assertEquals(null, accountIds);
    }
}