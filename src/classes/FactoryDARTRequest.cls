public with sharing class FactoryDARTRequest {
	
	private static FactoryDARTRequest instance;
	
	private FactoryDARTRequest(){}
	
	public static FactoryDARTRequest getInstance()
	{
		if(instance==null)
		{
			instance = new FactoryDARTRequest();
		}
		
		return instance;
	}
	
	
	/** ------------------ Company/Advertiser Request ------------------- */
	public HTTPWrapper.IGenericRequest createDARTSubmitAdvertiserRequest(AdServer_Login__c credential, OpportunityLineItem item, Account acc)
	{
		if(DARTUtil.DART6.equals(credential.RecordType.Name))// new version
		{ 
			return new DART6Message.DFPCompanyRequest(acc, item);
		} 
		 
		return null;
	}
	
	/** ------- Oreder Request --------- */
	public HTTPWrapper.IGenericRequest createDARTSubmitOrderRequest(AdServer_Login__c credential, Opportunity opp, OpportunityLineItem item, Map<String, DARTObject.DARTPerson> mapDartUser,  Map<String, Advertiser__c> mapAdvertiser)
	{
		if(DARTUtil.DART6.equals(credential.RecordType.Name))// new version
		{ 
			return new DART6Message.DFPOrderRequest(opp, item, mapDartUser, mapAdvertiser);
		} 
		 
		return null;
	}
	
	/** ------------ Ads/LineItem Request -------------- */
	public HTTPWrapper.IGenericRequest createDARTSubmitAdsRequest(AdServer_Login__c credential, OpportunityLineItem item, DARTObject.IDARTObjectOrder dartOrder, Opportunity opp)
	{  
		if(DARTUtil.DART6.equals(credential.RecordType.Name))// new version
		{ 
			return new DART6Message.DFPAdsRequest(item, dartOrder, opp);
		}
		
		return null;     
	}
	
	/** ------------ Salesperson/DartUser Request --------------- */
	public HTTPWrapper.IGenericRequest createDartSubmitSalePersonRequest(String userRoleId, AdServer_Login__c credential, OpportunityLineItem item, Opportunity opp)
	{
		
		if(DARTUtil.DART6.equals(credential.RecordType.Name))// new version
		{ 
			return new DART6Message.DFPSalespersonRequest(item, opp);
		}
		   
		return null; 
	}
	
	/** ------------ Forecast Request ----------------- */
	
	public HTTPWrapper.IGenericRequest createDartForecastRequest(AdServer_Login__c credential,OpportunityLineItem item)
	{
		
		if(DARTUtil.DART6.equals(credential.RecordType.Name))
		{
			return new DART6Message.DFPForecastRequest(item); 
		} 
		
		return null;
	}
	
	/** ------------ Delivery Request ----------------- */
	
	public HTTPWrapper.IGenericRequest createDartDeliveryRequest(AdServer_Login__c credential,String breakDown,String dateRange,
				Long jobid, DART6_REPORTSERVICE.REPORTServiceInterfacePort reportService)
	{
		if(DARTUtil.DART6.equals(credential.RecordType.Name))
		{
			return new DART6Message.DeliveryRequest(credential, jobid, reportService); 
		} 
		
		return null;
	}
	
	/** ------------------ LineItemPage Request ------------------- */
	public HTTPWrapper.IGenericRequest createDARTLineItemPageRequest(AdServer_Login__c credential, String filterQuery)
	{
		if(DARTUtil.DART6.equals(credential.RecordType.Name))// new version
		{ 
			return new DART6Message.DFPLineItemPageRequest(credential, filterQuery);
		} 
		 
		return null;
	}
			
}