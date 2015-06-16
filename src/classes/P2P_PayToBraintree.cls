/**
 *	This class is used as controller for page P2P_PayToBraintree.page.
 *	Its handle creattion customer and payment method at Braintree.
 *
 *	@author Kakada KHAN
 *	@date 02-Feb-2015
 *
 * Log:
   		- Bunhor @11-May-15: set bv.Expiration_Date__c 
 */
public class P2P_PayToBraintree {
    /** Parameter for get error from URL*/
    public static final String PARAM_ERR = 'BTerrors';
    /** Parameter for get account ID from URL*/ 
    public static final String PARAM_ACCID = 'ccregaccid';
	/** Parameter for get Account ID use in Controller*/
    public String accIdParamName {get{return PARAM_ACCID;}}
    /** Return client token to web form*/
    public String client_Token{get;set;} 
    /** Stroe account Id to use in controller*/ 
    public String accId{get;set;}
    /** The message to display on page*/
    public String message{get;set;}
    private String pId;
    
    /**
     * Constructor
     * Initailize variables value.
     */
    public P2P_PayToBraintree(){
        // The correct accId is always embaded in the URL
        accId = ApexPages.currentPage().getParameters().get(accIdParamName);                
        // For: The page redirect and load again when creating a new customer with errors ( Reload to get new client token)
        String theErr = ApexPages.currentPage().getParameters().get(PARAM_ERR); 
        //Display the message on page load
        displayError(theErr);
    } 
    
    /**
     * This method is the ActionMethod of the Page
     * It will do one of the following:
     *    - Request ClientToken from BrainTree whenever the page first load
     *    - Request Creating a new Customer/CreditCard at BrainTree whenever the page reload after clicking the form button
     * @return Pagereference
     */
    public Pagereference actionMethod(){
    	// If the Client-Token request success, these params will exist. 
        String paymentMethodNonce = ApexPages.currentPage().getParameters().get('payment_method_nonce');
        String holderName = ApexPages.currentPage().getParameters().get('holderName');
    	
    	// Service object  
        P2P_BraintreeServices btServices = new P2P_BraintreeServices();
    	
    	// The page first load --------------------------  
        if(paymentMethodNonce == null || holderName == null) {
            // First request (Client Token) when the page loaded 
            P2P_BraintreeServices.ClientTokenParser ctParser = btServices.getClientToken();
            client_Token = ctParser.clientToken;
            // Handle Error
            if(ctParser.isError){
                displayError(ctParser.errorMsg);
            }
        // The page reload ----------------------------
        }
        else{
        	Boolean isInsertBV = true;
        	
        	//Braintree_Customer_ID__c, BraintreeActiveFrom__c, EncryptedBTCustToken__c
            Account acc = [ Select  Id, Name, Finance_contact__r.Email, Finance_contact__r.Phone From Account Where Id = :accId];
            
            // Second request (Create a customer) when the button clicked
            P2P_BraintreeServices.CustomerParser cuParser = btServices.createCustomer(paymentMethodNonce, holderName, acc, true);              
            String paymentToken = cuParser.defaultPaymentMethodToken;
            String pURL = cuParser.paymentURL;
            String mask = cuParser.masked;
            Boolean def = cuParser.defaultToken;
            String cardType = cuParser.cardType;
            Date expiredDate = cuParser.getCardExpiredDate();
            
            String errorMsg = cuParser.errorMsg;    
            if(cuParser.isError){
                // if Creating a customer fail, create a new payment method
                P2P_BraintreeServices.CreditCartParser ccParser = btServices.createCreditCard(paymentMethodNonce, holderName, acc.id, true);              
                paymentToken = ccParser.token; 
                pURL = ccParser.paymentURL;
            	mask = ccParser.masked;
            	def = ccParser.defaultToken;
            	cardType = ccParser.cardType;
            	isInsertBV = !ccParser.isError;
				errorMsg = ccParser.errorMsg;
				expiredDate = ccParser.expiredDate;
            }
            
            if(isInsertBV && !Test.isRunningTest()){
            	errorMsg = 'ok';
            	Braintree_Vault__c bv = new Braintree_Vault__c();
				bv.Account__c = acc.Id;
				bv.Payment_Type_Value__c = cardType;
				bv.PaymentToken__c = paymentToken;
				bv.DefaultToken__c = def;
				bv.Masked_card_number__c = mask; 
            	bv.Expiration_Date__c = expiredDate;
	        	insert bv;
	        	pId = bv.Id;
            }
             //put error to URL-------
            if(!String.isBlank(errorMsg)){ 
                Pagereference pg = Page.P2P_PayToBraintree; 
                pg.getParameters().put(accIdParamName, acc.Id);
                pg.getParameters().put(PARAM_ERR, errorMsg);
                pg.getParameters().put('pId', pId);
                pg.setRedirect(true); 
                return pg;
            }
        }
        return null;
    }

    /**
     * Method to display message on page load
     * @param msg the message to be display
     */  
    public boolean cardSuccess {get;set;}   
    private void displayError(String msg){
        message=msg;
        String status = ApexPages.currentPage().getParameters().get(PARAM_ERR); 
        String id = ApexPages.currentPage().getParameters().get('pId');     
        if(String.isBlank(msg)) message='';
        else if(status == 'ok'){
        	message = id;
        	cardSuccess = true;
        }
    }
    
}