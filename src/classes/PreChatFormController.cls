/**

Change log;
- 2014-11-19 - GTCRM-1567 - GT Help Alerts on live chat pre chat form  
- 06-02-2015 - GTCRM-1570-Phone/Live chat close case per normal process       
- 2014-12-04 - GTCRM-1232 - Update existing help site alerts to only show for Help record type
- 2015-04-30 - GTCRM-1966 - Live chat owner and case link issues

**/

global class PreChatFormController {
    
    global PreChatFormController(){ 
            
    }
    /*
    
        (GTCRM-737) live chat status
        
        on chat completion, Live Agent (SFDC) should automatically;

        Create a case and attach live chat transcript; (GTCRM-439)
        
        - Map contact
        - If email address exists then map to contact
        - If email address does not exist then create contact;
        - Email = email address
        - Last name = email address
        - Case Record Type = ?Customer Services?
        - CaseOrigin = ?Live Chat?
        - CaseOwner = ?LiveChatTranscript.OwnerId?
        - Status = ?New?
        - Case.Posting_Reference__c = ?liveagent.prechat:AdRef? - from KnowledgeChatForm.page
        - Screen-pop newly created case
        
        Pass the following variables to KnowledgePostChat2.page to allow us to update the URL that is passed to map the case and the owner when the survey is synchronised with SFDC;
        
        - Case.Id
        - LiveChatTranscript.Owner.Id
        
        KnowledgePostChat2.page URL on line 11 should be updated to; 
        window.location.replace("http://supportsurvey.gumtree.com/go?iv=o5748ptq31l44&q1={!Case.Id}&q6={!LiveChatTranscript.OwnerId}&q7=Live Chat");
    
    */   
   // 06-02-2015 - GTCRM-1570-Phone/Live chat close case per normal process  
     private static final String New_Closed='Survey Send';
     private static final String LIVE_CHAT='Live Chat';
     private static final String CUSTOMER_SERVICE='Customer_Services';
     private static final String RESULT_STATUS='Result';
     private static final String CASE_ID='CaseId';
     private static final String ERROR_STATUS='Error';
     private static final String CONTACT_ID='PreChatConId';
     private static final String WINDOW = 'WIN';
     private static final String MAC = 'MAC';
     private static final String PHONE = 'ANDROID, IOS, BLACKBERRY, NOKIA';
  
     @remoteAction
          
         global static Map<String,String> checkIsEmailExist(String pemail, String pfirstname,String name, String AdRef, String emailOptOut,String description,String userAgent){
                    
         String accountIdForNewContacts =  CustomSettingsManager.getConfigSettingStringVal(CustomSettingsManager.GT_HELP_ACCOUNT_ID);
      
         List<contact> contacts = [select  Id, FirstName,LastName,Live_Agent_Block__c,IsChatting__c from contact where AccountId=:accountIdForNewContacts and email=:pemail limit 1];
         
         Map<String,String> mapResult = new Map<String,String>();           
            try{    
                String conId = '';             
                //case New Email create contact
                if(contacts.isEmpty()) {
                    //create new contact                
                    Contact newContact = new contact(Email = pemail, FirstName=pfirstname, LastName=name, AccountId=accountIdForNewContacts);
                    insert newContact;  
                    conId = newContact.id;
                }else{ 
                    //case existing email               
                    conId = contacts[0].id; 
                    
                    if(contacts[0].IsChatting__c){
                        mapResult.put( RESULT_STATUS , 'ONLINE_CONTACT');
                        return mapResult;   
                    }
                    // let update the contact with correct first name/last name
                    if (String.isEmpty(contacts[0].FirstName) || String.isEmpty(contacts[0].LastName)) {
                        contacts[0].FirstName = pfirstname;
                        contacts[0].LastName = name;
                        
                        update contacts[0];
                    }
                                    
                }
                 
                mapResult.put( CONTACT_ID ,conId);   
                 
                if(!contacts.isEmpty() && contacts[0].Live_Agent_Block__c){ 
                   //case user blocked             
                    mapResult.put( RESULT_STATUS , +'true');
                    return mapResult;   
                }
                 
                 //create new case
                Id caseRecordTypeId = [Select id From RecordType r where SobjectType='Case' and DeveloperName = :CUSTOMER_SERVICE].Id;
                
                // read the OS
                String agent = NetworkingUtils.getOSFromUserAgent(userAgent);               
                String userSourceExtra = populateUserSourceExtra(userAgent);
              
                Case newCase = new Case( Status= NEW_Closed, Closed_Reason__c= LIVE_CHAT, RecordTypeId =caseRecordTypeId, User_Source__c = agent, User_Source_Extra__c = userSourceExtra, User_Agent__c = userAgent,
                                        Origin= LIVE_CHAT , Posting_Reference__c= AdRef , ContactId = conId, Description = description );                
                
                //case opt in field
                newCase.Livechat_Transcript_Email_Opt_in__c = Boolean.valueOf(emailOptOut);
                insert newCase;    
                mapResult.put( CASE_ID ,newCase.id);   
                mapResult.put( RESULT_STATUS ,'false');    
                                
            }catch(Exception e){                
                mapResult.put( ERROR_STATUS ,e.getMessage() ); 
            } 
        return mapResult;   
     }
     
    
     
     @remoteAction
     global static Map<String,String> updateCaseOwner( string caseId,String ownerId, String conId){
            Map<String,String> mapResult = new Map<String,String>();
            try{
                Case caseOwnerUpdate =[select id,ownerId from Case where id= : caseId];
                caseOwnerUpdate.ownerId = ownerId;              
                update caseOwnerUpdate;
                
                //update isChatting__c=true during contact is online
                Contact con = [select  Id, IsChatting__c from Contact where Id =:conId AND IsChatting__c=false];
                if(con !=null){
                    con.IsChatting__c = true;
                    update con;
                }
                mapResult.put( RESULT_STATUS ,'Success' );  
                return mapResult;
            }catch(Exception e){                
                 //mapResult.put( ERROR_STATUS ,e.getMessage() );   
                // mapResult.put( RESULT_STATUS ,'Error' );
                  return mapResult;
            } 
         
     }
                 
     /**
      * PN: Task #3109 - Populate custom check box field and contact Id on live chat transcript object
      * Called From trigger LiveChatTranscriptFromCase
      */
     public static void PopulateLiveChatTranscriptFields(List<LiveChatTranscript> lctran){
        Set<String> caseIds = new Set<String>();
        For(LiveChatTranscript tran : lctran){
            if(tran.CaseId != null) caseIds.add(tran.CaseId);
        }
        Map<Id, Case> mCase = new Map<Id, Case>([Select Id, ContactId, Contact.FirstName, Contact.LastName, Livechat_Transcript_Email_Opt_in__c ,User_Source__c  From Case Where Id IN: caseIds]);
        
        for (LiveChatTranscript liveChatTran : lctran){
            
            if(liveChatTran.CaseId == null || mCase.get(liveChatTran.CaseId) == null) continue;
            Case caseRec = mCase.get(liveChatTran.CaseId);
            liveChatTran.Live_Chat_Transcripts_Email_Opt_in__c = caseRec.Livechat_Transcript_Email_Opt_in__c;
            //liveChatTran.ContactId = caseRec.ContactId;
            //liveChatTran.Contact__c = caseRec.ContactId;
            //liveChatTran.Case__c = caseRec.Id;
            liveChatTran.FirstName__c = caseRec.Contact.FirstName;
            liveChatTran.LastName__c = caseRec.Contact.LastName;
            
         }
      }
      
    /**
      * MS: Task #3550 - user source extra information from Live Chat
      * Called From trigger LiveChatTranscriptFromCase
      */
      public static void updateCaseUserSource(List<LiveChatTranscript> lstLCT){
        set<String> setCaseIDs = new Set<String>();
        List<Contact> contact2beupdate = new List<Contact>();
         
        for(LiveChatTranscript lct : lstLCT){
            if(lct.CaseId != null) setCaseIDs.add(lct.CaseId);
        }
        
        Map<Id, Case> mapCase = new Map<Id, Case>([Select Id, User_Source__c, User_Source_Extra__c, Origin, Contact.IsChatting__c  From Case Where Id IN: setCaseIDs]);
        
        for(LiveChatTranscript livechart : lstLCT){
            if(livechart.CaseId != null) {
                Case c = mapCase.get(livechart.CaseId);
                
                if (c!=null) {
                    c.User_Source__c = livechart.Platform;
                    c.IP_Address__c = livechart.IpAddress;
                    c.User_Agent__c = livechart.UserAgent;
                    //c. - = livechart.Location;  
                    
                    c.User_Source_Extra__c = populateUserSourceExtra(livechart.UserAgent);
                    
                    //to prevent isChatting__c = true when chat end
                    if(c.Origin == 'Live Chat' && c.Contact.IsChatting__c){
                        c.Contact.IsChatting__c = false;
                        contact2beupdate.add(c.Contact);
                    }
                    
                }   
            }
        }
        update contact2beupdate;
        update mapCase.values();
      }
      
      //Task#4472: User source extra information -GTCRM-771
      public static String populateUserSourceExtra(String agent){

        if(!String.isBlank(agent)){
            UAgentInfo ui = new UAgentInfo(agent);
            
            if(ui.isMobilePhone){
                return 'Mobile';
            }
            else if(ui.isTierTablet){
                return 'Tablet';
            }
            else if(ui.isDesktop){
                return 'Desktop';
            }
        } 
        return 'Unknown';
        
      
      }
      

// - 2014-11-19 - GTCRM-1567 - GT Help Alerts on live chat pre chat form         
    public List<PKB_Status_Message__c> msgErr {
        get {
            List<PKB_Status_Message__c> systemMsg = new List<PKB_Status_Message__c>(); 
            for(PKB_Status_Message__c sm: [SELECT MessageText__c, Message_Type__c, Message_Start_DateTime__c, Message_End_DateTime__c 
                                                  FROM PKB_Status_Message__c
                                                 WHERE Status__c = 'Active'
                                                 // 2014-12-04 - GTCRM-1232 - Update existing help site alerts to only show for Help record type
                                                 AND RecordType.Name = 'Help'
                                                  AND ((Message_Start_DateTime__c < :system.now() AND
                                                        Message_End_DateTime__c   > :system.now())
                                                  OR   (Message_Start_DateTime__c = null AND
                                                        Message_End_DateTime__c   = null)) order by CreatedDate desc
                                                  ]){
                   systemMsg.add(sm);
                 //System.debug('XXXXX sm-->' + sm);
            }
            return systemMsg;
        } 
        set;
    }
    
     @remoteAction
     global static Map<String,String> updateContactChatStatus(String conId){//updateContactChatStatus(String conId, String fromPostChat)
        Map<String,String> mapResult = new Map<String,String>();
        
     
            try{
                Contact con = [select  Id, IsChatting__c from Contact where Id =:conId AND IsChatting__c=true];
                if(con !=null){
                    con.IsChatting__c = false;
                    update con;
                    mapResult.put( RESULT_STATUS ,'Success' );
                }
                return mapResult;
            }catch(Exception e){
                mapResult.put( RESULT_STATUS ,'Error' );
                return mapResult;
            }
       
     }
    
     
}