@isTest
public class TestLiveAgentGEO{
	
	private static testMethod void testGEOLiveAgent()
	{
		Case vCase = new Case(); 
		
		Test.startTest();
		LiveAgentGEO.fetchVisitorGEO(vCase, '127.0.0.1');
		
		Test.stopTest();
		
		System.assertEquals(11.11,vCase.UMgeolocalization__Latitude__s,'lat from mock');
		System.assertEquals(22.22,vCase.UMgeolocalization__Longitude__s,'lon from mock');
		System.assertEquals('LocalHost',vCase.Country_Name__c,'country from mock');
		 
	}
}