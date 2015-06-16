/**
 * Task #4094: My checkout for Manage Ads ( GTCRM-1293 PRO - M2 - Build 'My checkout' module )
 * @description: attached doc "My checkout V1.docx "
 * @author: CPN
 * @createdDate: Oct-07-2014
 
 * @Revision
 *      - @Descripton   : #34523 - GTCRM-1293 - PRO - M2 - 'My Checkout' module - Design
 *      - @See          : 2014-11-27 - P2P - Technical specifications - Product List & Configuration.docx
 *      - @modifieddate : 02/12/2014 
 */
public without sharing class P2P_MyCheckoutController {
    public final String PRICE_BOOK_NAME = 'Self Service Price Book';
    
    //Filter Products
    public String searchKey { get; set; }
    public String categoryKey { get; set; }
    public String typeKey { get; set; }
    public String locationKey { get; set; }
    public Integer totalProduct {get;set;}
    public Decimal totalPrice {get;set;}
    public Decimal totalSub {get;set;}
    
    public List<SelectOption> lstFilterTyps {get;set;}
    public List<SelectOption> lstFilterLocations {get;set;}
    public List<SelectOption> categoryOpts { get; set; }
    public List<SelectOption> lstCustomDuration {get;set;}
    
    public Boolean hasError {get;set;}
    public List<BasketRow> lstBasketRows {get;set;}
    public Integer indexProGroupSel {get;set;}
    public Integer indexSubPro {get;set;}
    
    private String accountId;
    private Id curPricebookId;
    
    private String orderProduct = ' order by Product2.SortOrder__c'; //Product2.Site__r.Name
    
    public P2P_MyCheckoutController(){
        init();
    }
    
    private void init() {
        searchKey = '';
        categoryKey = '';
        typeKey = '';
        locationKey = '';
        totalProduct = 0;
        totalPrice = 0;
        totalSub = 0;
        hasError = false;
        
        //get account id from url
        accountId = P2P_Utils.retrieveCommunityAccountId();
        accountId = accountId == null ? '' : String.escapeSingleQuotes(accountId);
        if(accountId == '') return;
        
        //Get current account recordtype developername
        List<Account> lstAccounts = [Select Id, RecordTypeId, RecordType.DeveloperName From Account Where Id = : accountId limit 1];
        if(lstAccounts.isEmpty()) return;
        accountId = lstAccounts.get(0).Id;
        
        //Get PriceBookEntryId by account record type
        curPricebookId = getPricebook(lstAccounts.get(0).RecordType.DeveloperName);
        if(curPricebookId == null) return;
        
        getAdvertisingMeduim();
        putExistedMediaBasket();
        reCalculateTotalPriceAndProduct();
        
        //Filter Options
        lstFilterLocations = getProductFilterByLocation();
        lstFilterTyps = getProductFilterByType();
        categoryOpts = getProductFilterByCategory();
        lstCustomDuration = getProductDuration();
        
    }
    
    /**
    * Method get pricebook that match account record type
    * @param String accRecTyp   account record type developer name
    * @return related pricebook
    * @author SP
    */
    private Id getPricebook(String accRecTyp){
        
        P2P_Pricebook2Account__c pbAPIName = P2P_Pricebook2Account__c.getValues(accRecTyp);
        if(pbAPIName == null || pbAPIName.Map_2_Pricebook_Name__c == null) return null;
        
        List<Pricebook2> lstPricebook2 = [Select Id, Name From Pricebook2 Where Name=: pbAPIName.Map_2_Pricebook_Name__c limit 1];
        if(lstPricebook2.isEmpty()) return null;
        
        return Test.isRunningTest() ? Test.getStandardPricebookId() : lstPricebook2.get(0).Id;
    }
    
    /**
    * Method get Product Type
    */
    private List<SelectOption> getProductFilterByType(){
        List<SelectOption> lstOptions = new List<SelectOption>();
        // 2015-01-07 - Adjusted by Steve Paul - We will need to restrict types available for specific pricebooks
        //lstOptions.addall(P2P_Utils.getPicklist('Product2', 'Product_Subtype__c'));
        lstOptions.add(new SelectOption('', 'All types'));
        lstOptions.add(new SelectOption('Advertising', 'Standard advertising'));
        lstOptions.add(new SelectOption('Featured Advertising', 'Featured advertising'));
        lstOptions.add(new SelectOption('Applicant Tracking', 'Applicant tracking'));
        return lstOptions;
    }
    
    /**
    * Method get Product Family (Category)
    */
    private List<SelectOption> getProductFilterByCategory(){
        List<SelectOption> lstOptions = new List<SelectOption>();
        lstOptions.add(new SelectOption('', 'All categories'));
        lstOptions.addall(P2P_Utils.getPicklist('Product2', 'Family'));
        return lstOptions;
    }
    
    private List<SelectOption> getProductFilterByLocation(){
        List<SelectOption> lstOptions = new List<SelectOption>();
        lstOptions.add(new SelectOption('', 'Nationwide'));
        lstOptions.add(new SelectOption('London', 'London'));
        lstOptions.add(new SelectOption('RoUK', 'RoUK'));
        return lstOptions;
    }
    /**
    * Get duration from custom setting
    */
    public static List<SelectOption> getProductDuration(){
        List<SelectOption> lstOptions = new List<SelectOption>();
        lstOptions.add(new SelectOption('0', 'Please select'));      
            lstOptions.add(new SelectOption('1', '1'));
            lstOptions.add(new SelectOption('2', '2'));
            lstOptions.add(new SelectOption('3', '3'));
            lstOptions.add(new SelectOption('4', '4'));
            lstOptions.add(new SelectOption('5', '5'));
            lstOptions.add(new SelectOption('6', '6'));
            lstOptions.add(new SelectOption('7', '7'));
            lstOptions.add(new SelectOption('8', '8'));
            lstOptions.add(new SelectOption('9', '9'));
            lstOptions.add(new SelectOption('10', '10'));
            lstOptions.add(new SelectOption('11', '11'));
            lstOptions.add(new SelectOption('12', '12'));        
        return lstOptions;
        
        /* 2015-01-11 - Adjusted by Steve Paul to hard code values as appose to using custom setting
        PRO_ProductConfig_Duration__c proDur = PRO_ProductConfig_Duration__c.getValues('Product Duration');
        if(proDur == null) return lstOptions;
        
        lstOptions.add(new SelectOption(String.valueOf(Integer.valueOf(proDur.X1__c)), String.valueOf(proDur.X1__c)));
        lstOptions.add(new SelectOption(String.valueOf(Integer.valueOf(proDur.X2__c)), String.valueOf(proDur.X2__c)));
        lstOptions.add(new SelectOption(String.valueOf(Integer.valueOf(proDur.X3__c)), String.valueOf(proDur.X3__c)));
        lstOptions.add(new SelectOption(String.valueOf(Integer.valueOf(proDur.X4__c)), String.valueOf(proDur.X4__c)));
        lstOptions.add(new SelectOption(String.valueOf(Integer.valueOf(proDur.X5__c)), String.valueOf(proDur.X5__c)));
        lstOptions.add(new SelectOption(String.valueOf(Integer.valueOf(proDur.X6__c)), String.valueOf(proDur.X6__c)));
        lstOptions.add(new SelectOption(String.valueOf(Integer.valueOf(proDur.X7__c)), String.valueOf(proDur.X7__c)));
        lstOptions.add(new SelectOption(String.valueOf(Integer.valueOf(proDur.X8__c)), String.valueOf(proDur.X8__c)));
        lstOptions.add(new SelectOption(String.valueOf(Integer.valueOf(proDur.X9__c)), String.valueOf(proDur.X9__c)));
        lstOptions.add(new SelectOption(String.valueOf(Integer.valueOf(proDur.X10__c)), String.valueOf(proDur.X10__c)));
        lstOptions.add(new SelectOption(String.valueOf(Integer.valueOf(proDur.X11__c)), String.valueOf(proDur.X11__c)));
        lstOptions.add(new SelectOption(String.valueOf(Integer.valueOf(proDur.X12__c)), String.valueOf(proDur.X12__c)));
        return lstOptions;
        
        */
        
    }
    
    /**
    * Method get existed Media Basket
    * @return Map<Pricebook entry id, list of existed Media Basket>
    */
    private void putExistedMediaBasket(){
        Map<String, List<Media_Basket__c>> mapMediaBaskets = new Map<String, List<Media_Basket__c>>();
        Set<ID> proIds = new Set<ID>();
        Map<String, Set<String>> mapExistedProduct = new Map<String, Set<String>>();
        Map<String, Integer> mapProductGroupAndIndex = new Map<String, Integer>();
        
        //get existed Media basket
        // for(Media_Basket__c mb: [Select Sales_Price_Target__c, Id, Product_Group_Name__c, Quantity__c, PriceBookEntryIdText__c, Product_ID__c, until_Date__c, from_Date__c, Length_Months__c, Location__c, Net_Net_Net__c, Gross__c From Media_Basket__c Where Account_Id__c =: accountId]){

        // 2015-01-06 - Adjusted by Steve Paul - If Stage of Opportunity has moved to 'Booking' then we should not show previous Media_Basket__c records
        for(Media_Basket__c mb: [Select Sales_Price_Target__c, Id, Product_Group_Name__c, Quantity__c, PriceBookEntryIdText__c, Product_ID__c, until_Date__c, from_Date__c, Length_Months__c, Location__c, Net_Net_Net__c, Gross__c, Stage__c From Media_Basket__c Where Account_Id__c =: accountId AND Stage__c <> 'Booking']){
            if(mb.PriceBookEntryIdText__c == null) continue;
            proIds.add(mb.Product_ID__c);
            
            if(!mapMediaBaskets.containsKey(mb.Product_Group_Name__c)){
                mapMediaBaskets.put(mb.Product_Group_Name__c, new List<Media_Basket__c>());
            }
            mapMediaBaskets.get(mb.Product_Group_Name__c).add(mb);
        }
        System.debug('=========================mapMediaBaskets=' + mapMediaBaskets);
        if(proIds.isEmpty()) return;
        
        //get Product, to put into list
        Map<String, PricebookEntry> mapPbes = new Map<String, PricebookEntry>();
        for(PricebookEntry pbe: [Select Id, UnitPrice, Product2Id, Product2.Quantity__c, Product2.Id, Product2.Rate_Card__c
                                    FROM PricebookEntry
                                    Where Product2Id in: proIds AND Pricebook2Id =: curPricebookId And IsActive = true]){
            
            mapPbes.put(pbe.Id + '_' + pbe.Product2Id, pbe);                                
        }
        System.debug('=========================mapPbes=' + mapPbes);
        for(BasketRow br: lstBasketRows){
            System.debug('=========================br.productGroupName=' + br.productGroupName);
            //If it doesnt have any ProductGroup match the current ProductGroup, add it.
            if(!mapMediaBaskets.containsKey(br.productGroupName)){
                continue;
            }
            
            for(Media_Basket__c mb: mapMediaBaskets.get(br.productGroupName)){
                System.debug('=========================mb.PriceBookEntryIdText__c + mb.Product_ID__c=' + mb.PriceBookEntryIdText__c + '_' + mb.Product_ID__c);
                if(!mapPbes.containsKey(mb.PriceBookEntryIdText__c + '_' + mb.Product_ID__c)) continue;
                
                PricebookEntry pbe = mapPbes.get(mb.PriceBookEntryIdText__c + '_' + mb.Product_ID__c);
                Boolean isEnableQty = (pbe.Product2.Quantity__c == null || pbe.Product2.Quantity__c <= 0 );
                br.basketItems.add(new BasketItem(br.basketItems.size(), mb, pbe.UnitPrice, pbe.Product2.Rate_Card__c, isEnableQty));
                br.selected = true;
                mapProductGroupAndIndex.put(br.productGroupName, br.index);
                
                if(!mapExistedProduct.containsKey(br.productGroupName)){
                    mapExistedProduct.put(br.productGroupName, new Set<String>());
                }
                mapExistedProduct.get(br.productGroupName).add(mb.Product_ID__c);
            }
        }
        System.debug('========================mapProductGroupAndIndex=' + mapProductGroupAndIndex);
        System.debug('========================mapExistedProduct=' + mapExistedProduct);
        if(!mapProductGroupAndIndex.isEmpty()){
            getAllRelatedProducts(mapProductGroupAndIndex, mapExistedProduct);
        }
    }
    
    public String getSitePrefix(){
        return Site.getPathPrefix() == null ? '' : Site.getPathPrefix();
    }
    
    /**
    * Method get Product Group (Advertising Meduim)
    */
    public Pagereference getAdvertisingMeduim(){
        
        //Check old list if it has valid record, keep it
        Map<String, BasketRow> mapTmpBasketRows = new Map<String, BasketRow>(); //Map<Avertising Medium Name, BasketRow>
        Map<String, Set<String>> mapExistedProduct = new Map<String, Set<String>>();
        
        if(lstBasketRows != null && !lstBasketRows.isEmpty()){
            for(BasketRow br: lstBasketRows){
                System.debug('========================basketItems=' + br.basketItems);
                for(BasketItem bi: br.basketItems){
                    System.debug('========================mb=' + bi.mb);
                    System.debug('========================isValidBasketItem=' + isValidBasketItem(bi.mb, bi.mb.Id == null));
                    
                    if(isValidBasketItem(bi.mb, bi.mb.Id == null)){
                        if(!mapTmpBasketRows.containsKey(br.productGroupName)){
                            
                            BasketRow newBR = new BasketRow(br);
                            mapTmpBasketRows.put(br.productGroupName, newBR);
                        }
                        
                        BasketItem newBI = bi;
                        mapTmpBasketRows.get(br.productGroupName).basketItems.add(newBI);
                        
                        if(!mapExistedProduct.containsKey(br.productGroupName)){
                            mapExistedProduct.put(br.productGroupName, new Set<String>());
                        }
                        mapExistedProduct.get(br.productGroupName).add(newBI.mb.Product_ID__c);
                    }
                }
            }
        }
        System.debug('========================mapTmpBasketRows=' + mapTmpBasketRows);
        
        String pbId = curPricebookId;
        String queryWhere = ' Pricebook2Id =: pbId And IsActive = true and Product2.Advertising_Medium__c != null '; 
        String pSearchKey = '';
        if(!String.isEmpty(searchKey)) pSearchKey = '%' + searchKey.trim() + '%';
        if(!String.isEmpty(pSearchKey)) queryWhere += ' And Product2.Name Like: pSearchKey';
        if(!String.isEmpty(categoryKey)) queryWhere += ' And Product2.Family =: categoryKey ';
        if(!String.isEmpty(locationKey)) queryWhere += ' And Product2.Site__r.Name =: locationKey ' ;
        if(!String.isEmpty(typeKey)) queryWhere += ' AND Product2.Product_Subtype__c =:typeKey ';
        
        String query = 'Select Id, Name, UnitPrice, Product2Id, Product2.Quantity__c, Product2.Id, Product2.Featured__c, Product2.Rate_Card__c, Product2.Advertising_Medium__c, Product2.Advertising_Medium__r.Name, Product2.Advertising_Medium__r.Group_Description__c, Product2.Advertising_Medium__r.SortOrder__c From PricebookEntry Where ' + queryWhere + ' order by Product2.Advertising_Medium__r.SortOrder__c';
        system.debug('============query: ' + query);
        List<PricebookEntry> lstPbes = DataBase.query(query);
        
        Set<ID> hasInList = new Set<ID>();
        Set<ID> popularList = new Set<ID>();
        Map<String, Product2> mapProducts = new Map<String, Product2>();
        Map<String, PricebookEntry> mapPbes = new Map<String, PricebookEntry>();
        
        lstBasketRows = new List<BasketRow>();
        
        //get popular product
        for(PricebookEntry pbe : lstPbes){
            if(pbe.Product2.Featured__c){
                popularList.add(pbe.Product2.Advertising_Medium__c);
            }
        }
        
        //get Advertising Medium match condition search
        Integer i = 0;
        List<Integer> lstIndex2SelectSubProduct = new List<Integer>();
        Map<String, Integer> mapProductGroupAndIndex = new Map<String, Integer>();
        
        for(PricebookEntry pbe : lstPbes){
            mapProducts.put(pbe.Id, pbe.Product2); //map pricebook entry with product
            mapPbes.put(pbe.Id, pbe);
            
            //get related Product Group (Advertising Meduim)
            if(hasInList.contains(pbe.Product2.Advertising_Medium__c)) continue;
            hasInList.add(pbe.Product2.Advertising_Medium__c);
            
            BasketRow br = new BasketRow(i, false, pbe.Product2.Advertising_Medium__c, pbe.Product2.Advertising_Medium__r.Name, pbe.Product2.Advertising_Medium__r.Group_Description__c, pbe.Id);
            br.isPopulate = popularList.contains(pbe.Product2.Advertising_Medium__c);
            
            // check and put media basket that user just input
            if(mapTmpBasketRows.containsKey(pbe.Product2.Advertising_Medium__r.Name)){
                br.selected = true;
                br.basketItems.addall(mapTmpBasketRows.get(pbe.Product2.Advertising_Medium__r.Name).basketItems);
                mapProductGroupAndIndex.put(pbe.Product2.Advertising_Medium__r.Name, i);
                
                mapTmpBasketRows.remove(pbe.Product2.Advertising_Medium__r.Name);
            }
            
            lstBasketRows.add(br);
            i++;
        }
        System.debug('========================lstBasketRows=' + lstBasketRows);
        System.debug('========================mapProductGroupAndIndex=' + mapProductGroupAndIndex);
        System.debug('========================mapExistedProduct=' + mapExistedProduct);
        //get sub product and add into selected basket row
        if(!mapProductGroupAndIndex.isEmpty()){
            getAllRelatedProducts(mapProductGroupAndIndex, mapExistedProduct);
        }
        return null;
    }
    
    /**
    * Method get related Product when Product Group is checked
    */
    public Pagereference getRelatedProducts(){
        BasketRow proGroupSelected = lstBasketRows.get(indexProGroupSel);
        if(proGroupSelected.selected) return null;
        
        String query = 'Select Id, Name, UnitPrice, Product2Id, Product2.Quantity__c, Product2.Advertising_Medium__r.Name, Product2.Featured__c, Product2.Rate_Card__c, Product2.Advertising_Medium__c, Product2.Site__r.Name, Product2.Name, Pricebook2Id FROM PricebookEntry ';
        
        String pbId = curPricebookId;
        
        String advMediumId = proGroupSelected.productGroupId;
        String condition = ' Where Pricebook2Id =: pbId And IsActive = true and Product2.Advertising_Medium__c =: advMediumId ';
        if(!String.isEmpty(categoryKey)) condition += ' And Product2.Family =: categoryKey ';
        if(!String.isEmpty(locationKey)) condition += ' And Product2.Site__r.Name =: locationKey ' ;
        if(!String.isEmpty(typeKey)) condition += ' AND Product2.Product_Subtype__c =:typeKey ';
        System.debug('======================advMediumId=' + advMediumId);
        System.debug('======================pbId=' + pbId);
        System.debug('======================categoryKey=' + categoryKey);
        System.debug('======================locationKey=' + locationKey);
        System.debug('======================typeKey=' + typeKey);
        //get Media Basket record type Self-serve
        List<RecordType> lstMediaBasketRecTyps = [Select Id From RecordType Where SobjectType='Media_Basket__c' And DeveloperName='Self_Serve' limit 1];
        String recTypId = lstMediaBasketRecTyps.isEmpty() ? null: lstMediaBasketRecTyps.get(0).Id;
        System.debug('=======================' + query + condition + orderProduct);
        for(PricebookEntry pbe: DataBase.query(query + condition + orderProduct)){
            Product2 pro = pbe.Product2;
            Media_Basket__c mb = new Media_Basket__c(   from_Date__c = System.today(), 
                                                        PriceBookEntryIdText__c = pbe.Id, 
                                                        Account_Id__c = accountId,
                                                        Location__c = pbe.Product2.Site__r.Name,
                                                        Gross__c = 0,
                                                        Net_Net_Net__c = 0,
                                                        RecordTypeId = recTypId,
                                                        Quantity__c = pro.Quantity__c > 0? pro.Quantity__c : 0,
                                                        Product_ID__c = pbe.Product2Id,
                                                        Product_Group_Name__c = pro.Advertising_Medium__r.Name);
            
            System.debug('====================mb=' + mb);
            System.debug('====================size=' + proGroupSelected.basketItems.size());
            Boolean isEnableQty = (pro.Quantity__c == null || pro.Quantity__c <= 0 );
            BasketItem bi = new BasketItem(proGroupSelected.basketItems.size(), mb, pbe.UnitPrice, pbe.Product2.Rate_Card__c, isEnableQty);
            proGroupSelected.basketItems.add(bi);   
        }
        System.debug('====================proGroupSelected.basketItems=' + proGroupSelected.basketItems);
        proGroupSelected.selected = true;
                                    
        return null;
    }
    
    /**
    * Method get all related Product when load page and product group has defualt selected
    */
    private void getAllRelatedProducts(Map<String, Integer> mapProductGroupAndIndex, Map<String, Set<String>> mapExistedProduct){
        String query = 'Select Id, Name, UnitPrice, Product2Id, Product2.Advertising_Medium__r.Name, Product2.Quantity__c, Product2.Featured__c, Product2.Rate_Card__c, Product2.Advertising_Medium__c, Product2.Site__r.Name, Product2.Name, Pricebook2Id FROM PricebookEntry ';
        if(mapProductGroupAndIndex.isEmpty()) return;
        
        Set<ID> advMediumIds = new Set<ID>();
        for(Integer i: mapProductGroupAndIndex.values()){
            BasketRow proGroupSelected = lstBasketRows.get(i);
            advMediumIds.add(proGroupSelected.productGroupId);
        }
        System.debug('================advMediumIds=' + advMediumIds);
        
        if(advMediumIds.isEmpty()) return;
        
        String pbId = curPricebookId;
        String condition = ' Where Pricebook2Id =: pbId And IsActive = true and Product2.Advertising_Medium__c =: advMediumIds ';
        if(!String.isEmpty(categoryKey)) condition += ' And Product2.Family =: categoryKey ';
        if(!String.isEmpty(locationKey)) condition += ' And Product2.Site__r.Name =: locationKey ' ;
        if(!String.isEmpty(typeKey)) condition += ' AND Product2.Product_Subtype__c =:typeKey ';
        
        //get Media Basket record type Self-serve
        List<RecordType> lstMediaBasketRecTyps = [Select Id From RecordType Where SobjectType='Media_Basket__c' And DeveloperName='Self_Serve' limit 1];
        String recTypId = lstMediaBasketRecTyps.isEmpty() ? null: lstMediaBasketRecTyps.get(0).Id;
        
        for(PricebookEntry pbe: DataBase.query(query + condition + orderProduct)){
            Product2 pro = pbe.Product2;
            
            if(!mapProductGroupAndIndex.containsKey(pro.Advertising_Medium__r.Name)) continue;
            
            //If Product is existed in list, dont add more
            if(mapExistedProduct.containsKey(pro.Advertising_Medium__r.Name) && mapExistedProduct.get(pro.Advertising_Medium__r.Name).contains(pro.Id)) continue;
                        
            Media_Basket__c mb = new Media_Basket__c(   from_Date__c = System.today(), 
                                                        PriceBookEntryIdText__c = pbe.Id, 
                                                        Account_Id__c = accountId,
                                                        Location__c = pbe.Product2.Site__r.Name,
                                                        Gross__c = 0,
                                                        Net_Net_Net__c = 0,
                                                        RecordTypeId = recTypId,
                                                        Quantity__c = pro.Quantity__c > 0? pro.Quantity__c : 0,
                                                        Product_ID__c = pbe.Product2Id,
                                                        Product_Group_Name__c = pro.Advertising_Medium__r.Name);
            System.debug('===================mb=' + mb);
            BasketRow proGroupSelected = lstBasketRows.get(mapProductGroupAndIndex.get(pro.Advertising_Medium__r.Name));
            Boolean isEnableQty = pro.Quantity__c == null || pro.Quantity__c <= 0 ;
            BasketItem bi = new BasketItem(proGroupSelected.basketItems.size(), mb, pbe.UnitPrice, pbe.Product2.Rate_Card__c, isEnableQty);
            proGroupSelected.basketItems.add(bi);   
        }
        
    }
    /**
    * Method remove all related Products when Product Group is unchecked
    */
    public Pagereference removeProducts(){
        BasketRow proGroupSelected = lstBasketRows.get(indexProGroupSel);
        
        //check if it is existed Media_Basket, remove it from database
        Set<ID> mediaBasketIds = new Set<ID>();
        for(BasketItem subPro: proGroupSelected.basketItems){
            if(subPro.mb.Id == null) continue;
            mediaBasketIds.add(subPro.mb.Id);
        }
        if(!mediaBasketIds.isEmpty()){
            delete [Select Id From Media_Basket__c Where id in: mediaBasketIds];
        }
        
        proGroupSelected.selected = false;
        proGroupSelected.isChangedData = false;
        proGroupSelected.errorMsg = '';
        proGroupSelected.basketItems.clear();
        reCalculateTotalPriceAndProduct();
        return null;
    }
    
    /**
    * Method to remove sub product
    */
    public Pagereference removeSubProduct(){
        BasketRow proGroupSelected = lstBasketRows.get(indexProGroupSel);
        BasketItem subProSelected = proGroupSelected.basketItems.get(indexSubPro);
        
        //remove Media_Basket__c from database if it is existed
        String mediaBasketId = subProSelected.mb.Id == null ? '': subProSelected.mb.Id;
        if(mediaBasketId != ''){
            delete [Select Id From Media_Basket__c Where id =: mediaBasketId];
        }
        
        //remove sub product from list
        proGroupSelected.basketItems.remove(indexSubPro);
        
        //check Product Group has sub product
        //if it doesnt have a product, remove check from it
        if(proGroupSelected.basketItems.size() <= 0){
            proGroupSelected.selected = false;
            proGroupSelected.isChangedData = false;
            proGroupSelected.errorMsg = '';
            proGroupSelected.basketItems.clear();
        }
        //if it has prodcut, correct index
        else{
            Integer i=0;
            for(BasketItem subPro: proGroupSelected.basketItems){
                subPro.index = i;
                i++;
            }
        }
        
        //recalculate price
        reCalculateTotalPriceAndProduct();
        return null;
    }
    /**
    * Method calculate price and end date
    */
    public Pagereference calculatePrice(){
        BasketRow proGroupSelected = lstBasketRows.get(indexProGroupSel);
        proGroupSelected.isChangedData = true;
        proGroupSelected.errorMsg = '';
        BasketItem subProSelected = proGroupSelected.basketItems.get(indexSubPro);
        
        Decimal unitprice = subProSelected.unitPrice == null ? 0: subProSelected.unitPrice;
        Decimal qty = subProSelected.mb.Quantity__c == null? 0 : subProSelected.mb.Quantity__c;
        
        if(subProSelected.isRateCard){
            List<Rate_Card__c> lstRateCards = [Select Sales_Price__c, Id  
                                                    From Rate_Card__c 
                                                    Where Quantity2__c <=: subProSelected.mb.Quantity__c
                                                        AND Product__c =: subProSelected.mb.Product_ID__c
                                                        AND Length__c =: String.valueOf(Integer.valueOf(subProSelected.mb.Length_Months__c))
                                                        AND Active__c = true order by Quantity2__c desc limit 1];
                                                        
            if(!lstRateCards.isEmpty()){
                unitprice = lstRateCards.get(0).Sales_Price__c;
            }
        }
        hasError = false;
        //set start date 
        System.debug('===================subProSelected=' + subProSelected);
        subProSelected.mb.from_Date__c = Date.parse(subProSelected.startDate);
        System.debug('====================== ' + subProSelected.mb.from_Date__c.day() + 'month:' + subProSelected.mb.from_Date__c.month() + ' year: ' + subProSelected.mb.from_Date__c.year());
        if(subProSelected.mb.from_Date__c < system.today() || subProSelected.mb.from_Date__c == null){
            proGroupSelected.errorMsg = 'Start date cannot empty/less than today.';
            subProSelected.mb.from_Date__c.addError(' ');
            hasError = true;
        }
        
        subProSelected.mb.until_Date__c = calculateEndDate(subProSelected.mb.from_Date__c, Integer.valueOf(subProSelected.mb.Length_Months__c));
        subProSelected.mb.Sales_Price_Target__c = unitprice;
        subProSelected.mb.Gross__c = unitprice * qty;
        subProSelected.mb.Net_Net_Net__c = unitprice * qty;
        subProSelected.isChangedData = true;
        reCalculateTotalPriceAndProduct();
        return null;
    }
    
    /**
    * Method calculate end date
    */
    public static Date calculateEndDate(Date startDate, Integer month_length){
        if(startDate == null || startDate < System.today() || month_length == 0) return null;
        return startDate.addMonths(Integer.valueOf(month_length)).addDays(-1);
    }
    
    /**
    * Method calculate total price
    */
    private void reCalculateTotalPriceAndProduct(){
        totalSub = 0;
        totalPrice = 0;
        totalProduct = 0;
        for(BasketRow br: lstBasketRows){
            
            for(BasketItem bi: br.basketItems){
                totalSub += bi.mb.Gross__c == null ? 0 : bi.mb.Gross__c;
                totalPrice += bi.mb.Net_Net_Net__c;
                totalProduct++;
            }
        }
    }

    /**
    * Method continue to check out
    */
    public Pagereference doContinue2Checkout(){
        hasError = false;
        errorBskMsg  = '';
        
        //check validation each record
        if(!isValidated()){
            hasError = true;
            return null;    
        }
        
        
        //create Media basket
        List<Media_Basket__c> lstMediaBaskets = new List<Media_Basket__c>();
        for(BasketRow br:lstBasketRows){
            for(BasketItem bi: br.basketItems){
                if(!bi.isChangedData) continue;
                bi.mb.From_Site__c = true;
                lstMediaBaskets.add(bi.mb);
            }
        }
        
        if(!lstMediaBaskets.isEmpty()){
            try{
                upsert lstMediaBaskets;
            }catch(Exception e){
                hasError = true;
                errorBskMsg  = String.valueOf(e);
                return null;
            }
        }
        Pagereference pageref = Page.P2P_MyCheckOutPayment;
        pageref.getParameters().put('id', accountId);
        pageref.setRedirect(true);
        return pageref;
    }
    public String errorBskMsg { get; set; }
    /** 
    * Method check validation field
    * @return true if no error
    */
    private Boolean isValidated(){
        Boolean noError = true;
        String requiredMsg = 'You must enter value';
        for(BasketRow br: lstBasketRows){
            Boolean isError = false;
            
            for(BasketItem bi: br.basketItems){
                if(!bi.isChangedData) continue;
                
                if(bi.mb.Quantity__c == null || bi.mb.Quantity__c <= 0){
                    bi.mb.Quantity__c.addError(bi.mb.Quantity__c == null ? requiredMsg : 'Quantity must be greater than zero');
                    isError = true;
                }
                if(bi.mb.from_Date__c == null || bi.mb.from_Date__c < System.today()){
                    bi.mb.from_Date__c.addError(bi.mb.from_Date__c == null ? requiredMsg : 'Start Date must be later than today');
                    isError = true;
                }
                if(bi.mb.Length_Months__c == null || bi.mb.Length_Months__c <= 0){
                    //bi.mb.Length_Months__c.addError(bi.mb.Length_Months__c == null ? requiredMsg : 'Month length must be greater than zero');
                    isError = true;
                    bi.isErrorLength = true;
                    bi.msgErrorLength = bi.mb.Length_Months__c == null ? requiredMsg : 'Month length must be greater than zero';
                }
            }
            
            if(isError){
                br.errorMsg = 'Please specify your quantity, start date and duration';
                noError = false;
            }
        }
        
        return noError;
    }
    
    /**
    * Method check if record is valid (to valid BasketItem, populate all required fields) 
    */
    private Boolean isValidBasketItem(Media_Basket__c mb, Boolean checkStartDate){
        Boolean isValid = true;
        
        if(mb.Quantity__c == null || mb.Quantity__c <= 0){
            isValid = false;
        }
        if(mb.from_Date__c == null){
            
            isValid = false;
        }
        System.debug('===============checkStartDate=' + checkStartDate);
        if(checkStartDate && mb.from_Date__c < System.today()){
            isValid = false;
        }
        if(mb.Length_Months__c == null || mb.Length_Months__c <= 0){
            isValid = false;
        }
        
        return isValid;
    }
    
    
    public class BasketRow {
        public Integer index {get;set;}
        public String productGroupId {get;set;}
        public String productGroupName {get;set;}
        public String productGroupDesc {get;set;}
        public Boolean selected { get; set; }
        public List<BasketItem> basketItems{ get; set;}
        public String pricebookEntryId {get;set;}
        public Boolean isChangedData {get;set;}
        public Boolean isPopulate {get;set;}
        public String errorMsg {get;set;}
        
        public BasketRow(Integer index, Boolean isSelected, String pid, String pname, String pdesc, String pricebookEntryId){
            this.selected = isSelected;
            this.productGroupId = pid;
            this.productGroupName = pname;
            this.productGroupDesc = pdesc;
            this.pricebookEntryId = pricebookEntryId;
            this.basketItems = new List<BasketItem>();
            this.index = index;
            this.isChangedData = false;
            this.isPopulate = false;
            
        }
        
        public BasketRow(BasketRow br){
            this.selected = br.selected;
            this.productGroupId = br.productGroupId;
            this.productGroupName = br.productGroupName;
            this.productGroupDesc = br.productGroupDesc;
            this.pricebookEntryId = br.pricebookEntryId;
            this.basketItems = new List<BasketItem>();
            this.index = br.index;
            this.isChangedData = true;
            this.isPopulate = br.isPopulate;
        }
    }
    
    public class BasketItem { 
        public Media_Basket__c mb {get;set;}
        public Integer index {get;set;}
        public Boolean isEnableQty {get;set;}
        public Decimal unitPrice {get;set;}
        public Boolean isRateCard {get;set;}
        public Boolean isChangedData {get;set;}
        public String startDate {get;set;}
        public Boolean isErrorLength {get;set;}
        public String msgErrorLength {get;set;}
        
        public BasketItem(Integer i, Media_Basket__c mb, Decimal unitPrice, Boolean isRateCard, Boolean isEnableQty){
            this.index = i;
            this.mb = mb;
            this.unitPrice = unitPrice;
            this.isEnableQty = isEnableQty ;
            this.isRateCard = isRateCard;
            this.isChangedData = false;
            this.startDate = P2P_Utils.dateToStringWithFormat(mb.from_Date__c, 'dd/MM/yyyy');
            this.isErrorLength = false;
        }
        
    }
    
    
    /**
     * =========== Read more popup =============
     */
    public Advertising_Medium__c adMedium {get;set;}
    public String adid{get;set;}
    public String images{get;set;}
    
    public PageReference advMedium(){
        adMedium = [SELECT Name, Id,
                           Sales_message_1__c,
                           Sales_message_2__c,
                           Desktop_Image__c,
                           Mobile_Image__c,
                           iPhone_App_Image__c,
                           Android_App_Image__c 
                           FROM Advertising_Medium__c
                           WHERE Id = : adid];
                           
        images = (adMedium.Desktop_Image__c == null ? '' : adMedium.Desktop_Image__c) + ',';
        images += (adMedium.Mobile_Image__c == null ? '' : adMedium.Mobile_Image__c) + ',';
        images += (adMedium.iPhone_App_Image__c == null ? '' : adMedium.iPhone_App_Image__c) + ',';
        images += adMedium.Android_App_Image__c == null ? '' : adMedium.Android_App_Image__c;
        images = images.replaceAll(getSitePrefix(),'');
        return null;
    }
    
   // Alert banner at top of the page - Work in progress by Steve Paul
    public List<PKB_Status_Message__c> msgErr {
        get {
            List<PKB_Status_Message__c> systemMsg = new List<PKB_Status_Message__c>(); 
            for(PKB_Status_Message__c sm: [SELECT MessageText__c, Message_Type__c, Message_Start_DateTime__c, Message_End_DateTime__c, Module__c, Account__c
                                                  FROM PKB_Status_Message__c
                                                 WHERE Status__c = 'Active'
                                                  AND Module__c = 'Store'
                                                  AND (Account__c = :accountId OR Account__c = '')
                                                  AND ((Message_Start_DateTime__c < :system.now() AND
                                                        Message_End_DateTime__c   > :system.now())
                                                  OR   (Message_Start_DateTime__c = null AND
                                                        Message_End_DateTime__c   = null)) order by CreatedDate desc LIMIT 1
                                                  ]){
                   systemMsg.add(sm);
                 //System.debug('XXXXX sm-->' + sm);
            }
            return systemMsg;
        } 
        set;
    } 
    
}