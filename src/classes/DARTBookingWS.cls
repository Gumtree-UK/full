global class DARTBookingWS{
	
	webservice static String processWebservice(String oppId, String itemIds)
	{
		
		try
		{
			List<String> recIds;  
	        if(itemIds.indexOf(',')!=-1)
	        {
	            recIds = itemIds.split(',');
	        }
	        
	        Set<String> setIds = new Set<String>();
	        setIds.addAll(recIds);
	        
	        System.debug('------------> setIds: '  + setIds + '---------> oppId: ' + oppId);
			
			// Update Opportunity before running batch
			// -> To avoid parallel requests from the same opportunity.
			Opportunity oppty = new Opportunity(Id=oppId);
			oppty.Booking_in_Processing__c = true;
			update oppty;
			 
			// Call Execute Batch
			BatchDARTBookingProcess  batchProcess;

			if(setIds.isEmpty()) // If no LineItem is selected all LineItems will be used
			{
				batchProcess =  new BatchDARTBookingProcess(oppId);
			}
			else
			{
				batchProcess =  new BatchDARTBookingProcess(oppId, setIds);
			}
			 
			Database.executeBatch(batchProcess, 1);
			
			return 'OK';
	
		}catch(Exception ex){return 'Error: ' + ex+'\n'+ex.getStackTraceString();}
		
		return '';

	}
}