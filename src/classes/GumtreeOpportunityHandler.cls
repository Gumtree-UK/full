/*

Change log;
- 2015-03-24 - GTCRM-1735 - Ability for sales to take an upfront payment via credit/debit card or PayPal on opportunity

*/

public with sharing class GumtreeOpportunityHandler {
    
    private Opportunity oldOpportunity;
    private Opportunity newOpportunity;
    
    public GumtreeOpportunityHandler(Opportunity oldOpportunity, Opportunity newOpportunity) {
        this.oldOpportunity = oldOpportunity;
        this.newOpportunity = newOpportunity;
    }
    
    public GumtreeOpportunityHandler() {
    }
    
    public void handleOpportunityUpdate() {
        
        GumtreeUtilsInterface utils = GumtreeUtils.getGumtreeUtilsInterface();
        
        if (isGumtreeRecordType() && isBookingStageAndPaymentMade()) {
            
            Account acc = getAccount(newOpportunity);
            
            if (acc == null) {
                return;
            }
            
            GumtreeOpportunityHandler.assignPackagesFutureCall(acc.Id, newOpportunity.Id);
            
            if (acc.Account_Status__c != 'Active') {
                acc.Account_Status__c = 'Active';
                update acc;         
            }
        } 
    }
    
    /**
   * ADD 19 March 2014: #1641, PN    
   * Fetch Account Number of Fiqas Account Number
   */
    public static String lPad(String text, Integer length, String paddingCharacter){
    String result = text;
    while(result.length() < length){
      result = paddingCharacter + result;
    }
    return 'GT' + result;
  }
    
    public Account getAccount(Opportunity opportunity) {
        Account acc = [select Id, AccountNumber, Name, BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry, Account_Status__c, Password__c, Primary_Contact__c,RecordTypeId, Client_Type__c, Fiqas_Account_Synced__c from Account where id = :opportunity.AccountId];
            
        if (acc == null) {
            ErrorLog__c error = new ErrorLog__c();
            error.details__c = 'No account found for new opportunity';
            error.Related_Id__c = newOpportunity.Id;
            error.Type__c = 'handleOpportunityUpdate';
            Database.insert(error,false);
            return null;
        } else {
            return acc;
        }
    }
    
    public Boolean isGumtreeRecordType() {
        return newOpportunity.RecordTypeId == '01220000000YY7Y' || newOpportunity.RecordTypeId == '01220000000YaHA' || newOpportunity.RecordTypeId == '012w0000000QBzr' || newOpportunity.RecordTypeId == '01220000000YY7T' || newOpportunity.RecordTypeId == '01220000000YY7J';
    }
    
    public Boolean isBookingStageAndPaymentMade() {
        return isUpdatedToBookingAndPaymentMade() || isInBookingAndCCPaymentMade();
    }
    
    public Boolean isUpdatedToBookingAndPaymentMade() {
        return newOpportunity.StageName != oldOpportunity.StageName
                && newOpportunity.StageName == 'Booking'
                && (newOpportunity.Payment_Method__c != 'Credit/Debit Card'
                    || (newOpportunity.Payment_Method__c == 'Credit/Debit Card'
                            && newOpportunity.CC_Reference__c != null
                            && newOpportunity.CC_Reference__c != '')
                    
                    // 2015-03-24 - GTCRM-1735 - Ability for sales to take an upfront payment via credit/debit card or PayPal on opportunity
                    || (newOpportunity.Payment_Method__c == 'Credit/Debit Card'
                            && newOpportunity.Last_Payment_Taken__c != null)
                            );
    }
    
    public Boolean isInBookingAndCCPaymentMade() {
        return newOpportunity.StageName == 'Booking'
                && oldOpportunity.StageName == 'Booking'
                && newOpportunity.Payment_Method__c == 'Credit/Debit Card'
                
                // 2015-03-24 - GTCRM-1735 - Ability for sales to take an upfront payment via credit/debit card or PayPal on opportunity
                && ((newOpportunity.CC_Reference__c != null
                && newOpportunity.CC_Reference__c != '') 
                || (newOpportunity.Last_Payment_Taken__c != null))
                                
                && (newOpportunity.Payment_Method__c != oldOpportunity.Payment_Method__c
                    || newOpportunity.CC_Reference__c != oldOpportunity.CC_Reference__c
                
                // 2015-03-24 - GTCRM-1735 - Ability for sales to take an upfront payment via credit/debit card or PayPal on opportunity
                    || newOpportunity.Last_Payment_Taken__c != oldOpportunity.Last_Payment_Taken__c);
    }
    
    public void updatePrimaryContact(List<Opportunity> lOpportunity){
       List<OpportunityContactRole> lOpportunityContactRole=new List<OpportunityContactRole>();
       map<id,id> mapOpptyContactRole=new map<id,id>();
       String temp;

       lOpportunityContactRole=[select ContactID,OpportunityId from OpportunityContactRole where OpportunityId in:lOpportunity and isPrimary=true ];
       
       for  (OpportunityContactRole oOpptyContactRole : lOpportunityContactRole){
           mapOpptyContactRole.put(oOpptyContactRole.OpportunityId,oOpptyContactRole.ContactID );
       }
      
       for (Opportunity oOppty :lOpportunity){
           temp=null;
           temp=mapOpptyContactRole.get(oOppty.id);     
           if(temp != null){            
             oOppty.Primary_Contact__c=temp;            
          }     
       }
    }
    
    @future(callout = true)
    public static void assignPackagesFutureCall(Id accountId, Id opportunityId) {
        GumtreeAPIInterface api = GumtreeAPI.getGumtreeAPIInstance();
        GumtreeUtilsInterface utils = GumtreeUtils.getGumtreeUtilsInterface();
        Account account = [SELECT Id, AccountNumber, Name, Description, BillingStreet, Primary_Contact__c, 
                            BillingPostalCode, BillingCity, BillingState, BillingCountry, Account_Status__c, Client_Type__c 
                            FROM Account WHERE Id = :accountId];
                
        try {
            String accountNumber = account.AccountNumber;
            if (accountNumber == null || accountNumber == '') {
                Contact accountPrimaryContact = utils.getAccountPrimaryContact(account);
                String accountJson = utils.buildAccountJson(account, accountPrimaryContact.Email, null);
                String userJson = utils.buildUpdateUserJson(accountPrimaryContact);
                accountNumber = api.createAccountWithoutUpdatingSalesforce(accountId, accountJson, userJson, accountPrimaryContact.Email);
            }
            
            /**
       * ADD 19 March 2014: #1641, PN    
       * Update fiqas account number
       */
            Account acc = [Select Id, Finance_Contact__r.FirstName, Finance_Contact__r.MiddleName__c, 
                                        Finance_Contact__r.LastName, Finance_Contact__r.Email, Finance_Contact__r.Title, 
                                        Finance_Contact__r.Salutation, Finance_Contact__r.Sex__c,
                                        Account_Number_Fiqas__c,
                                        Parent.Name, Name,
                                        Fiqas_Customer_Extra__c,
                                       // Fiqas_ApplyBTWYN__c,
                                        Fiqas_ApplyVATYN__c,
                                        Fiqas_Customer_Type__c,
                                        Company_VAT_No__c,
                                        Company_Reg_No__c,
                                        BillingStreet,
                                        Fiqas_House_number__c,
                                        Fiqas_House_number_extra__c,
                                        BillingPostalCode,
                                        BillingCity,
                                        BillingCountry,
                                        //BTW_Number__c,
                                        //KVK_Number__c,
                                        Fiqas_Payment_Method__c,
                                        Fiqas_Billing_Cycle__c,
                                        Fiqas_CMRSheet__c,
                                        Account_Status__c,
                                        Fiqas_Dunning_Flow__c, 
                                        Password__c, 
                                        Primary_Contact__c,
                                        RecordTypeId, 
                                        Fiqas_Account_Synced__c,
                                        Client_Type__c From Account Where Id =: accountId];
            FiqasAPIservice.doCustomerUpsert(acc, lPad(accountNumber, 10, '0'), false);
            
            String packagesJson = '[';
            for (OpportunityLineItem oli : [select Id, PricebookEntryId, Quantity, from_Date__c, until_Date__c, Adjusted_credits__c, PricebookEntry.Product2.Product_Subtype__c 
                    from OpportunityLineItem 
                    WHERE OpportunityId = :opportunityId
                    AND (PricebookEntry.Product2.Product_Subtype__c = 'Advertising' OR PricebookEntry.Product2.Product_Subtype__c = 'Featured Advertising')
                    ]) {
                        
                Decimal adjusted_credits = 0;
                if (oli.Adjusted_credits__c != null)
                    adjusted_credits = oli.Adjusted_credits__c;
                        
                String packageJson = utils.buildPackageJSON(
                    accountNumber,
                    String.valueOf(oli.Id),
                    String.valueOf(oli.PricebookEntryId),
                    oli.from_Date__c,
                    oli.until_Date__c,
                    Math.round(oli.Quantity),
                    Math.round(adjusted_credits)
                    );
                packagesJson += packageJson + ',';
            }
            
            packagesJson = packagesJson.substring(0,packagesJson.length()-1) + ']';
            api.assignPackages(packagesJson, accountId);
            api.updateAccountNumberAndMarkAsMigrated(accountId, accountNumber);
            
            /**
       * ADD 19 March 2014: #1641, PN    
       * Update sf account
       */
            update acc;
            
        }catch (GumtreeCalloutException e) {
            //This is here just to wrap all api calls so that execution is halted if any one fails
        }
        api.logErrors();
        
        // Bunhor @06-May-15: GTCRM-1924 - Enhance API error logs with greater detail: logs from FiqasAPIservice.doCustomerUpsert > FiqasHTTPpost.CustomerInsert
		futureCreateErrorLog.saveLogs();
    }
    
    
}