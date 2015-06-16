@isTest(seeAllData=true)
public  class Liveagent_check_status_TestMethod {
	
	 public  static testmethod void testLiveagent_check_status(){
	 	  Profile p=[Select Id From Profile Where Name='System Administrator' or Name='Systemadministrator' Limit 1];
		    UserRole r=[Select Id From UserRole Limit 1];
		    User u=new User(Username='testUser1@boco.com',LastName='testLastName1',Email='testEmail1@boco.com',Alias='test1',TimeZoneSidKey='Pacific/kiritimati',
		            LocaleSidKey='ar',EmailEncodingKey='UTF-8',ProfileId=p.Id,LanguageLocaleKey='en_US',UserRoleId = r.Id);
		    insert u;         
		    System.runAs(u){
	 			String email ='LiveAgentCheckStatus@test.com';
		    	contact newContact = new contact(Email = email, LastName= email ,Live_Agent_Block__c= false  );
			 	insert newContact;	
			 	List<Config_Settings__c>   lstConfig =[Select Name, Checkbox_Value__c From Config_Settings__c  where name='CREATE_CONTACT_IN_CASE_TRIGGER_ENABLED' and Checkbox_Value__c= true];
			 	 //create new case
				 List<RecordType> lstRecords= [Select id From RecordType r where SobjectType='Case' and DeveloperName = 'Customer_Services'];
				 Case newCase = new Case( Status= 'New' , RecordTypeId =lstRecords.get(0).id , Origin= 'Live Chat' ,Posting_Reference__c= 'Test Live chat' );
			 	//case disable CREATE_CONTACT_IN_CASE_TRIGGER_ENABLED
			 	if( !lstConfig.isEmpty()){
			 		lstConfig.get(0).Checkbox_Value__c = false;
			 		update lstConfig;
			 		insert newCase ;
			 		lstConfig.get(0).Checkbox_Value__c = true;
			 		update lstConfig;
			 	}else{
			 		insert newCase ;		
			 	}			 	
			 	
				  	
		    	test.startTest();
		    		LiveChatVisitor lveVistitor= new LiveChatVisitor(); 
		    		insert lveVistitor;
		    		LiveChatTranscript liveAgent = new LiveChatTranscript(status='Missed',caseId= newCase.id, LiveChatVisitorId= lveVistitor.id);		    		
		    		insert liveAgent;
		    	test.stopTest();
	 	
		    }
	 }

}