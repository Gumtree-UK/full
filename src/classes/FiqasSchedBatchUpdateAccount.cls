/* 

Change log:
- 2013-04-22 - GTCRM-245 - Standard/Premium dunning flow on customer level

*/

global class FiqasSchedBatchUpdateAccount implements Database.Batchable<Account>, Database.AllowsCallouts {
 
 
 List<Account> accounts;

global FiqasSchedBatchUpdateAccount(List<Account>  a)
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

  
  if(acc.Fiqas_Account_Synced__c =='UPDATE'){
  
  string Result = FiqasHTTPpost.CustomerUpdate(                                               
                            
                            acc.Account_Number_Fiqas__c,
                            '',
                            '', 
                            acc.Fiqas_Customer_Type__c, 
                            'Active', // acc.Account_Status__c, 
                            acc.Name,
                            '', //fiqas_Customer_extra
                            String.valueOf(acc.Fiqas_ApplyVATYN__c),
                            acc.Finance_Contact__r.Email,
                            ReplaceNull(acc.Company_VAT_No__c),
                            ReplaceNull(acc.Company_Reg_No__c),
                            String.valueOf(acc.Fiqas_Dunning_Flow__c),   //CustInfo1
                            '', //CustInfo2
                            acc.BillingStreet,
                            '', //Fiqas_house_number_extra required if billingstreet entered
                            '', //Fiqas_house_number_extra
                            acc.BillingPostalCode,
                            acc.BillingCity,
                            acc.BillingCountry,
                            ReplaceNull(acc.Finance_Contact__r.FirstName),
                            '', //Finance_contact_middlename
                            acc.Finance_Contact__r.LastName,                   
                            '',   //finance_contact_Title    
                            '',   //finance_contact_salutation
                            String.valueOf(acc.Finance_Contact__r.Sex__c));  
  
                     if (Result == 'OK'){s.put('Fiqas_Account_Synced__c' , 'OK');   }
                     else{  s.put('Fiqas_Account_Synced__c','FAILED'); }
        }
        
  else {
        string Result = FiqasHTTPpost.CustomerInsert(                                              
                            acc.Account_Number_Fiqas__c,
                            '',
                            '', 
                            acc.Fiqas_Customer_Type__c,
                            'Active',  //acc.Account_Status__c, //CustStatus
                            acc.Name,
                            '', //fiqas_Customer_extra
                            String.valueOf(acc.Fiqas_ApplyVATYN__c),
                            acc.Finance_Contact__r.Email,                          
                            ReplaceNull(acc.Company_VAT_No__c),
                            ReplaceNull(acc.Company_Reg_No__c),
                            String.valueOf(acc.Fiqas_Dunning_Flow__c), //CustInfo1
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
    
    
                     if (Result == 'OK'){s.put('Fiqas_Account_Synced__c' , 'OK');   }
                     else{  s.put('Fiqas_Account_Synced__c','FAILED'); }
    
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
                //do nothing

}


 public static testMethod void testBatch() {
      
           Account acc = new Account();
                        acc.Name='Test Account_23$';      
                        acc.BillingStreet='12345';
                        acc.BillingCity='Test';
                        acc.Phone='12456796';
                        acc.BillingCountry='NL';
                        acc.BillingPostalCode='134697';
                        acc.BillingState='test'; 
                        acc.Fiqas_Account_Synced__c ='UPDATE';
                        acc.AccountNumber = '55555';
                        acc.Fiqas_Dunning_Flow__c = 'Standard';                 
                        insert acc;

        
        // Insert a contact
        Contact contact = new Contact(lastname='testContact', accountID=acc.Id);
        insert contact;   
       
   
     AccountContactRole acr = new AccountContactRole(Role='Other',IsPrimary=true, AccountId=acc.Id, ContactId=contact.Id);
        //insert acr;      
      
        Account[] myTestAccounts = [SELECT Id, Finance_Contact__r.FirstName, Finance_Contact__r.MiddleName__c, 
                                        Finance_Contact__r.LastName, Finance_Contact__r.Email, Finance_Contact__r.Title, 
                                        Finance_Contact__r.Salutation, Finance_Contact__r.Sex__c, 
                                        Account_Number_Fiqas__c,
                                        Parent.Name, Name,
                                        Fiqas_Customer_Extra__c,
                                        Fiqas_ApplyVATYN__c,
                                        BillingStreet,
                                        Fiqas_House_number__c,
                                        Fiqas_House_number_extra__c,
                                        BillingPostalCode,
                                        Fiqas_Account_Synced__c,
                                        BillingCity,
                                        BillingCountry,
                                        Account_Status__c,
                                        Fiqas_Customer_Type__c,
                                        Fiqas_Dunning_Flow__c,
                                        Company_VAT_No__c,
                                        Company_Reg_No__c,
                                        Fiqas_Payment_Method__c,
                                        Fiqas_Billing_Cycle__c,
                                        Fiqas_CMRSheet__c
                                        FROM Account WHERE Id=: acc.Id limit 1];
                                        
                                        
         test.startTest();                                
        FiqasSchedBatchUpdateAccount scriptBatch = new FiqasSchedBatchUpdateAccount(myTestAccounts);
        ID batchprocessid = Database.executeBatch(scriptBatch, 1);
        
        acc.Fiqas_Account_Synced__c = 'INSERT';
        update acc;
          Account[] myTestAccounts2 = [SELECT Id, Finance_Contact__r.FirstName, Finance_Contact__r.MiddleName__c, 
                                        Finance_Contact__r.LastName, Finance_Contact__r.Email, Finance_Contact__r.Title, 
                                        Finance_Contact__r.Salutation, Finance_Contact__r.Sex__c, 
                                        Account_Number_Fiqas__c,
                                        Parent.Name, Name,
                                        Fiqas_Customer_Extra__c,
                                        Fiqas_ApplyVATYN__c,
                                        BillingStreet,
                                        Fiqas_House_number__c,
                                        Fiqas_House_number_extra__c,
                                        BillingPostalCode,
                                        Fiqas_Account_Synced__c,
                                        BillingCity,
                                        BillingCountry,
                                        Account_Status__c,
                                        Fiqas_Customer_Type__c,
                                        Fiqas_Dunning_Flow__c,                                        
                                        Company_VAT_No__c,
                                        Company_Reg_No__c,
                                        Fiqas_Payment_Method__c,
                                        Fiqas_Billing_Cycle__c,
                                        Fiqas_CMRSheet__c

                                        FROM Account WHERE Id=: acc.Id limit 1];
              
        FiqasSchedBatchUpdateAccount scriptBatch2 = new FiqasSchedBatchUpdateAccount(myTestAccounts2);
        ID batchprocessid2 = Database.executeBatch(scriptBatch2, 1);
        
       
       
        test.stopTest();
     }

}