@isTest 
public with sharing class EmailSenderControllerTest {

	static testMethod void testSendEmail() {
		TestDataGenerator testDATA = new TestDataGenerator();
		testDATA.createAccount();
        testDATA.createAdvertiser();
        testDATA.createOpp(testDATA.lstAcc.get(0));
        
		Test.startTest();
        
		String url='/apex/EmailSender?ispdf=true&Oppid='+testDATA.opp.Id;
        
        PageReference pageSum=new PageReference(url); //vf page generated       
		
		Test.setCurrentPage(pageSum);
		
		EmailSenderController con = new EmailSenderController();
		con.sendMail();// Error To Email is required.
		System.assertEquals(con.isSent, false);
		
		con.toAddress = '123';
		con.sendMail();// Invalid Email.
		System.assertEquals(con.isSent, false);
		
		con.toAddress = 'test@test.com';
		con.ccAddress = 'testcc@test.com';
		con.subject   = 'test subject';
		con.bodyEmail = 'test body';
		con.sendMail();
		//System.assertEquals(con.isSent, true);
		Test.stopTest();
	}
}