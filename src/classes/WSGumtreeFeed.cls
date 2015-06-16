/**
* This class will provide a webservice method that called from 2 links ("Check Link", "Link User") from Account detail page.
* The webservice method will called to out side webservices (gumtree & ebaymotorspro).
*
* @author Bunhor
* @date 08-Oct-14 

Change log;
- 2015-05-08 - GTCRM-1924 - Enhance API error logs with greater detail 
- 2015-05-13 - GTCRM-1997 - Motors eMP Link Button - Increase timeout window

*/ 
global class WSGumtreeFeed{
    
    /** Gumtree endpoint */
    private static final String END_POINT_GUMTREE='https://inbound.gumtree.com/api/users/';
    /** eBay Motors Pro endpoint */
    private static final String END_POINT_EBAYMOTORPRO='https://api.ebaymotorspro.co.uk:443/emp/soap/gumtreeApi/v1';
    /** Action to do is  check link */
    public static final String ACTION_CHECK_LINK = 'checklink';
    /** Action to do is  link user */
    public static final String ACTION_LINK_USER = 'linkuser';
    /** Feed Provider */
    public static final String FEED_USER_EBAY_MOTORS_PRO = 'eBay Motors Pro';
    /** Feed Provider */
    private static String user_pass;
    /** For testing, mock response */
    private static HttpResponse mockResponse;
    // 2015-05-13 - GTCRM-1997 - Motors eMP Link Button - Increase timeout window
    public static Integer TIMEOUT = 120000;
    
    /** For store ErrorLog__c**/
    //HCS 08.05.2015
    private static List<ErrorLog__c> errors = new List<ErrorLog__c>();
    
    /**
    *  Return the result of the request.
    *  
    * @param FeedProvider is Account.Feed_Provider__c 
    * @param AccNumber is Account.AccountNumber
    * @param MPAccNumber is Account.eMP_Account_Number__c
    * @param Action tells what action to do. 
    * @return String  
    */ 
    webService static String linkGumtree(String FeedProvider, String AccNumber, String MPAccNumber, String Action){
        
        if(String.isBlank(FeedProvider) || String.isBlank(AccNumber) || (FeedProvider == FEED_USER_EBAY_MOTORS_PRO && String.isBlank(MPAccNumber))){
            String feedStatus = FeedProvider == FEED_USER_EBAY_MOTORS_PRO ? 'Missing account name, account id or eMP id' : 'Missing account name or account id';
            String errorType = Action == ACTION_CHECK_LINK ? GUMTREE_CHECK_LINK : GUMTREE_ACCOUNT_LINK;
            String actionType = Action == ACTION_CHECK_LINK ? GET_ACTION : UPDATE_ACTION;
            futureCreateErrorLog.createErrorRecordDetails(feedStatus , AccNumber , errorType, actionType,  ERROR_STATUS , COMPLETED, GUMTREE );
            return feedStatus;
        }
        
        // Getting custom setting user and password
        Credential__c csUserPass = Credential__c.getValues('WSGumtreeFeed');
        user_pass = csUserPass==null? '' : (csUserPass.get('User__c') +':'+ csUserPass.get('Password__c'));
        
        // Getting custom setting records
        Map<String, WSGumtreeFeed__c> mapCS = new Map<String, WSGumtreeFeed__c>();
        for(WSGumtreeFeed__c cs : WSGumtreeFeed__c.getall().values()){
             mapCS.put((cs.Name+'').tolowercase(), cs);
        }
         
        WSGumtreeFeed__c cs = mapCS.get(FeedProvider.tolowercase());
        if(cs == null){
            String errorStatus = 'This feed provider has not been added to the custom settings. Please contact your system administrator.';
            String errorType = Action == ACTION_CHECK_LINK ? GUMTREE_CHECK_LINK : GUMTREE_ACCOUNT_LINK;
            String actionType = Action == ACTION_CHECK_LINK ? GET_ACTION : UPDATE_ACTION;
            futureCreateErrorLog.createErrorRecordDetails( errorStatus , AccNumber , errorType, actionType,  ERROR_STATUS , COMPLETED, GUMTREE );
            return errorStatus;
        }
          
        String result = '';
         
        if(Action == ACTION_CHECK_LINK){
            // Check Link------------ 
            result = checkLinkGumtree(cs, AccNumber);  
        }else{
            // Link User--------------
            result = addLink(FeedProvider, cs, AccNumber, MPAccNumber); 
        }
       
        logErrors();
        
        return result;
    }
    
    /* For Insert ErrorLog__c*/
     private static  void logErrors() {
        for (ErrorLog__c error : errors) {
            Database.insert(error,false);
        }
    }
    
    private static final String COMPLETED='Completed';
    private static final String GUMTREE='Gumtree';
    private static final String SUCCESS_STATUS='Success';
    private static final String ERROR_STATUS='Error';
    private static final String UPDATE_ACTION='Update';
    private static final String GET_ACTION='Get';
    private static final String GUMTREE_CHECK_LINK = 'feedCheckLink';
    private static final String GUMTREE_ACCOUNT_LINK = 'feedAccountLink';
    
    /**
    *  Check link (callout) and return the result.
    *  
    * @param cs is a custom setting record.
    * @param AccNumber is Account.AccountNumber 
    * @return String  
    */ 
    private static String checkLinkGumtree(WSGumtreeFeed__c cs, String AccNumber){  
        HttpResponse res = callOut(END_POINT_GUMTREE + cs.Id__c,'GET', null);
        
        if(res.getStatusCode()!=200){
            errors.add( futureCreateErrorLog.createErrorLog(  res.getBody() , cs.id , GUMTREE_CHECK_LINK  , GET_ACTION ,  ERROR_STATUS  , COMPLETED , GUMTREE));   
            return 'Error code (Gumtree): '+res.getStatusCode();  
        }
        ResCheckLink obj =(ResCheckLink) System.JSON.deserialize(res.getBody(), ResCheckLink.class); 
        for(String id : obj.account_ids){ 
            if(id.trim().toLowerCase()==AccNumber.trim().toLowerCase()){
                //if(id.trim().toLowerCase()==(cs.Id__c+'').trim().toLowerCase())
                errors.add( futureCreateErrorLog.createErrorLog(  '' , cs.id , GUMTREE_CHECK_LINK  , GET_ACTION ,  SUCCESS_STATUS  , COMPLETED , GUMTREE)); 
                return 'Success, the account is now linked to Gumtree';
            }
        } 
        
        errors.add( futureCreateErrorLog.createErrorLog(  'Error, the account has not been linked' , cs.id , GUMTREE_CHECK_LINK , GET_ACTION ,  ERROR_STATUS  , COMPLETED , GUMTREE)); 
        return 'Error, the account has not been linked';
    }
    
    /**
    *  Add link (callout to Gumtree or ebaymotorspro) and return the result of the request.
    *  
    * @param FeedProvider is Account.Feed_Provider__c 
    * @param cs is a custom setting record.
    * @param AccNumber is Account.AccountNumber
    * @param MPAccNumber is Account.eMP_Account_Number__c 
    * @return String  
    */
    private static String addLink(String FeedProvider, WSGumtreeFeed__c cs, String AccNumber, String MPAccNumber){
        // called to 'Gumtree webservice'
        String addResult = addLinkGumtree(cs, AccNumber);
        
        if(FeedProvider == FEED_USER_EBAY_MOTORS_PRO){ 
            String errorMessage ='';
            String status = SUCCESS_STATUS;
            // called to 'eBay Motors Pro' webservice
            HttpResponse res = callOut(END_POINT_EBAYMOTORPRO, 'POST', getReqBody( AccNumber, MPAccNumber));
            if(res.getStatusCode()==200){       // The request was fulfilled.
                addResult =  'Success, the account is now linked to eBay Motors PRO';
            }else if(res.getStatusCode()==500){ //The server encountered an unexpected condition which prevented it from fulfilling the request.
                errorMessage = res.getBody();
                status = ERROR_STATUS;
                addResult = 'Error, the account has not been linked to eBay Motors PRO: ' + getErr500(res.getBody()+'');
            }else{
                status = ERROR_STATUS;
                errorMessage = res.getBody();
                addResult = 'Error code (eBay Motors Pro): '+res.getStatusCode();
            } 
            
            errors.add( futureCreateErrorLog.createErrorLog( errorMessage , cs.id , GUMTREE_ACCOUNT_LINK  , UPDATE_ACTION ,  status  , COMPLETED , GUMTREE)); 
        }
        return addResult;
    }
     
    /**
    *  Return the faulty string of error response code 500 in XML format
    *  
    * @param xmlRes XML response code = 500  
    * @return String  
    */
    private static String getErr500(String xmlRes){
        DOM.Document doc = new DOM.Document();
        doc.load(xmlRes);
        
        DOM.XMLNode err = getNode(doc.getRootElement(), 'Envelope', 'Envelope/Body/Fault/faultstring');
        return err.getText();
    }
    
    /**
    *  Return a Node with the specified path
    *  
    * @param xmlRes root Root node
    * @param xmlRes rootName Root name
    * @param xmlRes xPath Path to the note that we want to get Ex: Envelope/Header/Body/Fault/faultstring
    * @return DOM.XMLNode  
    */
    private static DOM.XMLNode getNode(DOM.XMLNode root, String rootName, String xPath){  
        DOM.XmlNode tmp;
        
        if(root == null || String.isBlank(xPath) || rootName.equals(xPath)){
            tmp = root;
        }else{
            for(DOM.XMLNode node : root.getChildElements()){ 
                if(tmp == null) tmp = getNode (node, rootName + '/' + node.getName(), xPath);
                else break;
            }
        }
        return tmp;  
    }
    
    /**
    *  Add link (callout to Gumtree) and return the result of the request.
    *  
    * @param cs is a custom setting record.
    * @param AccNumber is Account.AccountNumber
    * @return String  
    */
    private static String addLinkGumtree(WSGumtreeFeed__c cs, String AccNumber){
        String encodedEmail = EncodingUtil.urlEncode(cs.Email__c, 'UTF-8');  
        HttpResponse res = callOut(END_POINT_GUMTREE + encodedEmail + '/accounts/' +AccNumber+ '/add', 'POST', null);
        //HttpResponse res = callOut(END_POINT_GUMTREE + encodedEmail + '/accounts/' +cs.Id__c+ '/add', 'POST', null);
        if(res.getStatusCode()!=200) {
                errors.add( futureCreateErrorLog.createErrorLog( res.getBody() , cs.id , GUMTREE_ACCOUNT_LINK  , UPDATE_ACTION ,  ERROR_STATUS   , COMPLETED , GUMTREE)); 
                return 'Error code (Gumtree): '+res.getStatusCode();  
        }
        errors.add( futureCreateErrorLog.createErrorLog( '' , cs.id , GUMTREE_ACCOUNT_LINK  , UPDATE_ACTION ,  SUCCESS_STATUS   , COMPLETED , GUMTREE)); 
        return checkLinkGumtree(cs, AccNumber); 
    }
    
    /**
    *  Getting request body for calling to ebaymotorspro.
    *  
    * @param AccNumber is Account.AccountNumber
    * @param MPAccNumber is Account.eMP_Account_Number__c  
    * @return String  
    */
    private static String getReqBody(String AccNumber, String MPAccNumber){
        return  '<?xml version="1.0" encoding="UTF-8"?>'+
                '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:wsse="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd" xmlns:v1="http://api.ebaymotorspro.co.uk/soap/gumtreeApi/v1">'+
                '<soapenv:Header><wsse:Security><wsse:UsernameToken><wsse:Username>gumtreeCS</wsse:Username><wsse:Password Type="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-username-token-profile-1.0#PasswordText">0r1twgFT0627uA0o</wsse:Password></wsse:UsernameToken></wsse:Security></soapenv:Header>'+
                '<soapenv:Body><v1:SetGumtreeAccountIdRequest><v1:CustomerId>' + MPAccNumber + '</v1:CustomerId><v1:GumtreeAccountId>' + AccNumber + '</v1:GumtreeAccountId></v1:SetGumtreeAccountIdRequest></soapenv:Body>'+
                '</soapenv:Envelope>'; 
    }
    
    /**
    *  For generatting HttpRequest and returning the HttpResponse.
    *  
    * @param endpoint URL endpoint
    * @param httpMethod POST or GET 
    * @param body the body of the request (in case POST)
    * @return HttpResponse  
    */
    private static HttpResponse callOut(String endpoint,String httpMethod, String body){
    
           HttpRequest req = new HttpRequest();  
           req.setEndpoint(endpoint);  
           req.setMethod(httpMethod); 
           //HCS: 14-05-2014: resolved time out GumtreeAPI.TIMEOUT
           req.setTimeout(GumtreeAPI.TIMEOUT);         
           //TODO get user and password of the webservice from custom setting
           Blob headerValue = Blob.valueOf(user_pass);
           String authorizationHeader = 'Basic ' + EncodingUtil.base64Encode(headerValue);        
           req.setHeader('Authorization',authorizationHeader);       
     
           if(!String.isBlank(body)){
                req.setHeader('Content-Type', 'text/xml');
                req.setBody(body);  
           } 
           
           Http http = new Http();
           return Test.isRunningTest()? mockResponse : http.send(req); 
    }
    
    /**
    *  For using in test class
    *  
    * @param acc : the Account
    * @param action : Action can be 'checklink' or 'linkuser'
    * @param resp : the mock response
    * @return String  
    */
    public static String methodForTest(Account acc, String action, HttpResponse resp){
        mockResponse = resp;
        return linkGumtree(acc.Feed_Provider__c, acc.AccountNumber, acc.eMP_Account_Number__c, action); 
    }
    
    /**
    * Used for System.JSON.deserialize() method when getting response from Gumtree's check link request. 
    */  
    public class ResCheckLink{
        public Integer id;  //53458489
        public String type; //PRO
        public String email;    //amonroe@ebay.com
        public String phone;    //00353877787033
        public String first_name;   //Gumtree user
        public String last_name;    //Murphy
        public boolean phone_verified;
        public boolean captcha_verified;
        public boolean known_good;
        public String known_good_reason;    //ACCOUNT_HOLDER
        public APIKey api_key;
        public String[] account_ids;
        public String status;   //ACTIVE
        public boolean opt_in_marketing;
        public boolean in_bushfire;
        public boolean super_user;
        public String posting_since;    //2007-06-24T14:03:15Z
        public String created_date; //2011-01-01T00:00:00Z 
    } 
    
    /**
    * Used for System.JSON.deserialize() method when getting response from Gumtree's check link request. 
    */ 
    public class APIKey{
        public String access_key;   //6e991da16a30da0b1b96a3ee084f5722
        public String private_key;  //140d6901052e5ac7d48022756cffd200
    }
}