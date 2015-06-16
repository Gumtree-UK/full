/**
 * GTCRM-1957 - Ability for finance to take part/full payment of invoices
 *  - List selected invoices form Account or Opportunity related list
 *  - User able to override Amount_due__c and click the button to show next page to select payment method and pay
 *
 * @Author : Bunhor
 * @CreatedDate : 20-May-15 
 */
public without sharing class InvoicesPayment{ 
    /** DTO Invoices listed to be paid. */
    public DTOInv[] lstDtoInv{get;set;}
    /** Stirng of invioceId and pay amount, ex: a0Ng0000002qoIEEAY=5402.07,a0Nw0000008vkg3EAA=296,*/ 
    public String strInvsWithPayAmount{get;set;}  
    /** AccountId of selected invoices, init in constructor */ 
    public Id accId{get;set;}
    /** Account Name of selected invoices, init in constructor */
    public String accName{get;set;}
    /** selected invoices, init in constructor and action method */
    private Invoices__c[] selectedInvs;
    /** It can be opp or acc id and will be used for redirect when done the payment*/
    public id fromId{get;set;}
    /** Total Invoice Amount (inc VAT), for display only */ 
    public decimal totalInvAmount{get;set;}
    /** Total Amount Due, for display only */ 
    public decimal totalDueAmount{get;set;}
    /** Only some user profiles can edit to pay amount */ 
    public boolean isEditable{get{ 
        Set<String> sProfileNames = new Set<String>{'Finance & Strategy - Collections (Management)', 'Finance & Strategy - Collections', 'Finance & Strategy - Head', 'System Administrator', 'Operations - Sales Support (+ My Gumtree)', 'Operations - Sales Support', 'Operations - Management'};
        Profile pp = [select Name from Profile where id=:userinfo.getProfileId()]; 
        return sProfileNames.contains(pp.Name);
    }}
    
    /** Constructor */
    public InvoicesPayment(ApexPages.StandardSetController setCon){ 
         
        // invid is a url parameter, added when called from detail page
        Id invId = ApexPages.currentPage().getParameters().get('invid');
        
        // In case clicked from detail page button 
        if(String.isNotBlank(invId)){ 
            selectedInvs = new List<Invoices__c>{new Invoices__c(id=invId)}; 
            fromId = invId;
        // In case clicked from related list button
        }else{ 
            fromId = ApexPages.currentPage().getParameters().get('id'); // it can be opp or acc id 
            selectedInvs = setCon.getSelected();
            if(selectedInvs.isEmpty()){ // if nothing selected, query all invs 
                selectedInvs = [select id from Invoices__c where Account__c =:fromId or Opportunity__c =:fromId];
            } 
        }
        
        Invoices__c[] tem = [select Account__c, Account__r.Name from Invoices__c where id in :selectedInvs limit 1];
        if(tem.isEmpty()){
            ApexPages.Message msg = new ApexPages.Message(ApexPages.Severity.Warning, 'There are no invoices available to pay');
            ApexPages.addmessage(msg);
        }else{
            accId = tem[0].Account__c; 
            accName = tem[0].Account__r.Name;
        }  
    } 
    
    /** Called fram page action to update invoices from Fiqas*/
    public void synInvoicesFromFiqas(){
        totalInvAmount = 0;
        totalDueAmount = 0;
          
        try{
            // callout and update invs 
           synInvoicesFromFiqas(accId, selectedInvs); 
            
            // only Invoices.Amount_due__c > 0 
            lstDtoInv = new List<DTOInv>(); // reselect invs in order formula fields recaculated
            for(Invoices__c inv : [select id, Name, Payment_Due_Date__c, Amount_Due__c, Invoice_Status__c, Account__r.Id, Account__r.Account_Number_Fiqas__c, Invoice_Date__c, Invoice_Amount__c from Invoices__c where id in:selectedInvs and Amount_due__c > 0]){
                lstDtoInv.add(new DTOInv(inv));
                
                totalInvAmount += inv.Invoice_Amount__c;
                totalDueAmount += inv.Amount_Due__c;
            } 
            
            if(lstDtoInv.isEmpty()){
                ApexPages.Message msg = new ApexPages.Message(ApexPages.Severity.Warning, 'All invoices have been paid');
                ApexPages.addmessage(msg);
            }  
        }catch(Exception ex){
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.Warning, 'Latest invoices have not been received from Fiqas. Exception: '+ex.getMessage()); 
            ApexPages.addmessage(myMsg); 
        } 
    }
     
    /** Button clicked and another page popup for selecting payment method and confirm pay */
    public PageReference gotoPaymentPage(){
        strInvsWithPayAmount = '';
        for(DTOInv dto : lstDtoInv){
            strInvsWithPayAmount += dto.inv.id+'='+dto.toPay+',';   
            if(!dto.isToPayValid()){
                strInvsWithPayAmount = '';
                return null;
            }
        }
        strInvsWithPayAmount = strInvsWithPayAmount.removeEnd(',');
        return null; 
    }
    
    /** Update invoices from fiqas */
    public static void synInvoicesFromFiqas(id accid, Invoices__c[] invoices){
        String invIds = '';
        for(Invoices__c inv : invoices){invIds += inv.id+',';} 
        // callout and update invs
        if(invIds != ''){
          string result = P2P_FiqasInvoicesAPI.updateSelectedInvoicesFromFiqas(accId, invIds); 
          system.debug('>>>>>>result : ' + result);
          if (!result.equalsIgnoreCase('OK')) { 
             if(!test.isrunningTest()) throw new InvoicesPaymentMethodsPopup.PaymentException(result); 
          }
        }

        
    }
    
    /** DTO for Invoice to display in page */
    public class DTOInv{ 
        public Invoices__c inv{get;set;}
        public decimal toPay{get;set;}
        public string errMsg{get{ return isToPayValid() ? '' : 'You cannot pay more than what is due on an invoice, please update to pay amount';}}
        
        /** Constructor */
        public DTOInv(Invoices__c inv){
            this.inv = inv; 
            toPay = inv.Amount_Due__c;  
        }
        
        /** Constructor from transaction*/
        public DTOInv(Invoices__c inv, decimal toPay){
            this.inv = inv; 
            this.toPay = toPay;  
        }
        
        /** Validate toPay amount, It can not grater than Amount_Due__c*/
        public boolean isToPayValid(){
            return toPay <= inv.Amount_Due__c; 
        }
        
        /** Checking full or part payment*/
        public boolean isFullPay(){
            return toPay == inv.Amount_Due__c; 
        }
    } 
}