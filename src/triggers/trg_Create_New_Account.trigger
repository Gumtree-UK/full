trigger trg_Create_New_Account on Account (after insert,after update) {
    if(Trigger.isAfter){
        if(Trigger.isInsert){
            ClsCreateAccontNewEntitlement.create2EntitlementForEachAccount(Trigger.new);
        }else if(Trigger.isUpdate){
            Map<Id,Account> mAccountIds = new Map<Id,Account>();
            for(Account acc : Trigger.new){
                mAccountIds.put(acc.Id,acc);
            }
            //filter account without entitlement
            List<Account> lstAccount = new List<Account>();
            for(Account acc : [Select Id,(Select Id From Entitlements) From Account where Id in:mAccountIds.keyset()]){
                if(acc.Entitlements.size() == 0){
                    lstAccount.add(mAccountIds.get(acc.Id));
                }
            }
            if(lstAccount.size() > 0){
                ClsCreateAccontNewEntitlement.create2EntitlementForEachAccount(lstAccount); 
            }
        }
    }
    
}