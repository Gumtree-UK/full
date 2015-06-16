/**
 * Task #4820: GTCRM-1291 - PRO - M1 - 'My Financials' module - Real-time update of invoices (Fiqas API)
 * @author: Phanith Chhun
 * @category: Business logic
 * @createdDate: 28-Jan-2015
 */
global class P2P_FiqasInvoicesAPI{
    
    public static Fiqas_Settings__c FS = Fiqas_Settings__c.getInstance('Webservice');
    public final static String STATIC_RESPONE = 
        '<ArrayOfEBAY_Invoices_Get_SinceOut xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns="http://www.fiqas.nl/AdaptAPI/">' +
            '<EBAY_Invoices_Get_SinceOut Status="OK">' +
                '<CustNr>GT0000002883</CustNr>' +
                '<InvoiceNumber>GT140900196</InvoiceNumber>' +
                '<InvoiceDate>20140902</InvoiceDate>' +
                '<InvoiceAmount>5413.07</InvoiceAmount>' +
                '<IndividualInvoiceId></IndividualInvoiceId>' +
                '<LatestPaymentDate>20141001</LatestPaymentDate>' +
                '<InvoicePaymentStatus>Paid</InvoicePaymentStatus>' +
                '<InvoiceDescription>Factuur GT140900196</InvoiceDescription>' +
                '<InvoicePeriodFrom>20140801</InvoicePeriodFrom>' +
                '<InvoicePeriodTo>20140831</InvoicePeriodTo>' +
                '<InvoiceAmountPaid>5413.07</InvoiceAmountPaid>' +
                '<DunningBlockType>Invoice</DunningBlockType>' +
                '<DunningBlockStartDate>20140502</DunningBlockStartDate>' +
                '<DunningBlockEndDate>20140509</DunningBlockEndDate>' +
                '<DunningBlockReason>' +
                    'Proof of payment received case nr. 01819508 payment promise 7 May 2014' +
                '</DunningBlockReason>' +
            '</EBAY_Invoices_Get_SinceOut>' +
        '</ArrayOfEBAY_Invoices_Get_SinceOut>';
        
    /**
     * HTTP GET
     * GET /adaptapi.asmx/EBAY_Invoices_Get_Since?user=string&challenge=string&key=string&tranid=string&CustNrs=string&ChangedSince=string HTTP/1.1
     * Host: ebayapi.billing.nl
     */
    private static HttpRequest createRequest(String custNrs, String changedSince){
        HttpRequest req = new HttpRequest();
        req.setEndpoint(FS.Endpoint__c + 'EBAY_Invoices_Get_Since');
        req.setHeader('Host', FS.Http_header__c); 
        req.setHeader('content-type','application/x-www-form-urlencoded');
        req.setMethod('POST');
        req.setBody('user=' + FS.User__c + '&challenge=0&key='+ FS.Key__c + '&tranid=0&CustNrs=' + custNrs + '&ChangedSince=' + EncodingUtil.urlEncode(changedSince, 'UTF-8'));
        req.setHeader('Content-Length',req.getBody().length().format());
        return req;
    }
    
    /**
     * Bellow is sample response
     * <ArrayOfEBAY_Invoices_Get_SinceOut xmlns="http://www.fiqas.nl/AdaptAPI/">
          <EBAY_Invoices_Get_SinceOut Status="string" Reason="string">
            <CustNr>string</CustNr>
            <InvoiceNumber>string</InvoiceNumber>
            <InvoiceDate>string</InvoiceDate>
            <InvoiceAmount>string</InvoiceAmount>
            <IndividualInvoiceId>string</IndividualInvoiceId>
            <LatestPaymentDate>string</LatestPaymentDate>
            <InvoicePaymentStatus>string</InvoicePaymentStatus>
            <InvoiceDescription>string</InvoiceDescription>
            <InvoicePeriodFrom>string</InvoicePeriodFrom>
            <InvoicePeriodTo>string</InvoicePeriodTo>
            <InvoiceAmountPaid>string</InvoiceAmountPaid>
            <DunningNextStep>string</DunningNextStep>
            <DunningBlockType>string</DunningBlockType>
            <DunningBlockStartDate>string</DunningBlockStartDate>
            <DunningBlockEndDate>string</DunningBlockEndDate>
            <DunningBlockReason>string</DunningBlockReason>
          </EBAY_Invoices_Get_SinceOut>
     * </ArrayOfEBAY_Invoices_Get_SinceOut>
     */
    public static List<Map<String,String>> requestChangedInvoices(String accNrs, String changedSince){
        List<Map<String,String>> results = new List<Map<String, String>>();
        HttpRequest req = createRequest(accNrs, changedSince);
        HttpResponse res = new HttpResponse();
        if(Test.isRunningTest()){
            res.setBody(STATIC_RESPONE);
            res.setStatusCode(200);
        }else{
            res = new Http().send(req);
        }
        if(res.getStatusCode() != 200){
            return results;
        }
        Dom.Document doc = res.getBodyDocument();
        //Retrieve the root element for this document.  
        Dom.XMLNode d = doc.getRootElement();
        //Get the attribute 
        for(dom.XmlNode node : d.getChildElements()){
            if(node.getName()=='EBAY_Invoices_Get_SinceOut') {
                String status = node.getAttributeValue('Status', null);
                String reason = node.getAttributeValue('Reason', null);
                Map<String,String> result = new Map<String,String>{'Status' => status};
                for(Dom.XMLNode child : node.getChildElements()) {
                    result.put(child.getName(), child.getText());
                }
                results.add(result);
            }
        }  
        return results;
    }
    
    /**
     * @param accNrs is Account.Account_Number_Fiqas__c
     * @param changedSince is YESTERDAY
     */
    public static void upsertInvoicesFromAccountFiqas(String accId, String accNrs, String changedSince){
        List<Map<String,String>> fiqasInvoices = requestChangedInvoices(accNrs, changedSince);
        Map<String , Invoices__c> mInvoices = new Map<String , Invoices__c>();
        for(Invoices__c inv : [Select Name From Invoices__c Where Account__c =: accId]){
            mInvoices.put(inv.Name, inv);
        }
        for(Map<String,String> fiqasInvoice : fiqasInvoices){
            if(fiqasInvoice.get('Status') != 'OK') continue;
            String invName = fiqasInvoice.get('InvoiceNumber');
            Invoices__c inv = mInvoices.containsKey(invName) ? mInvoices.get(invName) : new Invoices__c();
            mapInvoiceValues(inv, fiqasInvoice, accId);
            mInvoices.put(invName, inv);
        }
        upsert mInvoices.values() ;
    }
     
    
    /**
     * Assign new value to SF INVOICE Fields
     */ 
    public static void mapInvoiceValues(Invoices__c inv, Map<String, String> fiqasInvoice, String accId){
        if(inv.Id == null) inv.Account__c = accId;
        inv.Name = fiqasInvoice.get('InvoiceNumber');
        inv.Invoice_Date__c = convertToDate(fiqasInvoice.get('InvoiceDate'));
        inv.Invoice_Amount__c = Decimal.valueOf(fiqasInvoice.get('InvoiceAmount'));
        inv.Opportunity__c = toSFId(fiqasInvoice.get('IndividualInvoiceId'));
        inv.Payment_Date__c = convertToDate(fiqasInvoice.get('LatestPaymentDate'));
        inv.Payment_Status__c = fiqasInvoice.get('InvoicePaymentStatus');
        inv.Description__c = fiqasInvoice.get('InvoiceDescription');
        inv.Period_From__c = convertToDate(fiqasInvoice.get('InvoicePeriodFrom'));
        inv.Period_Until__c = convertToDate(fiqasInvoice.get('InvoicePeriodTo'));
        inv.Amount_Paid__c = Decimal.valueOf(fiqasInvoice.get('InvoiceAmountPaid'));
        inv.Next_Step__c = fiqasInvoice.get('DunningNextStep');
        inv.Block_Type__c = fiqasInvoice.get('DunningBlockType');
        inv.Block_Start_Date__c =  convertToDate(fiqasInvoice.get('DunningBlockStartDate'));
        inv.Block_End_Date__c =  convertToDate(fiqasInvoice.get('DunningBlockEndDate'));
        inv.Block_Reason__c = fiqasInvoice.get('DunningBlockReason');
    }
    
    /**
     * val from response yyyymmdd
     */
    public static Date convertToDate(String val){
        if(val == null || val.length() != 8) return null;
        return Date.newInstance(Integer.valueOf(val.substring(0,4)), Integer.valueOf(val.substring(4,6)), Integer.valueOf(val.substring(6,8)));
    }
    
    /**
     * target val yyyymmdd
     */
    public static String convertToString(Date dt){
        if(dt == null) return '';
        String preM = dt.month() < 10 ? '0' : '';
        String preD = dt.day() < 10 ? '0' : '';
        return dt.year() + preM + dt.month() + preD + dt.day();
    }
    
    /**
     * Empty string to null
     */
    private static String toSFId(String val){
        if(val != null && (val.length() == 15 ||  val.length() == 18)) return val;
        return null; 
    }
    
    /**
     * Invoice Custom Button "Update Invoices"
     */
    webservice static String updateSelectedInvoicesFromFiqas(String accId, String itemIds){
        try{
            List<String> recIds;  
            if(itemIds.indexOf(',')!=-1){
                recIds = itemIds.split(',');
            }
            Set<String> setIds = new Set<String>();
            setIds.addAll(recIds);
            
            Account acc = [Select Account_Number_Fiqas__c From Account where Id =: accId];
            List<Map<String,String>> fiqasInvoices = requestChangedInvoices(acc.Account_Number_Fiqas__c, convertToString(Date.today().addDays(-1)));
            //List<Map<String,String>> fiqasInvoices = requestChangedInvoices(acc.Account_Number_Fiqas__c, '20100101');
            Map<String , Invoices__c> mInvoices = new Map<String , Invoices__c>();
            if(setIds.isEmpty()){
                for(Invoices__c inv : [Select Name From Invoices__c Where Account__c =:  accId]) mInvoices.put(inv.Name, inv);
            }else{
                for(Invoices__c inv : [Select Name From Invoices__c Where Id IN: setIds]) mInvoices.put(inv.Name, inv);
            }
            
            for(Map<String,String> fiqasInvoice : fiqasInvoices){
                String invName = fiqasInvoice.get('InvoiceNumber');
                if(fiqasInvoice.get('Status') != 'OK' || !mInvoices.containsKey(invName)) continue;
                Invoices__c inv = mInvoices.get(invName);
                mapInvoiceValues(inv, fiqasInvoice, accId);
                mInvoices.put(invName, inv);
            }
            update mInvoices.values();
            return 'OK';
        }catch(Exception ex){return 'Error: ' + ex+'\n'+ex.getStackTraceString();}
        return '';
    }
}