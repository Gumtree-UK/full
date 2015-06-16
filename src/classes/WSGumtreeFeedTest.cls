/**
* Test class for WSGumtreeFeed.cls
*
* @author Bunhor
* @date 09-Oct-14 
*/ 
@isTest(SeeAllData=true) 
public with sharing class WSGumtreeFeedTest { 
	/** Account for test */ 
	static Account acc = new Account( Feed_Provider__c = WSGumtreeFeed.FEED_USER_EBAY_MOTORS_PRO, Name = 'AccountTest', BillingStreet = 'Fake Street', BillingCity = 'Fake City', BillingState = 'London', BillingPostalCode = '123', BillingCountry = 'GB'); 
	/** Fake response */ 
	static HttpResponse res = new HttpResponse();
	/** a cumstom setting record containing  Id__c, Email__c, and Name (Name is the feed name) */ 
	static WSGumtreeFeed__c cs; 
	/** Response body in case error code = 500 when request to gumtree checklink */ 
	static String resErr500 =  	'<SOAP-ENV:Envelope xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/">'+
								    '<SOAP-ENV:Header/>'+
								    '<SOAP-ENV:Body>'+
									    '<SOAP-ENV:Fault>'+
										    '<faultcode>SOAP-ENV:Client</faultcode>'+
										    '<faultstring xml:lang="en">Gumtree account ID cannot be changed because there are live or pending Gumtree listings for that account</faultstring>'+
									    '</SOAP-ENV:Fault>'+
								    '</SOAP-ENV:Body>'+
							    '</SOAP-ENV:Envelope>';
    
    
    /**
	* Initialize the static variable
	* 
	* @return void
	*/ 
	static void initSetting(){ 
		cs = WSGumtreeFeed__c.getValues(acc.Feed_Provider__c);
		if(cs == null){
			cs = new WSGumtreeFeed__c(Name = acc.Feed_Provider__c, Id__c = '123', Email__c = 'test@a.a');
			insert cs;
		}
	}
	
	/**
	* testMethod for checklink
	* 
	* @return void
	*/ 
	static testMethod void testCheckLink() {
 
		String result = WSGumtreeFeed.methodForTest(acc, WSGumtreeFeed.ACTION_CHECK_LINK, res);
		System.assert(result != null); // 'Missing: AccountNumber and eMP_Account_Number__c'
		
		// adding missing data
		acc.AccountNumber = '123';
		acc.eMP_Account_Number__c = '456';
		 
		result =  WSGumtreeFeed.methodForTest(acc, WSGumtreeFeed.ACTION_CHECK_LINK, res);
		System.assert(result != null); // 'This Feed Provider does not existed in the custom setting!'
		
		//insert custom setting 
		initSetting();
		
		result = WSGumtreeFeed.methodForTest(acc, WSGumtreeFeed.ACTION_CHECK_LINK, res);
		System.assert(result != null); // not succes request (error code != 200) 
		
		// set the mock res to success, but no id
		res.setStatusCode(200);
		res.setBody('{"account_ids":[]}');
		
		result = WSGumtreeFeed.methodForTest(acc, WSGumtreeFeed.ACTION_CHECK_LINK, res);
		System.assert(result != null); // 'Account not linked' 
		
		// set id to the mock res  
		res.setBody('{"account_ids":['+acc.AccountNumber+']}');
		
		result = WSGumtreeFeed.methodForTest(acc, WSGumtreeFeed.ACTION_CHECK_LINK, res);
		System.assert(result != null); // 'Gumtree account linked' 
	}
	
	/**
	* testMethod for linkuser
	* 
	* @return void
	*/ 
	static testMethod void testAddLink(){
  
		// adding missing data
		acc.AccountNumber = '123';
		acc.eMP_Account_Number__c = '456';
		  
		// insert custom setting 
		initSetting();
		 
		// set the mock res to success 
		res.setStatusCode(200);  
		res.setBody('{"account_ids":['+cs.Id__c+']}');
		
		String result = WSGumtreeFeed.methodForTest(acc, WSGumtreeFeed.ACTION_LINK_USER, res);
		System.assert(result != null); // 'eMP account linked' 
		
		// set the mock res to 500 error
		res.setStatusCode(500);
		res.setBody(resErr500);
		
		result = WSGumtreeFeed.methodForTest(acc, WSGumtreeFeed.ACTION_LINK_USER, res);
		System.assert(result != null); // 'eMP not linked: '
		
		// set the mock res to  error
		res.setStatusCode(404);
		
		result = WSGumtreeFeed.methodForTest(acc, WSGumtreeFeed.ACTION_LINK_USER, res);
		System.assert(result != null); // 'Error code (eBay Motors Pro): '
		
		WSGumtreeFeed.ResCheckLink obj1 = new WSGumtreeFeed.ResCheckLink();
		WSGumtreeFeed.APIKey obj2 = new WSGumtreeFeed.APIKey();
	}
	
}