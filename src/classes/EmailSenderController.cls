public with sharing class EmailSenderController {
    
    public String toAddress{get;set;}
    public String ccAddress{get;set;}
    public String subject{get;set;}
    public String bodyEmail{get;set;}  
    public boolean isSent = false;
    public boolean isGeneratePDF{get;set;}
    public String oppId{get;set;}
    public boolean isPreview{get;set;}
    
   
    public String groupId{get;set;}
    final String SHORTTYPE='Screenshot-PDF';
    
    public list<ContentVersion> lstcon{get;set;}
     
     final string TEMPLATE_EN='SendShort_Template_EN';//'SendShort_Template_EN';
     public String atmentName{get;set;}
   
     string result{get;set;}
     Opportunity opp;
     string des;
     string desName='';
    public EmailSenderController(){
        oppId = ApexPages.currentPage().getParameters().get('Oppid');
        lstcon= new list<ContentVersion>([select Group_Id__c,Id from ContentVersion where Opportunity__c =:oppId and Shot_Type__c=:SHORTTYPE order by createdDate DESC limit 1
        ]);
        opp =[Select Id, Name,Owner.UserRole.Name,OwnerId, Internal_Only__c, Report_Language__c,Agency__r.Name, (Select PricebookEntry.product2.Site__r.Name FROM OpportunityLineItems LIMIT 1), (Select Role, IsPrimary, Contact.Email, Contact.Name,Contact.LastName, Contact.FirstName FROM OpportunityContactRoles WHERE Role=:ExcelReportHelper.CONTACT_ROLE_REPORT_RECEIVER OR IsPrimary=true), Campaign_Start__c, Campaign_End__c, Owner.Email, Owner.Name, Owner.Title, Owner.Phone, Campaign_Name__c, Additional_Mail_Text__c, Account.Name,Owner.FirstName, Owner.LastName FROM Opportunity WHERE id=:oppID];
        list<EmailTemplate> listEmailTemplate= [Select HtmlValue, Subject from EmailTemplate where name=:TEMPLATE_EN limit 1];
        
        if(!lstcon.isEmpty()){
             atmentName= WSLineItemCreative.validateFileName('Gumtree_'+opp.Agency__r.Name+'_'+opp.Account.Name+'_'+ opp.Campaign_Name__c+'.pdf');
             groupId=lstcon.get(0).Group_Id__c;
             isPreview=true;
        }else{
            atmentName= WSLineItemCreative.validateFileName('No attachment'); 
            groupId='';
            isPreview = false;
        }
        
        isGeneratePDF =  ApexPages.currentPage().getParameters().get('ispdf')=='true'?true:false;
        //Email subject
       
        //Email body
          
         list<OpportunityLineItem> li =opp.OpportunityLineItems;
         //atmentName= WSLineItemCreative.validateFileName('Gumtree_'+opp.Agency__r.Name+'_'+opp.Account.Name+'_'+ opp.Campaign_Name__c+'.pdf');
         String siteName='';
         if(!li.isEmpty()){ 
           siteName=li[0].PricebookEntry.product2.Site__r.Name==null?'':li[0].PricebookEntry.product2.Site__r.Name;
         }
         
         String temName='';
         /*boolean isAfter=opp.Campaign_End__c<System.today()?true:false;
         if(opp.Report_Language__c==ExcelReportHelper.REPORT_LANGUAGE_GE){
           temName = isAfter?TEMPLATE_END_ED:TEMPLATE_ED;
         }else{
           temName = isAfter?TEMPLATE_END_EN:TEMPLATE_EN;
         }*/
         //toAddress
         
          toAddress='';
          system.debug('opp.OpportunityContactRoles=='+opp.OpportunityContactRoles);
          if(!opp.OpportunityContactRoles.isEmpty()){
            OpportunityContactRole oppCont = opp.OpportunityContactRoles.get(0);
            toAddress= oppCont.Contact.Email!=null?oppCont.Contact.Email:'';
//            desName = oppCont.Contact.LastName+', '+oppCont.Contact.FirstName;
            desName = oppCont.Contact.FirstName;
            desName = desName.contains('null')?desName.replace('null',''):desName;
          }
       
        
        
       // subject= listEmailTemplate.get(0).Subject;Owner.FirstName, o.Owner.LastName
//        String name=opp.Owner.LastName+', '+opp.Owner.FirstName;
        String name= opp.Owner.FirstName+' '+opp.Owner.LastName;
        name=name.contains('null')?name.replace('null',''):name;
        if(!listEmailTemplate.isEmpty()){
           subject=listEmailTemplate.get(0).Subject;
           subject=subject.replace('[first LI.product2.Site_c.Name]', siteName);
           subject=subject.replace('[opp.Account.Name]', opp.Account.Name==null?'':opp.Account.Name);
           subject=subject.replace('[opp.Campaign_Name__c]', opp.Campaign_Name__c==null?'':opp.Campaign_Name__c);
           subject=subject.replace('[Campaign_Start__c]', opp.Campaign_Start__c==null?'':String.valueOf(opp.Campaign_Start__c));
           subject=subject.replace('[Campaign_End__c]', opp.Campaign_End__c==null?'':String.valueOf(opp.Campaign_End__c));  
        
           bodyEmail=listEmailTemplate.get(0).HtmlValue;
           des=bodyEmail;
           bodyEmail= bodyEmail.replace('[name]',desName);       
           bodyEmail= bodyEmail.replace('[opp.Campaign_Name__c]', opp.Campaign_Name__c==null?'':opp.Campaign_Name__c);
           bodyEmail= bodyEmail.replace('[first LI.product2.Site_c.Name]', siteName);
           bodyEmail= bodyEmail.replace('[Additional_Mail_Text__c]', opp.Additional_Mail_Text__c==null?'':opp.Additional_Mail_Text__c);
           bodyEmail= bodyEmail.replace('[opp.Owner.Name]', name );//opp.Owner.Name==null?'':opp.Owner.Name
           
           bodyEmail= bodyEmail.replace('[opp.Owner.Title]', opp.Owner.Title==null?'':opp.Owner.Title);
           bodyEmail= bodyEmail.replace('[opp.Owner.Email]', opp.Owner.Email==null?'':opp.Owner.Email);
           bodyEmail= bodyEmail.replace('[opp.Owner.Phone]', opp.Owner.Phone==null?'':opp.Owner.Phone);
           
           Document[] doc=[Select Id From Document WHERE name='GumtreeforBusiness_Logo' limit 1];
           String id = doc.isEmpty()?'':doc[0].id;       
           bodyEmail= bodyEmail.replace('[logo]', System.URL.getSalesforceBaseUrl().toExternalForm()+'/servlet/servlet.ImageServer?id='+id+'&oid='+UserInfo.getOrganizationId());
           
        }
        
       
       
    }
    public Pagereference sendMail(){ 
        string result='';
        
        if(toAddress==null || toAddress=='' || toAddress=='null'){return null;}
        toAddress=toAddress.replace(' ', '');
        list<String> addr=new list<String>{toAddress};
        List<String> listCC = new List<String>();
       ccAddress = (ccAddress==null ?'':ccAddress);
       
       for(String s:ccAddress.split(';')){
        if(s.trim()=='') continue;
        listCC.add(s.trim());
       }      
        //string strUrl='/apex/GeneratePDFV2?gruoupId='+groupId+'&OppId='+oppId;
        //doSend(String[] addr,String[] ccAddr,String subject,String displayName,String body,String attachedName,String contentId)
         ApexPages.Message lastNameMsg;
        
        if(!lstcon.isEmpty()){
            result = WSLineItemCreative.doSend(addr,(listCC.isEmpty()?null:listCC),subject,'Gumtree',bodyEmail,atmentName,lstcon.get(0).Id);
            lastNameMsg = new ApexPages.Message(result.indexOf('Apex Error')!=-1?ApexPages.Severity.Error:ApexPages.Severity.info,result );
             string urls= 'https://'+URL.getSalesforceBaseURL().getHost()+'/'+lstcon.get(0).Id+'?isdtp=vw'; 
            if(result.indexOf('Apex Error')==-1)createdTask(opp,urls);  
            ApexPages.addMessage(lastNameMsg); 
        }else{
             lastNameMsg = new ApexPages.Message(ApexPages.Severity.Error,'No attachment' );   
             ApexPages.addMessage(lastNameMsg); 
             return null;  
        }                      
        
       return new PageReference('/'+oppId);   
   }
   private void createdTask(Opportunity Opp,String url){
        Task nTask=new Task();
        
        nTask.Type    = 'Email';
        nTask.WhatId  = Opp.Id;
        nTask.Subject ='Email: Campaign Screenshots Sent';   
        nTask.Status  = 'completed';
        nTask.Priority = 'Normal';
        nTask.Call_Origin__c ='Outbound';
        nTask.ActivityDate = system.today();
        nTask.OwnerId = '00520000001Cywv';
        // nTask.OwnerId =Opp.OwnerId; - Issue with inactive users
        nTask.Content_PDF__c = url;
       string index='[opp.Owner.Name]';
       string finalDes=des.indexOf(index)!=-1?des.subString(80,des.indexOf(index)): des;
       finalDes=finalDes.replace('[name]',  desName);//opp.Owner.Name==null?'':opp.Owner.Name
       finalDes=finalDes.replace('[opp.Campaign_Name__c]', opp.Campaign_Name__c==null?'':opp.Campaign_Name__c);
       finalDes=finalDes.replace('[Additional_Mail_Text__c]', opp.Additional_Mail_Text__c==null?'':opp.Additional_Mail_Text__c);
       finalDes=finalDes+'\n\n'+ opp.Owner.Name;
       nTask.Description=removeHTMLTag(finalDes);
       insert nTask;
     
   }
    //remove tag html from bodyemail
    public String removeHTMLTag(String html){
    String str = Encodingutil.urlDecode(html, 'UTF-8');
    str = str.replace('</div><div><br></div><div>','\n\n');
    str = str.replace('<br>','\n');
    str = str.replace('</p>','\n');
    str = str.replace('</div><div>','\n');
    str = str.replace('&nbsp;', ' ');
    str = str.replace('&#37;', '%');
    str = str.replaceAll('<[^>]*>','');
    return str;
}
   
   
  
}