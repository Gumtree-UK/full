/**
*@Author : SPP
*@Date : 28/08/2014
*@Business : 
Helper class

//GTCRM-1464 Gumtree UK Direct Debit - Activation for Jobs 
-2014-03-12 - GTCRM-1804-Housing: Incorrect I/O template showing as motors ( Added RecordtypeName)

*/
public with sharing class Utils {
    
    public static String Display_Campaign_Delivery ='Display_Campaign_Delivery';
    public static String Campaign_Delivery_H ='Campaign_Delivery_H';
    public static String Campaign_Delivery ='Campaign_Delivery';
    public static String Campaign_Delivery_M ='Campaign_Delivery_M';
    public static String Daily_Deal_Delivery ='Daily_Deal_Delivery';
    public static String Daily_Deal_Initiation ='Daily_Deal_Initiation';
    public static String Order_Management ='Order_Management';
    public static String Display_Order_Management ='Display_Order_Management';
    public static String Display_Sales_Management ='Display_Sales_Management';
    public static String Sales_Management_H ='Sales_Management_H';
    public static String Sales_Management ='Sales_Management';
    public static String Sales_Management_M ='Sales_Management_M';
    
    // map opp rec type
    public static Map<String,Id> rectype;
 
    public static Map<String,Id> loadOppRecordType() {
        
        // load record type
        if (rectype==null) {        
            rectype = new Map<String,Id>();
            for (RecordType rt : [Select r.Name, r.Id, r.DeveloperName From RecordType r where SobjectType='Opportunity']) {
                rectype.put(rt.DeveloperName,rt.id);
            }
        }
        
        return recType;
    }
    
    public static String getPdfPagenameForGenerateAndAttach(Opportunity opp){

        String urlpage = '/apex/GeneratePdfAndAttach?id='+opp.Id + '&ApexPdfPage=' + getPdfPagename(opp);
        
        return urlpage;
   
   
    } 
   
    public static String getPdfPagenameForEchoSign(Opportunity opp){
        
        String urlpage = '/apex/' + getPdfPagename(opp) + '?id='+opp.Id;
        
        return urlpage;
        
    }
    /**
    *
    *
    */
    public static String getPdfPagename(Opportunity opp){
        String OppRecType = opp.RecordType.DeveloperName;
        Boolean ApplyVAT = opp.Account.Apply_VAT__c;
        String Discount = opp.Total_Discount_Check__c;
        String Payment = opp.Payment_Method__c;
        
        String HousingNoDiscExcVAT = 'IO_HousingNoDiscExcVAT';
        String HousingNoDiscIncVAT = 'IO_HousingNoDiscIncVAT';
        
        String HousingDiscExcVAT = 'IO_HousingDiscExcVAT';
        String HousingDiscIncVAT = 'IO_HousingDiscIncVAT';
        
        String DDHousingNoDiscExcVAT = 'IO_HousingNoDiscExcVAT_DirectDebit';
        String DDHousingNoDiscIncVAT = 'IO_HousingNoDiscIncVAT_DirectDebit';
        
        String DDHousingDiscExcVAT = 'IO_HousingDiscExcVAT_DirectDebit';
        String DDHousingDiscIncVAT = 'IO_HousingDiscIncVAT_DirectDebit';
        
        String JobsNoDiscExcVAT = 'IO_JobsNoDiscExcVAT';
        String JobsNoDiscIncVAT = 'IO_JobsNoDiscIncVAT';
        
        String JobsDiscExcVAT = 'IO_JobsDiscExcVAT';
        String JobsDiscIncVAT = 'IO_JobsDiscIncVAT';
        
        
        String DDJobsNoDiscExcVAT = 'IO_JobsNoDiscExcVAT_DirectDebit';
        String DDJobsNoDiscIncVAT = 'IO_JobsNoDiscIncVAT_DirectDebit';
        
        String DDJobsDiscExcVAT = 'IO_JobsDiscExcVAT_DirectDebit';
        String DDJobsDiscIncVAT = 'IO_JobsDiscIncVAT_DirectDebit';
        
        String MotorsNoDiscExcVAT = 'IO_MotorsNoDiscExcVAT';
        String MotorsNoDiscIncVAT = 'IO_MotorsNoDiscIncVAT';
        
        String MotorsDiscExcVAT = 'IO_MotorsDiscExcVAT';
        String MotorsDiscIncVAT = 'IO_MotorsDiscIncVAT';
        
        String DDMotorsNoDiscIncVAT = 'IO_MotorsNoDiscIncVAT_DirectDebit';
        String DDMotorsNoDiscExcVAT = 'IO_MotorsNoDiscExcVAT_DirectDebit';
        
        String DDMotorsDiscIncVAT = 'IO_MotorsDiscIncVAT_DirectDebit';
        String DDMotorsDiscExcVAT = 'IO_MotorsDiscExcVAT_DirectDebit';
        
        String MergeUrl = '';
        
        if (OppRecType == 'Campaign_Delivery_M' && Discount == 'NoDiscount' && Payment == 'Direct Debit' && ApplyVAT == true)
        {
            MergeURL = DDMotorsNoDiscIncVAT;
        }
        else if (OppRecType == 'Campaign_Delivery_M' && Discount == 'NoDiscount' && Payment == 'Direct Debit' && ApplyVAT == false)
        {
        MergeURL = DDMotorsNoDiscExcVAT;
        }
        else if (OppRecType == 'Campaign_Delivery_M' && Discount == 'Discount' && Payment == 'Direct Debit' && ApplyVAT == false)
        {
            MergeURL = DDMotorsDiscExcVAT;
        }
        else if (OppRecType == 'Campaign_Delivery_M' && Discount == 'Discount' && Payment == 'Direct Debit' && ApplyVAT == true)
        {
            MergeURL = DDMotorsDiscIncVAT;
        }
        else if(OppRecType == 'Campaign_Delivery_H' && Discount == 'NoDiscount' && Payment == 'Direct Debit' && ApplyVAT == false)
        {
            MergeURL = DDHousingNoDiscExcVAT;
        }
        else if (OppRecType == 'Campaign_Delivery_H' && Discount == 'NoDiscount' && Payment == 'Direct Debit' && ApplyVAT == true)
        {
            MergeURL = DDHousingNoDiscIncVAT;
        }
        else if (OppRecType == 'Campaign_Delivery_H' && Discount == 'Discount' && Payment == 'Direct Debit' && ApplyVAT ==false)
        {
            MergeURL = DDHousingDiscExcVAT;
        }
        else if (OppRecType == 'Campaign_Delivery_H' && Discount == 'Discount' && Payment == 'Direct Debit' && ApplyVAT == true)
        {
            MergeURL = DDHousingDiscIncVAT;
        }
        
         else if(OppRecType == 'Campaign_Delivery' && Discount == 'NoDiscount' && Payment == 'Direct Debit' && ApplyVAT == false)
        {
            MergeURL = DDJobsNoDiscExcVAT;
        }
        else if (OppRecType == 'Campaign_Delivery' && Discount == 'NoDiscount' && Payment == 'Direct Debit' && ApplyVAT == true)
        {
            MergeURL = DDJobsNoDiscIncVAT;
        }
        else if (OppRecType == 'Campaign_Delivery' && Discount == 'Discount' && Payment == 'Direct Debit' && ApplyVAT ==false)
        {
            MergeURL = DDJobsDiscExcVAT ;
        }
        else if (OppRecType == 'Campaign_Delivery' && Discount == 'Discount' && Payment == 'Direct Debit' && ApplyVAT == true)
        {
            MergeURL = DDJobsDiscIncVAT  ;
        }
        else if(OppRecType == 'Campaign_Delivery_H' && Discount == 'NoDiscount' && ApplyVAT == false)
        {
            MergeURL = HousingNoDiscExcVAT;
        }
        else if (OppRecType == 'Campaign_Delivery_H' && Discount == 'NoDiscount' && ApplyVAT == true)
        {
            MergeURL = HousingNoDiscIncVAT;
        }
        else if (OppRecType == 'Campaign_Delivery_H' && Discount == 'Discount' && ApplyVAT == false)
        {
            MergeURL = HousingDiscExcVAT;
        }
        else if (OppRecType == 'Campaign_Delivery_H' && Discount == 'Discount' && ApplyVAT == true)
        {
            MergeURL = HousingDiscIncVAT;
        }
        else if(OppRecType == 'Campaign_Delivery_M' && Discount == 'NoDiscount' && ApplyVAT == false)
        {
            MergeURL = MotorsNoDiscExcVAT;
        }
        else if (OppRecType == 'Campaign_Delivery_M' && Discount == 'NoDiscount' && ApplyVAT == true)
        {
            MergeURL = MotorsNoDiscIncVAT;
        }
        else if (OppRecType == 'Campaign_Delivery_M' && Discount == 'Discount' && ApplyVAT == false)
        {
            MergeURL = MotorsDiscExcVAT;
        }
        else if (OppRecType == 'Campaign_Delivery_M' && Discount == 'Discount' && ApplyVAT == true)
        {
            MergeURL = MotorsDiscIncVAT;
        }
        else if (Discount == 'NoDiscount' && ApplyVAT == false)
        {
            MergeURL = JobsNoDiscExcVAT;
        }
        else if (Discount == 'NoDiscount' && ApplyVAT == true)
        {
            MergeURL = JobsNoDiscIncVAT;
        }
        else if (Discount == 'Discount' && ApplyVAT == false)
        {
            MergeURL = JobsDiscExcVAT;
        }
        else if (Discount == 'Discount' && ApplyVAT == true)
        {
            MergeURL = JobsDiscIncVAT;
        } 
        return MergeURL;
    }
    
    
    /**
    * Used by WSEchoSignAuto, IODisplayController
    * EchoSign steps
    * create a template first
    * then use Id agreementId = echosign_dev1.AgreementTemplateService.load(agreementTemplateId,oppId);
    * to create the agreement
    * attachment must pushed to Opp.
    *
    */
    public static Id createEchoSignAgreementTemplate(Opportunity opp) {
        
           //create agreement template
        echosign_dev1__Agreement_Template__c agreementTemplate = new echosign_dev1__Agreement_Template__c();
        
        agreementTemplate.Name = 'Gumtree for Business I/O No. '+ opp.IOnumber__c;
        agreementTemplate.echosign_dev1__Name__c = agreementTemplate.Name;
        
        agreementTemplate.echosign_dev1__Opportunity__c = opp.Id;
        agreementTemplate.echosign_dev1__Account__c=opp.AccountId;
        
        agreementTemplate.echosign_dev1__Auto_Send__c = true;
        String mandateId = null;
       
        //@Remarks : if you need more sfdc fields, in the message template
        // ensure to update the soql in apex class sendEchoSignEmail
        //TH 28-10-2014 Changes in the email Templates (GTCRM-491)
        Double salePrice =null ;
        decimal qty = null ;
        Double Monthlyprice ;
        decimal lm ;
        Double discountprice  ; 
        list<OpportunityLineItem> opli=[Select Sales_Price_Net_Net__c,Net_Net_Net__c, Quantity, Length_Months__c From OpportunityLineItem  where OpportunityId =:opp.id  order by Length_Months__c,Quantity DESC limit 1];
        if(!opli.isEmpty()){
            salePrice = opli.get(0).Net_Net_Net__c;
            qty = Integer.valueOf(opli.get(0).Quantity);
            lm = opli.get(0).Length_Months__c;
            
            if( salePrice != null && qty!=null && lm != null){
               discountprice = ((salePrice/52)/qty).setScale(2);//((PRICE/CARS)*12)/52 (calculation which is Net_Net_Net__c /quantity )*12/52 )
                Monthlyprice=(saleprice/lm).setScale(2);
            }
                   
        }
        if (opp.Payment_Method__c == 'Direct Debit' && opp.RecordType.DeveloperName== 'Campaign_Delivery_M' )
        {
       
            // load default mapping
            echosign_dev1__SIGN_Data_Mapping__c sdm = [Select e.Name, e.Id From echosign_dev1__SIGN_Data_Mapping__c e where name='Direct Debit'];
            echosign_dev1__SIGN_Merge_Mapping__c smm = [Select e.Name, e.Id From echosign_dev1__SIGN_Merge_Mapping__c e where name='DDformMergeAccount'];
           
           
           agreementTemplate.echosign_dev1__Data_Mapping__c = sdm.Id;  // Direct Debit Mapping
           agreementTemplate.echosign_dev1__Merge_Mapping__c=smm.Id;//MergeMapping
           mandateId=opp.Direct_Debit_Mandate__c;
           // agreementTemplate.echosign_dev1__Message__c=agreementTemplate.echosign_dev1__Message__c.replace('"','');
            agreementTemplate.echosign_dev1__Message__c = 'Hi '+opp.Primary_Contact__r.FirstName+', ';
            //TH 28-10-2014 
            //agreementTemplate.echosign_dev1__Message__c += '\r\n\r\nYour current agreement to list on Gumtree will come to an end. You can renew quickly and easily by clicking on the link below.';
            //agreementTemplate.echosign_dev1__Message__c += '\r\n\r\n If you do this now you’ll receive the same great rate that you’ve enjoyed so far for the same period of time to put your stock in front of almost 1.9 million monthly visitors on the UK’s second largest used car website.';
             agreementTemplate.echosign_dev1__Message__c += '\r\n\r\n Your current agreement to list vehicles at a fixed price on Gumtree will soon come to an end.You can renew quickly and easily by clicking on the link below.';
             agreementTemplate.echosign_dev1__Message__c += '\r\n\r\n If you do this now you’ll continue to pay just £'+ Monthlyprice +' per month for the next '+ lm +' months for up to '+  qty+' cars – that’s just £'+ discountprice +' per car per week to put your stock in front of 1.9 million* monthly visitors.';
            //agreementTemplate.echosign_dev1__Message__c +='\r\n\r\n Remember that if your agreement is not renewed, your vehicles will no longer be seen by our 2 million motors visitors every month.'; 
            //agreementTemplate.echosign_dev1__Message__c += '\r\n\r\nWhy should you do this? \n\n You\'ll be able to continue to list up to 100 cars on Gumtree for another previous contract months at the same rate you\'re currently enjoying / at an even lower rate  as described in agreement per month (IN CASE OF OCCASIONS WHERE WE OFFER LONGER DURATION DEAL AND HENCE LOWER PRICE)You\'ll continue to have access to over 2 million people that are looking to buy a car each month (VERIFY CLAIM)ideally we would include a personalised claim – “your listings have been seen by more than 100,000 people last month”; “you received more than 100 email enquiries and more than 100 people called you through one of our mobile applications”'; 
            // agreementTemplate.echosign_dev1__Message__c += '\r\n\r\n If you’d like to secure this great offer then just click on the link above, or if you would like to talk to me about making any changes to your package then please contact me on '+opp.Owner.Phone+'.I\'m available from 9am to 6pm, Monday to Friday.';//Theary 28-10-2014
           agreementTemplate.echosign_dev1__Message__c += '\r\n\r\n If you’d like to secure this great offer for the next  '+ lm +' months then just click on the link above, or if you would like to talk to me about making any changes to your package then please contact me on '+opp.Owner.Phone+'. I\'m available from 9am to 6pm, Monday to Friday.';
           agreementTemplate.echosign_dev1__Message__c += '\r\n\r\n If we don’t hear from you your ads will stay on Gumtree on our rolling monthly package, but act now to secure your price for the next '+ lm+' months!'; 
            agreementTemplate.echosign_dev1__Message__c += '\r\n\r\nThanks,';
            agreementTemplate.echosign_dev1__Message__c += '\r\n'+opp.Owner.Firstname;
           agreementTemplate.echosign_dev1__Message__c += '\r\n *Source: comScore June 2014';
            
            
               
         agreementTemplate.Name = 'Your subscription is about to expire';
        agreementTemplate.echosign_dev1__Opportunity__c = opp.id;
    
        }
         
        else if (opp.Payment_Method__c != 'Direct Debit' && opp.RecordType.DeveloperName== 'Campaign_Delivery_M')
        {
            echosign_dev1__SIGN_Data_Mapping__c sdm = [Select e.Name, e.Id From echosign_dev1__SIGN_Data_Mapping__c e where name='Default Mapping'];
            echosign_dev1__SIGN_Merge_Mapping__c smm = [Select e.Name, e.Id From echosign_dev1__SIGN_Merge_Mapping__c e where name='P/O number'];
           
            agreementTemplate.echosign_dev1__Data_Mapping__c = sdm.Id; //Default Data Mapping
            agreementTemplate.echosign_dev1__Merge_Mapping__c=smm.Id;//MergeMapping
           //  agreementTemplate.echosign_dev1__Message__c=agreementTemplate.echosign_dev1__Message__c.replace('"','');
            agreementTemplate.echosign_dev1__Message__c = 'Hi '+opp.Primary_Contact__r.FirstName+', ';
            //TH 28-10-2014 
            //agreementTemplate.echosign_dev1__Message__c += '\r\n\r\nYour current agreement to list on Gumtree will come to an end. You can renew quickly and easily by clicking on the link below.';
            //agreementTemplate.echosign_dev1__Message__c += '\r\n\r\n If you do this now you’ll receive the same great rate that you’ve enjoyed so far for the same period of time to put your stock in front of almost 1.9 million monthly visitors on the UK’s second largest used car website.';
             agreementTemplate.echosign_dev1__Message__c += '\r\n\r\n Your current agreement to list vehicles at a fixed price on Gumtree will soon come to an end.You can renew quickly and easily by clicking on the link below.';
             agreementTemplate.echosign_dev1__Message__c += '\r\n\r\n If you do this now you’ll continue to pay just £'+ Monthlyprice +' per month for the next '+ lm +' months for up to '+  qty+' cars – that’s just £'+ discountprice +' per car per week to put your stock in front of 1.9 million* monthly visitors.';
            //agreementTemplate.echosign_dev1__Message__c +='\r\n\r\n Remember that if your agreement is not renewed, your vehicles will no longer be seen by our 2 million motors visitors every month.'; 
            //agreementTemplate.echosign_dev1__Message__c += '\r\n\r\nWhy should you do this? \n\n You\'ll be able to continue to list up to 100 cars on Gumtree for another previous contract months at the same rate you\'re currently enjoying / at an even lower rate  as described in agreement per month (IN CASE OF OCCASIONS WHERE WE OFFER LONGER DURATION DEAL AND HENCE LOWER PRICE)You\'ll continue to have access to over 2 million people that are looking to buy a car each month (VERIFY CLAIM)ideally we would include a personalised claim – “your listings have been seen by more than 100,000 people last month”; “you received more than 100 email enquiries and more than 100 people called you through one of our mobile applications”'; 
            // agreementTemplate.echosign_dev1__Message__c += '\r\n\r\n If you’d like to secure this great offer then just click on the link above, or if you would like to talk to me about making any changes to your package then please contact me on '+opp.Owner.Phone+'.I\'m available from 9am to 6pm, Monday to Friday.';//Theary 28-10-2014
            agreementTemplate.echosign_dev1__Message__c += '\r\n\r\n If you’d like to secure this great offer for the next  '+ lm +' months then just click on the link above, or if you would like to talk to me about making any changes to your package then please contact me on '+opp.Owner.Phone+'. I\'m available from 9am to 6pm, Monday to Friday.';
            agreementTemplate.echosign_dev1__Message__c += '\r\n\r\n If we don’t hear from you your ads will stay on Gumtree on our rolling monthly package, but act now to secure your price for the next '+ lm+' months!'; 
            agreementTemplate.echosign_dev1__Message__c += '\r\n\r\nThanks,';
            agreementTemplate.echosign_dev1__Message__c += '\r\n'+opp.Owner.Firstname;
            agreementTemplate.echosign_dev1__Message__c += '\r\n *Source: comScore June 2014';
            
       
        agreementTemplate.Name = 'Your subscription is about to expire';
        agreementTemplate.echosign_dev1__Opportunity__c = opp.id;
        }
        
        
        agreementTemplate.echosign_dev1__Master_Object_Type__c = 'Opportunity';        
        agreementTemplate.echosign_dev1__Signature_Type__c = 'e-Signature';
        insert agreementTemplate;
        
        //add recipientTemplate
        if (opp.Primary_Contact__c!=null) {
            echosign_dev1__Recipient_Template__c recipientTemplate = new echosign_dev1__Recipient_Template__c();
            recipientTemplate.echosign_dev1__Recipient_Type__c = 'Predefine the Recipient';
            recipientTemplate.echosign_dev1__Recipient_Type__c='Contact';
            recipientTemplate.echosign_dev1__Contact_Recipient__c=opp.Primary_Contact__c;
            recipientTemplate.echosign_dev1__Index__c = 1;
            recipientTemplate.echosign_dev1__Agreement_Template__c = agreementTemplate.Id;
            insert recipientTemplate;
        }
        
        //add attachment template
        echosign_dev1__Attachment_Template__c attachmentTemplate = new echosign_dev1__Attachment_Template__c();
        attachmentTemplate.echosign_dev1__Index__c = 1;
        attachmentTemplate.echosign_dev1__Type__c = 'Document from Master Object';
        attachmentTemplate.echosign_dev1__Attachment_Selection_Field__c = 'Created Date';
        attachmentTemplate.echosign_dev1__Agreement_Template__c = agreementTemplate.Id;
        insert attachmentTemplate;
        
        
        // add the additional mapping
        if (mandateId!=null) {
            echosign_dev1__Field_Template__c fieldTemplate = new echosign_dev1__Field_Template__c();
            fieldTemplate.echosign_dev1__Type__c = 'Input Specific Value';
            fieldTemplate.echosign_dev1__Constant_Value__c=mandateId;
            fieldTemplate.echosign_dev1__Agreement_Field__c='Mandate__c';        
            fieldTemplate.echosign_dev1__Agreement_Template__c = agreementTemplate.Id;
            insert fieldTemplate;
        }
        
        
        return agreementTemplate.Id;
            
    }
    
    /**
    *
    */
    public static Id generateAgreement(Id agreementTemplateId, Id oppId, boolean deletetemplate) {
    
        Id agreementId = echosign_dev1.AgreementTemplateService.load(agreementTemplateId,oppId);
        if (agreementId!=null && deletetemplate) {
            delete [Select Id from echosign_dev1__Agreement_Template__c where Id=:agreementTemplateId];
        }
        
        return agreementId;
    
    }
}