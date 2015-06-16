global class P2P_MySupport_ChatController {
    
	private static final String New_Closed='Closed';
	private static final String LIVE_CHAT='Live Chat';
    private static final String CUSTOMER_SERVICE='Customer_Services';
    private static final String FINANCE_SUPPORT = 'Finance_Support';
    private static final String RESULT_STATUS='Result';
    private static final String CASE_ID='CaseId';
    private static final String ERROR_STATUS='Error';
    private static final String CONTACT_ID='PreChatConId';
    
    public String getCustomer_Services(){
    	return CUSTOMER_SERVICE;	
    }
    
    public String getFinance_Support(){
    	return FINANCE_SUPPORT;
    }
    
    @remoteAction
    global static Map<String,String> checkIsEmailExist( String email,String AdRef, String emailOptOut,String description, String deployment){
		List<contact> contacts = [select  Id, Live_Agent_Block__c from contact where email = :email limit 1];
		Map<String,String> mapResult = new Map<String,String>();           
		try{    
        	String conId = '';             
            //case New Email create contact
            if(contacts.isEmpty()) {
                //create new contact                
                contact newContact = new contact(Email = email, LastName = email);
                insert newContact;  
                conId = newContact.id;
            }else{ 
                //case existing email               
                conId = contacts[0].id;                 
            }
             
            mapResult.put(CONTACT_ID ,conId);   
             
            if(!contacts.isEmpty() && contacts[0].Live_Agent_Block__c){ 
               //case user blocked             
                mapResult.put( RESULT_STATUS , +'true');
                return mapResult;   
            }
            
            //create new case
            String newCaseRec = CUSTOMER_SERVICE == deployment ? CUSTOMER_SERVICE : FINANCE_SUPPORT;
            List<RecordType> lstRecords= [Select id From RecordType r where SobjectType='Case' and DeveloperName = :newCaseRec];
            Case newCase = new Case( Status= NEW_Closed, Closed_Reason__c= LIVE_CHAT, RecordTypeId =lstRecords.get(0).id, 
                                     Origin= LIVE_CHAT, ContactId = conId, Description = description );                
            
            if(CUSTOMER_SERVICE == deployment) newCase.Posting_Reference__c = AdRef;
            else if(FINANCE_SUPPORT == deployment)  newCase.Invoice_Number__c = AdRef;
            
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
	global static Map<String,String> updateCaseOwner( string caseId,String ownerId){
		Map<String,String> mapResult = new Map<String,String>();
		try{
            Case caseOwnerUpdate =[select id,ownerId from Case where id= : caseId];
            caseOwnerUpdate.ownerId = ownerId;              
            update caseOwnerUpdate;
            mapResult.put( RESULT_STATUS ,'Success' );  
            return mapResult;
        }catch(Exception e){                
            mapResult.put( ERROR_STATUS ,e.getMessage() );   
            mapResult.put( RESULT_STATUS ,'Error' );
			return mapResult;
		} 
	}
}