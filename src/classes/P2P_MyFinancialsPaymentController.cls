/**
 * Task : My financials payment
 * @author: Steve Paul
 * @createdDate: 23-Dec-2014
 *
 * Change log : 
 * - Task #4086 : GTCRM-1291- PRO-M1- My Financials - Look and Feel To Front-end user, modifiedDate : 25-Dec-2014 by Pheaktra Hun
 */
public without sharing class P2P_MyFinancialsPaymentController {
    
    public List<InvoiceItem>lstInvs{get;set;}
        
    public Decimal totalVat {get;set;}
    public Decimal totalAmount {get;set;}
    public Boolean hasError {get;set;}
    public Integer removeIndex{get;set;}
    
    public P2P_MyFinancialsPaymentController(){
        init();
    }
    
    private void init(){
        requestToken();
        String invLstIds = Apexpages.currentPage().getParameters().get('selInv');
        accId = Apexpages.currentPage().getParameters().get('id');
        if(String.isEmpty(accId)) accId = P2P_Utils.retrieveCommunityAccountId();
        
        if(String.isEmpty(invLstIds)) return;
        
        //get all selected invoice
        Set<String>setInvIds = new Set<String>();
        for(Object invId : (List<Object>)JSON.deserializeUntyped(invLstIds)){
            setInvIds.add((String)invId);
        }
        
        lstInvs = new List<InvoiceItem>();
        Integer ind = 0;
        for(Invoices__c inv : [select Name, Invoice_Status__c, Days_since_creation__c, Invoice_Date__c, Period__c, Age__c, Invoice_amount__c, 
                                    Amount_due__c, Payment_date__c, Paid_in_full__c, Overdue__c, Document_type__c, Payment_Due_Date__c, Invoice_Amount_exc_VAT__c  
                                    From Invoices__c where Id in :setInvIds]){
                                        
            lstInvs.add(new InvoiceItem(ind, inv));
            ind++;                                  
        }
        
        calculateAmountAndVAT();
    }
           
    /**
     *  Method remove Selected invoice
     */
    public Pagereference removeSelectedInvoice(){
        lstInvs.remove(removeIndex);
        
        Integer ind = 0;
        for(InvoiceItem inv : lstInvs){
            inv.index = ind;
            ind++;
        }
        calculateAmountAndVAT();
        return null; 
    }
    
    /**
     *  Method to calculate Total VAT
     *  VAT = Sum(Invoice__c.Invoice_Amount__c) - Sum(Invoice__c.Invoice_Amount_exc_VAT__c)
     */
    private void calculateAmountAndVAT(){
        
        totalAmount = 0;
        totalVAT = 0;
        
        Decimal invAmount = 0;
        Decimal vatAmount = 0;
        
        for(InvoiceItem invItem : lstInvs){
            totalAmount += invItem.invoice.Amount_due__c==null ? 0 : invItem.invoice.Amount_due__c;
            invAmount += invItem.invoice.Invoice_amount__c==null ? 0 : invItem.invoice.Invoice_amount__c;
            vatAmount += invItem.invoice.Invoice_Amount_exc_VAT__c==null ? 0 : invItem.invoice.Invoice_Amount_exc_VAT__c;
        }
        
        totalVAT = invAmount - vatAmount;
    }
    
    /**
     *  Method Pay by Card
     */
    public Pagereference doPayByCard(){
        /*List<Media_Basket__c> lstMBUpdates = new List<Media_Basket__c>();
        for(BasketRow br: lstBasketRows){
                
                for(BasketItem bi: br.basketItems){
                        bi.mb.Payment_Method__c = 'Credit/Debit Card';
                        bi.mb.BillingFrequency__c = 'Up-front';
                        lstMBUpdates.add(bi.mb);
                }
        }
        
        if(!lstMBUpdates.isEmpty()){
                update lstMBUpdates;
        }*/
        
         //==== kakada ======
         lstBV = [Select Payment_Type_value__c, PaymentType__c,PaymentToken__c,Masked_card_number__c,Paypal_Email__c From Braintree_Vault__c where status__c = 'active' and Account__c =:accId/*'0011100000bN9SOAA0'*/ and PayPal_email__c = null]; 
                
        return null;
    }
    
        /**
        * Method Pay by Paypal
        */
        public Pagereference doPayByPaypal(){
             /*   List<Media_Basket__c> lstMBUpdates = new List<Media_Basket__c>();
                for(BasketRow br: lstBasketRows){
                        
                        for(BasketItem bi: br.basketItems){
                                bi.mb.Payment_Method__c = 'PayPal';
                                bi.mb.BillingFrequency__c = 'Upfront';
                                
                                lstMBUpdates.add(bi.mb);
                        }
                }
                 
                if(!lstMBUpdates.isEmpty()){
                        update lstMBUpdates;
                }
             */   
                //======= kakada =======
                lstBV = [Select Payment_Type_value__c, PaymentType__c,PaymentToken__c,Masked_card_number__c,Paypal_Email__c From Braintree_Vault__c where status__c = 'active' and Account__c =:accId /*'0011100000bN9SOAA0'*/ and PayPal_email__c !=null];
                return null;
        }
    
    public class InvoiceItem{
        public Integer index{get;set;}
        public Invoices__c invoice{get;set;}
        public InvoiceItem(Integer index, Invoices__c invoice){
            this.index = index;
            this.invoice = invoice;
        }
    }
       
    //Customer should be able to download a PDF copy of individual invoice
    public String contentDomain { get; set; }
    public String urldocPdf { get; set; }
    public String invNumber { get; set; }
    
    public PageReference requestPDFBody(){
        FiqasPDFViewController cont = new FiqasPDFViewController();
        cont.currentInvoiceNo = invNumber;
        cont.requestPDFBoday();
        urldocPdf =  cont.body != null ? 'data:application/pdf;base64,' + cont.body : '';
        return null;
    } 
    
    public String getInstanceUrl(){
       String domain;// = [Select d.Domain From Domain d where DomainType='DNS' Limit 1].Domain; Return site domain
       //if (domain==null){
           domain=URL.getSalesforceBaseURL().getHost();
       //}
       return 'https://'+domain;
    }
    
     //====== kakada Task #4829========
    public List<Braintree_Vault__c> lstBV{get;set;}
    public String paymentId{get;set;}
    public boolean isErrorTrans{get;set;}
    public String errorMsg{get;set;}
    public String accid {get;set;}
    public static String GUMTREE = 'Gumtree';
    public static String CURRENCY_CODE = 'GBP';
    public String client_token{get;set;}
    public String methodnonce{get;set;}
    public String paypal_email{get;set;}
    public String selectPaypal{get;set;}
    private String errLogRef;
    /**
     * Create transaction to Braintree.
     */
    public PageReference doTransaction(){
        Braintree_Vault__c bv = [Select PaymentToken__c, Payment_Type_Value__c, Account__c from Braintree_Vault__c where id =:paymentId];
        Fiqas_Settings__c FS = Fiqas_Settings__c.getInstance('Braintree_Webservice');
        String invRef = getPaymentRef(lstInvs);
        P2P_tempuriOrg.BasicHttpBinding_IBrainTreeCollectionService service = new P2P_tempuriOrg.BasicHttpBinding_IBrainTreeCollectionService ();
        service.timeout_x = P2P_BraintreeServices.REQUEST_TIMEOUT;
        String token = service.Login(FS.User__c,FS.Key__c);
        P2P_schemasDatacontractOrg.BrainTreeCollectionServiceResult result = service.InitiatePayment(token, GUMTREE, bv.PaymentToken__c, totalAmount, CURRENCY_CODE, invRef);
        errorMsg = result.Message;
        isErrorTrans = !(result.Succes);
        System.debug('Trans result>>>>>>>>'+result.Message);
        System.debug('result.Succes>>>>>>>>'+result.Succes);
        
        //Update invoice
        if(result.Succes){
            successTransaction(lstInvs,bv);
            
            //@vitou 16-06-2015
            updateAcc();
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
       * Update the invoice object
       */
      public void successTransaction(List<InvoiceItem> inItem,Braintree_Vault__c bv){
         List<Invoices__c> lstInv = new List<Invoices__c>();
         for(InvoiceItem i : inItem){
            i.invoice.Payment_Method__c = bv.Payment_Type_Value__c + ' - Online';
            i.invoice.Braintree_Vault__c = bv.id;
            i.invoice.Last_Payment_Taken__c = datetime.now();
            i.invoice.Payment_Amount__c = totalamount;
            lstInv.add(i.invoice);
         }
         update lstInv;
      }
      
     /**
     * vitou - 16-06-2015
     * Post successful payment, update acc status to active if debt=0
     */
     private void updateAcc(){
     	
            Account acc = [select Account_Status__c, Outstanding_Debt_Fiqas__c, byPass_validation__c from Account where id =:accid];
            if(acc.Account_Status__c != 'Active' && acc.Outstanding_Debt_Fiqas__c == 0){
                
                //update checkbox field to true to byPass validation role before update account status
                acc.byPass_validation__c = true;
                acc.Account_Status__c = 'Active';
                update acc;
                
                acc.byPass_validation__c = false;
                update acc;
            }
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
            lstBV = [Select Payment_Type_value__c, PaymentType__c,PaymentToken__c,Masked_card_number__c,Paypal_Email__c, Expiration_Date__c From Braintree_Vault__c where status__c = 'active' and Account__c =:accId /*'0011100000bN9SOAA0'*/ and PayPal_email__c !=null and Expiration_Date__c >= :system.today()];
        }
        return null;
      }
      
      /**
       * Get payment referrence format as
       * GT141100194~GT141000208~GT140900196
       */
      public String getPaymentRef(List<InvoiceItem> inItem){
         String result = '';
         errLogRef = '';
         for(InvoiceItem i : inItem){
            result += i.invoice.Name + '~';
            errLogRef += i.invoice.Id + '~';
         }
         errLogRef.substring(0, result.length()-1);
         return result.substring(0, result.length()-1);
      }
      
     /**
     * Fiqas Invoices should be refreshed in SFDC
     */
    public void receiveInvoices(){
        Account acc = [Select Current_Debt_Fiqas__c, Account_Number_Fiqas__c, Outstanding_Debt_Fiqas__c, Balance__c From Account Where Id =: accId];
        try{
            P2P_FiqasInvoicesAPI.upsertInvoicesFromAccountFiqas(acc.Id, acc.Account_Number_Fiqas__c, P2P_FiqasInvoicesAPI.convertToString(Date.today().addDays(-1)));
            
        }catch(Exception ex){
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.Warning, 'Latest invoices have not been received from Fiqas');
            System.debug('Exception receiveInvoices: ' + ex);
            ApexPages.addmessage(myMsg);
        }
        
        List<Invoices__c> lstInv = new List<Invoices__c>();
         for(InvoiceItem i : lstInvs){            
            lstInv.add(i.invoice);
         }
        lstInvs = new List<InvoiceItem>();
        Integer ind = 0;
        for(Invoices__c inv : [select Name, Invoice_Status__c, Days_since_creation__c, Invoice_Date__c, Period__c, Age__c, Invoice_amount__c, 
                                    Amount_due__c, Payment_date__c, Paid_in_full__c, Overdue__c, Document_type__c, Payment_Due_Date__c, Invoice_Amount_exc_VAT__c  
                                    From Invoices__c where Id in :lstInv]){
            lstInvs.add(new InvoiceItem(ind, inv));
            ind++;                                  
        }
    }
      /**
       * Save to Error_Log
       */
        private void saveErrorLog(boolean isSuccess,String msg){
            ErrorLog__c error = new ErrorLog__c();
            if(isSuccess){
                //success
                error.details__c = msg+' - Payment processed for ?'+totalAmount;
                error.Related_Id__c = errLogRef;
                error.Type__c = 'InvoicePaymentSuccess';
            }else{
                //error
                error.details__c = msg;
                error.Related_Id__c = errLogRef;
                error.Type__c = 'InvoicePaymentError';
            }
            insert error;            
        }
      
    //======End Task #4829 =====
 
 // get user agent for Google Analytics tracking
    public String getUA() {
        return ApexPages.currentPage().getHeaders().get('User-Agent');
    } 
       
}