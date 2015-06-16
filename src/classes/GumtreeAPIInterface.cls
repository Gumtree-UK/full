public interface GumtreeAPIInterface {
	void assignPackages(String packagesJson, String accountId);
	void assignPackage(Id accountId,String salesforceId,String salesforceCode,Date startDate,Date endDate,Integer initialCredits,Integer adjustedCredits);
	void createAccount(Id accountId, String accountJson, String userJson, String email);
	String createAccountWithoutUpdatingSalesforce(Id accountId, String accountJson, String userJson, String email);
	void updateUser(String userJson, String userId);
	void updateAccount(Id accountId, String accountJson);
	void updateAccountNumberAndMarkAsMigrated(String accountId, String accountNumber);
	GumtreeUserType getUserType(String email);
	String getBushfireUserJson(String email);
	void logErrors();
}