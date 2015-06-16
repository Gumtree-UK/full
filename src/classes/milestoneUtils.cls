/***
*
*@Author : Tom Veasna
*@Date : 07/03/2014
*@Business :
*Improve SLA and case Resolution Tracking - GTCRM- 688
* invoked from Trigger - completeResolutionTimeMilestone
*
*@Revision :
*
*/
public class milestoneUtils {
    public static Boolean doAction = true;
    public static Boolean callFromFuture = false;
    
    @future
    public static void completeMilestone(Set<Id> caseIds, DateTime complDate) {
        callFromFuture = true;
        completeMilestone2(caseIds,complDate);        
    }
    
   public static void completeMilestone1(Set<Id> caseIds, DateTime complDate) {
    
        completeMilestone2(caseIds,complDate);
         //in case was renewed, so it will create new case milestone in next session, so we used future to update case.TargetDate__c
         if (callFromFuture) { callFromFuture = false;}
         else {
            completeMilestone(caseIds,complDate);
          }
    }
     
    public static void completeMilestone2(Set<Id> caseIds, DateTime complDate){
        
        Map<Id,Case> mIdCase  = new Map<Id,Case>([Select Id,Reason,isClosed,Closed_Reason__c,RecordTypeId ,Status,SlaStartDate,SlaExitDate,TargetDate__c from Case where Id in:caseIds]);
        
        List<CaseMilestone> cmsToUpdate = [select Id, completionDate,caseId,case.Startdate__c,TargetDate
                           from CaseMilestone cm
                           where caseId in :caseIds order by caseId,createddate];
        System.debug('>>>>>>>>cmsToUpdate: '+cmsToUpdate); 
        
       
               
        //update casemilestone               
        if (!cmsToUpdate.isEmpty()){
        
            for (CaseMilestone cm : cmsToUpdate){
                
                Case c = mIdCase.get(cm.caseId);
                
                if (((c.isClosed)||(c.Status == 'Closed'))&&((c.SlaStartDate <= complDate)&&(c.SlaExitDate == null))){
                    cm.completionDate = complDate;
               
                }
                if(c.Status == 'Closed' && c.Closed_Reason__c!='Live Chat' && (c.RecordTypeId =='012g00000004btk' || c.RecordTypeId =='01220000000Q9DR' || c.RecordTypeId =='01220000000Dn8v' || c.RecordTypeId =='012w0000000QN48')) {
                   c.Closed_Reason__c=c.Reason ;
                     
             }
                                              
     c.TargetDate__c = cm.TargetDate;
              
                
            }
           
            Database.Saveresult[] updateResults = Database.update(cmsToUpdate,false);
            doAction = false;
           
            Database.Saveresult[] updatecaseResults = Database.update(mIdCase.values(),false);
           
            //delete all job records for jobs that have finished before today’s date. 
            Integer count = System.purgeOldAsyncJobs(Date.today());
            System.debug('Deleted ' +count + ' old jobs.');
          
        }                   
    }
  
 }