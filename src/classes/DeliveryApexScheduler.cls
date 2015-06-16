/**
 * CR #3065 : Problem with the schedule jobs using UI (GTCRM-587)
 * Apex Scheduler for below classes to run at 7 pm and 7am in morning :
 * - SchDeliveryRevenueScheduleDaily
 * - SchDeliveryRevenueSchedules
 * - SchDeliveryOpportunityProduct
 */
global class DeliveryApexScheduler implements Schedulable {
	
	private String jobName;
	private String className;
	
	global DeliveryApexScheduler(String clsName){
		jobName = clsName + 'ByApex';
		className = clsName;
	}

	public void startBatchJobs() {
		if(className == 'SchDeliveryRevenueScheduleDaily'){
			DeliveryController.start(DeliveryController.SCH_TYPE_DAILY, DeliveryController.SOBJECT_REV_SCH2_DAILY);
		}else if(className == 'SchDeliveryRevenueSchedules'){
			DeliveryController.start(DeliveryController.SCH_TYPE_MONTHLY, DeliveryController.SOBJECT_REV_SCH2);
		}else if(className == 'SchDeliveryOpportunityProduct'){
			DeliveryController.start(DeliveryController.SCH_TYPE_DAILY, DeliveryController.SOBJECT_OPPPRODUCT);
		}
	}

	// scheduler implementation
	global void execute(SchedulableContext sc) {
		System.abortJob(sc.getTriggerId());
		startBatchJobs();
		start(43200); // schedule next start for 0.5 day in the future (43200 seconds)
	}

	// start a new job
	public void start(Integer psec) {
		// schedule new job
		DateTime sysTime = datetime.now().addSeconds(psec);
		String cronExp = '' + sysTime.second() + ' ' + sysTime.minute() + ' ' + sysTime.hour() + ' ' + sysTime.day() + ' ' + sysTime.month() + ' ?';
		System.schedule(jobName + ' - ' + sysTime.format('dd/MM/YYYY HH:MM:SS aaa'), cronExp, new DeliveryApexScheduler(className));
	}
	
	// start from specific time
	public void start(Integer hour, Integer minute) {
		abortJobs();
		// schedule new job
		DateTime sysTime = DateTime.newInstance(Date.today(), Time.newInstance(hour, minute, 0, 0));
		String cronExp = '' + sysTime.second() + ' ' + sysTime.minute() + ' ' + sysTime.hour() + ' ' + sysTime.day() + ' ' + sysTime.month() + ' ?';
		System.schedule(jobName + ' - ' + sysTime.format('dd/MM/YYYY HH:MM:SS aaa'), cronExp, new DeliveryApexScheduler(className));
	}

	global void abortJobs() {
		String jobFilter = jobName + '%';
		List<CronTrigger> jobs = [SELECT Id, CronJobDetail.Id, CronJobDetail.Name, CronJobDetail.JobType FROM CronTrigger WHERE CronJobDetail.Name LIKE :jobFilter];
		for (CronTrigger job : jobs) {
			System.abortJob(job.Id);
		}
	}
}