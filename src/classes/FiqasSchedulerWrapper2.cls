/* 
Schedulable class to resend accounts to Fiqas every day 

Change log:
- 2013-04-22 - GTCRM-245 - Standard/Premium dunning flow on customer level

*/


global class FiqasSchedulerWrapper2 implements Schedulable {

   global void execute(SchedulableContext SC) {
      
   Account[] Acct = [SELECT Id, Finance_Contact__r.FirstName, Finance_Contact__r.MiddleName__c, 
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
                                       // Fiqas_Account_Synced__c,
                                        BillingCountry,
                                        //BTW_Number__c,
                                        //KVK_Number__c,
                                        Fiqas_Payment_Method__c,
                                        Fiqas_Billing_Cycle__c,
                                        Fiqas_CMRSheet__c,
                                        Fiqas_Account_Synced__c,
                                        Account_Status__c,
                                        Fiqas_Dunning_Flow__c
                                        FROM Account where
                                        ((Fiqas_Account_Synced__c= 'UPDATE' OR Fiqas_Account_Synced__c = 'INSERT') AND                                     
                                        BillingStreet != null AND
                                        BillingCity != null AND 
                                        BillingPostalCode != null AND 
                                        BillingCountry != null AND 
                                        Finance_Contact__r.LastName != null)];
       
      FiqasSchedBatchUpdateAccount F = new FiqasSchedBatchUpdateAccount(Acct); 
      
      ID batchprocessid = Database.executeBatch(F, 1);
 
   }   
}



/*
FiqasSchedulerWrapper m = new FiqasSchedulerWrapper();
        String sch = '0 0 20 * * ?';
        system.schedule('FiqasResendAccounts', sch, m);
        
*/