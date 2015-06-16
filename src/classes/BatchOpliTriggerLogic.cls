global class BatchOpliTriggerLogic implements Database.Batchable<sObject>,Database.AllowsCallouts,Database.Stateful { // Bunhor @15-Jan-15: adding Database.Stateful
	public boolean isBatchAutoRenewal = false; // Bunhor @15-Jan-15: this is from BatchAutoRenewal 
	
	private String query = 'Select AwaitForTriggerProcess__c,from_Date__c,until_Date__c, Id, Revenue2__c, Net__c, Length_months__c,OpportunityId,Adjusted_credits__c,PricebookEntryId,Quantity From OpportunityLineItem Where AwaitForTriggerProcess__c=true';
	public BatchOpliTriggerLogic(){
	 	
	} 
	global Database.QueryLocator start(Database.BatchableContext BC){
		
		return Database.getQueryLocator(query);
	}
	global void execute(Database.BatchableContext BC, List<OpportunityLineItem> scope){
		// Bunhor @15-Jan-15: new inserting RS price will be token from Rate Card of 3 Months Products
		if(isBatchAutoRenewal){ for(OpportunityLineItem opli : scope){ Revenue.mapRevId2IsRCprice.put(opli.Revenue2__c, true); } } 
		
		BatchAutoRenewal.fromBatch = true;
		GumtreeRemoteOpliController.updateOportunityLineItem(scope,new list<OpportunityLineItem>());
		BatchAutoRenewal.fromBatch = false;
	}
	
	global void finish(Database.BatchableContext BC){
		
	}
}