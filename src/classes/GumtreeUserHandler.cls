public with sharing class GumtreeUserHandler {

	private Contact newContact;
	private Contact oldContact;
	private GumtreeUtilsInterface utils;
	
	public GumtreeUserHandler(Contact newContact, Contact oldContact, GumtreeUtilsInterface utils) {
		this.newContact = newContact;
		this.oldContact = oldContact;
		this.utils = utils;
	}
	
	public void updateUser() {
		//if the contact is a primary contact then bushfire needs to be updated
		List<Account> accounts = utils.getAccounts(newContact.Email);
		System.debug(accounts);
		if (accounts != null && accounts.size() > 0 && isMigratedAccount(accounts)) {
			String newUserJson = utils.buildUpdateUserJson(newContact);
			String oldUserJson = utils.buildUpdateUserJson(oldContact);
			
			if(system.isBatch()){
				updateUserWithoutFuture(newUserJson, newContact.Email, oldUserJson, oldContact.Email);
			}else{
				updateUserFutureCall(newUserJson, newContact.Email, oldUserJson, oldContact.Email);
			}
		}
	}
	
	/*
	 * If the user is an existing bushfire user then update them on bushfire
	 */
	@future(callout = true)
	private static void updateUserFutureCall(String newUserJson, String newUserEmail, String oldUserJson, String oldUserEmail) {
		updateUserWithoutFuture (newUserJson, newUserEmail, oldUserJson, oldUserEmail);
	}
	
	private static void updateUserWithoutFuture (String newUserJson, String newUserEmail, String oldUserJson, String oldUserEmail) {
		GumtreeAPIInterface api = GumtreeAPI.getGumtreeAPIInstance();
		GumtreeUserType userType = api.getUserType(oldUserEmail);
		if (userType != GumtreeUserType.LEGACY) {
			api.updateUser(oldUserJson, oldUserEmail);
			api.updateUser(newUserJson, newUserEmail);
		}
	}
	
	private boolean isMigratedAccount(List<Account> accounts) {
		for (Account account : accounts) {
			if (account.Account_Migrated__c) {
				return true;
			}
		}
		return false;
	}
    
    public static testMethod void testBuildUserJson() {
    	
    	if (Gumtree_Settings__c.getInstance('Webservice') == null) {
  			upsert new Gumtree_Settings__c(Name = 'Webservice', SetupOwnerId=UserInfo.getOrganizationId());
    	}
    	
    	Contact newContact = new Contact();
    	newContact.FirstName = 'first_name';
    	newContact.LastName = 'last_name';
    	newContact.Email = 'email';
    	newContact.Phone = 'phone';
    	
    	Contact oldContact = new Contact();
    	oldContact.FirstName = 'first_name_old';
    	oldContact.LastName = 'last_name_old';
    	oldContact.Email = 'email_old';
    	oldContact.Phone = 'phone_old';
    	
    	Account account = new Account();
    	List<Account> accounts = new List<Account>();
    	
    	GumtreeUtilsMock utils = new GumtreeUtilsMock();
    	utils.setAccounts(accounts);
    	GumtreeUserHandler handler = new GumtreeUserHandler(newContact, oldContact, utils);
    	
    	handler.updateUser();
    }
}