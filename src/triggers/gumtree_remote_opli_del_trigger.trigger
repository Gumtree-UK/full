/*

Change log:
- GTCRM-369 - Fixed Modify product large opportunity "Too many SOQL queries"  (HCS - 26.09.2013)

*/

trigger gumtree_remote_opli_del_trigger on OpportunityLineItem (after delete) {   

     Set<String> setOppId = new Set<String>();
     Set<String> setAccountId = new Set<String>();
     for (OpportunityLineItem oli : Trigger.old) {
        if(oli.OpportunityId == null ) continue;
        setOppId.add(oli.OpportunityId);
     }
    Map<String,Opportunity> mapOpp = new  Map<String,Opportunity>([select ID, AccountID, StageName from Opportunity where id In: setOppId ]);
    for(Opportunity opp: mapOpp.values()){
        if( opp.AccountId== null ) continue;
        setAccountId.add(opp.AccountId);
    }
     Map<String,Account> mapAccount = new Map<String,Account>([select Id, AccountNumber from Account where id In :setAccountId]);    
    for (OpportunityLineItem oli : Trigger.old) { 
        //Opportunity op = [select ID, AccountID, StageName from Opportunity where id = :oli.OpportunityId];
        Opportunity op = mapOpp.get(oli.OpportunityId);
       // Account acc = [select Id, AccountNumber from Account where id = :op.AccountId];
         Account acc = mapAccount.get(op.AccountId);     
        if (acc.AccountNumber != null && acc.AccountNumber != '' && String.valueOf(oli.id) != '') {
            GumtreeUtilsInterface utils = GumtreeUtils.getGumtreeUtilsInterface();
            utils.remote(acc.AccountNumber).deletePackage( String.valueOf(oli.id) );
        }   
    }

}