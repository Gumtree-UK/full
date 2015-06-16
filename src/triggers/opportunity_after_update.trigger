trigger opportunity_after_update on Opportunity (after update, before update) {

	
	if (Trigger.isBefore && Trigger.isUpdate) {
		// SPP : 15/08/2014
    	// if opp has been approved, send the agreement
    	List<Opportunity> opps = new List<Opportunity>();
    	for (Opportunity opp:Trigger.new) {
    		
    		Opportunity oldopp = Trigger.oldmap.get(opp.Id);
    		if (oldopp.Approval_Status__c!=opp.Approval_Status__c && opp.Approval_Status__c) {
    			opps.add(opp);
    		}
    	}
    	if (!opps.isEmpty()) {
    		CloneOpportunity_GT.checkApproval(opps);
    	}
	}
    	

    if (Trigger.isAfter && Trigger.isUpdate)
    {
    	
    	SF_Gumtree_SOW_001 handler = new SF_Gumtree_SOW_001();
        handler.handleOpportunityAfterUpdate(Trigger.oldMap, Trigger.newMap);
    }
}