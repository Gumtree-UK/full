/**
    Test all classes(DART) Forecast/Booking/Delivery
    
    Created date: 12/02/2013
 */


@isTest 
public with sharing class TestDARTCodeCoverage {

    public static TestDataGenerator testDATA = new TestDataGenerator();
    
    
    /** DART6 Request Forecast By LineItem */ 
    static testMethod void testDART6RequestForecast()
    {
        
        Test.startTest();
        
	        // Generate data opp/oppItem
	        testDATA.createCredential();
	        testDATA.createTargetingHierarchy();
	        testDATA.createAccount();
	        testDATA.createAdvertiser();
	        testDATA.createOpp(testDATA.lstAcc.get(0));
	        testDATA.createOppTeamMember(testDATA.opp.id);
	        testDATA.createNewOppItemsDart(testDATA.opp.id,2,DARTUtil.DART6,testDATA.targetting[0].Id);
	        List<OpportunityLineItem> items = testDATA.getOppItem(testDATA.opp.id, new Set<String>{testDATA.lstLineItems.get(0).id});
	        
	        // Dart6Message
	        DART6Message dart6Msg = new DART6Message();
	        // Dart6Parser
	        DART6Parser dart6Parser = new DART6Parser();
	        // DartObject
	        DARTObject dartObj = new DARTObject();
	        DARTObject.DARTForecast dartFc = new DARTObject.DARTForecast(items.get(0));
	        
	        List<OpportunityLineItem> items2 = testDATA.getOppItem(testDATA.opp.id, new Set<String>{testDATA.lstLineItems.get(1).id});
	        // ForecastController
	        ForecastController fcCont2 = new ForecastController(items2.get(0));
	        fcCont2.forecastProcess();
	        List<DARTObject.DARTForecast> lstFc2 = fcCont2.getObjectForecast();
        
        Test.stopTest();
        
        // Forecast Request by lineItem
        System.assertEquals('300', lstFc2.get(0).getAvailableUnits(), '300, Test data from DARTMokup');
        System.assertEquals('getForecast', fcCont2.getInvokedMethod(), '');
        
        System.assertEquals('Multiformat1', dartFC.getPackage(), '');
        System.assertEquals('200', dartFC.getQuantity()+'', '');
        System.assertEquals('Test Desc', dartFC.getLineDesc(), '');
        System.assertEquals('Test product0', dartFC.getProductName(), '');
        
    }
  
    /** Test DART6 Booking */  
    static testMethod void testDART6Booking()
    {
        
    
        Test.startTest();
	        // Generate data opp/oppItem
	        testDATA.createCredential();
	        testDATA.createTargetingHierarchy();
	        testDATA.createAccount();
	        testDATA.createAdvertiser();
	        testDATA.createOpp(testDATA.lstAcc.get(0));
	        testDATA.createOppTeamMember(testDATA.opp.id);
	        testDATA.createNewOppItemsDart(testDATA.opp.id,2,DARTUtil.DART6,testDATA.targetting[0].Id);
	        List<OpportunityLineItem> items = testDATA.getOppItem(testDATA.opp.id, new Set<String>{testDATA.lstLineItems.get(0).id});
	        
	        Opportunity opp = testDATA.getOppty(testDATA.opp.id);
	        
	        // Dart6Message
	        DART6Message dart6Msg = new DART6Message();
	        // Dart6Parser
	        DART6Parser dart6Parser = new DART6Parser();
	        // DartObject
	        DARTObject dartObj = new DARTObject();
	        // DARTMockUp
	        DARTMockUp mockupdata = new DARTMockUp();
	        
	        DARTObject.DARTForecast dartFc = new DARTObject.DARTForecast(items.get(0));
	        
	        List<OpportunityLineItem> items2 = testDATA.getOppItem(testDATA.opp.id, new Set<String>{testDATA.lstLineItems.get(1).id});
	        // Booking
	        DARTBookingController bookingCont2 = new DARTBookingController(opp, items2.get(0));
	        
	        bookingCont2.requestCreateAdvertiser();
	        List<DARTObject.IDARTObjectAdvertiser> lstAdv = bookingCont2.getListAdvertiser();
	        
	        
	         Advertiser__c adv = new Advertiser__c(Dart6_Advertiser_Id__c=lstAdv.get(0).getDartId());
	        
	        Map<String, Advertiser__c> mapAdvertiser = new Map<String, Advertiser__c>();
	        mapAdvertiser.put(DARTUtil.DART6, adv);
	        
	        bookingCont2.processAndSendOrder(mapAdvertiser);
	        List<DARTObject.IDARTObjectOrder> lstOrder = bookingCont2.getListOrder();
	        bookingCont2.processAndSendLineItem(lstOrder.get(0), mapAdvertiser);
	        List<DARTObject.IDARTObjectAds> lstAds = bookingCont2.getListAds();
	        
	         //@vitou 19-12-2014 --> Test method in DARTUtil.cls */      
            string str = DARTUtil.generateTableCompaignItems(lstAds);       
            str = DARTUtil.generateTableCompaigns(lstOrder);            
            
        Test.stopTest();
        
        // Result 
        
        // Advertiser
        
        System.assertEquals('123456', lstAdv.get(0).getDartId(), '123456, Test data from DARTMokup');
        
        // Order
        System.assertEquals('22222', lstOrder.get(0).getDartId(), '22222, Test data from DARTMokup');
         
        //LineItem
        System.assertEquals('123456', lstAds.get(0).getDartId(), '123456, Test data from DARTMokup');
        System.assertEquals('111111', lstAds.get(0).getOrder().getDartId(), '111111, Test data from DARTMokup');
        System.assertEquals('Create LineItem/Ads', bookingCont2.getInvokedMethod());
        
    } 
    
    
    /** Test DART6 DeliveryReport */ 
    
    static testMethod void testDART6DeliveryReport()
    {
        testDATA.createCredential();
        
        DART_Delivery_Support__c dds = new DART_Delivery_Support__c(
                AdServer_Login__c=testDATA.listLogin.get(1).id,
                Schedule_Type__c = 'Daily',
                Sobject__c = 'Opportunity Product',
                Status__c = 'New',
                Attempt__c = 0
                );
        insert dds;
        test.startTest();
        
        dds = DeliveryController.getDeliverySupportRecord(dds.Id);
        DART6_REPORTSERVICE.REPORTServiceInterfacePort reportService = DeliveryController.buildQueryService(dds);
        DeliveryController devCont = new DeliveryController(dds);
        
        devCont.setReportService(reportService);
        devCont.importDelivery();
        
        DeliveryController.checkJobStatus(dds);
        DeliveryController.startNextAdServer('Opportunity Product', 'Monthly');
        DeliveryController.start('Monthly', 'Opportunity Product');
        DeliveryController.doStart(dds);
        
        DeliveryController.processBatchDelivery(dds, devCont.getListDart());
        DeliveryController devCont2 = new DeliveryController(dds);
        DeliveryController devCont3 = new DeliveryController(testDATA.listLogin.get(1), DART6Message.BREAKDOWN_DAILY, DART6Message.DATERANGE_YESTERDAY);
        
        test.stopTest();
    }
    
     /** Test DART6 Update Targeting Options */ 
    static testMethod void testSyncDFPLineItem(){
    	SyncDFPLineItem obj = new SyncDFPLineItem();
        testDATA.createCredential();
        testDATA.createTargetingHierarchy();
        testDATA.createAccount();
        testDATA.createAdvertiser();
        testDATA.createOpp(testDATA.lstAcc.get(0));
        testDATA.createOppTeamMember(testDATA.opp.id);
        testDATA.createNewOppItemsDart(testDATA.opp.id,2,DARTUtil.DART6,testDATA.targetting[0].Id);
        testDATA.lstLineItems.get(0).Ad_Id__c = '123456';
        update testDATA.lstLineItems.get(0);
        
        City__c city = new City__c(Dart_ID__c = 1);
        insert city;
        Country__c country = new Country__c(Dart_ID__c = 2);
        insert country;
        Content__c content = new Content__c(Name = '1');
        insert content;
        
        Geography__c geography_par = new Geography__c(Dart_ID__c = 50);
        insert geography_par;
        
        Geography__c geography_sub = new Geography__c(Dart_ID__c = 51, Node_Id__c = geography_par.id );
        insert geography_sub;
        
        Geography__c geography = new Geography__c(Dart_ID__c = 1, Node_Id__c = geography_sub.id );
        insert geography;
        
        Devices__c device_par = new Devices__c(Dart_ID__c = 51);
        insert device_par; 
        
        Devices__c device_sub = new Devices__c(Dart_ID__c = 52,Node_Id__c = device_par.id);
        insert device_sub;
        
        Devices__c device = new Devices__c(Dart_ID__c = 3, Node_Id__c = device_sub.id);
        insert device;               
        
    	Test.startTest();
    		SyncDFPLineItem.startScheduler();
    	Test.stopTest();
    }
   
    /** Class DART6_COMPANYSERVICE*/ 
	static testMethod void testClassDART6_COMPANYSERVICE()
	{
		DART6_COMPANYSERVICE companyService = new DART6_COMPANYSERVICE();
		DART6_COMPANYSERVICE.CompanyServiceInterfacePort compInPort = new DART6_COMPANYSERVICE.CompanyServiceInterfacePort();
		DART6_COMPANYSERVICE.CommonError comErr = new DART6_COMPANYSERVICE.CommonError();
		DART6_COMPANYSERVICE.InternalApiError inApiErr = new DART6_COMPANYSERVICE.InternalApiError();
		//DART6_COMPANYSERVICE.Authentication authen = new DART6_COMPANYSERVICE.Authentication();
		DART6_COMPANYSERVICE.BooleanValue bv = new DART6_COMPANYSERVICE.BooleanValue();
		DART6_COMPANYSERVICE.AppliedLabel appLabel = new DART6_COMPANYSERVICE.AppliedLabel();
		DART6_COMPANYSERVICE.updateCompaniesResponse_element updateResEle = new DART6_COMPANYSERVICE.updateCompaniesResponse_element();
		DART6_COMPANYSERVICE.UniqueError uniquErr = new DART6_COMPANYSERVICE.UniqueError();
		DART6_COMPANYSERVICE.RequiredError requiErr  = new DART6_COMPANYSERVICE.RequiredError();
		DART6_COMPANYSERVICE.SetValue setval = new DART6_COMPANYSERVICE.SetValue();
		DART6_COMPANYSERVICE.AuthenticationError authErr = new DART6_COMPANYSERVICE.AuthenticationError();
		DART6_COMPANYSERVICE.PermissionError perErr = new DART6_COMPANYSERVICE.PermissionError();
		DART6_COMPANYSERVICE.PublisherQueryLanguageSyntaxError pubQuLangSynErr = new DART6_COMPANYSERVICE.PublisherQueryLanguageSyntaxError();
//		DART6_COMPANYSERVICE.getCompany_element getComEle = new DART6_COMPANYSERVICE.getCompany_element();
		DART6_COMPANYSERVICE.String_ValueMapEntry valueMapEnty = new DART6_COMPANYSERVICE.String_ValueMapEntry();
		DART6_COMPANYSERVICE.StringLengthError strLenErr = new DART6_COMPANYSERVICE.StringLengthError();
		DART6_COMPANYSERVICE.Value v = new DART6_COMPANYSERVICE.Value();
		DART6_COMPANYSERVICE.getCompaniesByStatementResponse_element getComByStatResEle = new DART6_COMPANYSERVICE.getCompaniesByStatementResponse_element();
		//DART6_COMPANYSERVICE.OAuth oauth = new DART6_COMPANYSERVICE.OAuth();
		DART6_COMPANYSERVICE.createCompanies_element createComEle = new DART6_COMPANYSERVICE.createCompanies_element();
		DART6_COMPANYSERVICE.CompanyPage comPage = new DART6_COMPANYSERVICE.CompanyPage();
		DART6_COMPANYSERVICE.FeatureError FeatureErr = new DART6_COMPANYSERVICE.FeatureError();
		DART6_COMPANYSERVICE.updateCompaniesResponse_element upComResEle = new DART6_COMPANYSERVICE.updateCompaniesResponse_element();
		DART6_COMPANYSERVICE.TypeError typeErr = new DART6_COMPANYSERVICE.TypeError();
		DART6_COMPANYSERVICE.NumberValue numErr = new DART6_COMPANYSERVICE.NumberValue();
		DART6_COMPANYSERVICE.Company comp = new DART6_COMPANYSERVICE.Company();
		DART6_COMPANYSERVICE.SoapResponseHeader soapResHeader = new DART6_COMPANYSERVICE.SoapResponseHeader();
		//DART6_COMPANYSERVICE.CustomCriteriaSet custCriSet = new DART6_COMPANYSERVICE.CustomCriteriaSet();
		DART6_COMPANYSERVICE.NotNullError notNullErr = new DART6_COMPANYSERVICE.NotNullError();
		DART6_COMPANYSERVICE.createCompaniesResponse_element createComResEle = new DART6_COMPANYSERVICE.createCompaniesResponse_element();
		//DART6_COMPANYSERVICE.AudienceSegmentCriteria audienceSegCrit = new DART6_COMPANYSERVICE.AudienceSegmentCriteria();
		DART6_COMPANYSERVICE.updateCompanies_element updateComEle = new DART6_COMPANYSERVICE.updateCompanies_element();
		DART6_COMPANYSERVICE.DateTimeValue dateValue = new DART6_COMPANYSERVICE.DateTimeValue();
		DART6_COMPANYSERVICE.getCompaniesByStatement_element getComByState = new DART6_COMPANYSERVICE.getCompaniesByStatement_element();
		DART6_COMPANYSERVICE.CompanyCreditStatusError comCrStatusErr = new DART6_COMPANYSERVICE.CompanyCreditStatusError();
		DART6_COMPANYSERVICE.Statement st = new DART6_COMPANYSERVICE.Statement();
		DART6_COMPANYSERVICE.PublisherQueryLanguageContextError publiConErro = new DART6_COMPANYSERVICE.PublisherQueryLanguageContextError();
		DART6_COMPANYSERVICE.ApiError apiErr = new DART6_COMPANYSERVICE.ApiError();
		DART6_COMPANYSERVICE.Date_x dtx = new DART6_COMPANYSERVICE.Date_x();
		DART6_COMPANYSERVICE.SoapRequestHeader soapReqHe = new DART6_COMPANYSERVICE.SoapRequestHeader();
		DART6_COMPANYSERVICE.TeamError teamErr = new DART6_COMPANYSERVICE.TeamError();
		DART6_COMPANYSERVICE.createCompaniesResponse_element createCompaniesResEle = new DART6_COMPANYSERVICE.createCompaniesResponse_element();
//		DART6_COMPANYSERVICE.getCompanyResponse_element getComResEle = new DART6_COMPANYSERVICE.getCompanyResponse_element();
		DART6_COMPANYSERVICE.ApiException apiExc = new DART6_COMPANYSERVICE.ApiException();
		DART6_COMPANYSERVICE.QuotaError quaErr = new DART6_COMPANYSERVICE.QuotaError();
		DART6_COMPANYSERVICE.ApplicationException appExc = new DART6_COMPANYSERVICE.ApplicationException();
		DART6_COMPANYSERVICE.ParseError parseErr = new DART6_COMPANYSERVICE.ParseError();
		DART6_COMPANYSERVICE.ApiVersionError apiVerErr = new DART6_COMPANYSERVICE.ApiVersionError();
		DART6_COMPANYSERVICE.LabelEntityAssociationError labelAssErr = new DART6_COMPANYSERVICE.LabelEntityAssociationError();
		DART6_COMPANYSERVICE.ServerError serErr = new DART6_COMPANYSERVICE.ServerError();
		DART6_COMPANYSERVICE.DateTime_x datetimex = new DART6_COMPANYSERVICE.DateTime_x();
		DART6_COMPANYSERVICE.StatementError stateErr = new DART6_COMPANYSERVICE.StatementError();
		//DART6_COMPANYSERVICE.ClientLogin clLog = new DART6_COMPANYSERVICE.ClientLogin();
		//DART6_COMPANYSERVICE.CreativePlaceholder createPh = new DART6_COMPANYSERVICE.CreativePlaceholder();
		DART6_COMPANYSERVICE.TextValue txtVal = new DART6_COMPANYSERVICE.TextValue();
		DART6_COMPANYSERVICE.InvalidEmailError invErr = new DART6_COMPANYSERVICE.InvalidEmailError();
		DART6_COMPANYSERVICE.updateCompanies_element updComEle = new DART6_COMPANYSERVICE.updateCompanies_element();
		DART6_COMPANYSERVICE.createCompanies_element createCompaniesEle = new DART6_COMPANYSERVICE.createCompanies_element();
		
		
	}
	
	
	/** Class DART6_USERSERVICE */ 
	static testMethod void testClassDART6_USERSERVICE()
	{
		DART6_USERSERVICE userService=new DART6_USERSERVICE();
		DART6_USERSERVICE orderService = new DART6_USERSERVICE();
		DART6_USERSERVICE.CommonError comError = new DART6_USERSERVICE.CommonError();
		DART6_USERSERVICE.InternalApiError inApi = new DART6_USERSERVICE.InternalApiError();
		DART6_USERSERVICE.performUserActionResponse_element pUserAc = new DART6_USERSERVICE.performUserActionResponse_element();
		DART6_USERSERVICE.getUsersByStatementResponse_element userBySt = new DART6_USERSERVICE.getUsersByStatementResponse_element();
		//DART6_USERSERVICE.updateUser_element upUser = new DART6_USERSERVICE.updateUser_element();
		DART6_USERSERVICE.BooleanValue bv = new DART6_USERSERVICE.BooleanValue();
		DART6_USERSERVICE.RequiredError reqerr = new DART6_USERSERVICE.RequiredError();
		DART6_USERSERVICE.PermissionError perErr = new DART6_USERSERVICE.PermissionError();
		DART6_USERSERVICE.AuthenticationError autErr = new DART6_USERSERVICE.AuthenticationError();
		DART6_USERSERVICE.PublisherQueryLanguageSyntaxError pquLaSyn = new DART6_USERSERVICE.PublisherQueryLanguageSyntaxError();
		DART6_USERSERVICE.createUsers_element createUsE = new DART6_USERSERVICE.createUsers_element();
		DART6_USERSERVICE.getAllRolesResponse_element allRolRe = new DART6_USERSERVICE.getAllRolesResponse_element();
		DART6_USERSERVICE.String_ValueMapEntry stValMaEn = new DART6_USERSERVICE.String_ValueMapEntry();
		DART6_USERSERVICE.Value val = new DART6_USERSERVICE.Value();
        //DART6_USERSERVICE.OAuth oau = new DART6_USERSERVICE.OAuth();
		//DART6_USERSERVICE.createUser_element crUserElement = new DART6_USERSERVICE.createUser_element();
		DART6_USERSERVICE.performUserAction_element perUsAct = new DART6_USERSERVICE.performUserAction_element();
		DART6_USERSERVICE.createUsersResponse_element creatUserResEle = new DART6_USERSERVICE.createUsersResponse_element();
		DART6_USERSERVICE.updateUsersResponse_element updUseResEle = new DART6_USERSERVICE.updateUsersResponse_element();
		DART6_USERSERVICE.TypeError typErr = new DART6_USERSERVICE.TypeError();
		DART6_USERSERVICE.UserAction usAc = new DART6_USERSERVICE.UserAction();
		DART6_USERSERVICE.updateUsers_element updatUs = new DART6_USERSERVICE.updateUsers_element();
		DART6_USERSERVICE.NumberValue numVal = new DART6_USERSERVICE.NumberValue();
		DART6_USERSERVICE.createUsersResponse_element createUsResEle = new DART6_USERSERVICE.createUsersResponse_element();
		DART6_USERSERVICE.SoapResponseHeader soapResHeader = new DART6_USERSERVICE.SoapResponseHeader();
		//DART6_USERSERVICE.getUser_element getUserEle = new DART6_USERSERVICE.getUser_element();
		DART6_USERSERVICE.NotNullError notNullErr = new DART6_USERSERVICE.NotNullError();
		//DART6_USERSERVICE.getUserResponse_element getUserResEle = new DART6_USERSERVICE.getUserResponse_element();
		DART6_USERSERVICE.Statement str = new DART6_USERSERVICE.Statement();
		DART6_USERSERVICE.PublisherQueryLanguageContextError pbLaCon = new DART6_USERSERVICE.PublisherQueryLanguageContextError();
		DART6_USERSERVICE.ApiError ApiErr = new DART6_USERSERVICE.ApiError();
		DART6_USERSERVICE.Date_x datex = new DART6_USERSERVICE.Date_x();
		DART6_USERSERVICE.SoapRequestHeader soapResHder = new DART6_USERSERVICE.SoapRequestHeader();
		DART6_USERSERVICE.getUsersByStatement_element userByStaEle = new DART6_USERSERVICE.getUsersByStatement_element();
		DART6_USERSERVICE.ApiException apiExeption = new DART6_USERSERVICE.ApiException();
		DART6_USERSERVICE.getAllRoles_element getAllRolesEle = new DART6_USERSERVICE.getAllRoles_element();
		DART6_USERSERVICE.QuotaError quaErr = new DART6_USERSERVICE.QuotaError();
		//DART6_USERSERVICE.updateUserResponse_element upUserResEle = new DART6_USERSERVICE.updateUserResponse_element();
		DART6_USERSERVICE.UserRecord uRec = new DART6_USERSERVICE.UserRecord();
		DART6_USERSERVICE.ApplicationException appExcep = new DART6_USERSERVICE.ApplicationException();
		DART6_USERSERVICE.ParseError parErr = new DART6_USERSERVICE.ParseError();
		DART6_USERSERVICE.ServerError serErr = new DART6_USERSERVICE.ServerError();
		DART6_USERSERVICE.DateTime_x dateTimex = new DART6_USERSERVICE.DateTime_x();
		//DART6_USERSERVICE.ClientLogin clLog = new DART6_USERSERVICE.ClientLogin();
		DART6_USERSERVICE.TextValue txtVal = new DART6_USERSERVICE.TextValue();
		DART6_USERSERVICE.InvalidEmailError invaemailErr = new DART6_USERSERVICE.InvalidEmailError();
		DART6_USERSERVICE.getCurrentUser_element curEle = new DART6_USERSERVICE.getCurrentUser_element();
		DART6_USERSERVICE.Role rol = new DART6_USERSERVICE.Role();
		DART6_USERSERVICE.UpdateResult upResult = new DART6_USERSERVICE.UpdateResult();
		DART6_USERSERVICE.ActivateUsers activeUser = new DART6_USERSERVICE.ActivateUsers();
		DART6_USERSERVICE.StatementError stErr = new DART6_USERSERVICE.StatementError();
		DART6_USERSERVICE.getCurrentUserResponse_element curUsRes = new DART6_USERSERVICE.getCurrentUserResponse_element();
		DART6_USERSERVICE.FeatureError feaErr = new DART6_USERSERVICE.FeatureError();
		DART6_USERSERVICE.DropDownCustomFieldValue dropCusFv = new DART6_USERSERVICE.DropDownCustomFieldValue();
		DART6_USERSERVICE.BaseCustomFieldValue baseCusFv = new DART6_USERSERVICE.BaseCustomFieldValue();
		DART6_USERSERVICE.CustomFieldValue custFv = new DART6_USERSERVICE.CustomFieldValue();
		DART6_USERSERVICE.TeamError teamErr = new DART6_USERSERVICE.TeamError();
		DART6_USERSERVICE.CustomFieldValueError custFvErr = new DART6_USERSERVICE.CustomFieldValueError();
		DART6_USERSERVICE.DateValue dv = new DART6_USERSERVICE.DateValue();
		DART6_USERSERVICE.ApiVersionError apivErr = new DART6_USERSERVICE.ApiVersionError();
		
		//@vitou 19-12-2014 ==> new Version 201411
        DART6_USERSERVICE.SetValue setVal = new DART6_USERSERVICE.SetValue();
        DART6_USERSERVICE.BooleanValue boolVal = new DART6_USERSERVICE.BooleanValue();
        DART6_USERSERVICE.UniqueError uniqErr = new DART6_USERSERVICE.UniqueError();
        DART6_USERSERVICE.FeatureError featErr = new DART6_USERSERVICE.FeatureError();
        DART6_USERSERVICE.DropDownCustomFieldValue ddCustFldVal = new DART6_USERSERVICE.DropDownCustomFieldValue();
        DART6_USERSERVICE.UserPage userPage = new DART6_USERSERVICE.UserPage();
        DART6_USERSERVICE.BaseCustomFieldValue baseCustFldVal = new DART6_USERSERVICE.BaseCustomFieldValue();
        DART6_USERSERVICE.CustomFieldValue custFldVal = new DART6_USERSERVICE.CustomFieldValue();
        DART6_USERSERVICE.DateTimeValue dtVal = new DART6_USERSERVICE.DateTimeValue();
        DART6_USERSERVICE.TokenError tokenErr = new DART6_USERSERVICE.TokenError();
        DART6_USERSERVICE.ObjectValue objVal = new DART6_USERSERVICE.ObjectValue();
        DART6_USERSERVICE.CustomFieldValueError custFldValErr = new DART6_USERSERVICE.CustomFieldValueError();
        DART6_USERSERVICE.DateValue dateVal = new DART6_USERSERVICE.DateValue();
        DART6_USERSERVICE.ApiVersionError apiVerErr = new DART6_USERSERVICE.ApiVersionError();
        DART6_USERSERVICE.DeactivateUsers deactUser = new DART6_USERSERVICE.DeactivateUsers();
		
	}
	
	/** Class DART6_ORDERSERVICE */   
	static testMethod void testClassDART6_ORDERSERVICE()
	{
		DART6_ORDERSERVICE orderService = new DART6_ORDERSERVICE();
		
		DART6_ORDERSERVICE.CommonError ordComErr = new DART6_ORDERSERVICE.CommonError();
		DART6_ORDERSERVICE.ApproveOrdersWithoutReservationChanges ordApWithCh = new DART6_ORDERSERVICE.ApproveOrdersWithoutReservationChanges();
		DART6_ORDERSERVICE.InternalApiError ordInApiErr = new DART6_ORDERSERVICE.InternalApiError();
		DART6_ORDERSERVICE.updateOrders_element ordUpOrdEle = new DART6_ORDERSERVICE.updateOrders_element();
		DART6_ORDERSERVICE.ApproveOrders ordAppOrd = new DART6_ORDERSERVICE.ApproveOrders();
		DART6_ORDERSERVICE.OrderError ordErr = new DART6_ORDERSERVICE.OrderError();
		DART6_ORDERSERVICE.SubmitOrdersForApprovalAndOverbook ordSubOrdOver = new DART6_ORDERSERVICE.SubmitOrdersForApprovalAndOverbook();
		DART6_ORDERSERVICE.StringLengthError ordStringErr = new DART6_ORDERSERVICE.StringLengthError();
		DART6_ORDERSERVICE.createOrdersResponse_element ordCreRes = new DART6_ORDERSERVICE.createOrdersResponse_element();
		DART6_ORDERSERVICE.BooleanValue ordBooVal = new DART6_ORDERSERVICE.BooleanValue();
		DART6_ORDERSERVICE.AppliedLabel ordApLab = new DART6_ORDERSERVICE.AppliedLabel();
		DART6_ORDERSERVICE.UniqueError ordUniErr = new DART6_ORDERSERVICE.UniqueError();
		DART6_ORDERSERVICE.RequiredError ordReErr = new DART6_ORDERSERVICE.RequiredError();
		DART6_ORDERSERVICE.PauseOrders ordPauOrd = new DART6_ORDERSERVICE.PauseOrders();
		DART6_ORDERSERVICE.OrderPage ordPage = new DART6_ORDERSERVICE.OrderPage();
		DART6_ORDERSERVICE.AuthenticationError ordAuthErr = new DART6_ORDERSERVICE.AuthenticationError();
		DART6_ORDERSERVICE.PermissionError ordPerErr = new DART6_ORDERSERVICE.PermissionError();
		DART6_ORDERSERVICE.PublisherQueryLanguageSyntaxError ordPUSyErr = new DART6_ORDERSERVICE.PublisherQueryLanguageSyntaxError();
		DART6_ORDERSERVICE.DisapproveOrders ordDisOrd = new DART6_ORDERSERVICE.DisapproveOrders();
		DART6_ORDERSERVICE.String_ValueMapEntry ordStMapEnt = new DART6_ORDERSERVICE.String_ValueMapEntry();
		DART6_ORDERSERVICE.createOrdersResponse_element ordCreResEle = new DART6_ORDERSERVICE.createOrdersResponse_element();
		DART6_ORDERSERVICE.Value ordVal = new DART6_ORDERSERVICE.Value();
		DART6_ORDERSERVICE.DropDownCustomFieldValue ordDroFv = new DART6_ORDERSERVICE.DropDownCustomFieldValue();
		//DART6_ORDERSERVICE.OAuth ordOauth = new DART6_ORDERSERVICE.OAuth();
		DART6_ORDERSERVICE.ArchiveOrders ordArOrd = new DART6_ORDERSERVICE.ArchiveOrders();
		DART6_ORDERSERVICE.BaseCustomFieldValue ordBasFV = new DART6_ORDERSERVICE.BaseCustomFieldValue();
		DART6_ORDERSERVICE.TypeError ordTypErr = new DART6_ORDERSERVICE.TypeError();
		DART6_ORDERSERVICE.updateOrdersResponse_element ordUpdRes = new DART6_ORDERSERVICE.updateOrdersResponse_element();
		DART6_ORDERSERVICE.getOrdersByStatement_element ordOrdStaEle = new DART6_ORDERSERVICE.getOrdersByStatement_element();
		DART6_ORDERSERVICE.NumberValue ordNumVal = new DART6_ORDERSERVICE.NumberValue();
		DART6_ORDERSERVICE.SoapResponseHeader ordSoapRes = new DART6_ORDERSERVICE.SoapResponseHeader();
		DART6_ORDERSERVICE.CustomFieldValue ordCusFv = new DART6_ORDERSERVICE.CustomFieldValue();
		DART6_ORDERSERVICE.updateOrdersResponse_element ordUpdRs = new DART6_ORDERSERVICE.updateOrdersResponse_element();
		DART6_ORDERSERVICE.updateOrders_element ordupOrd = new DART6_ORDERSERVICE.updateOrders_element();
		DART6_ORDERSERVICE.SubmitOrdersForApprovalWithoutReservationChanges ordsubForAPch = new DART6_ORDERSERVICE.SubmitOrdersForApprovalWithoutReservationChanges();
		DART6_ORDERSERVICE.NotNullError ordNotNullErr = new DART6_ORDERSERVICE.NotNullError();
		DART6_ORDERSERVICE.SubmitOrdersForApproval ordSuAppva = new DART6_ORDERSERVICE.SubmitOrdersForApproval();
		DART6_ORDERSERVICE.ResumeAndOverbookOrders ordResOvOrd = new DART6_ORDERSERVICE.ResumeAndOverbookOrders();
		DART6_ORDERSERVICE.DateTimeValue ordDateVal = new DART6_ORDERSERVICE.DateTimeValue();
		DART6_ORDERSERVICE.Statement ordStat = new DART6_ORDERSERVICE.Statement();
		DART6_ORDERSERVICE.CompanyCreditStatusError ordComStat = new DART6_ORDERSERVICE.CompanyCreditStatusError();
		DART6_ORDERSERVICE.createOrders_element ordcreOrd = new DART6_ORDERSERVICE.createOrders_element();
		DART6_ORDERSERVICE.PublisherQueryLanguageContextError ordPuConEr = new DART6_ORDERSERVICE.PublisherQueryLanguageContextError();
		DART6_ORDERSERVICE.ApiError ordApiErr = new DART6_ORDERSERVICE.ApiError();
		DART6_ORDERSERVICE.DisapproveOrdersWithoutReservationChanges ordDisWitCh = new DART6_ORDERSERVICE.DisapproveOrdersWithoutReservationChanges();
		DART6_ORDERSERVICE.TeamError ordTeamErr = new DART6_ORDERSERVICE.TeamError();
		DART6_ORDERSERVICE.ApproveAndOverbookOrders ordOverBookOrd = new DART6_ORDERSERVICE.ApproveAndOverbookOrders();
		DART6_ORDERSERVICE.CustomFieldValueError ordCusvalErr = new DART6_ORDERSERVICE.CustomFieldValueError();
		//DART6_ORDERSERVICE.ApiException_x ordapiEx = new DART6_ORDERSERVICE.ApiException_x();
		DART6_ORDERSERVICE.performOrderActionResponse_element ordPerOrdresEle = new DART6_ORDERSERVICE.performOrderActionResponse_element();
		DART6_ORDERSERVICE.ResumeOrders ordResOrd = new DART6_ORDERSERVICE.ResumeOrders();
		DART6_ORDERSERVICE.ForecastError ordFcErr = new DART6_ORDERSERVICE.ForecastError();
		DART6_ORDERSERVICE.QuotaError ordQuErr = new DART6_ORDERSERVICE.QuotaError();
		DART6_ORDERSERVICE.OrderActionError ordOrdAcErr = new DART6_ORDERSERVICE.OrderActionError();
		//DART6_ORDERSERVICE.ApplicationException_x ordApiExcep = new DART6_ORDERSERVICE.ApplicationException_x();
		DART6_ORDERSERVICE.RangeError ordranErr = new DART6_ORDERSERVICE.RangeError();
		DART6_ORDERSERVICE.ParseError ordParErr = new DART6_ORDERSERVICE.ParseError();
		DART6_ORDERSERVICE.Money ordMoney = new DART6_ORDERSERVICE.Money();
		DART6_ORDERSERVICE.ApiVersionError ordVerErr = new DART6_ORDERSERVICE.ApiVersionError();
		DART6_ORDERSERVICE.LabelEntityAssociationError ordLaAssErr = new DART6_ORDERSERVICE.LabelEntityAssociationError();
		DART6_ORDERSERVICE.RetractOrdersWithoutReservationChanges ordRetWithCh = new DART6_ORDERSERVICE.RetractOrdersWithoutReservationChanges();
		DART6_ORDERSERVICE.ServerError ordSerErr = new DART6_ORDERSERVICE.ServerError();
		DART6_ORDERSERVICE.OrderAction ordOrAc = new DART6_ORDERSERVICE.OrderAction();
		DART6_ORDERSERVICE.createOrders_element ordCrOrdEle = new DART6_ORDERSERVICE.createOrders_element();
		DART6_ORDERSERVICE.UnarchiveOrders ordUnOrd = new DART6_ORDERSERVICE.UnarchiveOrders();
		DART6_ORDERSERVICE.DateTime_x orddatex = new DART6_ORDERSERVICE.DateTime_x();
		DART6_ORDERSERVICE.StatementError ordStatErr = new DART6_ORDERSERVICE.StatementError();
		//DART6_ORDERSERVICE.ClientLogin ordClienlog = new DART6_ORDERSERVICE.ClientLogin();
		DART6_ORDERSERVICE.RequiredCollectionError ordReCollErr = new DART6_ORDERSERVICE.RequiredCollectionError();
		DART6_ORDERSERVICE.TextValue ordTxtVal = new DART6_ORDERSERVICE.TextValue();
		//DART6_ORDERSERVICE.getOrder_element ordOrdEl = new DART6_ORDERSERVICE.getOrder_element();
		DART6_ORDERSERVICE.InvalidEmailError ordInvEr = new DART6_ORDERSERVICE.InvalidEmailError();
		//DART6_ORDERSERVICE.getOrderResponse_element ordGetOrdEle = new DART6_ORDERSERVICE.getOrderResponse_element();
		DART6_ORDERSERVICE.RetractOrders ordRetOrd = new DART6_ORDERSERVICE.RetractOrders();
		DART6_ORDERSERVICE.UpdateResult ordUpResl = new DART6_ORDERSERVICE.UpdateResult();
		DART6_ORDERSERVICE.getOrdersByStatementResponse_element ordByStEle = new DART6_ORDERSERVICE.getOrdersByStatementResponse_element();
		DART6_ORDERSERVICE.performOrderAction_element ordordACEle = new DART6_ORDERSERVICE.performOrderAction_element();
		DART6_ORDERSERVICE.DeleteOrders ordDel = new DART6_ORDERSERVICE.DeleteOrders();
		
		//@vitou 19-12-2014 ==> new Version 201411
         DART6_ORDERSERVICE.TechnologyTargetingError techTarErr = new DART6_ORDERSERVICE.TechnologyTargetingError();
         DART6_ORDERSERVICE.LineItemActivityAssociationError itemActAssErr = new DART6_ORDERSERVICE.LineItemActivityAssociationError();
         DART6_ORDERSERVICE.DateTimeRangeTargetingError dtRangeTarErr = new DART6_ORDERSERVICE.DateTimeRangeTargetingError();
         DART6_ORDERSERVICE.SetValue setVal = new DART6_ORDERSERVICE.SetValue();
         DART6_ORDERSERVICE.InventoryTargetingError invTarErr = new DART6_ORDERSERVICE.InventoryTargetingError();
         DART6_ORDERSERVICE.TemplateInstantiatedCreativeError temErr = new DART6_ORDERSERVICE.TemplateInstantiatedCreativeError();
         DART6_ORDERSERVICE.Date_x dateX = new DART6_ORDERSERVICE.Date_x();
         DART6_ORDERSERVICE.FeatureError featErr = new DART6_ORDERSERVICE.FeatureError();
         DART6_ORDERSERVICE.LineItemOperationError itemOpErr = new DART6_ORDERSERVICE.LineItemOperationError();
         DART6_ORDERSERVICE.ProgrammaticError proErr = new DART6_ORDERSERVICE.ProgrammaticError();
         DART6_ORDERSERVICE.EntityLimitReachedError entLimitErr = new DART6_ORDERSERVICE.EntityLimitReachedError();
         DART6_ORDERSERVICE.SoapRequestHeader soapReqHead = new DART6_ORDERSERVICE.SoapRequestHeader();
         DART6_ORDERSERVICE.NullError nullErr = new DART6_ORDERSERVICE.NullError();
         DART6_ORDERSERVICE.ApiException apiExcep = new DART6_ORDERSERVICE.ApiException();
         DART6_ORDERSERVICE.ApplicationException appExc = new DART6_ORDERSERVICE.ApplicationException();
         DART6_ORDERSERVICE.GenericTargetingError genTarErr = new DART6_ORDERSERVICE.GenericTargetingError();
         DART6_ORDERSERVICE.ContentMetadataTargetingError contMetaTarErr = new DART6_ORDERSERVICE.ContentMetadataTargetingError(); 
         DART6_ORDERSERVICE.FrequencyCapError FreqCapErr = new DART6_ORDERSERVICE.FrequencyCapError();
         DART6_ORDERSERVICE.LineItemError itemErr = new DART6_ORDERSERVICE.LineItemError();
         DART6_ORDERSERVICE.CreativeError createiveErr = new DART6_ORDERSERVICE.CreativeError();
         DART6_ORDERSERVICE.UserDomainTargetingError userDomTarErr = new DART6_ORDERSERVICE.UserDomainTargetingError();
         DART6_ORDERSERVICE.AudienceExtensionError audExtErr = new DART6_ORDERSERVICE.AudienceExtensionError();
         DART6_ORDERSERVICE.ClickTrackingLineItemError clickItemErr = new DART6_ORDERSERVICE.ClickTrackingLineItemError();
         DART6_ORDERSERVICE.LineItemCreativeAssociationError itemCreateAssErr = new DART6_ORDERSERVICE.LineItemCreativeAssociationError();
         DART6_ORDERSERVICE.InvalidUrlError invUrlErr = new DART6_ORDERSERVICE.InvalidUrlError();
         DART6_ORDERSERVICE.RequiredSizeError reqSizeErr = new DART6_ORDERSERVICE.RequiredSizeError();   
         DART6_ORDERSERVICE.RequiredNumberError reqNumErr = new DART6_ORDERSERVICE.RequiredNumberError();
         DART6_ORDERSERVICE.ReservationDetailsError resDetErr = new DART6_ORDERSERVICE.ReservationDetailsError();
         DART6_ORDERSERVICE.Order ord = new DART6_ORDERSERVICE.Order();
         DART6_ORDERSERVICE.ObjectValue objVal = new DART6_ORDERSERVICE.ObjectValue();
         DART6_ORDERSERVICE.AudienceSegmentError audSegErr = new DART6_ORDERSERVICE.AudienceSegmentError();
         DART6_ORDERSERVICE.DayPartTargetingError dayPartTarErr = new DART6_ORDERSERVICE.DayPartTargetingError();
         DART6_ORDERSERVICE.GeoTargetingError geoTarErr = new DART6_ORDERSERVICE.GeoTargetingError();
         DART6_ORDERSERVICE.DateValue dateVal = new DART6_ORDERSERVICE.DateValue();
	
	}
	
	/** Class DART6_LINEITEMSERVICE */ 
	static testMethod void testClassDART6_LINEITEMSERVICE()
	{
		DART6_LINEITEMSERVICE lineItem  = new DART6_LINEITEMSERVICE();
		DART6_LINEITEMSERVICE.FrequencyCap itemFreCap = new DART6_LINEITEMSERVICE.FrequencyCap();
		DART6_LINEITEMSERVICE.BrowserTargeting item1BwTar= new DART6_LINEITEMSERVICE.BrowserTargeting();
		DART6_LINEITEMSERVICE.CommonError item1ComErr = new DART6_LINEITEMSERVICE.CommonError();
		DART6_LINEITEMSERVICE.Technology item1Technology = new DART6_LINEITEMSERVICE.Technology();
		DART6_LINEITEMSERVICE.ReserveAndOverbookLineItems item1ReAndOverBook = new DART6_LINEITEMSERVICE.ReserveAndOverbookLineItems();
		DART6_LINEITEMSERVICE.TechnologyTargetingError item1 = new DART6_LINEITEMSERVICE.TechnologyTargetingError();
		DART6_LINEITEMSERVICE.ReserveLineItems item2 = new DART6_LINEITEMSERVICE.ReserveLineItems();
		DART6_LINEITEMSERVICE.InternalApiError item3 = new DART6_LINEITEMSERVICE.InternalApiError();
		DART6_LINEITEMSERVICE.LineItemSummary item4 = new DART6_LINEITEMSERVICE.LineItemSummary();
		DART6_LINEITEMSERVICE.BandwidthGroup item5 = new DART6_LINEITEMSERVICE.BandwidthGroup();
		DART6_LINEITEMSERVICE.OrderError item6 = new DART6_LINEITEMSERVICE.OrderError();
		DART6_LINEITEMSERVICE.DateTimeRangeTargetingError item7 = new DART6_LINEITEMSERVICE.DateTimeRangeTargetingError();
		DART6_LINEITEMSERVICE.createLineItems_element item8 = new DART6_LINEITEMSERVICE.createLineItems_element();
		DART6_LINEITEMSERVICE.UserDomainTargeting item9 = new DART6_LINEITEMSERVICE.UserDomainTargeting();
		DART6_LINEITEMSERVICE.InventoryTargetingError item10 = new DART6_LINEITEMSERVICE.InventoryTargetingError();
		DART6_LINEITEMSERVICE.DayPartTargeting item11 = new DART6_LINEITEMSERVICE.DayPartTargeting();
		DART6_LINEITEMSERVICE.BooleanValue itema = new DART6_LINEITEMSERVICE.BooleanValue();
		DART6_LINEITEMSERVICE.RequiredError itemb = new DART6_LINEITEMSERVICE.RequiredError();
		DART6_LINEITEMSERVICE.CustomCriteriaLeaf itemc = new DART6_LINEITEMSERVICE.CustomCriteriaLeaf();
		DART6_LINEITEMSERVICE.AuthenticationError itemd = new DART6_LINEITEMSERVICE.AuthenticationError();
		//DART6_LINEITEMSERVICE.RegionLocation iteme = new DART6_LINEITEMSERVICE.RegionLocation();
		DART6_LINEITEMSERVICE.PermissionError itemf = new DART6_LINEITEMSERVICE.PermissionError();
		DART6_LINEITEMSERVICE.DeviceManufacturerTargeting itemg = new DART6_LINEITEMSERVICE.DeviceManufacturerTargeting();
		DART6_LINEITEMSERVICE.updateLineItemsResponse_element itemh = new DART6_LINEITEMSERVICE.updateLineItemsResponse_element();
		DART6_LINEITEMSERVICE.InventoryTargeting itemi = new DART6_LINEITEMSERVICE.InventoryTargeting();
		DART6_LINEITEMSERVICE.LineItemOperationError itemgss = new DART6_LINEITEMSERVICE.LineItemOperationError();
		DART6_LINEITEMSERVICE.MobileDeviceSubmodelTargeting itemk = new DART6_LINEITEMSERVICE.MobileDeviceSubmodelTargeting();
		DART6_LINEITEMSERVICE.ReleaseLineItems itemRel = new DART6_LINEITEMSERVICE.ReleaseLineItems();
		DART6_LINEITEMSERVICE.OperatingSystemTargeting itemOpsTar = new DART6_LINEITEMSERVICE.OperatingSystemTargeting();
		DART6_LINEITEMSERVICE.MobileDevice itemModdv = new DART6_LINEITEMSERVICE.MobileDevice();
		DART6_LINEITEMSERVICE.BandwidthGroupTargeting itembdTa = new DART6_LINEITEMSERVICE.BandwidthGroupTargeting();
		DART6_LINEITEMSERVICE.CustomCriteria itemcus = new DART6_LINEITEMSERVICE.CustomCriteria();
		DART6_LINEITEMSERVICE.BaseCustomFieldValue itembasFv = new DART6_LINEITEMSERVICE.BaseCustomFieldValue();
		DART6_LINEITEMSERVICE.NumberValue itemnv = new DART6_LINEITEMSERVICE.NumberValue();
		DART6_LINEITEMSERVICE.GeoTargeting itemGo = new DART6_LINEITEMSERVICE.GeoTargeting();
		DART6_LINEITEMSERVICE.TimeOfDay itemToD = new DART6_LINEITEMSERVICE.TimeOfDay();
		//DART6_LINEITEMSERVICE.AdUnitSize itemAds = new DART6_LINEITEMSERVICE.AdUnitSize();
		DART6_LINEITEMSERVICE.CustomFieldValue itemcFv = new DART6_LINEITEMSERVICE.CustomFieldValue();
		DART6_LINEITEMSERVICE.SoapResponseHeader itemsoapResHe = new DART6_LINEITEMSERVICE.SoapResponseHeader();
		DART6_LINEITEMSERVICE.CustomCriteriaSet itemCusSet = new DART6_LINEITEMSERVICE.CustomCriteriaSet();
		DART6_LINEITEMSERVICE.NotNullError itemNotNul = new DART6_LINEITEMSERVICE.NotNullError();
		//DART6_LINEITEMSERVICE.getLineItem_element itemgetLineEle = new DART6_LINEITEMSERVICE.getLineItem_element();
		DART6_LINEITEMSERVICE.AudienceSegmentCriteria itemAudSeCr = new DART6_LINEITEMSERVICE.AudienceSegmentCriteria();
		DART6_LINEITEMSERVICE.EntityLimitReachedError itemEnReErr = new DART6_LINEITEMSERVICE.EntityLimitReachedError();
		DART6_LINEITEMSERVICE.createLineItemsResponse_element itemCreRes = new DART6_LINEITEMSERVICE.createLineItemsResponse_element();
		DART6_LINEITEMSERVICE.BrowserLanguageTargeting itemBrowTar = new DART6_LINEITEMSERVICE.BrowserLanguageTargeting();
		DART6_LINEITEMSERVICE.DateTimeValue itemDateTimeVal = new DART6_LINEITEMSERVICE.DateTimeValue();
		DART6_LINEITEMSERVICE.CompanyCreditStatusError itemComStaErr = new DART6_LINEITEMSERVICE.CompanyCreditStatusError();
		DART6_LINEITEMSERVICE.AdUnitTargeting itemAdUnit = new DART6_LINEITEMSERVICE.AdUnitTargeting();
		DART6_LINEITEMSERVICE.PublisherQueryLanguageContextError itemPubLaCon = new DART6_LINEITEMSERVICE.PublisherQueryLanguageContextError();
		DART6_LINEITEMSERVICE.performLineItemAction_element itemPerIAc = new DART6_LINEITEMSERVICE.performLineItemAction_element();
		DART6_LINEITEMSERVICE.SoapRequestHeader itemSoaHe = new DART6_LINEITEMSERVICE.SoapRequestHeader();
		DART6_LINEITEMSERVICE.TeamError itemTeamErr = new DART6_LINEITEMSERVICE.TeamError();
		DART6_LINEITEMSERVICE.ResumeAndOverbookLineItems itemResOvB = new DART6_LINEITEMSERVICE.ResumeAndOverbookLineItems();
		DART6_LINEITEMSERVICE.DeviceCategoryTargeting itemDevCatTar = new DART6_LINEITEMSERVICE.DeviceCategoryTargeting();
		DART6_LINEITEMSERVICE.NullError itemNuErr = new DART6_LINEITEMSERVICE.NullError();
		DART6_LINEITEMSERVICE.ApiException itemApiEx = new DART6_LINEITEMSERVICE.ApiException();
		DART6_LINEITEMSERVICE.OperatingSystemVersionTargeting itemopeverTar = new DART6_LINEITEMSERVICE.OperatingSystemVersionTargeting();
		DART6_LINEITEMSERVICE.ForecastError itemFc = new DART6_LINEITEMSERVICE.ForecastError();
		DART6_LINEITEMSERVICE.LineItemPage itemPage = new DART6_LINEITEMSERVICE.LineItemPage();
		DART6_LINEITEMSERVICE.MobileCarrierTargeting itemMoTar = new DART6_LINEITEMSERVICE.MobileCarrierTargeting();
		DART6_LINEITEMSERVICE.ApplicationException itemAppExc = new DART6_LINEITEMSERVICE.ApplicationException();
		DART6_LINEITEMSERVICE.GenericTargetingError itemGenTarErr = new DART6_LINEITEMSERVICE.GenericTargetingError();
		DART6_LINEITEMSERVICE.ApiVersionError itemApiverErr = new DART6_LINEITEMSERVICE.ApiVersionError();
		DART6_LINEITEMSERVICE.createLineItemsResponse_element itemcreResEle = new DART6_LINEITEMSERVICE.createLineItemsResponse_element();
		DART6_LINEITEMSERVICE.ContentTargeting itemContTar = new DART6_LINEITEMSERVICE.ContentTargeting();
		DART6_LINEITEMSERVICE.ServerError itemSerErr = new DART6_LINEITEMSERVICE.ServerError();
		DART6_LINEITEMSERVICE.FrequencyCapError itemFreErr = new DART6_LINEITEMSERVICE.FrequencyCapError();
		DART6_LINEITEMSERVICE.UnarchiveLineItems itemUna = new DART6_LINEITEMSERVICE.UnarchiveLineItems();
		DART6_LINEITEMSERVICE.DeviceCapabilityTargeting itemdevTar = new DART6_LINEITEMSERVICE.DeviceCapabilityTargeting();
		DART6_LINEITEMSERVICE.LineItemError itemEr = new DART6_LINEITEMSERVICE.LineItemError();
		DART6_LINEITEMSERVICE.performLineItemActionResponse_element itemPeracRes = new DART6_LINEITEMSERVICE.performLineItemActionResponse_element();
		DART6_LINEITEMSERVICE.DeviceCategory itemDev = new DART6_LINEITEMSERVICE.DeviceCategory();
		DART6_LINEITEMSERVICE.DeviceManufacturer itemDevMan = new DART6_LINEITEMSERVICE.DeviceManufacturer();
		DART6_LINEITEMSERVICE.BrowserLanguage itemBrovseLan = new DART6_LINEITEMSERVICE.BrowserLanguage();
		DART6_LINEITEMSERVICE.MobileDeviceSubmodel itemModSub = new DART6_LINEITEMSERVICE.MobileDeviceSubmodel();
		DART6_LINEITEMSERVICE.createLineItems_element itemcreaEl = new DART6_LINEITEMSERVICE.createLineItems_element();
		DART6_LINEITEMSERVICE.updateLineItems_element itemUpEle = new DART6_LINEITEMSERVICE.updateLineItems_element();
		DART6_LINEITEMSERVICE.CustomCriteriaNode itemCusNod = new DART6_LINEITEMSERVICE.CustomCriteriaNode();
		DART6_LINEITEMSERVICE.StringLengthError itemstrLengErr = new DART6_LINEITEMSERVICE.StringLengthError();
		//DART6_LINEITEMSERVICE.CountryLocation itemCountryLoc = new DART6_LINEITEMSERVICE.CountryLocation();
		DART6_LINEITEMSERVICE.UserDomainTargetingError itemUseDoErr = new DART6_LINEITEMSERVICE.UserDomainTargetingError();
		DART6_LINEITEMSERVICE.AppliedLabel itemAppla = new DART6_LINEITEMSERVICE.AppliedLabel();
		DART6_LINEITEMSERVICE.ActivateLineItems itemActivate = new DART6_LINEITEMSERVICE.ActivateLineItems();
		DART6_LINEITEMSERVICE.UniqueError itemuniquErr = new DART6_LINEITEMSERVICE.UniqueError();
		DART6_LINEITEMSERVICE.ResumeLineItems itemResum = new DART6_LINEITEMSERVICE.ResumeLineItems();
		DART6_LINEITEMSERVICE.getLineItemsByStatementResponse_element itemgetLineResEle = new DART6_LINEITEMSERVICE.getLineItemsByStatementResponse_element();
		DART6_LINEITEMSERVICE.PublisherQueryLanguageSyntaxError itemPulbSynErr = new DART6_LINEITEMSERVICE.PublisherQueryLanguageSyntaxError();
		DART6_LINEITEMSERVICE.DeliveryData itemDevData = new DART6_LINEITEMSERVICE.DeliveryData();
		DART6_LINEITEMSERVICE.AudienceExtensionError itemaudErr = new DART6_LINEITEMSERVICE.AudienceExtensionError();
		DART6_LINEITEMSERVICE.ClickTrackingLineItemError itemopSysErr = new DART6_LINEITEMSERVICE.ClickTrackingLineItemError();
		DART6_LINEITEMSERVICE.OperatingSystem itemopSys = new DART6_LINEITEMSERVICE.OperatingSystem();
		DART6_LINEITEMSERVICE.String_ValueMapEntry itemstrValMap = new DART6_LINEITEMSERVICE.String_ValueMapEntry();
		DART6_LINEITEMSERVICE.Size itemSize = new DART6_LINEITEMSERVICE.Size();
		DART6_LINEITEMSERVICE.Value itemval = new DART6_LINEITEMSERVICE.Value();
		DART6_LINEITEMSERVICE.DropDownCustomFieldValue itemDropCus = new DART6_LINEITEMSERVICE.DropDownCustomFieldValue();
		//DART6_LINEITEMSERVICE.OAuth itemAuth = new DART6_LINEITEMSERVICE.OAuth();
		DART6_LINEITEMSERVICE.LineItemCreativeAssociationError itemLineAss = new DART6_LINEITEMSERVICE.LineItemCreativeAssociationError();
		DART6_LINEITEMSERVICE.InvalidUrlError itemInvaUrlErr = new DART6_LINEITEMSERVICE.InvalidUrlError();
		DART6_LINEITEMSERVICE.RequiredSizeError itemReqSizeErr = new DART6_LINEITEMSERVICE.RequiredSizeError();
		DART6_LINEITEMSERVICE.TypeError itemTypeErr = new DART6_LINEITEMSERVICE.TypeError();
		DART6_LINEITEMSERVICE.VideoPositionTargeting itemVaTarg = new DART6_LINEITEMSERVICE.VideoPositionTargeting();
		//DART6_LINEITEMSERVICE.CityLocation itemCityLoc = new DART6_LINEITEMSERVICE.CityLocation();
		DART6_LINEITEMSERVICE.RequiredNumberError itemReNumErr = new DART6_LINEITEMSERVICE.RequiredNumberError();
		DART6_LINEITEMSERVICE.ReservationDetailsError itemResDetErr = new DART6_LINEITEMSERVICE.ReservationDetailsError();
		DART6_LINEITEMSERVICE.LineItemAction itemAc = new DART6_LINEITEMSERVICE.LineItemAction();
		DART6_LINEITEMSERVICE.Statement itemStat = new DART6_LINEITEMSERVICE.Statement();
		DART6_LINEITEMSERVICE.ApiError itemApiErr = new DART6_LINEITEMSERVICE.ApiError();
		DART6_LINEITEMSERVICE.Browser itemBw = new DART6_LINEITEMSERVICE.Browser();
		DART6_LINEITEMSERVICE.LineItemServiceInterfacePort itemInfPort = new DART6_LINEITEMSERVICE.LineItemServiceInterfacePort();
		DART6_LINEITEMSERVICE.CustomFieldValueError itemCusErr = new DART6_LINEITEMSERVICE.CustomFieldValueError();
		DART6_LINEITEMSERVICE.DayPartTargetingError itemDayErr = new DART6_LINEITEMSERVICE.DayPartTargetingError();
		DART6_LINEITEMSERVICE.GeoTargetingError itemGeoTarErr = new DART6_LINEITEMSERVICE.GeoTargetingError();
		DART6_LINEITEMSERVICE.QuotaError itemQuoErr = new DART6_LINEITEMSERVICE.QuotaError();
		DART6_LINEITEMSERVICE.MobileDeviceTargeting itemModTar = new DART6_LINEITEMSERVICE.MobileDeviceTargeting();
		DART6_LINEITEMSERVICE.getLineItemsByStatement_element itemBySt = new DART6_LINEITEMSERVICE.getLineItemsByStatement_element();
		DART6_LINEITEMSERVICE.RangeError itemRaErr = new DART6_LINEITEMSERVICE.RangeError();
		DART6_LINEITEMSERVICE.ParseError itemParErr = new DART6_LINEITEMSERVICE.ParseError();
		DART6_LINEITEMSERVICE.PauseLineItems itemPus = new DART6_LINEITEMSERVICE.PauseLineItems();
		DART6_LINEITEMSERVICE.LabelEntityAssociationError itemLaAssErr = new DART6_LINEITEMSERVICE.LabelEntityAssociationError();
		DART6_LINEITEMSERVICE.DeviceCapability itemDevCap = new DART6_LINEITEMSERVICE.DeviceCapability();
		DART6_LINEITEMSERVICE.DeliveryIndicator itemDeInd = new DART6_LINEITEMSERVICE.DeliveryIndicator();
		DART6_LINEITEMSERVICE.StatementError itemstatErr = new DART6_LINEITEMSERVICE.StatementError();
		//DART6_LINEITEMSERVICE.MetroLocation itemMetLoc = new DART6_LINEITEMSERVICE.MetroLocation();
		//DART6_LINEITEMSERVICE.ClientLogin itemClientLoc = new DART6_LINEITEMSERVICE.ClientLogin();
		DART6_LINEITEMSERVICE.ArchiveLineItems itemArch = new DART6_LINEITEMSERVICE.ArchiveLineItems();
		DART6_LINEITEMSERVICE.CreativePlaceholder itemCreHolder = new DART6_LINEITEMSERVICE.CreativePlaceholder();
		DART6_LINEITEMSERVICE.DeleteLineItems itemDelet = new DART6_LINEITEMSERVICE.DeleteLineItems();
		DART6_LINEITEMSERVICE.RequiredCollectionError itemRqueErr = new DART6_LINEITEMSERVICE.RequiredCollectionError();
		DART6_LINEITEMSERVICE.updateLineItemsResponse_element itemupdResEle = new DART6_LINEITEMSERVICE.updateLineItemsResponse_element();
		DART6_LINEITEMSERVICE.CustomTargetingError itemCustErr = new DART6_LINEITEMSERVICE.CustomTargetingError();
		DART6_LINEITEMSERVICE.TextValue itemTxtVal = new DART6_LINEITEMSERVICE.TextValue();
		DART6_LINEITEMSERVICE.LineItemFlightDateError itemFliDate = new DART6_LINEITEMSERVICE.LineItemFlightDateError();
		DART6_LINEITEMSERVICE.MobileCarrier itemMobCar = new DART6_LINEITEMSERVICE.MobileCarrier();
		DART6_LINEITEMSERVICE.updateLineItems_element itemUpElement = new DART6_LINEITEMSERVICE.updateLineItems_element();
//		DART6_LINEITEMSERVICE.getLineItemResponse_element itemGenResEle = new DART6_LINEITEMSERVICE.getLineItemResponse_element();
		DART6_LINEITEMSERVICE.Stats itemState = new DART6_LINEITEMSERVICE.Stats();
		DART6_LINEITEMSERVICE.UpdateResult itemupRes = new DART6_LINEITEMSERVICE.UpdateResult();
		//DART6_LINEITEMSERVICE.PostalCodeLocation itemPosLoc = new DART6_LINEITEMSERVICE.PostalCodeLocation();
		DART6_LINEITEMSERVICE.OperatingSystemVersion itemopSysverson = new DART6_LINEITEMSERVICE.OperatingSystemVersion();
		
		//@vitou 19-12-2014 ==> new Version 201411
        DART6_LINEITEMSERVICE.LineItemActivityAssociationError itemActAssErr = new DART6_LINEITEMSERVICE.LineItemActivityAssociationError();
        DART6_LINEITEMSERVICE.VideoPositionTarget vdoPosTar = new DART6_LINEITEMSERVICE.VideoPositionTarget();
        DART6_LINEITEMSERVICE.GrpSettings grpSet = new DART6_LINEITEMSERVICE.GrpSettings();
        DART6_LINEITEMSERVICE.SetValue setVAl = new DART6_LINEITEMSERVICE.SetValue();
        DART6_LINEITEMSERVICE.DateTime_x dtX = new DART6_LINEITEMSERVICE.DateTime_x();
        DART6_LINEITEMSERVICE.Date_x dateX = new DART6_LINEITEMSERVICE.Date_x();
        DART6_LINEITEMSERVICE.FeatureError featErr = new DART6_LINEITEMSERVICE.FeatureError();
        DART6_LINEITEMSERVICE.ProgrammaticError proErr = new DART6_LINEITEMSERVICE.ProgrammaticError();
        DART6_LINEITEMSERVICE.VideoPosition vdoPos = new DART6_LINEITEMSERVICE.VideoPosition();
        DART6_LINEITEMSERVICE.Money money = new DART6_LINEITEMSERVICE.Money();
        DART6_LINEITEMSERVICE.ContentMetadataTargetingError contMetaTarErr = new DART6_LINEITEMSERVICE.ContentMetadataTargetingError();
        DART6_LINEITEMSERVICE.DeviceCapabilityTargeting devCapTar = new DART6_LINEITEMSERVICE.DeviceCapabilityTargeting();
        DART6_LINEITEMSERVICE.LineItemActivityAssociation itemActAss = new DART6_LINEITEMSERVICE.LineItemActivityAssociation();
        DART6_LINEITEMSERVICE.TechnologyTargeting techTar = new DART6_LINEITEMSERVICE.TechnologyTargeting();
        DART6_LINEITEMSERVICE.ContentMetadataKeyHierarchyTargeting contMetaKeyHirTar = new DART6_LINEITEMSERVICE.ContentMetadataKeyHierarchyTargeting();
        DART6_LINEITEMSERVICE.VideoPositionWithinPod vdoPosWithPod = new DART6_LINEITEMSERVICE.VideoPositionWithinPod();
        DART6_LINEITEMSERVICE.Targeting tar = new DART6_LINEITEMSERVICE.Targeting();
        DART6_LINEITEMSERVICE.AudienceSegmentError audSegErr = new DART6_LINEITEMSERVICE.AudienceSegmentError();
        DART6_LINEITEMSERVICE.ObjectValue objVal = new DART6_LINEITEMSERVICE.ObjectValue();
        DART6_LINEITEMSERVICE.DateValue dateVal = new DART6_LINEITEMSERVICE.DateValue();
        DART6_LINEITEMSERVICE.Goal g = new DART6_LINEITEMSERVICE.Goal();
        DART6_LINEITEMSERVICE.CrossSellError crossSellErr = new DART6_LINEITEMSERVICE.CrossSellError();
        DART6_LINEITEMSERVICE.Location loc = new DART6_LINEITEMSERVICE.Location();
        DART6_LINEITEMSERVICE.EntityChildrenLimitReachedError entChildErr = new DART6_LINEITEMSERVICE.EntityChildrenLimitReachedError();
        DART6_LINEITEMSERVICE.DayPart dayPart = new DART6_LINEITEMSERVICE.DayPart();
        DART6_LINEITEMSERVICE.LineItem item = new DART6_LINEITEMSERVICE.LineItem();
		
		
	}

	 
	/** Class DART6_FORECASTSERVICE */ 
	static testMethod void testClassDart6AvailabilityForecast()
	{
		DART6_FORECASTSERVICE dart6FcService = new DART6_FORECASTSERVICE();
		DART6_FORECASTSERVICE.AdUnitCodeError adUnitError = new DART6_FORECASTSERVICE.AdUnitCodeError();
		//DART6_FORECASTSERVICE.AdUnitSize adUns = new DART6_FORECASTSERVICE.AdUnitSize();
		DART6_FORECASTSERVICE.AdUnitTargeting adUnitTar = new DART6_FORECASTSERVICE.AdUnitTargeting();
		DART6_FORECASTSERVICE.ApiError apiEr = new DART6_FORECASTSERVICE.ApiError();
		DART6_FORECASTSERVICE.ApiException apiEx = new DART6_FORECASTSERVICE.ApiException();
		DART6_FORECASTSERVICE.ApiVersionError apiVerErr = new DART6_FORECASTSERVICE.ApiVersionError();
		DART6_FORECASTSERVICE.ApplicationException appExc = new DART6_FORECASTSERVICE.ApplicationException();
		DART6_FORECASTSERVICE.AppliedLabel applLabel = new DART6_FORECASTSERVICE.AppliedLabel();
		DART6_FORECASTSERVICE.AudienceExtensionError auEx = new DART6_FORECASTSERVICE.AudienceExtensionError();
		DART6_FORECASTSERVICE.AudienceSegmentCriteria auSeg = new DART6_FORECASTSERVICE.AudienceSegmentCriteria();
		DART6_FORECASTSERVICE.BandwidthGroupTargeting bwgt = new DART6_FORECASTSERVICE.BandwidthGroupTargeting();
		DART6_FORECASTSERVICE.BaseCustomFieldValue baseCus = new DART6_FORECASTSERVICE.BaseCustomFieldValue();
		DART6_FORECASTSERVICE.Browser brw = new DART6_FORECASTSERVICE.Browser();
		DART6_FORECASTSERVICE.BrowserLanguage brwLan = new DART6_FORECASTSERVICE.BrowserLanguage();
		DART6_FORECASTSERVICE.BrowserLanguageTargeting bwlt = new DART6_FORECASTSERVICE.BrowserLanguageTargeting();
		DART6_FORECASTSERVICE.BrowserTargeting bt = new DART6_FORECASTSERVICE.BrowserTargeting();
		//DART6_FORECASTSERVICE.CityLocation ctLoc = new DART6_FORECASTSERVICE.CityLocation();
		DART6_FORECASTSERVICE.ClickTrackingLineItemError clTrac = new DART6_FORECASTSERVICE.ClickTrackingLineItemError(); 
		DART6_FORECASTSERVICE.CompanyCreditStatusError comCred = new DART6_FORECASTSERVICE.CompanyCreditStatusError();
		DART6_FORECASTSERVICE.ContentTargeting contar = new DART6_FORECASTSERVICE.ContentTargeting(); 
		//DART6_FORECASTSERVICE.CountryLocation counLoc = new DART6_FORECASTSERVICE.CountryLocation();
		DART6_FORECASTSERVICE.CustomTargetingError custarErr = new DART6_FORECASTSERVICE.CustomTargetingError();
		DART6_FORECASTSERVICE.CustomFieldValueError cusFvErr = new DART6_FORECASTSERVICE.CustomFieldValueError();
		DART6_FORECASTSERVICE.CustomFieldValue cusFv = new DART6_FORECASTSERVICE.CustomFieldValue();
		DART6_FORECASTSERVICE.CustomCriteriaSet cusCritSet = new DART6_FORECASTSERVICE.CustomCriteriaSet();
		DART6_FORECASTSERVICE.CustomCriteriaNode custCritNode = new DART6_FORECASTSERVICE.CustomCriteriaNode();
		DART6_FORECASTSERVICE.CustomCriteriaLeaf cusCritLeaf = new DART6_FORECASTSERVICE.CustomCriteriaLeaf();
		DART6_FORECASTSERVICE.CustomCriteria custCrit = new DART6_FORECASTSERVICE.CustomCriteria();
		DART6_FORECASTSERVICE.CreativePlaceholder creatPlh = new DART6_FORECASTSERVICE.CreativePlaceholder();
		DART6_FORECASTSERVICE.DayPart dayPart = new DART6_FORECASTSERVICE.DayPart();
		DART6_FORECASTSERVICE.DayPartTargeting dayPartTar = new DART6_FORECASTSERVICE.DayPartTargeting();
		DART6_FORECASTSERVICE.DropDownCustomFieldValue dropCus = new DART6_FORECASTSERVICE.DropDownCustomFieldValue(); 
		DART6_FORECASTSERVICE.DeviceManufacturer devManu = new DART6_FORECASTSERVICE.DeviceManufacturer();
		DART6_FORECASTSERVICE.DeviceCategoryTargeting devcateTar = new DART6_FORECASTSERVICE.DeviceCategoryTargeting();
		DART6_FORECASTSERVICE.DeviceCategory devCat = new DART6_FORECASTSERVICE.DeviceCategory();
		DART6_FORECASTSERVICE.DeviceCapabilityTargeting devCap = new DART6_FORECASTSERVICE.DeviceCapabilityTargeting();
		DART6_FORECASTSERVICE.DeviceCapability devCapility = new DART6_FORECASTSERVICE.DeviceCapability();
		DART6_FORECASTSERVICE.DeliveryIndicator devInd = new DART6_FORECASTSERVICE.DeliveryIndicator();
		DART6_FORECASTSERVICE.DeliveryData devData = new DART6_FORECASTSERVICE.DeliveryData();
		DART6_FORECASTSERVICE.DayPartTargetingError dayParErr = new DART6_FORECASTSERVICE.DayPartTargetingError();
		DART6_FORECASTSERVICE.DayPartTargeting dayPartTarg = new DART6_FORECASTSERVICE.DayPartTargeting();
		DART6_FORECASTSERVICE.EntityLimitReachedError entErr = new DART6_FORECASTSERVICE.EntityLimitReachedError();
		DART6_FORECASTSERVICE.ForecastError fcerr = new DART6_FORECASTSERVICE.ForecastError();
		DART6_FORECASTSERVICE.FrequencyCap freq = new DART6_FORECASTSERVICE.FrequencyCap();
		DART6_FORECASTSERVICE.FrequencyCapError freCapErr = new DART6_FORECASTSERVICE.FrequencyCapError();
		DART6_FORECASTSERVICE.GenericTargetingError genTar = new DART6_FORECASTSERVICE.GenericTargetingError();
		DART6_FORECASTSERVICE.GeoTargeting geoTar = new DART6_FORECASTSERVICE.GeoTargeting();
		DART6_FORECASTSERVICE.GeoTargetingError geoTarErr = new DART6_FORECASTSERVICE.GeoTargetingError();
		DART6_FORECASTSERVICE.InvalidUrlError inurlErr = new DART6_FORECASTSERVICE.InvalidUrlError();
		DART6_FORECASTSERVICE.InventoryTargeting invTarg = new DART6_FORECASTSERVICE.InventoryTargeting();
		DART6_FORECASTSERVICE.LabelEntityAssociationError labelEnAss = new DART6_FORECASTSERVICE.LabelEntityAssociationError();
		DART6_FORECASTSERVICE.LineItemCreativeAssociationError itemCreAss = new DART6_FORECASTSERVICE.LineItemCreativeAssociationError();
		DART6_FORECASTSERVICE.LineItemError itemErr = new DART6_FORECASTSERVICE.LineItemError();
		DART6_FORECASTSERVICE.LineItemFlightDateError lineFlighDateErr = new DART6_FORECASTSERVICE.LineItemFlightDateError();
		DART6_FORECASTSERVICE.Location lac = new DART6_FORECASTSERVICE.Location();
		//DART6_FORECASTSERVICE.MetroLocation metroLoc = new DART6_FORECASTSERVICE.MetroLocation();
		DART6_FORECASTSERVICE.MobileCarrier mobileCarr = new DART6_FORECASTSERVICE.MobileCarrier();
		DART6_FORECASTSERVICE.MobileCarrierTargeting mobCarTar = new DART6_FORECASTSERVICE.MobileCarrierTargeting();
		DART6_FORECASTSERVICE.MobileDevice mbDev = new DART6_FORECASTSERVICE.MobileDevice();
		DART6_FORECASTSERVICE.MobileDeviceSubmodel mobDevSub = new DART6_FORECASTSERVICE.MobileDeviceSubmodel();
		DART6_FORECASTSERVICE.MobileDeviceSubmodelTargeting mobDebSubModTar = new DART6_FORECASTSERVICE.MobileDeviceSubmodelTargeting();
		DART6_FORECASTSERVICE.MobileDeviceTargeting mobDevTar = new DART6_FORECASTSERVICE.MobileDeviceTargeting();
		DART6_FORECASTSERVICE.Money my = new DART6_FORECASTSERVICE.Money();
		DART6_FORECASTSERVICE.NotNullError notnullErr = new DART6_FORECASTSERVICE.NotNullError();
		DART6_FORECASTSERVICE.NullError nullErr = new DART6_FORECASTSERVICE.NullError();
		DART6_FORECASTSERVICE.NumberValue numVal = new DART6_FORECASTSERVICE.NumberValue();
		DART6_FORECASTSERVICE.OperatingSystem opSys = new DART6_FORECASTSERVICE.OperatingSystem();
		DART6_FORECASTSERVICE.OperatingSystemTargeting opSysTar = new DART6_FORECASTSERVICE.OperatingSystemTargeting();
		DART6_FORECASTSERVICE.OperatingSystemVersion optSysVer = new DART6_FORECASTSERVICE.OperatingSystemVersion();
		DART6_FORECASTSERVICE.OperatingSystemVersionTargeting optSysVerTar = new DART6_FORECASTSERVICE.OperatingSystemVersionTargeting();
		DART6_FORECASTSERVICE.QuotaError quotErr = new DART6_FORECASTSERVICE.QuotaError();
		DART6_FORECASTSERVICE.ParseError parsErr = new DART6_FORECASTSERVICE.ParseError();
		//DART6_FORECASTSERVICE.PostalCodeLocation posCodeLoc = new DART6_FORECASTSERVICE.PostalCodeLocation();
		DART6_FORECASTSERVICE.PublisherQueryLanguageContextError pubQueLangCon = new DART6_FORECASTSERVICE.PublisherQueryLanguageContextError();
		DART6_FORECASTSERVICE.PublisherQueryLanguageSyntaxError pbQuLocErr = new DART6_FORECASTSERVICE.PublisherQueryLanguageSyntaxError(); 
		DART6_FORECASTSERVICE.RangeError rageErr = new DART6_FORECASTSERVICE.RangeError();
		DART6_FORECASTSERVICE.RegExError ReExErr = new DART6_FORECASTSERVICE.RegExError();
		//DART6_FORECASTSERVICE.RegionLocation regLoc = new DART6_FORECASTSERVICE.RegionLocation();
		DART6_FORECASTSERVICE.RequiredCollectionError reqCollErr = new DART6_FORECASTSERVICE.RequiredCollectionError();
		DART6_FORECASTSERVICE.RequiredError reqErr = new DART6_FORECASTSERVICE.RequiredError();
		DART6_FORECASTSERVICE.RequiredNumberError ReNum = new DART6_FORECASTSERVICE.RequiredNumberError();
		DART6_FORECASTSERVICE.RequiredSizeError reqSizeErr = new DART6_FORECASTSERVICE.RequiredSizeError();
		DART6_FORECASTSERVICE.ReservationDetailsError ResDetailErr = new DART6_FORECASTSERVICE.ReservationDetailsError();
		DART6_FORECASTSERVICE.ServerError serErr = new DART6_FORECASTSERVICE.ServerError();
		DART6_FORECASTSERVICE.StatementError stateErr = new DART6_FORECASTSERVICE.StatementError();
		DART6_FORECASTSERVICE.Stats stats  = new DART6_FORECASTSERVICE.Stats();
		DART6_FORECASTSERVICE.StringLengthError strLengErr = new DART6_FORECASTSERVICE.StringLengthError();
		DART6_FORECASTSERVICE.TeamError teatErr = new DART6_FORECASTSERVICE.TeamError();
		DART6_FORECASTSERVICE.Technology technology = new DART6_FORECASTSERVICE.Technology();
		DART6_FORECASTSERVICE.TechnologyTargeting techTar = new DART6_FORECASTSERVICE.TechnologyTargeting();
		DART6_FORECASTSERVICE.TechnologyTargetingError tecTarErr = new DART6_FORECASTSERVICE.TechnologyTargetingError();
		DART6_FORECASTSERVICE.TextValue txtVal = new DART6_FORECASTSERVICE.TextValue();
		DART6_FORECASTSERVICE.TimeOfDay timeofDay = new DART6_FORECASTSERVICE.TimeOfDay();
		DART6_FORECASTSERVICE.TypeError typeErr = new DART6_FORECASTSERVICE.TypeError();
		DART6_FORECASTSERVICE.UniqueError uniqErr = new DART6_FORECASTSERVICE.UniqueError();
		DART6_FORECASTSERVICE.UserDomainTargeting useDomainTar = new DART6_FORECASTSERVICE.UserDomainTargeting();
		DART6_FORECASTSERVICE.UserDomainTargetingError userDomainTarErr = new DART6_FORECASTSERVICE.UserDomainTargetingError();
		DART6_FORECASTSERVICE.VideoPositionTargeting videoPosTar = new DART6_FORECASTSERVICE.VideoPositionTargeting();
		DART6_FORECASTSERVICE.Value val = new DART6_FORECASTSERVICE.Value();
		DART6_FORECASTSERVICE.CommonError commErr = new DART6_FORECASTSERVICE.CommonError();
		DART6_FORECASTSERVICE.InternalApiError internalErr = new DART6_FORECASTSERVICE.InternalApiError();
		DART6_FORECASTSERVICE.LineItemSummary lineItemSum = new DART6_FORECASTSERVICE.LineItemSummary();
		DART6_FORECASTSERVICE.BandwidthGroup banwidthGro = new DART6_FORECASTSERVICE.BandwidthGroup();
		DART6_FORECASTSERVICE.OrderError ordErr = new DART6_FORECASTSERVICE.OrderError();
		DART6_FORECASTSERVICE.DateTimeRangeTargetingError dartTimeRangErr = new DART6_FORECASTSERVICE.DateTimeRangeTargetingError();
		DART6_FORECASTSERVICE.InventoryTargetingError inveTarErr = new DART6_FORECASTSERVICE.InventoryTargetingError();
		DART6_FORECASTSERVICE.BooleanValue booleanVal = new DART6_FORECASTSERVICE.BooleanValue();
		DART6_FORECASTSERVICE.AuthenticationError autErr = new DART6_FORECASTSERVICE.AuthenticationError();
		DART6_FORECASTSERVICE.PermissionError perErr = new DART6_FORECASTSERVICE.PermissionError();
		DART6_FORECASTSERVICE.AdUnitAfcSizeError adUnitSizeErr = new DART6_FORECASTSERVICE.AdUnitAfcSizeError();
		DART6_FORECASTSERVICE.DeviceManufacturerTargeting devManTar = new DART6_FORECASTSERVICE.DeviceManufacturerTargeting();
		DART6_FORECASTSERVICE.LineItemOperationError lineItemErr = new DART6_FORECASTSERVICE.LineItemOperationError();
		DART6_FORECASTSERVICE.InventoryUnitError invUnitErr = new DART6_FORECASTSERVICE.InventoryUnitError();
		DART6_FORECASTSERVICE.SoapResponseHeader soaHearder = new DART6_FORECASTSERVICE.SoapResponseHeader();
		DART6_FORECASTSERVICE.DateTimeValue dateTimeVal = new DART6_FORECASTSERVICE.DateTimeValue();
		//DART6_FORECASTSERVICE.OAuth oau = new DART6_FORECASTSERVICE.OAuth();
		//DART6_FORECASTSERVICE.ClientLogin clienLog = new DART6_FORECASTSERVICE.ClientLogin();
		
		//@vitou 19-12-2014 ==> new Version 201411
        DART6_FORECASTSERVICE.LineItemActivityAssociationError itemActAssErr = new DART6_FORECASTSERVICE.LineItemActivityAssociationError();
        DART6_FORECASTSERVICE.VideoPositionTarget vdoPosTar = new DART6_FORECASTSERVICE.VideoPositionTarget();
        DART6_FORECASTSERVICE.GrpSettings grpSet = new DART6_FORECASTSERVICE.GrpSettings();
        DART6_FORECASTSERVICE.SetValue setVal = new DART6_FORECASTSERVICE.SetValue();
        DART6_FORECASTSERVICE.DateTime_x dtX = new DART6_FORECASTSERVICE.DateTime_x();
        DART6_FORECASTSERVICE.Date_x dateX = new DART6_FORECASTSERVICE.Date_x();
        DART6_FORECASTSERVICE.getForecastResponse_element forResEle = new DART6_FORECASTSERVICE.getForecastResponse_element();
        DART6_FORECASTSERVICE.FeatureError featErr = new DART6_FORECASTSERVICE.FeatureError();
        DART6_FORECASTSERVICE.ProgrammaticError proErr = new DART6_FORECASTSERVICE.ProgrammaticError();
        DART6_FORECASTSERVICE.VideoPosition vdoPos = new  DART6_FORECASTSERVICE.VideoPosition();
        DART6_FORECASTSERVICE.getForecastByIdResponse_element forcByIdRes = new  DART6_FORECASTSERVICE.getForecastByIdResponse_element();
        DART6_FORECASTSERVICE.SoapRequestHeader soapReqHead = new DART6_FORECASTSERVICE.SoapRequestHeader();
        DART6_FORECASTSERVICE.ContentMetadataKeyHierarchyTargeting contMetaKeyHirTar = new DART6_FORECASTSERVICE.ContentMetadataKeyHierarchyTargeting();
	}

	/** Test Class DART6_REPORTSERVICE */  
	
	static testMethod void testDART6ReportService()
	{
		DART6_REPORTSERVICE reportsv = new DART6_REPORTSERVICE();
   
	    DART6_REPORTSERVICE.CommonError comErr = new DART6_REPORTSERVICE.CommonError();
	    DART6_REPORTSERVICE.getReportDownloadUrlWithOptionsResponse_element getResDwOpRes = new    DART6_REPORTSERVICE.getReportDownloadUrlWithOptionsResponse_element();
	    DART6_REPORTSERVICE.DateTimeValue dateTimeVal = new DART6_REPORTSERVICE.DateTimeValue();
	    DART6_REPORTSERVICE.getReportDownloadUrlWithOptions_element getRepOpt = new DART6_REPORTSERVICE.getReportDownloadUrlWithOptions_element();
	    DART6_REPORTSERVICE.InternalApiError internalErr = new DART6_REPORTSERVICE.InternalApiError();
	    DART6_REPORTSERVICE.Statement statements = new DART6_REPORTSERVICE.Statement();
	    DART6_REPORTSERVICE.PublisherQueryLanguageContextError publicQuCont = new DART6_REPORTSERVICE.PublisherQueryLanguageContextError();
	    DART6_REPORTSERVICE.ApiError apiErr = new DART6_REPORTSERVICE.ApiError();
	    DART6_REPORTSERVICE.runReportJobResponse_element runRepJopRes = new DART6_REPORTSERVICE.runReportJobResponse_element();
	    DART6_REPORTSERVICE.Date_x datex = new DART6_REPORTSERVICE.Date_x();
	    DART6_REPORTSERVICE.SoapRequestHeader soapResHd = new DART6_REPORTSERVICE.SoapRequestHeader();
	    //DART6_REPORTSERVICE.Authentication auth = new DART6_REPORTSERVICE.Authentication();
	    DART6_REPORTSERVICE.getReportDownloadURL_element getRepUrl = new DART6_REPORTSERVICE.getReportDownloadURL_element();
	    DART6_REPORTSERVICE.getReportDownloadURLResponse_element getdRepUrlResEle = new DART6_REPORTSERVICE.getReportDownloadURLResponse_element();
	    DART6_REPORTSERVICE.BooleanValue bval = new DART6_REPORTSERVICE.BooleanValue();
	    DART6_REPORTSERVICE.ApiException apiEx = new DART6_REPORTSERVICE.ApiException();
	    DART6_REPORTSERVICE.RequiredError reqErr = new DART6_REPORTSERVICE.RequiredError();
	    DART6_REPORTSERVICE.AuthenticationError AuthErr = new DART6_REPORTSERVICE.AuthenticationError();
	    DART6_REPORTSERVICE.PermissionError perErr = new DART6_REPORTSERVICE.PermissionError();
	    DART6_REPORTSERVICE.QuotaError quotaErr = new DART6_REPORTSERVICE.QuotaError();
	    DART6_REPORTSERVICE.PublisherQueryLanguageSyntaxError pubQuSynErr = new DART6_REPORTSERVICE.PublisherQueryLanguageSyntaxError();
	    DART6_REPORTSERVICE.ReportQuery requery = new DART6_REPORTSERVICE.ReportQuery();
	    DART6_REPORTSERVICE.String_ValueMapEntry valMapEn = new DART6_REPORTSERVICE.String_ValueMapEntry();
	    DART6_REPORTSERVICE.ApplicationException appEx = new DART6_REPORTSERVICE.ApplicationException();
	    DART6_REPORTSERVICE.Value val = new DART6_REPORTSERVICE.Value();
	    DART6_REPORTSERVICE.getReportJob_element getJobEle = new DART6_REPORTSERVICE.getReportJob_element();
	    DART6_REPORTSERVICE.ApiVersionError apiVerErr = new DART6_REPORTSERVICE.ApiVersionError();
	    DART6_REPORTSERVICE.ReportError repErr = new DART6_REPORTSERVICE.ReportError();
	    //DART6_REPORTSERVICE.OAuth aut = new DART6_REPORTSERVICE.OAuth();
	    DART6_REPORTSERVICE.ServerError serErr = new DART6_REPORTSERVICE.ServerError();
	    DART6_REPORTSERVICE.DateTime_x dateTimex = new DART6_REPORTSERVICE.DateTime_x();
	    DART6_REPORTSERVICE.ReportDownloadOptions repDop = new DART6_REPORTSERVICE.ReportDownloadOptions();
	    DART6_REPORTSERVICE.StatementError stateErr = new DART6_REPORTSERVICE.StatementError();
	    //DART6_REPORTSERVICE.ClientLogin clientLog = new DART6_REPORTSERVICE.ClientLogin();
	    DART6_REPORTSERVICE.NumberValue numVal = new DART6_REPORTSERVICE.NumberValue();
	    DART6_REPORTSERVICE.TextValue txtval = new DART6_REPORTSERVICE.TextValue();
	    DART6_REPORTSERVICE.ReportServiceInterfacePort reIntPort = new DART6_REPORTSERVICE.ReportServiceInterfacePort();
	    DART6_REPORTSERVICE.SoapResponseHeader sheader = new DART6_REPORTSERVICE.SoapResponseHeader();
	    DART6_REPORTSERVICE.ReportJob reJob = new DART6_REPORTSERVICE.ReportJob();
	    DART6_REPORTSERVICE.runReportJob_element runReJob = new DART6_REPORTSERVICE.runReportJob_element();
	    DART6_REPORTSERVICE.getReportJobResponse_element getRejobResEle = new DART6_REPORTSERVICE.getReportJobResponse_element();
	    DART6_REPORTSERVICE.NotNullError notNullErr = new DART6_REPORTSERVICE.NotNullError();
	}

	/** Test Class DART6_CUSTOMTARGETINGSERVICE */  
	
	static testMethod void testDART6CustomTargetingService()
	{
		
		DART6_CUSTOMTARGETINGSERVICE customService = new DART6_CUSTOMTARGETINGSERVICE();
		
		DART6_CUSTOMTARGETINGSERVICE.CommonError comErr = new DART6_CUSTOMTARGETINGSERVICE.CommonError();
		DART6_CUSTOMTARGETINGSERVICE.DeleteCustomTargetingKeys delcusTarKey= new DART6_CUSTOMTARGETINGSERVICE.DeleteCustomTargetingKeys();
		DART6_CUSTOMTARGETINGSERVICE.CustomTargetingKeyAction custKeyAc= new DART6_CUSTOMTARGETINGSERVICE.CustomTargetingKeyAction();
		DART6_CUSTOMTARGETINGSERVICE.InternalApiError interApiErr = new DART6_CUSTOMTARGETINGSERVICE.InternalApiError();
		//DART6_CUSTOMTARGETINGSERVICE.Authentication aut = new DART6_CUSTOMTARGETINGSERVICE.Authentication();
		DART6_CUSTOMTARGETINGSERVICE.createCustomTargetingKeys_element cTKeyEle = new DART6_CUSTOMTARGETINGSERVICE.createCustomTargetingKeys_element();
		DART6_CUSTOMTARGETINGSERVICE.performCustomTargetingValueAction_element perCusValAc= new DART6_CUSTOMTARGETINGSERVICE.performCustomTargetingValueAction_element();
		DART6_CUSTOMTARGETINGSERVICE.BooleanValue bv = new DART6_CUSTOMTARGETINGSERVICE.BooleanValue();
		DART6_CUSTOMTARGETINGSERVICE.UniqueError uerr = new DART6_CUSTOMTARGETINGSERVICE.UniqueError();
		DART6_CUSTOMTARGETINGSERVICE.CustomTargetingKey custKey = new DART6_CUSTOMTARGETINGSERVICE.CustomTargetingKey();
		DART6_CUSTOMTARGETINGSERVICE.RequiredError reErr = new DART6_CUSTOMTARGETINGSERVICE.RequiredError();
		DART6_CUSTOMTARGETINGSERVICE.AuthenticationError autErr = new DART6_CUSTOMTARGETINGSERVICE.AuthenticationError();
		DART6_CUSTOMTARGETINGSERVICE.updateCustomTargetingValuesResponse_element updValResEle= new DART6_CUSTOMTARGETINGSERVICE.updateCustomTargetingValuesResponse_element();
		DART6_CUSTOMTARGETINGSERVICE.PermissionError perErr = new DART6_CUSTOMTARGETINGSERVICE.PermissionError();
		DART6_CUSTOMTARGETINGSERVICE.PublisherQueryLanguageSyntaxError pubQLErr = new DART6_CUSTOMTARGETINGSERVICE.PublisherQueryLanguageSyntaxError();
		DART6_CUSTOMTARGETINGSERVICE.String_ValueMapEntry valMaEnt = new DART6_CUSTOMTARGETINGSERVICE.String_ValueMapEntry();
		DART6_CUSTOMTARGETINGSERVICE.Value val = new DART6_CUSTOMTARGETINGSERVICE.Value();
		//DART6_CUSTOMTARGETINGSERVICE.OAuth auth = new DART6_CUSTOMTARGETINGSERVICE.OAuth();
		DART6_CUSTOMTARGETINGSERVICE.CustomTargetingValue custTarVal = new DART6_CUSTOMTARGETINGSERVICE.CustomTargetingValue();
		DART6_CUSTOMTARGETINGSERVICE.getCustomTargetingValuesByStatementResponse_element custValByStat = new DART6_CUSTOMTARGETINGSERVICE.getCustomTargetingValuesByStatementResponse_element();
		DART6_CUSTOMTARGETINGSERVICE.updateCustomTargetingKeys_element updCusKeyEle = new DART6_CUSTOMTARGETINGSERVICE.updateCustomTargetingKeys_element();
		DART6_CUSTOMTARGETINGSERVICE.updateCustomTargetingKeysResponse_element updTarKeyRes= new DART6_CUSTOMTARGETINGSERVICE.updateCustomTargetingKeysResponse_element();
		DART6_CUSTOMTARGETINGSERVICE.TypeError typeErr = new DART6_CUSTOMTARGETINGSERVICE.TypeError();
		DART6_CUSTOMTARGETINGSERVICE.NumberValue numVal = new DART6_CUSTOMTARGETINGSERVICE.NumberValue();
		DART6_CUSTOMTARGETINGSERVICE.SoapResponseHeader SoaHed = new DART6_CUSTOMTARGETINGSERVICE.SoapResponseHeader();
		DART6_CUSTOMTARGETINGSERVICE.createCustomTargetingValuesResponse_element creaCustValResEle= new DART6_CUSTOMTARGETINGSERVICE.createCustomTargetingValuesResponse_element();
		DART6_CUSTOMTARGETINGSERVICE.NotNullError notNullErr = new DART6_CUSTOMTARGETINGSERVICE.NotNullError();
		DART6_CUSTOMTARGETINGSERVICE.getCustomTargetingKeysByStatementResponse_element getCustKeyByResEle = new DART6_CUSTOMTARGETINGSERVICE.getCustomTargetingKeysByStatementResponse_element();
		DART6_CUSTOMTARGETINGSERVICE.CustomTargetingKeyPage custTargPage = new DART6_CUSTOMTARGETINGSERVICE.CustomTargetingKeyPage();
		DART6_CUSTOMTARGETINGSERVICE.DateTimeValue dtVal= new DART6_CUSTOMTARGETINGSERVICE.DateTimeValue();
		DART6_CUSTOMTARGETINGSERVICE.Statement st = new DART6_CUSTOMTARGETINGSERVICE.Statement();
		DART6_CUSTOMTARGETINGSERVICE.performCustomTargetingKeyAction_element perTargKeyAcElement = new DART6_CUSTOMTARGETINGSERVICE.performCustomTargetingKeyAction_element();
		DART6_CUSTOMTARGETINGSERVICE.PublisherQueryLanguageContextError pubQlContErr = new DART6_CUSTOMTARGETINGSERVICE.PublisherQueryLanguageContextError();
		DART6_CUSTOMTARGETINGSERVICE.ApiError apiErr= new DART6_CUSTOMTARGETINGSERVICE.ApiError();
		DART6_CUSTOMTARGETINGSERVICE.Date_x dx = new DART6_CUSTOMTARGETINGSERVICE.Date_x();
		DART6_CUSTOMTARGETINGSERVICE.SoapRequestHeader sH = new DART6_CUSTOMTARGETINGSERVICE.SoapRequestHeader();
		DART6_CUSTOMTARGETINGSERVICE.CustomTargetingServiceInterfacePort custSerInPort= new DART6_CUSTOMTARGETINGSERVICE.CustomTargetingServiceInterfacePort();
		DART6_CUSTOMTARGETINGSERVICE.updateCustomTargetingValues_element updVal = new DART6_CUSTOMTARGETINGSERVICE.updateCustomTargetingValues_element();
		DART6_CUSTOMTARGETINGSERVICE.NullError  nulErr = new DART6_CUSTOMTARGETINGSERVICE.NullError();
		DART6_CUSTOMTARGETINGSERVICE.ApiException apiExc = new DART6_CUSTOMTARGETINGSERVICE.ApiException();
		DART6_CUSTOMTARGETINGSERVICE.QuotaError quoaErr = new DART6_CUSTOMTARGETINGSERVICE.QuotaError();
		DART6_CUSTOMTARGETINGSERVICE.createCustomTargetingValues_element creatTargValEle  = new DART6_CUSTOMTARGETINGSERVICE.createCustomTargetingValues_element();
		DART6_CUSTOMTARGETINGSERVICE.ApplicationException appExc = new DART6_CUSTOMTARGETINGSERVICE.ApplicationException();
		DART6_CUSTOMTARGETINGSERVICE.getCustomTargetingValuesByStatement_element getCustTarEle= new DART6_CUSTOMTARGETINGSERVICE.getCustomTargetingValuesByStatement_element();
		DART6_CUSTOMTARGETINGSERVICE.ApiVersionError apiVerErr = new DART6_CUSTOMTARGETINGSERVICE.ApiVersionError();
		DART6_CUSTOMTARGETINGSERVICE.ParseError paErr= new DART6_CUSTOMTARGETINGSERVICE.ParseError();
		DART6_CUSTOMTARGETINGSERVICE.ServerError serErr = new DART6_CUSTOMTARGETINGSERVICE.ServerError();
		DART6_CUSTOMTARGETINGSERVICE.DateTime_x dtx= new DART6_CUSTOMTARGETINGSERVICE.DateTime_x();
		DART6_CUSTOMTARGETINGSERVICE.CustomTargetingValuePage cutValPage = new DART6_CUSTOMTARGETINGSERVICE.CustomTargetingValuePage();
		DART6_CUSTOMTARGETINGSERVICE.CustomTargetingValueAction custValAc = new DART6_CUSTOMTARGETINGSERVICE.CustomTargetingValueAction();
		DART6_CUSTOMTARGETINGSERVICE.createCustomTargetingKeysResponse_element creatTaKeyRes = new DART6_CUSTOMTARGETINGSERVICE.createCustomTargetingKeysResponse_element();
		DART6_CUSTOMTARGETINGSERVICE.StatementError staErr= new DART6_CUSTOMTARGETINGSERVICE.StatementError();
		//DART6_CUSTOMTARGETINGSERVICE.ClientLogin clLog = new DART6_CUSTOMTARGETINGSERVICE.ClientLogin();
		DART6_CUSTOMTARGETINGSERVICE.performCustomTargetingKeyActionResponse_element perCustKeyRes = new DART6_CUSTOMTARGETINGSERVICE.performCustomTargetingKeyActionResponse_element();
		DART6_CUSTOMTARGETINGSERVICE.getCustomTargetingKeysByStatement_element getTarKeyStr = new DART6_CUSTOMTARGETINGSERVICE.getCustomTargetingKeysByStatement_element();
		DART6_CUSTOMTARGETINGSERVICE.CustomTargetingError custTarErr = new DART6_CUSTOMTARGETINGSERVICE.CustomTargetingError();
		DART6_CUSTOMTARGETINGSERVICE.TextValue txVal = new DART6_CUSTOMTARGETINGSERVICE.TextValue();
		DART6_CUSTOMTARGETINGSERVICE.UpdateResult updRes= new DART6_CUSTOMTARGETINGSERVICE.UpdateResult();
		DART6_CUSTOMTARGETINGSERVICE.performCustomTargetingValueActionResponse_element perCustTarAcRes = new DART6_CUSTOMTARGETINGSERVICE.performCustomTargetingValueActionResponse_element();
		DART6_CUSTOMTARGETINGSERVICE.DeleteCustomTargetingValues delTarVal= new DART6_CUSTOMTARGETINGSERVICE.DeleteCustomTargetingValues();
		
		//@vitou 19-12-2014 ==> new Version 201411
        DART6_CUSTOMTARGETINGSERVICE.SetValue setVal = new DART6_CUSTOMTARGETINGSERVICE.SetValue();
        DART6_CUSTOMTARGETINGSERVICE.CollectionSizeError colSizeErr = new DART6_CUSTOMTARGETINGSERVICE.CollectionSizeError();
        DART6_CUSTOMTARGETINGSERVICE.FeatureError featErr = new DART6_CUSTOMTARGETINGSERVICE.FeatureError();
        DART6_CUSTOMTARGETINGSERVICE.ActivateCustomTargetingKeys actCustTarKey = new DART6_CUSTOMTARGETINGSERVICE.ActivateCustomTargetingKeys();
        DART6_CUSTOMTARGETINGSERVICE.ActivateCustomTargetingValues actCustTarVal = new DART6_CUSTOMTARGETINGSERVICE.ActivateCustomTargetingValues();
        DART6_CUSTOMTARGETINGSERVICE.DateValue dateVal = new DART6_CUSTOMTARGETINGSERVICE.DateValue();
	}  
	
	
	 /** Test Class DARTUtil */  //@vitou 19-12-2014   
  
    static testMethod void testDARTUtil()
    {

	   testDATA.createCredential();
       testDATA.createTargetingHierarchy();
       testDATA.createAccount();
       testDATA.createAdvertiser();
       testDATA.createOpp(testDATA.lstAcc.get(0));
       testDATA.createOppTeamMember(testDATA.opp.id);
       testDATA.createNewOppItemsDart(testDATA.opp.id,2,DARTUtil.DART6,testDATA.targetting[0].Id);
       List<OpportunityLineItem> items =testDATA.getOppItem(testDATA.opp.id, new Set<String>{testDATA.lstLineItems.get(0).id});

        Test.startTest();  	
		
		DARTUtil.composeDigestAuthorizationHeader('cambodia_DE-API','dartebaytest2012','/xmlserver/','POST');
		DARTUtil.getRequestToken('DE');
		try{
			DARTUtil.getRequestToken('855');
		}catch(Exception e){
			System.assert(e.getMessage().contains('Could not fetch token for DART6.'));
		}
				
		DARTUtil.sendMail(new List<String>{'test@test.com'},new List<String>{'test@test.com'}, DARTUtil.EMAIL_SUBJECT_BOOKING, 'Opportunity Owner','');		
		DARTUtil.getListAreaCodes('xxxxx');
		DARTUtil.getAdvertiser('xxxx','xxxx');
		DARTUtil.getListAvailSites('xxx',new Set<String>{'xxx'});
		
		DARTUtil.genTD('xxx');
		DARTUtil.genTR('xxx');
		
		List<DARTObject.DARTForecast> listForecast = new List<DARTObject.DARTForecast>();
		listForecast.add(new DARTObject.DARTForecast(TestDATA.lstLineItems.get(0)));
		DARTUtil.generateTableForecast(listForecast);
		
		DARTUtil.countCurrentBatch();
		DARTUtil.extractMessage('xxx');
		DARTUtil.isNumber('100');
		DARTUtil.isNumber('Ten');
		DARTUtil.encodeHTML('');
		DARTUtil.encodeHTML('www.google.com');
		DARTUtil.getListCountries('xxxxxxxxx');
		DARTUtil.getListCities('xxxxxxx');
		DARTUtil.getContentsByTargetType('XXXXXXXX', 'test');
		Integer x = DARTUTIL.toInteger('10');	
		DARTUtil.extractMessage('test error');
		DARTUtil.getListContents(TestData.targetting.get(0).id, TestData.lstPrd2.get(0).id);
			
		Nullpointerexception Ex = new Nullpointerexception();
        map<String,Exception> mapE = new map<String,Exception>();
        mapE.put('A',Ex);
        string errForecast = DARTUtil.generateTableForecastError(mapE);	
		
		string access_token = DARTUtil.getAccessToken(TestDATA.listLogin.get(0));
		 
		String body ='refresh_token=%rtoken%&client_id=%clid%&client_secret=%secret%&grant_type=refresh_token';
        body=body.replace('%rtoken%',testDATA.listLogin.get(0).Refresh_Token__c).replace('%clid%',testDATA.listLogin.get(0).Client_Id__c).replace('%secret%',testDATA.listLogin.get(0).Client_Secret__c);
        string author_request = DARTUtil.oauth2Request(body,'access_token');  
  
	  Test.stopTest();
    } 

}