/**
	Response mock up for unit test
	Created: 11/12/2012
 
*/
@isTest
public with sharing class DARTMockUp {   
	
	public static String generateDart5Response(HTTPWrapper.IGenericRequest request)
	{
		
		if(request instanceof DART6Message.DART6TokenRequest)
		{
			return 'Auth=xxxxxxxxxxyyyyyyyyyyzzzzzzzzzz'; 
		}
		else if(request instanceof DART6Message.DART6ReportDownloadRequest)
		{
			return DART6_IMPORTDELIVERY_RES_MOCK;
		}
		
		return '';
	}
	
	//DART6_FORECASTSERVICE.getForecastByIdResponse_element response_x;
	public static DART6_FORECASTSERVICE.getForecastResponse_element getMockDart6ForecastResponse_x()
	{
		DART6_FORECASTSERVICE.getForecastResponse_element mockFcRes = new DART6_FORECASTSERVICE.getForecastResponse_element();
		
		DART6_FORECASTSERVICE.Forecast fc = new DART6_FORECASTSERVICE.Forecast();
		fc.availableUnits = 300;
		mockFcRes.rval = fc;
		
		return mockFcRes;
	}
	
	public static DART6_COMPANYSERVICE.createCompaniesResponse_element getMockDart6CompanyResponse_x()
	{
		DART6_COMPANYSERVICE.createCompaniesResponse_element mockRest = new DART6_COMPANYSERVICE.createCompaniesResponse_element();
		DART6_COMPANYSERVICE.Company com = new DART6_COMPANYSERVICE.Company();
		com.id=123456;
		com.type_x='ADVERTISER';
	//	mockRest.rval=com;    old version
	    mockRest.rval=new List<DART6_COMPANYSERVICE.Company>{com};    //New Version 201411
		return mockRest;
	}
	
	public static DART6_FORECASTSERVICE.getForecastByIdResponse_element getMockDart6ForecastByIdResponse_x()
	{
		DART6_FORECASTSERVICE.getForecastByIdResponse_element mockFcRes = new DART6_FORECASTSERVICE.getForecastByIdResponse_element();
		
		DART6_FORECASTSERVICE.Forecast fc = new DART6_FORECASTSERVICE.Forecast();
		fc.availableUnits = 100;
		mockFcRes.rval = fc;
		
		return mockFcRes;
	}
	
	
	public static DART6_USERSERVICE.getUsersByStatementResponse_element getMockDart6UserByStatement_x()
	{
		DART6_USERSERVICE.getUsersByStatementResponse_element mockUserRes = new DART6_USERSERVICE.getUsersByStatementResponse_element();
		DART6_USERSERVICE.UserPage userPage = new DART6_USERSERVICE.UserPage();
		
		DART6_USERSERVICE.User_x user_x = new DART6_USERSERVICE.User_x();
		user_x.name = 'TestingUser';
		user_x.email = 'dart6testuser@gmail.com';
		user_x.id = Long.valueOf('123456');
		
		userPage.results = new List<DART6_USERSERVICE.User_x>{user_x};
		userPage.totalResultSetSize=1;
		
		
		mockUserRes.rval= userPage;
		
		System.debug('---------------------->mockUserRes' + mockUserRes);
		
		return mockUserRes;
	}
	
	
	public static DART6_ORDERSERVICE.createOrdersResponse_element getMockDart6ResponseOrder()
	{
		
		DART6_ORDERSERVICE.createOrdersResponse_element mockOrderRes = new DART6_ORDERSERVICE.createOrdersResponse_element();
		
		DART6_ORDERSERVICE.Order ord = new DART6_ORDERSERVICE.Order();
		ord.advertiserId = Long.valueOf('3333330');
		ord.poNumber ='PO-123';
		ord.id=Long.valueOf('22222');
		ord.traffickerId = Long.valueOf('2145');
		
		// mockOrderRes.rval = ord;    //old version
        mockOrderRes.rval = new List<DART6_ORDERSERVICE.Order>{ord};   //New Version 201411
         
		return mockOrderRes;

	}
	
	public static DART6_LINEITEMSERVICE.createLineItemsResponse_element getMockDart6ResponseLineItem()
	{
		DART6_LINEITEMSERVICE.createLineItemsResponse_element lineItemRes_x = new DART6_LINEITEMSERVICE.createLineItemsResponse_element();
		DART6_LINEITEMSERVICE.LineItem lineItem = new DART6_LINEITEMSERVICE.LineItem();
		
		DART6_LINEITEMSERVICE.Goal gl = new DART6_LINEITEMSERVICE.Goal(); 
		gl.unitType = 'STANDARD';
		
		lineItem.id = Long.valueOf('123456');
	//	lineItem.unitType = 'STANDARD';
		lineItem.costType = 'CPM';
		lineItem.orderId=Long.valueOf('111111');
		lineItem.primaryGoal = gl;
		
		lineItemRes_x.rval = new List<DART6_LINEITEMSERVICE.LineItem>{lineItem};
		return lineItemRes_x;
		
		
		
	} 
	
	public static DART6_LINEITEMSERVICE.createLineItemsResponse_element getMockDart6ResponseLineItem1()
	{
		DART6_LINEITEMSERVICE.createLineItemsResponse_element lineItemRes_x = new DART6_LINEITEMSERVICE.createLineItemsResponse_element();
		DART6_LINEITEMSERVICE.LineItem lineItem = new DART6_LINEITEMSERVICE.LineItem();
		
		DART6_LINEITEMSERVICE.Goal gl = new DART6_LINEITEMSERVICE.Goal(); 
		gl.unitType = 'STANDARD';
		
		lineItem.id = Long.valueOf('123456');
		//lineItem.unitType = 'STANDARD';
		lineItem.costType = 'CPM';
		lineItem.orderId=Long.valueOf('111111');
		lineItem.primaryGoal = gl;
		
		//lineItemRes_x.rval = lineItem;   old version
		lineItemRes_x.rval = new List<DART6_LINEITEMSERVICE.LineItem>{lineItem};
		return lineItemRes_x;
		
	} 
	
	
	public static DART6_LINEITEMSERVICE.updateLineItemsResponse_element getMockDart6ResponseLineItemUpdate()
	{
		DART6_LINEITEMSERVICE.updateLineItemsResponse_element lineItemRes_x = new DART6_LINEITEMSERVICE.updateLineItemsResponse_element();
		DART6_LINEITEMSERVICE.LineItem lineItem = new DART6_LINEITEMSERVICE.LineItem();
		
		DART6_LINEITEMSERVICE.Goal gl = new DART6_LINEITEMSERVICE.Goal(); 
		gl.unitType = 'STANDARD';
		
		lineItem.id = Long.valueOf('123456');
		//lineItem.unitType = 'STANDARD';
		lineItem.costType = 'CPM';
		lineItem.orderId=Long.valueOf('111111');
		lineItem.primaryGoal = gl;
		
		lineItemRes_x.rval = new List<DART6_LINEITEMSERVICE.LineItem>{lineItem};
		return lineItemRes_x;
		
	} 
	
	public static DART6_LINEITEMSERVICE.updateLineItemsResponse_element getMockDart6ResponseLineItemUpdate1()
	{
		DART6_LINEITEMSERVICE.updateLineItemsResponse_element lineItemRes_x = new DART6_LINEITEMSERVICE.updateLineItemsResponse_element();
		DART6_LINEITEMSERVICE.LineItem lineItem = new DART6_LINEITEMSERVICE.LineItem();
		
		DART6_LINEITEMSERVICE.Goal gl = new DART6_LINEITEMSERVICE.Goal(); 
		gl.unitType = 'STANDARD';
		
		lineItem.id = Long.valueOf('123456');
		//lineItem.unitType = 'STANDARD';
		lineItem.costType = 'CPM';
		lineItem.orderId=Long.valueOf('111111');
		lineItem.primaryGoal = gl;
		
		//lineItemRes_x.rval = lineItem;   old version
		lineItemRes_x.rval = new List<DART6_LINEITEMSERVICE.LineItem>{lineItem};
		return lineItemRes_x;
		
	}
	
	public static DART6_REPORTSERVICE.runReportJobResponse_element getMockDart6runReportJobResponse_element(){
		DART6_REPORTSERVICE.runReportJobResponse_element element = new DART6_REPORTSERVICE.runReportJobResponse_element();
		element.rval = new DART6_REPORTSERVICE.ReportJob();
		element.rval.id = 1111111;
		element.rval.reportJobStatus = DART6_REPORTSERVICE.REPORTJOBSTATUS_IN_PROGRESS;
		return element;
	}
	
	public static Dart6_ReportService.getReportJobResponse_element getMockDart6getReportJobResponse_element(){
		Dart6_ReportService.getReportJobResponse_element element = new Dart6_ReportService.getReportJobResponse_element();
		element.rval = new DART6_REPORTSERVICE.ReportJob();
		element.rval.id = 1111111;
		element.rval.reportJobStatus = DART6_REPORTSERVICE.REPORTJOBSTATUS_COMPLETED;
		return element;
	}
	
	public static Dart6_ReportService.getReportDownloadUrlWithOptionsResponse_element getMockDart6getReportDownloadUrlWithOptionsResponse_element(){
		Dart6_ReportService.getReportDownloadUrlWithOptionsResponse_element element = new Dart6_ReportService.getReportDownloadUrlWithOptionsResponse_element();
		element.rval = 'testURLDOWNLOAD';
		return element;
	}
	
	public static DART6_CUSTOMTARGETINGSERVICE.getCustomTargetingValuesByStatementResponse_element getMockDart6CustomKVByStatement()
	{
		DART6_CUSTOMTARGETINGSERVICE.CustomTargetingValue val1 = new DART6_CUSTOMTARGETINGSERVICE.CustomTargetingValue();
		val1.customTargetingKeyId = 11111;
		val1.id = 22222;
		val1.name = 'bmw';
		
		DART6_CUSTOMTARGETINGSERVICE.CustomTargetingValue val2 = new DART6_CUSTOMTARGETINGSERVICE.CustomTargetingValue();
		val2.customTargetingKeyId = 123123;
		val2.id = 66666;
		val2.name = 'red';
		
		DART6_CUSTOMTARGETINGSERVICE.CustomTargetingValue val3 = new DART6_CUSTOMTARGETINGSERVICE.CustomTargetingValue();
		val3.customTargetingKeyId = 123123;
		val3.id = 555555;
		val3.name = 'white';
		
		DART6_CUSTOMTARGETINGSERVICE.CustomTargetingValuePage page1 = new DART6_CUSTOMTARGETINGSERVICE.CustomTargetingValuePage();
		page1.totalResultSetSize = 3;
		page1.startIndex = 3;
		page1.results = new DART6_CUSTOMTARGETINGSERVICE.CustomTargetingValue[]{val1, val2, val3};
		
		
		DART6_CUSTOMTARGETINGSERVICE.getCustomTargetingValuesByStatementResponse_element el = new DART6_CUSTOMTARGETINGSERVICE.getCustomTargetingValuesByStatementResponse_element();
		
		
		el.rval = page1;
		
		return el;
		
	}
	
	public static DART6_CUSTOMTARGETINGSERVICE.createCustomTargetingValuesResponse_element getMockDart6CreateFreeFormValue()
	{
		DART6_CUSTOMTARGETINGSERVICE.CustomTargetingValue val1 = new DART6_CUSTOMTARGETINGSERVICE.CustomTargetingValue();
		val1.customTargetingKeyId = 11111;
		val1.id = 33333;
		val1.name = 'hummer';
		
		DART6_CUSTOMTARGETINGSERVICE.createCustomTargetingValuesResponse_element el = new DART6_CUSTOMTARGETINGSERVICE.createCustomTargetingValuesResponse_element();
		el.rval = new DART6_CUSTOMTARGETINGSERVICE.CustomTargetingValue[]{val1};
		
		return el;
	}
	
	
	//@vitou 23-12-2014
	public static DART6_CUSTOMTARGETINGSERVICE.getCustomTargetingKeysByStatementResponse_element getMockupDart6CustomCriteriaByStatement()
	{ 
		DART6_CUSTOMTARGETINGSERVICE.getCustomTargetingValuesByStatementResponse_element el1 = getMockDart6CustomKVByStatement();
		
		DART6_CUSTOMTARGETINGSERVICE.CustomTargetingKey key = new DART6_CUSTOMTARGETINGSERVICE.CustomTargetingKey();
		key.id = Long.ValueOf('11111');
		key.name = 'test';
		key.displayname = 'test';
		key.type_x = 'FREEFORM';
		key.status = 'test';
			
		DART6_CUSTOMTARGETINGSERVICE.CustomTargetingKeyPage rval = new DART6_CUSTOMTARGETINGSERVICE.CustomTargetingKeyPage();
		rval.results = new list<DART6_CUSTOMTARGETINGSERVICE.CustomTargetingKey>{key};
		rval.startIndex = 0;
		rval.totalResultSetSize = 1;
		
		DART6_CUSTOMTARGETINGSERVICE.getCustomTargetingKeysByStatementResponse_element el = new DART6_CUSTOMTARGETINGSERVICE.getCustomTargetingKeysByStatementResponse_element();
		el.rval = rval;
		return el;		 
	}
	
	/**
	* Added For Importing status
	*/    
	public static DART6_LINEITEMSERVICE.getLineItemsByStatementResponse_element getMockDart6ResponseLineItemByStatement()
	{
		DART6_LINEITEMSERVICE.Date_x datex = new DART6_LINEITEMSERVICE.Date_x();
		datex.day = 1;
		datex.month = 1;
		datex.year = 2014;
		
		DART6_LINEITEMSERVICE.DateTime_x datetimex = new DART6_LINEITEMSERVICE.DateTime_x();
		datetimex.date_x = datex;
		datetimex.hour = 1;
		datetimex.minute = 1;
		datetimex.second = 1;
		
		DART6_LINEITEMSERVICE.AdUnitTargeting adUnitTargeting = new DART6_LINEITEMSERVICE.AdUnitTargeting();
		adUnitTargeting.adUnitId = '1';
		adUnitTargeting.includeDescendants = true;
		
		DART6_LINEITEMSERVICE.InventoryTargeting inventoryTargeting = new DART6_LINEITEMSERVICE.InventoryTargeting();
		inventoryTargeting.targetedAdUnits = new List<DART6_LINEITEMSERVICE.AdUnitTargeting>{adUnitTargeting};
		
		DART6_LINEITEMSERVICE.Location locationCity = new DART6_LINEITEMSERVICE.Location();
		locationCity.id = 1;
		locationCity.type_x = 'City';
		
		DART6_LINEITEMSERVICE.Location locationCountry = new DART6_LINEITEMSERVICE.Location();
		locationCountry.id = 2;
		locationCountry.type_x = 'Country';
		
		DART6_LINEITEMSERVICE.GeoTargeting geoTargeting = new DART6_LINEITEMSERVICE.GeoTargeting();
		geoTargeting.targetedLocations = new List<DART6_LINEITEMSERVICE.Location>{locationCity, locationCountry};
		
		/*** @vitou 22-12-2014 ==> increase code coverage in synDFPLineItem **/
		//Connection Targeting
		DART6_LINEITEMSERVICE.Technology tech1 = new DART6_LINEITEMSERVICE.Technology();
		tech1.id = 3;
		tech1.Technology_Type = 'Device';
		tech1.mobileDeviceCriterionId = 1;
	    
	    DART6_LINEITEMSERVICE.DeviceCategoryTargeting deviceTarget = new DART6_LINEITEMSERVICE.DeviceCategoryTargeting();
	    deviceTarget.targetedDeviceCategories = new list<DART6_LINEITEMSERVICE.technology>{tech1};
	    
	    DART6_LINEITEMSERVICE.Technology tech2 = new DART6_LINEITEMSERVICE.Technology();
	    tech2.id = 4;
	    tech2.Technology_Type = 'BandwidthGroup';
	    DART6_LINEITEMSERVICE.BandwidthGroupTargeting bandwidthGroupTargeting = new DART6_LINEITEMSERVICE.BandwidthGroupTargeting();
	    bandwidthGroupTargeting.bandwidthGroups = new list<DART6_LINEITEMSERVICE.technology>{tech2};
	    bandwidthGroupTargeting.isTargeted = true;
	    
	    DART6_LINEITEMSERVICE.Technology tech3 = new DART6_LINEITEMSERVICE.Technology();
	    tech3.id = 5;
	    tech3.Technology_Type = 'MobileCarrier';
	    DART6_LINEITEMSERVICE.MobileCarrierTargeting mobileCarrierTargeting = new DART6_LINEITEMSERVICE.MobileCarrierTargeting();
	    mobileCarrierTargeting.isTargeted = true;
	    mobileCarrierTargeting.mobileCarriers = new list<DART6_LINEITEMSERVICE.technology>{tech3};
	    
	    
	    DART6_LINEITEMSERVICE.TechnologyTargeting techTarget = new DART6_LINEITEMSERVICE.TechnologyTargeting();
	    techTarget.deviceCategoryTargeting = deviceTarget;
	    techTarget.bandwidthGroupTargeting = bandwidthGroupTargeting;
	    techTarget.mobileCarrierTargeting  = mobileCarrierTargeting;	   
	    
	    //KeyValue Targeting
	    		
		DART6_CUSTOMTARGETINGSERVICE.getCustomTargetingValuesByStatementResponse_element el1 = getMockDart6CustomKVByStatement();
		
		DART6_FORECASTSERVICE.CustomCriteriaNode crit1a = new DART6_FORECASTSERVICE.CustomCriteriaNode();     
	    crit1a.keyId = Long.ValueOf('11111');
	    crit1a.valueIds = new Long[]{Long.ValueOf('22222')};
	    crit1a.operator = 'IS';
	    crit1a.type_x = 'CustomCriteria';
	    
	    DART6_FORECASTSERVICE.CustomCriteriaNode crit2a = new DART6_FORECASTSERVICE.CustomCriteriaNode();     
	    crit2a.keyId = Long.ValueOf('123123');
	    crit2a.valueIds = new Long[]{Long.ValueOf('66666')};
	    crit2a.operator = 'IS';
	    crit2a.type_x = 'CustomCriteria'; 
		
		/***
	    DART6_FORECASTSERVICE.CustomCriteriaNode crit1a = new DART6_FORECASTSERVICE.CustomCriteriaNode();     
	    crit1a.keyId = Long.ValueOf('349093');
	    crit1a.valueIds = new Long[]{Long.ValueOf('57554280013')};
	    crit1a.operator = 'IS';
	    crit1a.type_x = 'CustomCriteria';
	   
	    DART6_FORECASTSERVICE.CustomCriteriaNode crit2a = new DART6_FORECASTSERVICE.CustomCriteriaNode();     
	    crit2a.keyId = Long.ValueOf('349093');
	    crit2a.valueIds = new Long[]{Long.ValueOf('75620325373')};
	    crit2a.operator = 'IS';
	    crit2a.type_x = 'CustomCriteria'; ***/
	    
	    
	    DART6_FORECASTSERVICE.CustomCriteriaNode[] children_level3 = new List<DART6_FORECASTSERVICE.CustomCriteriaNode>();
	    children_level3.add(crit1a);
	    children_level3.add(crit2a);	   	   	   		   
	    
	    DART6_FORECASTSERVICE.CustomCriteriaNode critSet1 = new DART6_FORECASTSERVICE.CustomCriteriaNode();
	    critSet1.logicalOperator = 'AND';
	    critSet1.CustomCriteriaNode_Type = 'CustomCriteriaSet_sub2'; 
	    critset1.children = children_level3;  
	         
	    DART6_FORECASTSERVICE.CustomCriteriaNode[] children_level2 = new List<DART6_FORECASTSERVICE.CustomCriteriaNode>();
	    children_level2.add(critset1);
	   
	   DART6_FORECASTSERVICE.CustomCriteriaSet critSet = new DART6_FORECASTSERVICE.CustomCriteriaSet();
	   critSet.logicalOperator = '0R';
	   critSet.CustomCriteriaNode_Type = 'CustomCriteriaSet_Parents'; 
	   critset.children = children_level2;           
		/** ---------- **/
		 
		DART6_LINEITEMSERVICE.Targeting targeting = new DART6_LINEITEMSERVICE.Targeting();
		targeting.inventoryTargeting = inventoryTargeting;
		targeting.geoTargeting = geoTargeting;
		targeting.technologyTargeting = techTarget;
		targeting.customTargeting = critset;

		
		DART6_LINEITEMSERVICE.Goal gl = new DART6_LINEITEMSERVICE.Goal(); 
		gl.unitType = 'STANDARD';
		
		DART6_LINEITEMSERVICE.LineItem lineItem = new DART6_LINEITEMSERVICE.LineItem();
		lineItem.id = 123456;
//		lineItem.unitType = 'STANDARD';
		lineItem.costType = 'CPM';
		lineItem.orderId = Long.valueOf('111111');
		lineItem.status = 'Delivered';
		lineItem.startDateTime = datetimex;
		lineItem.endDateTime = datetimex;
		lineItem.lastModifiedDateTime = datetimex;
		lineItem.targeting = targeting;
		lineItem.primaryGoal = gl;
		
		DART6_LINEITEMSERVICE.LineItemPage lineItemPage = new DART6_LINEITEMSERVICE.LineItemPage();
		lineItemPage.totalResultSetSize = 1;
		lineItemPage.startIndex = 0;
		lineItemPage.results = new List<DART6_LINEITEMSERVICE.LineItem>{lineItem};
		DART6_LINEITEMSERVICE.getLineItemsByStatementResponse_element el = new DART6_LINEITEMSERVICE.getLineItemsByStatementResponse_element();
		el.rval = lineItemPage;
		return el;
	}
	public final static String DART6_IMPORTDELIVERY_RES_MOCK = '<?xml version=\'1.0\'?>'+
				'<Report reportTimeStamp=\'2013-01-24T10:06:21.832Z\'><HeaderData/><ReportData>'+
				'<ColumnHeaders>'+
				'<ColumnHeader name=\'orderId\' localizedName=\'Order ID\'/>'+
				'<ColumnHeader name=\'lineItemId\' localizedName=\'Line item ID\'/>'+
				'<ColumnHeader name=\'lineitemLifetimeMergedImpressions\' localizedName=\'Ad server impressions\'/>'+
				'<ColumnHeader name=\'lineitemLifetimeMergedClicks\' localizedName=\'Ad server clicks\'/>'+
				'<ColumnHeader name=\'mergeLineItemDeliveryIndicator\' localizedName=\'Delivery indicator\'/></ColumnHeaders>'+
				'<DataSet>'+
				'<Row rowNum=\'1\'><Column name=\'orderId\'><Val>112363990</Val></Column>'+
				'<Column name=\'lineItemId\'><Val>9056470</Val></Column>'+
				'<Column name=\'lineitemLifetimeMergedImpressions\'><Val>640,381</Val></Column>'+
				'<Column name=\'lineitemLifetimeMergedClicks\'><Val>N/A</Val></Column>'+
				'<Column name=\'mergeLineItemDeliveryIndicator\'><Val>167</Val></Column>'+
				'</Row>'+
				'</DataSet></ReportData></Report>';
		
				
	public static LineItemCreativeAssociationService.getLineItemCreativeAssociationsByStatementResponse_element getMockDart6CreativeResponse_x()
	{
		LineItemCreativeAssociationService.LineItemCreativeAssociation lica = new LineItemCreativeAssociationService.LineItemCreativeAssociation();
		lica.creativeId = 56789;
		lica.destinationUrl = 'http://test.test';
		lica.lineItemId = 123456;
		
		
		 
		LineItemCreativeAssociationService.LineItemCreativeAssociationPage page1 = new LineItemCreativeAssociationService.LineItemCreativeAssociationPage();
		page1.totalResultSetSize = 1;
		page1.startIndex = 0;
		page1.results = new LineItemCreativeAssociationService.LineItemCreativeAssociation[]{lica};
		
		LineItemCreativeAssociationService.getLineItemCreativeAssociationsByStatementResponse_element res = new LineItemCreativeAssociationService.getLineItemCreativeAssociationsByStatementResponse_element();
		res.rval = page1;
		
		return res;	
	}  
					
				
}