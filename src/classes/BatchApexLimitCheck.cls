/**
 * Task #3907: DART6 Delivery RunningReport you are hitting the heap limit: (GTCRM-1350)
 * @description: Add the condition to all batch classes to run only 5 jobs at a time so that their would be only 5 jobs running all time.
 * @author: CPN
 * @createdDate: Sept-12-2014
 */
public class BatchApexLimitCheck {
	private final static integer APEX_BATCH_LIMIT = 5;
	public final static String CAN_NOT_EXECUTE_MORE_MSG = 'You already reached ' + APEX_BATCH_LIMIT + ' active batch';
	
	/**
	 * This is method should be called wherever there is an apex batch initialization
	 */
	public static Boolean isHittingLimit(){
		Integer activeCounter = [Select count() From AsyncApexJob Where Status IN ('Queued','Processing','Preparing','Holding') And JobType='BatchApex'];
		return activeCounter >= APEX_BATCH_LIMIT;
	}
}