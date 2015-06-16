trigger Survey_Results_Before_Insert on Survey_Results__c (before insert) {

    if (Trigger.isBefore && Trigger.isInsert)
    {
        SF_Gumtree_SOW_001 handler = new SF_Gumtree_SOW_001();
        handler.handleSurvey_Results_BeforeInserts(Trigger.new);
    }
    
}