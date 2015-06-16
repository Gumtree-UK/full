/*
 * Used to insert/update multiple (ARRAY) of Invocies sent from FIQAS with REST API

Change log:
- GTCRM-13 - Invoice retrieve/update direct from Fiqas (added InvoiceCurrency requirement)
- GTCRM-785 - Days since creation not updating on invoice
*/ 
@RestResource(urlMapping='/InvoicesInsert/*')
global class FiqasInvoiceReceiveService {


    @HttpPost
    global static String doPost(RestRequest req, RestResponse res) {

/*


# 1 insert, 1 update
{
    "invoiceList": [
        {
            "custnr": "MAP0000009969",
            "name": "ab9b3195-4",
            "invoiceDate" : "2012-04-04",
            "invoiceAmount" : 100.00,
            "oppid" : "",
            "paymentDate" : "2012-04-20",
            "paymentStatus" : "Promise",
            "description" : "test erik",
            "periodFrom" : "2012-03-01",
            "periodUntil" : "2012-04-01",
            "amountPaid" : 100.00
        },
        {
            "Custnr": "MAP0000009969",
            "Name": "ab9b3195-5",
            "invoiceDate" : "2012-04-04",
            "invoiceAmount" : 100.00,
            "oppid" : "",
            "paymentDate" : "2012-04-20",
            "paymentStatus" : "Promise",
            "description" : "test erik",
            "periodFrom" : "2012-03-01",
            "periodUntil" : "2012-04-01",
            "amountPaid" : 100.00
        }
    ]
}

# 2 update
{
    "invoiceList": [
        {
            "Custnr": "MAP0000009969",
            "Name": "ab9b3195-4"
        },
        {
            "Custnr": "MAP0000009969",
            "Name": "ad0ee75f-f"
        }
    ]
}


*/


        List<Invoice> invList = new List<Invoice>();
        List<Invoices__c> invoicesInsertSFDCList = new List<Invoices__c>();
        List<Invoices__c> invoicesUpdateSFDCList = new List<Invoices__c>();
        
        System.debug('json string: ' + req.requestBody.toString());
        
        //addLog(req.requestBody.toString());
        
        JSONParser parser = JSON.createParser(req.requestBody.toString());  
        
        while (parser.nextToken() != null) {
            System.debug('Current token: ' + parser.getCurrentToken());
            
          if(parser.getCurrentToken() == JSONtoken.START_ARRAY){
            System.debug('Start parsing..');
            while(parser.nextToken() != null){
                System.debug('next token..:' + parser.getCurrentName());
                if(parser.getCurrentToken() == JSONToken.START_OBJECT){
                    Invoice inv = (Invoice)parser.readValueAs(Invoice.class);
                    System.debug('Custnr: ' + inv.Name);
                    invList.add(inv);
                    parser.skipChildren();
                }
            }
                System.debug('End..');  
          }        
        }
        
        System.debug('List with invoices:' + invList);
        
        if (invList.isEmpty())
        {
            return 'No invoices found in message';
        }
        
        //TODO: move to different method: mapCustNrAccId(); 
        Set<String> setCustnr = new Set<String>();
        for(Invoice inv : invList)
        {
            if (inv.custnr != null && inv.custnr != '')
            {
                setCustnr.add(inv.custnr);
            }
        }
        if (setCustnr.isEmpty())
        {
            return 'No customer nrs found in message';
        }
        List<Account> accList = [select Id, Name, Account_Number_Fiqas__c from Account where Account_Number_Fiqas__c in: setCustnr];
        System.debug('List acc:' + accList);
        
        if (accList.isEmpty())
        {
            return 'No matching accounts found';
        }
    
        //TODO: move to different method!
        Set<String> setName = new Set<String>();
        for(Invoice inv : invList)
        {
            if (inv.name != null && inv.name != '')
            {
                setName.add(inv.name);
            }
        }
        if (setName.isEmpty())
        {
            return 'No invoice names found in message';
        }
        List<Invoices__c> invoicesList = [select Id, Name from Invoices__c where Name in: setName];

        System.debug('List invoices__c:' + invoicesList);
    
        //TODO: move to differenet method.
        //Loop the Invoices add add some fields in the object.
        for(Invoice inv : invList){
            System.debug('Current invoice: ' + inv);
            Boolean matchFound = false;
            for(Invoices__c invC : invoicesList){
                if(inv.name == invC.Name){
                    System.debug('Matching Invoice Name: UPDATE');
                    inv.invoiceStatus = 'UPDATE';
                    inv.id = invC.Id;
                    matchFound = true;
                    break;
                }
            }
            if (!matchFound)
            {
                System.debug('No matching Invoice Name: NEW');
                inv.invoiceStatus = 'NEW';
            }

            
            for(Account acc : accList)
            {
                if(inv.custnr == acc.Account_Number_Fiqas__c){
                    System.debug('Matching Account: ' + acc.Name);
                    inv.accountId = acc.Id;
                    break;
                }
            }
        }
        
        // if update add to updateList else add to insert List (or the other way around ;-))
        for(Invoice inv: invList){
            
            if(inv.invoiceStatus == 'NEW'){
                System.debug('Add Invoice: ' + inv.name + 'to Insert List..');
                Invoices__c invSFDC = createInvoicesSFDCObj(inv);
                invoicesInsertSFDCList.add(invSFDC);
            }else{
                System.debug('Use Invoice ID to Update the records: ' + inv.id);
                
                Invoices__c invSFDC = createInvoicesSFDCObj(inv);
                invoicesUpdateSFDCList.add(invSFDC);
            }
        }
    
        System.debug('List Invoice:' + invList);    
        System.debug('invoicesSFDC to Update List:' + invoicesUpdateSFDCList);
        System.debug('invoicesSFDC to Insert List:' + invoicesInsertSFDCList);
        
        update invoicesUpdateSFDCList;
        insert invoicesInsertSFDCList;
    	
    	List<Invoices__c> listToUpdate = new List<Invoices__c>();
    	listToUpdate.addAll(invoicesUpdateSFDCList);
    	listToUpdate.addAll(invoicesInsertSFDCList);
    	updateDaysSinceCreation(listToUpdate);
    	
        return 'true';
    }
    
    /**
     * Task #3452: GTCRM-785 - Days since creation not updating on invoice
     * By CPN, 9-Sep-2014
     */
    private static void updateDaysSinceCreation(List<Invoices__c> listToUpdate){
    	List<Invoices__c> updatedInvList = new List<Invoices__c>();
        for(Invoices__c inv : [SELECT Id, Age__c, Days_since_creation__c 
                               FROM Invoices__c 
                               WHERE Id IN: listToUpdate]) {
        	if(inv.Days_since_creation__c != inv.Age__c){
        		inv.Age__c = inv.Days_since_creation__c;
                updatedInvList.add(inv);
        	}
        }
        update updatedInvList;
    }
    
    private static Invoices__c createInvoicesSFDCObj(Invoice inv){
        System.debug('Invoice object to be casted to Invoices__c object.');
        
        Invoices__c i = new Invoices__c(id = inv.id);
        i.Name = inv.name;
        i.Account_Number_Fiqas__c = inv.custnr;
        if(inv.invoiceStatus == 'NEW') i.Account__c = inv.accountId; 
        i.Invoice_Date__c = inv.invoiceDate;
        i.Invoice_Amount__c = inv.invoiceAmount;
        i.Invoice_Currency__c = inv.invoiceCurrency;
        if(inv.oppid != null && inv.oppid != '') i.Opportunity__c = inv.oppid;
        i.Payment_Date__c = inv.paymentDate;
        i.Payment_Status__c = inv.paymentStatus;
        i.Description__c = inv.description;
        i.Period_From__c = inv.periodFrom;
        i.Period_Until__c = inv.periodUntil;
        i.Amount_Paid__c = inv.amountPaid;
        i.Next_Step__c = inv.nextstep;
        i.Block_Type__c = inv.blocktype;
        i.Block_Start_Date__c = inv.blockstartdate;
        i.Block_End_Date__c = inv.blockenddate;
        i.Block_Reason__c = inv.blockreason;
        i.Invoice_Amount_Extra__c = inv.invoiceExtraAmount;
        i.Invoice_Amount_Writtenoff__c = inv.invoiceAmountWrittenoff;  
       // i.Mandate__c=inv.MandateId; //TH 07-04-2014    
        return i;
    }
    
   /*
   * Util add Log
  */ 
  /*private static void addLog(String postBody){
    ErrorLog__c log = new ErrorLog__c();
    log.Type__c = 'invoiceArrayInsertUpdateREST';
    log.Details__c = 'Received new batch of Invoices \n\nPOST body: ' + postBody;
    insert log;
  }*/
  

     public class Invoice {
         String custnr;
         String name;
         Date invoiceDate;
         Decimal invoiceAmount;
         String invoiceCurrency;
         String oppid;
         Date paymentDate;
         String paymentStatus;
         String description;
         Date periodFrom;
         Date periodUntil;
         Double amountPaid;
         String nextstep;
         String blocktype;
         Date blockstartdate;
         Date blockenddate;
         String blockreason;
         Decimal invoiceAmountWrittenoff;
         Decimal invoiceExtraAmount;
         // internal usage properties
         String invoiceStatus;
         String accountId;
         String id;
        // String MandateId;
             
         public Invoice(String a, String n, Date id, Decimal ia, String ic, String o, Date pd,
                         String ps, String d, Date pf, Date pu, Double ap, String ns, String bt, Date bst, Date bed, String br, Decimal iaw, Decimal iea,String MandateId ) {
               custnr = a; /* Fiqas Account Number */
               name = n; /* Invoice Number */
               invoiceDate = id; /* 2012-02-20 */
               InvoiceAmount = ia;
               invoiceCurrency = ic;
               Oppid = o;
               paymentDate = pd;
               paymentStatus = ps;
               description = d;
               periodFrom = pf;
               periodUntil = pu;
               amountPaid = ap;
               nextstep = ns;
               blocktype = bt;
               blockstartdate = bst;
               blockenddate = bed;
               blockreason = br;
               invoiceAmountWrittenoff = iaw;
               invoiceExtraAmount = iea;
               //MandateId=MandateId;//07-04-2014
          }
      }

}