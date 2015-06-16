/*

Change log:
- GTCRM-369 - Fixed Modify product large opportunity "Too many SOQL queries"  (HCS - 26.09.2013)
- GTCRM-749 - Auto-renewal/rolling/cancel opportunities 

- GTCRM-749 : NK:14/02/2014: fixed future called from Batch AutoRenewal
*/

trigger gumtree_remote_opli_trigger on OpportunityLineItem (after update) {
	//do not run this trigger when batchRenewal running. the trigger logic will be processed right after BatchRenewal finishes
	System.debug('=========================gumtree_remote_opli_trigger 111=======' + Limits.getQueries());
	if(!BatchAutoRenewal.fromBatch ){
   		GumtreeRemoteOpliController.updateOportunityLineItem(trigger.new,trigger.old);  
   }
   System.debug('=========================gumtree_remote_opli_trigger 222=======' + Limits.getQueries());
    
}