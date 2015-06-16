/* 
 * CRMWaypoint, November 2011
 * This class schelues running of Clone opportunity for renewal
 *
 *@Revision : SPP - 15/08/2014
 * issue with the renewal  and the approval process.
 *
 * We do the approval process when done is completed.
 *
 
 Change log;
 - 2015-04-20 - GTCRM-1757 - Motors Auto Create - Incorrect Opportunities created - Do not create if opp total = 0
 
 */
 
global with sharing class CloneOpportunityScheduler_GT implements Schedulable {

    /*
    
  A schedule class run every day, it will look at the following criteria.
•   IF OPP.Campaign_End__c = OPP.Account.Max_Campaign_End_Date__c
•   AND OPP.IsWon = True
•   AND OPP.StageName  <> ‘Booking (Cancelled)’
•   AND OPP.Auto_Date_To_Renew__c = Today()
•   AND OPP.AutoRecordtypesforopprenewal__c=TRUE

    
    */


   global void execute(SchedulableContext SC) {
    
        List<String> oppIdList = new list<String> ();
        List<Opportunity> oppToRenewList = [SELECT id, Name, RecordTypeId, RecordType.DeveloperName,Campaign_End__c, Account.Max_Campaign_End_Date__c, Account.Id, Net_Net__c
                                            FROM Opportunity
                                            WHERE StageName <> 'Booking (Cancelled)'
                                            AND IsWon = true
                                            AND Auto_Date_To_Renew__c = TODAY
                                            AND AutoRecordtypesforopprenewal__c='TRUE'
                                            AND RecordType.DeveloperName in ('Display_Campaign_Delivery','Campaign_Delivery_H','Campaign_Delivery','Campaign_Delivery_M')
                                            //  2015-04-20 - GTCRM-1757 - Motors Auto Create - Incorrect Opportunities created - Do not create if opp total = 0
                                            AND Net_Net__c > 0
                                            ];
                                            

        for (Opportunity opp: oppToRenewList){
        
            if (opp.Campaign_End__c==opp.Account.Max_Campaign_End_Date__c) {
                oppIdList.add(opp.id);
                
            }
        }
         
         
        if (!oppIdList.isEmpty()){
            
            try {
                // clone
                List<Opportunity> newOppIds = CloneOpportunity_GT.doCloneOpp(oppIdList, true);
                
                Map<String,Id> recTypes = Utils.loadOppRecordType();
                
                // start the renewal
                List<Opportunity> opps = new List<Opportunity>();
                for(Opportunity opp : newOppIds){
                    
                        
                    if(recTypes.get('Sales_Management_M').equals(opp.RecordTypeId)  || (recTypes.get('Sales_Management_H').equals(opp.RecordTypeId))){
                        opps.add(opp);
                    }
                }
                
                if(opps.size() > 0){ 
                
                    System.debug('>>>>>>> CloneOpportunityScheduler_GT Opp renewal ' + opps);
                    Set<Id> oppIds = CloneOpportunity_GT.sendApproval(opps);
                    
                    
                
                    if (!Test.isRunningTest()) {
                        if(!BatchApexLimitCheck.isHittingLimit()){
                            // generate agreement only opp approved 
                            Id batchEchoSignId = Database.executeBatch(new EchoSignServicesBatch(oppIds,Userinfo.getSessionId()), 1); 
                        }
                    }
                }
                
                
            }
            catch (CloneOpportunity_GT.RenewalCloneException ex) {
                
                futureCreateErrorLog.createErrorRecord(ex.getMessage(), 'opportunityRenew', 'opportunityRenew');
            }
            
        }
        else {
            System.debug('>>>>>>No Opportunity to be renewd.');
            futureCreateErrorLog.createErrorRecord('No opportunities to renew', 'opportunityRenew', 'opportunityRenew');
        }
                                                                              
    }
}