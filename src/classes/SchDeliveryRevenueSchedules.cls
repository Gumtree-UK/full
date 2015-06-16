global class SchDeliveryRevenueSchedules implements Schedulable{
    global void execute(SchedulableContext sc) {
        DeliveryController.start(DeliveryController.SCH_TYPE_MONTHLY, DeliveryController.SOBJECT_REV_SCH2);
    }
    
    public static void startApexScheduler(){
    	DeliveryApexScheduler apexSch = new DeliveryApexScheduler('SchDeliveryRevenueSchedules');
    	apexSch.start(7, 0);// At 7:00 AM 
    }
    
    static testMethod void testSch()
    {
        Test.startTest();
        SchDeliveryRevenueSchedules sch = new SchDeliveryRevenueSchedules();
        
        String m = '20 30 8 10 2 ?';
        system.schedule('Test',m, sch);
        
        SchDeliveryRevenueSchedules.startApexScheduler();
        
        Test.stopTest();
        
    }
}