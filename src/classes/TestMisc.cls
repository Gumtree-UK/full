@isTest(seeAllData=true)
public class TestMisc{

 static TestDataGenerator testDATA = new TestDataGenerator();
 
 static testMethod void testOpportunityBooking()
 {
    
    testDATA.createTargetingHierarchy();
    testDATA.createAccount();
    testDATA.createAdvertiser();
    testDATA.createOpp(testDATA.lstAcc.get(0));
    
    Opportunity opp1 = testDATA.Opp;
    
    Opportunity opp2 = opp1.clone(false);
    opp2.Opportunity__c = opp1.Id;
    insert opp2;
    
    Contact con = new Contact(LastName='test contact000001');
    insert con;
    
    testDATA.lstAcc[0].Primary_contact__c = con.Id;
    testDATA.lstAcc[0].Finance_contact__c = con.Id;
    update testDATA.lstAcc[0];
    testDATA.createNewOppItemsDart(opp1.Id, 1, DARTUtil.DART6, null);
    
    //testDATA.createNewOppItemsDart(opp2.id,2,DARTUtil.DART6,testDATA.targetting[0].Id);
           
    Test.startTest();
    
    ClsBookingOppUpdate.updateProductDate(new List<Opportunity>{opp2});
    
    
    Test.stopTest();
 }
 static testMethod void testOpportunityServiceCancelBeforeTime()
 {
    testDATA.createTargetingHierarchy();
    testDATA.createAccount();
    testDATA.createAdvertiser();
    testDATA.createOpp(testDATA.lstAcc.get(0));
      
    Opportunity opp1 = testDATA.Opp;
    
    Contact con = new Contact(LastName='test contact000001');
    insert con;
    testDATA.lstAcc[0].Primary_contact__c = con.Id;
    testDATA.lstAcc[0].Finance_contact__c = con.Id;
    update testDATA.lstAcc[0];
    
    Test.startTest();
    
    ClsOpportunityService.cloneOpportunity(opp1.Id);
    testDATA.createNewOppItemsDart(opp1.Id, 1, DARTUtil.DART6, null);
    List<OpportunityLineItem> item = [Select Id, Cancellation_Date__c, Notice_Date__c, Cancellation_Reason__c From OpportunityLineItem Where OpportunityId = : opp1.Id];
    item[0].from_Date__c = system.today() - 30;
    item[0].Notice_Date__c = system.today();
    update item[0];
    
    item[0].Cancellation_Date__c = system.today() + 30;
    item[0].Notice_Date__c = system.today() + 5;
    item[0].Cancellation_Reason__c = 'test';
    update item[0];
    
    opp1.IsCancellationPending__c = true;
    update opp1;
    //ClsOpportunityService.updateCancelledOpp(new List<Opportunity>{opp1},new List<Opportunity>{opp1});
    Test.stopTest();
 }

 static testMethod void testCancelAfterTimeSameMonth()
 {
    testDATA.createTargetingHierarchy();
    testDATA.createAccount();
    testDATA.createAdvertiser();
    testDATA.createOpp(testDATA.lstAcc.get(0));
    
    Opportunity opp1 = testDATA.Opp;
    Contact con = new Contact(LastName='test contact000001');
    insert con;
    testDATA.lstAcc[0].Primary_contact__c = con.Id;
    testDATA.lstAcc[0].Finance_contact__c = con.Id;
    update testDATA.lstAcc[0];
    Test.startTest();
    
    ClsOpportunityService.cloneOpportunity(opp1.Id);
    testDATA.createNewOppItemsDart(opp1.Id, 1, DARTUtil.DART6, null);
    List<OpportunityLineItem> item = [Select Id, Cancellation_Date__c, Notice_Date__c, Cancellation_Reason__c From OpportunityLineItem Where OpportunityId = : opp1.Id];
    item[0].from_Date__c = system.today().toStartOfMonth().addMonths(-1);
    item[0].until_Date__c = system.today().toStartOfMonth().addMonths(1) + 5;
    update item[0];
    
    item[0].Cancellation_Date__c = system.today().toStartOfMonth().addMonths(1) + 6;
    item[0].Notice_Date__c = system.today() + 5;
    item[0].Cancellation_Reason__c = 'test';
    update item[0];
    
    opp1.IsCancellationPending__c = true;
    update opp1;
    Test.stopTest();
 }

 static testMethod void testCancelAfterTimeFutureMonth()
 {
    testDATA.createTargetingHierarchy();
    testDATA.createAccount();
    testDATA.createAdvertiser();
    testDATA.createOpp(testDATA.lstAcc.get(0));
    
    Opportunity opp1 = testDATA.Opp;
    Contact con = new Contact(LastName='test contact000001');
    insert con;
    testDATA.lstAcc[0].Primary_contact__c = con.Id;
    testDATA.lstAcc[0].Finance_contact__c = con.Id;
    update testDATA.lstAcc[0];
    //Test.startTest(); // Bunhor @20-Jan-15: move this to below item update avoiding "Too many SOQL queries: 101" 
    
    ClsOpportunityService.cloneOpportunity(opp1.Id);
    testDATA.createNewOppItemsDart(opp1.Id, 1, DARTUtil.DART6, null);
    List<OpportunityLineItem> item = [Select Id, Cancellation_Date__c, Notice_Date__c, Cancellation_Reason__c From OpportunityLineItem Where OpportunityId = : opp1.Id];
    item[0].from_Date__c = system.today().toStartOfMonth().addMonths(-1);
    item[0].until_Date__c = system.today().toStartOfMonth().addMonths(1);
    update item[0];
    Test.startTest();
    item[0].Cancellation_Date__c = item[0].until_Date__c + 35;
    item[0].Notice_Date__c = system.today() + 5;
    item[0].Cancellation_Reason__c = 'test';
    update item[0];
    
    opp1.IsCancellationPending__c = true;
    update opp1;
    Test.stopTest();
 }

}