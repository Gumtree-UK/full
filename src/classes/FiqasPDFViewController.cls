// GTCRM-1833 -Can't view an invoice in Salesforce - exceeds limit

public with sharing class FiqasPDFViewController {
 //   GTCRM-1833-Can't view an invoice in Salesforce - exceeds limit
    transient public String body{get;set;}
    transient public Boolean isSuccess{get;set;}
    transient public String currentInvoiceNo{get;set;}
    transient private String invId;
    transient public String mockBody; 
    
    public FiqasPDFViewController() {
        currentInvoiceNo = Apexpages.currentPage().getParameters().get('id');   
        invId = Apexpages.currentPage().getParameters().get('invId');
        if( currentInvoiceNo == null ){
            isSuccess =  false;
            ApexPages.Message invalidDates = new ApexPages.Message(ApexPages.severity.ERROR, 'Invalid invoice number.' );  
            ApexPages.addMessage(invalidDates); 
            return;
        }
        isSuccess = true;       
        //openPdfProcess();
    }
    
    public FiqasPDFViewController(String invNo){
        currentInvoiceNo = invNo;
    }
    
    public PageReference openPdfProcess(){   
        requestPDFBoday();       
        if(body == null) return null;
        //Create new attachment
        Blob pdfBody = EncodingUtil.base64Decode(body); // Convert from base64 string to blob
        Attachment att = new Attachment(ParentId = invId, Name = +currentInvoiceNo+'.pdf', Body = pdfBody);
        insert att; 
        return null;
    }
    
    public void requestPDFBoday(){
        isSuccess = true;
        Integer contentLength = 0;
        HttpRequest req = new HttpRequest();
        HttpResponse res = new HttpResponse();
        Http http = new Http();
        Fiqas_Settings__c FS = Fiqas_Settings__c.getInstance('Webservice');
        req.setHeader('Host', FS.Http_header__c);  
        req.setHeader('content-type','application/x-www-form-urlencoded');
        req.setEndpoint(FS.Endpoint__c +'GetDocument');
        req.setMethod('POST');     
        req.setBody('user=' + FS.User__c + 
        '&challenge=0&key='+ FS.Key__c +
        //'&tranid=0&InvoiceNo='+'MP131020221');
        '&tranid=0&InvoiceNo='+currentInvoiceNo);
        contentLength = req.getBody().length();
        req.setHeader('Content-Length',contentLength.format());
        String result='';
      
         try {
            if (!Test.isRunningTest()) res = http.send(req);   
            else res.setBody(mockBody);
            //Get the result   
            result = res.getBody();
            Dom.Document doc = res.getBodyDocument();  
            //Retrieve the root element for this document.  
            Dom.XMLNode d = doc.getRootElement();
            //Get the attribute 
            for ( dom.XmlNode node : d.getChildElements()) {                    
                if(node.getName()=='GetDocumentOut') {                      
                    String Status = node.getAttributeValue('Status', null);
                    String Reason = node.getAttributeValue('Reason', null);
                    if(Status<> null && Status=='FAILED'){
                        isSuccess = false;
                        ApexPages.Message invalidDates = new ApexPages.Message(ApexPages.severity.ERROR, Reason );  
                        ApexPages.addMessage(invalidDates); 
                    }
                    for( dom.XmlNode childNode: node.getChildElements()){
                        if(childNode.getName()=='PDFFile'){
                            body = childNode.getText();
                        }
                    }
                }
            }
         }catch(Exception e){           
            ApexPages.Message invalidDates = new ApexPages.Message(ApexPages.severity.ERROR, e.getMessage() );  
            ApexPages.addMessage(invalidDates); 
            isSuccess = false;
         }
    }
    
}