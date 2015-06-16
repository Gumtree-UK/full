/**

Change log:
- 2014-04-08 - GTCRM-884 - Remove error log on successful messages
- 2015-04-29 - GTCRM-1924 - Modified Enhance API error logs with greater detail BY Cheasarat 
- 2015-05-06 - fixed: System.CalloutException: You have uncommitted work pending. Please commit or rollback before calling out

**/

public with sharing class GumtreeAPI implements GumtreeRemoteInterface, GumtreeAPIInterface {

    public static String  APIHOST    = Gumtree_Settings__c.getInstance('Webservice').Endpoint__c;
    public static String  ACCESSKEY  = Gumtree_Settings__c.getInstance('Webservice').AccessKey__c;
    public static String  PRIVATEKEY = Gumtree_Settings__c.getInstance('Webservice').PrivateKey__c;
    //public static Integer TIMEOUT    = 5000;
    public static Integer TIMEOUT    = 120000;//TH: 26-02-2014: resolved time out GumtreeAPI.TIMEOUT
    private GumtreeUtilsInterface utils;
    private APIRequestInterface request;
    private static List<ErrorLog__c> errors = new List<ErrorLog__c>();
    
    public GumtreeAPI() {
        this.utils = GumtreeUtils.getGumtreeUtilsInterface();
        this.request = APIRequestImpl.getAPIRequestInstance();
        System.debug('instantiate gapi');
    }
    
    public GumtreeAPI(GumtreeUtilsInterface utils, APIRequestInterface request) {
        this.utils = utils;
        this.request = request;
    }

    public GumtreeUtilsInterface getUtils() {
        return utils;
    }
    
  
    
    public void assignPackages(String packagesJson, String accountId) {
        String url = '/api/packages/batch';
        HttpResponse response = request.sendRequest('POST', url, packagesJson);
        
        String  exceptionMessage = '';
        String status = SUCCESS_STATUS;
        if( response.getStatusCode() != 201 ){
        	  exceptionMessage = response.toString() + ' ' + response.getBody() ;
        	  status = ERROR_STATUS;
        }
         errors.add( futureCreateErrorLog.createErrorLog( exceptionMessage , accountId , 'assignPackages'  , CREATE_ACTION ,  status  , COMPLETED , GUMTREE) );   
         
       /* if (response.getStatusCode() == 201) {
            //addErrorRecord('Created/Updated packages on Gumtree', accountId, 'assignPackages');  
        }
        else {
            futureCreateErrorLog.createErrorRecord(response.toString() + ' ' + response.getBody(), accountId, 'assignPackagesError');
        }
        */
        
        
    }

    public void assignPackage(Id accountId,String salesforceId,String salesforceCode,Date startDate,Date endDate,Integer initialCredits,Integer adjustedCredits) {
        GumtreeAPI.assignPackageCallout(accountId, salesforceId, salesforceCode, startDate, endDate, initialCredits, adjustedCredits);
    }
    
     private static void assignPackageCallout(Id accountId,String salesforceId,String salesforceCode,Date startDate,Date endDate,Integer initialCredits,Integer adjustedCredits) {
        If(BatchAutoRenewal.fromBatch){
            assignPackageCalloutProcess(accountId,salesforceId,salesforceCode, startDate, endDate, initialCredits, adjustedCredits);
            
        }else{
            assignPackageCalloutReal(accountId,salesforceId,salesforceCode, startDate, endDate, initialCredits, adjustedCredits) ;
        }
        
 }
 
 	private static final String CREATE_ACTION='Create';
 	private static final String COMPLETED='Completed';
 	private static final String GUMTREE='Gumtree';
 	private static final String SUCCESS_STATUS='Success';
 	private static final String ERROR_STATUS='Error';
 	private static final String DELETE_ACTION='Delete';
 	private static final String UPDATE_ACTION='Update';
 	
	 
     private static void assignPackageCalloutProcess(Id accountId,String salesforceId,String salesforceCode,Date startDate,Date endDate,Integer initialCredits,Integer adjustedCredits) {
        GumtreeAPI api = new GumtreeAPI();
        
        Account account = [SELECT Id, AccountNumber, Name, Description, BillingStreet, Primary_Contact__c, 
                            BillingPostalCode, BillingCity, BillingState, BillingCountry, Account_Status__c 
                            FROM Account WHERE Id = :accountId];
        if (account.AccountNumber == null || account.AccountNumber == '') {
            api.createAccountAndAssignPackages(account, salesforceId, salesforceCode, startDate, endDate, initialCredits, adjustedCredits);         
        } else {
            String json = api.getUtils().buildPackageJSON(account.AccountNumber, salesforceId, salesforceCode, startDate, endDate, initialCredits, adjustedCredits);
            APIRequestInterface request = APIRequestImpl.getAPIRequestInstance();
            String url = '/api/packages';
            HttpResponse response = request.sendRequest('POST', url, json);
            
            String  exceptionMessage = '';
	        String status = SUCCESS_STATUS;
	        if( response.getStatusCode() != 201 ){
	        	  exceptionMessage = response.toString() + ' ' + response.getBody() ;
	        	  status = ERROR_STATUS;
	        }
	         errors.add( futureCreateErrorLog.createErrorLog( exceptionMessage , salesforceId , 'assignPackage'  , CREATE_ACTION ,  status  , COMPLETED , GUMTREE));   
         
           /* if (response.getStatusCode() == 201) {
                //futureCreateErrorLog.createErrorRecord('Created/Updated package on Gumtree', salesforceId, 'assignPackage');            
            }
            else {
                futureCreateErrorLog.createErrorRecord(response.toString() + ' ' + response.getBody(), salesforceId, 'assignPackageError');
            }
            */
            
        }
     }
    @future(callout = true)
    public static void assignPackageCalloutReal(Id accountId,String salesforceId,String salesforceCode,Date startDate,Date endDate,Integer initialCredits,Integer adjustedCredits) {
        assignPackageCalloutProcess(accountId, salesforceId, salesforceCode, startDate, endDate, initialCredits, adjustedCredits) ;
    }
    
    public void createAccountAndAssignPackages(Account account,String salesforceId,String salesforceCode,Date startDate,Date endDate,Integer initialCredits,Integer adjustedCredits) {
        
        Contact primaryContact = utils.getAccountPrimaryContact(account);
        String accountJson = utils.buildAccountJson(account, primaryContact.Email, null);
        String userJson = utils.buildUpdateUserJson(primaryContact);
        
        HttpResponse response = request.sendRequest('POST', '/api/accounts', accountJson);
        if (response.getStatusCode() == 201 ) {
        	errors.add( futureCreateErrorLog.createErrorLog( '' , account.Id , 'createAccount'  , CREATE_ACTION ,  SUCCESS_STATUS  , COMPLETED , GUMTREE));
        	
            String accountNumber = utils.getStringFromJson('id', response.getBody());
            
            userJson = addAccountToUserJson(userJson, accountNumber);
            
            String url = '/api/users/' + primaryContact.Email + '/email';
            HttpResponse userResponse = request.sendRequest('PUT', url, userJson);

            if (userResponse.getStatusCode() == 200) {
                url = '/api/packages';
                String packageJson = utils.buildPackageJSON(accountNumber, salesforceId, salesforceCode, startDate, endDate, initialCredits, adjustedCredits);                              
                HttpResponse packageResponse = request.sendRequest('POST', url, packageJson);

                if (packageResponse.getStatusCode() == 201) {
                    //futureCreateErrorLog.createErrorRecord('DM - Created Account on Bushfire:' + accountJson, account.Id, 'updateAccount');
                    //futureCreateErrorLog.createErrorRecord('DM - Updated User on Gumtree:' + userJson, null, 'updateUser');
                    //futureCreateErrorLog.createErrorRecord('DM - Created/Updated package on Gumtree', salesforceId, 'assignPackage');   
                    errors.add( futureCreateErrorLog.createErrorLog( '' , salesforceId  , 'assignPackage'  , CREATE_ACTION ,  SUCCESS_STATUS  , COMPLETED , GUMTREE));
                                                
                } else {
                    //futureCreateErrorLog.createErrorRecord(packageResponse.toString() + ' ' + response.getBody() + ' :: ' + accountNumber, , 'assignPackageError');
                    errors.add( futureCreateErrorLog.createErrorLog( packageResponse.toString() + ' ' + response.getBody()  , salesforceId  , 'assignPackage'  , CREATE_ACTION ,  ERROR_STATUS  , COMPLETED , GUMTREE));
                    
                }                               
            } else {
            	
            	 errors.add( futureCreateErrorLog.createErrorLog( userResponse.getBody() , primaryContact.Email  , 'updateUser'  , UPDATE_ACTION ,  ERROR_STATUS  , COMPLETED , GUMTREE));
                //futureCreateErrorLog.createErrorRecord('Failed to update User on Gumtree: '+userResponse.getBody() + 'json:' + userJson, primaryContact.Email, 'updateUserError');
                sendGumtreeAPIErrorEmail('Failed to update User on Gumtree', 'Failed to update User on Gumtree: '+userResponse.getBody() + '\n' + userJson);                
            }
            
            updateAccountNumberAndMarkAsMigrated(account.Id, accountNumber);            
        } else {
            
            //futureCreateErrorLog.createErrorRecord('Failed to create Account on Bushfire: '+response.getBody(), account.Id, 'createAccountError');
             errors.add( futureCreateErrorLog.createErrorLog( response.getBody() , account.Id , 'createAccount'  , CREATE_ACTION ,  ERROR_STATUS  , COMPLETED , GUMTREE));
            sendGumtreeAPIErrorEmail('Failed to create Account on Bushfire', 'Failed to create Account on Bushfire: '+response.getBody() + '\n' + accountJson);
            
        }
        
               
    }
    
    public void deletePackage(String salesforceId) { 
        GumtreeAPI.deletePackageCallout(salesforceId);
    }
    
    /* Created by Bunhor @29-Sep-2014
     * This method will be called from Batch (since Future/Batch can not call futured method)
     */
    public static void deletePackageNotFuture(String salesforceId) {  
        GumtreeAPI api = new GumtreeAPI();
        APIRequestInterface request = APIRequestImpl.getAPIRequestInstance();
        String url = '/api/packages/'+salesforceId;
        HttpResponse response = request.sendRequest('DELETE', url, null);
        System.debug('----------------response------------'+response);
       
       /* if (response.getStatusCode() == 204 ) {
            //futureCreateErrorLog.createErrorRecord('Deleted package on Gumtree', salesforceId, 'deletePackage');
        } else {
            futureCreateErrorLog.createErrorRecord('Failed to delete package on Gumtree: '+response.getBody(), salesforceId, 'deletePackageError');
        }*/
        
        String  exceptionMessage = '';
	    String status = SUCCESS_STATUS;
	    if( response.getStatusCode() != 204 ){
	        exceptionMessage = response.getBody() ;
	        status = 'Error';
	    }
	    errors.add( futureCreateErrorLog.createErrorLog( exceptionMessage , salesforceId , 'deletePackage'  , DELETE_ACTION ,  status  , COMPLETED , GUMTREE));
    }
    
    @future(callout = true) 
    public static void deletePackageCallout(String salesforceId) {
    	GumtreeAPI.deletePackageNotFuture(salesforceId);   
    }
    
    public void createAccount(Id accountId, String accountJson, String userJson, String email) {
        String url = '/api/accounts';
        HttpResponse response = request.sendRequest('POST', url, accountJson);
        
        String  exceptionMessage = '';
	     String status = SUCCESS_STATUS;
	      if( response.getStatusCode() != 201 ){
	        	  exceptionMessage = response.getBody() ;
	        	  status = 'Error';
	      }
	     errors.add( futureCreateErrorLog.createErrorLog( exceptionMessage , accountId , 'createAccount'  , CREATE_ACTION ,  status  , COMPLETED , GUMTREE));
        
        if (response.getStatusCode() == 201 ) {
            String accountNumber = utils.getStringFromJson('id', response.getBody());
            userJson = addAccountToUserJson(userJson, accountNumber);
            updateUser(userJson, email);
            updateAccountNumberAndMarkAsMigrated(accountId, accountNumber);
            //addErrorRecord('Created Account on Bushfire:' + accountJson, accountId, 'createAccount');
        } else {
            //futureCreateErrorLog.createErrorRecord('Failed to create Account on Bushfire: '+response.getBody(), accountId, 'createAccountError');
            sendGumtreeAPIErrorEmail('Failed to create Account on Bushfire', 'Failed to create Account on Bushfire: '+response.getBody() + '\n' + accountJson);
            throw new GumtreeCalloutException('Failed to create Account on Bushfire');
        }
    }
    
    /**
     * Needed if you want to do more callouts after creating account
     */
    public String createAccountWithoutUpdatingSalesforce(Id accountId, String accountJson, String userJson, String email) {
        String url = '/api/accounts';
        HttpResponse response = request.sendRequest('POST', url, accountJson);
        
         String  exceptionMessage = '';
	     String status = SUCCESS_STATUS;
	      if( response.getStatusCode() != 201 ){
	        	  exceptionMessage = response.getBody() ;
	        	  status = ERROR_STATUS;
	      }
	     errors.add( futureCreateErrorLog.createErrorLog( exceptionMessage , accountId , 'createAccount'  , CREATE_ACTION ,  status  , COMPLETED , GUMTREE));
        
        if (response.getStatusCode() == 201 ) {
            String accountNumber = utils.getStringFromJson('id', response.getBody());
            userJson = addAccountToUserJson(userJson, accountNumber);
            updateUser(userJson, email);
            //addErrorRecord('Created Account on Bushfire:' + accountJson, accountId, 'createAccount');
            return accountNumber;
        } else {
            
            //futureCreateErrorLog.createErrorRecord('Failed to create Account on Bushfire: '+response.getBody(), accountId, 'createAccountError');
            sendGumtreeAPIErrorEmail('Failed to create Account on Bushfire', 'Failed to create Account on Bushfire: '+response.getBody() + '\n' + accountJson);
            throw new GumtreeCalloutException('Failed to create Account on Bushfire');
        }
        
         
	       
    }
    
    public void updateAccount(Id accountId, String accountJson) {
        String AccountNumber = utils.getStringFromJson('id', accountJson);
        String url = '/api/accounts/' + accountNumber;
        HttpResponse response = request.sendRequest('PUT', url, accountJson);
        
        String  exceptionMessage = '';
	    String status = SUCCESS_STATUS;
        if (response.getStatusCode() == 200 ) {
            //addErrorRecord('Updated Account on Bushfire:' + accountJson, accountId, 'updateAccount');
        } else {
        	exceptionMessage =  response.getBody() ;
	        status = ERROR_STATUS;
            System.debug('---------------->> ELSE <<------------------');
           // futureCreateErrorLog.createErrorRecord('Failed to update Account on Bushfire: '+response.getBody(), accountId, 'updateAccountError');
            sendGumtreeAPIErrorEmail('Failed to update Account on Bushfire', 'Failed to update Account on Bushfire: '+response.getBody() + '\n' + accountJson);
        }
          
	   errors.add( futureCreateErrorLog.createErrorLog( exceptionMessage , accountId , 'updateAccount'  , UPDATE_ACTION ,  status  , COMPLETED , GUMTREE));   
    }
    
    public void updateUser(String userJson, String email) {        
        String url = '/api/users/' + email + '/email';
        HttpResponse response = request.sendRequest('PUT', url, userJson);
        
         String  exceptionMessage = '';
	     String status = SUCCESS_STATUS;
        if (response.getStatusCode() == 200 ) {
            //addErrorRecord('Updated User on Gumtree:' + userJson, null, 'updateUser');
        } else {
        	exceptionMessage = response.getBody() ;
	        status = ERROR_STATUS;
            //futureCreateErrorLog.createErrorRecord('Failed to update User on Gumtree: '+response.getBody() + 'json:' + userJson, email, 'updateUserError');
            sendGumtreeAPIErrorEmail('Failed to update User on Gumtree', 'Failed to update User on Gumtree: '+response.getBody() + '\n' + userJson);
        }
	    errors.add( futureCreateErrorLog.createErrorLog( exceptionMessage , email , 'updateUser'  , UPDATE_ACTION ,  status  , COMPLETED , GUMTREE));   
    }
    
    //This is not a very nice way of doing things but the apex json parser isn't very nice so much easier to do with this string matching
    public String addAccountToUserJson(String userJson, String accountNumber) {
        System.debug(userJson);
        if(userJson.contains('"account_ids" : [ ]')) {
            userJson = userJson.replace('"account_ids" : [ ]', '"account_ids" : [' + accountNumber + ']');
        }else {
            userJson = userJson.replace(']', ',' + accountNumber + ']');
        }
        return userJson;
    }
    
    public void updateAccountNumberAndMarkAsMigrated(Id accountId, String accountNumber) {
        Account account = [SELECT AccountNumber FROM Account WHERE Id = :accountId];
        if (account != null) {
            account.AccountNumber = accountNumber;
            account.Account_Migrated__c = true;
            update account;
        }
    }
    
    public GumtreeUserType getUserType(String email) {
        String url = '/api/emails/' + email + '/user';
        HttpResponse response = request.sendRequest('GET', url, null);
        boolean isBushfireUser = false;
        if (response.getStatusCode() == 200 ) {
            isBushfireUser = utils.getBooleanFromJson('in_bushfire', response.getBody());
            if (isBushfireUser) {
                return GumtreeUserType.BUSHFIRE;
            }else {
                return GumtreeUserType.LEGACY;
            }
        }
        return GumtreeUserType.NONE;
    }
    
    public String getBushfireUserJson(String email) {
        String url = '/api/emails/' + email + '/user';
        HttpResponse response = request.sendRequest('GET', url, null);
        if (response.getStatusCode() == 200 ) {
            return response.getBody();
        }
        return null;
    }
    
    public void updateUsedCredits(String accountId){
        GumtreeAPI.updateUsedCreditsCallout(accountId);
    }
    
    // This is only currently used by a future method, which cannot call other future methods, so no need to make this @future
    public static void updateUsedCreditsCallout(String accountId){
        APIRequestInterface request = APIRequestImpl.getAPIRequestInstance();
        String url = '/api/accounts/'+accountId+'/packages';
        HttpResponse response = request.sendRequest('GET', url, null);
        
         String  exceptionMessage = '';
	     String status = SUCCESS_STATUS;
        if (response.getStatusCode() == 200){
            GumtreeCreditPackages packages = (GumtreeCreditPackages)JSON.deserialize(response.getBody(), GumtreeCreditPackages.class);
            processUsedCredits(packages.packages);
            system.debug('packages========'+packages.packages);
            //futureCreateErrorLog.createErrorRecord('Successfully updated credit packages from Gumtree', accountId, 'updatePackage');
        } else {
        	 exceptionMessage =  response.getBody() ;
	         status = ERROR_STATUS;
            //futureCreateErrorLog.createErrorRecord('Failed to return package details from Gumtree: '+response.getBody(), accountId, 'updatePackageError');
        }  
        
         
	   errors.add( futureCreateErrorLog.createErrorLog( exceptionMessage , accountId , 'updatePackage'  , UPDATE_ACTION ,  status  , COMPLETED , GUMTREE));               
    }
    
    private static void processUsedCredits(List<GumtreeCreditPackage> packages){
        if (packages != null) {
            //Th 24-02-2014 fixed Too many SOQL queries: 201
            Map<Id,GumtreeCreditPackage>  mapcreditPackage= new Map<Id,GumtreeCreditPackage>();
            list<OpportunityLineItem> lstOpliUpdate=new list<OpportunityLineItem>();
            for (GumtreeCreditPackage updatedPackage : packages) {
                Date endDate = Date.valueOf(updatedPackage.end_date);
                // only update line items that are active or expired in the last 3 months
                if (endDate < Date.today().addMonths(-3)) {
                    continue;
                }
                mapcreditPackage.put(updatedPackage.salesforce_id,updatedPackage);
               /* OpportunityLineItem[] oli = [SELECT id, Credits_remaining__c FROM OpportunityLineItem WHERE id = :updatedPackage.salesforce_id];
                if (oli.size() == 0) continue;
                oli[0].Credits_used__c = updatedPackage.used_credits;
                update oli[0]; */
            }
           //NK:07/03/2014  (optimized)
            for(OpportunityLineItem opli:[SELECT id, Credits_remaining__c FROM OpportunityLineItem WHERE ID IN: mapcreditPackage.keySet()]){
                opli.Credits_used__c = mapcreditPackage.get((opli.Id+'')).used_credits;
                lstOpliUpdate.add(opli);
                 
            }
            if(!lstOpliUpdate.IsEmpty()) update lstOpliUpdate;
        }       
    }
    
    private void addErrorRecord(string exceptionMessage, string Id, string Origin){
         ErrorLog__c newErrorRecord = new ErrorLog__c();
         newErrorRecord.details__c = exceptionMessage;
         newErrorRecord.Related_Id__c = Id;
         newErrorRecord.Type__c = Origin;
         errors.add(newErrorRecord);
    }
    
    public void logErrors() {
        for (ErrorLog__c error : errors) {
            Database.insert(error,false);
        }
    }
    
    private static void sendGumtreeAPIErrorEmail(String subject, String body) {
        String adminUser = 'oblackwood@gumtree.com';
        EmailSender sender = new EmailSender();
        sender.subject(subject)
                .body(body)
                .includeCurrentUser()
                .addRecipient(adminUser)
                .send();
    }
    
    public static GumtreeAPIInterface getGumtreeAPIInstance() {
        System.debug('getGumtreeAPIInstance');
        if (Test.isRunningTest()) {
            GumtreeAPIMock mock = new GumtreeAPIMock();
            return mock;
        }
        return new GumtreeAPI();
    }    
    
    static testmethod void testApiCalls() {
        ID userId = '00300000003T2PGAA0';
        String salesforceCode = 'abcdef';
        String salesforceId  = 'deadbeef';
        Date startDate = Date.valueOf('2010-01-01 00:00:00');
        Date endDate = Date.valueOf('2011-01-01 00:00:00');
        Integer initialCredits = 100;
        Integer adjustedCredits = 0;
        
        String accountName = 'foo';
        String accountNumber = '11111111';
        String password;
        String contactFirstname;
        String contactLastname;
        String contactEmail;
        String contactPhone;
        String accountActive;
        String billingStreet;
        String billingCity;
        String billingPostcode;
        
        GumtreeUtils utils = new GumtreeUtils();
        APIRequestMock request = new APIRequestMock();
        request.setStatusCode(201);
        request.setBody('12');
        GumtreeAPI api = new GumtreeAPI(utils, request);
        
        Account newAccount = setupAccount();
        
        api.assignPackage(newAccount.Id, salesforceCode, salesforceId, startDate, endDate, initialCredits, adjustedCredits);
        
        api.updateUsedCredits('1');
        
        api.deletePackage(newAccount.Id);    
        
        api.createAccountAndAssignPackages(newAccount, salesforceId, salesforceCode, startDate, endDate, initialCredits, adjustedCredits);
        
        String userJson = '{json}';
        String accountJson = '{json}';
        String email = 'david.smith@gumtree.com.test';
        api.createAccountWithoutUpdatingSalesforce(newAccount.Id, accountJson, userJson, email);
        
        
        newAccount.AccountNumber = 'testaccno';
        upsert newAccount;
        
        api.assignPackage(newAccount.Id, salesforceCode, salesforceId, startDate, endDate, initialCredits, adjustedCredits);
    }
    
    static testmethod void testCreateAccount() {
        
        Account newAccount = setupAccount();
        
        GumtreeUtilsMock utils = new GumtreeUtilsMock();
        APIRequestMock request = new APIRequestMock();
        request.setStatusCode(201);
        request.setBody('12');
        GumtreeAPI api = new GumtreeAPI(utils, request);
        String accountJson = '';
        String userJson = '';
        api.createAccount(newAccount.Id, accountJson, userJson, newAccount.Primary_contact__r.Email);
        
        Boolean errorThrown = false;
        request.setStatusCode(500);
        try {
            api.createAccount(newAccount.Id, accountJson, userJson, newAccount.Primary_contact__r.Email);
        }catch (GumtreeCalloutException e) {
            errorThrown = true;
        }
        System.assert(errorThrown);
    }
    
    static testmethod void testUpdateUser() {
        GumtreeUtilsMock utils = new GumtreeUtilsMock();
        APIRequestMock request = new APIRequestMock();
        request.setStatusCode(200);
        GumtreeAPI api = new GumtreeAPI(utils, request);
        String UserJson = '';
        api.updateUser(userJson, '1');
        
        request.setStatusCode(500);
        api.updateUser(userJson, '1');
    }
    
    static testmethod void testGetUserType() {
        GumtreeUtilsMock utils = new GumtreeUtilsMock();
        APIRequestMock request = new APIRequestMock();
        request.setStatusCode(200);
        request.setBody('{in_bushfire : true}');
        utils.setBoolFromJson(true);
        GumtreeAPI api = new GumtreeAPI(utils, request);
        
        GumtreeUserType result = api.getUserType('email');
        System.assertEquals(GumtreeUserType.BUSHFIRE, result);
        
        utils.setBoolFromJson(false);
        request.setStatusCode(404);
        result = api.getUserType('email');
        System.assertEquals(GumtreeUserType.NONE, result);
    }
    
    static testmethod void testGetBushfireUser() {
        GumtreeUtilsMock utils = new GumtreeUtilsMock();
        APIRequestMock request = new APIRequestMock();
        request.setStatusCode(200);
        request.setBody('bushfire user');
        utils.setBoolFromJson(true);
        GumtreeAPI api = new GumtreeAPI(utils, request);
        
        String result = api.getBushfireUserJson('email');
        System.assertEquals('bushfire user', result);
        
        utils.setBoolFromJson(false);
        request.setStatusCode(500);
        result = api.getBushfireUserJson('email');
        System.assertEquals(null, result);
    } 
    
    static testmethod void testProcessUsedCredits() {
        GumtreeCreditPackage creditPackage = new GumtreeCreditPackage(20, 21, 3, 'String sfId', '2012-02-01', '2012-03-05',
            1, 1, 1, 'String name', false );
        List<GumtreeCreditPackage> packages = new List<GumtreeCreditPackage>();
        packages.add(creditPackage);
        GumtreeApi.processUsedCredits(packages);
    }
    
    static testMethod void testGetGumtreeAPIInstance() {
        //just for coverage
        GumtreeAPI.getGumtreeAPIInstance();
    }
    
    static testmethod void testAssignPackages() {
        GumtreeUtilsMock utils = new GumtreeUtilsMock();
        APIRequestMock request = new APIRequestMock();
        GumtreeAPI api = new GumtreeAPI(utils, request);
        
        String packagesJson = 'json';
        String accountId = '123';
        api.assignPackages(packagesJson, accountId);
        request.verifySendRequest(1);
        
        request.setStatusCode(500);
    }
    
    static testmethod Account setupAccount() {
        
        Contact primaryContact = new Contact();
        primaryContact.FirstName = 'david';
        primaryContact.LastName = 'david';
        primaryContact.Phone = 'david';
        primaryContact.Email = 'david@test.com';
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
        
        return newAccount;
    }
    
}