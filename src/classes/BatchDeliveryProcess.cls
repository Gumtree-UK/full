/** Batch process of Delivery
 *  Request all Report From Dart and check with relevant SObjects
 *  1.  OpportunityProduct (daily run and manual run) 
 *  2.  Revenue_Schedules2__c (monthly run) 
 *  3.  Revenue_Schedule_Daily2__c (daily run)
 *  @Created Date: 18/01/2013  
 *  @Change log:
 *  - 2013-05-10 - GTCRM-207 - Map DFP lineItem status to Ad Status field in SF on OLI & RSD
 *  - 2014-17-Oct - Task #4167 - Failed to process batch for class 'BatchDeliveryProcess' (UNABLE_TO_LOCK_ROW)
 */  
global class BatchDeliveryProcess implements Database.Batchable<sObject>, Database.Stateful, Database.AllowsCallOuts{
    private final String SOBJ_FIELD_SEP = '.';
    public final Integer MAX_RETRY = 5;
    private Map<String, DARTObject.IDARTGenericObject> mWithAdId;
    private Map<String, List<DARTObject.IDARTGenericObject>> mWithOutAdId;
    private String networkId;
    private String sobj;  
    private DART_Delivery_Support__c dds;
    private Integer dartSize = 0; 
    private Set<String> ignoredFields = new Set<String>{'Ad_Id__c', 'Adserver_ID_Order_ID__c', 'Day__c', 'Month__c'};
    private Set<String> retryRowIds;
    
    public String queryString;
    public Set<String> successRecords = new Set<String>();
    public Set<String> unupdateRecords = new Set<String>();
    public List<DARTObject.IDARTGenericObject> listImport= new List<DARTObject.IDARTGenericObject>();
    public String loggedString = '';
    public Integer retryCounter = 0;
    
    
    /**
     * D6 FieldNames:
     * mergeReservationImpressionsDelivered -> MERGED_AD_SERVER_IMPRESSIONS
     * mergeLineItemDeliveryIndicator -> MERGED_AD_SERVER_DELIVERY_INDICATOR
     * mergeReservationClicksDelivered -> MERGED_AD_SERVER_CLICKS 
     */
    public Map<String, String> mFieldsDartToSObj = new Map<String, String>{
        //Matching OpportunityLineItem
        DeliveryController.OPPORTUNITY_PRODUCT_API_NAME + SOBJ_FIELD_SEP + 'Ad_Id__c' => DARTObject.DEL_FIELD_ADID, //'lineItemId',
        DeliveryController.OPPORTUNITY_PRODUCT_API_NAME + SOBJ_FIELD_SEP + 'Adserver_ID_Order_ID__c' => DARTObject.DEL_FIELD_ORDERID, //'orderId',
        DeliveryController.OPPORTUNITY_PRODUCT_API_NAME + SOBJ_FIELD_SEP + 'Delivered_AI_LT__c' => DARTObject.DEL_FIELD_ADDELIVERED, //'mergeReservationImpressionsDelivered', Delivered (Lifetime)  
        DeliveryController.OPPORTUNITY_PRODUCT_API_NAME + SOBJ_FIELD_SEP + 'delivered_Clicks_LT__c' => DARTObject.DEL_FIELD_ADCLICKED_LIFETIME, //'mergeReservationClicksDelivered', Clicks Recorded (Lifetime) (delivered_Clicks_LT__c)
        DeliveryController.OPPORTUNITY_PRODUCT_API_NAME + SOBJ_FIELD_SEP + 'OSI__c' => DARTObject.DEL_FIELD_ADOSI, //'mergeLineItemDeliveryIndicator', OSI (Lifetime)
        //Matching Revenue_Schedules2__c
        DeliveryController.REVENUE_SCHEDULE_API_NAME + SOBJ_FIELD_SEP + 'Delivered_AI__c' => DARTObject.DEL_FIELD_IMPRESS_DELIVERED, //'mergeReservationImpressionsDelivered', Impressions Delivered  
        //DeliveryController.REVENUE_SCHEDULE_API_NAME + SOBJ_FIELD_SEP + 'Delivered_AI_Lifetime__c' => DARTObject.DEL_FIELD_ADDELIVERED, //'mergeReservationImpressionsDelivered', Delivered (Lifetime) 
        DeliveryController.REVENUE_SCHEDULE_API_NAME + SOBJ_FIELD_SEP + 'Clicks_Recorded__c' => DARTObject.DEL_FIELD_CLICKS_DELIVERED, //'mergeReservationClicksDelivered', Clicks Recorded 
        //DeliveryController.REVENUE_SCHEDULE_API_NAME + SOBJ_FIELD_SEP + 'Clicks_Recorded_Lifetime__c' => DARTObject.DEL_FIELD_ADCLICKED_LIFETIME, //'mergeReservationClicksDelivered', Clicks Recorded (Lifetime)
        //Revenue_Schedule_daily2__c
        DeliveryController.REVENUE_SCHEDULE_DAILY_API_NAME + SOBJ_FIELD_SEP + 'Delivered_AI__c' => DARTObject.DEL_FIELD_IMPRESS_DELIVERED, //'mergeReservationImpressionsDelivered', Impressions Delivered  
        //DeliveryController.REVENUE_SCHEDULE_DAILY_API_NAME + SOBJ_FIELD_SEP + 'Delivered_AI_Lifetime__c' => DARTObject.DEL_FIELD_ADDELIVERED, //'mergeReservationImpressionsDelivered', Delivered (Lifetime) 
        DeliveryController.REVENUE_SCHEDULE_DAILY_API_NAME + SOBJ_FIELD_SEP + 'Clicks_Recorded__c' => DARTObject.DEL_FIELD_CLICKS_DELIVERED, //'mergeReservationClicksDelivered', Clicks Recorded 
        //DeliveryController.REVENUE_SCHEDULE_DAILY_API_NAME + SOBJ_FIELD_SEP + 'Clicks_Recorded_Lifetime__c' => DARTObject.DEL_FIELD_ADCLICKED_LIFETIME, //'mergeReservationClicksDelivered', Clicks Recorded (Lifetime)
        DeliveryController.REVENUE_SCHEDULE_DAILY_API_NAME + SOBJ_FIELD_SEP + 'OSI_RSD__c' => DARTObject.DEL_FIELD_ADOSI //'mergeLineItemDeliveryIndicator'
    };
    
    /** 
     * For executing on first adlogin 
     */
    public BatchDeliveryProcess(String queryString, List<DARTObject.IDARTGenericObject> lstDartObject, String ddsId){ 
        dartSize = lstDartObject.size();
        this.dds = DeliveryController.getDeliverySupportRecord(ddsId);
        this.networkId = dds.AdServer_Login__r.Name;
        this.queryString = queryString;
        this.sobj = dds.Sobject__c;
        this.listImport = lstDartObject;
        initMapperDartObject(lstDartObject);
        retryRowIds = new Set<String>();
    }
    
    /**
     * Retry on some technically failed records, specific ids for re-execution
     * For specific reason: DML Lock Row
     */
    public BatchDeliveryProcess(String queryString, List<DARTObject.IDARTGenericObject> lstDartObject, String ddsId, Set<String> retryIds){
    	this(queryString, lstDartObject, ddsId);
    	retryRowIds = retryIds;
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC){
    	//Check the query should be a retry query or ordinary query
        return Database.getQueryLocator(queryString + (!retryRowIds.isEmpty() ? ' And Id IN: retryRowIds' : ''));
    }
      
    global void execute(Database.BatchableContext BC, List<sObject> scope){
    	BatchAutoRenewal.fromBatch=true;
        doExecute(scope);
        BatchAutoRenewal.fromBatch=false;
    }
    
    global void doExecute(List<Sobject> scope){
        //Update status
        List<DARTLogger.LogMessage> ldartLogger = new List<DARTLogger.LogMessage>();
        try{
            DeliveryController.updateStatusLineItem(dds, scope);
        }catch(Exception e){
            ldartLogger.add(new DARTLogger.LogMessage(
                dds.Id ,'Import Delivery Status Fault',
                'BatchDeliveryProcess.execute', dds.AdServer_Login__r.RecordType.name,
                DARTLogger.TYPE_ERROR, dds.DART_Status__c, e + ''));
        } 

        //Update amount fields
        List<Sobject> lsobj = new List<Sobject>();
        for(Sobject sobj : scope){
            try{
                String sobjId = sobj.get('Id') + '';
                if(submitToSFRecord(sobj)){
                    lsobj.add(sobj);
                    successRecords.add(sobjId); 
                }else{
                    unupdateRecords.add(sobjId);
                }
            }catch(Exception e){
                ldartLogger.add(new DARTLogger.LogMessage(
                    sobj.Id ,'Import Delivery Process Fault',
                    'BatchDeliveryProcess.execute', dds.AdServer_Login__r.RecordType.name,
                    DARTLogger.TYPE_ERROR, dds.DART_Status__c, e + ''));
            } 
        }
        //if(!lsobj.isEmpty()) update lsobj;
        
        //Handle some locked records form other contexts
        Database.SaveResult[] lsr = Database.update(lsobj, false);
		for (Database.SaveResult sr:lsr){
		    if(sr.isSuccess()) continue;
		    Database.Error err = sr.getErrors()[0];
		    if(err.getMessage().contains('UNABLE_TO_LOCK_ROW')){
		    	retryRowIds.add(sr.getId());
		    	successRecords.remove(sr.getId());
		    	unupdateRecords.add(sr.getId());
		    }
		}
		if(!retryRowIds.isEmpty()){
			ldartLogger.add(new DARTLogger.LogMessage(
                    dds.Id ,'Import Delivery Process Fault',
                    'BatchDeliveryProcess.execute', dds.AdServer_Login__r.RecordType.name,
                    DARTLogger.TYPE_ERROR, dds.DART_Status__c, 'UNABLE_TO_LOCK_ROW for some records, retry action on finish[' +retryCounter+ '] :' + retryRowIds));
		}
        if(!ldartLogger.isEmpty()) DARTLogger.getInstance().log(dds.Id,ldartLogger);
    }  
    
    global void dofinish(){
    	if(!retryRowIds.isEmpty() && retryCounter < MAX_RETRY){
    		BatchDeliveryProcess retryBatch = new BatchDeliveryProcess(queryString, listImport, dds.Id, retryRowIds);
    		retryBatch.successRecords = successRecords;
    		retryBatch.unupdateRecords = unupdateRecords;
    		retryBatch.retryCounter = retryCounter + 1; 
    		retryBatch.loggedString = loggedString + '\nRetry [' +retryCounter+ ']:' + '\n' + retryRowIds + '\n';
    		ID batchprocessid = Database.executeBatch(retryBatch);
    		return;
    	}
    	dds.DART_Status__c = DeliveryController.REPORT_QUERY_COMPLETED;
        dds.Status__c = DeliveryController.DART_STATUS_FINISHED;
        update dds;
        Attachment attlog = createAttachedLogfile(true);
        DARTLogger.getInstance().log(dds.Id,new List<DARTLogger.LogMessage>{new DARTLogger.LogMessage(
                                dds.Id ,'Import Delivery Process',
                                'BatchDeliveryProcess.finish',dds.AdServer_Login__r.RecordType.name,
                                DARTLogger.TYPE_SUCCESS, dds.DART_Status__c, 'Update size: ' + successRecords.size() + ' of '+ dartSize + ' [ Attachment Id Details ' + attlog.Id + ' ]')});
    	DeliveryController.startNextAdServer(sobj, dds.Schedule_Type__c);
    }
    
    global void finish(Database.BatchableContext BC){
        try{
            dofinish();
        }catch(Exception e){
            DARTLogger.getInstance().log(dds.Id,new List<DARTLogger.LogMessage>{new DARTLogger.LogMessage(
                                dds.Id ,'Import Delivery Process Fault',
                                'BatchDeliveryProcess.finish', dds.AdServer_Login__r.RecordType.name,
                                DARTLogger.TYPE_ERROR, dds.DART_Status__c, e + '')});
            DeliveryController.startNextAdServer(sobj, dds.Schedule_Type__c);
        } 
    }

    /**
     * For Matching Ad Id from report with Ad_Id__c
     */
    private void initMapperDartObject(List<DARTObject.IDARTGenericObject> lstDartObject){
        mWithAdId = new Map<String, DARTObject.IDARTGenericObject>();
        mWithOutAdId = new Map<String, List<DARTObject.IDARTGenericObject>>();
        for(DARTObject.IDARTGenericObject dObj : lstDartObject){
            DARTObject.DARTDelivery dartObj = (DARTObject.DARTDelivery)dObj;
            if(dartObj.getAdId() != ''){
                mWithAdId.put(getCombinedKeyDart(dartObj, false), dartObj);
                
                loggedString += getCombinedKeyDart(dartObj, false) + ' ========= ' + dartObj + '\n\n';
                
            } 
            if(dartObj.getOrderId() != ''){
                if(!mWithOutAdId.containsKey(dartObj.getOrderId())) mWithOutAdId.put(getCombinedKeyDart(dartObj, true), new List<DARTObject.IDARTGenericObject>());
                mWithOutAdId.get(getCombinedKeyDart(dartObj, true)).add(dartObj);
            }
        }
    }
    
    private String getCombinedKeyDart(DARTObject.DARTDelivery dartObj, Boolean isAdIdNull){
    	String dateString = dartObj.getDateString();
    	if(dateString.contains(' ')) dateString = dateString.split(' ')[0];
        if(isAdIdNull) return dartObj.getOrderId() + SOBJ_FIELD_SEP + networkId + SOBJ_FIELD_SEP + dateString;
        return dartObj.getAdId() + SOBJ_FIELD_SEP + networkId + SOBJ_FIELD_SEP + dateString;
    }
    
    private String getCombinedKeySObject(SObject sobj, Boolean isAdIdNull){
        Map<String, String> mTypeField = new Map<String, String>{
            DeliveryController.REVENUE_SCHEDULE_API_NAME => 'Product_Country_RS__c', 
            DeliveryController.REVENUE_SCHEDULE_DAILY_API_NAME => 'Product_Country_RSD__c',
            DeliveryController.OPPORTUNITY_PRODUCT_API_NAME => 'PricebookEntry.Product2.Site__r.Country__c'
        };
        
        Map<String, String> mDateField = new Map<String, String>{
            DeliveryController.REVENUE_SCHEDULE_API_NAME => 'Month__c', 
            DeliveryController.REVENUE_SCHEDULE_DAILY_API_NAME => 'Day__c',
            DeliveryController.OPPORTUNITY_PRODUCT_API_NAME => ''
        }; 
         
        String sobjType = String.valueOf(sobj.getSObjectType());
        
        String valDate = mDateField.get(sobjType) == '' ? '' : sobj.get(mDateField.get(sobjType)) + '';
        if(valDate != ''){
            DateTime valDatetime = DateTime.valueOf(valDate);
            if(sobjType == DeliveryController.REVENUE_SCHEDULE_API_NAME) valDate = MINT_TO_MONTH.get(valDatetime.month());
            else if(sobjType == DeliveryController.REVENUE_SCHEDULE_DAILY_API_NAME) valDate = valDatetime.format('M/d/yy');// format response from server;
        } 
        
        String networkfield = mTypeField.get(sobjType);
        String valNetwork = '';
        if(networkfield == 'PricebookEntry.Product2.Site__r.Country__c') valNetwork += sobj.getSObject('PricebookEntry').getSObject('Product2').getSObject('Site__r').get('Country__c');
        else valNetwork += sobj.get(networkfield);
        
        //If Ad_Id__c = “” match Order Id from report with Order_Id__c, oppline If Ad_Id__c = “” match Order Id from report with Adserver_ID_Order_ID__c
        if(isAdIdNull) return (sobjType == DeliveryController.OPPORTUNITY_PRODUCT_API_NAME ? sobj.get('Adserver_ID_Order_ID__c')  : sobj.get('Order_Id__c')) + SOBJ_FIELD_SEP + valNetwork + SOBJ_FIELD_SEP + valDate;
        return sobj.get('Ad_Id__c') + SOBJ_FIELD_SEP + valNetwork + SOBJ_FIELD_SEP + valDate;
        
    }
    
    /**
     * • Match Ad Id from report with Ad_Id__c and submit values to SF according to 5.3
     * • If Ad_Id__c = “” match Order Id from report with Order_Id__c, sum up values and submit sum to SF according to 5.3
     * • Only for daily: Select from OpportunityProducts all records according to 5.2.2 and get Adserver_ID_Order_ID__c, Ad_Id__c
     * • Match Ad Id from report with Ad_Id__c and submit values to SF according to 5.3
     * • If Ad_Id__c = “” match Order Id from report with Adserver_ID_Order_ID__c, sum up values and submit sum to SF according to 5.3
     */
    private Boolean submitToSFRecord(SObject sobj){
        loggedString += getCombinedKeySObject(sobj, false) + ' >>>>>> ' + sobj + '\n\n';
        String sobjType = sobj.getSObjectType() + SOBJ_FIELD_SEP ;
        //Get Matching DartObjects
        DARTObject.DARTDelivery dartObject = null;
        if(sobj.get('Ad_Id__c') == null){
            String val_Order = getCombinedKeySObject(sobj, true);
            //Sum List dartObjects
            if(mWithOutAdId.containsKey(val_Order)) dartObject = sumDartObjects((List<DARTObject.DARTDelivery>)mWithOutAdId.get(val_Order)); 
        }else if(mWithAdId.containsKey(getCombinedKeySObject(sobj, false))){
            dartObject = (DARTObject.DARTDelivery)mWithAdId.get(getCombinedKeySObject(sobj, false));
        }
        if(dartObject == null) return false;
        //Assign Values form matching DartObject to SObject
        for(String combinTypeField : mFieldsDartToSObj.keySet()){
            if(!combinTypeField.contains(sobjType)) continue;
            String sobjFieldname = combinTypeField.replace(sobjType, '');
            if(ignoredFields.contains(sobjFieldname)) continue;
            String dartObjectFieldname = mFieldsDartToSObj.get(combinTypeField);
            String dartVal = String.valueOf(dartObject.getValue(dartObjectFieldname) + '');
            dartVal = dartVal.replace('%', '').replace(',', '');
            if(!DARTUtil.isNumber(dartVal)) continue;
            sobj.put(sobjFieldname, Decimal.valueOf(dartVal));
        }
        return true;
    }
    //DARTDelivery:[mapRecord={AdClickedLifetime=313, AdDelivered=432,652, AdId=16350070, AdOSI=97.73%, CampaignId=120347110, ClicksDelivered=313, ImpressionsDelivered=432,652}]
    /**
     * Sum all dartObject with empty Ad Id 
     */
     private DARTObject.DARTDelivery sumDartObjects(List<DARTObject.DARTDelivery> ldartDelivery){
        Map<Object,Object> mapRecord = new Map<Object,Object>{
            DARTObject.DEL_FIELD_ADDELIVERED => '0',
            DARTObject.DEL_FIELD_ADCLICKED_LIFETIME => '0',
            DARTObject.DEL_FIELD_ADOSI => '0',
            DARTObject.DEL_FIELD_ADID => '0',
            DARTObject.DEL_FIELD_ORDERID => '0',
            DARTObject.DEL_FIELD_IMPRESS_DELIVERED => '0',
            DARTObject.DEL_FIELD_CLICKS_DELIVERED => '0'
        };
        for(Integer i = 0; i<ldartDelivery.size(); i++){
            DARTObject.DARTDelivery dartDelivery = ldartDelivery[i];
            for(Object keyObject : mapRecord.keySet()){
                String fldname = (String)keyObject;
                if(fldname.equals(DARTObject.DEL_FIELD_ADID) || fldname.equals(DARTObject.DEL_FIELD_ORDERID)) continue; 
                String recVal = String.valueOf(mapRecord.get(fldname)+'').replace('%', '').replace(',', '');
                if(!DARTUtil.isNumber(recVal)) recVal = '0';
                String dartVal = String.valueOf(dartDelivery.getValue(fldname)+'').replace('%', '').replace(',', '');
                if(!DARTUtil.isNumber(dartVal)) dartVal = '0';
                Decimal sum = Decimal.valueOf(recVal) + Decimal.valueOf(dartVal);
                mapRecord.put(fldname, sum);
            }
        }
        return new DARTObject.DARTDelivery(mapRecord);
     } 
     
     public static final Map<Integer, String> MINT_TO_MONTH = new Map<Integer, String>{
        1 => 'January',
        2 => 'February',
        3 => 'March',
        4 => 'April',
        5 => 'May',
        6 => 'June',
        7 => 'July',
        8 => 'August',
        9 => 'September',
        10 => 'October',
        11 => 'November',
        12 => 'December'
    };
    
    private Attachment createAttachedLogfile(Boolean doLog){
        Attachment att = new Attachment();
        att.ParentId = dds.Id;
        att.Name = 'Logged Import Data';
        if(!doLog) return att;
        String messageBody = 'Updated size: ' + successRecords.size() + ' of '+ dartSize;
        messageBody += '\n\nUpdated Records:[ ';
        for(String rec : successRecords) messageBody += ' ' + rec;
        messageBody += ' ]\n\nNonUpdate Records:[ ';
        for(String rec : unupdateRecords) messageBody += ' ' + rec; 
        messageBody += ' ]\n\nImported Data:[ ';
        for(DARTObject.IDARTGenericObject dObj : listImport){
            DARTObject.DARTDelivery dartObj = (DARTObject.DARTDelivery)dObj;
            messageBody += '\n' + dartObj.getAdId() + ' > ' + dartObj;
        }
        messageBody += ' ]'; 
        att.Body = Blob.valueOf(messageBody + '\n\n ----EXTRA MAPPING---- :\n\n' + loggedString);
        insert att;
        return att;
    }
}