/**
*@Author : spp
*@Date : 29/08/2014
*@Business : 
*We would like  to send the invoice from salesforce to Email address of customer or opportunity priamry contact 
 with the click of a button.
*/
public with sharing class FiqasResendInvoice {
    
    public static String mailbcc ='operations@gumtree.com';
    
    List<Invoices__c> invoices;
    

    public String selectType {get;set;}
    public List<SelectOption> getListOption {get {return getListOption();} private set;}    
    public String accId {get;set;}
    public String freeOrFinanceEmail {get ;set;}
    public String contactEmail {get;set;}
    
    
    public boolean isError {get; private set;}
    public boolean isContact {get; private set;}
    public boolean isFreeEmail {get;private set;}
    public boolean isShowEmail {get; private set;}
    
    public Invoices__c invoice {get;set;}
    
    
    
    public FiqasResendInvoice(ApexPages.StandardSetController ctrl){
    
        // read the select invoices 
        invoices = ctrl.getSelected();   
        
        // getting invoiceid from url
        String action = ApexPages.currentPage().getParameters().get('invoiceId');       
        if(action != null) {
            invoices=[SELECT Id FROM Invoices__c WHERE Id = : action];
        }
            
        
        // load default email Opportunity__r.Primary_contact_email__c       
        // Select i.Opportunity__r.Primary_contact_email__c, i.Opportunity__c, i.Account_Number_Fiqas__c From Invoices__c i where id=:
        invoice=[Select i.Account__r.Finance_contact__c, i.Account_Number_Fiqas__c, i.Account__c, i.Account__r.Name, i.Contact__c From Invoices__c i where id=:invoices LIMIT 1];   
        accId=invoice.Account__c;
                
        // Display finance contact from Account
        Contact cont=[SELECT Email, FirstName, LastName FROM Contact WHERE Id = : invoice.Account__r.Finance_contact__c];
        freeOrFinanceEmail=cont.FirstName +' '+cont.LastName;
        contactEmail=cont.Email;
                
        isContact=false;
        isShowEmail=true;
        
        
    } 

    
    // Check some condition to start page
    public PageReference checkCondition() {
            
        // getting invoiceid from url
        String action = ApexPages.currentPage().getParameters().get('invoiceId');           
        
        if(invoices.size() < 1 && action == null ){
            isError=true;
            ApexPages.Message msg = new Apexpages.Message(ApexPages.Severity.Error,'Please select at least one invoice.');
            ApexPages.addmessage(msg);
            return null;
        }   
        
        else{
            isError=getOneAccount(invoices);            
            if(isError && action == null ){
                ApexPages.Message msg = new Apexpages.Message(ApexPages.Severity.Error,'There are many accounts on selected invoices.');
                ApexPages.addmessage(msg);
                return null;
            }       
        }
            
        return null;        
    }
    


    // Resend Invoice
    public PageReference resend() {
        
        String mailTo='';
        if(isShowEmail){
            mailTo=contactEmail;
        }
        else{
            mailTo=freeOrFinanceEmail;
        }
                
        if (String.isEmpty(mailTo)) {
            ApexPages.Message msg = new Apexpages.Message(ApexPages.Severity.Error,'No email to send.');
            ApexPages.addmessage(msg);
            return null;
        }
        
        try {
            for(Invoices__c inv : [SELECT Name FROM Invoices__c WHERE Id IN : invoices]){
                FiqasHTTPpost.EBAY_ResendInvoice(inv.Name,mailTo,mailbcc);
            }
        } catch (Exception ex) {
            ApexPages.Message msg = new Apexpages.Message(ApexPages.Severity.Error,ex.getMessage());
            ApexPages.addmessage(msg);
            
            return null;
        }
        
        ApexPages.Message msg = new Apexpages.Message(ApexPages.Severity.Confirm,'Invoice Sent.');
        ApexPages.addmessage(msg);
        
            
        return null;
    }

    // back to previous page
    public PageReference cancel() {
        
        String returnUrl = ApexPages.currentPage().getParameters().get('retUrl');
        
        if(String.isEmpty(returnUrl)){
            Schema.DescribeSObjectResult r = Invoices__c.sObjectType.getDescribe();
            returnUrl = '/' + r.getKeyPrefix();
        }
        
        PageReference pgReturnPage = new PageReference(returnUrl);
        pgReturnPage.setRedirect(true);
        
        return pgReturnPage;
    }
    
    
    // show the email of contact on column email when user select a contact name
    public PageReference showContactEmail(){
        contactEmail='';    
        if(invoice.Contact__c != null){
            Contact cont=[SELECT Email FROM Contact WHERE Id =: invoice.Contact__c];
            if(cont != null){
                contactEmail=cont.Email;        
                isShowEmail=true;
            }
        }
        return null;
    }
    
    
    // get dropdown list items
    public List<SelectOption> getListOption (){     
        List<SelectOption>selectoptionType = new List<SelectOption>();
        selectoptionType.add(new SelectOption('FINANCE','Finance Contact'));
        selectoptionType.add(new SelectOption('CONTACT','Related Contact'));
        selectoptionType.add(new SelectOption('EMAIL','Email'));
        return selectoptionType;
    }
    
    
    //User Change type of recipient (OnChange event)
    public Pagereference selectChangeType(){
        
        freeOrFinanceEmail='';
        contactEmail='';
        
        if(selectType.equalsIgnoreCase('FINANCE')){
            //Do finance email
            isContact=false;
            isFreeEmail=false;
            isShowEmail=true;
            Contact cont=[SELECT Email, FirstName, LastName FROM Contact WHERE Id = : invoice.Account__r.Finance_contact__c];
            freeOrFinanceEmail=cont.FirstName +' '+cont.LastName;
            contactEmail=cont.Email;
        }
        else if(selectType.equalsIgnoreCase('CONTACT')){
            //Do contact email
            isShowEmail=true;
            isContact=true; 
        }
        else{
            //Do free email
            isShowEmail=false;
            isFreeEmail=true;
            isContact=false;                    
        }       
        
        return null;
    }

    /**
    * Make sure the selected record is one account
    */
    private boolean getOneAccount(List <Invoices__c> invs){
        Set<Id> acct=new Set<Id>();
        for(Invoices__c inv : [SELECT Account__c FROM Invoices__c WHERE Id IN : invs]){
            acct.add(inv.Account__c);
        }
        return acct.size()!=1;              
    }
    

}