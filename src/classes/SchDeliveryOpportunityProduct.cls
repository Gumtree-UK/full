global class SchDeliveryOpportunityProduct implements Schedulable{
    global void execute(SchedulableContext sc) {
        DeliveryController.start(DeliveryController.SCH_TYPE_DAILY, DeliveryController.SOBJECT_OPPPRODUCT);
    }
    
    public static void startApexScheduler(){
        DeliveryApexScheduler apexSch = new DeliveryApexScheduler('SchDeliveryOpportunityProduct');
        apexSch.start(7, 0);// At 7:00 AM 
    }
    
    static testMethod void testSch()
    {
        Test.startTest();
        SchDeliveryOpportunityProduct sch = new SchDeliveryOpportunityProduct();
        
        String m = '20 30 8 10 2 ?';
        system.schedule('Test',m, sch);
        
        SchDeliveryOpportunityProduct.startApexScheduler();
        
        Test.stopTest();
        
    }
}