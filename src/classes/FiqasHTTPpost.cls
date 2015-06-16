/* 
** Web services to call Fiqas Financial Services

Change log:
- 2013-04-22 - GTCRM-245 - Standard/Premium dunning flow on customer level
- 2015-04-21 - GTCRM-1945 - API send issue with DD Mandates (improve ErrorLog creation) BY PNC
- 2015-04-29 - GTCRM-1924 - Enhance API error logs with greater detail BY BUNHOR
*/

public with sharing class FiqasHTTPpost {

    public static Fiqas_Settings__c FS = Fiqas_Settings__c.getInstance('Webservice');
    public static string Status = '';
    public static final string INTEGRATION = 'Fiqas';
    
    //**********************Customer Insert ****************************
    public static String CustomerInsert(String CustNr, String CustParentNr, String CustBillParentNr, String CustType, String CustStatus, String CustName, String CustNameExtra, String CustVATYn, String CustEmail, String CustVATNo, String CustRegNo, String CustInfo1, String CustInfo2, String AddressStreet, String AddressNumber, String AddressNumberExtra, String AddressZipcode, String AddressCity, String AddressCountry, String ContactFirstName, String ContactMiddleName, String ContactLastName, String ContactTitle, String ContactSalutation, String ContactSexe, String PayMethType, String PayMethAccountNr, String PayMethAccountHolder, String PayMethBankName, String PayMethBankCity, String BillingCycle, String CmrType){
        Integer contentLength = 0;
        HttpRequest req = new HttpRequest();
        HttpResponse res = new HttpResponse();
        Http http = new Http();
        req.setHeader('Host', FS.Http_header__c);  
        req.setHeader('content-type','application/x-www-form-urlencoded');
        req.setEndpoint(FS.Endpoint__c + 'Ebay_Customer_Insert');
        req.setMethod('POST');
     
        req.setBody('user='+ FS.User__c +  
        '&challenge=0&key='+ FS.Key__c + 
        '&tranid=0&CustNr='+ CustNr + 
        '&CustParentNr='+ CustParentNr + 
        '&CustBillParentNr='+ CustBillParentNr + 
        '&CustType='+ CustType + 
        '&CustStatus='+ CustStatus + 
        '&CustName='+ EncodingUtil.urlEncode(CustName, 'UTF-8')  + 
        '&CustNameExtra='+ CustNameExtra + 
        '&CustVATYn='+ CustVATYn + 
        '&CustEmail='+ CustEmail + 
        '&CustVATNo='+ CustVATNo + 
        '&CustRegNo='+ CustRegNo + 
        '&CustInfo1='+ CustInfo1 + 
        '&CustInfo2='+ CustInfo2 + 
        '&AddressStreet='+ EncodingUtil.urlEncode(AddressStreet, 'UTF-8') + 
        '&AddressNumber='+ AddressNumber + 
        '&AddressNumberExtra='+ AddressNumberExtra + 
        '&AddressZipcode='+ AddressZipcode + 
        '&AddressCity='+ AddressCity + 
        '&AddressCountry='+ AddressCountry + 
        '&ContactFirstName='+ ContactFirstName + 
        '&ContactMiddleName='+ ContactMiddleName + 
        '&ContactLastName='+ ContactLastName + 
        '&ContactTitle='+ ContactTitle + 
        '&ContactSalutation='+ ContactSalutation + 
        '&ContactSexe='+ ContactSexe + 
        '&PayMethType='+ PayMethType + 
        '&PayMethAccountNr='+ PayMethAccountNr + 
        '&PayMethAccountHolder='+ PayMethAccountHolder + 
        '&PayMethBankName='+ PayMethBankName + 
        '&PayMethBankCity='+ PayMethBankCity + 
        '&BillingCycle='+ BillingCycle + 
        '&CmrType='+ CmrType);
              
        //  req.setCompressed(true); // otherwise we hit a limit of 32000
        
        contentLength = req.getBody().length();
        req.setHeader('Content-Length',contentLength.format());
        //invoke the web service call
        String result = '';
        try {
            Dom.Document doc;
            if(!Test.isRunningTest()){
                res = http.send(req);
                //Get the result      
                doc = res.getBodyDocument();
            }else{// a test is running
                // Create the request envelope
                doc = new DOM.Document();
                String soapNS = 'http://schemas.xmlsoap.org/soap/envelope/';
                String xsi = 'http://www.w3.org/2001/XMLSchema-instance';
                dom.XmlNode envelope = doc.createRootElement('Envelope', soapNS, 'soapenv');
                envelope.setNamespace('xsi', xsi);
                envelope.setAttributeNS('schemaLocation', soapNS, xsi, null);
                dom.XmlNode body = envelope.addChildElement('Ebay_Customer_InsertOut', soapNS, null);
                body.addChildElement('Status', 'OK', null);
                body.addChildElement('Reason', 'OK', null);
            }
            result = res.getBody();
            //Retrieve the root element for this document.  
            Dom.XMLNode d = doc.getRootElement();
             
            //Get the attribute 
            for ( dom.XmlNode node : d.getChildElements()) {
                if(node.getName()=='Ebay_Customer_InsertOut') {
                    Status = node.getAttributeValue('Status', null); 
                    String Reason = node.getAttributeValue('Reason', null);
                    //futureCreateErrorLog.createErrorRecord(Status + Reason + req.getBody(), CustNr, 'FiqasCustInsert' );
                    // Bunhor @29-Apr-15: GTCRM-1924 - Enhance API error logs with greater detail
                    String temResult = Status.equalsIgnoreCase('FAILED')? 'Error' : 'Success'; 
                    futureCreateErrorLog.keepLog(Status + Reason + req.getBody(), CustNr, 'FiqasCustInsert', 'Create', temResult, 'Completed', INTEGRATION); 
                }  
            }   
        }catch(exception e) {
            //futureCreateErrorLog.createErrorRecord(e.getMessage() + req.getBody() + result, CustNr,'FiqasCustInsertError' );
            // Bunhor @29-Apr-15: GTCRM-1924 - Enhance API error logs with greater detail
            futureCreateErrorLog.keepLog(e.getMessage() + req.getBody() + result, CustNr,'FiqasCustInsert', 'Create', 'Error', 'Completed', INTEGRATION);
        }
        return Status;
    }
    
    /**
     * ADD 19 March 2014: #1641, PN    
     * Give an option not to create log, so we can perform next call-out
     */
    public static String CustomerInsertWithoutLog(String CustNr, String CustParentNr, String CustBillParentNr, String CustType, String CustStatus, String CustName, String CustNameExtra, String CustVATYn, String CustEmail, String CustVATNo, String CustRegNo, String CustInfo1, String CustInfo2, String AddressStreet, String AddressNumber, String AddressNumberExtra, String AddressZipcode, String AddressCity, String AddressCountry, String ContactFirstName, String ContactMiddleName, String ContactLastName, String ContactTitle, String ContactSalutation, String ContactSexe, String PayMethType, String PayMethAccountNr, String PayMethAccountHolder, String PayMethBankName, String PayMethBankCity, String BillingCycle, String CmrType){
        Integer contentLength = 0;
        HttpRequest req = new HttpRequest();
        HttpResponse res = new HttpResponse();
        Http http = new Http();
        req.setHeader('Host', FS.Http_header__c);  
        req.setHeader('content-type','application/x-www-form-urlencoded');
        req.setEndpoint(FS.Endpoint__c + 'Ebay_Customer_Insert');
        req.setMethod('POST');
     
        req.setBody('user='+ FS.User__c +  
        '&challenge=0&key='+ FS.Key__c + 
        '&tranid=0&CustNr='+ CustNr + 
        '&CustParentNr='+ CustParentNr + 
        '&CustBillParentNr='+ CustBillParentNr + 
        '&CustType='+ CustType + 
        '&CustStatus='+ CustStatus + 
        '&CustName='+ EncodingUtil.urlEncode(CustName, 'UTF-8')  + 
        '&CustNameExtra='+ CustNameExtra + 
        '&CustVATYn='+ CustVATYn + 
        '&CustEmail='+ CustEmail + 
        '&CustVATNo='+ CustVATNo + 
        '&CustRegNo='+ CustRegNo + 
        '&CustInfo1='+ CustInfo1 + 
        '&CustInfo2='+ CustInfo2 + 
        '&AddressStreet='+ EncodingUtil.urlEncode(AddressStreet, 'UTF-8') + 
        '&AddressNumber='+ AddressNumber + 
        '&AddressNumberExtra='+ AddressNumberExtra + 
        '&AddressZipcode='+ AddressZipcode + 
        '&AddressCity='+ AddressCity + 
        '&AddressCountry='+ AddressCountry + 
        '&ContactFirstName='+ ContactFirstName + 
        '&ContactMiddleName='+ ContactMiddleName + 
        '&ContactLastName='+ ContactLastName + 
        '&ContactTitle='+ ContactTitle + 
        '&ContactSalutation='+ ContactSalutation + 
        '&ContactSexe='+ ContactSexe + 
        '&PayMethType='+ PayMethType + 
        '&PayMethAccountNr='+ PayMethAccountNr + 
        '&PayMethAccountHolder='+ PayMethAccountHolder + 
        '&PayMethBankName='+ PayMethBankName + 
        '&PayMethBankCity='+ PayMethBankCity + 
        '&BillingCycle='+ BillingCycle + 
        '&CmrType='+ CmrType);
              
        //  req.setCompressed(true); // otherwise we hit a limit of 32000
        
        contentLength = req.getBody().length();
        req.setHeader('Content-Length',contentLength.format());
        //invoke the web service call
        String result = '';
        try {
            Dom.Document doc;
            if(!Test.isRunningTest()){
                res = http.send(req);
                //Get the result      
                doc = res.getBodyDocument();
            }else{// a test is running
                // Create the request envelope
                doc = new DOM.Document();
                String soapNS = 'http://schemas.xmlsoap.org/soap/envelope/';
                String xsi = 'http://www.w3.org/2001/XMLSchema-instance';
                dom.XmlNode envelope = doc.createRootElement('Envelope', soapNS, 'soapenv');
                envelope.setNamespace('xsi', xsi);
                envelope.setAttributeNS('schemaLocation', soapNS, xsi, null);
                dom.XmlNode body = envelope.addChildElement('Ebay_Customer_InsertOut', soapNS, null);
                body.addChildElement('Status', 'OK', null);
                body.addChildElement('Reason', 'OK', null);
            }
            result = res.getBody();
            //Retrieve the root element for this document.  
            Dom.XMLNode d = doc.getRootElement();
    
            //Get the attribute 
            for ( dom.XmlNode node : d.getChildElements()) {
                if(node.getName()=='Ebay_Customer_InsertOut') {
                    Status = node.getAttributeValue('Status', null);
                    String Reason = node.getAttributeValue('Reason', null);
                    //futureCreateErrorLog.createErrorRecord(Status + Reason + req.getBody(), CustNr, 'FiqasCustInsert' );
                }
            }  
        }catch(exception e) {
            //futureCreateErrorLog.createErrorRecord(e.getMessage() + req.getBody() + result, CustNr,'FiqasCustInsertError' );
        }
        return Status;
    }
    
    //**********************Customer Update ****************************
    public static String CustomerUpdate(String CustNr, String CustParentNr, String CustBillParentNr, String CustType, String CustStatus, String CustName, String CustNameExtra, String CustVATYn, String CustEmail, String CustVATNo, String CustRegNo, String CustInfo1, String CustInfo2, String AddressStreet, String AddressNumber, String AddressNumberExtra, String AddressZipcode, String AddressCity, String AddressCountry, String ContactFirstName, String ContactMiddleName, String ContactLastName, String ContactTitle, String ContactSalutation, String ContactSexe){
        Integer contentLength = 0;
        HttpRequest req = new HttpRequest();
        HttpResponse res = new HttpResponse();
        Http http = new Http();
        req.setHeader('Host', FS.Http_header__c);  
        req.setHeader('content-type','application/x-www-form-urlencoded');
    
        req.setEndpoint(FS.Endpoint__c + 'Ebay_Customer_Update');
        req.setMethod('POST');
    
        req.setBody('user=' + FS.User__c + 
        '&challenge=0&key='+ FS.Key__c +
        '&tranid=0&CustNr='+ CustNr + 
        '&CustParentNr='+ CustParentNr + 
        '&CustBillParentNr='+ CustBillParentNr + 
        '&CustType='+ CustType + 
        '&CustStatus='+ CustStatus + 
        '&CustName='+ EncodingUtil.urlEncode(CustName, 'UTF-8') + 
        '&CustNameExtra='+ CustNameExtra +
        '&CustVATYn='+ CustVATYn +
        '&CustEmail='+ CustEmail +
        '&CustVATNo='+ CustVATNo +
        '&CustRegNo='+ CustRegNo +
        '&CustInfo1='+ CustInfo1 +
        '&CustInfo2='+ CustInfo2 +
        '&AddressStreet='+ EncodingUtil.urlEncode(AddressStreet, 'UTF-8')  +
        '&AddressNumber='+ AddressNumber +
        '&AddressNumberExtra='+ AddressNumberExtra +
        '&AddressZipcode='+ AddressZipcode +
        '&AddressCity='+ AddressCity +
        '&AddressCountry='+ AddressCountry +
        '&ContactFirstName='+ ContactFirstName +
        '&ContactMiddleName='+ ContactMiddleName +
        '&ContactLastName='+ ContactLastName +
        '&ContactTitle='+ ContactTitle +
        '&ContactSalutation='+ ContactSalutation +
        '&ContactSexe='+ ContactSexe);
        
        contentLength = req.getBody().length();
        req.setHeader('Content-Length',contentLength.format());
  
        //invoke the web service call
        String result = '';
        try {
            Dom.Document doc;
            if(!Test.isRunningTest()){
                res = http.send(req);
                //Get the result    
                doc = res.getBodyDocument();
            }else{ // a test is running
                // Create the request envelope
                doc = new DOM.Document();
                String soapNS = 'http://schemas.xmlsoap.org/soap/envelope/';
                String xsi = 'http://www.w3.org/2001/XMLSchema-instance';
                dom.XmlNode envelope = doc.createRootElement('Envelope', soapNS, 'soapenv');
                envelope.setNamespace('xsi', xsi);
                envelope.setAttributeNS('schemaLocation', soapNS, xsi, null);
                dom.XmlNode body = envelope.addChildElement('Ebay_Customer_UpdateOut', soapNS, null);
                body.addChildElement('Status', 'OK', null);
                body.addChildElement('Reason', 'OK', null);
            }
            result = res.getBody();
            //Retrieve the root element for this document.  
            Dom.XMLNode d = doc.getRootElement();
             
            //Get the attribute 
            for ( dom.XmlNode node : d.getChildElements()) {
                if(node.getName()=='Ebay_Customer_UpdateOut') {
                    Status = node.getAttributeValue('Status', null);
                    String Reason = node.getAttributeValue('Reason', null);   
                    //futureCreateErrorLog.createErrorRecord(Status + Reason + req.toString(), CustNr, 'FiqasCustUpdate');
                    // Bunhor @29-Apr-15: GTCRM-1924 - Enhance API error logs with greater detail
                    String temResult = Status.equalsIgnoreCase('FAILED')? 'Error' : 'Success';
                    futureCreateErrorLog.keepLog(Status + Reason + req.toString(), CustNr, 'FiqasCustUpdate', 'Update', temResult, 'Completed', INTEGRATION); 
                }
            }  
        }catch(exception e) {
            //futureCreateErrorLog.createErrorRecord(e.getMessage() + req.toString() + result, CustNr,'FiqasCustUpdateError');
            // Bunhor @29-Apr-15: GTCRM-1924 - Enhance API error logs with greater detail
            futureCreateErrorLog.keepLog(e.getMessage() + req.toString() + result, CustNr,'FiqasCustUpdate', 'Update', 'Error', 'Completed', INTEGRATION); 
        }
        return Status;
    }
    
    /**
     * ADD 19 March 2014: #1641, PN    
     * Give an option not to create log, so we can perform next call-out
     */
    public static String CustomerUpdateWithoutLog(String CustNr, String CustParentNr, String CustBillParentNr, String CustType, String CustStatus, String CustName, String CustNameExtra, String CustVATYn, String CustEmail, String CustVATNo, String CustRegNo, String CustInfo1, String CustInfo2, String AddressStreet, String AddressNumber, String AddressNumberExtra, String AddressZipcode, String AddressCity, String AddressCountry, String ContactFirstName, String ContactMiddleName, String ContactLastName, String ContactTitle, String ContactSalutation, String ContactSexe){
        Integer contentLength = 0;
        HttpRequest req = new HttpRequest();
        HttpResponse res = new HttpResponse();
        Http http = new Http();
        req.setHeader('Host', FS.Http_header__c);  
        req.setHeader('content-type','application/x-www-form-urlencoded');
    
        req.setEndpoint(FS.Endpoint__c + 'Ebay_Customer_Update');
        req.setMethod('POST');
    
        req.setBody('user=' + FS.User__c + 
        '&challenge=0&key='+ FS.Key__c +
        '&tranid=0&CustNr='+ CustNr + 
        '&CustParentNr='+ CustParentNr + 
        '&CustBillParentNr='+ CustBillParentNr + 
        '&CustType='+ CustType + 
        '&CustStatus='+ CustStatus + 
        '&CustName='+ EncodingUtil.urlEncode(CustName, 'UTF-8') + 
        '&CustNameExtra='+ CustNameExtra +
        '&CustVATYn='+ CustVATYn +
        '&CustEmail='+ CustEmail +
        '&CustVATNo='+ CustVATNo +
        '&CustRegNo='+ CustRegNo +
        '&CustInfo1='+ CustInfo1 +
        '&CustInfo2='+ CustInfo2 +
        '&AddressStreet='+ EncodingUtil.urlEncode(AddressStreet, 'UTF-8')  +
        '&AddressNumber='+ AddressNumber +
        '&AddressNumberExtra='+ AddressNumberExtra +
        '&AddressZipcode='+ AddressZipcode +
        '&AddressCity='+ AddressCity +
        '&AddressCountry='+ AddressCountry +
        '&ContactFirstName='+ ContactFirstName +
        '&ContactMiddleName='+ ContactMiddleName +
        '&ContactLastName='+ ContactLastName +
        '&ContactTitle='+ ContactTitle +
        '&ContactSalutation='+ ContactSalutation +
        '&ContactSexe='+ ContactSexe);
        
        contentLength = req.getBody().length();
        req.setHeader('Content-Length',contentLength.format());
        //invoke the web service call
        String result = '';
        
        try {
            Dom.Document doc;
            if(!Test.isRunningTest()){
                res = http.send(req);
                //Get the result    
                doc = res.getBodyDocument();
            }else{// a test is running
                // Create the request envelope
                doc = new DOM.Document();
                String soapNS = 'http://schemas.xmlsoap.org/soap/envelope/';
                String xsi = 'http://www.w3.org/2001/XMLSchema-instance';
                dom.XmlNode envelope = doc.createRootElement('Envelope', soapNS, 'soapenv');
                envelope.setNamespace('xsi', xsi);
                envelope.setAttributeNS('schemaLocation', soapNS, xsi, null);
                dom.XmlNode body = envelope.addChildElement('Ebay_Customer_UpdateOut', soapNS, null);
                body.addChildElement('Status', 'OK', null);
                body.addChildElement('Reason', 'OK', null);
            }
            result = res.getBody();
            //Retrieve the root element for this document.  
            Dom.XMLNode d = doc.getRootElement();
    
            //Get the attribute 
            for ( dom.XmlNode node : d.getChildElements()) {
                if(node.getName()=='Ebay_Customer_UpdateOut') {
                    Status = node.getAttributeValue('Status', null);
                    String Reason = node.getAttributeValue('Reason', null);   
                    //futureCreateErrorLog.createErrorRecord(Status + Reason + req.toString(), CustNr, 'FiqasCustUpdate');
                }
            }
        } 
        catch(exception e) {
            //futureCreateErrorLog.createErrorRecord(e.getMessage() + req.toString() + result, CustNr,'FiqasCustUpdateError');
        }
       return Status;
    }
    
 
    //**********************Invoice Insert ****************************
    public static void InvoiceInsert (String InvSentId, String CustNr,String ProductType,String ProductSubtype,String ProductCode,String Reference,String Description,String UnitLabel,String UnitCount,String UnitPrice,String Amount, String VatPercentage,String VatType,String AmountPaid,String StartDate,String EndDate,String IndividualInvoice,String InvoiceExtra1,String InvoiceExtra2,String InvoiceExtra3,String InvoiceExtra4,String InvoiceExtra5,String InvoicelineExtra1,String InvoicelineExtra2,String InvoicelineExtra3,String InvoicelineExtra4,String InvoicelineExtra5){//
        
        //for testing : ProductType=string&ProductSubtype=string&ProductCode=string&Reference=string&Description=string&UnitLabel=string&UnitCount=string&UnitPrice=string&Amount=string&VatPercentage=string&VatType=string&AmountPaid=string&StartDate=string&EndDate=string&IndividualInvoice=string&InvoiceExtra1=string&InvoiceExtra2=string&InvoiceExtra3=string&InvoiceExtra4=string&InvoiceExtra5=string&InvoicelineExtra1=string&InvoicelineExtra2=string&InvoicelineExtra3=string&InvoicelineExtra4=string&InvoicelineExtra5=string
        
        Integer contentLength = 0;
        HttpRequest req = new HttpRequest();
        HttpResponse res = new HttpResponse();
        Http http = new Http();
        req.setHeader('Host', FS.Http_header__c);  
        req.setHeader('content-type','application/x-www-form-urlencoded');
        req.setEndpoint(FS.Endpoint__c + 'EBAY_InvoiceLine_Insert');
        req.setMethod('POST');

        req.setBody('user=' + FS.User__c + 
        '&challenge=0&key=' + FS.Key__c +
        '&tranid=0&CustNr=' + CustNr +  
        '&ProductType=' + ProductType +
        '&ProductSubtype=' + ProductSubtype +
        '&ProductCode='+ ProductCode +
        '&Reference=' + Reference + 
        '&Description=' + EncodingUtil.urlEncode(Description, 'UTF-8')  +
        '&UnitLabel=' + UnitLabel +
        '&UnitCount=' + UnitCount +
        '&UnitPrice=' + UnitPrice + 
        '&Amount='+ Amount +
        '&VatPercentage=' + VatPercentage +
        '&VatType=' + VatType +
        '&AmountPaid=' + AmountPaid + 
        '&StartDate=' + StartDate +
        '&EndDate=' + EndDate +
        '&IndividualInvoice=' + IndividualInvoice + 
        '&InvoiceExtra1='+ InvoiceExtra1 + 
        '&InvoiceExtra2=' + InvoiceExtra2 + 
        '&InvoiceExtra3=' + InvoiceExtra3 + 
        '&InvoiceExtra4=' + InvoiceExtra4 + 
        '&InvoiceExtra5=' + InvoiceExtra5 + 
        '&InvoicelineExtra1='+ InvoicelineExtra1 + 
        '&InvoicelineExtra2='+ InvoicelineExtra2 + 
        '&InvoicelineExtra3=' + InvoicelineExtra3 + 
        '&InvoicelineExtra4=' + InvoicelineExtra4 + 
        '&InvoicelineExtra5=' + InvoicelineExtra5
        //'&MandateId=' +MandateId //TH 07-04-2014
        );
     
        contentLength = req.getBody().length();
        req.setHeader('Content-Length',contentLength.format());
     
        //invoke the web service call
        
        String result = '';
        if(!Test.isRunningTest()){
            try {
                res = http.send(req);
                result = res.getBody();
            
                //Get the result      
                result = res.getBody();
                Dom.Document doc = res.getBodyDocument();
             
                //Retrieve the root element for this document.  
                Dom.XMLNode d = doc.getRootElement();
        
                //Get the attribute 
                for ( dom.XmlNode node : d.getChildElements()) {
                    if(node.getName()=='EBAY_InvoiceLine_InsertOut') {
                        Status = node.getAttributeValue('Status', null);
                        String Reason = node.getAttributeValue('Reason', null);
                        if (Status != 'OK'){
                            list<InvoicesSent__c> invSentToDelete = [SELECT id FROM InvoicesSent__c WHERE id = :InvSentId];
                            if (!invSentToDelete.isEmpty()) delete invSentToDelete;
                        }
                        futureCreateErrorLog.createErrorRecord(Status + Reason + req.getBody(), IndividualInvoice, 'FiqasInvoiceInsert' );
                    }
                }  
            } 
            catch(exception e) {
                list<InvoicesSent__c> invSentToDelete = [SELECT id FROM InvoicesSent__c WHERE id = :InvSentId];
                if (!invSentToDelete.isEmpty()) delete invSentToDelete;
                futureCreateErrorLog.createErrorRecord(e.getMessage() + req.getBody() + result, IndividualInvoice, 'FiqasInvoiceError' );
            }
        }
        else{
            // a test is running
           Status = 'OK';
        }
    }
    
    //**********************Customer Get ****************************
    public static String CustomerGet (String CustNr){
     
        Integer contentLength = 0;
        HttpRequest req = new HttpRequest();
        HttpResponse res = new HttpResponse();
        Http http = new Http();
        req.setHeader('Host', FS.Http_header__c);  
        req.setHeader('content-type','application/x-www-form-urlencoded');
        req.setEndpoint(FS.Endpoint__c + 'Ebay_Customer_Get');
        req.setMethod('POST');    
    
    
        req.setBody('user=' + FS.User__c + 
        '&challenge=0&key='+ FS.Key__c +
        '&tranid=0&CustNr='+ CustNr); 
    
        contentLength = req.getBody().length();
        req.setHeader('Content-Length',contentLength.format());
     
        //invoke the web service call
        String result = '';
        if(!Test.isRunningTest()){
            try {
                res = http.send(req);
                
                //Get the result   
                result = res.getBody();
                Dom.Document doc = res.getBodyDocument();
                
                //Retrieve the root element for this document.  
                Dom.XMLNode d = doc.getRootElement();
                 
                //Get the attribute  
                for ( dom.XmlNode node : d.getChildElements()) {
                    if(node.getName()=='Ebay_Customer_GetOut') {
                        Status = node.getAttributeValue('Status', null);
                        String Reason = node.getAttributeValue('Reason', null);   
                        //futureCreateErrorLog.createErrorRecord(Status +' // ' + Reason, CustNr, 'FiqasCustGet');
                        // Bunhor @29-Apr-15: GTCRM-1924 - Enhance API error logs with greater detail
                        String temResult = Status.equalsIgnoreCase('FAILED')? 'Error' : 'Success';
                        futureCreateErrorLog.keepLog(Status +' // ' + Reason, CustNr, 'FiqasCustGet', 'Get', temResult, 'Completed', INTEGRATION);  
                    }
                } 
            } 
            catch(exception e) {
                //futureCreateErrorLog.createErrorRecord(e.getMessage() + res.toString() + result, CustNr,'FiqasCustGetError');
                // Bunhor @29-Apr-15: GTCRM-1924 - Enhance API error logs with greater detail
                futureCreateErrorLog.keepLog(e.getMessage() + res.toString() + result, CustNr,'FiqasCustGet', 'Get', 'Error', 'Completed', INTEGRATION);   
            }
        }
            
        else{
            // a test is running
           Status = 'FAILED';
        }
        return Status;          
    }
    /********** TH 27-03-2014 ********/
    public static string eBAY_API_BACSMandate_Insert(String CustNr,string PayMethType,String PayMethActiveFrom ,String PayMethActiveUntil,String PayMethAccountNr,string PayMethAccountHolder,string PayMethMandateId,string PayMethBankSortCode,String PayMethAccountCode ,string PayMethStatusReason){
        Integer contentLength = 0;
        HttpRequest req = new HttpRequest();
        HttpResponse res = new HttpResponse();
        Http http = new Http();
       // req.setHeader('Host', FS.Http_header__c);  
        req.setHeader('content-type','application/x-www-form-urlencoded');
        req.setEndpoint(FS.Endpoint__c + 'EBAY_API_BACSMandate_Insert');//https://ebayapiuat.billing.nl:25001/adaptapi.asmx/EBAY_API_BACSMandate_Insert
        req.setMethod('POST');
        req.setBody('user='             + FS.User__c + 
        '&challenge=0&tranid=0&key='    + FS.Key__c +
        '&CustNr='              +CustNr+
        '&PayMethType='         +PayMethType+
        '&PayMethActiveFrom='   +PayMethActiveFrom+
        '&PayMethActiveUntil='  +PayMethActiveUntil+
        '&PayMethAccountNr='    +PayMethAccountNr+
        '&PayMethAccountHolder='+PayMethAccountHolder+
        '&PayMethMandateId='    +PayMethMandateId+ 
        '&PayMethBankSortCode=' +PayMethBankSortCode+
        '&PayMethAccountCode='  +PayMethAccountCode+
        '&PayMethStatusReason=' +PayMethStatusReason);
        
        contentLength = req.getBody().length();
        req.setHeader('Content-Length',contentLength.format());
        
        //invoke the web service call
        String result = '';
        if(!Test.isRunningTest()){
            try {
                
                res = http.send(req);
                //Get the result      
                result = res.getBody();
                system.debug('result====='+result);
                system.debug('res.getBodyDocument='+res.getBodyDocument());
                Dom.Document doc = res.getBodyDocument();
             
                //Retrieve the root element for this document.  
                Dom.XMLNode d = doc.getRootElement();
                system.debug('root element====='+d); 
                //Get the attribute 
                for ( dom.XmlNode node : d.getChildElements()) {
                    if(node.getName()=='EBAY_API_BACSMandate_InsertOut') {
                        Status = node.getAttributeValue('Status', null);
                        String Reason = node.getAttributeValue('Reason', null);
                        futureCreateErrorLog.createErrorRecordDetails(Reason + req.getBody(), PayMethMandateId, 'FiqasMandateInsert', 'Create', 'Success', 'Completed', INTEGRATION);
                    }
                }  
            } 
            catch(exception e) {
                futureCreateErrorLog.createErrorRecordDetails(e.getMessage() + req.getBody() + result, PayMethMandateId,'FiqasMandateInsert', 'Create', 'Error', 'Completed', INTEGRATION);
            }
        }
        else{
            // a test is running
            Status = 'OK';
        }
        return Status;
        
    }
    
    
     /**
    * The API service EBAY_ResendInvoice is used to resend an invoice by email to a specified email address. 
    
        input : 
        InvoiceNo   AN(25)  Yes The invoice number of the invoice which needs to be resend.
        MailTo  AN(50)  Yes The email address the invoice has to be send to. 
        MailBcc AN(50)  No  Email Bcc the invoice will be send to. 
    
    
        output : 
        Status  AN(10)  OK or FAILED
        Reason  AN(250) Empty if Status = OK
        Filled if  Status = FAILED
    
    *
    */
     public static String EBAY_ResendInvoice(String invoiceNo,String mailTo,String mailBcc) {
        Integer contentLength = 0;
        HttpRequest req = new HttpRequest();
        HttpResponse res = new HttpResponse();
        Http http = new Http();
       // req.setHeader('Host', FS.Http_header__c);  
        req.setHeader('content-type','application/x-www-form-urlencoded');
        req.setEndpoint(FS.Endpoint__c + 'Ebay_ResendInvoice');//https://ebayapiuat.billing.nl:25001/adaptapi.asmx/EBAY_API_BACSMandate_Insert
        req.setMethod('POST');
        req.setBody('user='             + FS.User__c + 
        '&challenge=0&tranid=0&key='    + FS.Key__c +
        '&InvoiceNo='               + EncodingUtil.urlEncode(invoiceNo, 'UTF-8') +
        '&MailTo='      + EncodingUtil.urlEncode(mailTo, 'UTF-8') +
        '&MailBcc='         + EncodingUtil.urlEncode(mailBcc, 'UTF-8')
        );
        
        contentLength = req.getBody().length();
        req.setHeader('Content-Length',contentLength.format());
        
        //invoke the web service call
        String result = '';
        if(!Test.isRunningTest()){
            try {
                
                res = http.send(req);
                //Get the result      
                result = res.getBody();
                system.debug('result====='+result);
                system.debug('res.getBodyDocument='+res.getBodyDocument());
                Dom.Document doc = res.getBodyDocument();
             
                //Retrieve the root element for this document.  
                Dom.XMLNode d = doc.getRootElement();
                 
                //Get the attribute 
                for ( dom.XmlNode node : d.getChildElements()) {
                    if(node.getName()=='EBAY_ResendInvoiceOut') {
                        Status = node.getAttributeValue('Status', null);
                        String Reason = node.getAttributeValue('Reason', null);
                        futureCreateErrorLog.createErrorRecord(Status + Reason + req.getBody(), invoiceNo, 'FiqasResendInvoice' );
                    }
                }  
            } 
            catch(exception e) {
                futureCreateErrorLog.createErrorRecord(e.getMessage() + req.getBody() + result, invoiceNo,'FiqasResendInvoice' );
            }
        }
        else{
            // a test is running
            Status = 'OK';
        }
        return Status;
        
    }
    
    
    
    @istest(SeeAllData=true)
    static void test(){
      
        Account acct = new Account();
                        acct.Name='Test Account_#45213';      
                        acct.BillingStreet='12345';
                        acct.BillingCity='Test';
                        acct.Phone='12456796';
                        acct.BillingCountry='NL';
                        acct.BillingPostalCode='134697';
                        acct.BillingState='test';  
                        acct.Fiqas_Dunning_Flow__c='Standard';                  
                        insert acct;
        
        // Insert a contact
        Contact contact = new Contact(lastname='testContact2', accountID=acct.Id);
        insert contact;   
   
        AccountContactRole acr = new AccountContactRole(Role='Other',IsPrimary=true, AccountId=acct.Id, ContactId=contact.Id);
        insert acr;     
        
        acct.BillingCity = 'Utrecht';
        update acct;
        
        Account[] acc = [SELECT Id, Finance_Contact__r.FirstName, Finance_Contact__r.MiddleName__c, 
                                Finance_Contact__r.LastName, Finance_Contact__r.Email, Finance_Contact__r.Title, 
                                Finance_Contact__r.Salutation, Finance_Contact__r.Sex__c, 
                                Account_Number_Fiqas__c,
                                Parent.Name, Name,
                                Fiqas_Customer_Extra__c,
                                Fiqas_ApplyVATYN__c,
                                BillingStreet,
                                Fiqas_House_number__c,
                                Fiqas_House_number_extra__c,
                                BillingPostalCode,
                                Fiqas_Account_Synced__c,
                                BillingCity,
                                BillingCountry,
                                Fiqas_Customer_Type__c,
                                Company_VAT_No__c,
                                Company_Reg_No__c,
                                Fiqas_Payment_Method__c,
                                Fiqas_Billing_Cycle__c,
                                Account_Status__c,
                                Fiqas_CMRSheet__c,
                                Fiqas_Dunning_Flow__c
                           FROM Account 
                           WHERE Id=: acct.Id 
                           limit 1];
        test.startTest(); 
        String resultfromGet  = FiqasHTTPpost.CustomerGet(acc[0].Account_Number_Fiqas__c);
        String ResultFromUpdate = FiqasHTTPpost.CustomerUpdate(                                               
            acc[0].Account_Number_Fiqas__c,
            '',
            '', 
            acc[0].Fiqas_Customer_Type__c, 
            acc[0].Account_Status__c, 
            acc[0].Name,
            '', //fiqas_Customer_extra
            String.valueOf(acc[0].Fiqas_ApplyVATYN__c),
            acc[0].Finance_Contact__r.Email,
            acc[0].Company_VAT_No__c,
            acc[0].Company_Reg_No__c,
            acc[0].Fiqas_Dunning_Flow__c,   //CustInfo1
            '', //CustInfo2
            acc[0].BillingStreet,
            '', //Fiqas_house_number_extra required if billingstreet entered
            '', //Fiqas_house_number_extra
            acc[0].BillingPostalCode,
            acc[0].BillingCity,
            acc[0].BillingCountry,
            acc[0].Finance_Contact__r.FirstName,
            '', //Finance_contact_middlename
            acc[0].Finance_Contact__r.LastName,                   
            '',   //finance_contact_Title    
            '',   //finance_contact_salutation
            String.valueOf(acc[0].Finance_Contact__r.Sex__c));   
                            
        String ResultFromInsert = FiqasHTTPpost.CustomerInsert(                                              
            acc[0].Account_Number_Fiqas__c,
            '',
            '', 
            acc[0].Fiqas_Customer_Type__c,
            acc[0].Account_Status__c, //CustStatus
            acc[0].Name,
            '', //fiqas_Customer_extra
            String.valueOf(acc[0].Fiqas_ApplyVATYN__c),
            acc[0].Finance_Contact__r.Email,                          
            acc[0].Company_VAT_No__c,
            acc[0].Company_Reg_No__c,
            acc[0].Fiqas_Dunning_Flow__c,   //CustInfo1
            '', //CustInfo2
            acc[0].BillingStreet,
            String.valueof(acc[0].Fiqas_House_number__c), //required if billingstreet entered
            '', //Fiqas_house_number_extra
            acc[0].BillingPostalCode,
            acc[0].BillingCity, 
            acc[0].BillingCountry,
            acc[0].Finance_Contact__r.FirstName,
            '', //Finance_contact_middlename
            acc[0].Finance_Contact__r.LastName,                    
            '',   //finance_contact_Title    
            '',   //finance_contact_salutation
            String.valueOf(acc[0].Finance_Contact__r.Sex__c), 
            acc[0].Fiqas_Payment_Method__c, 
            '', //PayMethAccountNr
            '', //PayMethAccountHolder
            '', //PayMethBankName
            '', //PayMethBankCity
            acc[0].Fiqas_Billing_Cycle__c,
            acc[0].Fiqas_CMRSheet__c);
        String ResultFromUpdateWithoutLog = FiqasHTTPpost.CustomerUpdateWithoutLog(                                               
            acc[0].Account_Number_Fiqas__c,
            '',
            '', 
            acc[0].Fiqas_Customer_Type__c, 
            acc[0].Account_Status__c, 
            acc[0].Name,
            '', //fiqas_Customer_extra
            String.valueOf(acc[0].Fiqas_ApplyVATYN__c),
            acc[0].Finance_Contact__r.Email,
            acc[0].Company_VAT_No__c,
            acc[0].Company_Reg_No__c,
            acc[0].Fiqas_Dunning_Flow__c,   //CustInfo1
            '', //CustInfo2
            acc[0].BillingStreet,
            '', //Fiqas_house_number_extra required if billingstreet entered
            '', //Fiqas_house_number_extra
            acc[0].BillingPostalCode,
            acc[0].BillingCity,
            acc[0].BillingCountry,
            acc[0].Finance_Contact__r.FirstName,
            '', //Finance_contact_middlename
            acc[0].Finance_Contact__r.LastName,                   
            '',   //finance_contact_Title    
            '',   //finance_contact_salutation
            String.valueOf(acc[0].Finance_Contact__r.Sex__c));   
                            
        String ResultFromInsertWithoutLog = FiqasHTTPpost.CustomerInsertWithoutLog(                                              
            acc[0].Account_Number_Fiqas__c,
            '',
            '', 
            acc[0].Fiqas_Customer_Type__c,
            acc[0].Account_Status__c, //CustStatus
            acc[0].Name,
            '', //fiqas_Customer_extra
            String.valueOf(acc[0].Fiqas_ApplyVATYN__c),
            acc[0].Finance_Contact__r.Email,                          
            acc[0].Company_VAT_No__c,
            acc[0].Company_Reg_No__c,
            acc[0].Fiqas_Dunning_Flow__c,   //CustInfo1
            '', //CustInfo2
            acc[0].BillingStreet,
            String.valueof(acc[0].Fiqas_House_number__c), //required if billingstreet entered
            '', //Fiqas_house_number_extra
            acc[0].BillingPostalCode,
            acc[0].BillingCity, 
            acc[0].BillingCountry,
            acc[0].Finance_Contact__r.FirstName,
            '', //Finance_contact_middlename
            acc[0].Finance_Contact__r.LastName,                    
            '',   //finance_contact_Title    
            '',   //finance_contact_salutation
            String.valueOf(acc[0].Finance_Contact__r.Sex__c), 
            acc[0].Fiqas_Payment_Method__c, 
            '', //PayMethAccountNr
            '', //PayMethAccountHolder
            '', //PayMethBankName
            '', //PayMethBankCity
            acc[0].Fiqas_Billing_Cycle__c,
            acc[0].Fiqas_CMRSheet__c);
            //TH07-04-3014
            Pricebook2 pb = [select Id from Pricebook2 where IsStandard=true limit 1];
            Opportunity opp = new Opportunity(
              Name='Test Opp',
              //Agency__c=acc2.id,
              AccountId=acc[0].id,
              Campaign_Name__c='Campaign',
              StageName='Contract',
              CloseDate=System.today(),
              Pricebook2Id=pb.Id,
              Payment_Method__c='Direct Debit');

            insert opp;
            Mandate__c objMan=new Mandate__c();
            objMan.Opportunity__c=opp.Id;
            insert objMan;
            String Man=FiqasHTTPpost.eBAY_API_BACSMandate_Insert(
            'BACS DD',
            '',
            '2014-04-05',
            '2014-07-27',
            '123',
            'Test123',
            objMan.Id,
            '12',
            '',
            ''
             );
        test.stopTest();
        
        // for converage
        FiqasHTTPpost.EBAY_ResendInvoice('test', 'test@test.com', 'test2@test.com');
        FiqasHTTPpost.InvoiceInsert('test', 'test','test','test','test','test','test','test','test','test','test', 'test','test','test','test','test','test','test','test','test','test','test','test','test','test','test','test');
        
        
    }
}