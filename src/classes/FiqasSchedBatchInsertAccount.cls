/* 

Change log:
- 2013-04-22 - GTCRM-245 - Standard/Premium dunning flow on customer level

*/

global class FiqasSchedBatchInsertAccount implements Database.Batchable<Account>, Database.AllowsCallouts {
 
 
 List<Account> accounts;

global FiqasSchedBatchInsertAccount(List<Account>  a)
{
    accounts = a.clone();
}

global Iterable<Account> start(Database.batchableContext BC){
        return accounts;
     }
public static string output = '';
global void execute(Database.BatchableContext BC, Account[] scope)
{

list<Account> Aforupdate = new list<Account>();
for(Sobject s : scope)
{
Account acc = (Account)s;  

  string Result = FiqasHTTPpost.CustomerInsert(                                              
                            acc.Account_Number_Fiqas__c,
                            '',
                            '', 
                            acc.Fiqas_Customer_Type__c,
                            'Active', //CustStatus
                            acc.Name,
                            '', //fiqas_Customer_extra
                            String.valueOf(acc.Fiqas_ApplyVATYN__c),
                            acc.Finance_Contact__r.Email,                          
                            ReplaceNull(acc.Company_VAT_No__c),
                            ReplaceNull(acc.Company_Reg_No__c),
                            String.valueof(acc.Fiqas_Dunning_Flow__c),   //CustInfo1
                            '', //CustInfo2
                            acc.BillingStreet,
                            ReplaceNull(String.valueof(acc.Fiqas_House_number__c)), //required if billingstreet entered
                            '', //Fiqas_house_number_extra
                            acc.BillingPostalCode,
                            ReplaceNull(acc.BillingCity), 
                            acc.BillingCountry,
                            ReplaceNull(acc.Finance_Contact__r.FirstName),
                            '', //Finance_contact_middlename
                            acc.Finance_Contact__r.LastName,                    
                            '',   //finance_contact_Title    
                            '',   //finance_contact_salutation
                            String.valueOf(acc.Finance_Contact__r.Sex__c), 
                            acc.Fiqas_Payment_Method__c, 
                            '', //PayMethAccountNr
                            '', //PayMethAccountHolder
                            '', //PayMethBankName
                            '', //PayMethBankCity
                            acc.Fiqas_Billing_Cycle__c,
                            acc.Fiqas_CMRSheet__c);
  
  if (Result == 'OK'){
            
            s.put('Fiqas_Account_Synced__c' , 'OK');
                }

  else
  {
            s.put('Fiqas_Account_Synced__c','FAILED');
  }
 

}
	update scope;

	// Bunhor @06-May-15: GTCRM-1924 - Enhance API error logs with greater detail
    futureCreateErrorLog.saveLogs();
}

 // this is a small function that replaces a 'null' string with a '' string'
 public static String ReplaceNull(String input){
    output = input;
    if (input==null){
        output = '';
    }
    return output;
 } 





global void finish(Database.BatchableContext BC)
{
                //do stuff when batch completes - or not

}


 public static testMethod void testBatch() {
    
  /*  
           Account acct = new Account();
                        acct.Name='Test Account_#45213';      
                        acct.BillingStreet='12345';
                        acct.BillingCity='Test';
                        acct.Phone='12456796';
                        acct.BillingCountry='NL';
                        acct.BillingPostalCode='134697';
                        acct.BillingState='test';                    
                        insert acct;  
    
    
        // Insert a contact
        Contact contact = new Contact(lastname='testContact', accountID=acct.Id);
        insert contact;   
       
   
     AccountContactRole acr = new AccountContactRole(Role='Other',IsPrimary=true, AccountId=acct.Id, ContactId=contact.Id);
        insert acr;      
      
    
        Account[] myTestAccounts = [SELECT Id, Finance_Contact__r.FirstName, Finance_Contact__r.MiddleName__c, 
                                        Finance_Contact__r.LastName, Finance_Contact__r.Email, Finance_Contact__r.Title, 
                                        Finance_Contact__r.Salutation, Finance_Contact__r.Sex__c, 
                                        Account_Number_Fiqas__c,
                                        Parent.Name, Name,
                                        Fiqas_Customer_Extra__c,
                                        Fiqas_ApplyVATYN__c,                                      
                                        Account_Status__c,
                                        BillingStreet,
                                        Fiqas_House_number__c,
                                        Fiqas_House_number_extra__c,
                                        BillingPostalCode,
                                        Fiqas_Account_Synced__c,
                                        BillingCity,
                                        Fiqas_Customer_Type__c,
                                        BillingCountry,
                                        Company_VAT_No__c,
                                        Company_Reg_No__c,
                                        Fiqas_Payment_Method__c,
                                        Fiqas_Billing_Cycle__c,
                                        Fiqas_CMRSheet__c,
                                        Fiqas_Dunning_Flow__c
                                        FROM Account where Id=: acct.Id limit 1];
                                        
         test.startTest();                                
        FiqasSchedBatchInsertAccount scriptBatch = new FiqasSchedBatchInsertAccount(myTestAccounts);
        ID batchprocessid = Database.executeBatch(scriptBatch, 1);
  
        test.stopTest();
        */
     }

}