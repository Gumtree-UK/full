@isTest
public with sharing class BounceBackEmailsTest {
	public static TestMethod void testDoRemoveDummyRecords(){
        Test.startTest();
        BounceBackEmails.doRemoveDummyRecords();
        Test.stopTest();
    }
}