global class SchDeliveryRevenueScheduleDaily implements Schedulable{
    global void execute(SchedulableContext sc) {
        DeliveryController.start(DeliveryController.SCH_TYPE_DAILY, DeliveryController.SOBJECT_REV_SCH2_DAILY);
    }
    
    public static void startApexScheduler(){
    	DeliveryApexScheduler apexSch = new DeliveryApexScheduler('SchDeliveryRevenueScheduleDaily');
    	apexSch.start(7, 0);// At 7:00 AM 
    }
    
    static testMethod void testSch()
    {
        Test.startTest();
        SchDeliveryRevenueScheduleDaily sch = new SchDeliveryRevenueScheduleDaily();
        
        String m = '20 30 8 10 2 ?';
        system.schedule('Test',m, sch);
        
        SchDeliveryRevenueScheduleDaily.startApexScheduler();
        
        Test.stopTest();
        
    }
}