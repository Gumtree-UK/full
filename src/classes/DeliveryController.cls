/*

Change log:
- 2013-05-10 - GTCRM-207 - Map DFP lineItem status to Ad Status field in SF on OLI & RSD

*/

public with sharing class DeliveryController  extends DARTObject.AbstractDARTController{
    public static final String REVENUE_SCHEDULE_DAILY_API_NAME = 'Revenue_Schedule_daily2__c'; 
    public static final String REVENUE_SCHEDULE_API_NAME = 'Revenue_Schedule2__c';
    public static final String OPPORTUNITY_PRODUCT_API_NAME = 'OpportunityLineItem';
     
    public static final String SOBJECT_OPPPRODUCT = 'Opportunity Product';
    public static final String SOBJECT_REV_SCH2 = 'Revenue Schedules2';
    public static final String SOBJECT_REV_SCH2_DAILY = 'Revenue Schedule Daily2';
    public static final String DART_STATUS_NEW = 'New';
    public static final String DART_STATUS_AWAIT = 'Await';
    public static final String DART_STATUS_FINISHED = 'Finished';
    public static final String SCH_TYPE_DAILY = 'Daily'; 
    public static final String SCH_TYPE_MONTHLY = 'Monthly';
    public static final String SCH_TYPE_MANUALLY = 'Manually';
    public static final String TYPE_MANUALLY_POLLING = 'Polling Import';
    public static final String REPORT_QUERY_FAILED = 'FAILED';
    public static final String REPORT_QUERY_INPROGRESS = 'IN_PROGRESS';
    public static final String REPORT_QUERY_COMPLETED = 'COMPLETED';
    public static final String REPORT_QUERY_RETRY = 'RETRY';
    public static final Integer MAX_RETRY_IMPORT = 3;
    public static final Integer MAX_ATTAMPT_WAITING = 10;
    
    
     
    AdServer_Login__c login;
    String breakDown, dateRange; 
    
    public DART_Delivery_Support__c dartDelStatus {get; set;}
    
    /** Default Contrustor: Daily */
    public DeliveryController(AdServer_Login__c login)
    {
        this.login = login;
        this.breakDown = DART6Message.BREAKDOWN_DAILY;
        this.dateRange = DART6Message.DATERANGE_YESTERDAY;
        dartDelStatus = new DART_Delivery_Support__c();
    }
     
    public DeliveryController(AdServer_Login__c login,String breakDown,String dateRange)
    {
        this.login = login;
        this.breakDown = breakDown;
        this.dateRange = dateRange;
        dartDelStatus = new DART_Delivery_Support__c();
    }
    
    public DeliveryController(DART_Delivery_Support__c dds)
    {
        dartDelStatus = dds;
        login = [SELECT RecordType.name,Name,Login_URL__c, User_Name__c, Password__c, Network_ID__c FROM AdServer_Login__c WHERE Id =: dds.AdServer_Login__c limit 1];
    }
    
    private Long jobid;
    
    public void setJobid(Long jobid){
        this.jobid = jobid;
    }
    
    private DART6_REPORTSERVICE.REPORTServiceInterfacePort reportService;
    
    public void setReportService (DART6_REPORTSERVICE.REPORTServiceInterfacePort reportService){
        this.reportService = reportService;
    }
    
    /** initate the ImportDelivery Process 
     *  - just insert the the relavant DDS from the eligible Logins
     *  - should be called from Scheduler
     *  - manually
     *  @param scheduleType
     *  @param sobj
     */
    public static void start(String scheduleType,String sobj)
    {
        DART_Delivery_Support__c[] listDDs = new List<DART_Delivery_Support__c>();
        for(AdServer_Login__c login : [SELECT RecordType.name,Name,Login_URL__c, User_Name__c, Password__c, Network_ID__c FROM AdServer_Login__c WHERE  Active__c=true AND isDeleted=false ])//Id = 'a0UR0000003IsS7' And Network_ID__c <> null
        {
            DART_Delivery_Support__c dds = new DART_Delivery_Support__c(
                AdServer_Login__c = login.Id, Attempt__c = 0, Retry_Counter__c = 0,
                Schedule_Type__c = scheduleType,
                Sobject__c = sobj,
                Status__c = DART_STATUS_NEW
                );
            listDDs.add(dds);
        }
        
        if(!listDDs.isEmpty())
        {
            insert listDDs; 
            DART6BatchDeliverySupport batchSupport = new DART6BatchDeliverySupport(listDDs[0].Id, DART6BatchDeliverySupport.CALL_TYPE_REQUEST_REPORT);
            ID batchprocessid = Database.executeBatch(batchSupport);
        }
    }
    
    /** dart6: create a report job at dart server */
    public static void createReportJob(DART_Delivery_Support__c dds, DART6_REPORTSERVICE.REPORTServiceInterfacePort reportService, Dart6_ReportService.ReportJob reportJob)
    {
        dds.Job_Id__c = runReportRequest(reportService, reportJob);
        dds.DART_Status__c = REPORT_QUERY_INPROGRESS;
        dds.Status__c = DART_STATUS_AWAIT;
        dds.Attempt__c = dds.Attempt__c + 1;
        update dds;
        createSchedulerWatcher(dds.Id, dds.Sobject__c);
    } 
    
    /** createSchedulerWatcher */
    public static void createSchedulerWatcher(String ddsId, String sObj){
        DART6SchReportRequestWatcher watcher = new DART6SchReportRequestWatcher(ddsId);
        System.schedule('DART6 Delivery RunningReport Checker for Report ' + sObj + ' at ' + Datetime.now()  , watcher.createCronExpForNextFireTime(), watcher);
    } 
    
    public static void startNextAdServer(String sobj, String scheduletype){
        List<DART_Delivery_Support__c> ldds = [Select AdServer_Login__r.Name, AdServer_Login__r.Network_ID__c, AdServer_Login__r.RecordType.name,Status__c, Sobject__c, Schedule_Type__c, Job_Id__c, DART_Status__c, Attempt__c, AdServer_Login__c From DART_Delivery_Support__c Where Status__c =: DART_STATUS_NEW And Sobject__c =: sobj And Schedule_Type__c =: scheduletype limit 1];
        if(ldds.isEmpty()) return;
        DART6BatchDeliverySupport batchSupport = new DART6BatchDeliverySupport(ldds[0].Id, DART6BatchDeliverySupport.CALL_TYPE_REQUEST_REPORT);
        ID batchprocessstartNextAdServerid = Database.executeBatch(batchSupport);
    }
    
    /** dart6: check job status */ 
    public static void checkJobStatus(DART_Delivery_Support__c dds)
    {
        //dds = getDeliverySupportRecord(dds.Id);
        DART6_REPORTSERVICE.REPORTServiceInterfacePort reportService = DeliveryController.buildQueryService(dds);
        //request to get status here: COMPLETED, IN_PROGRESS, FAILED
        Dart6_ReportService.ReportJob reportJob = reportService.getReportJob((long)dds.Job_Id__c);
        // if complete ok -> run controller batch from importDelivery()
        if(reportJob.reportJobStatus == DART6_REPORTSERVICE.REPORTJOBSTATUS_COMPLETED){
            DeliveryController controller = new DeliveryController(dds);
            controller.setReportService(reportService);
            controller.setJobid((long)dds.Job_Id__c);
            controller.importDelivery();
            processBatchDelivery(dds, controller.getListDart());
            return;
        }
        // if complete FAILED -> log
        if(reportJob.reportJobStatus == DART6_REPORTSERVICE.REPORTJOBSTATUS_FAILED){
            dds.DART_Status__c = REPORT_QUERY_FAILED;
            dds.Status__c = DART_STATUS_FINISHED;
            update dds;
            throw new ExceptionGroup.DARTException('Failed to query report from server');
            return;
        }
        
        // If attempt more than MAX_ATTAMPT_WAITING, report job is stuck. A new job will be attempted 
        if(dds.Attempt__c > MAX_ATTAMPT_WAITING && dds.Status__c == DART_STATUS_AWAIT){
            retryImport(dds, new DARTLogger.LogMessage(
                                dds.Id ,'Import Delivery Process was abandoned',
                                'DeliveryController.checkJobStatus', dds.AdServer_Login__r.RecordType.name,
                                DARTLogger.TYPE_ERROR, dds.Status__c, 'Requesting report takes time too long with more than ' + MAX_ATTAMPT_WAITING + ' attempts' ));
            return;
        }
            
        // if in progress -> run scheduler watcher, attempt++
        dds.DART_Status__c = REPORT_QUERY_INPROGRESS;
        dds.Status__c = DART_STATUS_AWAIT;
        dds.Attempt__c = dds.Attempt__c + 1;
        createSchedulerWatcher(dds.Id, dds.Sobject__c);
        update dds;
    }
    
    
    /** dart5: request query: process in batch
     *  dart6: download xml : process in batch
     */
    public void importDelivery()
    {
        //create request
        HTTPWrapper.IGenericRequest deliveryRequest = FactoryDARTRequest.getInstance().createDartDeliveryRequest(login,breakDown,dateRange, jobid, reportService);
        
        //create parser 
        DART6Parser.IDartParser deliveryParser = FactoryParser.getInstance().createDeliveryParser(login.RecordType.Name, dartDelStatus.Sobject__c);
        
        //create connection
        DARTObject.IDARTConnector deliveryCon = FactoryConnector.getInstance().createConnector(login.RecordType.Name,deliveryRequest, deliveryParser);
        System.debug('\n\n=========================>> deliveryCon\n\n' + deliveryCon);
        deliveryCon.connect();    
        invokedMethod = deliveryRequest.getInvokedMethod();
        
        //getDartObjects
        listDartObjects = deliveryCon.getDartObjects();
        
    }
    
    public static DART_Delivery_Support__c getDeliverySupportRecord(String recId){
         return [Select Retried_DART_Delivery_Support__c, AdServer_Login__r.Name, AdServer_Login__r.Network_ID__c, AdServer_Login__r.RecordType.name,Status__c, Sobject__c, Schedule_Type__c, Job_Id__c, DART_Status__c, Attempt__c, AdServer_Login__c, Retry_Counter__c From DART_Delivery_Support__c where Id =: recId];
    }
    
    public static Map<String, String> mDart5BreakDown = new Map<String, String>{
        SCH_TYPE_MONTHLY => DART6Message.BREAKDOWN_MONTHLY, 
        SCH_TYPE_DAILY => DART6Message.BREAKDOWN_DAILY,
        SCH_TYPE_MANUALLY => DART6Message.BREAKDOWN_DAILY 
    };
    
    public static Map<String, String> mDart5DateRange = new Map<String, String>{
        SCH_TYPE_MONTHLY => DART6Message.DATERANGE_LASTMONTH, 
        SCH_TYPE_DAILY => DART6Message.DATERANGE_YESTERDAY,
        SCH_TYPE_MANUALLY => DART6Message.DATERANGE_YESTERDAY
    };
    
    public static Map<String, String> mGeneralQuery = new Map<String, String>{
        SOBJECT_REV_SCH2_DAILY => 'Select Ad_Id__c, Ad_Status__c, Order_Id__c, Delivered_AI__c, Delivered_AI_Lifetime__c, Clicks_Recorded__c, Clicks_Recorded_Lifetime__c, OSI_RSD__c, Product_Country_RSD__c, Day__c From ' + REVENUE_SCHEDULE_DAILY_API_NAME + ' Where %DATECRIT% Product__r.Site__r.Country__c =\'%1\' AND Product__r.RecordType.Name =\'%2\' AND Opportunity__r.IsWon = TRUE AND (Ad_Id__c <> null OR Order_Id__c <> null)',
        SOBJECT_REV_SCH2 => 'Select Ad_Id__c, Order_Id__c, Delivered_AI__c, Delivered_AI_Lifetime__c, Clicks_Recorded__c, Clicks_Recorded_Lifetime__c, Product_Country_RS__c, Month__c From ' + REVENUE_SCHEDULE_API_NAME  + ' Where %DATECRIT% Product__r.Site__r.Country__c =\'%1\' AND Product__r.RecordType.Name =\'%2\' AND Opportunity__r.IsWon = TRUE AND (Ad_Id__c <> null OR Order_Id__c <> null)',
        SOBJECT_OPPPRODUCT => 'Select Ad_Id__c, Ad_Status__c, Adserver_ID_Order_ID__c, Delivered_AI_LT__c, delivered_Clicks_LT__c, OSI__c, PricebookEntry.Product2.Site__r.Country__c, PricebookEntry.Product2.RecordType.Name From ' + OPPORTUNITY_PRODUCT_API_NAME + ' Where %DATECRIT% PricebookEntry.Product2.Site__r.Country__c =\'%1\' AND PricebookEntry.Product2.RecordType.Name =\'%2\' AND Opportunity.IsWon = TRUE AND (Ad_Id__c <> null OR Adserver_ID_Order_ID__c <> null)'
    };

    public static Map<String, String> mQuerySObject = new Map<String, String>{
        SOBJECT_REV_SCH2_DAILY => mGeneralQuery.get(SOBJECT_REV_SCH2_DAILY).replace('%DATECRIT%', ' Day__c >= %YESTERDAY% AND Day__c < %TOMORROW% AND '),
        SOBJECT_REV_SCH2 => mGeneralQuery.get(SOBJECT_REV_SCH2).replace('%DATECRIT%', ' Month__c >= %DAYSTART_LAST_MONTH% AND Month__c <= %TODAY% AND '),
        SOBJECT_OPPPRODUCT => mGeneralQuery.get(SOBJECT_OPPPRODUCT).replace('%DATECRIT%', ' from_Date__c <= %YESTERDAY% AND until_Date__c >= %YESTERDAY% AND ')
    };
         
    /**Called from 'start' of Main scheduler. and from Batch to continue to next Login */ 
    public static void doStart(DART_Delivery_Support__c dds)
    {   
        
        if(DARTUtil.DART5.equals(dds.AdServer_Login__r.RecordType.name))
        {
            //call batch to DeliveryController dCon = new DeliveryController(dds);
            DeliveryController controller = new DeliveryController([SELECT RecordType.name,Name,Login_URL__c, User_Name__c, Password__c, Network_ID__c FROM AdServer_Login__c WHERE Id =: dds.AdServer_Login__c], mDart5BreakDown.get(dds.Schedule_Type__c), mDart5DateRange.get(dds.Schedule_Type__c));
            
            System.debug('\n\n============================>Selected:\n\n' + [SELECT RecordType.name,Name,Login_URL__c, User_Name__c, Password__c, Network_ID__c FROM AdServer_Login__c WHERE Id =: dds.AdServer_Login__c]);
            System.debug('\n\n============================>controller:\n\n' + controller);
            controller.importDelivery();
            processBatchDelivery(dds, controller.getListDart());
        }
        else if(DARTUtil.DART6.equals(dds.AdServer_Login__r.RecordType.name)) 
        {
            DART6_REPORTSERVICE.REPORTServiceInterfacePort reportService = buildQueryService(dds);
            Dart6_ReportService.ReportJob reportJob = buildReportQuery(dds.Sobject__c, '');
            createReportJob(dds, reportService, reportJob);
        }
    }
    
    public static void processBatchDelivery(DART_Delivery_Support__c dds, List<DARTObject.IDARTGenericObject> lstDartObject){
        DateTime dToday = System.now();
        DateTime dNextMonth = dToday.addMonths(1);
        DateTime dLastMonth = dToday.addMonths(-1);
        String dsToday = dToday.format(DARTUtil.DART_DATEFORMAT_QUERY);
        String dsYesterday = dToday.addDays(-1).format(DARTUtil.DART_DATEFORMAT_QUERY) ;
        String dsB4Yesterday = dToday.addDays(-2).format(DARTUtil.DART_DATEFORMAT_QUERY) ;
        String dsTomorrow = dToday.addDays(1).format(DARTUtil.DART_DATEFORMAT_QUERY); 
        String dsStartThisMonth = DateTime.newInstance(dToday.year(),dToday.month(),dToday.day()).format(DARTUtil.DART_DATEFORMAT_QUERY) ;
        String dsStartNextMonth = DateTime.newInstance(dNextMonth.year(),dNextMonth.month(),dNextMonth.day()).format(DARTUtil.DART_DATEFORMAT_QUERY) ;
        String dsStartLastMonth = DateTime.newInstance(dLastMonth.year(),dLastMonth.month(),1).format(DARTUtil.DART_DATEFORMAT_QUERY) ;
        
        String queryStr = mQuerySObject.get(dds.Sobject__c).replace('%1', dds.AdServer_Login__r.Name).replace('%2', dds.AdServer_Login__r.RecordType.Name);
        queryStr = queryStr.replaceAll('%DAYSTART_THIS_MONTH%', dsStartThisMonth).replaceAll('%DAYSTART_NEXT_MONTH%', dsStartNextMonth).replaceAll('%TODAY%', dsToday).replaceAll('%YESTERDAY%', dsYesterday).replaceAll('%TOMORROW%', dsTomorrow).replaceAll('%B4YESTERDAY%', dsB4Yesterday).replaceAll('%DAYSTART_LAST_MONTH%', dsStartLastMonth);
        //NK:05/03/2014: moved from the line below (commented) to fix 'no more than 1 batch in test method'
        if(Test.isRunningTest()) queryStr = queryStr.substring(0, queryStr.indexOf('Where')) + ' Limit 1';
        BatchDeliveryProcess batchDelivery = new BatchDeliveryProcess(queryStr, lstDartObject, dds.Id);
        //if(Test.isRunningTest()) queryStr = queryStr.substring(0, queryStr.indexOf('Where')) + ' Limit 10';
        ID batchprocessid = Database.executeBatch(batchDelivery);
    }
    
    /** 
     *
     */
    public static DART6_REPORTSERVICE.REPORTServiceInterfacePort buildQueryService(DART_Delivery_Support__c dds){       
        return buildQueryService(dds.AdServer_Login__r.Name, dds.AdServer_Login__r.Network_ID__c);
    } 
    
    /** 
     *
     */
    public static DART6_REPORTSERVICE.REPORTServiceInterfacePort buildQueryService(String adServName, String netId){
        // Get Authentication
   /*** String authToken = DARTUtil.getRequestToken(adServName);
        DART6_REPORTSERVICE.Authentication authen = new DART6_REPORTSERVICE.Authentication();
        authen.Authentication_Type = DARTUtil.AUTHENTICATION_TYPE;
        authen.token = authToken;
        authen.type_x = DARTUtil.AUTHENTICATION_TYPE;   ***/
        
        AdServer_Login__c login = DARTUtil.getCredential(DARTUtil.DART6, adServName);
        String authToken = DARTUtil.getAccessToken(login); // new version 201411
        
        // Build Service Request Header
        DART6_REPORTSERVICE.SoapRequestHeader header = new DART6_REPORTSERVICE.SoapRequestHeader();
        header.applicationName='ReportService';
        header.networkCode= netId;

        Map<String,String> inputHttpHeaders_x = new Map<String, String>();     // new version 201411
        inputHttpHeaders_x.put('Authorization', 'Bearer '+authToken);          // new version 201411
        
        DART6_REPORTSERVICE.REPORTServiceInterfacePort reportService = new DART6_REPORTSERVICE.ReportServiceInterfacePort();
        reportService.RequestHeader = header;       
        reportService.inputHttpHeaders_x = inputHttpHeaders_x;       // new version 201411
        
        return reportService;
    }
    
    private static Map<String,String[]> queryFieldsDART6 = new Map<String, String[]>{
                SOBJECT_OPPPRODUCT => new String[]{'MERGED_AD_SERVER_DELIVERY_INDICATOR'},
                SOBJECT_REV_SCH2_DAILY => new String[]{'MERGED_AD_SERVER_IMPRESSIONS','MERGED_AD_SERVER_CLICKS', 'MERGED_AD_SERVER_DELIVERY_INDICATOR'},
                SOBJECT_REV_SCH2 => new String[]{'MERGED_AD_SERVER_IMPRESSIONS','MERGED_AD_SERVER_CLICKS', 'MERGED_AD_SERVER_DELIVERY_INDICATOR'}
    };
    
    private static Map<String,String[]> dimensionFieldsDART6 = new Map<String, String[]>{
            SOBJECT_OPPPRODUCT => new String[]{'ORDER_ID', 'LINE_ITEM_ID'},
            SOBJECT_REV_SCH2_DAILY => new String[] {'ORDER_ID', 'LINE_ITEM_ID', 'DATE'},
            SOBJECT_REV_SCH2 => new String[] {'ORDER_ID', 'LINE_ITEM_ID', 'MONTH_AND_YEAR'}
    };
    
    /**
     * Build Query for report service
     */
    public static Dart6_ReportService.ReportJob buildReportQuery(String sobjType, String addQuery){
        // Create report query.
        Dart6_ReportService.Statement statement = new Dart6_ReportService.Statement();
        statement.query = addQuery;
        Dart6_ReportService.ReportQuery reportQuery = new Dart6_ReportService.ReportQuery();
        reportQuery.statement = statement;
        reportQuery.dateRangeType = 'CUSTOM_DATE';
        reportQuery.columns = queryFieldsDART6.get(sobjType);
        reportQuery.dimensions = dimensionFieldsDART6.get(sobjType);
        DateTime todayDate = System.now();
        DateTime yesterdayDate = todayDate.addDays(-1);
        DateTime b4yesterdayDate = todayDate.addDays(-2);
        DateTime lastMonthDate = todayDate.addMonths(-1);
        DateTime daystartLastMonth = DateTime.newInstance(lastMonthDate.year(),lastMonthDate.month(),1);
        
        reportQuery.startDate = new Dart6_ReportService.Date_x();
        reportQuery.endDate = new Dart6_ReportService.Date_x();
        if(sobjType == SOBJECT_OPPPRODUCT){
            reportQuery.dimensionAttributes = new String[]{'LINE_ITEM_LIFETIME_MERGED_IMPRESSIONS', 'LINE_ITEM_LIFETIME_MERGED_CLICKS'};
            reportQuery.startDate.year = yesterdayDate.year();
            reportQuery.startDate.month = yesterdayDate.month();
            reportQuery.startDate.day = yesterdayDate.day();
            reportQuery.endDate.year = todayDate.year();
            reportQuery.endDate.month = todayDate.month();
            reportQuery.endDate.day = todayDate.day();
        }else if(sobjType == SOBJECT_REV_SCH2_DAILY){
            reportQuery.startDate.year = yesterdayDate.year();
            reportQuery.startDate.month = yesterdayDate.month();
            reportQuery.startDate.day = yesterdayDate.day();
            reportQuery.endDate.year = todayDate.year();
            reportQuery.endDate.month = todayDate.month();
            reportQuery.endDate.day = todayDate.day();
        }else if(sobjType == SOBJECT_REV_SCH2){
            reportQuery.startDate.year = daystartLastMonth.year();
            reportQuery.startDate.month = daystartLastMonth.month();
            reportQuery.startDate.day = daystartLastMonth.day();
            reportQuery.endDate.year = todayDate.year();
            reportQuery.endDate.month = todayDate.month();
            reportQuery.endDate.day = todayDate.day();
        }
        //test dateRange
        //reportQuery.statement.query = 'WHERE LINE_ITEM_ID IN (9385390, 9320350)';
        //reportQuery.dateRangeType = 'CUSTOM_DATE';
        
        Dart6_ReportService.ReportJob reportJob = new Dart6_ReportService.ReportJob();
        reportJob.reportQuery = reportQuery;
        return reportJob;
    }
    
    /**
     * @return runningReportId as String
     */
    public static Long runReportRequest(DART6_REPORTSERVICE.REPORTServiceInterfacePort reportService, Dart6_ReportService.ReportJob reportJob){
        // Run report job.
        reportJob = reportService.runReportJob(reportJob);
        return reportJob.id;
    }
    
    /**
    * Retry another job after a time-out failure OR job has been stuck
    */
    public static void retryImport(DART_Delivery_Support__c failedDds, DARTLogger.LogMessage logmsg){
        if(failedDds.Status__c != DART_STATUS_FINISHED && failedDds.Retry_Counter__c < MAX_RETRY_IMPORT){
            DART_Delivery_Support__c retriedDds = failedDds.clone(false);
            retriedDds.Attempt__c = 0;
            retriedDds.Status__c = DART_STATUS_NEW;
            retriedDds.DART_Status__c = null;
            retriedDds.Job_Id__c = null;
            retriedDds.Retry_Counter__c = failedDds.Retry_Counter__c + 1;
            insert retriedDds;
            failedDds.Retried_DART_Delivery_Support__c = retriedDds.Id;
            failedDds.DART_Status__c = REPORT_QUERY_RETRY;
        }
        failedDds.Status__c = DART_STATUS_FINISHED;
        if(failedDds.DART_Status__c != REPORT_QUERY_RETRY) failedDds.DART_Status__c = REPORT_QUERY_FAILED;
        update failedDds;
        if(logmsg != null) DARTLogger.getInstance().log(failedDds.Id,new List<DARTLogger.LogMessage>{logmsg});
        startNextAdServer(failedDds.Sobject__c, failedDds.Schedule_Type__c);
    }
    
    /**
    * Added For Importing status: OLI,RSD
    * @created date: 9-May-2013
    */
    public static void updateStatusLineItem (DART_Delivery_Support__c dds, List<SObject> lSobjects){
        String fieldAdId = 'Ad_Id__c';
        String fieldDateRSD = 'Day__c';
        String fieldStatus = 'Ad_Status__c';
        String orderIds = '';
        Map<String, SObject> mIds = new Map<String, SObject>();
        for(SObject sobj : lSobjects){
            if(String.valueOf(sobj.getSObjectType()) == REVENUE_SCHEDULE_API_NAME) return;
            if(
                sobj.get(fieldAdId) == null ||
                (String.valueOf(sobj.getSObjectType()) == REVENUE_SCHEDULE_DAILY_API_NAME && sobj.get(fieldDateRSD) != null && Date.valueOf(sobj.get(fieldDateRSD)) != System.today())
            ) continue;
            String adIdVal = String.valueOf(sobj.get(fieldAdId));
            if(!mIds.containsKey(adIdVal)) orderIds += adIdVal + ',';
            mIds.put(adIdVal, sobj);            
        }
        if(orderIds == '') return;
        orderIds = orderIds.substring(0, orderIds.length()-1);
        DART6_LINEITEMSERVICE.LineItemServiceInterfacePort lineItemService = DeliveryController.buildLineItemService(dds);
        // Create a statement to only select line items that need creatives from a given order.
        DART6_LINEITEMSERVICE.Statement filterStatement = new DART6_LINEITEMSERVICE.Statement();
        filterStatement.query = 'WHERE id IN (' + orderIds + ')';
        // Get line items by statement.
        DART6_LINEITEMSERVICE.LineItemPage page = lineItemService.getLineItemsByStatement(filterStatement);
        if (page.results != null) {
            for (DART6_LINEITEMSERVICE.LineItem lineItem : page.results) {
                if(!mIds.containsKey(String.valueOf(lineItem.id))) continue;
                mIds.get(String.valueOf(lineItem.id)).put(fieldStatus, lineItem.status);
            }
        }
        update mIds.values();
    }
    
    /**
    * Added For Importing status: Build LineItem service
    */
    public static DART6_LINEITEMSERVICE.LineItemServiceInterfacePort buildLineItemService(DART_Delivery_Support__c dds){
        String adServName = dds.AdServer_Login__r.Name; 
        String netId = dds.AdServer_Login__r.Network_ID__c;
        // Get Authentication
   /***     String authToken = DARTUtil.getRequestToken(adServName);
        DART6_LINEITEMSERVICE.Authentication authen = new DART6_LINEITEMSERVICE.Authentication();
        authen.Authentication_Type = DARTUtil.AUTHENTICATION_TYPE;
        authen.token = authToken;
        authen.type_x = DARTUtil.AUTHENTICATION_TYPE;    ***/ //old version
        
        AdServer_Login__c login = DARTUtil.getCredential(DARTUtil.DART6, adServName);
        String authToken = DARTUtil.getAccessToken(login); // new version 201411
        
        // Build Service Request Header
        DART6_LINEITEMSERVICE.SoapRequestHeader header = new DART6_LINEITEMSERVICE.SoapRequestHeader();
        header.applicationName='LineItemService';
        header.networkCode= netId;
        
         Map<String,String> inputHttpHeaders_x = new Map<String, String>();     // new version 201411
        inputHttpHeaders_x.put('Authorization', 'Bearer '+authToken);          // new version 201411
        
        DART6_LINEITEMSERVICE.LineItemServiceInterfacePort lineItemService = new DART6_LINEITEMSERVICE.LineItemServiceInterfacePort();
        lineItemService.RequestHeader = header;
        lineItemService.inputHttpHeaders_x = inputHttpHeaders_x;       // new version 201411  
      
        return lineItemService;
    }
    
    /** Test DART6 DeliveryReport */
    @isTest(SeeAllData=true)  
    static void testDART6DeliveryReport()
    {
        TestDataGenerator testDATA = new TestDataGenerator();
        // Generate data opp/oppItem
        testDATA.createCredential();
        testDATA.createTargetingHierarchy();
        testDATA.createAccount();
        testDATA.createAdvertiser();
        testDATA.createOpp(testDATA.lstAcc.get(0));
        testDATA.createOppTeamMember(testDATA.opp.id);
        testDATA.createNewOppItemsDart(testDATA.opp.id,2,DARTUtil.DART6,testDATA.targetting[0].Id);
            
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
        DeliveryController.startNextAdServer('Opportunity Product', 'Manually');
        DeliveryController.start('Manually', 'Opportunity Product');
        DeliveryController.doStart(dds);
        
        DeliveryController.processBatchDelivery(dds, devCont.getListDart());
        DeliveryController devCont2 = new DeliveryController(dds);
        DeliveryController devCont3 = new DeliveryController(testDATA.listLogin.get(1), DART6Message.BREAKDOWN_DAILY, DART6Message.DATERANGE_YESTERDAY);
        
        test.stopTest();
    }
}