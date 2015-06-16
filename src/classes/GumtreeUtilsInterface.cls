public interface GumtreeUtilsInterface {

	Boolean isAccountMigrated(Account acc);
		
	Boolean isAccountMigrated(String accountNum);
		
	Boolean isAccountMigrated(Id accountId);
    
    Boolean getBooleanFromJson(String key, String jsonContent);
    
    String getStringFromJson(String key, String jsonContent);
    
    GumtreeRemoteInterface remote(Account acc);
    
    GumtreeRemoteInterface remote(String accountNumber);
    
    /*
     * null handling for writing string fields to json
     */ 
    void writeStringFieldToJson(JSONGenerator gen, String key, String value);
    
    /*
     * null handling for writing Boolean fields to json
     */ 
    void writeBooleanFieldToJson(JSONGenerator gen, String key, Boolean value);
    
    /*
     * null handling for writing Lists to json
     */ 
    void writeListToJson(JSONGenerator gen, String key, Object value);
    
    /*
     * null handling for writing Objects to json
     */ 
    void writeObjectToJson(JSONGenerator gen, String key, Object value);
    
    /*
     * Get a list of Account Ids for a particular contact
     */
    List<String> getAccountIds(Contact contactToUpdate);
    
    /*
     * Get a list of Account Ids for a particular contact email
     */
    List<String> getAccountIds(String email);
    
    /*
     * Get a list of Account Ids for a particular contact
     */
    List<Long> getAccountNumbers(Contact contactToUpdate);
    
    /*
     * Get a list of Account for a particular contact
     */
    List<Account> getAccounts(Contact contactToUpdate);
    
    /*
     * Get a list of Account for a particular contact email
     */
    List<Account> getAccounts(String email);
    
    /*
     * Create the JSON for updating a user
     */
    String buildUpdateUserJson(Contact primaryContact);
    
    /*
     * Get the primary contact details for an account.  This can be used if the account is the trigger.old account
     */
    Contact getAccountPrimaryContact(Account account);
    
    
    String buildAccountJSON(Account account, String primaryContactEmail, String financeContactEmail);
    
	String buildPackageJSON(String userId,String salesforceId,String salesforceCode,Date startDate,Date endDate,Integer initialCredits,Integer adjustedCredits);    
        
}