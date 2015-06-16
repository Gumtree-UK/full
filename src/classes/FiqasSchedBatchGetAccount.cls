/* 

Change log:
- 2013-04-22 - GTCRM-245 - Standard/Premium dunning flow on customer level

*/

global class FiqasSchedBatchGetAccount implements Database.Batchable<Account>, Database.AllowsCallouts {
 
 
 List<Account> accounts;

global FiqasSchedBatchGetAccount(List<Account>  a)
{
    accounts = a.clone();
}

global Iterable<Account> start(Database.batchableContext BC){
        return accounts;
     }

global void execute(Database.BatchableContext BC, Account[] scope)
{

    list<Account> Aforupdate = new list<Account>();
    for(Sobject s : scope)
    {
      Account acc = (Account)s;  
      string Result = FiqasHTTPpost.CustomerGet(acc.Account_Number_Fiqas__c);
      
      if (Result == 'OK'){s.put('Fiqas_Account_Synced__c' , 'UPDATE');}
      else if (Result =='FAILED'){s.put('Fiqas_Account_Synced__c' , 'INSERT'); }
      else {s.put('Fiqas_Account_Synced__c','FAILED');  }
    
    }
    update scope;
    
    // Bunhor @06-May-15: GTCRM-1924 - Enhance API error logs with greater detail: logs from FiqasHTTPpost.CustomerGet
	futureCreateErrorLog.saveLogs();
}

global void finish(Database.BatchableContext BC)
{
                //schedule next batch
                
         System.debug(LoggingLevel.WARN,'Batch Process 1 Finished');
        //Build the system time of now + 20 seconds to schedule the batch apex.
        Datetime sysTime = System.now();
        sysTime = sysTime.addSeconds(20);
        String chron_exp = '' + sysTime.second() + ' ' + sysTime.minute() + ' ' + sysTime.hour() + ' ' + sysTime.day() + ' ' + sysTime.month() + ' ? ' + sysTime.year();
        system.debug(chron_exp);
        FiqasSchedulerWrapper2 FW = new FiqasSchedulerWrapper2();
        //Schedule the next job, and give it the system time so name is unique
        System.schedule('FiqasResendjob' + sysTime.getTime(),chron_exp,FW);

}

 public static testMethod void testBatch() {
       
       
           Account acc = new Account();
                        acc.Name='Test Account_#453';      
                        acc.BillingStreet='12345';
                        acc.BillingCity='Test';
                        acc.Phone='12456796';
                        acc.BillingCountry='NL';
                        acc.BillingPostalCode='134697';
                        acc.BillingState='test';  
                        acc.Fiqas_Dunning_Flow__c = 'Standard';                  
                        insert acc;

        
        // Insert a contact
        Contact contact = new Contact(lastname='testContact', accountID=acc.Id);
        insert contact;   
       
   
     AccountContactRole acr = new AccountContactRole(Role='Other',IsPrimary=true, AccountId=acc.Id, ContactId=contact.Id);
        insert acr;     
        
        acc.BillingCity = 'Utrecht';
        update acc;
  
      
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
                                        Fiqas_Customer_Type__c,
                                        Company_VAT_No__c,
                                        Company_Reg_No__c,
                                        Fiqas_Payment_Method__c,
                                        Fiqas_Billing_Cycle__c,
                                        Account_Status__c,
                                        Fiqas_CMRSheet__c,
                                        Fiqas_Dunning_Flow__c
                                        FROM Account WHERE Id=: acc.Id limit 1];
                                        
         test.startTest();                                
        FiqasSchedBatchGetAccount scriptBatch = new FiqasSchedBatchGetAccount(myTestAccounts);
        ID batchprocessid = Database.executeBatch(scriptBatch, 1);
        
        Account[] myTestAccount = [Select Id, Fiqas_Account_Synced__c from Account where Id =: myTestAccounts[0].Id limit 1];
      
 
        test.stopTest();
     }

}