trigger SetPrimaryContact on Opportunity (before update) {
	
	    OpportunityHandler.updatePrimaryContact(Trigger.new);
   }