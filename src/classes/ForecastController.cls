/** Controller responsible to process AvailabilityForecast
	
	Created Date: 22/11/2012
*/
public with sharing class ForecastController{

	OpportunityLineItem item;
	List<DARTObject.DARTForecast> listForecast;
	
	/** for log */	
	String invokedMethod;
	 

	public ForecastController(OpportunityLineItem item)
	{    
		 this.item = item;   
	}
	
	public void forecastProcess()
	{  
		// request to get Availability Forecast
		
		String dartVersion = item.PricebookEntry.Product2.RecordType.Name;
		AdServer_Login__c credential = DARTUtil.getCredential(dartVersion,item.PriceBookEntry.Product2.Site__r.Country__c);
		//System.debug('>>>>>>>>>>>>>>.credential:'+credential); 
		//create request DART5/6
		HTTPWrapper.IGenericRequest dartForecastRequest = FactoryDARTRequest.getInstance().createDartForecastRequest(credential,item);
        
        //create Parser accordingly
        DART6Parser.IDartParser forecastParser = FactoryParser.getInstance().createForecastParser(dartVersion, item);
        
        //create Connection DART5/6 
        DARTObject.IDARTConnector forecastCon = FactoryConnector.getInstance().createConnector(dartVersion,dartForecastRequest, forecastParser);
        forecastCon.connect();    
        
        invokedMethod = dartForecastRequest.getInvokedMethod();
		  
		//get result 
		listForecast = (List<DARTObject.DARTForecast>)forecastCon.getDartObjects();
		
		
		 
		//System.debug('----------------------- listForecast: ' + listForecast);
		
		//System.debug('--------------------invokedMethod: ' + invokedMethod);
 	
	}
	
 
	
	public List<DARTObject.DARTForecast> getObjectForecast()
	{
		return listForecast;
	} 
	
	public String getInvokedMethod()
	{
		return invokedMethod;
	}
	
}