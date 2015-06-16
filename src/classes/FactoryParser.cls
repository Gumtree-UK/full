public with sharing class FactoryParser {
	
	private static FactoryParser instance;
	
	private FactoryParser(){}
	
	public static FactoryParser getInstance()
	{
		if(instance==null)
		{
			instance = new FactoryParser();	
		} 
		return instance;
	}	 
	 
	/** -------------------------------- 
		Advertiser Parser 
	------------------------------- */ 
	public DART6Parser.IDartParser createAdvertiserParser(Account acc, String dartVersion)
	{
		if(DARTUtil.DART6.equals(dartVersion))  
		{ 
			return new DART6Parser.DFPResponseToCompanyParser(acc); 
		}
		return null;
	}
	 
	  
	 
	/** -------------------------------- 
		Order Parser 
	------------------------------- */ 
	public DART6Parser.IDartParser createOrderParser(AdServer_Login__c credential,String dartVersion, Opportunity opp)
	{
		if(DARTUtil.DART6.equals(dartVersion))  
		{ 
			return new DART6Parser.DFPResponseToOrderParser(opp, credential); 
		}
		return null;
	} 
	
	/** -------------------------------- 
		Person Parser 
	------------------------------- */
	public DART6Parser.IDartParser createSalespersonParser(String dartVersion)
	{
		if(DARTUtil.DART6.equals(dartVersion))
		{
			return new DART6Parser.DFPResponseToSalespersonParser();
		} 
		return null;
	}
	 
	
	
	/** -------------------------------- 
		Ads/LineItem Parser 
	------------------------------- */
	public DART6Parser.IDartParser createAdsParser(AdServer_Login__c credential, String dartVersion, OpportunityLineItem item, Map<String, Advertiser__c> mapAdvertiser)
	{
		if(DARTUtil.DART6.equals(dartVersion)) 
		{ 
			return new DART6Parser.DFPResponseToAdsParser(item, credential, mapAdvertiser);
		} 
		return null;  
	} 
	 
	/** -------------------------------- 
		Forecast Parser 
	------------------------------- */
	public DART6Parser.IDARTParser createForecastParser(String dartVersion, OpportunityLineItem item)
	{
		if(DARTUtil.DART6.equals(dartVersion))  
		{  
			return new DART6Parser.DFPResponseToForecastParser(item);
		} 
		return null;
	}
	
	/** -------------------------------- 
		Delivery Parser 
	------------------------------- */
	public DART6Parser.IDARTParser createDeliveryParser(String dartVersion, String sobjType)
	{
		if(DARTUtil.DART6.equals(dartVersion))  
		{  
			return new DART6Parser.Xml6ToDeliveryParser(sobjType);
		} 
		return null;
	}
	
	/** -------------------------------- 
		LineItemPage Parser 
	------------------------------- */ 
	public DART6Parser.IDartParser createLineItemPageParser(String dartVersion)
	{
		if(DARTUtil.DART6.equals(dartVersion))  
		{ 
			return new DART6Parser.DFPResponseToLineItemParser(); 
		}
		return null;
	}
}