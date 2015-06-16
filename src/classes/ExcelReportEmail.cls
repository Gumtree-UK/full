/**

GTCRM-222 - Automate client reporting for AdSales

Change log:
- 

**/

public with sharing class ExcelReportEmail {
    
   //email templates
   final String TEMPLATE_END_ED='Automated_Endreporting_Template_DE';
     final String TEMPLATE_END_EN='Automated_Endreporting_Template_EN';
     final String TEMPLATE_ED='Automated_reporting_Template_DE';
     final String TEMPLATE_EN='Automated_reporting_Template_EN';
    
   public String toAddress{get;set;}
   public String ccAddress{get;set;}
   public String subject{get;set;}
   public String bodyEmail{get;set;}   
   
   String name;// used in email body ex: Dear [name],
   
   /*====sender filtered by opp.owner role=====
   NOTE: In the future, if you want to add more emails, please follow 3 steps:
       1- create an Organization-Wide-Email-Address
        2- create a Custom-Label
             (Organization-Wide-Email-Address.DisplayName = Custom-Label.value)
        3- go to method "getDisplayName" then add an item to map "mapPrefixRole"
            Ex: 'FR' => System.Label.excel_email_display_name_FR
   
   EXISTING:
   System.Label.excel_email_display_name_ROE     = OrgWideEmailAddress.DisplayName ='eBay Advertising Account Management ROE';
   System.Label.excel_email_display_name_UK      = OrgWideEmailAddress.DisplayName ='eBay Advertising Account Management UK';  
   System.Label.excel_email_display_name_DE      = OrgWideEmailAddress.DisplayName ='eBay Advertising Account Management DE';  
   System.Label.excel_email_display_name_default                    ='Gumtree AdOps';
   ==============*/
   String oppOwnerRole=''; //init in "initEmail" method
   /** 
     *   Used to get displayName from the "Owner.UserRole.Name" 
     */
   String getDisplayName(){
     //Key the the Role's prefix that we can clasify role's name to a specific country.
     map<String, String> mapPrefixRole = new map<String, String>{'ROE'=>System.Label.excel_email_display_name_ROE,
                                  'UK' =>System.Label.excel_email_display_name_UK ,
                                         'DE' =>System.Label.excel_email_display_name_DE  };
    for(String prefix : mapPrefixRole.keySet()){
      if(oppOwnerRole.startsWith(prefix)){
        return mapPrefixRole.get(prefix);
      }
    }
     return System.Label.excel_email_display_name_default;
   }
   //=======================
   
   
   public String oppID{get;set;} 
   
   ExcelReport excelReport;
   public String attName{get;set;} 
   
   /** 
     *   Constructor default
     */
   public ExcelReportEmail(){         
     oppID=ApexPages.currentPage().getParameters().get('oppId');
     excelReport =new ExcelReport(oppID);
     attName= excelReport.fileName;
     initEmail();
   }
   
   /** 
     *   Constructor for calling from scheduler-batch
     */
   public ExcelReportEmail(String oppID){     
     this.oppID=oppID;
     excelReport =new ExcelReport(oppID);
     attName= excelReport.fileName; 
     initEmail();
   }
   
   /** 
     *   initialize all intance variables
     */ 
   void initEmail(){
     
     Opportunity opp =[Select Owner.UserRole.Name, Internal_Only__c, Report_Language__c, (Select PricebookEntry.product2.Site__r.Name FROM OpportunityLineItems LIMIT 1), (Select Role, IsPrimary, Contact.Email, Contact.Name FROM OpportunityContactRoles WHERE Role=:ExcelReportHelper.CONTACT_ROLE_REPORT_RECEIVER OR IsPrimary=true), Campaign_Start__c, Campaign_End__c, Owner.Email, Owner.Name, Owner.Title, Owner.Phone, Campaign_Name__c, Additional_Mail_Text__c, Account.Name FROM Opportunity WHERE id=:oppID];
     
     oppOwnerRole=(opp.Owner.UserRole.Name==null?'':opp.Owner.UserRole.Name);
     
     //selecting tempate=== 
     String temName='';
     boolean isAfter=opp.Campaign_End__c<System.today()?true:false;
     if(opp.Report_Language__c==ExcelReportHelper.REPORT_LANGUAGE_GE){
       temName = isAfter?TEMPLATE_END_ED:TEMPLATE_ED;
     }else{
       temName = isAfter?TEMPLATE_END_EN:TEMPLATE_EN;
     }
     list<EmailTemplate> listEmailTemplate= [Select HtmlValue, Subject from EmailTemplate where name=:temName limit 1];
     //=====================
     
     //If the field “opp.Internal_Only__c” is checked the mail will only be sent the opportunity owner and the user in “opp.Account_Manager__c”.
     if(opp.Internal_Only__c){
       toAddress=opp.Owner.Email;
//       ccAddress=opp.Account_Manager__r.Email==null?'':opp.Account_Manager__r.Email;
       name=opp.Owner.Name==null?'':opp.Owner.Name;       
     }else{
       
//       ccAddress= opp.Owner.Email +'; '+ ((opp.Account_Manager__r.Email==null)?'':(opp.Account_Manager__r.Email+'; '));
       ccAddress= opp.Owner.Email;
       
       //Per default the recipients of the mail are all contact roles where role = “Reporting Receiver”.(1st for To-address, the remains for Cc-address) 
       //If there is no contact role with this role it will be replaced by the primary contact role
       for(OpportunityContactRole ocr : opp.OpportunityContactRoles){
         if(ocr.role==ExcelReportHelper.CONTACT_ROLE_REPORT_RECEIVER){
           if(toAddress==null || toAddress=='' || toAddress=='null'){
             toAddress=String.valueOf(ocr.Contact.Email);
             name=String.valueOf(ocr.Contact.Name);
           }else{
             ccAddress+=ocr.Contact.Email==null?'':(ocr.Contact.Email+'; ');
           }
         }
       }
       for(OpportunityContactRole ocr : opp.OpportunityContactRoles){
         if(toAddress!=null && toAddress!='' && toAddress!='null'){break;}
         if(ocr.IsPrimary){
           if(toAddress==null || toAddress=='' || toAddress=='null'){
             toAddress=String.valueOf(ocr.Contact.Email);
             name=String.valueOf(ocr.Contact.Name);
           }else{
             ccAddress+=ocr.Contact.Email==null?'':(ocr.Contact.Email+'; ');
           }
         }
       }
       
       if(ccAddress.contains(';')){
         ccAddress=ccAddress.substring(0, ccAddress.lastIndexOf(';'));
       }
       
       
     }
     
     //[first LI.product2.Site_c.Name] 
     list<OpportunityLineItem> li =opp.OpportunityLineItems;
     String siteName='';
     if(!li.isEmpty()){ 
       siteName=li[0].PricebookEntry.product2.Site__r.Name==null?'':li[0].PricebookEntry.product2.Site__r.Name;
     }
     
     // find and replace 
     if(!listEmailTemplate.isEmpty()){
       subject=listEmailTemplate.get(0).Subject;
       subject=subject.replace('[first LI.product2.Site_c.Name]', siteName);
       subject=subject.replace('[opp.Account.Name]', opp.Account.Name==null?'':opp.Account.Name);
       subject=subject.replace('[opp.Campaign_Name__c]', opp.Campaign_Name__c==null?'':opp.Campaign_Name__c);
       subject=subject.replace('[Campaign_Start__c]', opp.Campaign_Start__c==null?'':String.valueOf(opp.Campaign_Start__c));
       subject=subject.replace('[Campaign_End__c]', opp.Campaign_End__c==null?'':String.valueOf(opp.Campaign_End__c));
       
       bodyEmail=listEmailTemplate.get(0).HtmlValue;
       bodyEmail= bodyEmail.replace('[name]', (name==null)?'':name);       
       bodyEmail= bodyEmail.replace('[opp.Campaign_Name__c]', opp.Campaign_Name__c==null?'':opp.Campaign_Name__c);
       bodyEmail= bodyEmail.replace('[first LI.product2.Site_c.Name]', siteName);
       bodyEmail= bodyEmail.replace('[Additional_Mail_Text__c]', opp.Additional_Mail_Text__c==null?'':opp.Additional_Mail_Text__c);
       bodyEmail= bodyEmail.replace('[opp.Owner.Name]', opp.Owner.Name==null?'':opp.Owner.Name);
       bodyEmail= bodyEmail.replace('[opp.Owner.Title]', opp.Owner.Title==null?'':opp.Owner.Title);
       bodyEmail= bodyEmail.replace('[opp.Owner.Email]', opp.Owner.Email==null?'':opp.Owner.Email);
       bodyEmail= bodyEmail.replace('[opp.Owner.Phone]', opp.Owner.Phone==null?'':opp.Owner.Phone);
       
       Document[] doc=[Select Id From Document WHERE name='GumtreeforBusiness_Logo' limit 1];
       String id = doc.isEmpty()?'':doc[0].id;       
       bodyEmail= bodyEmail.replace('[logo]', System.URL.getSalesforceBaseUrl().toExternalForm()+'/servlet/servlet.ImageServer?id='+id+'&oid='+UserInfo.getOrganizationId());
           
     }
   }
   
   /** 
     *   Send Email with attachments
     */
     public Pagereference sendMail(){       
       if(toAddress==null || toAddress=='' || toAddress=='null'){return null;}
       toAddress=toAddress.replace(' ', '');//trim      
      List<String> listTo = new List<String>(toAddress.split(';'));
      //List<String> listTo = new List<String>{'bunhor.eng@gaea-sys.com'};
    // Set email file attachments
        Messaging.Emailfileattachment att = new Messaging.Emailfileattachment();
    att.setFileName(attName);//System.Label.excel_email_att_file_name
      att.setBody(Blob.valueOf(excelReport.getxml()));
      
      // Create EmailMessage and assign parameters      
    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage(); 
    mail.setToAddresses(listTo);
    if(ccAddress!=null && ccAddress!=''){
      ccAddress=ccAddress.replace(' ', '');//trim
        List<String> listCC = new List<String>(ccAddress.split(';'));
        //List<String> listCC = new List<String>{'vadhanak.voun@gaea-sys.com'}; 
      mail.setCcAddresses(listCC);
    }
    
    /*=======Sender email can be defualt or from OrgWideEmailAddress ====  */
    String displayName=  getDisplayName();
    if(displayName==System.Label.excel_email_display_name_default){
      mail.setSenderDisplayName(displayName);//sender address  will be determined by Email Settings in sf
    }else{
      List<OrgWideEmailAddress> listEmail =[Select Id From OrgWideEmailAddress Where DisplayName=:displayName Limit 1];
      if(listEmail.isEmpty()){
        mail.setSenderDisplayName(displayName);//sender address  will be determined by Email Settings in sf
      }else{
        mail.setOrgWideEmailAddressId(listEmail.get(0).Id);//sender address  will be determined by OrgWideEmailAddress
      }
    }
    //================
    
    
    mail.setSubject(subject); 
    mail.setHtmlBody(bodyEmail); 
      mail.setFileAttachments(new List<Messaging.EmailFileAttachment>{att});
  
      try{
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
            Pagereference oppPage = new Pagereference('/'+oppID);
            oppPage.setRedirect(true);
        return oppPage;
        }catch(System.EmailException ex){       
            ApexPages.Message errormsg = new ApexPages.Message(ApexPages.severity.ERROR,ex.getMessage() ); //Err_Email_Address
            ApexPages.addMessage(errormsg);
            return null;
        }
      
   }
   
   /** 
     *   call when click button back in email preview
     */  
   public Pagereference back(){
     Pagereference oppPage = new Pagereference('/'+oppID);
     return oppPage;
   }
}