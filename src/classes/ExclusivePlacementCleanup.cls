/*
 * check ExclusivePlacements, delete entries with Date < Today.
 * Batchable & Schedulable
 */
global without sharing class ExclusivePlacementCleanup implements Database.Batchable<SObject>, Schedulable{

    private static string limitSQL = '';

    public void setTest(Boolean b) {
        limitSQL = ' limit 10';
    }

    // Batchjob
    global Database.QueryLocator start(Database.BatchableContext bc) {
        String query = 'select Id from exclusive_Placement__c where Date__c < TODAY' + limitSQL;
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List<sObject> scope){
        delete scope;
    }

    global void finish(Database.BatchableContext BC){}
    
    // Schedulable
    global void execute(SchedulableContext sc) {
        Database.executeBatch(new ExclusivePlacementCleanup());
    }
    
    static testMethod void testExclusivePlacementCleanupBatch() {

        exclusive_Placement__c ep = new exclusive_Placement__c(
            Date__c = Date.today() -5,
            Opportunity__c  = [select Id from Opportunity limit 1].Id,
            Revenue2__c      = [select Id from Revenue2__c limit 1].Id
        );
        insert ep;
        
        Test.startTest();
        ExclusivePlacementCleanup epc = new ExclusivePlacementCleanup();
        epc.setTest(true);
        Database.executeBatch(epc);
        Test.stopTest();
    }

    static testMethod void testExclusivePlacementCleanupSchedule() {
        Test.startTest();
        ExclusivePlacementCleanup epc = new ExclusivePlacementCleanup();
        epc.setTest(true);
        SchedulableContext sc;
        epc.execute(sc);
        Test.stopTest();
    }
}