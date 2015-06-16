/* Thomas Ward august 2011
**
** Custom error log to display interface errors to administrators
** - eventually we want to store errors sent from interface partners also
**
Change log:
- 2015-04-21 - GTCRM-1945 - API send issue with DD Mandates (improve ErrorLog creation) BY PNC
- 2015-04-29 - GTCRM-1924 - Adding createErrorLog and createErrorRecordDetails(overrided) and Modified methods BY BUNHOR 
- 2015-05-06 - GTCRM-1924 - Adding lstCalloutLog, keepLog() and saveLogs(): avoiding "System.CalloutException: You have uncommitted work pending. Please commit or rollback before calling out" BY BUNHOR 
*/
 
global class futureCreateErrorLog {
    /**keep ErrorLog__c records creating, it will be inserted without CalloutException.*/
    private static ErrorLog__c[] lstCalloutLog = new List<ErrorLog__c>();
    
    private static String getApexJob(){
        String jobSep = ';';
        String job = ''; 
        job += System.isBatch() ? jobSep + 'Batch Apex' : '' ;
        job += System.isFuture() ? jobSep + 'Future' : '' ;
        job += System.isScheduled() ? jobSep + 'Scheduled Apex' : '' ;
        return job.replaceFirst(jobSep, '');
    }
    
    public static void createErrorRecordDetails(string exceptionMessage, string Id, string Origin, String action, String result, String status){
        ErrorLog__c newErrorRecord = createErrorLog(exceptionMessage, Id, Origin, action, result, status, null);
        Database.insert(newErrorRecord,false);
    }
    
    public static void createErrorRecordDetails(string exceptionMessage, string Id, string Origin, String action, String result, String status, String integration){
        ErrorLog__c newErrorRecord = createErrorLog(exceptionMessage, Id, Origin, action, result, status, integration);
        Database.insert(newErrorRecord,false);
    }
    
    /** 
     * Creating ErrorLog__c records and add to lstCalloutLog so that saveLogs() can insert records later.
     * @Author : Bunhor 
     * @CreatedDate : 06-May-15
     */
    public static void keepLog(string exceptionMessage, string Id, string Origin, String action, String result, String status, String integration){
    	lstCalloutLog.add(createErrorLog(exceptionMessage, Id, Origin, action, result, status, integration));
    }
     
    /** 
     * This will be used to insert ErrorLog__c records, created from keepLog, out side loop or after other callouts.
     * @Author : Bunhor 
     * @CreatedDate : 06-May-15
     */ 
    public static void saveLogs(){
    	Database.insert(lstCalloutLog,false);
    }
     
    /** 
     * Creating an ErrorLog__c record 
     * @Author : Bunhor 
     * @CreatedDate : 29-Apr-15
     */  
    public static ErrorLog__c createErrorLog(string exceptionMessage, string Id, string Origin, String action, String result, String status, String integration){
        ErrorLog__c newErrorRecord = new ErrorLog__c();
        newErrorRecord.details__c = exceptionMessage;
        newErrorRecord.Related_Id__c = Id;
        newErrorRecord.Type__c = Origin;
        newErrorRecord.Action__c = action;
        newErrorRecord.Result__c = result;
        newErrorRecord.Apex_Job__c = getApexJob();
        newErrorRecord.Status__c = status;
        newErrorRecord.Integration__c = integration;
        return newErrorRecord;
    }
     
    public static void createErrorRecord(string exceptionMessage, string Id, string Origin){
        ErrorLog__c newErrorRecord = createErrorLog(exceptionMessage, Id, Origin, null, null, null, null);
        Database.insert(newErrorRecord,false);
        // system.debug('######errorloginsert'  + exceptionMessage + Id + Origin);
    }

    @future     
    public static void createFutureErrorRecord(string exceptionMessage, string Id, string Origin){ 
        createErrorRecord(exceptionMessage, Id, Origin);
    }     
     
    public static testMethod void testBatch() {
        string error = 'Testing 123';
        string Id = '111' ;  
        string Origin = 'test';                              
        test.startTest();                                
        futureCreateErrorLog.createErrorRecord(error, Id, Origin);
        futureCreateErrorLog.createFutureErrorRecord(error, Id, Origin);
        futureCreateErrorLog.createErrorRecordDetails(error, Id, Origin, 'Create', 'OK', 'Completed');
        futureCreateErrorLog.createErrorRecordDetails(error, Id, Origin, 'Create', 'OK', 'Completed', null);
        test.stopTest();
    }
}