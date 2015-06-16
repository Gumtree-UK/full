@isTest(SeeAllData=true)
public with sharing class PreChatFormControllerTestMethod {


         public  static testmethod void testPreChatFormController(){
            Profile p=[Select Id From Profile Where Name='System Administrator' or Name='Systemadministrator' Limit 1];
            UserRole r=[Select Id From UserRole Limit 1];
            User u=new User(Username='testUser1@boco.com',LastName='testLastName1',Email='testEmail1@boco.com',Alias='test1',TimeZoneSidKey='Pacific/kiritimati',
                    LocaleSidKey='ar',EmailEncodingKey='UTF-8',ProfileId=p.Id,LanguageLocaleKey='en_US',UserRoleId = r.Id);
            insert u;         
            System.runAs(u){
                String email ='UserPreChatBlock@PreChatBlock.com';
                contact newContact = new contact(Email = email, Lastname='name',Live_Agent_Block__c= true  );
                insert newContact;  
                
                 //create new case
                 List<RecordType> lstRecords= [Select id From RecordType r where SobjectType='Case' and DeveloperName = 'Customer_Services'];
                 Case newCase = new Case( Status= 'New' , RecordTypeId =lstRecords.get(0).id , Origin= 'Live Chat' ,Posting_Reference__c= 'Test Live chat',Description ='description', Reason='abc' );
                 insert newCase ;       
                test.startTest();
                PreChatFormController controller = new PreChatFormController(); 
               Map<String,String> mapResult = PreChatFormController.checkIsEmailExist( email,'firstname','name','TestPreChat AdRef', 'false','description','agent1');//case email blocked                
               mapResult = PreChatFormController.checkIsEmailExist('TestPreChat@Prechat.com','firstname','name','TestPreChat AdRef', 'false', 'description','agent1');//case new email
               // Map<String,String> mapResult = PreChatFormController.checkIsEmailExist( email,'firstname','name','TestPreChat AdRef', 'false','agent1');//case email blocked                
               //mapResult = PreChatFormController.checkIsEmailExist('TestPreChat@Prechat.com','firstname','name','TestPreChat AdRef', 'false', 'agent1');//case new email
                newContact.Live_Agent_Block__c= false;
                update newContact; 
               mapResult = PreChatFormController.checkIsEmailExist( email,'firstname','name','TestPreChat AdRef', 'false' ,'description','agent1');//case existing email
               // mapResult = PreChatFormController.checkIsEmailExist( email,'firstname','name','TestPreChat AdRef', 'false' ,'agent1');//case existing email
                mapResult = PreChatFormController.updateCaseOwner( newCase.id, u.id,newContact.Id);
                 
                LiveChatVisitor visitor = new LiveChatVisitor();
                insert visitor;
                LiveChatTranscript liveChatTran = new LiveChatTranscript(caseId = newCase.Id, LiveChatVisitorId = visitor.Id);  
                insert liveChatTran;

                PKB_Status_Message__c sm = new PKB_Status_Message__c(Message_Type__c='Safety Alert', MessageText__c='Test', Message_Start_DateTime__c=Date.today(), Message_End_DateTime__c=Date.today()+5, Status__c = 'Active');
                insert sm;
				//improve test coverage
				PreChatFormController.populateUserSourceExtra('Mozilla/5.0 (Linux; Android 4.2.2; nl-nl; SAMSUNG GT-I9505 Build/JDQ39) AppleWebKit/535.19 (KHTML, like Gecko) Version/1.0 Chrome/18.0.1025.308 Mobile Safari/535.19');
                PreChatFormController.populateUserSourceExtra('Mozilla/5.0 (compatible; MSIE 10.0; Windows NT 6.2; Trident/6.0)');
                PreChatFormController.populateUserSourceExtra('Mozilla/5.0 (Linux; U; Android 4.2.2; nl-nl; GT-P5210 Build/JDQ39) AppleWebKit/534.30 (KHTML, like Gecko) Version/4.0 Safari/534.30');
                PreChatFormController.updateContactChatStatus(newContact.Id);
                test.stopTest();
                
                
            }
      }
}