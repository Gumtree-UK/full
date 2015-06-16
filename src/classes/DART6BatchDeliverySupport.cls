global class DART6BatchDeliverySupport implements Database.Batchable<sObject>, Database.AllowsCallOuts, Database.Stateful{

	public final static String CALL_TYPE_CHECK_REPORT_STATUS = 'Check Running Report';
	public final static String CALL_TYPE_REQUEST_REPORT = 'Query Report';
	private String callType;
	public String jobId;
	private DART_Delivery_Support__c dds;
	 
	public DART6BatchDeliverySupport(String ddsId, String calltype){
		this.callType = calltype;
		dds = DeliveryController.getDeliverySupportRecord(ddsId);
	}

	global Database.QueryLocator start(Database.BatchableContext BC){
		return Database.getQueryLocator([Select Id From DART_Delivery_Support__c Where Id =: dds.Id]);
	}
	 
	global void execute(Database.BatchableContext BC, List<sObject> scope){}  
	
	global void finish(Database.BatchableContext BC){
		try{
			if(callType == CALL_TYPE_CHECK_REPORT_STATUS){ 
				DeliveryController.checkJobStatus(dds); 
			}else if(callType == CALL_TYPE_REQUEST_REPORT){ 
				DeliveryController.doStart(dds);
			}
			if(jobId != null ) System.abortJob(jobId);
		}catch(Exception e){
			DeliveryController.retryImport(dds, new DARTLogger.LogMessage(
								dds.Id , callType,
							    'DART6BatchDeliverySupport.finish', dds.AdServer_Login__r.RecordType.name, e));
			if(jobId != null ) System.abortJob(jobId);
		}
	}
}