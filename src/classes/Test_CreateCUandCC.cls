public class Test_CreateCUandCC {
    public static final String PARAM_ERR = 'BTerrors';
    public static final String PARAM_ACCID = 'accid';
    public String accIdParamName {get{return PARAM_ACCID;}}
    public String client_Token{get;set;} 
    public String accId{get;set;}
    public String message{get;set;}
    
    private Account acc;
    public Test_CreateCUandCC(){
        accId = ApexPages.currentPage().getParameters().get(accIdParamName);                
        String theErr = ApexPages.currentPage().getParameters().get(PARAM_ERR); 
        acc = [ Select  Id, Name, Finance_contact__r.Email, Finance_contact__r.Phone From Account Where Id = :accId];
        //displayError(theErr);
    } 

    public Pagereference actionMethod(){
        String paymentMethodNonce = ApexPages.currentPage().getParameters().get('payment_method_nonce');
        String holderName = ApexPages.currentPage().getParameters().get('holderName');
    	
        P2P_BraintreeServices btServices = new P2P_BraintreeServices();
    	
        if(paymentMethodNonce == null || holderName == null) {
            P2P_BraintreeServices.ClientTokenParser ctParser = btServices.getClientToken();
            client_Token = ctParser.clientToken;
            /*
            if(ctParser.isError){
                displayError(ctParser.errorMsg);
            }*/
        }
        else{
                String res = btServices.testCreateCreditCard(paymentMethodNonce, holderName, acc.id, true);    
                
                ErrorLog__c error = new ErrorLog__c();
				error.details__c = res;
				error.Related_Id__c = acc.id;
				error.Type__c = 'CreateCreditCardLog';
		    	
		    	insert error;
		    	
                Pagereference pg = Page.Test_CreateCUandCC; 
                pg.getParameters().put(accIdParamName, acc.Id);
                pg.setRedirect(true); 
                return pg;
        }
       return null;
    }
    public PageReference createCustomer(){
    	P2P_BraintreeServices btServices = new P2P_BraintreeServices();
    	String res = btServices.testCreateCustomer(acc);
    	
    	ErrorLog__c error = new ErrorLog__c();
		error.details__c = res;
		error.Related_Id__c = acc.id;
		error.Type__c = 'CreateCustomerLog';
    	
    	insert error;
    	
    	Pagereference pg = Page.Test_CreateCUandCC; 
        pg.getParameters().put(accIdParamName, acc.Id);
        pg.setRedirect(true); 
        return pg;
    }

}