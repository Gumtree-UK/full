trigger gumtree_remote_account_trigger on Account (after update) {
    
    Integer i = 0;
    for (Account acc : Trigger.new) {
    	if(acc.RecordTypeId == '012200000005MbL' || acc.RecordTypeId == '01220000000Disx' ||
                   acc.RecordTypeId == '01220000000DqON' || acc.RecordTypeId == '01220000000YDMy' ||
                   acc.RecordTypeId == '012200000002Lwv' || acc.RecordTypeId == '012200000002LlM' ||
                   acc.RecordTypeId == '01220000000Q8xS' || acc.RecordTypeId == '012w0000000QA3A' ||
                   acc.RecordTypeId == '012W00000004QtZ') {
                   	
                //new stuff   	
            	Account oldAccount = Trigger.old[i];
            	GumtreeAccountHandler handler = new GumtreeAccountHandler(oldAccount, acc);
            	handler.updateAccount();
            	
        	}
        i++;
        
    } // foreach Account
    
} // trigger