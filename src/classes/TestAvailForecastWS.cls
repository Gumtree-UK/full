/**
    Test class 
     -> AvailForecastWS
     
     Created date: 19/12/2012
 */ 
 
@isTest
private class TestAvailForecastWS {
    static TestDataGenerator testDATA = new TestDataGenerator();
    
     // Test -> selected all/no selected lineItems of Opp
    static testMethod void noItemSelectedTest() {
        testDATA.createCredential();
        testDATA.createTargetingHierarchy();
        
        String lineItemIds = '';
        testDATA.createAccount();
        testDATA.createAdvertiser();
        testDATA.createOpp(testDATA.lstAcc.get(0));
        Opportunity opp = testDATA.opp;
        testDATA.createNewOppItemsDart(opp.id,1,DARTUtil.DART5,testDATA.targetting[0].Id);
        
        List<OpportunityLineItem> lstItems = testDATA.lstLineItems;
        for(OpportunityLineItem oppItem : lstItems)
        {
            lineItemIds += lineItemIds +',';
        }
          
       
        test.startTest();
        AvailForecastWS.processWebservice(opp.Id, lineItemIds);
        test.stopTest();

    }
    
    //test dart 6
    static testMethod void selectedSomeItemsTest6() {
        testDATA.createCredential();
        testDATA.createTargetingHierarchy();
        testDATA.createAccount();
        testDATA.createAdvertiser();
        testDATA.createOpp(testDATA.lstAcc.get(0));
        testDATA.createNewOppItemsDart(testDATA.opp.id,1,DARTUtil.DART6,testDATA.targetting[0].Id);
        
        List<OpportunityLineItem> lstItems = testDATA.lstLineItems;
        
        String lineItemIds = lstItems.get(0).id + ',';// + lstItems.get(1).id + ',';
        test.startTest();
        String result = AvailForecastWS.processWebservice(testDATA.opp.Id, lineItemIds);
        test.stopTest();
       // System.assertEquals(result, 'OK','');
        System.debug('*********************result:'+result);
        
    } 
    
}