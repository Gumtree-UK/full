public class P2P_MediaBasketCreateOppOpli {
    
    /**
    * trigger create Opportunity and Opportunity Line Item when Media Basket is created 
    */
    public static void createOppOpli(List<Media_Basket__c> lstMBs){
        Set<ID> accIds = new Set<ID>();
        
        for(Media_Basket__c mb : lstMBs){
            if(mb.From_Site__c == false) continue;
            accIds.add(mb.Account_Id__c);
            System.debug('===================mb=' + mb);
        }
        if(accIds.isEmpty()) return;
        
        //get all pricebook from custom setting
        Set<String> pbNames = new Set<String>();
        Map<String, P2P_Pricebook2Account__c> mapAccPB = P2P_Pricebook2Account__c.getAll();
        for(P2P_Pricebook2Account__c mapPb: mapAccPB.values()){
            pbNames.add(mapPb.Map_2_Pricebook_Name__c);
        }
        
        Map<String, String> mapPbId = new Map<String, String>();
        for(Pricebook2 pb: [Select Id, Name From Pricebook2 Where Name in: pbNames]){
            mapPbId.put(pb.Name, pb.Id);
        }
        
        //get all Opportunity Record Type from custom setting 
        Set<String> oppRecTypName = new Set<String>();
        Map<String, P2P_AccGetOppRecTyp__c> mapOppRec = P2P_AccGetOppRecTyp__c.getAll();
        for(P2P_AccGetOppRecTyp__c oppRec: mapOppRec.values()){
            oppRecTypName.add(oppRec.OppRecTypName__c);
        }
        
        Map<String, String> mapRecTyp = new Map<String, String>();
        for(RecordType recTyp: [Select Id, Name From RecordType Where SobjectType='Opportunity' AND Name in: oppRecTypName]){
            mapRecTyp.put(recTyp.Name, recTyp.Id);
        }
        
        //get existed Won Opportunity related Account last 6 months
        Set<ID> accIdHasExistedOppLast6Months = new Set<ID>();
        for(Opportunity existedOpp: [Select Id, AccountId From Opportunity Where AccountId in: accIds AND IsWon = true AND CloseDate >=: System.today().addMonths(-6)]){
            accIdHasExistedOppLast6Months.add(existedOpp.AccountId);
        }
        
        //get related Accounts
        //create Opportunities and OpportunityContactRole from related account
        Map<String, Opportunity> mapNewOpps = new Map<String, Opportunity>();
        Map<String, OpportunityContactRole> mapNewOppConRoles = new Map<String, OpportunityContactRole>();
        
        for(Account acc: [Select Id, Name, RecordType.DeveloperName, Primary_contact__c, OwnerId From Account Where Id in: accIds]){
            String accRecTyp    = acc.RecordType.DeveloperName;
            String pricebookName = mapAccPB.containsKey(accRecTyp) ? mapAccPB.get(accRecTyp).Map_2_Pricebook_Name__c : '';
            String pricebookID  = mapPbId.containsKey(pricebookName) ? mapPbId.get(pricebookName) : '';
            String oppRecName   = mapOppRec.containsKey(accRecTyp) ? mapOppRec.get(accRecTyp).OppRecTypName__c : '';
            String recTypId     = mapRecTyp.containsKey(oppRecName) ? mapRecTyp.get(oppRecName) : '';
            
            //for unit test
            if(Test.isRunningTest()) pricebookID = Test.getStandardPricebookId();
                    
            Opportunity newOpp = new Opportunity(Pricebook2Id = pricebookID,
                                                 RecordTypeId = recTypId,
                                                 AccountId = acc.Id,
                                                 Name = acc.Name + ' - Self-serve -', //Campaign_Start__c ???
                                                 CloseDate = System.today(),
                                                 StageName = 'Self-serve checkout',
                                                 Probability = 50,
                                                 Type = accIdHasExistedOppLast6Months.contains(acc.Id) ? 'Existing business': 'New business',
                                                 LeadSource = 'Self Serve',
                                                 OwnerId = acc.OwnerId
                                                 //Payment_Method__c,
                                                 //BillingFrequency__c,
                                                  ); 
            mapNewOpps.put(acc.Id, newOpp);
            
            if(acc.Primary_contact__c == null) continue;
            OpportunityContactRole newOppConRole = new OpportunityContactRole(  ContactId = acc.Primary_contact__c,
                                                                                IsPrimary = true
                                                                                );
            
            mapNewOppConRoles.put(acc.Id, newOppConRole);
        }
        
        if(!mapNewOpps.isEmpty()){
            insert mapNewOpps.values();
        }
        
        //create OppotunityContactRole
        for(String accId: mapNewOppConRoles.keySet()){
            if(!mapNewOpps.containsKey(accId)) continue;
            
            String oppId = mapNewOpps.get(accId).Id;
            mapNewOppConRoles.get(accId).OpportunityId = oppId;
        }
        
        if(!mapNewOppConRoles.isEmpty()){
            insert mapNewOppConRoles.values();
        }
        
        //4.5.3System to create OpportunityLineItem records from Media_Basket__c
        Map<String, OpportunityLineItem> mapInserOplis = new Map<String, OpportunityLineItem>();
        for(Media_Basket__c mb : lstMBs){
            if(!mapNewOpps.containsKey(mb.Account_Id__c)) continue;
            String oppId = mapNewOpps.get(mb.Account_Id__c).Id;
            System.debug('============oppId=' + oppId);
            OpportunityLineItem newOpli = new OpportunityLineItem(  PricebookEntryId    = mb.PriceBookEntryIdText__c,
                                                                    Billing_Category__c = mb.Billing_Category__c,
                                                                    from_Date__c        = mb.from_Date__c,
                                                                    until_Date__c       = mb.until_Date__c,
                                                                    Length_Months__c    = mb.Length_Months__c,
                                                                    Quantity            = mb.Quantity__c,
                                                                    Sales_Price_Target__c = mb.Sales_Price_Target__c,
                                                                    Rate_Discount_I__c  = mb.Rate_Discount_I__c,
                                                                    Rate_Discount_II__c = mb.Rate_Discount_II__c,
                                                                    Promo_code__c       = mb.Promo_code__c,
                                                                    Rebate_In_Kind_Reason__c = mb.Discount_reason__c,
                                                                    Feed_setup__c       = mb.Feed_setup__c,
                                                                    Net_Net_Net__c      = mb.Net_Net_Net__c,
                                                                    OpportunityId       = oppId,
                                                                    UnitPrice           = mb.Sales_Price_Target__c);
            mapInserOplis.put(mb.Account_Id__c + mb.Product_ID__c + mb.PriceBookEntryIdText__c, newOpli);
        }
         
        if(!mapInserOplis.isEmpty()){
            insert mapInserOplis.values();
        }
        System.debug('=======================mapInserOplis=' + mapInserOplis);
       
        for(Media_Basket__c mb : lstMBs){
            System.debug('=======================mb.Account_Id__c=' + mb.Account_Id__c);
            mb.OpportunityId__c = mapNewOpps.get(mb.Account_Id__c).Id;
            mb.OpportunityLineItemId__c = mapInserOplis.get(mb.Account_Id__c + mb.Product_ID__c + mb.PriceBookEntryIdText__c).Id;
        }
        
        //Opportunity update name
        List<Opportunity> lstUpdateOppName = [Select Id, Name, Campaign_Start__c From Opportunity Where Id in: mapNewOpps.values()];
        for(Opportunity opp: lstUpdateOppName){
            opp.Name = opp.Name + ' ' + opp.Campaign_Start__c;
        }
        
        if(!lstUpdateOppName.isEmpty()){
            update lstUpdateOppName;
        }
        
    }
    
    /**
    * Trigger update Opportunity Line Item when user update Media Basket
    */
    public static void updateOpli(List<Media_Basket__c> lstOldMediaBasket, Map<Id, Media_Basket__c> mapNewMediaBasket){
        List<OpportunityLineItem> lstOpliUpdate = new List<OpportunityLineItem>();
        
        for(Media_Basket__c oMB: lstOldMediaBasket){
            Media_Basket__c nMB = mapNewMediaBasket.get(oMB.Id);
            if(nMB.From_Site__c == false) continue;
            
            if( oMB.from_Date__c != nMB.from_Date__c || 
                oMB.until_Date__c != nMB.until_Date__c || 
                oMB.Length_Months__c != nMB.Length_Months__c || 
                oMB.Quantity__c != nMB.Quantity__c ||
                oMB.Feed_setup__c != nMB.Feed_setup__c ||
                oMB.Promo_code__c != nMB.Promo_code__c ||
                oMB.Rate_Discount_II__c != nMB.Rate_Discount_II__c ||
                oMB.Discount_reason__c != nMB.Discount_reason__c){
                System.debug('============nMB=' + nMB.Discount_reason__c); 
                OpportunityLineItem newOpli = new OpportunityLineItem(  Id                  = nMB.OpportunityLineItemId__c,
                                                                        PricebookEntryId    = nMB.PriceBookEntryIdText__c,
                                                                        Billing_Category__c = nMB.Billing_Category__c,
                                                                        from_Date__c        = nMB.from_Date__c,
                                                                        until_Date__c       = nMB.until_Date__c,
                                                                        Length_Months__c    = nMB.Length_Months__c,
                                                                        Quantity            = nMB.Quantity__c,
                                                                        Sales_Price_Target__c = nMB.Sales_Price_Target__c,
                                                                        Rate_Discount_I__c  = nMB.Rate_Discount_I__c,
                                                                        Rate_Discount_II__c = nMB.Rate_Discount_II__c,
                                                                        Promo_code__c       = nMB.Promo_Code__c,
                                                                        Rebate_In_Kind_Reason__c = nMB.Discount_reason__c,
                                                                        Feed_setup__c       = nMB.Feed_setup__c,
                                                                        Net_Net_Net__c      = nMB.Net_Net_Net__c,
                                                                        UnitPrice           = nMB.Sales_Price_Target__c
                                                                        );
            lstOpliUpdate.add(newOpli);
            System.debug('============newOpli=' + newOpli); 
            }
        }
        
        if(!lstOpliUpdate.isEmpty()){
            update lstOpliUpdate;
        }
    }
    
    /**
    * Method to update Opportunity when user click buttons "Pay"
    */
    public static void updateOpp(List<Media_Basket__c> lstOldMediaBasket, Map<Id, Media_Basket__c> mapNewMediaBasket){
        
        Set<ID> oppIds = new Set<ID>();
        
        for(Media_Basket__c oMB: lstOldMediaBasket){
            Media_Basket__c nMB = mapNewMediaBasket.get(oMB.Id);
            if(nMB.From_Site__c == false) continue;
            
            if(oMB.Payment_Method__c != nMB.Payment_Method__c || oMB.BillingFrequency__c != nMB.BillingFrequency__c){
                oppIds.add(nMB.OpportunityId__c);
            }
        }
        if(oppIds.isEmpty()) return;
        
        //Get Opportunity RecordType
        Map<String, String> mapOppBookingRecordType = new Map<String, String>{  'Self-serve initiation (H)' => 'Self-serve delivery (H)',
                                                                                'Self-serve initiation (J)' => 'Self-serve delivery (J)',
                                                                                'Self-serve initiation (M)' => 'Self-serve delivery (M)'};
                                                                                
        Map<String, String> mapOppBookingRecordTypId = new Map<String, String>();
        for(RecordType recTyp : [Select Id, Name From RecordType Where SobjectType='Opportunity' AND Name Like 'Self-serve delivery%']){
            mapOppBookingRecordTypId.put(recTyp.Name, recTyp.Id);
        }
        
        Map<ID, Opportunity> mapOpps = new Map<ID, Opportunity>([Select Id, RecordType.Name, RecordType.Id From Opportunity Where Id in:oppIds]);
        Set<ID> existedChange = new Set<ID>();
        List<Opportunity> lstOpps = new List<Opportunity>();
        
        for(Media_Basket__c oMB: lstOldMediaBasket){
            Media_Basket__c nMB = mapNewMediaBasket.get(oMB.Id);
            if(nMB.From_Site__c == false) continue;
            
            if(oMB.Payment_Method__c != nMB.Payment_Method__c || oMB.BillingFrequency__c != nMB.BillingFrequency__c){
                if(existedChange.contains(nMB.OpportunityId__c)) continue; //avoid duplicate Opportunity
                
                if(!mapOpps.containsKey(nMB.OpportunityId__c)) continue; 
                
                existedChange.add(nMB.OpportunityId__c);
                Opportunity opp = new Opportunity(Id = nMB.OpportunityId__c,
                                                    Payment_Method__c=nMB.Payment_Method__c,
                                                    BillingFrequency__c=nMB.BillingFrequency__c);
                                                    
                if(nMB.Stage__c != null){
                    String curRecTypName = mapOpps.get(nMB.OpportunityId__c).RecordType.Name;
                    String recTypName = mapOppBookingRecordType.containsKey(curRecTypName) ? mapOppBookingRecordType.get(curRecTypName): '';
                    String recTypId = mapOppBookingRecordTypId.containsKey(recTypName) ? mapOppBookingRecordTypId.get(recTypName) : '';
                    opp.StageName = nMB.Stage__c;
                    
                    if(recTypId != ''){
                        opp.RecordTypeId = recTypId;
                    }
                }
                lstOpps.add(opp);
            }
        }
        
        
        if(!lstOpps.isEmpty()){
            update lstOpps;
        }
        
    }
    
    /**
    * Trigger for delete Opportunity Line Item when user delete Media Basket
    */
    public static void deleteOpli(List<Media_Basket__c> lstDelMediaBasket){
        Set<Id> opliIds = new Set<Id>();
        
        for(Media_Basket__c mb: lstDelMediaBasket){
            if(mb.From_Site__c == false) continue;
            opliIds.add(mb.OpportunityLineItemId__c);
        }
        
        if(!opliIds.isEmpty()){
            delete [Select Id From OpportunityLineItem Where Id in: opliIds];
        }
    }
}