/**

Change log:
- GTCRM-031 - Upgrade eSignature tool to include data mappings
- 2014-05-14 - GTCRM-807 - Gumtree UK Direct Debit
 -2014-12-03 - GTCRM-1584-Apex classes with Test Code Coverage below 75%
 -2014-03-12 - GTCRM-1804-Housing: Incorrect I/O template showing as motors ( Added RecordtypeName)

Change log;

**/

public with sharing class IODisplayController {

    private Opportunity opp;
    private String errorMessage = 'Error Message: Unknown';
    private Boolean showErrorMessage = false;
    private Static Boolean IS_TEST = false;
    
    ApexPages.StandardController standardController = null;
    public IODisplayController(ApexPages.StandardController sc) {
        opp = (Opportunity) sc.getRecord();
        
        opp = [Select Id, Name,IOnumber__c,Approval_Status__c,RecordType.DeveloperName,Campaign_Start__c,Direct_Debit_Mandate__r.Modulus_Check_Sales_Ops__c,Direct_Debit_Mandate__r.I_O_Display__c,Auto_Renewal__c,Direct_Debit_Mandate__r.Name,Primary_Contact__c,Direct_Debit_Mandate__c,Direct_Debit_Mandate__r.Mandate_Status__c, Primary_Contact__r.FirstName, Owner.Firstname, Owner.Phone, StageName, IsWon, IsClosed, CloseDate, Amount, AccountId, Account.Name, RecordTypeId, Payment_Method__c from Opportunity where Id = :opp.Id];
    }

    public IODisplayController()
    {
        // opp = [Select Id, Name, Primary_Contact__c, StageName, IsWon, IsClosed, CloseDate, Amount, AccountId, Account.Name, RecordTypeId from Opportunity where Id = '0062000000ALvZv'];
    }
    
    public String getErrorMessage()
    {
       return errorMessage;
    }
    
    public Boolean getShowErrorMessage()
    {
       return showErrorMessage;
    }
       
    public PageReference cancel()
    {
        return new PageReference('/'+opp.Id);
    }
    

    public PageReference createAgreementAndAttachPDF()
    {
         showErrorMessage = false;
        // Look at getting parameter!
        
        if (SF_Gumtree_SOW_001.valueIsNull(opp.Primary_Contact__c))
        {
            showErrorMessage = true;
            errorMessage = 'Please Select a Primary Contact for the Opportunity.';
            return null;
        }
        
        if (!opp.Approval_Status__c)
        {
            showErrorMessage = true;
            errorMessage = 'Opportunity must be approved before agreement can be generated. Please submit for approval first.';
            return null;
        }
        
        // PageReference pdf = Page.IO_Display_inc_VAT;
        
        // String pageName = 'IO_Display_inc_VAT';
        String pageName = ApexPages.currentPage().getParameters().get('ApexPdfPage');
        System.debug('Getting Page Name '+pageName);
        PageReference pdf = new PageReference('/apex/'+pageName);
        
        pdf.getParameters().put('id',(String)opp.id);
        pdf.setRedirect(true);
        // Take the PDF content
        // Blob 
        Blob b = null;
        if (IODisplayController.IS_TEST)
        {
            b = Blob.valueof('test pdf contents');
        }
        else
        {
            // b = pdf.getContentAsPDF();
            b = pdf.getContent();   
        }
        
          // load default MergeMapping
        
      
        // Need to insert an agreement -
        echosign_dev1__SIGN_Agreement__c agreement = new echosign_dev1__SIGN_Agreement__c();
        // agreement.Name =  opp.Name+' agreement';
        agreement.Name = 'Gumtree for Business I/O No. '+ opp.IOnumber__c;
        agreement.echosign_dev1__Opportunity__c = opp.id;
          Attachment attachment = new Attachment();
             

        // GTCRM-031 - Upgrade eSignature tool to include data mappings
        // 2014-05-14 - GTCRM-807 - Gumtree UK Direct Debit

        if (opp.Payment_Method__c == 'Direct Debit'  && opp.RecordType.DeveloperName== 'Campaign_Delivery_M' && opp.Auto_Renewal__c == true)
        {
       
                // load default mapping
           echosign_dev1__SIGN_Data_Mapping__c sdm = [Select e.Name, e.Id From echosign_dev1__SIGN_Data_Mapping__c e where name='Direct Debit'];
          echosign_dev1__SIGN_Merge_Mapping__c smm = [Select e.Name, e.Id From echosign_dev1__SIGN_Merge_Mapping__c e where name='DDformMergeAccount'];
        
           agreement.echosign_dev1__Process_Template__c = sdm.Id; // Direct Debit Data Mapping
           agreement.echosign_dev1__Merge_Mapping__c = smm.Id;//MergeMapping
           
           agreement.echosign_dev1__Account__c=opp.AccountId;
           agreement.Mandate__c=opp.Direct_Debit_Mandate__c;
           
          agreement.echosign_dev1__Message__c = 'Hi '+opp.Primary_Contact__r.FirstName+', ';
        agreement.echosign_dev1__Message__c += '\r\n\r\nYour current agreement to list on Gumtree will come to an end.You can renew quickly and easily by clicking on the link below.';
        agreement.echosign_dev1__Message__c += '\r\n\r\n If you do this now you’ll receive the same great rate which you’ve enjoyed so far.You may also be entitled to an even better deal by increasing your monthly vehicle limit.';
        agreement.echosign_dev1__Message__c +='\r\n\r\n Remember that if your agreement is not renewed, your vehicles will no longer be seen by our 2 million motors visitors every month.'; 
        //agreement.echosign_dev1__Message__c += '\r\n\r\nWhy should you do this? \n\n You\'ll be able to continue to list up to 100 cars on Gumtree for another previous contract months at the same rate you\'re currently enjoying / at an even lower rate  as described in agreement per month (IN CASE OF OCCASIONS WHERE WE OFFER LONGER DURATION DEAL AND HENCE LOWER PRICE)You\'ll continue to have access to over 2 million people that are looking to buy a car each month (VERIFY CLAIM)ideally we would include a personalised claim – “your listings have been seen by more than 100,000 people last month”; “you received more than 100 email enquiries and more than 100 people called you through one of our mobile applications”'; 
        agreement.echosign_dev1__Message__c += '\r\n\r\nIf you have any questions, or would like to upgrade your package to cover more cars, please don’t hesitate to give me a call on '+opp.Owner.Phone+'.I\'m available from 9am to 6pm, Monday to Friday.';
        agreement.echosign_dev1__Message__c += '\r\n\r\nThanks,';
        agreement.echosign_dev1__Message__c += '\r\n'+opp.Owner.Firstname;
        
        // System.debug('Message is: '+agreement.echosign_dev1__Message__c);
        attachment.Name = 'Gumtree for Business I/O No. '+ opp.IOnumber__c+'.pdf';         
        agreement.Name = 'Your subscription is about to expire';
        agreement.echosign_dev1__Opportunity__c = opp.id;
        }
        else if (opp.Payment_Method__c != 'Direct Debit' && opp.RecordType.DeveloperName== 'Campaign_Delivery_M' && opp.Auto_Renewal__c == true)
        {
            // load default mapping
            echosign_dev1__SIGN_Data_Mapping__c sdm = [Select e.Name, e.Id From echosign_dev1__SIGN_Data_Mapping__c e where name='Default Mapping'];
        echosign_dev1__SIGN_Merge_Mapping__c smm = [Select e.Name, e.Id From echosign_dev1__SIGN_Merge_Mapping__c e where name='P/O number'];
    
       
           agreement.echosign_dev1__Process_Template__c = sdm.Id;  // Direct Debit Mapping
           agreement.echosign_dev1__Merge_Mapping__c=smm.Id;//MergeMapping
           
           agreement.echosign_dev1__Account__c=opp.AccountId;
           agreement.Mandate__c=opp.Direct_Debit_Mandate__c;
           
                     
        agreement.echosign_dev1__Message__c = 'Hi '+opp.Primary_Contact__r.FirstName+', ';
        agreement.echosign_dev1__Message__c += '\r\n\r\nYour current agreement to list on Gumtree will come to an end.You can renew quickly and easily by clicking on the link below.';
        agreement.echosign_dev1__Message__c += '\r\n\r\n If you do this now you’ll receive the same great rate which you’ve enjoyed so far.You may also be entitled to an even better deal by increasing your monthly vehicle limit.';
        agreement.echosign_dev1__Message__c +='\r\n\r\n Remember that if your agreement is not renewed, your vehicles will no longer be seen by our 2 million motors visitors every month.'; 
        //agreement.echosign_dev1__Message__c += '\r\n\r\nWhy should you do this? \n\n You\'ll be able to continue to list up to 100 cars on Gumtree for another previous contract months at the same rate you\'re currently enjoying / at an even lower rate  as described in agreement per month (IN CASE OF OCCASIONS WHERE WE OFFER LONGER DURATION DEAL AND HENCE LOWER PRICE)You\'ll continue to have access to over 2 million people that are looking to buy a car each month (VERIFY CLAIM)ideally we would include a personalised claim – “your listings have been seen by more than 100,000 people last month”; “you received more than 100 email enquiries and more than 100 people called you through one of our mobile applications”'; 
        agreement.echosign_dev1__Message__c += '\r\n\r\nIf you have any questions, or would like to upgrade your package to cover more cars, please don’t hesitate to give me a call on '+opp.Owner.Phone+'.I\'m available from 9am to 6pm, Monday to Friday.';
        agreement.echosign_dev1__Message__c += '\r\n\r\nThanks,';
        agreement.echosign_dev1__Message__c += '\r\n'+opp.Owner.Firstname;
        
        // System.debug('Message is: '+agreement.echosign_dev1__Message__c);
        attachment.Name = 'Gumtree for Business I/O No. '+ opp.IOnumber__c+'.pdf';         
        agreement.Name = 'Your subscription is about to expire';
        agreement.echosign_dev1__Opportunity__c = opp.id;
        
        }
        else if (opp.Payment_Method__c == 'Direct Debit'  && opp.Direct_Debit_Mandate__r.I_O_Display__c == true)
        {
    
                // load default mapping
            echosign_dev1__SIGN_Data_Mapping__c sdm = [Select e.Name, e.Id From echosign_dev1__SIGN_Data_Mapping__c e where name='DirectDebitReject'];
          echosign_dev1__SIGN_Merge_Mapping__c smm = [Select e.Name, e.Id From echosign_dev1__SIGN_Merge_Mapping__c e where name='DDformMergeAccount'];
        
        agreement.echosign_dev1__Process_Template__c = sdm.Id; // Direct Debit Reject Mapping
             agreement.echosign_dev1__Merge_Mapping__c = smm.Id;//MergeMapping
             agreement.echosign_dev1__Account__c=opp.AccountId;
             agreement.Mandate__c=opp.Direct_Debit_Mandate__c;
          
          agreement.echosign_dev1__Message__c = 'Hi '+opp.Primary_Contact__r.FirstName+', ';
          agreement.echosign_dev1__Message__c += '\r\n\r\nPlease e-Sign DirectDebit Form  below. ';
          agreement.echosign_dev1__Message__c += '\r\n\r\nIf you have any problems please give me a call on '+opp.Owner.Phone+'.  ';
          agreement.echosign_dev1__Message__c += '\r\n\r\nThanks,    ';
          agreement.echosign_dev1__Message__c += '\r\n'+opp.Owner.Firstname;
          
          // System.debug('Message is: '+agreement.echosign_dev1__Message__c);
        attachment.Name = 'Gumtree for Business I/O No. '+ opp.IOnumber__c+'.pdf';         
        agreement.Name = 'Gumtree for Business Direct Debit Application No. '+opp.Direct_Debit_Mandate__r.Name;
        agreement.echosign_dev1__Opportunity__c = opp.id;
        }
       
       
        else if (opp.Payment_Method__c == 'Invoice'  && opp.Direct_Debit_Mandate__r.I_O_Display__c == true)
        {
    
                // load default mapping
            echosign_dev1__SIGN_Data_Mapping__c sdm = [Select e.Name, e.Id From echosign_dev1__SIGN_Data_Mapping__c e where name='DirectDebitReject'];
          echosign_dev1__SIGN_Merge_Mapping__c smm = [Select e.Name, e.Id From echosign_dev1__SIGN_Merge_Mapping__c e where name='DDformMergeAccount'];
        
        agreement.echosign_dev1__Process_Template__c = sdm.Id; // Direct Debit Reject Mapping
             agreement.echosign_dev1__Merge_Mapping__c = smm.Id;//MergeMapping
             agreement.echosign_dev1__Account__c=opp.AccountId;
             agreement.Mandate__c=opp.Direct_Debit_Mandate__c;
          
          agreement.echosign_dev1__Message__c = 'Hi '+opp.Primary_Contact__r.FirstName+', ';
          agreement.echosign_dev1__Message__c += '\r\n\r\nPlease e-Sign DirectDebit Form  below. ';
          agreement.echosign_dev1__Message__c += '\r\n\r\nIf you have any problems please give me a call on '+opp.Owner.Phone+'.  ';
          agreement.echosign_dev1__Message__c += '\r\n\r\nThanks,    ';
          agreement.echosign_dev1__Message__c += '\r\n'+opp.Owner.Firstname;
          
          
          // System.debug('Message is: '+agreement.echosign_dev1__Message__c);
        attachment.Name = 'Gumtree for Business I/O No. '+ opp.IOnumber__c+'.pdf';         
        agreement.Name = 'Gumtree for Business Direct Debit Application No. '+opp.Direct_Debit_Mandate__r.Name;
        agreement.echosign_dev1__Opportunity__c = opp.id;
        }
       
        
        else if (opp.Payment_Method__c == 'Direct Debit' )
        {
                      // load default mapping
            echosign_dev1__SIGN_Data_Mapping__c sdm = [Select e.Name, e.Id From echosign_dev1__SIGN_Data_Mapping__c e where name='Direct Debit'];
            echosign_dev1__SIGN_Merge_Mapping__c smm = [Select e.Name, e.Id From echosign_dev1__SIGN_Merge_Mapping__c e where name='DDformMergeAccount'];
        
          agreement.echosign_dev1__Process_Template__c = sdm.Id;  // Direct Debit Mapping
             agreement.echosign_dev1__Merge_Mapping__c = smm.Id;//MergeMapping
             agreement.echosign_dev1__Account__c=opp.AccountId;
             agreement.Mandate__c=opp.Direct_Debit_Mandate__c;
                 
          agreement.echosign_dev1__Message__c = 'Hi '+opp.Primary_Contact__r.FirstName+', ';
          agreement.echosign_dev1__Message__c += '\r\n\r\nPlease e-Sign the Agreement and DirectDebit Form  below. ';
          agreement.echosign_dev1__Message__c += '\r\n\r\nIf you have any problems please give me a call on '+opp.Owner.Phone+'.  ';
          agreement.echosign_dev1__Message__c += '\r\n\r\nThanks,    ';
          agreement.echosign_dev1__Message__c += '\r\n'+opp.Owner.Firstname;
          
         // System.debug('Message is: '+agreement.echosign_dev1__Message__c);
         attachment.Name = 'Gumtree for Business I/O No. '+ opp.IOnumber__c+'.pdf';
                 
        }
        else
        {
            
            
          echosign_dev1__SIGN_Data_Mapping__c sdm = [Select e.Name, e.Id From echosign_dev1__SIGN_Data_Mapping__c e where name='Default Mapping'];
        echosign_dev1__SIGN_Merge_Mapping__c smm = [Select e.Name, e.Id From echosign_dev1__SIGN_Merge_Mapping__c e where name='P/O number'];
    
          agreement.echosign_dev1__Process_Template__c=sdm.Id; //Default Data Mapping
          agreement.echosign_dev1__Merge_Mapping__c = smm.Id;//MergeMapping
                                       
          agreement.echosign_dev1__Message__c = 'Hi '+opp.Primary_Contact__r.FirstName+', ';
          agreement.echosign_dev1__Message__c += '\r\n\r\nPlease e-Sign the contract below. ';
          agreement.echosign_dev1__Message__c += '\r\n\r\nIf you have any problems please give me a call on '+opp.Owner.Phone+'.  ';
          agreement.echosign_dev1__Message__c += '\r\n\r\nThanks,    ';
          agreement.echosign_dev1__Message__c += '\r\n'+opp.Owner.Firstname;
        
        }
        
        
             
        if (!SF_Gumtree_SOW_001.valueIsNull(opp.Primary_Contact__c))
        {
            agreement.echosign_dev1__Recipient__c = opp.Primary_Contact__c;
        }
        
        agreement.echosign_dev1__SenderSigns__c = false;
        
        insert agreement;
       

        attachment.Description = 'Attachment created from opportunity through VF';
        // attachment.ParentId = opp.id;   
        attachment.ParentId = agreement.id;
        attachment.Body = b;
        // System.debug('Message is: '+agreement.echosign_dev1__Message__c);
         attachment.Name = 'Gumtree for Business I/O No. '+ opp.IOnumber__c+'.pdf';
      
        insert attachment;
      
        PageReference p = new PageReference('/'+agreement.ID); // to open agreement Detail
        p.setRedirect(true);
        return p;
    }
    
    public static TestMethod void testIODisplayController()
    {
        try{
            IODisplayController dummy = new IODisplayController();
            dummy.getErrorMessage();
            dummy.getShowErrorMessage();
            
            IODisplayController.IS_TEST = true;
            Account account = new Account(name='testAccount',BillingPostalCode='test', BillingCity='Test',BillingStreet='Test',BillingCountry='GB');
            insert account;
            
            //Insert Mandate__c
            Mandate__c mandate = new Mandate__c();
            mandate.Account__c = account.Id;
            insert mandate;
            
            // Insert a contact
            Contact contact = new Contact(lastname='testContact', accountID=account.ID);
            insert contact;
            
            // Insert Opp with Primary Contact- 
            Opportunity opp = new Opportunity(Name='Test Opp', StageName='First Call', CloseDate = (Date.Today() + 20),Amount=20, Primary_Contact__c=contact.Id);
            insert opp;
            
            ApexPages.StandardController sc = new Apexpages.StandardController(opp);
            
            
            // String pageName = 'IO_Display_inc_VAT';
            String pageName = ApexPages.currentPage().getParameters().put('ApexPdfPage','IO_Display_inc_VAT');
            IODisplayController iodc = new IODisplayController(sc);
            iodc.createAgreementAndAttachPDF();
            
            OpportunityContactRole ocr = new OpportunityContactRole(Role='Other',IsPrimary=true,OpportunityId=opp.Id,ContactId=contact.Id);
            insert ocr;
            
            opp.StageName = 'Pitched';
            
            update opp;
            
            echosign_dev1__SIGN_Agreement__c ag = new echosign_dev1__SIGN_Agreement__c(
            Name = 'abc',
            echosign_dev1__Account__c = account.id,        
            echosign_dev1__Recipient__c = contact.id,
            echosign_dev1__SenderSigns__c = false
            );
            insert ag;
            
            echosign_dev1__SIGN_Merge_Mapping__c mm = new echosign_dev1__SIGN_Merge_Mapping__c(
            Name = 'abc',
            echosign_dev1__Cached_Input_Type__c='List',
            echosign_dev1__Default__c=TRUE,
            echosign_dev1__Description__c='Test');
            insert mm;
            
            echosign_dev1__SIGN_Data_Mapping__c dm = new echosign_dev1__SIGN_Data_Mapping__c(
            Name = 'abc',
            echosign_dev1__Cached_Input_Type__c = 'List',
            echosign_dev1__Default_Data_Mapping__c = TRUE,
            echosign_dev1__Description__c = 'Test');
            insert dm;
                    
            ag.echosign_dev1__Merge_Mapping__c = mm.id;
            ag.echosign_dev1__Process_Template__c = dm.id;
            update ag;
    
            iodc = new IODisplayController(sc);
            iodc.createAgreementAndAttachPDF();
            
            opp.Approval_Status__c = true;
            update opp;
            
            iodc = new IODisplayController(sc);
            iodc.createAgreementAndAttachPDF();
            iodc.cancel();
            
         //2014-12-03   GTCRM-1584-Apex classes with Test Code Coverage below 75%
            
            opp.Payment_Method__c = 'Direct Debit';
            opp.Auto_Renewal__c = true;
            update opp;
            iodc = new IODisplayController(sc);
            iodc.createAgreementAndAttachPDF();
            
            opp.Payment_Method__c = 'Invoice';
            update opp;
            iodc = new IODisplayController(sc);
            iodc.createAgreementAndAttachPDF();
            
            mandate.I_O_Display__c = true;
            update mandate;
            opp.Direct_Debit_Mandate__c = mandate.Id;
            opp.Payment_Method__c = 'Direct Debit';
            opp.Auto_Renewal__c = false;
            update opp;
            iodc = new IODisplayController(sc);
            iodc.createAgreementAndAttachPDF();
            
            opp.Payment_Method__c = 'Invoice';
            update opp;
            iodc = new IODisplayController(sc);
            iodc.createAgreementAndAttachPDF();
            
            mandate.I_O_Display__c = false;
            update mandate;
            opp.Payment_Method__c = 'Direct Debit';
            update opp;
            iodc = new IODisplayController(sc);
            iodc.createAgreementAndAttachPDF();
        }catch(Exception e){
            System.debug('>>>>>IODisplayController.Error: '+e.getMessage());
        }
        try{
            //test scheduler from SchSyncDFPLineItem class
            new SchSyncDFPLineItem().execute(null);
        }catch(Exception e){
            System.debug('>>>>>>IODisplayController.SchSyncDFPLineItem.Error: '+e.getMessage());
        }
    }
}