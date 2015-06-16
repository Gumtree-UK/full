/**
 * GTCRM-1735 - Ability for sales to take an upfront payment on opportunity
 * @author: Steve Paul
 * @createdDate: 23-Mar-2015
 *
 * Change log : 

 */
public without sharing class OppBraintreePayment{
    public Decimal totalVat {get;set;}
    public Decimal totalAmount {get;set;}
    public Decimal totalSub {get;set;}
    public Decimal totalPrice {get;set;}
    private Opportunity opp;
    public List<Braintree_Vault__c> lstBV{get;set;}
    public String paymentId{get;set;}
    public boolean isErrorTrans{get;set;}
    public String errorMsg{get;set;}
    public String accid {get;set;}
    public String IOnumber {get;set;}
    private static String GUMTREE = 'Gumtree';
    private static String CURRENCY_CODE = 'GBP';
    public String client_token{get;set;}
    public String methodnonce{get;set;}
    public String paypal_email{get;set;}
    public String selectPaypal{get;set;}
    public boolean isCallbyPaypal{get;set;}
    public String refURL{get;set;}
    public OppBraintreePayment(){
        init();
    }
    
    private void init(){
        requestToken();
        refURL = Apexpages.currentPage().getParameters().get('refurl');
        String oppId = Apexpages.currentPage().getParameters().get('opp');
        opp = [Select Amount_Net_Net_Inc_VAT__c,
                            Account.Id,
                            IOnumber__c,
                            Payment_Token__c,
                            Last_Payment_Taken__c,
                            VAT_Amount__c,
                            Net_Net__c
                            From Opportunity
                            Where id = :oppId
                            ];
        totalSub = opp.Net_Net__c;
        totalVat = opp.VAT_Amount__c;
        totalPrice = opp.Amount_Net_Net_Inc_VAT__c;
        totalAmount = totalPrice;
        accid = opp.Account.Id;
        IONumber = opp.IOnumber__c;
    }
    
    /**
     *  Method Pay by Card
     */
    public Pagereference doPayByCard(){
        lstBV = [Select Payment_Type_value__c, PaymentType__c,PaymentToken__c,Masked_card_number__c,Paypal_Email__c From Braintree_Vault__c where status__c = 'active' and Account__c =:accId/*'0011100000bN9SOAA0'*/ and PayPal_email__c = null]; 
        return null;
    }
    
    /**
    * Method Pay by Paypal
    */
    public Pagereference doPayByPaypal(){
        lstBV = [Select Payment_Type_value__c, PaymentType__c,PaymentToken__c,Masked_card_number__c,Paypal_Email__c From Braintree_Vault__c where status__c = 'active' and Account__c =:accId /*'0011100000bN9SOAA0'*/ and PayPal_email__c !=null];
        return null;
    }

    /**
     * Create transaction to Braintree.
     */
    public PageReference doTransaction(){
        Braintree_Vault__c bv = [Select PaymentToken__c, Payment_Type_Value__c, Account__c from Braintree_Vault__c where id =:paymentId];
        Fiqas_Settings__c FS = Fiqas_Settings__c.getInstance('Braintree_Webservice');
        P2P_tempuriOrg.BasicHttpBinding_IBrainTreeCollectionService service = new P2P_tempuriOrg.BasicHttpBinding_IBrainTreeCollectionService ();
        String token = service.Login(FS.User__c,FS.Key__c);
        P2P_schemasDatacontractOrg.BrainTreeCollectionServiceResult result = service.InitiatePayment(token, GUMTREE, bv.PaymentToken__c, totalAmount, CURRENCY_CODE, opp.IOnumber__c);
        errorMsg = result.Message;
        isErrorTrans = !(result.Succes);
        System.debug('Trans result>>>>>>>>'+result.Message);
        System.debug('result.Succes>>>>>>>>'+result.Succes);
        
        //Update invoice
        if(result.Succes){
            opp.Payment_Method__c = bv.Payment_Type_Value__c.equalsIgnoreCase('PayPal')?'PayPal':'Credit/Debit Card';
            opp.Payment_Token__c = bv.Id;
            opp.Last_Payment_Taken__c = datetime.now();
            update opp;
        }
        //Save to error log
        saveErrorLog(result.Succes,result.Message);
        
      return null;
    }  
    
    /**
     * Delete payment method
     * @param token is the payment token to be delete at braintree
     */
    public PageReference doDeletePayment(){
      P2P_BraintreeServices btServices = new P2P_BraintreeServices();
      Braintree_Vault__c bv = [Select Id,PaymentToken__c, Status__c from Braintree_Vault__c where id =:paymentId];
      P2P_BraintreeServices.CreditCartParser ccParser = btServices.deleteCreditCard(bv.PaymentToken__c);
      bv.Status__c = 'inactive';
      update bv;
      return null;
    }
      
      /**
       * get client token from braintree server
       */
      public void requestToken(){
        P2P_BraintreeServices btServices = new P2P_BraintreeServices();     
        P2P_BraintreeServices.ClientTokenParser ctParser = btServices.getClientToken();
        client_token = ctParser.clientToken;
      }
      
      /**
       * Create payment with paypal
       */
      public PageReference createPaymentPaypal(){       
        P2P_BraintreeServices btServices = new P2P_BraintreeServices();
        Boolean isInsertBV = true;
        
        //Braintree_Customer_ID__c, BraintreeActiveFrom__c, EncryptedBTCustToken__c
        Account acc = [ Select  Id, Name, Finance_contact__r.Email, Finance_contact__r.Phone From Account Where Id = :accId];
        
        // Second request (Create a customer) when the button clicked
        P2P_BraintreeServices.CustomerParser cuParser = btServices.createCustomer(methodnonce, '', acc, false);              
        String paymentToken = cuParser.defaultPaymentMethodToken;
        Boolean def = cuParser.defaultToken;
        
        if(cuParser.isError){
            // if Creating a customer fail, create a new payment method
            P2P_BraintreeServices.CreditCartParser ccParser = btServices.createCreditCard(methodnonce, '', acc.id, false);              
            paymentToken = ccParser.token; 
            def = ccParser.defaultToken;
            isInsertBV = !ccParser.isError;
        }
        if(isInsertBV){
            Braintree_Vault__c bv = new Braintree_Vault__c();
            bv.Payment_Type_Value__c = 'PayPal';
            bv.Account__c = accId;
            bv.PaymentToken__c = paymentToken;
            bv.DefaultToken__c = def;
            bv.PayPal_email__c = paypal_email;
            insert bv;
            selectPaypal = bv.id;
            lstBV = [Select Payment_Type_value__c, PaymentType__c,PaymentToken__c,Masked_card_number__c,Paypal_Email__c From Braintree_Vault__c where status__c = 'active' and Account__c =:accId /*'0011100000bN9SOAA0'*/ and PayPal_email__c !=null];
        }
        return null;
      }
      
      /**
       * Save to Error_Log
       */
        private void saveErrorLog(boolean isSuccess,String msg){
            ErrorLog__c error = new ErrorLog__c();
            if(isSuccess){
                //success
                error.details__c = msg+' - Payment processed for �'+opp.Amount_Net_Net_Inc_VAT__c;
                error.Related_Id__c = opp.Id;
                error.Type__c = 'OppUpfrontPayment';
                error.Result__c = 'Success';
                error.Action__c = 'Create';
                error.Status__c = 'Completed';
                error.Integration__c = 'Braintree';
            }else{
                //error
                error.details__c = msg;
                error.Related_Id__c = opp.Id;
                error.Type__c = 'OppUpfrontPayment';
                error.Result__c = 'Error';
                error.Action__c = 'Create';
                error.Status__c = 'Completed';
                error.Integration__c = 'Braintree';
            }
            insert error;            
        }
}