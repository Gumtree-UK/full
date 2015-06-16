global class RevenuesUnused implements Database.Batchable<SObject>, Schedulable {

    private String limitSQL = '';
    private Integer batchsize = 50;

    public void setTest() {
        limitSQL = ' limit 10';
    }
    public void setBatchsize(Integer bs) {
        batchsize   = bs;
    }

    global Database.QueryLocator start(Database.BatchableContext bc) {
        String query = 'select Id from Revenue2__c' + limitSQL;
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<sObject> scope){
        List<Revenue2__c> rs = new List<Revenue2__c>();
        List<Revenue2__c> rev2del = new List<Revenue2__c>();

        for (sObject sO : scope) {
            Revenue2__c r = (Revenue2__c) sO;
            rs.add(r);
        }

        Set<Id> revIds = new Set<Id>();
        for(OpportunityLineItem oli : [select Revenue2__c from OpportunityLineItem where Revenue2__c IN : rs]){
            revIds.add(oli.Revenue2__c);
        }

        for(Revenue2__c r : rs) {
            if (!revIds.contains(r.Id)) {
                rev2del.add(r);
            }
        }

        if (!rev2del.isEmpty()) {
            delete rev2del;
        }
    }

    global void finish(Database.BatchableContext BC){
    }

    // Scheduler
    global void execute(SchedulableContext sc) {
        //RevenuesUnused batch = this;
        Database.executeBatch(this, batchsize);
    }

    // Testmethods
    static testMethod void testRevenuesUnusedSchedule() {
        Test.startTest();
        RevenuesUnused p = new RevenuesUnused();
        p.setTest();
        SchedulableContext sc;
        p.execute(sc);
        Test.StopTest();
    }

    static testMethod void testRevenuesUnused() {
        Test.startTest();
        RevenuesUnused p = new RevenuesUnused();
        p.setTest();
        p.setBatchsize(100);
        Database.executeBatch(p);
        Test.StopTest();
    }
}