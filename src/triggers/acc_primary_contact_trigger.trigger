trigger acc_primary_contact_trigger on Account (before update) {

    Integer i = 0;
    for (Account acc : Trigger.new) {
        if (acc.RecordTypeId == '01220000000Disx' || acc.RecordTypeId == '012200000005MbL'
         || acc.RecordTypeId == '01220000000DqON' || acc.RecordTypeId == '01220000000YDMy'
         || acc.RecordTypeId == '012W00000004LZA' || acc.RecordTypeId == '012200000002Lwv'
         || acc.RecordTypeId == '012200000002LlM' || acc.RecordTypeId == '012W00000004QtZ'
         || acc.RecordTypeId == '01220000000Q8xS' || acc.RecordTypeId == '012w0000000QA3A') {
            
            if (acc.Primary_contact__c == null) {
                String contactId = GumtreeAccountHandler.getSuitablePrimaryContact(acc);
                if (contactId != null) {
                    acc.Primary_contact__c = contactId;
                } else {
                    acc.addError('Account needs a primary contact set');                    
                }
            } else {
            	// primary contact is set, check we aren't overwriting account number
                if ((acc.AccountNumber == '' || acc.AccountNumber == null)
                        && Trigger.old[i].AccountNumber != '') {
                    acc.AccountNumber = Trigger.old[i].AccountNumber;   
                }   
            }
        }
        i++;
    }

}