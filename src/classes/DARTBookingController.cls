public with sharing class DARTBookingController {
	
    List<DARTObject.DARTAds> listAds;
	List<DARTObject.IDARTObjectOrder> lstOrder;
    Map<String, String> mapDartObject = new Map<String, String>();
    
    List<DARTObject.IDARTObjectAds> lstAds;
    
    List<DARTObject.IDARTObjectAdvertiser> lstDartAdvertiser;
    
    Opportunity opp;
    OpportunityLineItem item;
    String dartVersion;
    AdServer_Login__c credential;
    String invokedMethod;
   
   
    /* Contructor */
    public DARTBookingController(Opportunity opp, OpportunityLineItem item)
    {
    	this.opp = opp;
    	this.item = item;
    	
    	dartVersion = item.PricebookEntry.Product2.RecordType.Name;
		credential = DARTUtil.getCredential(dartVersion,item.PriceBookEntry.Product2.Site__r.Country__c);

    }
    
    /** Request to create new Advertiser/Company */
    public void requestCreateAdvertiser()
    {
    	Account[] lstAccs = [Select id, Name, RecordType.name From Account Where id =: opp.AccountId];
    		
		// Request to Create new Advertiser/Company
		if(lstAccs.size() > 0)
		{
			HTTPWrapper.IGenericRequest dartAdvRequest = FactoryDARTRequest.getInstance().createDartSubmitAdvertiserRequest(credential, item, lstAccs.get(0));
	        DART6Parser.IDartParser dartAdvParser = FactoryParser.getInstance().createAdvertiserParser(lstAccs.get(0), dartVersion);
	        DARTObject.IDARTConnector dartAdvCon = FactoryConnector.getInstance().createConnector(dartVersion, dartAdvRequest, dartAdvParser);
	        dartAdvCon.connect();
	        lstDartAdvertiser = (List<DARTObject.IDARTObjectAdvertiser>) dartAdvCon.getDartObjects();
	        invokedMethod = dartAdvRequest.getInvokedMethod();
	        
	        System.debug('\n\n\n ===============> lstDartAdvertiser: ' + lstDartAdvertiser);
	        
		}
		else{
			throw new ExceptionGroup.DARTException('No related Account for this Opportunity.');
		}
    }
    
    
    public void processAndSendOrder(Map<String, Advertiser__c> mapAdvertiser)
    {

		List<DARTObject.DARTPerson> listDartPerson = new List<DARTObject.DARTPerson>();
		Map<String, DARTObject.DARTPerson> mapDartUser = new Map<String, DARTObject.DARTPerson>();
		
    	if(dartVersion.equals(DARTUtil.DART6))
    	{
    		// Request to get User/Traficker ID (DART USER ID) 
	    	HTTPWrapper.IGenericRequest dartListSalesPerson = FactoryDARTRequest.getInstance().createDartSubmitSalePersonRequest('', credential, item, opp);
	        DART6Parser.IDartParser salespersonParser = FactoryParser.getInstance().createSalespersonParser(dartVersion);
	        DARTObject.IDARTConnector personCon = FactoryConnector.getInstance().createConnector(dartVersion, dartListSalesPerson, salespersonParser);
	        personCon.connect();
	        listDartPerson.addAll((List<DARTObject.DARTPerson>)personCon.getDartObjects());
	        
    	}
    	
    	System.debug('=============> listDartPerson:' + listDartPerson);

        List<OpportunityTeamMember> lstOppTeamMember = DARTUtil.getOpportunityTeamMember(opp.id);
		
        for(DARTObject.DARTPerson p : listDartPerson)
        {
        	if(lstOppTeamMember.size()>0){
        		
        		if((lstOppTeamMember.get(0).User.Name).equals(p.getDartName()))
	        	{
	        		mapDartUser.put(lstOppTeamMember.get(0).User.Name, p);
	        	}
        	}else{
        		if((credential.User_Name__c).equals(p.getUserEmail()))
	        	{
	        		mapDartUser.put(credential.User_Name__c, p);
	        	}
        	}
        	
        	if((opp.Owner.Name).equals(p.getDartName()))
        	{
        		mapDartUser.put(opp.Owner.Name, p);
        	}
        }
        
        System.debug('===============> mapDartUser: ' + mapDartUser);
       
    	// Order Request 
        HTTPWrapper.IGenericRequest dartSubmitOrderReq = FactoryDARTRequest.getInstance().createDARTSubmitOrderRequest(credential, opp, item, mapDartUser, mapAdvertiser);
        DART6Parser.IDartParser orderParser = FactoryParser.getInstance().createOrderParser(credential, dartVersion, opp);
        DARTObject.IDARTConnector orderCon = FactoryConnector.getInstance().createConnector(dartVersion, dartSubmitOrderReq, orderParser);
        orderCon.connect(); 
        invokedMethod = dartSubmitOrderReq.getInvokedMethod();
        lstOrder = (List<DARTObject.IDARTObjectOrder>)orderCon.getDartObjects();
        
        System.debug('====================> lstOrder: ' + lstOrder);
         
    }
     
   
    public void processAndSendLineItem(DARTObject.IDARTObjectOrder dartOrder, Map<String, Advertiser__c> mapAdvertiser)
    {
        // LineItem Request

        HTTPWrapper.IGenericRequest dartSubmitAdsReq = FactoryDARTRequest.getInstance().createDARTSubmitAdsRequest(credential, item, dartOrder, opp);
        DART6Parser.IDartParser adsParser = FactoryParser.getInstance().createAdsParser(credential, dartVersion, item, mapAdvertiser);
        DARTObject.IDARTConnector adsCon = FactoryConnector.getInstance().createConnector(dartVersion, dartSubmitAdsReq, adsParser);
        adsCon.connect();
        invokedMethod = dartSubmitAdsReq.getInvokedMethod();
        lstAds = (List<DARTObject.IDARTObjectAds>)adsCon.getDartObjects();
        System.debug('=====================> ads: ' + lstAds);
        
		
    }
    
    public List<DARTObject.IDARTObjectAdvertiser> getListAdvertiser()
    {
    	return lstDartAdvertiser;
    }
    
    public List<DARTObject.IDARTObjectAds> getListAds()
    {
    	return lstAds;
    }
    
    public List<DARTObject.IDARTObjectOrder> getListOrder()
    {
    	return lstOrder;
    }
	
	public String getInvokedMethod() 
	{
		return invokedMethod;
	}
	
}