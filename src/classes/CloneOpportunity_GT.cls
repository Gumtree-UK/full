/* 
Clone opportunity and related lists on button click
23-02-2015- GTCRM-1763-Submitter Id to Opportunity owner when sending for approval during the auto create of opportunity.
27-02-2014-GTCRM-1823- Display opp clone issue with length pre-population
@Revision : SPP - 15/08/2014

Update the clone method to return the list opp ids cloned.

Change log;
- 2015-03-20 - GTCRM-1887 - Clone opportunity should not clone direct debit mandate field
- 2015-04-27 - GTCRM-1735 - Ability for sales to take an upfront payment on opportunity
- 2015-05-21 - GTCRM-2028 - SOX controls: Signed contract attached on opportunity level

 */
 global class CloneOpportunity_GT {
    public static Boolean IS_TEST = false;
    private static final String BILLING_CPM = 'CPM';
     private static final String OPP_NAME_CONTAIN_AC = ' - AC';
    
    
    
    
    private static List<sObject> getSObject(String sObjectName, String queryFrom) {
        try {
            Schema.DescribeSObjectResult r = null;
            Map<String, Schema.SObjectField> M = new Map<String, Schema.SObjectField>();
            List<sObject> Slist = null;
            String SOQL = '';
            sObject S = null;
               
            // Get the sObject describe result for the Opportunity object
            r = Schema.getGlobalDescribe().get(sObjectName).getDescribe();

            //Generate a Map of the fields
            M = r.fields.getMap();

            //Loop through the list of Field Names and concatenate the SOQL query string
            SOQL = 'SELECT ';
            for (String fieldName : M.keySet()){
                //   System.debug('fieldName: ' + fieldName);
                SOQL += fieldName + ',';
            }

            //Remove the last , unnecessary comma
            SOQL = SOQL.substring(0,SOQL.length()-1);

            //Append the FROM and WHERE clause, using LIMIT 1 as an example
            SOQL += ' ' + queryFrom;
            //Execute SOQL
            System.debug('XXXXXXXX SOQL-->'+SOQL);
            SList = Database.query(SOQL);

            return SList;
        }
        catch(Exception e) {
            return null;
        }
    }
 
    webservice static String cloneOpp(list<String> oppid, boolean Renew) {
        
        
            // load record with Key as DeveloperName
        Map<String,Id> recTypes =  Utils.loadOppRecordType();
        
       List<sObject> Slist = null;
        map<id,id> OppOldNewMap = new map<id,id>();
        Savepoint sp = Database.setSavepoint();
        try {
            string inString  = '';
            for (String tmpId: oppid) {
                inString += '\'' + tmpId +  '\'' + ',';
            }
            inString = inString.substring(0,inString.length()-1);
            String queryFrom = 'FROM Opportunity where Id in ('+ inString + ')';
            Slist = getSObject('Opportunity', queryFrom);
        
            //Cast the sObject type into an Opportunity
            List<Opportunity> opp = new List<Opportunity>();
            if (SList == null) {
                return null;
            }
            for (sObject So : Slist) {
                Opportunity tmpOpp = (Opportunity)So;
                tmpOpp.ClonedFrom__c = tmpOpp.Id;
                opp.add(tmpOpp);
            }
            Slist = null;

            if (opp[0] != null) {
        
                map<id,id> OppAccOwnerMap = new map<id,id>();
                
                
                Opportunity[] oppCloneList = opp.deepClone(false);
                Opportunity[] oppCloneListNew = new list<Opportunity>();
                opp = null;
                set<id> oppTerm = new set<id>();
                set<id> oppTermNew = new set<id>();
                for (Opportunity tmpOpp: oppCloneList) {
                    Opportunity oppClone = tmpOpp;
                    
                    //oppClone.RecordTypeId = '01220000000YaHAAA0';//?  OPP. RecordTypeid=?01220000000YaHAAA0? (Campaign Delivery Housing)
                    oppClone.StageName = 'Needs Establishment';
                    oppClone.Order_ID_Dart__c = null;
                    oppClone.P_O_Number__c = null;
                    oppClone.CC_Reference__c = null;
                    oppClone.Approved_Amount_Net_Net__c = null;
                    oppClone.Approval_Status__c = false;
                    oppClone.Probability =0.30;
                    oppClone.Approval_Cancellation__c= false;
                    oppClone.IsCancellationPending__c = false;
                    oppClone.Auto_Renewal__c = false;
                    // 2015-03-20 - GTCRM-1887 - Clone opportunity should not clone direct debit mandate field
                    oppClone.Direct_Debit_Mandate__c = null;
                    
                    // 2015-04-27 - GTCRM-1735 - Ability for sales to take an upfront payment on opportunity
                    oppClone.Payment_Token__c = null;
                    oppClone.Last_Payment_Taken__c = null; 
                    oppClone.Payment_Amount__c = null;
                    oppClone.Transaction_Id__c = null;
                   
                    // 2015-05-21 - GTCRM-2028 - SOX controls: Signed contract attached on opportunity level
                    oppClone.Signed_Contract_Attached__c = false;
                   
                    if ( oppClone.RecordTypeId == recTypes.get(Utils.Campaign_Delivery)) {oppClone.RecordTypeId = recTypes.get(Utils.Sales_Management);} //Campaign Delivery (J) -->   Sales Management (J)
                    else if ( oppClone.RecordTypeId == recTypes.get(Utils.Campaign_Delivery_H)) {oppClone.RecordTypeId = recTypes.get(Utils.Sales_Management_H);} //Campaign Delivery (H) --> Sales Management (H)
                    else if ( oppClone.RecordTypeId == recTypes.get(Utils.Campaign_Delivery_M)) {oppClone.RecordTypeId = recTypes.get(Utils.Sales_Management_M);} //Campaign Delivery (M) --> Sales Management (M)
                    else if ( oppClone.RecordTypeId == recTypes.get(Utils.Display_Campaign_Delivery)) {oppClone.RecordTypeId = recTypes.get(Utils.Display_Sales_Management);} //Campaign Delivery (D) --> Sales Management (D)
                    //else if ( oppClone.RecordTypeId == recTypes.get(Utils.Daily_Deal_Delivery)) {oppClone.RecordTypeId = recTypes.get(Utils.Daily_Deal_Initiation);} //Daily Deal Delivery --> Daily Deal Initiation
                    //else if ( oppClone.RecordTypeId == recTypes.get(Utils.Campaign_Delivery_M)) {oppClone.RecordTypeId = recTypes.get(Utils.Sales_Management_M);} //Daily Deal Delivery --> Daily Deal Initiation
                    
                    oppClone.CloseDate = date.today();
                    
                    oppCloneListNew.add(oppClone);
                }
                insert oppCloneListNew;
                for (Opportunity tmpOpp: oppCloneListNew){
                  OppOldNewMap.put(tmpOpp.ClonedFrom__c, tmpOpp.id);
                }
                system.debug('XXXXXXXXXXXXXXXXXXXXX oppCloneListNew-->'+oppCloneListNew);
                system.debug('XXXXXXXXXXXXXXXXXXXXX OppOldNewMap-->'+OppOldNewMap);
                //set of new Opp, which were TERM
                for(id idTmp:oppTerm){
                    oppTermNew.add(OppOldNewMap.get(idTmp));
                }
            
                // clone ContactRoles
                queryFrom = 'From OpportunityContactRole where OpportunityId in ('+ inString + ')';
                Slist = getSObject('OpportunityContactRole', queryFrom);

                if (SList == null) {
                    return oppid[0];
                }
                
                List<OpportunityContactRole> ocrs = new List<OpportunityContactRole>();
                for (sObject So : Slist) {
                    System.debug((OpportunityContactRole)So);
                    ocrs.add((OpportunityContactRole)So);
                }
                Slist = null;

        if (!ocrs.isEmpty()) {
          OpportunityContactRole[] ocrCloneList = ocrs.deepClone(false);
          ocrs = null;
          List<OpportunityContactRole> ocrsNew = new List<OpportunityContactRole>();
          for (OpportunityContactRole ocr : ocrCloneList){
            ocr.OpportunityId = OppOldNewMap.get(ocr.OpportunityId);
            ocrsNew.add(ocr);
          }
          insert ocrsNew;
          ocrsNew = null;
        }
        
        // clone LineItems
        queryFrom = ',Opportunity.RecordTypeId From OpportunityLineItem where OpportunityId in ('+ inString + ')';
        Slist = getSObject('OpportunityLineItem', queryFrom);

        if (SList == null) {
          return oppid[0];
        }
        List<OpportunityLineItem> olis = new List<OpportunityLineItem>();
        for (sObject So : Slist) {
          OpportunityLineItem oliTemp = (OpportunityLineItem)So;
          olis.add(oliTemp);
        }
        Slist = null;

        if (!olis.isEmpty()) {
          OpportunityLineItem[] oliCloneList                  = olis.deepClone(false);
                         
          List<OpportunityLineItem> olisNew                   = new List<OpportunityLineItem>();
          for (OpportunityLineItem oli : oliCloneList){
            oli.OpportunityId = OppOldNewMap.get(oli.OpportunityId);
            oli.Revenue2__c = null;
            oli.totalprice = null;
            oli.Ad_ID__c = null;
            oli.Adserver_ID_Order_ID__c = null;
            oli.Adjusted_credits__c = null;
            oli.Availability__c = null;
            oli.Im_AdServer_buchen__c = true;
            oli.Check_Inventory__c = true;
            oli.Credits_used__c = null;
            oli.Deal_run__c = false;
            oli.delivered_Clicks_LT__c = null;
            oli.delivered_AI_LT__c = null;
            oli.Quantity_Refunded__c = null;
            oli.OSI__c = null;
            oli.Additional_Time_Days__c = 0;
            oli.Cancellation_Reason__c = null;
            oli.Cancellation_Date__c = null;
            oli.Notice_Date__c = null;
            oli.Status__c = null;
            
            
            if (oli.Opportunity.RecordTypeId ==  recTypes.get(Utils.Daily_Deal_Delivery) || oli.Opportunity.RecordTypeId == recTypes.get(Utils.Daily_Deal_Initiation)) {
                          oli.from_Date__c = null;  
                          oli.until_Date__c = null;
                          oli.Quantity = 1;  
            }
            else {
              //oli.from_Date__c = date.today();
              Date oldUntilDate = oli.until_Date__c ;
              oli.from_Date__c = oldUntilDate.addDays(1);
            //  oli.until_Date__c =oli.until_Date__c ;  
            
               Integer numberOfMonth = Integer.valueOf(oli.Length_Months__c);
         //   (GTCRM-1823) Display opp clone issue with length pre-population
            if(numberOfMonth < 1){              
            }
            oli.until_Date__c=oli.until_Date__c == null?null:oli.until_Date__c.addMonths(numberOfMonth); //*   If OPP.Campaign_End_Date__c is 21/5/14 then OLI.from_Date__c = 21/5/14, Length was cloned with 3 therefore OLI.until_Date__c = 21/8/14.
          //  oli.until_Date__c = oldFromDate.addMonths(numberOfMonth); 
            oli.Additional_Time_Days__c = 0;//? OLI.Additional_Time_Days__c = 0
            
            
            }  
            olisNew.add(oli);
            system.debug('XXXXXXXXXXXXXXXXXXXXXXXXX olisNew-->'+olisNew);
          }
          insert olisNew;
          olisNew= null;
        }
        return oppCloneListNew[0].id;
            }
            return 'An Error occured. Please contact your Salesforce.com Administrator for help.\n\n' + 'Creating new Opportunity failed';
        }
        catch(Exception q){
            q.setMessage('An Error occured. Please contact your Salesforce.com Administrator for help.\n\n' + q.getMessage());
            Database.rollback(sp);
            return q.getMessage();
        } 
    }
    

    
    
    /**
    * Renewal process : clone process used from Scheduler - CloneOpportunityScheduler_GT
    *
    */
    global static List<Opportunity> doCloneOpp(list<String> oppid, boolean Renew){
        
        // load record with Key as DeveloperName
        Map<String,Id> recTypes =  Utils.loadOppRecordType();
        
        // return the list of id cloned
        List<Opportunity> clonedoppids = new List<Opportunity>();
        
        
        List<sObject> Slist = null;
        map<id,id> OppOldNewMap = new map<id,id>();
        Savepoint sp = Database.setSavepoint();
        try {
            string inString  = '';
            for (String tmpId: oppid) {
                inString += '\'' + tmpId +  '\'' + ',';
            }
            inString = inString.substring(0,inString.length()-1);
            String queryFrom = 'FROM Opportunity where Id in ('+ inString + ')';
            System.debug('>>>>>>>>doCloneOpp.queryFrom');
            Slist = getSObject('Opportunity', queryFrom);
            System.debug('>>>>>>doCloneOpp.Slist: '+Slist);
            //Cast the sObject type into an Opportunity
            List<Opportunity> opp = new List<Opportunity>();
            if (SList == null) {
                return null;
            }
            for (sObject So : Slist) {
                Opportunity tmpOpp = (Opportunity)So;
                tmpOpp.ClonedFrom__c = tmpOpp.Id;
                opp.add(tmpOpp);
            }
            Slist = null;

            if (opp[0] != null) {
        
                map<id,id> OppAccOwnerMap = new map<id,id>();
                
                    for(Opportunity oppTmp: [SELECT id, Account.OwnerId
                                                FROM Opportunity
                                                WHERE id in :oppid ]) {
                        OppAccOwnerMap.put(oppTmp.id, oppTmp.Account.OwnerId);                              
                    }
                                                    
               
                
                Opportunity[] oppCloneList = opp.deepClone(false);
                Opportunity[] oppCloneListNew = new list<Opportunity>();
                opp = null;
                set<id> oppTerm = new set<id>();
                set<id> oppTermNew = new set<id>();
                for (Opportunity tmpOpp: oppCloneList) {
                    Opportunity oppClone = tmpOpp;
                    
                   //Bunhor @15-Dec-14: 
                    oppClone.Opportunity__c = oppClone.ClonedFrom__c;
                    
                    //oppClone.RecordTypeId = '01220000000YaHAAA0';//?  OPP. RecordTypeid=?01220000000YaHAAA0? (Campaign Delivery Housing)
                    //replace '- AC-End date' with new ' - AC- End date'
                    if(String.valueOf(oppClone.Name).contains(OPP_NAME_CONTAIN_AC))
                    {
                      oppClone.Name = String.valueOf(oppClone.Name).substringBefore(OPP_NAME_CONTAIN_AC)+ ' - AC'+ '-'+oppClone.Campaign_End__c.format();
                    }
                    else
                    {
                      oppClone.Name = oppClone.Name +' - AC'+ '-'+oppClone.Campaign_End__c.format();//oppClone.Name = oppClone.Name + ' - AR';
                    }
                    
                    //oppClone.RecordTypeId = '01220000000YaHAAA0';//?  OPP. RecordTypeid=?01220000000YaHAAA0? (Campaign Delivery Housing)
                    oppClone.StageName = 'Proposal Development';
                    oppClone.Order_ID_Dart__c = null;
                    oppClone.P_O_Number__c = null;
                    oppClone.CC_Reference__c = null;
                    oppClone.Approved_Amount_Net_Net__c = null;
                    oppClone.Approval_Status__c = false;
                    oppClone.Probability =50;
                    oppClone.Approval_Cancellation__c= false;
                    oppClone.IsCancellationPending__c = false;
                    oppClone.LeadSource= 'Existing';
                    oppClone.Auto_Renewal__c = true;
                    
                    // 2015-03-20 - GTCRM-1887 - Clone opportunity should not clone direct debit mandate field
                    oppClone.Direct_Debit_Mandate__c = null;
                    
                    // 2015-04-27 - GTCRM-1735 - Ability for sales to take an upfront payment on opportunity
                    oppClone.Payment_Token__c = null;
                    oppClone.Last_Payment_Taken__c = null;                   
                    oppClone.Payment_Amount__c = null;
                    oppClone.Transaction_Id__c = null;

                    // 2015-05-21 - GTCRM-2028 - SOX controls: Signed contract attached on opportunity level
                    oppClone.Signed_Contract_Attached__c = false;
    
                    if (oppClone.RecordTypeId!=recTypes.get(Utils.Campaign_Delivery_H)) oppClone.Auto_Renewal__c = true;//for specify this opportunity is auto renewal
                  
                    if ( oppClone.RecordTypeId == recTypes.get(Utils.Campaign_Delivery)) {oppClone.RecordTypeId = recTypes.get(Utils.Sales_Management);} //Campaign Delivery (J) -->   Sales Management (J)
                    else if ( oppClone.RecordTypeId == recTypes.get(Utils.Campaign_Delivery_H)) {oppClone.RecordTypeId = recTypes.get(Utils.Sales_Management_H);} //Campaign Delivery (H) --> Sales Management (H)
                    else if ( oppClone.RecordTypeId == recTypes.get(Utils.Campaign_Delivery_M)) {oppClone.RecordTypeId = recTypes.get(Utils.Sales_Management_M);} //Campaign Delivery (M) --> Sales Management (M)
                    else if ( oppClone.RecordTypeId == recTypes.get(Utils.Display_Campaign_Delivery)) {oppClone.RecordTypeId = recTypes.get(Utils.Display_Sales_Management);} //Campaign Delivery (D) --> Sales Management (D)
                    //else if ( oppClone.RecordTypeId == recTypes.get(Utils.Daily_Deal_Delivery)) {oppClone.RecordTypeId = recTypes.get(Utils.Daily_Deal_Initiation);} //Daily Deal Delivery --> Daily Deal Initiation
                    //else if ( oppClone.RecordTypeId == recTypes.get(Utils.Campaign_Delivery_M)) {oppClone.RecordTypeId = recTypes.get(Utils.Sales_Management_M);} //Daily Deal Delivery --> Daily Deal Initiation
                    
                        oppClone.Type = 'Existing Business';
                        oppClone.OwnerId = OppAccOwnerMap.get((id)oppClone.ClonedFrom__c); 
                        if (oppClone.BillingFrequency__c == 'Term') {
                            oppClone.BillingFrequency__c = 'Month to Month';
                            oppTerm.add(oppClone.clonedfrom__c);
                        }
                          oppClone.CloseDate = oppClone.Campaign_End__c; //?  OPP.CloseDate should be equal to Previous OPP.Campaign_End_Date__c  
                       // oppClone.CloseDate = oppClone.Campaign_Start__c;
                        
                    oppCloneListNew.add(oppClone);
                }
                
                insert oppCloneListNew;
                for (Opportunity tmpOpp: oppCloneListNew){
                  OppOldNewMap.put(tmpOpp.ClonedFrom__c, tmpOpp.id);
                  
                  // return values                  
                  clonedoppids.add(tmpOpp);
                  
                }
                //set of new Opp, which were TERM
                for(id idTmp:oppTerm){
                    oppTermNew.add(OppOldNewMap.get(idTmp));
                }
            
                // clone ContactRoles
                queryFrom = 'From OpportunityContactRole where OpportunityId in ('+ inString + ')';
                Slist = getSObject('OpportunityContactRole', queryFrom);

                if (SList == null) {
                    return new List<Opportunity>();
                    //return oppid[0];
                }
                
                List<OpportunityContactRole> ocrs = new List<OpportunityContactRole>();
                for (sObject So : Slist) {
                    System.debug((OpportunityContactRole)So);
                    ocrs.add((OpportunityContactRole)So);
                }
                Slist = null;

        if (!ocrs.isEmpty()) {
          OpportunityContactRole[] ocrCloneList = ocrs.deepClone(false);
          ocrs = null;
          List<OpportunityContactRole> ocrsNew = new List<OpportunityContactRole>();
          for (OpportunityContactRole ocr : ocrCloneList){
            ocr.OpportunityId = OppOldNewMap.get(ocr.OpportunityId);
            ocrsNew.add(ocr);
          }
          insert ocrsNew;
          ocrsNew = null;
        }
        
        // clone LineItems
        queryFrom = ',Opportunity.RecordTypeId, PricebookEntry.Product2.Id, PricebookEntry.Product2.Price_Auto_Renewal__c,PricebookEntry.Product2.Rate_Card__c, PricebookEntry.UnitPrice, PricebookEntry.Product2.Length_months__c, PricebookEntry.Product2Id From OpportunityLineItem where OpportunityId in ('+ inString + ')';
        Slist = getSObject('OpportunityLineItem', queryFrom);

        if (SList == null) {
            return new List<Opportunity>();
          //return oppid[0];
        }
        List<OpportunityLineItem> olis = new List<OpportunityLineItem>();
        for (sObject So : Slist) {
          OpportunityLineItem oliTemp = (OpportunityLineItem)So;
          olis.add(oliTemp);
        }
        Slist = null;

        if (!olis.isEmpty()) {
          OpportunityLineItem[] oliCloneList                  = olis.deepClone(false);
                         
          List<OpportunityLineItem> olisNew                   = new List<OpportunityLineItem>();
          for (OpportunityLineItem oli : oliCloneList){
            oli.OpportunityId = OppOldNewMap.get(oli.OpportunityId);
            oli.Revenue2__c = null;
            oli.totalprice = null;
            oli.Ad_ID__c = null;
            oli.Adserver_ID_Order_ID__c = null;
            oli.Adjusted_credits__c = null;
            oli.Availability__c = null;
            oli.Im_AdServer_buchen__c = true;
            oli.Check_Inventory__c = true;
            oli.Credits_used__c = null;
            oli.Deal_run__c = false;
            oli.delivered_Clicks_LT__c = null;
            oli.delivered_AI_LT__c = null;
            oli.Quantity_Refunded__c = null;
            oli.OSI__c = null;
            oli.Additional_Time_Days__c = 0;
            oli.Cancellation_Reason__c = null;
            oli.Cancellation_Date__c = null;
            oli.Notice_Date__c = null;
            oli.Status__c = null;
            Date oldUntilDate = oli.until_Date__c ;//?   OLI.from_Date__c should be equal to Previous OPP.Campaign_End_Date__c = 21/5/14 
            oli.from_Date__c = oldUntilDate.addDays(1);
           // Date oldFromDate = oli.from_Date__c;//Opplineitem.from_Date__c = Old. Opplineitem.from_Date__c+1 i.e. if the previous opplineitme. from_Date__c=17/1112014 then during the cloning process it should be Opplineitem.from_Date__c =18/11/2014.
           // oli.from_Date__c = oldFromDate.addDays(1);
            
            Integer numberOfMonth = Integer.valueOf(oli.Length_Months__c);
            if(numberOfMonth < 1){
                numberOfMonth = 1;
                oli.Length_Months__c = 1;
            }
            oli.until_Date__c=oli.until_Date__c == null?null:oli.until_Date__c.addMonths(numberOfMonth); //*   If OPP.Campaign_End_Date__c is 21/5/14 then OLI.from_Date__c = 21/5/14, Length was cloned with 3 therefore OLI.until_Date__c = 21/8/14.
          //  oli.until_Date__c = oldFromDate.addMonths(numberOfMonth); 
            oli.Additional_Time_Days__c = 0;//? OLI.Additional_Time_Days__c = 0
            
           
              //oli.Opportunity__r.Billing Frequency
           
            if(oppTermNew.contains(oli.OpportunityId)){
                oli.Discount__c = 0;
                oli.Additional_Time_Days__c = 0;
            }
            
            olisNew.add(oli);
            system.debug('XXXXXXXXXXXXXXXXXXXXXXXXX olisNew-->'+olisNew);
          }
          
          //clone price from product when Price_Auto_Renewal__c == true
          clonePriceFromRC(olisNew);
          
          insert olisNew;
          olisNew= null;
        }
      
          string newIds = '';
          for (id idTmp: OppOldNewMap.values()){
                        newIds += idTmp + ', '; 
           }
          futureCreateErrorLog.createErrorRecord('Renewed opportunities: '+newIds, 'opportunityRenew', 'opportunityRenew');
          //return newIds;
          
           return clonedoppids;
               
       }
       
       return new List<Opportunity>();
           // return 'An Error occured. Please contact your Salesforce.com Administrator for help.\n\n' + 'Creating new Opportunity failed';
            
        }
        catch(Exception q){
            q.setMessage('An Error occured. Please contact your Salesforce.com Administrator for help.\n\n' + q.getMessage());
            Database.rollback(sp);
            
            throw new RenewalCloneException(q.getMessage());
            //return q.getMessage();
            
        }
        
        
        // we are done now error
        
       
        
        
    }
    
    
    public class RenewalCloneException extends Exception {}
    
    
    /**
    *
    * Approval process
    */
    public static Set<Id> sendApproval(List<Opportunity> lstOpp){
        
        Set<Id> oppIds = new Set<Id>();
            //send approval process
            for(Opportunity opp : lstOpp){
                
                if (opp.Auto_Renewal__c && opp.RecordTypeid =='012w0000000QBzsAAG') {
                    // Create an approval request for the Opportunity
                    Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
                    req1.setComments('Submitting request for approval.');
                    req1.setObjectId(opp.id);
                    // GTCRM-1763-Submitter Id to Opportunity owner when sending for approval during the auto create of opportunity.
                    req1.setSubmitterId(opp.OwnerId);
                    // Submit the approval request for the account
                    Approval.ProcessResult result = Approval.process(req1);
                    
                    System.debug('>>>>>>result: '+result);
                    if (result.getInstanceStatus()=='Approved') {
                        oppIds.add(opp.id);
                    }
                    
                }
            }
        
        return oppIds;
    }
    
    
    /**
    *
    * check if opp is approved, used by the trigger opp after update
    */
    public static void checkApproval(List<Opportunity> lstOpp) {
        
        
        Set<Id> oppIds = new Set<Id>();
        for(Opportunity opp : lstOpp){
                
                System.debug('>>>> opp.Auto_Renewal__c ' + opp.Auto_Renewal__c);
                System.debug('>>>> opp.Approval_Status__c ' + opp.Approval_Status__c);
                System.debug('>>>> opp.RecordTypeId ' + opp.RecordTypeId);
                if (opp.Auto_Renewal__c && opp.Approval_Status__c) {
                    oppIds.add(opp.Id);
                }
        }
        
        System.debug('>>>> checkApproval.Ids ' + oppIds);
            
        // check if the opp is approved
        Set<Id> approvedOppIds = new Set<Id>();
        for (ProcessInstance  pi : [Select ID, Status,TargetObjectID, TargetObject.Name From ProcessInstance Where TargetObjectID in : oppIds AND Status = 'Approved']) {
            System.debug('>>>> checkApproval.ProcessInstance ' + pi);
            
            approvedOppIds.add(pi.TargetObjectID);
        }

        if (!approvedOppIds.isEmpty()) {
                if (!Test.isRunningTest()) {
                    if(BatchApexLimitCheck.isHittingLimit()) return;
                    Id batchEchoSignId = Database.executeBatch(new EchoSignServicesBatch(approvedOppIds,Userinfo.getSessionId()), 1); 
                }
             
        }
            
            
    }
   
    //clone price from product when Price_Auto_Renewal__c == true
    private static void clonePriceFromRC(OpportunityLineItem[] lstOpli){
    
        for(OpportunityLineItem opli : lstOpli){
            Product2 pro = opli.PricebookEntry.Product2;
            Rate_Card__c rc = Revenue.getRateCard(opli, lstOpli);
            
            if( pro.Price_Auto_Renewal__c && pro.Rate_Card__c && rc != null) opli.UnitPrice = rc.Sales_Price__c;
            //else opli.UnitPrice = opli.PricebookEntry.UnitPrice;
            
            //Re-Evaluate Sales Price Target
            calSalesPriceTarget(opli);
        }
    }
    
    
    private static void calSalesPriceTarget(OpportunityLineItem opli){
        Decimal salePriceTarget = opli.Sales_Price_Target__c;
        salePriceTarget = (salePriceTarget == null? 0: salePriceTarget);
        //if(salePriceTarget != 0) return;
        
        Decimal salePrice = opli.UnitPrice;
        salePrice = (salePrice == null? 0: salePrice);
        
        Boolean isSurchargeGBP = opli.Surcharge_Type__c == ModifyProductController2.GBP_TYPE; //get type of Surcharge
        Boolean isDiscountGBP = opli.Discount_Type__c == ModifyProductController2.GBP_TYPE;//get type of Discount
        
        Decimal surchargePrice = opli.Targeting_Surcharge__c;
        surchargePrice = (surchargePrice== null? 0: surchargePrice);
        surchargePrice = (isSurchargeGBP? surchargePrice: (salePrice * surchargePrice) /100); 
        
        Decimal discountPrice = opli.Rate_Discount_II__c;
        discountPrice = (discountPrice == null? 0: discountPrice);
        discountPrice = (isDiscountGBP? discountPrice: (salePrice * discountPrice) /100); 
        
        salePriceTarget = salePrice + surchargePrice - discountPrice;
        opli.Sales_Price_Target__c= salePriceTarget;
    }
    
    
    static testMethod void cloneOpportunity() {

        User user = [select Id from User where IsActive=true limit 1];

   
            // use one existing account
        Account acc = new Account();
        acc.Name = 'Test Account 1'; 
        acc.BillingStreet = 'Fake Street';
        acc.BillingCity = 'Fake City';
        acc.BillingState = 'London';
        acc.BillingPostalCode = '123'; 
        acc.BillingCountry = 'GB';
        insert acc;
            
        // new contact
        Contact con=new Contact();
        con.LastName='TestContact';
        con.AccountId=acc.Id;
        con.Fax='1234567';
        con.Email='Test@test.com';
        con.MobilePhone='1346975';
    
        insert con;
    
        Product2 prod = new Product2(
          Name='ApexTestProd',
          IsActive=true);
        insert prod;
    
        Pricebook2 pb = [select Id from Pricebook2 where IsStandard=true limit 1];
    
        PricebookEntry pbe = new PricebookEntry(
          UseStandardPrice=false,
          Product2Id=prod.Id,
          Pricebook2Id=pb.Id,
          UnitPrice=1.00,
          IsActive=true);
        insert pbe;
    
        Opportunity opp = new Opportunity(
          Name='Test Opp',
          Probability=100,
          StageName='gebucht',
          CloseDate=System.today(),
          //Start_of_Campaign__c=System.today(),
          //End_of_Campaign__c=System.today(),
          Pricebook2Id=pb.Id);
        insert opp;
        
        Opportunity opp2 = new Opportunity(
          Name='Test Opp2',
          Probability=100,
          StageName='gebucht',
          CloseDate=System.today(),
          //Start_of_Campaign__c=System.today(),
          //End_of_Campaign__c=System.today(),
          //RecordTypeId = '01220000000YZwQ',
          Pricebook2Id=pb.Id);
        insert opp2;
    
    
        OpportunityContactRole ocr = new OpportunityContactRole(
          OpportunityId=opp.id,
          Role='Other',
          ContactId=con.id);
        insert ocr;
    
        OpportunityLineItem oli = new OpportunityLineItem(
          Quantity=100,
          TotalPrice=100.0,
          //Delivered_Clicks__c=5,
          //Delivered_Impressions__c=10,
          OpportunityId=opp.Id,
          //Amount_Net_Net_Net__c=100.0,
          PricebookEntryId=pbe.Id);
        insert oli;
    
        Content__c c = new Content__c(
            );
            insert c;
        
        list<String> oppid = new list<string>();
        oppid.add(opp.id);
        Test.startTest();
        CloneOpportunity_GT.cloneOpp(oppid, false);
        CloneOpportunity_GT.cloneOpp(oppid, true);
        CloneOpportunity_GT.cloneOpp(null, false);
        Test.stopTest();
  }
  
}