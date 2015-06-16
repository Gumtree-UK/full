/*
**This class was used for "Improve SLA and case resolution tracking - GTCRM- 688"
*/

public with sharing class ClsCreateAccontNewEntitlement {

    /*
    **This method was used in case accounts were inserted. 
    **It will insert 2 Entitlements for each Account
    */  
    public static void create2EntitlementForEachAccount(List<Account> accounts){
        //store all new account ids created
        Set<Id> accountIds = new Set<Id>();
        for(Account account : accounts){
            accountIds.add(account.Id);
        }
        
        //attached 2 entitlements for each account created
        List<Entitlement> entitlements = new List<Entitlement>();
        for(Id accountId : accountIds){
            entitlements.add(new Entitlement(
                Name = 'SLA',
                //Status = 'Active',
                StartDate = System.today(),
                SlaProcessId = '552w00000004LAv',
                AccountId = accountId
            ));
            entitlements.add(new Entitlement(
                Name = 'Re-open SLA',
                //Status='Active',
                StartDate=System.today(),
                SlaProcessId = '552w00000004SRw',
                AccountId = accountId
            )); 
        }
        if(entitlements.size() > 0){
            Database.Saveresult[] saveResults = Database.insert(entitlements,false);
            handleErrorHandling(saveResults,entitlements,'AccountId','Entitlement');
        }   
    }
    /*
    **This method was used in case Cases were created. 
    **It will attached Entitlement from Account with Entitlement's Name equals SLA to Case
    */
    public static void attachEntitlementFromAccount2Case(List<Case> cases,String entitlementName){
        Map<Id,List<Case>> mAccountId_Entitlements = new Map<Id,List<Case>>();
        Set<Id> accountIds = new Set<Id>();
        for(Case caseObj : cases){
            if(caseObj.AccountId == null)continue;
            if(mAccountId_Entitlements.get(caseObj.AccountId) == null)
                mAccountId_Entitlements.put(caseObj.AccountId,new List<Case>());
            mAccountId_Entitlements.get(caseObj.AccountId).add(caseObj);
            accountIds.add(caseObj.AccountId);
        }
        List<Entitlement> lstEntitlement = [Select Name,AccountId From Entitlement Where AccountId in:accountIds
                                                AND Name=:entitlementName Order by LastModifiedDate desc];
        for(Entitlement entitlement : lstEntitlement){
            List<Case> lstCase = mAccountId_Entitlements.get(entitlement.AccountId);
            Case c = lstCase.get(0);
            c.EntitlementId = entitlement.Id;
        }
    }
    
    
    /*
    **Error log report should create automatically for each batch job run.
    */
    public static void handleErrorHandling(Database.Saveresult[] updateResults,List<SObject> lstSobj, String parentField,String objName){
        List<Note> notes = new List<Note>();
        for(Integer i=0; i<updateResults.size(); i++){
            if (!updateResults.get(i).isSuccess()){
                // DML operation failed
                Database.Error error = updateResults.get(i).getErrors().get(0);
                notes.add(new Note(Body = error.getMessage(),ParentId = lstSobj.get(i).get(parentField)+'',
                Title=objName));
            }
        }
        if(notes.size() > 0){
            insert notes;
        }
    }
    //GTCRM-1712 -Case milestones not accurate for SLA report
    public static void updateCaseSLAReport(List<Case> lstCase, boolean isBeforeInsert){
        
        for(Case c : lstCase){
            if((c.Status == 'Closed' || c.isClosed || c.Status == 'Survey Send' || c.Status == 'Response Sent') && c.Date_Time_Re_Opened__c != null && !isBeforeInsert){
                c.Reopen_SLAs_First_Response__c = true;
            }
            else if(c.Status == 'New (Re-Open)' && c.Date_Time_Re_Opened__c != null && !isBeforeInsert){
                c.Reopen_SLAs_First_Response__c = false;
            }
        }
        
    }
    

}