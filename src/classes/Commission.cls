/**

Change log:
- 2014-01-29 - GTCRM-679 - Housing TSNB commission plan
- 2014-04-16 - GTCRM-920 - Ability to adjust final commission payable amount
- 2014-04-22 - GTCRM-922 - Ability to create spot awards for AWF
- 2014-04-28 - GTCRM-931 - Corporate Display new starter commission plan
- 2014-09-04 - Update test class due to deployment issue

**/

public without sharing class Commission {

public static void setAnnualRate (List<Commission2__c> triggerNew, List<Commission2__c> triggerOld, Map<Id, Commission2__c> triggerOldMap, Boolean isBefore, Boolean isInsert, Boolean isUpdate, Boolean isDelete, Boolean isUnDelete) {

        if (isInsert) {
            for (Commission2__c com: triggerNew) {
                    
                    com.Annual_Rate__c = com.Profile__r.Current_Rate__c; 
                    com.of_rate_as_OTE__c = com.Profile__r.Current_Rate_OTE__c;
                     
                  }
        }
}

  public static void setCommissionPayable (List<Commission2__c> triggerNew, List<Commission2__c> triggerOld, Map<Id, Commission2__c> triggerOldMap, Boolean isBefore, Boolean isInsert, Boolean isUpdate, Boolean isDelete, Boolean isUnDelete) {

        if (isBefore && (isInsert || isUpdate)) {
            for (Commission2__c com: triggerNew) {
                    
                    // - GTCRM-931 - Corporate Display new starter commission plan                   
                    if (com.RecordTypeId == '012w0000000QDyf' && com.Total_Score__c < 100  ) {
                       com.Commission_payable__c = 0 + com.Commission_Adjusted__c;
                       }
                    
                    if (com.RecordTypeId == '012w0000000QDyf' && com.Total_Score__c >= 100  ) {
                       com.Commission_payable__c = (com.Sales_Actual__c * 0.10) + com.Commission_Adjusted__c;
                       }
                                       
                    if (com.RecordTypeId == '012w0000000QDyf' && com.Total_Score__c > 200  ) {   // cap commission plan at 200% of target
                       com.Commission_payable__c = ((com.Sales_Target__c * 2) * 0.10) + com.Commission_Adjusted__c;
                       }
                       
                    // - GTCRM-922 - Ability to create spot awards for AWF
                    if (com.RecordTypeId == '012w0000000QDyg' ) {
                         com.Commission_payable__c = com.Award_amount__c + com.Commission_Adjusted__c;
                       }
                    
                    // - GTCRM-679 - Housing TSNB commission plan       
                    // Booked Revenue - Housing TSNB
                    if (com.RecordTypeId == '012w0000000QCNh' ) {
                       com.Commission_payable__c = (com.Commission_before_multiplier__c * com.Commission_multiplier__c / 100 * com.Subscription_multiplier__c / 100) + com.Commission_Adjusted__c;
                       }
                       
                    // Booked Revenue - Jobs TSNB 
                    if (com.RecordTypeId == '01220000000Q7za' ) {
                         com.Commission_payable__c = (com.Commission_before_multiplier__c * com.Commission_multiplier__c / 100) + com.Commission_Adjusted__c;
                       }

                    // Delivered Revenue
                    else if (com.RecordTypeId == '01220000000Q7zk'){
                        com.Sales_Target__c = (com.Item_1_Metric_Target__c + com.Item_2_Metric_Target__c + com.Item_3_Metric_Target__c + com.Item_4_Metric_Target__c + com.Item_5_Metric_Target__c);
//                        com.Sales_Actual__c = (com.Item_1_Metric_Actual__c + com.Item_2_Metric_Actual__c + com.Item_3_Metric_Actual__c + com.Item_4_Metric_Actual__c + com.Item_5_Metric_Actual__c + com.Sales_Adjusted__c);
                        com.Sales_Actual__c = (com.Item_1_Metric_Actual__c + com.Item_2_Metric_Actual__c + com.Item_3_Metric_Actual__c + com.Item_4_Metric_Actual__c + com.Item_5_Metric_Actual__c);

                    if(com.Total_Score__c < 85) {
                        com.Commission_payable__c = 0 + com.Commission_Adjusted__c;  
                       } 
                    else if(com.Total_Score__c > 85 && com.Total_Score__c < 100) {
                       com.Commission_payable__c = ((com.Period_Rate__c * com.Variable_bonus_85__c) * (com.Total_Score__c - 85) / 100)
                                                   + com.Commission_Adjusted__c;
                       }                                     
                    else if(com.Total_Score__c >= 100 && com.Total_Score__c < 120) {
                       com.Commission_payable__c = ((com.Period_Rate__c * com.Variable_bonus_85__c) * (100 - 85) / 100 +
                                                   (com.Period_Rate__c * com.Variable_bonus_100__c) * (com.Total_Score__c - 100) / 100)
                                                   + com.Commission_Adjusted__c;
                       }                                 
                    else if(com.Total_Score__c >= 120) {
                       com.Commission_payable__c = ((com.Period_Rate__c * com.Variable_bonus_85__c) * (100 - 85) / 100 +
                                                   (com.Period_Rate__c * com.Variable_bonus_100__c) * (120 - 100) / 100 +
                                                   (com.Period_Rate__c * com.Variable_bonus_120__c) * (com.Total_Score__c - 120) / 100)
                                                    + com.Commission_Adjusted__c;
                       }     
                    else if(com.Total_Score__c >= 140) {
                       com.Commission_payable__c = ((com.Period_Rate__c * com.Variable_bonus_85__c) * (100 - 85) / 100 +
                                                   (com.Period_Rate__c * com.Variable_bonus_100__c) * (120 - 100) / 100 +
                                                   (com.Period_Rate__c * com.Variable_bonus_120__c) * (140 - 120) / 100)
                                                   + com.Commission_Adjusted__c;
                       }
                       
                     else if(com.Total_Score__c >= 200) {
                        com.Commission_payable__c = ((com.Period_Rate__c * com.Variable_bonus_85__c) * (100 - 85) / 100 +
                                                    (com.Period_Rate__c * com.Variable_bonus_100__c) * (120 - 100) / 100 +
                                                    (com.Period_Rate__c * com.Variable_bonus_120__c) * (200 - 120) / 100)
                                                    + com.Commission_Adjusted__c;
                       }                             
                        
            }
        }
  }
}

  public static void setCommissionApproval (List<Commission2__c> triggerNew, List<Commission2__c> triggerOld, Map<Id, Commission2__c> triggerOldMap, Boolean isBefore, Boolean isInsert, Boolean isUpdate, Boolean isDelete, Boolean isUnDelete) {
/*
  for(Commission2__c cp: trigger.new){ 
     if(Trigger.isInsert && cp.Name == 'Pending')
     {
          genRequest(cp);
     }else if(Trigger.isUpdate)
     {
          Commission2__c oldcp = trigger.oldMap.get(cp.Id);
          if(cp.Commission_Status__c== 'Pending' && oldcp.Commission_Status__c <> 'Pending')
          {
                genRequest(cp);
          }
     }
  }
  //moved approval submission to a method to allow reusability
  public void genRequest(Commission2__c cp){
       Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
       req1.setComments('Submitting commission for approval.');
       req1.setObjectId(cp.id);
       Approval.ProcessResult result = Approval.process(req1); 
       System.assert(result.isSuccess());        
  
  }
*/
}

static testMethod void Commssion() {

// - 2014-09-04 - Update test class due to deployment issue
    User user = [select Id from User WHERE IsActive=true AND Profile.Name = 'System Administrator' LIMIT 1];
    
    SFDC_Profile__c pro = new SFDC_Profile__c(
        Name = 'Steven Paul',
        OwnerId = user.id);
    insert pro;
    
    Commission2__c com = new Commission2__c(
        Profile__c = pro.id,
        Variable_bonus_85__c = 0.022,
        Variable_bonus_100__c = 0.012,
        Variable_bonus_120__c = 0.005,
        Sales_Target__c = 1000,
        Sales_Actual__c = 900,
        Sales_Adjusted__c = 0,
        Commission_Adjusted__c = 0,
        Item_1_Metric_Target__c = 10000,
        Item_1_Metric_Actual__c = 9000,
        Item_1_Weighting__c = 0.50,
        Item_2_Metric_Target__c = 45,
        Item_2_Metric_Actual__c = 43,
        Item_2_Weighting__c = 0.15,
        Item_3_Metric_Target__c = 15,
        Item_3_Metric_Actual__c = 15,
        Item_3_Weighting__c = 0.15,
        Item_4_Metric_Target__c = 0,
        Item_4_Metric_Actual__c = 0,
        Item_4_Weighting__c = 0,
        Item_5_Metric_Target__c = 0,
        Item_5_Metric_Actual__c = 0,                
        Item_5_Weighting__c = 0
        );
    insert com;
}
}