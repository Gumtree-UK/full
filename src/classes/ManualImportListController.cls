/**
* Import delivery from product button list "Import_Delivery"
* If user selects only certain ad lines then update those only
* If user selects no adlines then update all adlines
*/
public with sharing class ManualImportListController {
	public String oppId {get; set;}
	public Boolean isError {get; set;}
	
	private final String KEY_SEP = '_';
	private String sobjtype;
	private String recIds;
	private String query;
	private Map<String, List<String>> mLoginSobjIds = new Map<String, List<String>>();//Country+DartVersion => {sobjId}
	private Map<String, List<String>> mDartVersionCountry = new Map<String, List<String>>();// DartVersion => {Country}
	private Map<String, String> mAdId = new Map<String, String>(); //Id => AdId;
	private Map<String, AdServer_Login__c> mAdLogin = new Map<String, AdServer_Login__c>();//Country+DartVersion => login
	private Map<String, DART_Delivery_Support__c> mDDSupport = new Map<String, DART_Delivery_Support__c>();//Country+DartVersion => DDSupport
	
	//Check after each polling dartVersion => {countries}
	private Map<String, Set<String>> waitingDartVersionCountry = new Map<String, Set<String>>(); // requested list
	private Map<String, Set<String>> completeDartVersionCountry = new Map<String, Set<String>>();
	
	/**
	* Constructor without params
	*/
	public ManualImportListController(){
		sobjtype = Encodingutil.urlDecode(ApexPages.currentPage().getParameters().get('sobjtype'), 'UTF-8');
		oppId = Encodingutil.urlDecode(ApexPages.currentPage().getParameters().get('oppId'), 'UTF-8');
		recIds = Encodingutil.urlDecode(ApexPages.currentPage().getParameters().get('recIds'), 'UTF-8');
		query = DeliveryController.mGeneralQuery.get(sobjtype).replace('%DATECRIT%', '');
		isError = false;
	}
	
	/**
	* Mapping all DartVersion, Country, AdId for product
	*/
	public PageReference checkProductListServers(){
		try{
			List<String> proIds = recIds != '' ? recIds.split(',') : new List<String>();
			List<OpportunityLineItem> lpro = !proIds.isEmpty() 
				? [Select Id, Ad_Id__c, PricebookEntry.Product2.Site__r.Country__c, PricebookEntry.Product2.RecordType.Name From OpportunityLineItem Where Id IN: proIds]
				: [Select Id, Ad_Id__c, PricebookEntry.Product2.Site__r.Country__c, PricebookEntry.Product2.RecordType.Name From OpportunityLineItem Where OpportunityId =: oppId];
			if(lpro.isEmpty()) return null;
			Set<String> dartVersions = new Set<String>();
			Set<String> sCountry = new Set<String>();
			for(OpportunityLineItem pro : lpro){
				sCountry.add(pro.PricebookEntry.Product2.Site__r.Country__c);
				dartVersions.add(pro.PricebookEntry.Product2.RecordType.Name);
				//Unique AdId to a country
				String keyDart = pro.PricebookEntry.Product2.Site__r.Country__c + KEY_SEP + pro.PricebookEntry.Product2.RecordType.Name;
				if(!mLoginSobjIds.containsKey(keyDart)) mLoginSobjIds.put(keyDart, new List<String>());
				mLoginSobjIds.get(keyDart).add(pro.Id);
				if(pro.Ad_Id__c != null) mAdId.put(pro.Id, pro.Ad_Id__c);
				//DartVersion used by multiple country
				if(!mDartVersionCountry.containsKey(pro.PricebookEntry.Product2.RecordType.Name)) mDartVersionCountry.put(pro.PricebookEntry.Product2.RecordType.Name, new List<String>());
				mDartVersionCountry.get(pro.PricebookEntry.Product2.RecordType.Name).add(pro.PricebookEntry.Product2.Site__r.Country__c);
			}
			//Create support logger
			for(AdServer_Login__c login : [SELECT RecordType.Name, Name, Login_URL__c, User_Name__c, Password__c, Network_ID__c FROM AdServer_Login__c WHERE Name IN: sCountry AND RecordType.Name IN: dartVersions AND Active__c=true AND isDeleted=false ]){
				String keyDart = login.Name + KEY_SEP + login.RecordType.Name;
				if(!mLoginSobjIds.containsKey(keyDart)) continue;
				DART_Delivery_Support__c dds = new DART_Delivery_Support__c(
					AdServer_Login__c = login.Id, Attempt__c = 0, Retry_Counter__c = 0,
					Schedule_Type__c = DeliveryController.TYPE_MANUALLY_POLLING,
					Sobject__c = DeliveryController.SOBJECT_OPPPRODUCT,
					Status__c = DeliveryController.DART_STATUS_NEW
					);
				mDDSupport.put(keyDart, dds);
				mAdLogin.put(keyDart, login);
			}
			//if(!mDDSupport.isEmpty()) insert mDDSupport.values();
			//do request report and poll for other countries and servers
			keepPollingReportRequest = true;
			pollReportRequest();
		}catch(Exception e){
			isError = true;
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Failed to import data : ' + e.getMessage()));
		}
		return null;
	}
	
	public String messages {get; set;}
	
	//---Step 2 : Poll All report Status and update when complete---
	public Boolean keepPollingStatus {get; set;}
	/**
	* Poll status and update when Complete
	*/
	public PageReference pollReportStatus(){
		try{
			messages = '';
			for(String dartversion : waitingDartVersionCountry.keySet()){
				if(dartversion == DARTUtil.DART5) continue;
				for(String country : waitingDartVersionCountry.get(dartversion)){
					//Login locating in loop but perform only once, so query or dml won't be an issue
					if(!completeDartVersionCountry.containsKey(dartversion)) completeDartVersionCountry.put(dartversion, new Set<String>());
					if(completeDartVersionCountry.get(dartversion).contains(country)) continue;
					//See status from requested reports
					String keylogin = country + KEY_SEP + dartversion;
					//AdServer_Login__c login = mAdLogin.get(keylogin);
					DART_Delivery_Support__c dds = DeliveryController.getDeliverySupportRecord(mDDSupport.get(keylogin).Id);
					DART6_REPORTSERVICE.REPORTServiceInterfacePort reportService = DeliveryController.buildQueryService(dds.AdServer_Login__r.Name , dds.AdServer_Login__r.Network_ID__c);
					Dart6_ReportService.ReportJob reportJob = reportService.getReportJob((long)dds.Job_Id__c);
					String reportStatus = reportJob.reportJobStatus;
					//messages += '<Br/><Br/>-Report Status: ' + reportStatus ;
					if(reportStatus == DART6_REPORTSERVICE.REPORTJOBSTATUS_COMPLETED){
						// Import task complete
						completeDartVersionCountry.get(dartversion).add(country);
						DeliveryController controller = new DeliveryController(dds);
						controller.setReportService(reportService);
						controller.setJobid((long)dds.Job_Id__c);
						processDeliveryUpdate(controller);
				    }else if(reportStatus == DART6_REPORTSERVICE.REPORTJOBSTATUS_FAILED){
				    	// Import task complete
				    	completeDartVersionCountry.get(dartversion).add(country);
				    	//Throw message and log
				    	dds.DART_Status__c = DeliveryController.REPORT_QUERY_FAILED;
						dds.Status__c = DeliveryController.DART_STATUS_FINISHED;
						update dds;
						throw new ExceptionGroup.DARTException('Failed to query report from server');
				    }else{
				    	//log progress
				    	dds.DART_Status__c = DeliveryController.REPORT_QUERY_INPROGRESS;
				    	dds.Status__c = DeliveryController.DART_STATUS_AWAIT;
					    dds.Attempt__c = dds.Attempt__c + 1;
					    update dds;
					    if(dds.Attempt__c > DeliveryController.MAX_ATTAMPT_WAITING && dds.Status__c == DeliveryController.DART_STATUS_AWAIT){
							// Import task complete
							completeDartVersionCountry.get(dartversion).add(country);
							throw new ExceptionGroup.DARTException('Requesting report takes time too long with more than ' + DeliveryController.MAX_ATTAMPT_WAITING + ' attempts');
					    }
				    }
				    keepPollingStatus = true;
					return null;
				}
			}
			keepPollingStatus = false;
			return new PageReference('/' + oppId);
		}catch(Exception e){
			isError = true;
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Failed to import data : ' + e.getMessage()));
		}
		return null;
	}
	
	/**
	* Update process base on Controller
	*/
	private void processDeliveryUpdate(DeliveryController controller){
		//Download and do update
		controller.importDelivery();
		DART_Delivery_Support__c dds = controller.dartDelStatus;
		String keylogin = dds.AdServer_Login__r.Name + KEY_SEP + dds.AdServer_Login__r.RecordType.Name;
		List<String> sobjIds = mLoginSobjIds.get(keylogin);
		BatchDeliveryProcess batchProcess = new BatchDeliveryProcess(null, controller.getListDart(), dds.Id);
		String dQuery = query.replace('%1', dds.AdServer_Login__r.Name).replace('%2', dds.AdServer_Login__r.RecordType.Name) + ' AND Id IN: sobjIds';
		batchProcess.doExecute(Database.query(dQuery));
		//Do log
		batchProcess.dofinish();
	}
	
	//---Step 1 : Poll Request---
	public Boolean keepPollingReportRequest {get; set;}
	/**
	* poll all report requests first, next poll status then update
	*/
	public PageReference pollReportRequest(){
		try{
			for(String dartversion : mDartVersionCountry.keySet()){
				for(String country : mDartVersionCountry.get(dartversion)){
					if(!waitingDartVersionCountry.containsKey(dartversion)) waitingDartVersionCountry.put(dartversion, new Set<String>());
					//Query and DML is ok to perform here, the logic only perform once
					if(waitingDartVersionCountry.get(dartversion).contains(country)) continue;
					waitingDartVersionCountry.get(dartversion).add(country);
					doRequestReport(country, dartversion);
					keepPollingReportRequest = true;
					return null;
				}
			}
			keepPollingReportRequest = false;
			keepPollingStatus = true;
			pollReportStatus();
		}catch(Exception e){
			isError = true;
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Failed to import data : ' + e.getMessage()));
		}
		return null;
	}
	
    /** 
    * do request on specific country and dartversion
    */
    private void doRequestReport(String country, String dartversion){
    	String keylogin = country + KEY_SEP + dartversion;
    	if(dartversion == DARTUtil.DART5){
			//todo : logic import Dart5
    	}else if(dartversion == DARTUtil.DART6){
    		String adIds = '';
    		for(String sobjId : mLoginSobjIds.get(keylogin)){
    			if(mAdId.get(sobjId) != null) adIds += mAdId.get(sobjId) + ',' ;
    		}
    		String reportId = '';
    		if(adIds != ''){
    			adIds = adIds.substring(0, adIds.length() - 1);
	    		AdServer_Login__c login = mAdLogin.get(keylogin);
	    		DART6_REPORTSERVICE.REPORTServiceInterfacePort reportService = DeliveryController.buildQueryService(login.Name , login.Network_ID__c);
				Dart6_ReportService.ReportJob reportJob = DeliveryController.buildReportQuery(sobjtype, 'WHERE LINE_ITEM_ID IN (' + adIds + ')');
				reportId = String.valueOf(DeliveryController.runReportRequest(reportService, reportJob));
    		} 
    		DART_Delivery_Support__c dds = mDDSupport.get(keylogin);
	    	dds.Job_Id__c = adIds == '' ? null : Decimal.valueOf(reportId);
			dds.DART_Status__c = adIds == '' ? DeliveryController.REPORT_QUERY_COMPLETED : DeliveryController.REPORT_QUERY_INPROGRESS;
			dds.Status__c = adIds == '' ? DeliveryController.DART_STATUS_FINISHED : DeliveryController.DART_STATUS_AWAIT;
			dds.Attempt__c = adIds == '' ? dds.Attempt__c : dds.Attempt__c + 1;
			upsert dds;
    	}
    }
    
    @isTest (seeAllData=true)
    public static void TestManualImportListController(){
    	TestDataGenerator testDATA = new TestDataGenerator();
    	// Generate data opp/oppItem
        testDATA.createCredential();
        testDATA.createTargetingHierarchy();
        testDATA.createAccount();
        testDATA.createAdvertiser();
        testDATA.createOpp(testDATA.lstAcc.get(1));
        testDATA.createOppTeamMember(testDATA.opp.id);
        testDATA.createNewOppItemsDart(testDATA.opp.id,1,DARTUtil.DART6,testDATA.targetting[0].Id);
        List<OpportunityLineItem> items = testDATA.getOppItem(testDATA.opp.id, new Set<String>{testDATA.lstLineItems.get(0).id});
        
    	Test.startTest();
    		Pagereference pg = Page.ManualImportList;
            Test.setCurrentPageReference(pg);
            pg.getParameters().put('sobjtype', DeliveryController.SOBJECT_OPPPRODUCT);
            pg.getParameters().put('oppId', testDATA.opp.Id);
            pg.getParameters().put('recIds',testDATA.lstLineItems[0].Id);
			ManualImportListController controller = new ManualImportListController();
			controller.checkProductListServers();
			controller.pollReportStatus();
			
			//Test without selected records
			pg = Page.ManualImportList;
            Test.setCurrentPageReference(pg);
            pg.getParameters().put('sobjtype', DeliveryController.SOBJECT_OPPPRODUCT);
            pg.getParameters().put('oppId', testDATA.opp.Id);
            pg.getParameters().put('recIds','');
			controller = new ManualImportListController();
			controller.checkProductListServers();
			controller.pollReportStatus();
    	Test.stopTest();
    }
}