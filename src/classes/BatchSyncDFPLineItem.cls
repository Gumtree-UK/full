/**
 * R #2596 : referenced SyncDFPLineItem
 */
global class BatchSyncDFPLineItem implements Database.Batchable<sObject>, Database.Stateful, Database.AllowsCallouts{
    
    private List<AdServer_Login__c> toProcessAdLogin;
    public SyncDFPLineItem syncCon;
    
    global BatchSyncDFPLineItem(List<AdServer_Login__c> ladLogin){
        syncCon = new SyncDFPLineItem();
        toProcessAdLogin = ladLogin;
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC){
        return Database.getQueryLocator([SELECT RecordType.name,Name,Login_URL__c, User_Name__c, Password__c, Network_ID__c, Site__c,  Client_ID__c, Client_Secret__c, Refresh_Token__c FROM AdServer_Login__c WHERE Id IN: toProcessAdLogin]);
    }
    
    global void execute(Database.BatchableContext BC, List<AdServer_Login__c> scope){
        // to fixed error Future method cannot be called from a future or batch method
        BatchAutoRenewal.fromBatch=true;
        syncCon.processSync(scope[0]);
        BatchAutoRenewal.fromBatch=false;
    }
    
    global void finish(Database.BatchableContext BC){
        
    }
}