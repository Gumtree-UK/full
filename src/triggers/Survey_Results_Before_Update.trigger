trigger Survey_Results_Before_Update on Survey_Results__c (before update) {

    if (Trigger.isBefore && Trigger.isUpdate)
    {
        SF_Gumtree_SOW_001 handler = new SF_Gumtree_SOW_001();
        handler.handleSurvey_Results_BeforeUpdates(Trigger.oldMap, Trigger.newMap);
    }
}