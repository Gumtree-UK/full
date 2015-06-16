global class DART6SchReportRequestWatcher implements Schedulable{
    public final static Integer NEXT_EXEC_TIME_IN_SECONDS = 120; // minimum 2 mins
    private String ddsId;
    /**
     * 
     */
    public DART6SchReportRequestWatcher(String ddsId){
        this.ddsId = ddsId;
    } 
    
    public String createCronExpForNextFireTime(){
        DateTime now = System.now().addSeconds(NEXT_EXEC_TIME_IN_SECONDS);
        return now.second() + ' ' 
            + now.minute() + ' ' 
            + now.hour() + ' '
            + now.day() + ' '
            + now.month() + ' ? ' 
            + now.year();
    }
    
    global void execute(SchedulableContext sc) {
    	DART_Delivery_Support__c dds = DeliveryController.getDeliverySupportRecord(ddsId);
        try{
        	DART6BatchDeliverySupport batchSupport = new DART6BatchDeliverySupport(ddsId, DART6BatchDeliverySupport.CALL_TYPE_CHECK_REPORT_STATUS);
        	if(sc != null) batchSupport.jobId = sc.getTriggerID();
        	ID batchprocessid = Database.executeBatch(batchSupport);
    	}catch(Exception e){
    		DeliveryController.retryImport(dds, new DARTLogger.LogMessage(
								dds.Id , DART6BatchDeliverySupport.CALL_TYPE_CHECK_REPORT_STATUS,
							    'DART6SchReportRequestWatcher.execute', dds.AdServer_Login__r.RecordType.name, e));
			if(sc.getTriggerID() != null ) System.abortJob(sc.getTriggerID());
		}
    }
}