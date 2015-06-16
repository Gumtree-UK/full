trigger finance_contact_after_update on Contact (after update) {
 
	
    Integer i = 0;
    for (Contact c : Trigger.new) {
        if (c.FirstName != Trigger.old[i].FirstName
            || c.LastName != Trigger.old[i].LastName
            || c.Email != Trigger.old[i].Email
            || c.Phone != Trigger.old[i].Phone) {
            
            for (Account acc : [SELECT id, name, UpdateAccount__c, Fiqas_Account_Synced__c
                                FROM Account 
                                WHERE Finance_contact__r.id = :c.id
                                OR Primary_contact__r.id = :c.id]) {
                System.debug('Updating account: '+acc.name);
                acc.Fiqas_Account_Synced__c = 'CONTACTRESYNC';                
                
                if (acc.UpdateAccount__c != null)
                    acc.UpdateAccount__c = acc.UpdateAccount__c + 1;
                else
                    acc.UpdateAccount__c = 1;
                    
                update acc;
                
            }
        }
        i++;
    }

}