@isTest
private class TestAddAgreementEventToChatterFeed
{
    private static testMethod void myTest()
    {
        Contact objContact = new Contact();
        objContact.LastName = 'Test';
        List<echosign_dev1__SIGN_AgreementEvent__c > lstAE = new List<echosign_dev1__SIGN_AgreementEvent__c> ();
        insert objContact;
    
        echosign_dev1__SIGN_Agreement__c objA1 = new echosign_dev1__SIGN_Agreement__c();
        objA1.echosign_dev1__Recipient__c = objContact.Id;
        objA1.Name = 'Test Agreement 1';
        insert objA1;
        
        echosign_dev1__SIGN_Agreement__c objA2 = new echosign_dev1__SIGN_Agreement__c();
        objA2.echosign_dev1__Recipient__c = objContact.Id;
        objA2.Name = 'Test Agreement 2';
        insert objA2;
    
        echosign_dev1__SIGN_Agreement__c objA3 = new echosign_dev1__SIGN_Agreement__c();
        objA3.echosign_dev1__Recipient__c = objContact.Id;
        objA3.Name = 'Test Agreement 3';
        insert objA3;
        
        echosign_dev1__SIGN_AgreementEvent__c objAE1 = new echosign_dev1__SIGN_AgreementEvent__c();
        objAE1.echosign_dev1__SIGN_Agreement__c = objA1.Id;
        lstAE.add(objAE1);
        
        echosign_dev1__SIGN_AgreementEvent__c objAE2 = new echosign_dev1__SIGN_AgreementEvent__c();
        objAE2.echosign_dev1__SIGN_Agreement__c = objA2.Id;
        objAE2.echosign_dev1__Description__c= 'signed';
        lstAE.add(objAE2);
        
        echosign_dev1__SIGN_AgreementEvent__c objAE3 = new echosign_dev1__SIGN_AgreementEvent__c();
        objAE3.echosign_dev1__SIGN_Agreement__c = objA3.Id;
        objAE3.echosign_dev1__Description__c= 'sent out';
        lstAE.add(objAE3);
    
        insert lstAE;
        

        
    }
}