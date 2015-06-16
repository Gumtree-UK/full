public with sharing class GumtreeUtilsMock implements GumtreeUtilsInterface {
	
	private Integer statusCode = 0;
	private List<Account> accounts;
	private List<String> accountIds;
	private String stringFromJson = 'testString';
	private Boolean boolFromJson;
	private Boolean isAccountMigrated = true;
	private Boolean cretaeNewUsersInBushfire = true;
	private Contact contact;
	private Map<Account,Contact> contactMap = new Map<Account,Contact>();

	public Boolean isAccountMigrated(Account acc) {
		return isAccountMigrated(acc.AccountNumber);
	}
		
	public Boolean isAccountMigrated(String accountNum) {
		return isAccountMigrated;
	}
		
	public Boolean isAccountMigrated(Id accountId) {
		return isAccountMigrated;
	}
	
	public GumtreeRemoteInterface remote(Account acc) {
		return remote(acc.AccountNumber);
	}
	
	public GumtreeRemoteInterface remote(String accountId) {
		return new GumtreeAPI();
	}
    
    public Boolean getBooleanFromJson(String key, String jsonContent) {
    	return boolFromJson;
    }
    
    public String getStringFromJson(String key, String jsonContent) {
		return stringFromJson;
    }
    
    /*
     * null handling for writing string fields to json
     */ 
    public void writeStringFieldToJson(JSONGenerator gen, String key, String value) {
    }
    public void writeBooleanFieldToJson(JSONGenerator gen, String key, Boolean value) {
    }
    
    /*
     * null handling for writing Lists to json
     */ 
    public void writeListToJson(JSONGenerator gen, String key, Object value) {
    }
    
    /*
     * null handling for writing Objects to json
     */ 
    public void writeObjectToJson(JSONGenerator gen, String key, Object value) {
    }
    
    public List<Account> getAccounts(String email) {
    	return this.accounts;
    }
    
    public List<String> getAccountIds(String email) {
    	return this.accountIds;
    }
    
    /*
     * Get a list of Account Ids for a particular contact
     */
    public List<String> getAccountIds(Contact contactToUpdate) {
    	return accountIds;
    }
    
    /*
     * Get a list of Account Numbers for a particular contact
     */
    public List<Long> getAccountNumbers(Contact contactToUpdate) {
    	List<Long> accountNumbers = new List<Long>();
    	return accountNumbers;
    }
    
    /*
     * Get a list of Account for a particular contact
     */
    public List<Account> getAccounts(Contact contactToUpdate) {
    	return accounts;
    }

    public String buildUpdateUserJson(Contact primaryContact) {
        return 'test string';
    }
    
	public String buildAccountJSON(Account account, String primaryContactEmail, String financeContactEmail) {
		return 'test account';
	}    
    
    public String buildPackageJSON(String userId,String salesforceId,String salesforceCode,Date startDate,Date endDate,Integer initialCredits,Integer adjustedCredits) {
    	return 'test package';
    }
    
    public Contact getAccountPrimaryContact(Account account) {
    	if (contactMap.containsKey(account)) {
    		return contactMap.get(account);
    	}
		return this.contact;
    }
    
    public void addContactToMap(Contact contact, Account account) {
    	contactMap.put(account, contact);
    }
    
    public void setStatusCode(Integer statusCode) {
    	this.statusCode = statusCode;
    }
    
    public void setAccounts(List<Account> accounts) {
    	this.accounts = accounts;
    }
    
    public void setAccounts(List<String> accountIds) {
    	this.accountIds = accountIds;
    }
    
    public void setStringFromJson(String stringFromJson) {
    	this.stringFromJson = stringFromJson;
    }
    
    public void setBoolFromJson(Boolean boolFromJason) {
    	this.boolFromJson = boolFromJason;
    }
    
    public void setIsAccountMigrated(Boolean isAccountMigrated) {
    	this.isAccountMigrated = isAccountMigrated;
    }
    
    public void setCretaeNewUsersInBushfire(Boolean isAccountMigrated) {
    	this.cretaeNewUsersInBushfire = isAccountMigrated;
    }
    
    public Contact setContact(Contact contact) {
    	return this.contact = contact;
    }
}