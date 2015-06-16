/*

- GTCRM-785 - Days since creation not updating on invoice

Change log:

*/

global class SchInvoiceAgeUpdate implements Schedulable {
    global void execute(SchedulableContext ctx) {
        List<Invoices__c> updatedInvList = new List<Invoices__c>();
        
        for(Invoices__c inv : [SELECT Id, Age__c, Days_since_creation__c 
                               FROM Invoices__c 
                               WHERE Days_Since_Creation_Check__c = 'FALSE']) {
            
                inv.Age__c = inv.Days_since_creation__c;
                updatedInvList.add(inv);
            
        }
        
        update updatedInvList;
    }
}