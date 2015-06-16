trigger opencasescountoncontact on Case (after insert, after update,after delete) {
	
	 
    Set<Id> caseIds;
    if(trigger.isDelete) caseIds = trigger.oldmap.keyset();
    else caseIds = trigger.newmap.keyset();
    List<Case> lstCase = [select id, ContactId from Case where id in: caseIds];
    set<Id> sConId = new set<Id>();
    for(Case cs: lstCase){
        if(cs.ContactId != null){
            sConId.add(cs.ContactId);
        }
    }
    if(sConId != null && sConId.size() > 0){

//        List<Contact> lstContact = [select id, Case_Count__c, (select id from Cases where status = 'New') from Contact where id in: sConId];
        List<Contact> lstContact = [select id, Open_CasesCount__c, (select id from Cases where IsClosed = False) from Contact where id in: sConId];
        if(lstContact.size() > 0){
            for(Contact con: lstContact){
               con.Open_CasesCount__c = con.Cases.size();
            }
            
            update lstContact;
        }
    }
}