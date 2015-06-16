@IsTest public with sharing class GumtreeAPIMock implements GumtreeAPIInterface, GumtreeRemoteInterface {
	
	public void assignPackages(String packagesJson, String accountId) {
	}
	
    public void assignPackage(String userId,String salesforceId,String salesforceCode,Date startDate,Date endDate,Integer initialCredits,Integer adjustedCredits) {
    }
    
    public void deletePackage(String salesforceId) { 
    }
    
	public void createAccount(Id accountId, String accountJson, String userJson, String email) {
		
	}
	public String createAccountWithoutUpdatingSalesforce(Id accountId, String accountJson, String userJson, String email) {
		return '';
    }
	public void updateUser(String userJson, String userId) {
		
	}
	public void updateAccountNumberAndMarkAsMigrated(String accountId, String accountNumber) {
		
	}
    public void updateAccount(Id accountId, String accountJson) {
    	
    }
	public GumtreeUserType getUserType(String email) {
		return GumtreeUserType.NONE;
	}
	public String getBushfireUserJson(String email) {
		return 'bushfire user json';
	}
	
	public void logErrors() {
		
	}
}