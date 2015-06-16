/*
* Batch run daily at midnight to check Product End Date equals current day (schedule run on 11PM)
* @createdDate: 10-May-2013 
* @author:      Sopha Pum
* Chang log: 
        Description     :   IF (Payment_Method__c = Credit Card
                            THEN Update Payment_Method__c = Invoice
                            
                            IF (Billing_Frequency__c = One Invoice
                            THEN Update Payment_Method__c = Monthly in arrears
        modified date   : GTCRM-1046 - 23/06/2014
        author          : SUY Sreymol
        
        GTCRM-1320 - Auto-renew taking place on suspended accounts
         
   - SP - 23-Feb-2015 : added logic track batch process
            
 */   
global class BatchAutoRenewal implements Database.Batchable<sObject>,Database.AllowsCallouts  {  
    public static boolean fromBatch=false; 
    private final String STAGE_NAME = 'Booking (Auto-renewal)';
    private final String BILLING_FREQUENCY = 'Monthly in arrears';
    private final String PAYMENT_METHOD = 'Invoice';
    private final String STAGE_NAME_TO_CHECK = 'Booking';
    private final String ITEM_STAGE = 'cancelled';
    private final String BILLING_FREQUENCY_FIRST_RENEW = 'One Invoice';
    private final String PAYMENT_METHOD_FIRST_RENEW = 'Credit/Debit Card';
    // GTCRM-1320 - Auto-renew taking place on suspended accounts
    private final String ACCOUNT_STATUS = 'Active';
    
    private String opliId;
    // GTCRM-1320 - Auto-renew taking place on suspended accounts
    private String query = 'Select until_Date__c, Id, Revenue2__c, Net__c, Length_months__c '+
                            'From OpportunityLineItem '+
                            'Where PricebookEntry.Product2.Auto_renewal__c = true '+
                                'AND status__c !=:ITEM_STAGE '+
                                'AND (Opportunity.StageName =:STAGE_NAME_TO_CHECK OR Opportunity.StageName =:STAGE_NAME) '+
                                'AND until_Date__c = TODAY '+
                                'AND Net_Net_Net__c > 0 '+
                                'AND Opportunity.Account.Account_Status__c = :ACCOUNT_STATUS';
    //private String query = 'Select until_Date__c, Id, Revenue2__c, Net__c, Length_months__c From OpportunityLineItem Where PricebookEntry.Product2.Auto_renewal__c = true AND status__c !=:ITEM_STAGE AND (Opportunity.StageName =:STAGE_NAME_TO_CHECK OR Opportunity.StageName =:STAGE_NAME) AND until_Date__c = TODAY AND Net_Net_Net__c > 0';
    //private String query = 'Select until_Date__c, Id, Revenue2__c, Net__c, Length_months__c From OpportunityLineItem Where PricebookEntry.Product2.Auto_renewal__c = true AND status__c !=:ITEM_STAGE AND (Opportunity.StageName =:STAGE_NAME_TO_CHECK OR Opportunity.StageName =:STAGE_NAME) AND until_Date__c = TODAY';
    //private String query = 'Select until_Date__c, Id, Revenue__c, Net__c, Length_months__c From OpportunityLineItem Where PricebookEntry.Product2.Auto_renewal__c = true AND status__c !=:ITEM_STAGE AND (Opportunity.StageName =:STAGE_NAME_TO_CHECK OR Opportunity.StageName =:STAGE_NAME) AND (until_Date__c >= N_DAYS_AGO:6 AND until_Date__c < N_DAYS_AGO:4)';
    //for test 
    public BatchAutoRenewal(String opliId){
        this.opliId = opliId;
    } 
    
    public BatchAutoRenewal(){      
    } 
    
    global Database.QueryLocator start(Database.BatchableContext BC){
        String conditionTest = ' And id =: opliId';
        system.debug('conditionTest:::>>>>>>>>>>' + query + conditionTest);
        
        createErrorLog(BC.getJobId());
        
        return Database.getQueryLocator(query + (opliId == null ? '' : conditionTest));
    }
    
    global void execute(Database.BatchableContext BC, List<OpportunityLineItem> scope){
        system.debug('scope:::>>>>>>>>'+scope.size());
        createErrorLog(BC.getJobId());
        
        Set<ID> revenueIds = new Set<ID>();
        List<Revenue_Schedule2__c> lstRS2Update = new List<Revenue_Schedule2__c>();
        //List<Opportunity> lstOpp2UpdateStage = new List<Opportunity>(); 
        Map<String,Opportunity> mOpp2UpdateStage = new Map<String,Opportunity>(); //NK:31/05/2013: replace list above to fix duplicate oppid in the list
        system.debug('>>>>>>>>'+scope.size());
        //When the current date equals the product end date, exactly one month should be added to the end date.
        for(OpportunityLineItem opli: scope){  
            Date cur_untilDate = opli.until_Date__c;
            Decimal months = (opli.Length_months__c == null ? 0: opli.Length_months__c);
         
            
         // Decimal RenewAmount =  (months == 0? 0: ((opli.Net__c)/months));
            
        //  opli.Auto_Renewal_Amount__c = (opli.Auto_Renewal_Amount__c == null?0: opli.Auto_Renewal_Amount__c ) + RenewAmount;
            opli.until_Date__c = cur_untilDate.addMonths(1);
            
            // Bunhor @06-Jan-14: new inserting RS price will be token from Rate Card of 3 Months Products
            Revenue.mapRevId2IsRCprice.put(opli.Revenue2__c, true);
            
            opli.Length_months__c = months + 1;
            opli.AwaitForTriggerProcess__c = true;
            system.debug('=============opli=='+opli);   
            revenueIds.add(opli.Revenue2__c);
        }
        
        if(!scope.isEmpty()){
            fromBatch=true; 
            update scope; 
        }
        system.debug('fromBatch:>>>>>>>>>>>' + fromBatch);
        system.debug('revenueIds:>>>>>>>>>>>' + revenueIds);
        //create 1 additional revenue schedule with the same monthly amount as the last revenue schedule
        for(Revenue2__c revenue: [Select Id, Opportunity__c, Opportunity__r.StageName, Opportunity__r.BillingFrequency__c, Opportunity__r.Payment_Method__c, (Select Revenue2__c, Product__c,   Month__c, Auto_renew_month__c From Revenue_Schedules2__r order by Month__c DESC limit 1) From Revenue2__c Where Id in: revenueIds]){
            system.debug('empty RS:>>>>>>>>>>>' + revenue.Revenue_Schedules2__r.isEmpty());
            //If it hasn't any RS, go next record
            if(revenue.Revenue_Schedules2__r.isEmpty()) continue;
            
            Revenue_Schedule2__c rs = revenue.Revenue_Schedules2__r.get(0);
            rs.Auto_renew_month__c = true; //For every new RS record added using this logic, the checkbox �auto-renew month� needs to be set on the RS record
            lstRS2Update.add(rs);
            
            //When an auto-renewal takes place (an extra revenue schedule is created), the stage of the opportunity should be changed to �Booking (Auto-renewal)�                                           
            //lstOpp2UpdateStage.add(new Opportunity(Id = revenue.Opportunity__c,
            //                                      StageName = STAGE_NAME));
            
            //NK:31/05/2013: replace list above to fix duplicate oppid in the list
            
            If (revenue.Opportunity__c != null) {
                // SUY Sreymol - 23/06/2014 - #3242:note#76-When first auto renew takes place we should check and update the following fields accordingly
                if (revenue.Opportunity__r.StageName != STAGE_NAME) {
                    String billFreq;
                    String paymentMethod;
                    billFreq = (revenue.Opportunity__r.BillingFrequency__c == BILLING_FREQUENCY_FIRST_RENEW) ? BILLING_FREQUENCY : revenue.Opportunity__r.BillingFrequency__c;
                    paymentMethod = (revenue.Opportunity__r.Payment_Method__c == PAYMENT_METHOD_FIRST_RENEW) ? PAYMENT_METHOD : revenue.Opportunity__r.Payment_Method__c;
                    mOpp2UpdateStage.put(revenue.Opportunity__c, new Opportunity(Id = revenue.Opportunity__c,
                                                    StageName = STAGE_NAME, BillingFrequency__c = billFreq, Payment_Method__c = paymentMethod));
                } else {
                //---------------23/06/2014-----------------------//
                    mOpp2UpdateStage.put(revenue.Opportunity__c, new Opportunity(Id = revenue.Opportunity__c,
                                                    StageName = STAGE_NAME, BillingFrequency__c = BILLING_FREQUENCY, Payment_Method__c = PAYMENT_METHOD ));
                }
            }   
        }
        
        system.debug('lstRS2Update:::>>>>>>>>>>' + lstRS2Update);
        if(!lstRS2Update.isEmpty()){  
            update lstRS2Update; 
        } 
        
        //NK:31/05/2013: replace list above to fix duplicate oppid in the list
        //if(!lstOpp2UpdateStage.isEmpty()){
        system.debug('mOpp2UpdateStage:::>>>>>>>>>>' + mOpp2UpdateStage);
        if(!mOpp2UpdateStage.isEmpty()){
            update mOpp2UpdateStage.values();
        }
        
    }
    
    global void finish(Database.BatchableContext BC){
        createErrorLog(BC.getJobId());
        
        //process the trigger logic, that we skipped from the trigger to prevent future called from batch
        BatchOpliTriggerLogic batchopli = new BatchOpliTriggerLogic();
        batchopli.isBatchAutoRenewal = true;  // Bunhor @15-Jan-15: this is from BatchAutoRenewal 
        Database.executeBatch(batchopli,1); // batch size 1 to prevent uncommitted when callout in loop
    } 
    
    /**
    * Method create error log to track process
    * @createdDate: 23-Feb-2015
    * @author: SP
    */
    public static void createErrorLog(ID jobId){
        
        AsyncApexJob a = [Select Id, Status, ExtendedStatus From AsyncApexJob Where Id=: jobId];
        System.debug('===================a4=' + a);
        List<ErrorLog__c> lstErrLog = [Select Id, Related_Id__c, Status__c, details__c From ErrorLog__c Where Related_Id__c =: a.Id limit 1];
        
        ErrorLog__c nErr = new ErrorLog__c();
        if(!lstErrLog.isEmpty()){
            nErr = lstErrLog.get(0);
        }        
        nErr.Status__c = a.Status;
        nErr.Related_Id__c = a.Id;
        nErr.details__c = a.ExtendedStatus;
        upsert nErr;
    }
    
    /** For test Only **/
    webservice static void executeBatch(String opliId){
        BatchAutoRenewal batch = new BatchAutoRenewal(opliId);
        ID batchprocessid = Database.executeBatch(batch);
        createErrorLog(batchprocessid);
        
    }
}