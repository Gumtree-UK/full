/**
 * This class use as Controller for P2P_ExportStatementFilter page.
 * <p>
 * Built the Report with the filter option
 * this Week /Month/ Year and customer 
 * should able to view and download as PDF.
 * It should pick the invoice statement for that account only.
 *
 * @author Kakada Khan
 * @date 23-Oct-2014
 */

public class P2P_ExportStatementFilter{
    public List<Invoices__c> lstInvoices{get;set;}
    public boolean isNorecord{get {return (lstInvoices.isEmpty());}}    
    public Map<String,Decimal>sumFields {get;set;}  
    public Integer getInvCount{get{return lstInvoices.size();}}
    public String filter;//{get;set;}
    public Account acc{get;set;}
    public Invoices__c totalInv{get;set;}
    
    /** 
     * Constructor
     * Get the Account Id from URL 
     */
    public P2P_ExportStatementFilter(){
        totalInv = new Invoices__c();
        String acctId = ApexPages.currentPage().getParameters().get('acctid');
        acc = [select Name, AccountNumber, Account_Number_Fiqas__c from Account where Id=:acctId];          
        
        filter='';
        lstInvoices = getInvoices(filter);
        calculateFields();
    }
    
    /**
     * Filter the invoice by Invoice Date
     * @param filter is the expression to be filter
     * @return List of Invoices
     */
    private List<Invoices__c> getInvoices(String exp){
        String combin = ' AND Invoice_Date__c = '+exp;
        String sql = 'SELECT Period_Until__c,Period_From__c,Payment_Status__c,Payment_Date__c, Payment_Due_Date__c, Invoice_Status__c, '+
                     'Name,Invoice_Date__c,Invoice_Amount_exc_VAT__c, Invoice_Amount__c,'+
                     'Amount_Paid__c,Amount_Due__c,Account_Number__c FROM Invoices__c '+
                     'WHERE Account__c = \'' + acc.Id + '\' order by Invoice_Date__c DESC';
                     sql += String.isBlank(exp) ? '' : combin;
        
        List<Invoices__c> lstInv = Database.query(sql);     
        return lstInv;
    }
    
    /**
     * Get the total of some values:
     * -Amount Exc
     * -Amount Inc
     * -Amount Paid
     * -Amount Due
     */ 
    private void calculateFields(){
        Decimal amountExc=0;Decimal amountInc=0;
        Decimal amountPad=0;Decimal amountDue=0;
        for(Invoices__c i : lstInvoices){
            amountExc += i.Invoice_Amount_exc_VAT__c==null?0:i.Invoice_Amount_exc_VAT__c;
            amountInc += i.Invoice_Amount__c==null?0:i.Invoice_Amount__c;
            amountPad += i.Amount_Paid__c==null? 0:i.Amount_Paid__c;
            amountDue += i.Amount_Due__c==null?0:i.Amount_Due__c;
        }
        totalInv.Invoice_Amount_exc_VAT__c = amountExc;
        totalInv.Invoice_Amount__c = amountInc;
        totalInv.Amount_Paid__c = amountPad;
        totalInv.Invoice_Amount_Extra__c = amountDue;
    }

    /**
     * Method to format Amount
     * @return String the amount formated
     
    private String getAmount(String i){ 
        String s = ( Decimal.valueOf(i==null||i.trim()==''?'0':i).setScale(2) + 0.001 ).format();
        return s.substring(0,s.length()-1);
    }
    
    */
    
}