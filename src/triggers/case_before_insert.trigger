trigger case_before_insert on Case (before insert,before update) {
	
    if (Trigger.isBefore && Trigger.isInsert)
    {
        SF_Gumtree_SOW_001 handler = new SF_Gumtree_SOW_001();
        handler.handleCaseBeforeInserts(Trigger.new);
        KnowledgeController.updateCaseUserSource(trigger.new);
        System.debug('>>>>>>>before insert case.case.Account: '+Trigger.new.get(0).AccountId);
        ClsCreateAccontNewEntitlement.attachEntitlementFromAccount2Case(Trigger.new,'SLA');
        ClsCreateAccontNewEntitlement.updateCaseSLAReport(trigger.new, true);
    }else if(Trigger.isBefore && Trigger.isUpdate){
        List<Case> cases2beUpdate = new List<Case>();
        List<Case> case2beUpdate1 = new List<Case>();//in case when create new case without Account and update with an Account
        for(Integer i=0;i<Trigger.new.size();i++){
            if('New (Re-Open)'.Equals(Trigger.new.get(i).Status) &&
                !'New (Re-Open)'.Equals(Trigger.old.get(i).Status)){
                cases2beUpdate.add(Trigger.new.get(i));     
            }else if(Trigger.old.get(i).AccountId == null && Trigger.new.get(i).AccountId != null){
                case2beUpdate1.add(Trigger.new.get(i));
            }
        }
        System.debug('>>>>>>>after update case.case.Account: '+Trigger.new.get(0).AccountId);
        if(cases2beUpdate.size() > 0)
           ClsCreateAccontNewEntitlement.attachEntitlementFromAccount2Case(cases2beUpdate,'Re-open SLA');
            
        if(case2beUpdate1.size() > 0){
            ClsCreateAccontNewEntitlement.attachEntitlementFromAccount2Case(case2beUpdate1,'SLA');
        }
        ClsCreateAccontNewEntitlement.updateCaseSLAReport(trigger.new, false);  
    }
    
}