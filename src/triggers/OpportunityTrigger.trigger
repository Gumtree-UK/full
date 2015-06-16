trigger OpportunityTrigger on Opportunity (after update) {
	
	// Update line items to lock (set isOppLost__c = true) for Scheduling 
	if(Trigger.isAfter && Trigger.isUpdate)
	OppStage2DeletePackage.lock4DeletePackage(Trigger.new, Trigger.oldMap);
	
	
}