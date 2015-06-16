/* Thomas Ward October 2011
**
** CRMWaypoint.com 
**
** RestFull Web services to call DNB Web services
*/


global with sharing class DNBWebservices {

    //*****************Retrieve DUNS numbers*********************//

    //fixed values we need

public static DNB_Settings__c DNBset = DNB_Settings__c.getInstance('DNBaccess');

webService  static Account[] GetDUNSnumbers(String Name, String CountryCode, String PostCode, String BillingState){
     
   // Create the request envelope 
    
        DOM.Document doc = new DOM.Document();
               
        dom.XmlNode envelope = doc.createRootElement('Envelope', DNBset.soapNS__c, 'soapenv');
        envelope.setNamespace('xsi', DNBset.xsi__c);
        envelope.setAttributeNS('schemaLocation', DNBset.soapNS__c, DNBset.xsi__c, null);
   
   // add the body     
        dom.XmlNode body = envelope.addChildElement('Body', DNBset.soapNS__c, null).addChildElement('ws_LookUp', DNBset.serviceNS1__c, 'look').addChildElement('lookUpRequest', null, null);
        dom.XmlNode accountinfo = body.addChildElement('lookUpInput', null, null);  
            
        body.addChildElement('UserId', null, null).addTextNode( DNBset.Username__c );
        body.addChildElement('Password', null, null).addTextNode( DNBset.Password__c );
        accountinfo.addChildElement('Name', null, null).addTextNode(Name);
        accountinfo.addChildElement('Country_Code', null, null).addTextNode(CountryCode);
  //        accountinfo.addChildElement('Street_Address', null, null).addTextNode(StreetAddress);
        accountinfo.addChildElement('Post_Code', null, null).addTextNode(PostCode);
        accountinfo.addChildElement('State_or_Region', null, null).addTextNode(BillingState);
    

   
    
     //create a new instance of httprequest
     HttpRequest req = new HttpRequest();
     HttpResponse res = new HttpResponse();
     //set method
     req.setMethod('POST');

     // set endpoint url
     req.setEndpoint( DNBset.DUNSservice__c );

     // set header
     req.setHeader('Content-Type', 'text/xml');

     // set soap envelope into request body
     req.setBodyDocument(doc);
     
     // create a new instance of Http class
     Http http = new Http();
     // send request

    list <Account> results = new list <Account>();     
    
 // system.debug('##### Outbound Message: ' + doc.toXmlString());
     
     try {
            res = http.send(req);

     // method to parse httpresponse
    
      results = parseResponse(res);   
      } catch(exception e) {
           futureCreateErrorLog.createFutureErrorRecord(e + doc.toXmlString(), Name, 'DNBGetDUNSError');
            }
return results;
}


//this method is used to parse the response.
public static Account[] parseResponse(HttpResponse res)
{

list <Account> Accountslist= new list<Account>();
  
    
 Dom.Document resDoc = res.getBodyDocument();        
 Dom.XMLNode envelope = resDoc.getRootElement();

    system.debug('##### Inbound Message: ' + resDoc.toXmlString());
Dom.XmlNode Body = envelope.getChildElement('Body', DNBset.SoapNS__c).
        getChildElement('ws_LookUpResponse', DNBset.ServiceNS1__c).
        getChildElement('lookupResponse', null).
        getChildElement('DGX', null);
        
        
if (Body.getChildElement('SIGNONMSGSRSV1', null).getChildElement('SONRS', null).getChildElement('STATUS', null). 
        getChildElement('CODE', null).getText() != '0'){
       
        String Message = Body.getChildElement('SIGNONMSGSRSV1', null).getChildElement('SONRS', null).getChildElement('STATUS', null). 
        getChildElement('MESSAGE', null).getText();
         futureCreateErrorLog.createFutureErrorRecord('Error Message'+ Message + ' Response Message: '+  resDoc.toXmlString(), 'DNBErrorMessage', 'DNBGetDUNSError');
        }
   else if  (Body.getChildElement('CREDITMSGSRSV2', null).getChildElement('LOOKUPTRNRS', null).getChildElement('STATUS', null). 
        getChildElement('CODE', null).getText() != '0'){
       
        String Message = Body.getChildElement('CREDITMSGSRSV2', null).getChildElement('LOOKUPTRNRS', null).getChildElement('STATUS', null). 
        getChildElement('MESSAGE', null).getText();
         futureCreateErrorLog.createFutureErrorRecord( 'Error Message: '+ Message + ' Result Message: '+ resDoc.toXmlString(), 'DNBErrorMessage', 'DNBGetDUNSError');
      
    }
 else {  
    for ( dom.XmlNode node : envelope.getChildElement('Body', DNBset.SoapNS__c).
        getChildElement('ws_LookUpResponse', DNBset.ServiceNS1__c).
        getChildElement('lookupResponse', null).
        getChildElement('DGX', null).           
        getChildElement('CREDITMSGSRSV2', null).    
        getChildElement('LOOKUPTRNRS', null).
        getChildElement('LOOKUPRS', null). 
        getChildElement('LOOKUPRSCOMPANY', null).getChildren()){
            if(node.getName()=='ArrayOfLOOKUPRSCOMPANYItem') { 
                Account a = new Account( 
                Name = node.getChildElement('NME', null).getText(),
                BillingStreet = node.getChildElement('ADR_LINE', null).getText(),
                BillingCity = node.getChildElement('NON_POST_TOWN', null).getText(),
                BillingPostalCode = node.getChildElement('POST_CODE', null).getText(),              
                DUNS_Number__c = node.getChildElement('DUNS_NBR', null).getText());
                 Accountslist.add(a);
            }
    }
   }
        
          
        

return Accountslist;
}



    //*****************Retrieve Credit Rating*********************//
    
    webService static Account[] GetCreditRating(String DUNSnumber, String CountryCode){
     
   // Create the request envelope 
    
        DOM.Document doc = new DOM.Document();
               
        dom.XmlNode envelope = doc.createRootElement('Envelope', DNBset.soapNS__c, 'soapenv');
        envelope.setNamespace('xsi', DNBset.xsi__c);
        envelope.setAttributeNS('schemaLocation', DNBset.soapNS__c, DNBset.xsi__c, null);
   
   // add the body     
        dom.XmlNode body =      envelope.addChildElement('Body', DNBset.soapNS__c, null).addChildElement('ws_GDM', DNBset.serviceNS2__c, 'wsp').addChildElement('gdmRequest', null, null);
        dom.XmlNode orders =    body.addChildElement('Orders', null, null);
        dom.XmlNode imm =       body.addChildElement('Immediate_Delivery', null, null);
        dom.XmlNode add =       body.addChildElement('AdditionalFields', null, null).addChildElement('ArrayOfAdditionalFieldsItem', null, null);    
            
        body.addChildElement('UserId', null, null).addTextNode(DNBset.Username__c);
        body.addChildElement('Password', null, null).addTextNode( DNBset.Password__c );
        orders.addChildElement('Product', null, null).addTextNode('GDM');
        orders.addChildElement('Product_Type', null, null).addTextNode('D');
        if(CountryCode=='DE'){
           orders.addChildElement('Reason_Code', null, null).addTextNode('1');
        }
        orders.addChildElement('DnB_DUNS_Number', null, null).addTextNode(DUNSnumber);
        imm.addChildElement('Mode', null, null).addTextNode('DIRECT');
        imm.addChildElement('Format', null, null).addTextNode('XML');
        add.addChildElement('FieldName', null, null).addTextNode('CR_RULE');
       if(CountryCode =='CA'){
                add.addChildElement('FieldValue', null, null).addTextNode('MP_SF_CAN');
        }else if(CountryCode =='US'){
                add.addChildElement('FieldValue', null, null).addTextNode('MP_SF_US');
        }else { 
                add.addChildElement('FieldValue', null, null).addTextNode('MP_SF');
        }
   
     //create a new instance of httprequest
     HttpRequest req = new HttpRequest();
     HttpResponse res = new HttpResponse();
     //set method
     req.setMethod('POST');

     // set endpoint url
     req.setEndpoint(DNBset.CreditService__c);

     // set header
     req.setHeader('Content-Type', 'text/xml');

     // set soap envelope into request body
     req.setBodyDocument(doc);
     
     // create a new instance of Http class
     Http http = new Http();
     // send request
  
  list <Account> results = new list <Account>();   
 // system.debug(doc.toXmlString());
     
     try {
            res = http.send(req);
            
     // method to parse httpresponse
    
      results = parseResponse2(res);   
      } catch(exception e) {
                 futureCreateErrorLog.createFutureErrorRecord(e + res.getBodyDocument().toXmlString(), DUNSnumber, 'DNBGetRatingError');
            }
return results;
}

//this method is used to parse the response.
public static Account[] parseResponse2(HttpResponse res)
{
list <Account> AccslistRating= new list<Account>();
 Dom.Document resDoc = res.getBodyDocument();        
 Dom.XMLNode envelope = resDoc.getRootElement();
 system.debug('##### Message Response: ' + resDoc.toXmlString());
   

    for ( dom.XmlNode node : envelope.getChildElement('Body', DNBset.SoapNS__c).
        getChildElement('ws_GDMResponse', DNBset.ServiceNS2__c).
        getChildElement('gdmResponse', null).
        getChildElement('DGX', null).           
        getChildElement('CREDITMSGSRSV2', null).    
        getChildElement('DATATRNRS', null).
        getChildElement('DATARS', null). 
        getChildElement('RPT', null).getChildren()){
            if(node.getName()=='DCSN_INFO') {           
                Account ac = new Account(               
                DNB_Credit_Rate__c  = decimal.valueOf(node.getChildElement('CR_DCSN', null).getText()));
               if(node.getChildElement('CR_LMT', null).getText() !=''){            
               ac.DNB_Max_credit_limit__c = decimal.valueOf(node.getChildElement('CR_LMT', null).getText());}
               
                    
                AccslistRating.add(ac);
                 }
            
    }
return AccslistRating;
}















}