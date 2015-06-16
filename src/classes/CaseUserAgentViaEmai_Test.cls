/**
@Author : spp
@Date : 23/09/2014
@Business :

When case is created via email, we compute the user agent

See CaseUserAgentViaEmai_Trg

*
*/
@isTest(SeeAllData=true)
private class CaseUserAgentViaEmai_Test {

    static testMethod void myUnitTest1() {
        
        
        String header1 = 'Received: from [209.85.212.176] ([209.85.212.176:49560] helo=mail-wi0-f176.google.com) \n';
        header1 += 'X-Mailer: iPhone Mail (11D257)\n';
		header1 += 'Message-Id: <6D71CFA7-7198-4D35-9D17-ADF97331C786@gmail.com>\n';
        
        	  // Insert a contact
       	Contact c = new Contact(lastname='testContact');
        insert c;
      
        
        //Set up user
        User u1 = [SELECT Id FROM User WHERE Alias='ROBOT'];
        
        //Run As U1
        System.RunAs(u1){
        	
        
      
        	Case c1 = new Case (subject='testcase',contactid = c.Id);  
        	insert c1;


		    EmailMessage em = new EmailMessage();
		    em.FromAddress = 'test@example.com';
		    em.Incoming = true;
		    em.ToAddress = 'hello@670ocglw7xhomi4oyr5yw2zvf.8kp7yeag.8.case.salesforce.com';
		    em.Subject = 'Test email';
		    em.TextBody = 'Hello';
		    em.headers = header1;
		    em.ParentId = c1.Id; // The inserted test Case Id that you created above
		    
		    insert em;

        }
  
	
	    
    }
    
    
     static testMethod void myUnitTest2() {
        
        
        String header1 = 'Received: from [209.85.212.176] ([209.85.212.176:49560] helo=mail-wi0-f176.google.com) \n';
        header1 += 'X-Mailer: BlackBerry Email (2.0.0.7971)\n';
		header1 += 'Message-ID: <0hhwdrusii4gxtjbiv24jabq.1411528069076@email.android.com>\n';
        
        	  // Insert a contact
       	Contact c = new Contact(lastname='testContact');
        insert c;
      
        
        //Set up user
        User u1 = [SELECT Id FROM User WHERE Alias='ROBOT'];
        
        //Run As U1
        System.RunAs(u1){
        	
        
      
        	Case c1 = new Case (subject='testcase',contactid = c.Id);  
        	insert c1;


		    EmailMessage em = new EmailMessage();
		    em.FromAddress = 'test@example.com';
		    em.Incoming = true;
		    em.ToAddress = 'hello@670ocglw7xhomi4oyr5yw2zvf.8kp7yeag.8.case.salesforce.com';
		    em.Subject = 'Test email';
		    em.TextBody = 'Hello';
		    em.headers = header1;
		    em.ParentId = c1.Id; // The inserted test Case Id that you created above
		    
		    insert em;

        }
  
	
	    
    }
    
     static testMethod void myUnitTest3() {
        
        
        String header1 = 'Received: from [209.85.212.176] ([209.85.212.176:49560] helo=mail-wi0-f176.google.com) \n';
		header1 += 'Message-ID: <0hhwdrusii4gxtjbiv24jabq.1411528069076@email.android.com>\n';
        
        	  // Insert a contact
       	Contact c = new Contact(lastname='testContact');
        insert c;
      
        
        //Set up user
        User u1 = [SELECT Id FROM User WHERE Alias='ROBOT'];
        
        //Run As U1
        System.RunAs(u1){
        	
        
      
        	Case c1 = new Case (subject='testcase',contactid = c.Id);  
        	insert c1;


		    EmailMessage em = new EmailMessage();
		    em.FromAddress = 'test@example.com';
		    em.Incoming = true;
		    em.ToAddress = 'hello@670ocglw7xhomi4oyr5yw2zvf.8kp7yeag.8.case.salesforce.com';
		    em.Subject = 'Test email';
		    em.TextBody = 'Hello';
		    em.headers = header1;
		    em.ParentId = c1.Id; // The inserted test Case Id that you created above
		    
		    insert em;

        }
  
	
	    
    }
}