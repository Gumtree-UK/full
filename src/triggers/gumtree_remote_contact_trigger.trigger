/**
*
*@Revision : 
* Trigger to update info in gumtree system (remote)
* it is only for business account with account number, so we need additional condition to avoid trigger to fire all the time
* We try to handle the future call to avoid sfdc limitation
*
*/
trigger gumtree_remote_contact_trigger on Contact (after insert, after update) {
 
		// account GT Help Account
		String accountIdForNewContacts =  CustomSettingsManager.getConfigSettingStringVal(CustomSettingsManager.GT_HELP_ACCOUNT_ID);
	      
		for(Contact newContact : Trigger.new) {
			// we bypass GT Gumtree Help Account	
			String accountid = newContact.AccountId;
			if (accountid!=null) {
				accountid = accountid.left(15);
			}
			//System.debug('>>>>> accountid ' + accountid + ' >>> ' + accountIdForNewContacts);
			
			
			if(Trigger.isUpdate && !Test.isRunningTest() && !accountIdForNewContacts.equalsIgnoreCase(accountid)) {
				Contact oldContact = Trigger.oldMap.get(newContact.Id);
				GumtreeUtilsInterface utils = GumtreeUtils.getGumtreeUtilsInterface();
				GumtreeUserHandler handler = new GumtreeUserHandler(newContact, oldContact, utils);
				
				if(oldContact.Email != newContact.Email || oldContact.AccountId == null || oldContact.FirstName != newContact.FirstName || oldContact.LastName != newContact.LastName || oldContact.Phone != newContact.Phone || oldContact.AccountId != newContact.AccountId) {				
					
					handler.updateUser();
				}else {
					//No updates made that bushfire cares about
				}
			}else {
				//Currently we don't need to create users but this will change when we want to start creating accounts and users straight to bushfire
				//GumtreeUserHandler handler = new GumtreeUserHandler(newContact);
				//handler.createUser();
			}
		}
	
	
}