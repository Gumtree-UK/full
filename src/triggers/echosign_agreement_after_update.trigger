trigger echosign_agreement_after_update on echosign_dev1__SIGN_Agreement__c (after update) {

    if (Trigger.isAfter && Trigger.isUpdate)
    {
    	SF_Gumtree_SOW_001 handler = new SF_Gumtree_SOW_001();
    	handler.handleEchoSign_AgreementAfterUpdates(Trigger.oldMap, Trigger.newMap);
    }
}