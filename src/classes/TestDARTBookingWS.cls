/**
   Test class 
    -> DARTBookingWS
    
    Created date: 11/02/2013
 */  
 
@isTest 
public with sharing class TestDARTBookingWS {
  
  static TestDataGenerator testDATA = new TestDataGenerator();
  
  // Test Dart5
    static testMethod void noItemSelectedTest() {
        
       
	    test.startTest();
	    
		 	testDATA.createCredential();
		    testDATA.createTargetingHierarchy();
		    
		    String lineItemIds = '';
		    testDATA.createAccount();
		    testDATA.createAdvertiser();
		    testDATA.createOpp(testDATA.lstAcc.get(2));
		    Opportunity opp = testDATA.opp;
		    testDATA.createOppTeamMember(opp.id);
		    
		    testDATA.createNewOppItemsDart(opp.id,1,DARTUtil.DART5,testDATA.targetting[0].Id);
		    
		    List<OpportunityLineItem> lstItems = testDATA.lstLineItems;
		    for(OpportunityLineItem oppItem : lstItems)
		    {
		      lineItemIds += lineItemIds +',';
		    }
	     
		     DARTBookingWS.processWebservice(opp.Id, lineItemIds);
	     test.stopTest();

    }
    
  
  // Test dart 6
    static testMethod void selectedSomeItemsTest6() {
        
     	test.startTest();
     	
	     	testDATA.createCredential();
	        testDATA.createTargetingHierarchy();
	    	testDATA.createAccount();
	        testDATA.createAdvertiser();
	    	testDATA.createOpp(testDATA.lstAcc.get(1));
	    	testDATA.createOppTeamMember(testDATA.opp.id);
	    	testDATA.createNewOppItemsDart(testDATA.opp.id,2,DARTUtil.DART6,testDATA.targetting[0].Id);
	    
	        List<OpportunityLineItem> lstItems = testDATA.lstLineItems;
	        
	        String lineItemIds = lstItems.get(0).id + ',';// + lstItems.get(1).id + ',';
	     	
	     	String result = DARTBookingWS.processWebservice(testDATA.opp.Id, lineItemIds);
	     	System.assertEquals(result, 'OK','');
    		System.debug('*********************result:'+result);
     	test.stopTest();
     	
    
    }   
    
    // Test Dart6 -> Account no AdvertiserId
    static testMethod void testDart6NoAdvertiserId() {
        
       
	     test.startTest();
	     
		     testDATA.createCredential();
	         testDATA.createTargetingHierarchy();
	
	         testDATA.createAccount();
	         testDATA.createAdvertiser();
	    	 testDATA.createOpp(testDATA.lstAcc.get(0));
	    	 testDATA.createOppTeamMember(testDATA.opp.id);
	         Opportunity opp = testDATA.opp;
	         testDATA.createNewOppItemsDart(opp.id,1,DARTUtil.DART6,testDATA.targetting[0].Id);
	        
	      	 List<OpportunityLineItem> lstItems = testDATA.lstLineItems;
	
	         String lineItemIds = lstItems.get(0).id + ',';// + lstItems.get(1).id + ',';
		     
		     DARTBookingWS.processWebservice(opp.Id, lineItemIds);
		     
	     test.stopTest();

    }
    

}