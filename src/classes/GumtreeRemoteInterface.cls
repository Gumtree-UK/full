public interface GumtreeRemoteInterface {

	void assignPackage(String userId,String salesforceCode,String salesforceId,Date startDate,Date endDate,Integer initialCredits,Integer adjustedCredits);

	void deletePackage(String SalesForceId);	
	
}