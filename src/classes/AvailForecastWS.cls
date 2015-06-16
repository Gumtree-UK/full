/** 
  Webservice of Availability Forecast.
  Call process batch when clicking button(Availability Forecast) on detail page of Opp
  
  Created Date:26-11-2012 
  */ 

global class AvailForecastWS {
  
  webservice static String processWebservice(String oppId, String itemIds)
  {
    //System.debug('\n\n opp ID: ' + oppId);
    //System.debug('\n\n oppItem ID: ' + itemIds);

    if(BatchApexLimitCheck.isHittingLimit())
    {
      return 'Number of BatchApex reaches the governor limit. Please try some time later.';
    }
    
    try
    {
      List<String> recIds;  
          if(itemIds.indexOf(',')!=-1)
          {
              recIds = itemIds.split(',');
          }
          
          Set<String> setIds = new Set<String>();
          setIds.addAll(recIds);
      
      // Update Opportunity before running batch
      // -> To avoid parallel requests from the same opportunity.
      Opportunity oppty = new Opportunity(Id=oppId);
      oppty.Booking_in_Processing__c = true;
      update oppty;
       
      // Call Execute Batch
      BatchAvailabilityForecastProcess  batchProcess;

      if(setIds.isEmpty()) // If no LineItem is selected all LineItems will be used
      {
        batchProcess =  new BatchAvailabilityForecastProcess(oppId);
      }
      else
      {
        batchProcess =  new BatchAvailabilityForecastProcess(oppId, setIds);
      }
       
      Database.executeBatch(batchProcess, 1);
      
      return 'OK';
  
    }catch(Exception ex){return 'Error: ' + ex+'\n'+ex.getStackTraceString();}
    
    return '';

  }  

}