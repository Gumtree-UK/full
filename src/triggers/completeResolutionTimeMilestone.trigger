/***
*
*@Author : Tom Veasna
*@Date : 07/03/2014
*@Business :
*@See : milestoneUtils
*
*/
trigger completeResolutionTimeMilestone on Case (after insert,after update,before insert) {
	 
	
    if(Trigger.isAfter){
        System.debug('>>>>>>doAction: '+milestoneUtils.doAction);
        if(!milestoneUtils.doAction){
            milestoneUtils.doAction = true;
            return;
        }
        Set<Id> caseIds = new Set<Id>();
        for(Case c : Trigger.new){
            caseIds.add(c.Id);
        }
        if(Trigger.isUpdate){
            
           
            milestoneUtils.completeMilestone1(caseIds, System.now()); 
            
        }else{ // after insert
        	 // Future invokation is used, because the Milestone is created by SFDC after 
        		if (!Test.isRunningTest()) {
            		milestoneUtils.completeMilestone(caseIds, System.now()); 
        		}
        	
        }
    }else{ // before insert, set default account
    	
    	// account GT Help Account
		String accountIdForNewContacts =  CustomSettingsManager.getConfigSettingStringVal(CustomSettingsManager.GT_HELP_ACCOUNT_ID);
	  
        for(Case c : Trigger.new){
            if(c.AccountId == null){
                c.AccountId = accountIdForNewContacts;
            }
        }
    }
   
}