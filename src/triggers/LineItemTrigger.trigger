trigger LineItemTrigger on OpportunityLineItem (after delete, after insert, after undelete, 
after update, before delete, before insert, before update) {
	System.debug('=========================LineItemTrigger 111=======' + Limits.getQueries());
    // calc Amount by delivery
     LineItems.calcAmountByDelivery(trigger.new, trigger.old, trigger.oldMap, trigger.isBefore, trigger.isInsert, trigger.isUpdate, trigger.isDelete, trigger.isUnDelete);
	System.debug('=========================LineItemTrigger 222=======' + Limits.getQueries());
    // calc Package Quantities
    LineItems.checkQuantity(trigger.new, trigger.old, trigger.oldMap, trigger.isBefore, trigger.isInsert, trigger.isUpdate, trigger.isDelete, trigger.isUnDelete);
	System.debug('=========================LineItemTrigger 333=======' + Limits.getQueries());
    // copy discounts and calc n/n/n for not CPM based prices
    LineItems.copyDiscountsFromOpportunityToLineItem(trigger.new, trigger.old, trigger.oldMap, trigger.isBefore, trigger.isInsert, trigger.isUpdate, trigger.isDelete, trigger.isUnDelete);
	System.debug('=========================LineItemTrigger 444=======' + Limits.getQueries());
    // calc n/n/n for CPM based prices
    LineItems.setPricesCPM(trigger.new, trigger.old, trigger.oldMap, trigger.isBefore, trigger.isInsert, trigger.isUpdate, trigger.isDelete, trigger.isUnDelete);
	System.debug('=========================LineItemTrigger 555=======' + Limits.getQueries());
    // delete Revenues when Lineitem is deleted
    LineItems.deleteReveues (trigger.old, trigger.isBefore, trigger.isDelete);
	System.debug('=========================LineItemTrigger 666=======' + Limits.getQueries());
    // create / update Revenues
    LineItems.updateRevenues(trigger.new, trigger.old, trigger.oldMap, trigger.isBefore, trigger.isInsert, trigger.isUpdate, trigger.isDelete, trigger.isUnDelete);
    System.debug('=========================LineItemTrigger 777=======' + Limits.getQueries());    
    // change AdName according to Naming convension
    LineItems.setAdName(trigger.new, trigger.old, trigger.oldMap, trigger.isBefore, trigger.isInsert, trigger.isUpdate, trigger.isDelete, trigger.isUnDelete);
	System.debug('=========================LineItemTrigger 888=======' + Limits.getQueries());
	//SUY Sreymol 19/05/2014 to recalculate net/net/net delivered when line item is created/update
	if (trigger.isAfter && !ClsBookingOppUpdate.IS_CANCEL_BEFORE_TIME) {
		if (trigger.isDelete) RevenueSchedule2Handler.setTmpNetnetnetDelivered(trigger.old);
		else RevenueSchedule2Handler.setTmpNetnetnetDelivered(trigger.new);
	}
	System.debug('=========================LineItemTrigger 999=======' + Limits.getQueries());
}