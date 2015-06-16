/**
 * 	This class Test for FiqasResendInvoice 
 *
 *	@ Author: Kakada Khan
 *	@ Date: 02/09/2014
 *	@ Business:
 *	We would like  to send the invoice from salesforce to Email address of customer or opportunity priamry contact 
 *	with the click of a button.
 *
 */

@isTest(SeeAllData=true)
private class FiqasResendInvoice_Test {
	
	static testMethod void myTest(){
		
		//Create account
		List<Account>lstAct = createSomeAccount(10);
		insert lstAct;
		
		//Create 10 contacts with account 
		List<Contact> lstContact = createSomeContact(10,lstAct);
		insert lstContact;
		
		// update field in account
		List<Account> lstAccount = [SELECT Id, Primary_contact__c, Finance_contact__c FROM Account WHERE Id IN : lstAct];
		for(Integer i=0 ;i<lstContact.size();i++){
			lstAccount[i].Primary_contact__c=lstContact[i].Id;
			lstAccount[i].Finance_contact__c=lstContact[i].Id;
		}
		update lstAccount;
	
		//Create opportunity
		  Opportunity opp = new Opportunity(
	      Name='Test Opp',
	      //Agency__c=acc2.id ,
	      AccountId=lstAccount[0].id,
	      Campaign_Name__c='Campaign',
	      StageName='gebucht',
	      CloseDate=System.today()
	      );
	
	    insert opp;
		
		
		//Create 5 Invoices / account
		List<Invoices__c> lstInv = new List<Invoices__c>();
		for(Account acc : lstAccount){			
			for(Integer i=1;i<=5;i++){
				Invoices__c inv = new Invoices__c();
				inv.Account__c=acc.Id;
				inv.Opportunity__c=opp.Id;
				inv.Invoice_Date__c = System.today();
				lstInv.add(inv);
			}			
		}
		insert lstInv;	
		

		//set current page to test
		Pagereference pageRef=Page.FiqasResendInvoice;
		Test.setCurrentPage(pageRef);		

		List<Invoices__c> lstInvoices = [SELECT Id FROM Invoices__c WHERE Id IN : lstInv];

		//===== user select multi invoice with different account=====//		
		Apexpages.StandardSetcontroller stCon1 =new ApexPages.StandardSetcontroller(lstInvoices);
		stCon1.setSelected(lstInvoices);
	    FiqasResendInvoice fri1 = new FiqasResendInvoice(stCon1);	        
	    fri1.checkCondition();

		//Assert that will show message error on page
		List<Apexpages.Message> msgs1 = ApexPages.getMessages();
    	boolean b1 = false;
    	for(Apexpages.Message msg:msgs1){
    	    if (msg.getDetail().contains('There are many accounts on selected invoices.')) b1 = true;
    	}
   		system.assert(b1);//Assert the Page Message was Properly Displayed

		//====Test user send by click the link
		ApexPages.currentPage().getParameters().put('invoiceId', lstInvoices[0].Id);		
		
		//reset invoice to null
		lstInvoices=new List<Invoices__c>();		
		Apexpages.StandardSetcontroller stCon =new ApexPages.StandardSetcontroller(lstInvoices);
        FiqasResendInvoice fri = new FiqasResendInvoice(stCon);
        fri.checkCondition();
		
		//=== test for code coverage
		fri.cancel();
		List<SelectOption>lsts=fri.getListOption;
		
		//Make sure finance contact email not null;
		System.assert(fri.contactEmail != null);
		
		//====Test when user change recipient type 'FINANCE'
		fri.selectType='FINANCE';						
		fri.selectChangeType();		
		
		//Verify finance contact email not null;
		System.assert(fri.contactEmail != null);

		// Click button send
		fri.resend();
		
		//Assert that will show message success on page
		List<Apexpages.Message> msgs = ApexPages.getMessages();
    	boolean b = false;
    	for(Apexpages.Message msg:msgs){
    	    if (msg.getDetail().contains('Invoice Sent.')) b = true;
    	}
   		system.assert(b);//Assert the Page Message was Properly Displayed

		//====Test when user change recipient type 'CONTACT'
		fri.selectType='CONTACT';
		
		lstInvoices = [SELECT Id FROM Invoices__c WHERE Id IN : lstInv LIMIT 1];
		Invoices__c inv = [SELECT Account__c FROM Invoices__c WHERE Id = : lstInvoices[0].Id];		
		Contact c=[SELECT Id FROM Contact WHERE AccountId = : inv.Account__c];	
			
		// assign one contact for customlookup field
		fri.invoice.Contact__c = c.Id;
		fri.selectChangeType();
		fri.showContactEmail();
		
		//Verify finance contact email not null;
		System.assert(fri.contactEmail != null);
		
		
		//====Test when user change recipient type 'EMAIL'
		fri.selectType='EMAIL';
		fri.selectChangeType();					
		fri.freeOrFinanceEmail='test1@test.com';
		fri.resend();
		
		//Assert that will show message sucess on page
		List<Apexpages.Message> msgsw = ApexPages.getMessages();
    	boolean b2 = false;
    	for(Apexpages.Message msg:msgsw){
    	    if (msg.getDetail().contains('Invoice Sent.')) b2 = true;
    	}
   		system.assert(b2);//Assert the Page Message was Properly Displayed
   		
   		
   		//==== test when now email to send 
   		fri.selectType='EMAIL';
		fri.selectChangeType();					
		fri.freeOrFinanceEmail='';
		fri.resend();
		
		//Assert that will show message error on page
		List<Apexpages.Message> msgsws = ApexPages.getMessages();
    	boolean b3 = false;
    	for(Apexpages.Message msg:msgsws){
    	    if (msg.getDetail().contains('No email to send.')) b3 = true;
    	}
   		system.assert(b3);//Assert the Page Message was Properly Displayed
   		
   		
   		
	}
	
	
	
	// ====== Create some Contacts =======//
	static List<Contact> createSomeContact(Integer num,List<Account> lstAccount){
		
		List<Contact> lstCon = new List<Contact>();
		
		for(Integer i = 1; i <= num; i++){				
			Contact c = new Contact();
			c.AccountId=lstAccount[i-1].id;
			c.FirstName='first'+i;
			c.LastName='last'+i;
			c.Email= c.FirstName + c.LastName +'@test.com';
				
			lstCon.add(c);		
		}	
		return lstCon;
	}

	//==== Create some accounts ======//
	static List<Account> createSomeAccount(Integer num){
		
		List<Account> lstAcct=new List<Account>();			
		//Create Accounts
		for(Integer i = 1; i <= num; i++){
			
			Account acct = new Account(		
			 Name='Test Acc'+i,
                        BillingStreet = 'DFP Fake Street',
                        BillingCity = 'DFP Fake City',
                        BillingState = 'DFP Fake State',
                        BillingPostalCode = '123',
                        BillingCountry = 'GB',
                        Country_Code__c='GB',
                        Bank_Country__c = 'GB'
			);
				
			lstAcct.add(acct);
		}	
		return lstAcct;
	}

}// End class