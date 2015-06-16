/**
 * GTCRM-1957 - Ability for finance to take part/full payment of invoices
 *  - User can delete, add or edit payment methods and do transaction, pay 
 *  
 * @Author : Bunhor
 * @CreatedDate : 20-May-15
 
Change log;
- 2015-06-10 - GTCRM-2044 - Auto un-suspend account post Braintree invoice payments

 */
public without sharing class InvoicesPaymentMethodsPopup{
    /** Total of pay amount, used for display only */ 
    public decimal totalPrice {get;set;} 
    /** List of payment methods belong to the account */ 
    public List<Braintree_Vault__c> lstBV{get;set;}
    /** Id of payment methods selected */ 
    public String paymentId{get;set;}
    /** Is transaction error? */ 
    public boolean isErrorTrans{get;set;}
    /** Transaction error messages */
    public String errorMsg{get;set;}
    /** The account id */
    public String accid {get;set;}  
    /** Email for displaying in page */
    public String paypal_email{get;set;}
    /** URL redirect when pay successfull */  
    public String refURL{get;set;}
    /** DTO invoices used to process the payment */ 
    public InvoicesPayment.DTOInv[] lstDtoInv;
    
    /** Constructor */
    public InvoicesPaymentMethodsPopup(){
        init();
    }
    
    /** Use to initialize class instances */
    private void init(){ 
        refURL = Apexpages.currentPage().getParameters().get('refurl');
        accid = Apexpages.currentPage().getParameters().get('accId');
        
        totalPrice = 0; 
        lstDtoInv = new List<InvoicesPayment.DTOInv>(); 
        
        String strInvsWithPayAmount = Apexpages.currentPage().getParameters().get('strInvsWithPayAmount');
        if(String.isNotBlank(strInvsWithPayAmount)){
            Map<id, decimal> mInvTopay = new Map<id, decimal>();
            for(String strInv : strInvsWithPayAmount.split(',')){
                if(strInv.contains('=')){
                    String[] tem = strInv.split('='); 
                    id invId = tem[0];
                    decimal toPay = Decimal.valueOf(tem[1]); 
                    mInvTopay.put(invId, toPay);
                    
                    totalPrice += toPay;
                }   
            }
            for(Invoices__c inv : [select id, Name, Amount_Due__c from Invoices__c where id in :mInvTopay.keyset()]){
                lstDtoInv.add(new InvoicesPayment.DTOInv(inv, mInvTopay.get(inv.id))); 
            }
        }
        
    }
    
    /** Query payment methods of the account */
    public Pagereference doPayByCard(){
        lstBV = [   select Payment_Type_value__c, PaymentType__c,PaymentToken__c,Masked_card_number__c,Paypal_Email__c from Braintree_Vault__c 
                    where status__c = 'active' and Account__c =:accId and Masked_card_number__c != null and Expiration_Date__c >= :system.today()]; 
        // If no payment methods match the criteria, query all.
        if(lstBV.isEmpty()){
            lstBV = [   select Payment_Type_value__c, PaymentType__c,PaymentToken__c,Masked_card_number__c,Paypal_Email__c from Braintree_Vault__c 
                        where Account__c =:accId];
        }
        return null;
    } 
    
    
    
    /** Delete payment method */
    public PageReference doDeletePayment(){
      P2P_BraintreeServices btServices = new P2P_BraintreeServices();
      Braintree_Vault__c bv = [Select Id,PaymentToken__c, Status__c from Braintree_Vault__c where id =:paymentId];
      P2P_BraintreeServices.CreditCartParser ccParser = btServices.deleteCreditCard(bv.PaymentToken__c);
      bv.Status__c = 'inactive';
      update bv;
      return null;
    }
    
    /**
     * Create transaction to Braintree.
     *  - Callout to fiqas and process reponse
     *  - Update invoices and insert logs
     *  - All full payments will be a single transaction, Part payment will in individual transaction.  
     */
    public PageReference doTransaction(){
        Map<id, ErrorLog__c> mInvIdLog = new Map<id, ErrorLog__c>();
        InvoicesPayment.DTOInv[] fullDtoPayInvs = new List<InvoicesPayment.DTOInv>();
        InvoicesPayment.DTOInv[] partDtoPayInvs = new List<InvoicesPayment.DTOInv>();
         
        for(InvoicesPayment.DTOInv dto : lstDtoInv){ 
            if(dto.isFullPay()){
                fullDtoPayInvs.add(dto);        
            }else{
                partDtoPayInvs.add(dto);    
            } 
            ErrorLog__c log = new ErrorLog__c(Integration__c='Braintree', Type__c='InvoicePayment', Action__c='Create', Result__c='Success', Details__c='OK - Payment processed for �'+dto.toPay, Status__c='Completed', Related_Id__c=dto.inv.id);
            mInvIdLog.put(dto.inv.id, log);
        }   
        Braintree_Vault__c btVault = [Select PaymentToken__c, Payment_Type_Value__c, Account__c from Braintree_Vault__c where id =:paymentId];
        Fiqas_Settings__c FS = Fiqas_Settings__c.getInstance('Braintree_Webservice');
        
        errorMsg = '';
        isErrorTrans = false;
        
        try{ 
            // doTransaction for fullpayment in a single callout
            doTransAndCatched(fullDtoPayInvs, btVault, FS); 
        }catch(Exception ex){
            errorMsg += ex.getMessage() +'\n';
            isErrorTrans = true; 
            
            for(InvoicesPayment.DTOInv dto : fullDtoPayInvs){
                ErrorLog__c log = mInvIdLog.get(dto.inv.id);    
                log.Result__c = 'Error';
                log.Details__c = ex.getMessage(); 
            }
        }
        
        // doTransaction for partpayments, loop to callout for each inv
        for(InvoicesPayment.DTOInv dto : partDtoPayInvs){ 
            try{ 
                doTransAndCatched( new List<InvoicesPayment.DTOInv>{dto}, btVault, FS);
            }catch(Exception ex){
                errorMsg += ex.getMessage() +'\n';
                isErrorTrans = true; 
                 
                ErrorLog__c log = mInvIdLog.get(dto.inv.id);    
                log.Result__c = 'Error';
                log.Details__c = ex.getMessage();  
            }
        }
         
        // Syn from fiqas, update in sf -@vitou 11-06-2015 move to try/catch block
        try{
        	InvoicesPayment.synInvoicesFromFiqas(accid, lstInvCatchedForUpdated);
        }catch(exception ex){
        	errorMsg += ex.getMessage();
        	return null;
        }
                  
        // DML after all callouts
        update lstInvCatchedForUpdated;
        
        insert mInvIdLog.values();
              
        //@vitou 11-06-2015 ==> update account status to active if Debt=0
        updateAcc();
        
        return null; 
    }  
    
    /**
     * Post successful payment, update acc
     */
    private void updateAcc(){
        if(!isErrorTrans){
            Account acc = [select Account_Status__c, Outstanding_Debt_Fiqas__c , byPass_validation__c from Account where id =:accid];
            if(acc.Account_Status__c != 'Active' && acc.Outstanding_Debt_Fiqas__c == 0){
                //acc.Account_Status__c = 'Active';
                //update acc;
                
                //@vitou 10-06-2015 ==> update checkbox field to true to byPass validation role before update account status
                acc.byPass_validation__c = true;
                acc.Account_Status__c = 'Active';
                update acc;
                
                acc.byPass_validation__c = false;
                update acc;
            }
        } 
    }
     
    /** All invoices all are stored while looping to callout. It will be updated later */
    static List<Invoices__c> lstInvCatchedForUpdated = new List<Invoices__c>(); 
    
    /** Callout and catched invoices for updating later */
    public static void doTransAndCatched(List<InvoicesPayment.DTOInv> lstDtoInv, Braintree_Vault__c bv, Fiqas_Settings__c FS){
        if(lstDtoInv.isEmpty()) return;
           
        Decimal totalAmount=0;
        String invRef ='';
        for(InvoicesPayment.DTOInv dto : lstDtoInv){
            totalAmount += dto.toPay;
            invRef += dto.inv.Name+'~';
        }
        invRef = invRef.removeEnd('~'); 
        
        P2P_tempuriOrg.BasicHttpBinding_IBrainTreeCollectionService service = new P2P_tempuriOrg.BasicHttpBinding_IBrainTreeCollectionService();
        service.timeout_x = P2P_BraintreeServices.REQUEST_TIMEOUT;
        String token = service.Login(FS.User__c,FS.Key__c); 
        P2P_schemasDatacontractOrg.BrainTreeCollectionServiceResult result = service.InitiatePayment(token, P2P_MyFinancialsPaymentController.GUMTREE, bv.PaymentToken__c, totalAmount, P2P_MyFinancialsPaymentController.CURRENCY_CODE, invRef);
         
        if(result.Succes){ 
            for(InvoicesPayment.DTOInv dto : lstDtoInv){
                dto.inv.Last_Payment_Taken__c = system.now();
                dto.inv.Braintree_Vault__c = bv.id; 
                dto.inv.Payment_Method__c = bv.Payment_Type_Value__c + ' - Internal';
                dto.inv.Payment_Amount__c = dto.toPay;
                
                lstInvCatchedForUpdated.add(dto.inv); 
            }
        }else{
            throw new PaymentException(result.Message); 
        } 
    }
    
    /** Class for Exception if fiqas reponse with error message */ 
    public class PaymentException extends Exception {} 
}