/**
*
*
*/
global class FiqasBatchInvoiceInsert implements Database.Batchable<InvoicesSent__c>, Database.AllowsCallouts {
 
    List<InvoicesSent__c> opps;
 
    global FiqasBatchInvoiceInsert(List<InvoicesSent__c>  o) {
        opps = o.clone();
    }

    global Iterable<InvoicesSent__c> start(Database.batchableContext BC){
        return opps;
    }   

    global void execute(Database.BatchableContext BC, InvoicesSent__c[] scope){

        for(Sobject s : scope) {
        InvoicesSent__c opp = (InvoicesSent__c)s;  
        			//String InExtra1=opp.Opportunity__r.Payment_Method__c.equals('Direct Debit')?opp.InvoiceExtra1__c:'null';
                    FiqasHTTPpost.InvoiceInsert(
                    opp.Id,  //InvSentId 
                    String.valueOf(opp.Account_Number_Fiqas__c),
                    opp.Fiqas_Product_type__c, //ProductType  
                    ReplaceNull(opp.Fiqas_Product_Subtype__c), //ProductSubType       
                    opp.Fiqas_Product_Code__c, //ProductCode     
                    String.valueOf(opp.IOnumber__c), //ProductReference          
                    opp.Fiqas_Invoice_Description__c,
                    ReplaceNull(opp.Unit_Label__c), //UnitLabel
                    String.valueOf(opp.Invoice_Quantity__c), //UnitCount
                    String.valueOf(opp.Sales_Price__c.setScale(2)), //UnitPrice
                    String.valueOf(opp.Invoice_Amount__c.setScale(2)),
                    String.valueOf(opp.Fiqas_VAT_Percentage__c),
                    String.valueOf(opp.Apply_VAT__c),//placeholder for VATtype
                    String.valueOf(opp.Amount_Paid__c.setScale(2)),//AmountPaid
                    opp.Fiqas_Start_Date__c,
                    opp.Fiqas_End_Date__c,                
                    opp.Opportunity__c,//individual invoice,
                    ReplaceNull(opp.InvoiceExtra1__c),//InvoiceExtra1--TH 07-04-2014 Primary_contact_FirstName__c//06-08-2014 change from  ReplaceNull(String.valueOf(opp.Mandate__c))
                    //opp.InvoiceExtra1__c,//Comment #117
                    ReplaceNull(opp.Primary_contact_LastName__c),//InvoiceExtra2 
                    ReplaceNull(opp.Primary_contact_Email__c),//InvoiceExtra3 
                    '',//InvoiceExtra4 
                    '',//InvoiceExtra5 
                    ReplaceNull(opp.InvoiceLineExtra1__c),  //InvoicelineExtra1 
                    '',//InvoicelineExtra2 
                    '',//InvoicelineExtra3 
                    '',//InvoicelineExtra4 
                    ''//InvoicelineExtra5
                     //ReplaceNull(String.valueOf(opp.Mandate__c))//MandateId07-04-2014
                     ); 
        }
    }
    
     // this is a small function that replaces a 'null' string with a '' string'
    public static String ReplaceNull(String input){

        if (input==null){
            return '';
        }
        return input;
    } 

    global void finish(Database.BatchableContext BC) {
        //Send an email to the User after your batch completes
        String currentUserId = UserInfo.getUserId();
        User currentUser = [ SELECT Id, Email FROM User WHERE Id = :currentUserId ];
         
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        String[] toAddresses = new String[] {currentuser.Email};
        mail.setToAddresses(toAddresses);
        mail.setSubject('Gumtree invoices have been sent.');
/*        mail.setTemplateId('00X20000001icmj');
*/
        mail.setHtmlBody('Invoice lines have been sent to the billing system.<p>'  +
                              'You can view what was sent <a href="https://emea.salesforce.com/00O20000004fJ1s">here</a><p>' +
                              'Please check for any errors <a href="https://emea.salesforce.com/00O20000004fQgo">here</a> ');
                              
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    }

    public static testMethod void testBatch() {
      InvoicesSent__c []o = [SELECT 
          Id,
          Account_Number_Fiqas__c,
          Fiqas_Product_type__c,
          Fiqas_Product_Subtype__c,
          Fiqas_Product_Code__c,
          Opportunity__c,
          Unit_Label__c,
          Fiqas_Start_Date__c,
          Fiqas_End_Date__c, 
          Invoice_Amount__c,
          Invoice_Quantity__c,
          IOnumber__c,
          Sales_Price__c,
          Fiqas_Invoice_Description__c,
          Fiqas_VAT_Percentage__c,
          Apply_VAT__c,
          Amount_Paid__c,
          Primary_contact_FirstName__c,
          Primary_contact_LastName__c,
          Primary_contact_Email__c,
          InvoiceLineExtra1__c,InvoiceExtra1__c
        FROM InvoicesSent__c limit 1];
        
        test.startTest();                                
        FiqasBatchInvoiceInsert scriptBatch = new FiqasBatchInvoiceInsert(o);
        ID batchprocessid = Database.executeBatch(scriptBatch, 1);
        test.stopTest();
     }

}