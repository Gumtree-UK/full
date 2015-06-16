trigger tgrUpdateCancelledLineItem on Opportunity (after update) {
 
     ClsOpportunityService.updateCancelledOpp(Trigger.old,Trigger.new);
 
}