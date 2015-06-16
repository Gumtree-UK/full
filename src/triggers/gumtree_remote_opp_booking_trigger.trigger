trigger gumtree_remote_opp_booking_trigger on Opportunity (after update) {

    Integer i = 0;
    for (Opportunity opp : Trigger.new) {
    	GumtreeOpportunityHandler handler = new GumtreeOpportunityHandler(Trigger.old[i], opp);
    	handler.handleOpportunityUpdate();
        i++;
    }
}