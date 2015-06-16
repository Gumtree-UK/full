global class GumtreeAPI_Batch implements Database.Batchable<sObject>, Database.AllowsCallouts {
 
 global String query;
 global GumtreeAPI api;
    
    global database.querylocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List<sObject> scope) {
        api = new GumtreeAPI();
        BatchAutoRenewal.fromBatch=true;
        for(sObject s : scope) {
            Account a = (Account)s;
            api.updateUsedCredits(a.AccountNumber);
        }
        BatchAutoRenewal.fromBatch=false;
        api.logErrors();
    }
    
    global void finish(Database.BatchableContext BC) {      
    }
    
}