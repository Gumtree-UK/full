/**
   Test class 
    -> DARTDeliveryWS
    
    Created date: 12/02/2013
 */
@isTest 
public with sharing class TestDARTDeliveryWS {

  static TestDataGenerator testDATA = new TestDataGenerator();
  
  static testMethod void testDartDevWs()
  {
    testDATA.createTargetingHierarchy();
        
        testDATA.createAccount();
        testDATA.createAdvertiser();
    testDATA.createOpp(testDATA.lstAcc.get(0));
        Opportunity opp = testDATA.opp;
        testDATA.createNewOppItemsDart(opp.id,1,DARTUtil.DART5,testDATA.targetting[0].Id);
        testDATA.createNewOppItemsDart(opp.id,1,DARTUtil.DART6,testDATA.targetting[0].Id);
        
    test.startTest();
    String results =  DARTDeliveryWS.processImportDelivery();
    
    DARTDeliveryWS.processImportDeliveryRS_Daily();
    
    DARTDeliveryWS.processImportDeliveryRS_Monthly();
    
    test.stopTest();
    
    System.assertEquals(results,'SUCCESS: Importing Delivery of Opportunity Product is now running in background.');
  }

  

}