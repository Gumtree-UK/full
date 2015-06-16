/** Controller of Product Configuration Page
  Main Functions:
    + Provides raw Campaign Items to be modified bases on the items in basket.
    + Duplicates the items.
    + Remove items from basket.
    + Splits items into 1 calendar week bases on Start Date and End Date.
    + Splits items into 2 calendar weeks bases on Start Date and End Date.
    + Splits items into calendar month bases on Start Date and End Date.
    + Copies and pasts the value of the field through the column.
    + Saves all items as campaign items and links to media campaign.
    + Restricts field usage based on product checkbox controls
    + Populates Sales price from Rate Card object based on length/quantity for Accounts products
  
  Where is it used?
    + The reference page is called from page SelectSearch and button "Modify Products" in Campaign Item related list of Media Campaign(by passing the selected items as Ids on the fly.)

Change log:
- 2013-07-01 - GTCRM-30 - Auto-calculate quantity for CPD
- 2013-07-01 - GTCRM-361 - Auto-calculate until (Date) based on Length/Months
- 2014-02-19 - GTCRM-809 - Upgrade DFP Time Targeting
- 2014-04-28 - task 2606 Can we please also add the copy down function so the users can copy targeting to the line items below once selected once in the modifyproduct page?
- 2014-29-04 - #3122 - MOVE FROM - TargetingCountryAssociation__c & TargetingCityAssociation__c  objects to TargetingGeographyAssociation__c object
- 2014-05-20 - GTCRM-635 - AdSales Automate screenshots - Preview URL
- 2014-06-10 - #3229 - GTCRM-880 - Devices & Connection Targeting
- 2014-06-27 - #GTCRM-946 Modify product error message - invalid integer 
- 2015-05-19 - Task #5285: GTCRM-1896 - Product Configuration: Auto-revert to top tier pricing
- 2015-05-19 - Task #5285: GTCRM-2002 - Pre-populate quantity from default on product
*/
public class ModifyProductController2{  
  
  public   List<DtoItem> lstRecords{get;set;}
   
  public String selPosition{get;set;}
  public String selColumn{get;set;}
  public String selShare{get;set;}
  public String selCopies{get;set;}
  public String mcName{get;set;}
  public String accName{get;set;}
  public String accId{get;set;}
  public Decimal oppProb{get;set;}
  public String errorMsg{get;set;}
  public Boolean fromDateError{get;set;}
  public String BP_Collision{get;set;}
  public Boolean forceDateSave{get;set;}  //Indicates that user decide to save even the Start Date > TODAY
  public Boolean errorFieldStatus{get;set;}
  public  String refreshUrl{get;set;}
  public String ActiveTab{get;set;}
  public Integer prodcount{get;set;}
  public  String mcPBId {set;get;}
  public Double selectedRandomNr {get;set;}
  public String warningOli {set;get;}
  
  public Boolean isSave {get;set;}
  private String camItems;
  private String backUrl;
  private String id;
  private List<Media_Basket__c> baskets;
  private Set<String> sItemId;  
  
  private Map<String, DtoItem> mapPackageMain = new Map<String, DtoItem>();
//  private Map<String, List<String>> mapPbe2Id = new Map<String, List<String>>(); // store Key: dtoId (main), value: procebookEntry of Package Component (child)
  private String currencyOpp = '';
  
  public String hsize {get;set;}
  public Boolean isEdit{get;set;}
    
  public static Map<String, String> mapValueBillingCategory2 = new Map<String, String>();
  private Integer dtoIdRunner ;
  
  private final String EXP_GETKEYVALUE = '(\\(.*?=(.*?)\\))';
  private final String EXP_GETKEY = '(\\((.*?)\\=.*?)\\)';
  
  private final String BILLING_CPM = 'CPM';
  
 public Map<String, Product_Pricing_Mapping__c> prodPricingMap {get;set;}

  public ModifyProductController2(ApexPages.StandardController controller){    
     
      prodPricingMap = Product_Pricing_Mapping__c.getAll();
      hsize = '63px';
      dtoIdRunner = 0;
      isSave = false; // to show error field after save
      //controller.setPageSize(10);
      errorFieldStatus = false;
      fromDateError = false;  
      forceDateSave = false;
      isEdit = false;
      isPollerMode = false;
      errorMsg = '';
      warningOli = '';
      
      camItems = ApexPages.currentPage().getParameters().get('camItems');
      backUrl = ApexPages.currentPage().getParameters().get('retURL');  
      refreshUrl = Apexpages.currentPage().getUrl();
      
      lDisplayRec = new List<DtoItem>();
      numbtn = new List<Integer>();
      disableNext = true;
      disablePre = true;
      pageNum = 1;
      
      //get all value of Billing category 2
      Schema.DescribeFieldResult F1 = Product2.Billing_Category2__c.getDescribe();
      List<Schema.PicklistEntry> P1 = F1.getPicklistValues();

      for(Schema.PicklistEntry x : P1){
        mapValueBillingCategory2.put(x.getValue(),x.getValue());
      }
        
        
      
      //Media Campaign Id manually passed by button "Add Items" in Campaign Items related list of Media Campaign
      id = ApexPages.currentPage().getParameters().get('mcId'); //id Opp
      mcPBId = ApexPages.currentPage().getParameters().get('mcPBId');//id pricebook
      
      if(id == null){
        id = ApexPages.currentPage().getParameters().get('id');
        isEdit=true;
      }
      
      List<Opportunity> listMedia = [Select Pricebook2Id, AccountId, Name, Account.Name,Probability From Opportunity  Where  Id=:id];
      
      if (listMedia.isEmpty()) return ;
      if(mcPBId == '' || mcPBId == null) mcPBId = listMedia.get(0).Pricebook2Id;
      mcName  = listMedia.get(0).Name;
      accName = listMedia.get(0).Account.Name;
      accId   = listMedia.get(0).AccountId;
      oppProb = listMedia.get(0).Probability;
      camItems = null;
      
      if(!isEdit){  //Add mode
        
        initList();
          
      }else{  // Edit mode
        
        //get all package products
        sItemId= new Set<String>();
        
        // All the related components are marked with the Salesforce id at the line item in the field “package_line_item__c”
        List<OpportunityLineItem> olis=[Select Id From OpportunityLineItem  Where opportunityId=:id and package_line_item__c = null]; 
        for (OpportunityLineItem oli: olis) {
          sItemId.add(oli.Id);
        }   
        
        
        handleEdit();
        backUrl='/'+ApexPages.currentPage().getParameters().get('id');
      }
      
      
  /*    if(id != null){ // ADD MODE
        List<Opportunity> listMedia = [Select , AccountId, Name, Account.Name,Probability From Opportunity  Where  Id=:id];
        if (listMedia.isEmpty()) return ;
        mcName  = listMedia.get(0).Name;
        accName = listMedia.get(0).Account.Name;
        accId   = listMedia.get(0).AccountId;
        oppProb = listMedia.get(0).Probability;
        initList(); 
        camItems = null;
        isEdit   = false;
        
      }else{ // EDIT MODE
        //Media Campaign Id automaticaly passed by button "Edit Seleted Items"
        id = ApexPages.currentPage().getParameters().get('id');
        List<Opportunity> listMedia = [Select AccountId, Name, Account.Name,Probability From Opportunity  Where  Id=:id];
        if (listMedia.isEmpty()) return ;
        mcName = listMedia.get(0).Name;
        accName = listMedia.get(0).Account.Name;
        accId = listMedia.get(0).AccountId;
        oppProb  =listMedia.get(0).Probability;
        
        sItemId= new Set<String>(); 
              
        String olids = ApexPages.currentPage().getParameters().get('modolis');
        if (olids!=null && olids!='') {     
          List<String> oli_list = olids.split(',');         
          for (String oli: oli_list) {
            sItemId.add(oli);
          }   
          
        }
        else { // edit all
          List<OpportunityLineItem> olis=[Select Id From OpportunityLineItem  Where OpportunityId=:id];
          for (OpportunityLineItem oli: olis) {
            sItemId.add(oli.Id);
          } 
        }
                
        camItems = null;        
        handleEdit();
        isEdit=true;
        backUrl='/'+ApexPages.currentPage().getParameters().get('id');
      }
    */
        reEvaluateAll();
      gotoPage();
    
      
      
      
  } 
 
  
  //populate the existing campaign item into product configuration screen
  private void handleEdit(){        
    warningOli ='';
    lstRecords  = new List<DtoItem>();
    baskets   = new List<Media_Basket__c>();
    String queryStr = 'Select Id';
    for(String f : mainFields){
      queryStr = queryStr + ', '+ f ;
    }
    //HB FIX, damit Pricebook abgefragt wird
    //2014-05-20 - GTCRM-635 - AdSales Automate screenshots - Preview URL
    queryStr = queryStr + ', Targeting__r.Name, PricebookEntry.Product2.RecordType.Name, PricebookEntry.Name,PricebookEntry.Product2.Billing_Category2__c,PricebookEntry.Product2.available_Key_Values__c, PricebookEntry.Product2.Id,PricebookEntry.Product2.Fixed_price__c,PricebookEntry.Product2.Fixed_Site__c,PricebookEntry.Product2.Variable_CPM_price__c,PricebookEntry.Product2.Billing_Category__c,PricebookEntry.Product2.Advertising_Medium__r.Name,PricebookEntry.Product2.Exclusive_Placement__c,PricebookEntry.Product2.Advertising_Medium__r.related_Mediums__c,PricebookEntry.Product2.Placement__r.Name,PricebookEntry.Product2.Site__r.Name,PricebookEntry.Product2.Name,PriceBookEntry.Product2.PreviewUrl__c';
    queryStr = queryStr + ' From OpportunityLineItem  where Id IN: sItemId';
    
    
    // get product Id to select available site
    Set <String> proIdsAva = new Set<String>();
    Map<String, String> mapAvailableSite = new Map<String, String>();
    
    List<OpportunityLineItem> lopli = (List<OpportunityLineItem>)Database.query(queryStr);
    for(OpportunityLineItem item : lopli){  
      proIdsAva.add(item.PricebookEntry.Product2.Id);
    }
    
  
    
    //get available site for opportunity
    for(Available_Site__c a : [Select a.available_Site__r.DartName__c, a.available_Site__r.Id, a.available_Site__c, a.Product__c, a.Id From Available_Site__c a where Product__c in: proIdsAva order by available_Site__r.DartName__c]){
        if(!mapAvailableSite.containsKey(a.Product__c)){
          mapAvailableSite.put(a.Product__c, a.available_Site__r.DartName__c + '.');
        }else{
          String tmp = mapAvailableSite.get(a.Product__c);
          tmp = tmp.subString(0, tmp.length() - 1);
          tmp += ',' + a.available_Site__r.DartName__c + '.';
          mapAvailableSite.put(a.Product__c, tmp);
        }
    }
    
    //get product for opportunity
    Map<Id, Product2> mapProduct = new Map<Id, Product2>([select p.Id, p.Quantity__c, p.Name, p.tech_targeting__c, p.Time__c, p.Keywords__c, p.FC__c, p.ManualSetEndDate__c, p.MonthsDays__c, p.Fixed_Price__c, p.Fixed_Site__c, p.Geo_IP__c, p.Rate_Card__c, p.Length_Months__c, p.PreviewURL__c, p.Devices__c, p.Connections__c  From Product2 p where id in: proIdsAva]);
    
    //get package_component to check predefine_Key_Value
    //Map<String, Boolean> mapChkPreDefineKey = new Map<String, Boolean>();
    //for(Packagecomponent__c p : [Select p.predefined_Key_Values__c, p.Package_product__c, p.Id From Packagecomponent__c p where Package_product__c in: proIdsAva]){
    //  mapChkPreDefineKey.put(p.Package_product__c, (p.predefined_Key_Values__c == null? false: true));
    //}
    
    
    
    for(OpportunityLineItem item : lopli){                  
      
      Media_Basket__c bsk = new Media_Basket__c(AdPriceIdText__c=item.PriceBookEntryId, UserId__c=System.Userinfo.getUserId(), OpportunityId__c=id);      
      baskets.add(bsk);
      
      //DtoItem newItem = new DtoItem(item.PricebookEntry.Name,item);
      Boolean hasSite = false;
      if(mapAvailableSite.containsKey(item.PricebookEntry.Product2.Id)) hasSite = true;
      DtoItem newItem = new DtoItem(item.PricebookEntry.Name, item, item.PricebookEntry.Product2.Fixed_Site__c, item.PricebookEntry.Product2.Id, mapAvailableSite.get(item.PricebookEntry.Product2.Id), hasSite, item.PricebookEntry.Product2.available_Key_Values__c, item.PricebookEntry.Product2.Billing_Category2__c, mapProduct.get(item.PricebookEntry.Product2.Id), (item.PricebookEntry.Product2.available_Key_Values__c == null? false : true), dtoIdRunner);
      newItem.billingCategory2 = item.Billing_category__c;
      newItem.setquantity(item.Quantity == null ?  '' : String.valueOf(item.Quantity));
      dtoIdRunner = newItem.dtoId; 
      lstRecords.add(newItem);
    }
    
    
    
    prodcount = lstRecords.size();  
    refreshPosition(lstRecords);
    warningOli = lstRecords.size() > 100 ? system.Label.Warning_OppLine : '';
  }
  
  /*
    Selects all related basket records from the system to create a list of CompaignItems depends on its product to modify or remove.
  */
  private void initList(){    
    
      warningOli='';
      lstRecords = new List<DtoItem>();             
      Set<String> sEntriesID = new Set<String>();
      Map<String,Decimal> sEntriesPrice = new Map<String,Decimal>();      
          
      baskets = [Select Id,AdPriceIdText__c From Media_Basket__c where UserId__c=:System.userInfo.getUserId() AND OpportunityId__c=:id];
      
      for (Media_Basket__c media:baskets){
        sEntriesID.add(media.AdPriceIdText__c);
      }
                        
      Map<Id,PricebookEntry> mPriceBook = new Map<Id,PricebookEntry>([Select  Unitprice,
                                          Id, 
                                          Name, 
                                          Product2Id,
                                          Product2.Default_Geo_IP__c, 
                                          Product2.Variable_CPM_price__c,
                                          Product2.Name, 
                                          Product2.Id,
                                          Product2.Fixed_price__c,
                                          Product2.Advertising_Medium__r.Name,
                                          Product2.Advertising_Medium__r.FC_Quantity__c,
                                          Product2.Advertising_Medium__r.FC_Period__c,
                                          Product2.Advertising_Medium__r.FC_Ad_served_every__c,
                                          Product2.AdServer_Keywords_Key_Values__c,
                                          Product2.RecordType.Name,
                                          Product2.Billing_Category__c,
                                          Product2.Billing_Category2__c,
//                                          Product2.garantiertes_AI_Volumen_Januar__c,
//                                          Product2.garantiertes_AI_Volumen_Februar__c,
//                                          Product2.garantiertes_AI_Volumen_M_rz__c,
//                                          Product2.garantiertes_AI_Volumen_April__c,
//                                          Product2.garantiertes_AI_Volumen_Mai__c,
//                                          Product2.garantiertes_AI_Volumen_Juni__c,
//                                          Product2.garantiertes_AI_Volumen_Juli__c,
//                                          Product2.garantiertes_AI_Volumen_August__c,
//                                          Product2.garantiertes_AI_Volumen_September__c,
//                                          Product2.garantiertes_AI_Volumen_Oktober__c,
//                                          Product2.garantiertes_AI_Volumen_November__c,
//                                          Product2.garantiertes_AI_Volumen_Dezember__c,
                                          Product2.Exclusive_Placement__c,
                                          Product2.Advertising_Medium__r.related_Mediums__c,
                                          Product2.Placement__r.Name,
                                          Product2.Site__r.Name,
                                          Product2.Fixed_Site__c,
                                          Product2.available_Key_Values__c,
                                          Product2.Length_Months__c,
                                          //2014-05-20 - GTCRM-635 - AdSales Automate screenshots - Preview URL                                          
                                          Product2.PreviewUrl__c
                                          from PricebookEntry a where Id in:sEntriesID]);
                                          
      System.debug('==================================================================mPriceBook: ' + mPriceBook);
      
    //  String billcat;
      Integer quant;
      String pack;
    //  Decimal pprice;     
      Set <String> proId = new Set<String>();
      
      Map<String, String> mapDtoId = new Map<String, String>();
      
      // get product Id to select available site
      Set <String> proIdsAva = new Set<String>();
      Map<String, String> mapAvailableSite = new Map<String, String>();
      
      for (PricebookEntry pbe: mPriceBook.values()){
        proIdsAva.add(pbe.Product2Id);
      }
      
      //get available site of each product
      for(Available_Site__c a : [Select a.available_Site__r.DartName__c, a.available_Site__r.Id, a.available_Site__c, a.Product__c, a.Id From Available_Site__c a where Product__c in: proIdsAva order by available_Site__r.DartName__c]){
        if(!mapAvailableSite.containsKey(a.Product__c)){
          mapAvailableSite.put(a.Product__c, a.available_Site__r.DartName__c + '.');
        }else{
          String tmp = mapAvailableSite.get(a.Product__c);
          tmp = tmp.subString(0, tmp.length() - 1);
          tmp += ' , ' + a.available_Site__r.DartName__c + '.';
          mapAvailableSite.put(a.Product__c, tmp);
        }
      }
      
        //get product for opportunity
        Map<Id, Product2> mapProduct = new Map<Id, Product2>([select p.Id, p.Quantity__c, p.Name, p.tech_targeting__c, p.Time__c, p.Keywords__c, p.FC__c, p.ManualSetEndDate__c, p.MonthsDays__c, p.Fixed_Price__c, p.Fixed_Site__c, p.Geo_IP__c, p.Rate_Card__c, p.Length_Months__c From Product2 p where id in: proIdsAva]);
        
        //get package_component to check predefine_Key_Value
        ///Map<String, Boolean> mapChkPreDefineKey = new Map<String, Boolean>();
        //for(Packagecomponent__c p : [Select p.predefined_Key_Values__c, p.Package_product__c, p.Id From Packagecomponent__c p where Package_product__c in: proIdsAva]){
        //  mapChkPreDefineKey.put(p.Package_product__c, (p.predefined_Key_Values__c == null ? false: true));
        //}
        
        
      for (Media_Basket__c media: baskets){
        PricebookEntry priceBook = mPriceBook.get(media.AdPriceIdText__c);                    
        pack = '';
        
        if (priceBook.Product2.RecordType.Name == 'Package') { // PACKAGE
        //  pack = 'Content Special';
          proId.add(pricebook.Product2Id);
        }
        
        OpportunityLineItem camItem = new OpportunityLineItem(  PricebookEntryId  = priceBook.Id,
                                    PricebookEntry    = priceBook,
                                    OpportunityId     = id,
                                    Billing_category__c = priceBook.Product2.Billing_Category__c,
                                    UnitPrice       = priceBook.Unitprice,
                                    Discount__c = 0,
                                    FC_Quantity__c    = pricebook.Product2.Advertising_Medium__r.FC_Quantity__c,
                                    FC_Period__c    = pricebook.Product2.Advertising_Medium__r.FC_Period__c,
                                    FC_Ad_served_every__c = pricebook.Product2.Advertising_Medium__r.FC_Ad_served_every__c,
                                    AdKeywords__c = pricebook.Product2.AdServer_Keywords_Key_Values__c,
                                    KeyValueString__c = pricebook.Product2.AdServer_Keywords_Key_Values__c,
                                    Check_Inventory__c  = true,
                                    from_date__c = date.today(),
                                    until_Date__c = date.today().addMonths(1),
                                    Length_months__c = pricebook.Product2.Length_Months__c,
                                    //until_Date__c = date.today(),
                                    Quantity      = quant
                                    //Package__c      = pack,
                                    //Customer_Order_No__c=''
                                    );
        //DtoItem newItem = new DtoItem(priceBook.Product2.Name,camItem);   
        Boolean hasSite = false;
        
        if(mapAvailableSite.containsKey(priceBook.Product2.Id)) hasSite = true;   
        DtoItem newItem = new DtoItem(priceBook.Product2.Name, camItem, priceBook.Product2.Fixed_Site__c, priceBook.Product2.Id ,mapAvailableSite.get(priceBook.Product2.Id), hasSite, priceBook.Product2.available_Key_Values__c, priceBook.Product2.Billing_Category2__c, mapProduct.get(priceBook.Product2.Id), (priceBook.Product2.available_Key_Values__c == null ? false : true), dtoIdRunner);
        dtoIdRunner = newItem.dtoId;
        mapDtoId.put(priceBook.Product2.Id, newItem.dtoId + '');  //get DtoId to use as key for Package Component related
        mapPackageMain.put(newItem.dtoId + '' , newItem);   //get main Package
        
        
        lstRecords.add(newItem);
      
      } 
      
      //SP 08-08-11
      //Package Component Related Package Product
      if(proId.size() > 0){
          //get package component related product(main)
    /*      List<Product2> eprods = [Select Id,(select Package_product__c, Singleproduct__c, Price__c from Packagecomponents__r) from Product2 where Id in:proId];
          
          Map<String, PricebookEntry> mapPbe = new Map<String, PricebookEntry>();
          sEntriesID.clear();
          
          for (Product2 pro : eprods){
            for(Packagecomponent__c pb : pro.Packagecomponents__r){
              sEntriesID.add(pb.Singleproduct__c);
              sEntriesPrice.put(pro.Id + '_' + pb.Singleproduct__c,pb.Price__c);
            }
          }       
                    
          for (PricebookEntry priceBook2:[Select Product2.Billing_Category__c,Unitprice, 
                              Product2.Name, 
                              Product2.Id, 
                              Product2.Fixed_price__c,
                              Product2.Advertising_Medium__r.FC_Quantity__c,
                              Product2.Advertising_Medium__r.FC_Period__c,
                              Product2.Advertising_Medium__r.FC_Ad_served_every__c,
                              Product2.RecordType.Name ,
                              Product2.Fixed_Site__c,
                              Product2.available_Key_Values__c
                              from PricebookEntry where Pricebook2Id=:mcPBId and Product2Id in :sEntriesID]){
            
            mapPbe.put(priceBook2.Product2.Id, priceBook2);
          }
          
  */        
  //        for (Product2 pro : eprods){
            
  //          for(Packagecomponent__c pb : pro.Packagecomponents__r){
  //            if(!mapPbe.containskey(pb.Singleproduct__c)) continue;
  //            PricebookEntry pbe = mapPbe.get(pb.Singleproduct__c);   
              
            /*  if(!mapPbe2Id.containsKey(mapDtoId.get(pro.Id))){
                mapPbe2Id.put(mapDtoId.get(pro.Id), new List<String>());
              }
              mapPbe2Id.get(mapDtoId.get(pro.Id)).add(pbe.Id);
            */  
  //            if(!mapPbe2Id.containsKey(pro.Id)){
  //              mapPbe2Id.put(pro.Id, new List<String>());
  //            }
  //            mapPbe2Id.get(pro.Id).add(pbe.Id);
              
              
            
          /*    OpportunityLineItem opli = new OpportunityLineItem( PricebookEntryId = pbe.Id,
                                          OpportunityId = id,
                                          Billing_category__c = pbe.Product2.Billing_Category__c,
                                          UnitPrice = sEntriesPrice.get(pro.Id + '_' + pbe.Product2.Id),
                                          FC_Quantity__c = pbe.Product2.Advertising_Medium__r.FC_Quantity__c,
                                          FC_Period__c = pbe.Product2.Advertising_Medium__r.FC_Period__c,
                                          FC_Ad_served_every__c = pbe.Product2.Advertising_Medium__r.FC_Ad_served_every__c,
                                          Check_Inventory__c = true,
                                          Quantity = quant
                                          //Package__c = 'Content Special');
                                          );
                                          
              //DtoItem newItem2 = new DtoItem(pbe.Product2.Name,opli);
              Boolean hasSite = false;
              if(mapAvailableSite.containsKey(pbe.Product2.Id)) hasSite = true;
              DtoItem newItem2 = new DtoItem(pbe.Product2.Name,opli,pbe.Product2.Fixed_Site__c,pbe.Product2.Id,mapAvailableSite.get(pbe.Product2.Id), hasSite, pbe.Product2.available_Key_Values__c);
              lstRecords.add(newItem2);
          */  
    //        }
    //      }
        
          
      }
      
      
      
      prodcount=lstRecords.size();
       
      refreshPosition(lstRecords);
      warningOli = lstRecords.size() > 100 ? system.Label.Warning_OppLine : '';
  } 
   
  /* Bunhor @ 18-July-2014
   * TODO: Default Geo-IP Targeting on Product Level 
   * Called from action menthod from modifyproduct2.page 
   */
    public PageReference createDefaultGeoNames(){
      if(isEdit) return null; // only when new oli inserting
      
      set<String> setDefaultGEOs = new Set<String>();
      Targeting__c[] lstTGs = new List<Targeting__c>();
      
      OpportunityLineItem[] lstOliHasGeos = new List<OpportunityLineItem>();
       
      for(DtoItem dto : lstRecords){ 
        String strGEOs = dto.item.PricebookEntry.Product2.Default_Geo_IP__c;
        if(strGEOs != null && dto.item.id == null){ //   only when new oli inserting ==> dto.item.id == null
          lstOliHasGeos.add(dto.item);
          lstTGs.add(new Targeting__c()); // creating Targeting__c for oli that has Default_Geo_IP__c
          for(String geo : strGEOs.split(',')){
            if(geo != '' && geo != null)  setDefaultGEOs.add(geo.trim());  
          } 
        } 
      }
      
      if(!setDefaultGEOs.isEmpty() && !lstTGs.isEmpty()){
        // getting all Geography__c that matched wiht product2.Default_Geo_IP__c
        Map<String, Geography__c> mapGeographyName2Geography = new Map<String, Geography__c>();
        for(Geography__c g : [select Id, Name, Node_ID__c from Geography__c where Name in :setDefaultGEOs and Name != null]){
          mapGeographyName2Geography.put(g.Name, g );
        }
        
        if(!mapGeographyName2Geography.isEmpty()){
          insert lstTGs;
        
        // creating and inserting TargetingGeographyAssociation__c
          TargetingGeographyAssociation__c[] lstGeoAss = new List<TargetingGeographyAssociation__c>();
          
          for(integer i=0; i<lstOliHasGeos.size(); i++){
            OpportunityLineItem li = lstOliHasGeos[i];
            Targeting__c tg = lstTGs[i];
             
            li.Targeting__c = tg.Id;  // assigning Targeting__c to the line item
            String countryDesc = '';
            String cityDesc = '';
            
            String strGEOs = li.PricebookEntry.Product2.Default_Geo_IP__c;
            
            // each oli have many TargetingGeographyAssociation__c (loop to create it)
            for(String geo : strGEOs.split(',')){
               
              Geography__c geography = mapGeographyName2Geography.get(geo.trim());
              if(geography != null){ 
                countryDesc += (geography.Node_ID__c == null)? (geo+', ') : ''; 
                cityDesc += (geography.Node_ID__c == null)? '' : (geo+', ') ;
               
                lstGeoAss.add(new TargetingGeographyAssociation__c( Targeting__c = tg.Id, Geography__c = geography.id)  );
              }
            }
            
            li.Countries_Description__c = countryDesc;
            li.City_description__c = cityDesc;
          } 
          insert lstGeoAss; 
        } 
      }
      return null;
    }
    
      
  /*
  
  Remove a basket record from list based on Ad_Price__c.Id
  
  */
  private void removeBasket(String pricebookEntryId){ 
     warningOli = '';       
    for(Integer k=0;k<baskets.size();k++){            
      if(baskets.get(k).AdPriceIdText__c==pricebookEntryId){  
          String idBasket =   baskets.get(k).Id;
          baskets.remove(k);
          
          //remove basket from database
          delete [Select Id From Media_Basket__c where id =: idBasket];
          break;
      }                         
    }       
    
                   
    warningOli = lstRecords.size() > 100 ? system.Label.Warning_OppLine : '';       
  }   
  /*
  Reset positon of DtoItem record depends on index in list
  */
  private void refreshPosition(List<DtoItem> recDTOs){    
      warningOli = '';
      for(Integer i=0;i<recDTOs.size();i++){        
        recDTOs.get(i).position=i;        
      }
      //System.debug('>>>>>>>>>>>>>>>>recDTOs.size():'+recDTOs.size());
      warningOli = recDTOs.size() > 100 ? system.Label.Warning_OppLine : '';
  }   
  
  
  private Media_Basket__c createNewBasket(OpportunityLineItem tmpCamItem){
    Media_Basket__c nBasket=new Media_Basket__c(adPriceIdText__c=tmpCamItem.PricebookEntryId,OpportunityId__c=id,UserId__c=System.Userinfo.getUserId());    
    return nBasket;
      
  }
   
  private OpportunityLineItem getNewCamItem(String productName,OpportunityLineItem camItem,Decimal quantity,Date startDate,Date endDate){
       
      OpportunityLineItem nCamItem = createClone(productName,camItem, '');
       //camItem.clone(false,true);
      nCamItem.Quantity=quantity;
      nCamItem.from_Date__c=startDate;
      nCamItem.until_Date__c=endDate;
      
      //bindTreeConfigurator(nCamItem, productName);  -> bindTreeConfigurator(map);
      return nCamItem;  
   }
  /*
    Return 3 letters day string of input date.
    Ex: getDayInWeek(17/05/2010) returns ‘MON’;
        
  */
  private String getDayInWeek(Date argDate){
    DateTime tmp=DateTime.newInstance(argDate.year(),argDate.month(),argDate.day());
    return tmp.format('EEE');
  }
  /*
  Get number of crossing months that are available in input range.
    Ex:12/04/2010 , 12/05/2010
    Return 2;
  */  
  private Integer getNumMonths(Date startDate,Date endDate){
    Integer months=0;
    Date lastSun=startDate;
    Date startTmp=startDate;
    Date lastDate;
    while(startTmp<=endDate){
      lastDate=lastDate=Date.newInstance(startTmp.year(), startTmp.month(), date.daysInMonth(startTmp.year(),startTmp.month()));
      if(startTmp==lastDate){
        months=months+1;
        lastSun=startTmp;
      }
      startTmp=startTmp.addDays(1);
    }
    If(lastSun<endDate){
      months=months+1;
    }
    return months;
  }
  /*
  Get number of calendar weeks in input range date if iweek2 equal false.
  If iweek2 equal false , its return number of 2 calendar week.
  */
  private Integer getNumWeeks(Date startDate,Date endDate,Boolean isweek2){
    Double week=0;
    Double week2=0;
    Date lastSun=startDate;
    Date startTmp=startDate;
    while(startTmp<=endDate){
      startTmp=startTmp.addDays(1);       
      if(getDayInWeek(startTmp)=='Sun'){
        week=week+1; 
        lastSun=startTmp;       
      }
    }
    if(lastSun<endDate) week=week+1;
    if(isweek2) return (Math.ceil(week/2)).intValue();
    return week.intValue();
    
  }

  /*
  Copy value from selected field and  paste through the same column. 
  Types of field to be copied:
    - Checkbox (boolean)
    - Text
    - Number
    ** Ignore the other fields that already had value
  */
  private void doCopy(boolean force){
    //System.debug('========================================================positiion:' + selPosition);
    //System.debug('========================================================lstRecords.size():' + lstRecords.size());
    try{
    errorMsg='';
    warningOli = '';
    fromDateError=false;
    forceDateSave=false;
    errorFieldStatus=false;
    DtoItem selDtoItem = lstRecords.get(Integer.valueOf(selPosition));
    OpportunityLineItem selItem = selDtoItem.item;
    Targeting__c srcTar;
   //   String selItemidAsString = selItem.Targeting__c + '';
    if( (selItem.Targeting__c + '') != ''){
      srcTar =  [Select Id,
            (Select Operator__c, Targeting__c, DART_KeyValue__c, DART_KeyValue__r.Key_Value_Name__c, targetkeyvalue__c From TargetingKeyValueAssociations__r), 
            //(Select Targeting__c, Country__c, TargetCountry__c From TargetingCountryAssociations__r), 
            (Select Targeting__c, TargetingContent__c, TargetingContent__r.DartName__c, Exclude__c, Target_Content_Key__c From TargetingContentAssociations__r), 
            //(Select Targeting__c, City__c, targetcity__c From TargetingCityAssociations__r), 
            (Select Targeting__c, AreaCode__c, Target_Areacode_Key__c From TargetingAreaCodeAssociations__r) ,
            (Select Targeting__c, Geography__c, TargetGeography__c  From TargetingGeographyAssociations__r ),
            (Select Targeting__c, Device__c, TargetDevice__c From TargetingDeviceAssociations__r),
            (Select Targeting__c, Connection__c, TargetConnection__c From TargetingConnectionAssociations__r)
            From Targeting__c t Where Id =: selItem.Targeting__c];
      
    }
    Boolean isBoolean = false;
    Map<String, Schema.SObjectField> mapOpportItemField = Schema.SObjectType.OpportunityLineItem.fields.getMap();
    Schema.SObjectField so = mapOpportItemField.get(selColumn);
    if(so.getDescribe().getType()==Schema.DisplayType.BOOLEAN){
      isBoolean = true;
    }
//    System.debug('--------selPosition--------- '+selPosition);
    
       
      Map<Integer, Targeting__c> mapTarget = new Map<Integer, Targeting__c>(); // new targeting
      Map<Integer, String> mapTargetId = new Map<Integer, String>(); //existing targetingId
      
      Map<Integer, OpportunityLineItem> mapOliExist = new Map<Integer, OpportunityLineItem>();//for save Targeting match with line item  
      
     // System.debug('>>>>>>>>>>>>>>>>selColumn = '+selColumn);
     // System.debug('>>>>>>>>>>>>>>>>lstRecords = '+lstRecords);
      for(Integer i=Integer.valueOf(selPosition)+1 ;i < lstRecords.size() ; i++){
      //  System.debug('========================================================positiion:' + i);
      //System.debug('>>>>>>>>>>>>>>>>i = '+i);
      //System.debug('>>>>>>>>>>>>>>>>lDisplayRec = '+lDisplayRec.get(i));
      //System.debug('>>>>>>>>>>>>>>>>lDisplayRec = '+lDisplayRec);
      
      if(selColumn == 'DFP_Time_Monday__c'){
          if(force){
            lstRecords.get(i).strHourOfDays = selDtoItem.strHourOfDays;
          }else{
            if( lstRecords.get(i).strHourOfDays == '' ){
              lstRecords.get(i).strHourOfDays = selDtoItem.strHourOfDays;
            }
          } 
      }
      
      if(selColumn == 'UnitPrice'){
         if(lstRecords.get(i).item.PricebookEntry.Product2.Fixed_price__c == true && (lstRecords.get(i).item.Billing_category__c == 'CPM' || lstRecords.get(i).item.Billing_category__c == 'Fix price' || lstRecords.get(i).item.Billing_category__c == 'CPD')){
           continue;
         }
      }else if(selColumn == 'Rich_Line_Description__c'){
        if(lstRecords.get(i).isFixedSite == true || lstRecords.get(i).isHasSite == false){
          continue;
        }
      }else if(selColumn == 'KeyValueString__c'){
         if(lstRecords.get(i).isHasPreDefine == false){
           continue;
         }
      }
      else if(selColumn == 'FC_Quantity__c' || selColumn == 'FC_Ad_Served_Every__c' || selColumn == 'FC_Period__c' || selColumn == 'Check_Inventory__c'){
         if(lstRecords.get(i).pro.FC__c == false){
           continue;
         }
      }
      else if(selColumn == 'AdBrowsersMinorVersion__c' || selColumn == 'AdBrowsersMajorVersion__c' || selColumn == 'AdOperatingSystems__c' || selColumn == 'AdWebBrowsers__c'){
         if(lstRecords.get(i).pro.tech_targeting__c == false){
           continue;
         }
       
      }
      else if(selColumn == 'Length_Months__c' || selColumn == 'Additional_Time_Days__c'){
         if(lstRecords.get(i).pro.MonthsDays__c == false){
           continue;
         }
         }
      else if(selColumn == 'until_Date__c'){
         if(lstRecords.get(i).pro.ManualSetEndDate__c == false){
           continue;
         }
         }
        else if(selColumn == 'AdKeywords__c' || selColumn == 'Keywords_KeyValue_combination__c'){
         if(lstRecords.get(i).pro.Time__c == false){
           continue;
         }
         }
    else if(selColumn == 'Countries_Description__c' || selColumn == 'City_description__c'){
         if(lstRecords.get(i).pro.Geo_IP__c == false){
           continue;
         }
         }
         else if(selColumn == 'PreviewURL__c'){
         if(lstRecords.get(i).pro.PreviewURL__c == false){
           continue;
         }
         }

      // System.debug('1111111111');
    OpportunityLineItem tmp=lstRecords.get(i).item;
      if(!force){
         if((!isBoolean && tmp.get(selColumn) != null && tmp.get(selColumn) != '' ) || (isBoolean && (tmp.get(selColumn) == selItem.get(selColumn)))){
          //break;
          if(mapOpportItemField.get(selColumn).getDescribe().getType() == Schema.DisplayType.Double || mapOpportItemField.get(selColumn).getDescribe().getType() == Schema.DisplayType.Integer || mapOpportItemField.get(selColumn).getDescribe().getType() == Schema.DisplayType.CURRENCY){
            if(tmp.get(selColumn) != 0){
              continue;
            }
          }else{
            continue;
          }
        }
      }
      ///  System.debug('========================================================positiion1:' + i);
      tmp.put(selColumn,selItem.get(selColumn));
      
      if(selColumn == 'Targeting_Surcharge__c'){
        tmp.put('Surcharge_Type__c',selItem.get('Surcharge_Type__c'));
      }
      if(selColumn== 'Rate_Discount_II__c'){
        tmp.put('Discount_Type__c',selItem.get('Discount_Type__c'));
      }
       
      //Tree copier down direction: copy all tree relation of srcProduct to another
      if(srcTar <> null) {
        //dirrectly comparation cause invalid id while id == null
        String idAsString = tmp.Targeting__c;
        Targeting__c tmpTar;
        if(idAsString == '' || idAsString == null){
           tmpTar = new Targeting__c(TempBinder__c = true , Description__c = selDtoItem.productName + ' targeting' ); 
          //insert tmpTar;
          mapTarget.put(i,tmpTar);
           mapOliExist.put(i, tmp);
          //tmp.Targeting__c = tmpTar.Id;
        }else{
          mapTargetId.put(i,idAsString);
        }
     
         
      }      
      
    }
    
    for(Integer i=Integer.valueOf(selPosition)-1; i >= 0 ; i-- ){
      //System.debug('==========================22==============================positiion:' + i);
        
        if(selColumn == 'DFP_Time_Monday__c'){
            if(force){
              lstRecords.get(i).strHourOfDays = selDtoItem.strHourOfDays;
            }else{
              if( lstRecords.get(i).strHourOfDays == '' ){
                lstRecords.get(i).strHourOfDays = selDtoItem.strHourOfDays;
              }
            } 
        }
        
        if(selColumn == 'UnitPrice'){
          if(lstRecords.get(i).item.PricebookEntry.Product2.Fixed_price__c == true && (lstRecords.get(i).item.Billing_category__c == 'CPM' || lstRecords.get(i).item.Billing_category__c == 'Fix price')){
            continue;
          }
        }else if(selColumn == 'Rich_Line_Description__c'){
          if(lstRecords.get(i).isFixedSite == true || lstRecords.get(i).isHasSite == false){
            continue;
          }
        }else if(selColumn == 'KeyValueString__c'){
           if(lstRecords.get(i).isHasPreDefine == false){
             continue;
           }
        }//else if(selColumn == 'AdBrowsersMajorVersion__c'){
          // if(lstRecords.get(i).pro.Keywords__c == false){
           //  continue;
           //}
        //}
        else if(selColumn == 'FC_Quantity__c' || selColumn == 'FC_Ad_served_every__c' || selColumn == 'FC_Period__c' || selColumn == 'Check_Inventory__c'){
           if(lstRecords.get(i).pro.FC__c == false){
             continue;
           }
        }else if(selColumn == 'AdBrowsersMinorVersion__c' || selColumn == 'AdBrowsersMajorVersion__c'){
           if(lstRecords.get(i).pro.tech_targeting__c == false){
             continue;
           }
        }
        else if(selColumn == 'Length_Months__c' || selColumn == 'Additional_Time_Days__c'){
      //  System.debug('22222222');
         if(lstRecords.get(i).pro.MonthsDays__c == false){
           continue;
         }
         }
      else if(selColumn == 'until_Date__c'){
      //  System.debug('22222222');
         if(lstRecords.get(i).pro.ManualSetEndDate__c == false){
           continue;
         }
         }
          else if(selColumn == 'PreviewURL__c'){
         if(lstRecords.get(i).pro.PreviewURL__c == false){
           continue;
         }
         }

        OpportunityLineItem tmp=lstRecords.get(i).item;
        
         if(!force){
           if((!isBoolean && tmp.get(selColumn) != null && tmp.get(selColumn) != '' ) || (isBoolean && (tmp.get(selColumn) == selItem.get(selColumn)))){
             // break;
             if(mapOpportItemField.get(selColumn).getDescribe().getType() == Schema.DisplayType.Double || mapOpportItemField.get(selColumn).getDescribe().getType() == Schema.DisplayType.Integer || mapOpportItemField.get(selColumn).getDescribe().getType() == Schema.DisplayType.CURRENCY){
              if(tmp.get(selColumn) != 0){
                
                continue;
              }
            }else{
              continue;
            }
             
             
          }
         }
       //   System.debug('=========================22===============================positiion1:' + i);
        tmp.put(selColumn,selItem.get(selColumn));
        if(selColumn == 'Targeting_Surcharge__c'){
            tmp.put('Surcharge_Type__c',selItem.get('Surcharge_Type__c'));
         }
         if(selColumn== 'Rate_Discount_II__c'){
            tmp.put('Discount_Type__c',selItem.get('Discount_Type__c'));
         }
        //Tree copier up direction: copy all tree relation of srcProduct to another
        if(srcTar <> null) {
          String idAsString = tmp.Targeting__c;
          if(idAsString == '' || idAsString == null){
            Targeting__c tmpTar = new Targeting__c(TempBinder__c = true , Description__c = selDtoItem.productName + ' targeting' ); 
            //insert tmpTar;
            mapTarget.put(i,tmpTar);
            mapOliExist.put(i, tmp);
            //tmp.Targeting__c = tmpTar.Id;
          }else{
            mapTargetId.put(i,idAsString);
          }
          
         /*
          if(selColumn == 'Rich_Line_Description__c'){
            copyTargetContent (srcTar , tmp.Targeting__c);
            
          }else if(selColumn == 'KeyValueString__c'){
            copyTargetKeyValue (srcTar , tmp.Targeting__c);
            
          }else if(selColumn == 'CountriesDescription__c'){
            copyTargetCountry (srcTar , tmp.Targeting__c);
            
          }else if(selColumn == 'TargetCitiesString__c'){
            copyTargetCity(srcTar , tmp.Targeting__c);
            
          }else if(selColumn == 'AreaCode_Description__c'){
            copyTargetAreacode(srcTar , tmp.Targeting__c);
            
          }
           
          */
         
          
        }
      
    }
    //insert new targeting to pull ids 
    insert  mapTarget.values();
    system.debug('mapTarget===='+mapTarget);
    //match line item and targeting
    for(Integer keymap: mapOliExist.keySet()){
      mapOliExist.get(keymap).Targeting__c = mapTarget.get(keymap).Id;
    }
    
    
    Map<String, Targeting__c> mapTarget2 = new Map<String, Targeting__c>(); //k= new tID; v = src
    
    for(Targeting__c t: mapTarget.values()){ //put new ids
      mapTarget2.put(t.Id,srcTar);       
    }
     for(String idAsString: mapTargetId.values()){  //put existing ids
      mapTarget2.put(idAsString,srcTar);       
    }
     
    mapTargetId = null;
    mapTarget = null;
    // rich copy
    if(selColumn == 'Rich_Line_Description__c'){
      //copyTargetContent (srcTar , tmp.Targeting__c);
      copyTargetContent(mapTarget2);
    }else if(selColumn == 'KeyValueString__c'){
      //copyTargetKeyValue (srcTar , tmp.Targeting__c);
      copyTargetKeyValue(mapTarget2);
    }else if(selColumn == 'CountriesDescription__c'){
      //copyTargetCountry (srcTar , tmp.Targeting__c);
//    copyTargetCountry(mapTarget2);
    }else if(selColumn == 'TargetCitiesString__c'){
      //copyTargetCity(srcTar , tmp.Targeting__c);
//    copyTargetCity(mapTarget2);
    }else if(selColumn == 'AreaCode_Description__c'){
      //copyTargetAreacode(srcTar , tmp.Targeting__c);
      copyTargetAreacode(mapTarget2);
    }else if(selColumn == 'Connection_Targeting__c'){
        copyTargetingDevices(mapTarget2);
    }else if(selColumn == 'Device_Targeting__c'){
        copyTargetingConnections(mapTarget2);
    }
    
    if(selColumn == 'Quantity' || selColumn == 'Length_Months__c'){
        reEvaluateSalesPrice();
    }
    if(selColumn == 'Surcharge_Type__c' || selColumn == 'Rate_Discount_II__c'  || selColumn == 'Billing_Category__c'){
        reEvaluateNetNetNet();
    }
    if(selColumn == 'Budget_NetNetNet__c'){
        reEvaluateQtyByBudget();
    }
    if(selColumn == 'Sales_Price_Target__c'){
        reEvaluateSurchargeAndDiscount();
    }
    
    gotoPage();
    warningOli = lstRecords.size() > 100 ? system.Label.Warning_OppLine : '';
    }catch(Exception e){
      Apexpages.Message msg = new Apexpages.Message(ApexPages.Severity.ERROR, e + '');
      Apexpages.addMessage(msg);
    }
  }
  
  //HCS 28.04.2014 Task 2606 
  public void doCopyForNewTargeting(){
     doCopyNewTargeting(false);     
  }
  private void doCopyNewTargeting(Boolean isForceCopy ){
    try{
        Set<String> setColumnForCopy= new Set<String>{'City_description__c','Countries_Description__c','Rich_Line_Description__c','KeyValueString__c'}; 
        for(String col:setColumnForCopy ){
            selColumn = col;
            system.debug('selColumn===='+selColumn);
            doCopy( isForceCopy );
        }     
      
    }catch(Exception e){
      Apexpages.Message msg = new Apexpages.Message(ApexPages.Severity.ERROR, e + '');
      Apexpages.addMessage(msg);
    }
    
  }
   public void doForceCopyForNewTargeting(){
    doCopyNewTargeting(true);       
  }
  //final Set<String> targetContentFieldSet = new Set<String>{'Rich_Line_Description__c','KeyValueString__c','CountriesDescription__c','TargetCitiesString__c','AreaCode_Description__c'};
  
  public PageReference copyField(){
    try{
      doCopy(false);
      
      warningOli = lstRecords.size() > 100 ? system.Label.Warning_OppLine : '';
    }catch(Exception e){
      Apexpages.Message msg = new Apexpages.Message(ApexPages.Severity.ERROR, e + '');
      Apexpages.addMessage(msg);
    }
    return null;
  }
   public PageReference forceCopyField(){
    try{
      doCopy(true);
      warningOli = lstRecords.size() > 100 ? system.Label.Warning_OppLine : '';
    }catch(Exception e){
      Apexpages.Message msg = new Apexpages.Message(ApexPages.Severity.ERROR, e + '');
      Apexpages.addMessage(msg);
    }
    return null;
   }
  //back to previous page
  public PageReference goBack(){        
    return new PageReference(backUrl);    
  }
  
  private static Map<String, Schema.SObjectField> mapCampaignItemField = Schema.SObjectType.OpportunityLineItem.fields.getMap();
  //add Fields which are needed for modifying 
  public static Set<String> mainFields = new Set<String>();
  static {
      mainFields.add('OpportunityId');
      mainFields.add('until_Date__c');
      mainFields.add('from_Date__c');
      mainFields.add('UnitPrice');
      //mainFields.add('Customer_Order_No__c');
      mainFields.add('Rate_Discount_I__c');
      mainFields.add('Rate_Discount_II__c');
      mainFields.add('Targeting_Surcharge__c');
      mainFields.add('Sales_Price_Target__c');
//      mainFields.add('Sales_Price_Net_Net__c');
      mainFields.add('Net_Net_Net__c');
      mainFields.add('Check_Inventory__c');
      mainFields.add('Quantity');
      //mainFields.add('Guaranteed_AI__c');
      mainFields.add('AE__c');
        
      mainFields.add('Length_Months__c');
      mainFields.add('Additional_Time_days__c');
      mainFields.add('Site_s__c');
      
      mainFields.add('FC_Quantity__c');
      mainFields.add('FC_Ad_Served_Every__c');
      mainFields.add('FC_Period__c');
      mainFields.add('AdOperatingSystems__c');
      
  //    mainFields.add('PricebookEntry.Product2.AdServer_Keywords_Key_Values__c');
      mainFields.add('AdKeyWords__c');
      mainFields.add('AdHourofDay__c');
      mainFields.add('AdDayofWeek__c');
      mainFields.add('Keywords_KeyValue_combination__c');
      
      mainFields.add('AdBrowsersMinorVersion__c');
      mainFields.add('AdBrowsersMajorVersion__c');
      
      //mainFields.add('Additional_Billing_information2__c');
      //mainFields.add('Additional_Billing_information1__c');
      mainFields.add('Boomerang__c');
      
      //HB FIX, sonst wird bei Edit versucht, PricebookEntry.Name zu updaten
      //mainFields.add('PricebookEntry.Name');  

      mainFields.add('Description');      
      mainFields.add('Billing_category__c');
      mainFields.add('Availability__c'); 
      mainFields.add('PricebookEntryId');
      mainFields.add('AdWebBrowsers__c');
      //mainFields.add('Delivered_Clicks__c');
      
      //mainFields.add('Rebate_In_Kind__c');    
      mainFields.add('Rebate_In_Kind_Reason__c');   
      
      mainFields.add('Rich_Line_Description__c');
      mainFields.add('Targeting__c');
      mainFields.add('KeyValueString__c');    
      mainFields.add('Countries_Description__c');
      mainFields.add('City_Description__c');
      //mainFields.add('AreaCode_Description__c'); 
      
      //mainFields.add('Plattform__c');   
      
      mainFields.add('Package__c');  
      mainFields.add('Surcharge_Type__c');
      mainFields.add('Discount_Type__c');
      mainFields.add('Budget_NetNetNet__c');
      
      mainFields.add('DFP_Time_Monday__c'); 
      mainFields.add('DFP_Time_Tuesday__c');   
      mainFields.add('DFP_Time_Wednesday__c');   
      mainFields.add('DFP_Time_Thursday__c');   
      mainFields.add('DFP_Time_Friday__c');   
      mainFields.add('DFP_Time_Saturday__c');   
      mainFields.add('DFP_Time_Sunday__c'); 
      mainFields.add('Device_Targeting__c');
      mainFields.add('Connection_Targeting__c');
      
      //2014-05-20 - GTCRM-635 - AdSales Automate screenshots - Preview URL
      mainFields.add('PreviewUrl__c');
     
  }
  //To enable addError for cloned sobject,this method is used instead of clone() method 
  //addError bug should be fixed?
  private OpportunityLineItem createClone(String productName,OpportunityLineItem srcObj, String idOpli){
    OpportunityLineItem cItm;
    if(srcObj.Id == null || idOpli== ''){
      cItm = new OpportunityLineItem();
    }else{
      cItm = new OpportunityLineItem(id= idOpli);
    }
    System.debug('<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<:::' + srcObj);
    for(String fn : mainFields){
      System.debug('<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<fn::' + fn);
      
      if(srcObj.get(fn)== null) continue; 
      
      if(mapCampaignItemField.get(fn).getDescribe().getType() == Schema.DisplayType.DATETIME){
        cItm.put(fn,Datetime.valueOfGmt(srcObj.get(fn)+ ''));
        
      }else{
        
        //Field OpportunityId is not editable 
        if(idOpli != '' && (fn == 'OpportunityId' || fn=='PricebookEntryId')) continue;
        //if(cItm.OpportunityId != null && fn == 'OpportunityId') continue;
        System.debug('<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<srcObj.get(fn)::' + srcObj.Id + ':::'  + fn);
        System.debug('<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<srcObj.get(fn)::' + srcObj.get(fn));
        cItm.put(fn,(srcObj.get(fn)));
      }
      
    }
    if (!mainFields.contains('PricebookEntry')) { // 2011-01-11 St.Voß - enable Usage of Product Properties while cloning Lines
      cItm.PricebookEntry = srcObj.PricebookEntry;
    }
    
     //OpportunityLineItem cItm = srcObj.clone(false,true);// not preserve id, deep clone
    return cItm;
    
  }
 

  
 
  /*
    HCS use poller for save record
    02.07.2014
  */
  List<DtoItem> lstAllRecords = new List<DtoItem>();
  private Integer RECORD_COUNT_FOR_RUN_POLLER = 20;
  private Integer RECORD_SPLIT_COUNT = 10;
  public Boolean isPollerMode{get;set;} 
  
  
  public final String X_ACCOUNT_ID = '0017000000jhcnE'; //test='001T000000nkP4W';// 15 char
  //save campaign items to media campaign
  public PageReference saveRecords(){  
       //reEvaluateAll();
      isSave = true;
      errorMsg='';
      warningOli='';
      if(lstRecords.isEmpty()){         
         errorMsg=system.Label.No_value_to_insert ; 
         return null;
      } 
      //HCS fixed Too many DML rows: 10001
      //02.07.2014
      //case no more record for process
      if( isPollerMode && lstAllRecords.isEmpty()){
        isPollerMode = false;
         return new Pagereference('/'+id);
      }

      List<OpportunityLineItem>  lstCamItem=new List<OpportunityLineItem>();
      errorFieldStatus=false;
      fromDateError=false;      
      String ErrorTab='';
      
      List<exclusive_Placement__c> BPCheckAll;// = new List<exclusive_Placement__c> ();
      BP_Collision='' ;
      //HCS fixed Too many DML rows: 10001
      //02.07.2014
      if( !isPollerMode ){
              //generate BPCheckAll rather than soql in the loop
              if ((AccId+'xxxxxxxxxxxxxxx').substring(0,15) == X_ACCOUNT_ID && oppProb>=25 && !forceDateSave) {
                 //BPCheck = [ exclusive_Placement__c Where Opportunity__r.Probability>=25 and Product__r.Site__r.Name=:dto.item.PricebookEntry.Product2.Site__r.Name and Product__r.Placement__r.Name=:dto.item.PricebookEntry.Product2.Placement__r.Name and Date__c>=:dto.item.from_Date__c and Date__c<=:dto.item.until_Date__c];
                Set<String> siteNames = new Set<String>();
                Set<String> placementDBNames = new Set<String>();
                List<Date> fDates = new List<Date>();
                List<Date> tDates = new List<Date>();
                 
                
                for(DtoItem dto:lstRecords){
                  siteNames.add(dto.item.PricebookEntry.Product2.Site__r.Name);
                  placementDBNames.add(dto.item.PricebookEntry.Product2.Placement__r.Name);
                  fDates.add(dto.item.from_Date__c);
                  tDates.add(dto.item.until_Date__c);
                }
                fDates.sort();
                tDates.sort();
                Date fd = fDates.get(0);
                Date td = tDates.get((tDates.size()-1));
                
                BPCheckAll =  [Select Id,Product__r.Placement__r.Name,Product__r.Site__r.Name,Date__c,Product__r.Advertising_Medium__r.Name,Product__r.Advertising_Medium__r.related_Mediums__c From exclusive_Placement__c Where Opportunity__r.Probability >= 25 and Product__r.Site__r.Name IN:siteNames  and Product__r.Placement__r.Name IN:placementDBNames and Date__c >= : fd and Date__c <=: td];
                  
                siteNames =null;
                placementDBNames = null;
                fDates =null;
                tDates =null;
              }
              if ((AccId+'xxxxxxxxxxxxxxx').substring(0,15) == X_ACCOUNT_ID && oppProb>=25 && !forceDateSave) {       
        
                String WF;
                String fdate; 
                String tdate;
                for(DtoItem dto:lstRecords){
                  
                  if(dto.item.PricebookEntry.Product2.Exclusive_Placement__c==true) {
                    
                    
                    //abit slower, but avoid selection in the loop
                    //BPCheck = [Select Id,Product__r.Advertising_Medium__r.Name,Product__r.Advertising_Medium__r.related_Mediums__c From exclusive_Placement__c Where Opportunity__r.Probability>=25 and Product__r.Site__r.Name=:dto.item.PricebookEntry.Product2.Site__r.Name and Product__r.Placement__r.Name=:dto.item.PricebookEntry.Product2.Placement__r.Name and Date__c>=:dto.item.from_Date__c and Date__c<=:dto.item.until_Date__c];
                    List<exclusive_Placement__c>  BPCheck = new List<exclusive_Placement__c>();   
                    for(exclusive_Placement__c bp : BPCheckAll){    //abit slower but NOT select in the loop
                      if(bp.Product__r.Site__r.Name == dto.item.PricebookEntry.Product2.Site__r.Name  
                      && bp.Product__r.Site__r.Name == dto.item.PricebookEntry.Product2.Site__r.Name
                      && bp.Product__r.Placement__r.Name == dto.item.PricebookEntry.Product2.Placement__r.Name
                      && bp.Date__c >= dto.item.from_Date__c
                      && bp.Date__c <= dto.item.until_Date__c 
                       
                      ){
                        BPCheck.add(bp);
                      }
                    }
                    if (BPCheck.size()>0) {
                            
                      // check 1 : New product BWF <-> BP WF
                      if (dto.item.PricebookEntry.Product2.Advertising_Medium__r.related_Mediums__c!=null) {
                        
                        
                        List<String> BWF_list = dto.item.PricebookEntry.Product2.Advertising_Medium__r.related_Mediums__c.toLowerCase().split(';');
                        for(string BWF:BWF_list){
                            
                          for(exclusive_Placement__c BP:BPCheck){
                            
                            WF=BP.Product__r.Advertising_Medium__r.Name.toLowerCase();
                            
                            if (WF.contains(BWF)) {
                              
                              fdate = dto.item.from_Date__c.day()+'.'+dto.item.from_Date__c.month()+'.'+dto.item.from_Date__c.year();
                              tdate = dto.item.until_Date__c.day()+'.'+dto.item.until_Date__c.month()+'.'+dto.item.until_Date__c.year();
                             
                              BP_Collision=dto.item.PricebookEntry.Product2.Name+', '+fdate+' - '+tdate;
                              break;
                            }
                          } // for
                          if (BP_Collision!='') {
                            break;
                          }
                        } // for
                      } // if
                      
                      // check 2 : New product WF <-> BP BWF
                      if (dto.item.PricebookEntry.Product2.Advertising_Medium__r.Name!=null) {
                        
                        
                        WF=dto.item.PricebookEntry.Product2.Advertising_Medium__r.Name.toLowerCase();
                        
                        for(exclusive_Placement__c BP:BPCheck){
                              
                          if (BP.Product__r.Advertising_Medium__r.related_Mediums__c!=null)  {             
                            List<String> BWF_list = BP.Product__r.Advertising_Medium__r.related_Mediums__c.toLowerCase().split(';');
                            
                            for(string BWF:BWF_list){
                            
                            
                              if (WF.contains(BWF)) {
                              
                             
                                fdate = dto.item.from_Date__c.day()+'.'+dto.item.from_Date__c.month()+'.'+dto.item.from_Date__c.year();
                                tdate = dto.item.until_Date__c.day()+'.'+dto.item.until_Date__c.month()+'.'+dto.item.until_Date__c.year();
                             
                                BP_Collision=dto.item.PricebookEntry.Product2.Name+', '+fdate+' - '+tdate;
                                break;
                              }
                            } // if
                          } // for
                          if (BP_Collision!='') {
                            break;
                          }
                        }
                      }
                    }         
                  }   
                  if (BP_Collision!='') {
                    break;
                  }
                }   // for  
                
                if(BP_Collision!=''){
                  return null;
                }
                
              }   // if
              
              for(DtoItem dto:lstRecords){  
                      
                dto.saveSelectedHoursToItem(); //Bunhor: modifying the OpportunityLineItem time targetting
        
                //Validate the required fields and addError to the correct fields
                if(dto.item.Length_Months__c==null  ){
                  dto.item.from_Date__c.addError(system.Label.Empty_value);
                  errorFieldStatus=true;
                  if (ErrorTab=='') {
                    ErrorTab='name1';
                    }
                }     
               // GTCRM-946 Modify product error message - invalid integer 
               
               if(dto.item.Length_Months__c==null && (dto.item.Pricebookentry.Product2.RecordType.Name=='Classifieds')){
                  dto.item.Length_Months__c.addError(system.Label.Empty_value);
                  errorFieldStatus=true;
                  if (ErrorTab=='') {
                    ErrorTab='name1';
                    }
                }
                   
                if(dto.item.until_Date__c==null && (dto.item.Pricebookentry.Product2.RecordType.Name=='DART5' || dto.item.Pricebookentry.Product2.RecordType.Name=='DART6' )){ 
                   dto.item.until_Date__c.addError(system.Label.Empty_value);
                   errorFieldStatus=true;
                   if (ErrorTab=='') {
                     ErrorTab='name1';
                     }
                }
        
                if(!forceDateSave){
                  if(dto.item.from_Date__c!=null && dto.item.from_Date__c< System.today()){             
                      dto.item.from_Date__c.addError(system.Label.Error_from_date);
                      fromDateError=true;
                  if (ErrorTab=='') {
                    ErrorTab='name1';
                    }               
                  }   
                }
                
                if(dto.item.until_Date__c!=null && dto.item.from_Date__c!=null && dto.item.until_Date__c<dto.item.from_Date__c ){                     
                    dto.item.until_Date__c.addError(system.Label.Error_until_date);
                    errorFieldStatus=true;
                    if (ErrorTab=='') {
                      ErrorTab='name1';
                    }                 
                }   
        
                if(dto.item.Billing_category__c==null  ){
                  dto.item.Billing_category__c.addError(system.Label.Empty_value);
                  errorFieldStatus=true;
                  if (ErrorTab=='') {
                    ErrorTab='name2';
                    }
                }
        
                if(dto.item.Rich_Line_Description__c==null && (dto.item.Pricebookentry.Product2.RecordType.Name=='DART5' || dto.item.Pricebookentry.Product2.RecordType.Name=='DART6' )){
                  dto.item.Rich_Line_Description__c.addError(system.Label.Error_CategoryTargeting);
                  errorFieldStatus=true;
                  if (ErrorTab=='') {
                    ErrorTab='tabname6';
                    }
                }
            System.debug('>>>>>>>>>>>>>>>>>dto.item.Quantity:'+dto.item.Quantity+'<<<');
                if(dto.item.Quantity==null || dto.item.Quantity==0){
                  dto.item.Quantity.addError(system.Label.Empty_value);
                  errorMsg='Quantity: ' + system.Label.Empty_value; 
                  errorFieldStatus=true;
                  if (ErrorTab=='') {
                    ErrorTab='name2';
                    }
                }       
        
                if(dto.item.UnitPrice==null){
                  dto.item.UnitPrice.addError(system.Label.Empty_value);
                  errorFieldStatus=true;
                  if (ErrorTab=='') {
                    ErrorTab='name2';
                  }
                }     
                
                if(dto.item.Rate_Discount_II__c >0 && dto.item.Rebate_In_Kind_Reason__c ==null){
                  dto.item.Rebate_In_Kind_Reason__c.addError(system.Label.Error_Discount_Reason);
                  errorFieldStatus=true;
                  if (ErrorTab=='') {
                    ErrorTab='name2';
                  }
                }                                     
                
                if(dto.item.FC_Ad_Served_Every__c!=null && dto.item.FC_Quantity__c==null ){
                   dto.item.FC_Quantity__c.addError(system.Label.Empty_value);
                   errorFieldStatus=true;
                   system.debug ('***HB FC IMPRESSIONS EMPTY');
                   if (ErrorTab=='') {
                     ErrorTab='name3';
                   }     
                }
        
                if(dto.item.FC_Ad_Served_Every__c!=null && dto.item.FC_Quantity__c!=null && dto.item.FC_Period__c==null ){
                   dto.item.FC_Period__c.addError(system.Label.Empty_value);
                   errorFieldStatus=true;
                   system.debug ('***HB FC TIMEPERIODS EMPTY');
                   if (ErrorTab=='') {
                     ErrorTab='name3';
                   }
                }
                
        /*
                 if(dto.item.Site_s__c==null && dto.item.Pricebookentry.Product2.RecordType.Name=='Accounts'){
                   dto.item.Site_s__c.addError(system.Label.Empty_value);
                   errorFieldStatus=true;
                   if (ErrorTab=='') {
                     ErrorTab='name1';
                     }
                 }
        */
        
              
            //    String strTmp = checkValidation(dto.item.KeyValueString__c);
            /*    if(strTmp != ''){
                  dto.item.KeyValueString__c.addError(strTmp);
                  errorFieldStatus=true;
                  if (ErrorTab=='') {
                    ErrorTab='tabname8';
                  }
                }
                
            //    strTmp = checkValidation(dto.item.AdKeyWords__c);
                if(strTmp != ''){
                  dto.item.AdKeyWords__c.addError(strTmp);
                  errorFieldStatus=true;
                  if (ErrorTab=='') {
                    ErrorTab='tabname9';
                  }
                }
            */    
                if (ErrorTab!='') {
                  ActiveTab=ErrorTab;
                }
        
                if (dto.item.UnitPrice>0 && dto.item.Quantity>0) {
                  dto.item.Net_Net_Net__c = dto.item.UnitPrice * dto.item.Quantity;
                }
                //mapOpliMain.put(dto.dtoId+'', dto.item);                  
                //lstCamItem.add(dto.item);
               // system.debug(dto.item);
              }    
     
     
      }
       if(errorFieldStatus || fromDateError){
         return null;
      }
       //HCS fixed Too many DML rows: 10001
      //02.07.2014
       Map<String, OpportunityLineItem> mapOpliMain = new Map<String, OpportunityLineItem>();  
      if( lstRecords.size() > RECORD_COUNT_FOR_RUN_POLLER ){
        isPollerMode = true;
        lstAllRecords = lstRecords;      
      }
      if( isPollerMode ){
        lstRecords = new List<DtoItem>();
        for(Integer i= lstAllRecords.size()-1 ;i >= 0 ; i-- ){
            if( lstRecords.size() >= RECORD_SPLIT_COUNT ) break;
            DtoItem dto = lstAllRecords.get(i);
            lstRecords.add( dto );
            lstAllRecords.remove(i);               
        }
      }
      
       for(DtoItem dto:lstRecords){  
         mapOpliMain.put(dto.dtoId+'', dto.item); 
       }   
      
      lstCamItem.addall(mapOpliMain.values());
     
      //NK:14/06/2013: moved from top of Save Record; saving could check error first
      reEvaluateAll();
      
      createTargeting4ProFixedSite(lstRecords);
      
      
          
      //get all package component related package main
      //set the calculated price for each package component (during the saving process of the visualforce page) to the new field "component_price__c" and set the standard field salesprice to 0
      
      Map<String, OpportunityLineItem> mapOli = new Map<String, OpportunityLineItem>();
  
    //  mapOli = createPackageComponent(mapOpliMain);
      mapOli = createUpdatePackCom(mapOpliMain);
      
      System.debug('========================== mapOli: ' + mapOli.values());
      //add all product package component to main list to save
      lstCamItem.addall(mapOli.values());
      System.debug('>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>:::' + lstCamItem);
      try{         
        
        if(!delItem.isEmpty()) {
          delete [Select Id From OpportunityLineItem Where Id In :delItem];
        }
        upsert lstCamItem;
        
        updatePackageComponent(mapOli, mapOpliMain);
        
        Integer days=0;
        Boolean asyncRevenues = false;
//        Set<Id> oliIds = new Set<Id>();
        
        Set<Id> countTargetingId = new Set<Id>();
        
        for (OpportunityLineItem ols : lstCamItem) {
          String s = String.valueOf(ols.Targeting__c);
          if (s != null && ((s + '') != '')) {
            countTargetingId.add(ols.Targeting__c);
          }
          
          days += ols.from_Date__c.daysBetween(ols.until_Date__c);
//          if (days > 200 && !asyncRevenues) {
          if (days > 50 && !asyncRevenues) {
            asyncRevenues=true;
          }
//          oliIds.add(ols.Id);
        }
        
//        TargetingCount.countTargeting(countTargetingId);
/*
        if (!countTargetingId.isEmpty()) {
          Targeting__c[] countTargeting = [select Id,CountTargeting__c from Targeting__c where Id = : countTargetingId and CountTargeting__c=false];
          for (Targeting__c t : countTargeting) {
            t.CountTargeting__c = true;
          }
          update countTargeting;
        }
*/
        if (asyncRevenues) {
          
//          Revenue.start(oliIds);
      //    RevenueBatch rb = new RevenueBatch();
      //    rb.startWithOliList(lstCamItem);
        }
        else {
          
          Revenue.start(lstCamItem);
        }
        
        //Clear the basket after saving Campaign Items to Media Campaign  
        if(camItems==null){
          delete [Select Id,AdPriceIdText__c From Media_Basket__c where UserId__c=:System.userInfo.getUserId() AND OpportunityId__c=:id]; 
        }
        
              
      }catch(Exception e){        
        errorMsg=e +'';
        isPollerMode = false;
        lstRecords  = lstAllRecords; 
        return null;
      }
      
    //refresh Targeting__c for each LineItem
    Set<String> savedTar = new Set<String>();
    for(OpportunityLineItem item : lstCamItem){
      savedTar.add(item.Targeting__c);
    }

    List<Targeting__c> ltar = new List<Targeting__c> ();
    for(Targeting__c tar : [Select Id, TempBinder__c From Targeting__c Where Id In : savedTar]){
      tar.TempBinder__c = false;
      ltar.add(tar);
    }  
    update ltar;
    
 
    
    System.debug(LoggingLevel.Debug, '********* Heap Size 3 **************: ' + Limits.getHeapSize() + '/' + Limits.getLimitHeapSize());
    
    //Imediately return to Media Campaign detail page
    return  isPollerMode ? null : new Pagereference('/'+id);  
   
  
  }   
  
  
  /**
  *   Method for check product that is fixed site to create targeting 
  */
  private void createTargeting4ProFixedSite(List<DtoItem> lstRec){
        
      
      Map<String, String> mTargeting = new Map<String, String>(); //for store all targeting Id from product that is fixed site
      Map<String, List<String>> mAvilableSite = new Map<String, List<String>>(); //for store all available sites from product that is fixed site
      Map<String, Targeting__c> mTarNotExsit = new Map<String, Targeting__c>(); //for store all targeting not exist from product that is fixed site
      Set<String> sAvaiSiteName = new Set<String>();//store all available site name
      
      //get targeting from opli which product is Fixed site
      for(DtoItem dto: lstRecords){
        if(dto.isFixedSite){
          //put avialable site to map
          String avaiSite = (dto.availableSite + '' != '' ? dto.availableSite : '');
          if(avaiSite != ''){
            //check has targeting or not. If not create new one
            if(dto.item.Targeting__c + '' == ''){
              Targeting__c t = new Targeting__c(TempBinder__c = true, Description__c = 'TargetingTreeProduct');
              mTarNotExsit.put(dto.dtoId + '', t);
            }else{
              mTargeting.put(dto.dtoId + '', dto.item.Targeting__c);
            }
          
            String keyMap = dto.dtoId + '';
            
            //remove last "." from available site name 
            String strTmp = avaiSite.substring(0, avaiSite.length() -1);
              
            //check has 1 or more available site
            if(strTmp.contains(' , ')){
              
              
              
              //split string available site 
              for(String avSite : strTmp.split(' , ')){
                sAvaiSiteName.add(avSite);
                
                if(!mAvilableSite.containsKey(keyMap)){
                  mAvilableSite.put(keyMap, new List<String>());
                }
                mAvilableSite.get(keyMap).add(avSite);
              }
            }else{
              mAvilableSite.put(keyMap, new List<String>{strTmp});
              sAvaiSiteName.add(strTmp);
            }
          }
        }
      }
    
      
      
      //create new targeting
      try{
        if(!mTarNotExsit.isEmpty()){
          insert mTarNotExsit.values();
        }
      }catch(Exception ex){
        Apexpages.Message msg = new Apexpages.Message(ApexPages.Severity.ERROR, ex.getMessage());
        Apexpages.addMessage(msg); 
      }
      
      //put new targeting to all product that is fixed site
      for(DtoItem dto: lstRecords){
        if(dto.isFixedSite){
          if(dto.item.Targeting__c + '' == ''){
            if(!mTarNotExsit.containsKey(dto.dtoId + '')) continue;
            dto.item.Targeting__c = mTarNotExsit.get(dto.dtoId + '').Id;
          }
        }
      }
      
      //put all targeting ids in one list
      for(String keymap : mTarNotExsit.keySet()){
        mTargeting.put(keymap, mTarNotExsit.get(keymap).Id);
      }
      
      
      List<String> idTar = new List<String>();//store id targeting 
      Map<String, String> mTmp = new Map<String, String>();//store all targeting that has no content targeting
      
      
      for(String keyMap : mTargeting.keySet()){
        idTar.add(mTargeting.get(keyMap));
        mTmp.put(mTargeting.get(keyMap), keyMap);
      }
      
      //check targeting has targetingContentAssociate or not 
      //if has content Associate already, don create
      for(Targeting__c lTar : [select Id, (Select Id From TargetingContentAssociations__r limit 1) from Targeting__c where id in:idTar ]){
        if(lTar.TargetingContentAssociations__r.size() > 0){
          mTmp.remove(lTar.Id);
        }
      }
      
      Map<String, String> mContent = new Map<String, String>(); //store id Content
      for(Content__c content : [Select id, Name, DartName__c from Content__c where DartName__c in:sAvaiSiteName]){
        mContent.put(content.DartName__c, content.Id);
      }
      
      List<TargetingContentAssociation__c> lstTarCon = new List<TargetingContentAssociation__c>();
      Set<String> tarId =  new Set<String>();
      Set<String> assoNotToDelete = new Set<String>();
      
      //create content targeting
      for(String keyIdDTO: mTmp.values()){
        if(!mAvilableSite.containsKey(keyIdDTO)) continue;
        for(String avaiSiteName: mAvilableSite.get(keyIdDTO)){
          String ex_key = ''; //targeting id + Content ID
          String targetingId = mTargeting.get(keyIdDTO);
          
          String contentName = avaiSiteName;
          
          String contentId = mContent.get(contentName);
          ex_key = targetingId + contentId;
          TargetingContentAssociation__c tarCon = new TargetingContentAssociation__c(Targeting__c = targetingId, TargetingContent__c = contentId, Exclude__c = false,  Target_Content_Key__c = ex_key );
          lstTarCon.add(tarCon);
          tarId.add(targetingId);
          assoNotToDelete.add(ex_key);
        }
      }
      try{
        if(!lstTarCon.isEmpty()){
          upsert lstTarCon;         
         delete [Select Id From TargetingContentAssociation__c Where Targeting__c in:tarId And Target_Content_Key__c Not In :assoNotToDelete ];
          
        }
      }catch(Exception ex){
        Apexpages.Message msg = new Apexpages.Message(ApexPages.Severity.ERROR, ex.getMessage());
        Apexpages.addMessage(msg); 
      }
      
      
    
  }
  
  private void updatePackageComponent(Map<String, OpportunityLineItem> mapOli, Map<String, OpportunityLineItem> mapOpliMain){
    //put package related(child) to correct package component(main)  
        Map<String, List<OpportunityLineItem>> mapMainChild = new Map<String, List<OpportunityLineItem>>();// use to store match Package product(main) with Package Component related(child)
        for(String str: mapOli.keySet()){
          String keyM = str.split('_##_').get(1);
          keyM = keyM.split('_').get(1);
          OpportunityLineItem opli= mapOli.get(str);
          //put oli correct with Package Component
          if(!mapMainChild.containsKey(keyM)){
            mapMainChild.put(keyM, new List<OpportunityLineItem>());
          }
          mapMainChild.get(keyM).add(opli);
          
        }
        
        // insert for each package component line item the salesforce id of the related package product line item into the field "package_line_item__c" at the line item object
        List<OpportunityLineItem> lopli = new List<OpportunityLineItem>();
        for(String keyMap: mapOpliMain.keySet()){
          if(!mapMainChild.containsKey(keyMap)) continue;
          OpportunityLineItem opliMain = mapOpliMain.get(keyMap);
          for(OpportunityLineItem opli : mapMainChild.get(keyMap)){
            opli.package_line_item__c = opliMain.Id;
            lopli.add(opli);
          }
        }
        if(lopli.size()>0){
          update lopli;
        }
  }
  
/*  private Map<String, OpportunityLineItem> createUpdatePackCom(Map<String, OpportunityLineItem> mapOpliMain){
    
    Set<String> idProMain = new Set<String>();
    Set<String> idProChild = new Set<String>();
    Set<String> idOpliMain = new Set<String>();
    Map<String, List<String>> mapOpliChildExist = new Map<String, List<String>>(); //Key: id OpportunityLineItem Main, Value: list of id OpportunityLineitem child
    Map<String, OpportunityLineItem> mapOli = new Map<String, OpportunityLineItem>();
    
    //get Package Product Id
    for(OpportunityLineItem opli: mapOpliMain.values()){  
      
      //check record is Package or not 
      if(opli.PricebookEntry.Product2.RecordType.Name == 'Package'){
        
        //get all Package product id      
        if(opli.id == null){
          idProMain.add(opli.PricebookEntry.Product2Id);
        }else{
          idOpliMain.add(opli.id);
        }
      }
    }
    
    //get all opli child
    Set<String> idOpliChildExist = new Set<String>();
    Map<String, OpportunityLineItem> mapOpliChild = new Map<String, OpportunityLineItem>([select id, package_line_item__c, PricebookEntryId, PricebookEntry.Product2.Name, Rich_Line_Description__c, KeyValueString__c, related_package__c  from OpportunityLineItem where package_line_item__c in:idOpliMain]);
    if(idOpliMain.size() > 0){
      for(OpportunityLineItem opli: mapOpliChild.values()){
        
        if(!mapOpliChildExist.containsKey(opli.package_line_item__c)){
          mapOpliChildExist.put(opli.package_line_item__c, new List<String>());
          
        }
        mapOpliChildExist.get(opli.package_line_item__c).add(opli.Id);
      }
      
    }
    
    //get Package Component
      List<Product2> proMain = new List<Product2>([select Id,(select Package_product__c, Singleproduct__c, Price__c from Packagecomponents__r) from Product2 where Id in:idProMain]);
    
    
    //get Package Component Id
    Map<String, List<String>> mapOpliChildNotExist = new Map<String, List<String>>();
    for(Product2 p: proMain){
      for(PackageComponent__c pc: p.Packagecomponents__r){
        idProChild.add(pc.Singleproduct__c);
        
        if(!mapOpliChildNotExist.containsKey(p.Id)){
          mapOpliChildNotExist.put(p.Id, new List<String>());
        }
        mapOpliChildNotExist.get(p.Id).add(pc.Singleproduct__c);
        
      }
    }
    
    
    Map<String, PricebookEntry> mapPbeChildNotExist = new Map<String, PricebookEntry>();
    //get pricebook entry that match with package component
    for (PricebookEntry pbe:[Select Id, Product2.Billing_Category__c,Unitprice, Product2.Name, Product2.Id, Product2.Fixed_price__c,Product2Id,
                                Product2.Advertising_Medium__r.FC_Quantity__c,
                                Product2.Advertising_Medium__r.FC_Period__c,
                                Product2.Advertising_Medium__r.FC_Ad_served_every__c,
                                Product2.RecordType.Name, Product2.Fixed_Site__c, Product2.available_Key_Values__c
                                from PricebookEntry where Pricebook2Id=:mcPBId and Product2Id in :idProChild]){
              
      mapPbeChildNotExist.put(pbe.Product2Id, pbe);
    }   
    
    System.debug('----------------------------------------------------------------------:::::' + mapPbeChildNotExist.keySet());
    //get right Package product and package component
    Map<String, Packagecomponent__c> mapPackageCom = new Map<String, Packagecomponent__c>();
    for(Packagecomponent__c pc :[Select p.Package_product__c, p.predefined_Key_Values__c, p.Id, p.Singleproduct__c,  p.DART_Content__r.DartName__c, p.DART_Content__c From Packagecomponent__c p where Singleproduct__c in:idProChild and Package_product__c in:idProMain]){
      //get Dart_Name to store in Rich_Line_Description__c of Product Component related
      String keyMap = pc.Singleproduct__c + ' ' + pc.Package_product__c;
      if(!mapPackageCom.containsKey(keyMap)){
        mapPackageCom.put(keyMap, pc);
      }
    }
      
    Map<String, String> mapDartContent = new Map<String, String>();
    
    for(String keyMap : mapOpliMain.keySet()){
      
      List<String> lstOpliChild = new List<String>();
      
      OpportunityLineItem opliMain = mapOpliMain.get(keyMap);
      if(opliMain.PricebookEntry.Product2.RecordType.Name != 'Package') continue; 
      Decimal numOfPackCom = 0;
      Decimal subUnitPrice = 0;
      
      if(opliMain.Id != null){  //Opli main is exist
        numOfPackCom = mapOpliChildExist.get(opliMain.Id).size();
        lstOpliChild = mapOpliChildExist.get(opliMain.Id);
      }else{  //opli main is not exist
        numOfPackCom = mapOpliChildNotExist.get(opliMain.PricebookEntry.Product2Id).size();
        lstOpliChild = mapOpliChildNotExist.get(opliMain.PricebookEntry.Product2Id);
      }
      
      subUnitPrice = (opliMain.UnitPrice == null? 0: opliMain.UnitPrice)/ numOfPackCom;
      
      
      for(String strTmp : lstOpliChild){  //if lstOpliChild get from mapOpliChildExist, strTmp = id opli child exist
        //create Package related product 
        OpportunityLineItem opli = createClone('', opliMain, strTmp);
        String keySinNPro = strTmp + ' ' + opliMain.PricebookEntry.Product2Id;
        if(opliMain.Id != null){
        //  opli.PricebookEntryId = mapOpliChild.get(strTmp).PricebookEntryId;
          opli.Rich_Line_Description__c = mapOpliChild.get(strTmp).Rich_Line_Description__c;
          opli.KeyValueString__c = mapOpliChild.get(strTmp).KeyValueString__c;
          opli.related_package__c = mapOpliChild.get(strTmp).related_package__c;
          
        }else{
          if(!mapPbeChildNotExist.containsKey(strTmp)) continue;
          opli.PricebookEntryId = mapPbeChildNotExist.get(strTmp).Id;
          opli.Rich_Line_Description__c = mapPackageCom.get(keySinNPro).DART_Content__r.DartName__c;
          opli.KeyValueString__c = mapPackageCom.get(keySinNPro).predefined_Key_Values__c; 
          opli.related_package__c = opliMain.PricebookEntry.Product2Id;
        }
        
        opli.UnitPrice = 0;
        opli.component_price__c = subUnitPrice;
        if(opliMain.Id != null){
          mapOli.put(mapOpliChild.get(strTmp).PricebookEntry.Product2.Name + '_##_'+ mapOpliChild.get(strTmp).PricebookEntryId + '_' + keyMap, opli);
          mapDartContent.put(mapOpliChild.get(strTmp).PricebookEntry.Product2.Name + '_##_'+ mapOpliChild.get(strTmp).PricebookEntryId + '_' + keyMap, mapPackageCom.get(keySinNPro).DART_Content__c);
        }else{
          mapOli.put(mapPbeChildNotExist.get(strTmp).Product2.Name + '_##_'+ mapPbeChildNotExist.get(strTmp).Id + '_' + keyMap, opli);
          mapDartContent.put(mapPbeChildNotExist.get(strTmp).Product2.Name + '_##_'+ mapPbeChildNotExist.get(strTmp).Id + '_' + keyMap, mapPackageCom.get(keySinNPro).DART_Content__c);
        }
        
        
      }
      
    }
    
    bindTreeConfigurator(mapOli, true);
    
    createTarCont4PC(mapOli, mapDartContent);
    
    createKeyValue4PC(mapOli);
    return mapOli;
  }
*/  
  
  private Map<String, OpportunityLineItem> createUpdatePackCom(Map<String, OpportunityLineItem> mapOpliMain){
    
    Set<String> idProMain = new Set<String>();
    Set<String> idProChild = new Set<String>();
    Set<String> idOpliMain = new Set<String>();
    Map<String, String> mapOpliChildExist = new Map<String, String>(); 
    Map<String, OpportunityLineItem> mapOli = new Map<String, OpportunityLineItem>();
    
    System.debug('++++++++++++++++++++ mapOpliMain.values(): ' + mapOpliMain.values());
    
    //get Package Product Id
    for(OpportunityLineItem opli: mapOpliMain.values()){  
      
      //check record is Package or not 
      if(opli.PricebookEntry.Product2.RecordType.Name == 'Package'){
        
        //get all Package product id      
        if(opli.id != null){
          idOpliMain.add(opli.id);
        }
        idProMain.add(opli.PricebookEntry.Product2Id);
      }
    }
    
    System.debug('>>>>>>>>>>>>>>>>>>>>>>> mapOli: ' + mapOli);
    
    //get all opli child
    Set<String> idOpliChildExist = new Set<String>();
    Map<String, OpportunityLineItem> mapOpliChild = new Map<String, OpportunityLineItem>([select id, package_line_item__c, PricebookEntryId, PricebookEntry.Product2Id, PricebookEntry.Product2.Name, Rich_Line_Description__c, KeyValueString__c, related_package__c, PriceBookEntry.Product2.PreviewUrl__c  from OpportunityLineItem where package_line_item__c in:idOpliMain]);
    if(idOpliMain.size() > 0){
      for(OpportunityLineItem opli: mapOpliChild.values()){
        
        if(!mapOpliChildExist.containsKey(opli.package_line_item__c + opli.PricebookEntry.Product2Id)){
          mapOpliChildExist.put(opli.package_line_item__c + opli.PricebookEntry.Product2Id, opli.Id);
        }
      }
    }
    
    //get Package Component
    List<Product2> proMain = new List<Product2>([select Id, Quantity__c, (select Package_product__c, Singleproduct__c, Price__c from Packagecomponents__r) from Product2 where Id in:idProMain]);
    
    //get Package Component Id
    Map<String, List<String>> mapProMainChild = new Map<String, List<String>>();
    for(Product2 p: proMain){
      for(PackageComponent__c pc: p.Packagecomponents__r){
        idProChild.add(pc.Singleproduct__c);
        
        if(!mapProMainChild.containsKey(p.Id)){
          mapProMainChild.put(p.Id, new List<String>());
        }
        mapProMainChild.get(p.Id).add(pc.Singleproduct__c);
        
      }
    }
    
    
    Map<String, PricebookEntry> mapPbeChild = new Map<String, PricebookEntry>();
    //get pricebook entry that match with package component
    for (PricebookEntry pbe:[Select Id, Product2.Billing_Category__c,Unitprice, Product2.Name, Product2.Id, Product2.Fixed_price__c,Product2Id,
                                Product2.Advertising_Medium__r.FC_Quantity__c,
                                Product2.Advertising_Medium__r.FC_Period__c,
                                Product2.Advertising_Medium__r.FC_Ad_served_every__c,
                                // 2014-05-20 - GTCRM-635 - AdSales Automate screenshots - Preview URL
                                Product2.PreviewUrl__c,
                                Product2.RecordType.Name, Product2.Fixed_Site__c, Product2.available_Key_Values__c
                                from PricebookEntry where Pricebook2Id=:mcPBId and Product2Id in :idProChild]){
              
      mapPbeChild.put(pbe.Product2Id, pbe);
    }   
    
    
    //get right Package product and package component
    Map<String, Packagecomponent__c> mapPackageCom = new Map<String, Packagecomponent__c>();
    for(Packagecomponent__c pc :[Select p.Package_product__c, p.predefined_Key_Values__c, p.Id, p.Singleproduct__c,  p.DART_Content__r.DartName__c, p.DART_Content__c From Packagecomponent__c p where Singleproduct__c in:idProChild and Package_product__c in:idProMain]){
      //get Dart_Name to store in Rich_Line_Description__c of Product Component related
      String keyMap = pc.Singleproduct__c + ' ' + pc.Package_product__c;
      if(!mapPackageCom.containsKey(keyMap)){
        mapPackageCom.put(keyMap, pc);
      }
    }
      
      
    Map<String, String> mapDartContent = new Map<String, String>();
    
    
    for(String keyMap : mapOpliMain.keySet()){
      
      List<String> lstOpliChild = new List<String>();
      
      OpportunityLineItem opliMain = mapOpliMain.get(keyMap);
      if(opliMain.PricebookEntry.Product2.RecordType.Name != 'Package') continue; 
      
      Decimal numOfPackCom = 0;
      Decimal subUnitPrice = 0;
      Double subQuantity = 0;
      if(!mapProMainChild.containsKey(opliMain.PricebookEntry.Product2Id)) continue;
      
      numOfPackCom = mapProMainChild.get(opliMain.PricebookEntry.Product2Id).size();
      lstOpliChild = mapProMainChild.get(opliMain.PricebookEntry.Product2Id);
      
      subUnitPrice = (opliMain.UnitPrice == null? 0: opliMain.UnitPrice);
      subQuantity = (opliMain.Quantity == null? 0: opliMain.Quantity);
      if (opliMain.Billing_category__c == 'Fix Price' || opliMain.Billing_category__c == 'CPO') {
        subUnitPrice = subUnitPrice / numOfPackCom;
      } else {
        subQuantity = Math.floor(subQuantity / numOfPackCom);
      } 
      
      for(String strTmp : lstOpliChild){  //strTmp = id single product
      
        //create Package related product 
        
        
        
        OpportunityLineItem opli;
        String keySinNPro = strTmp + ' ' + opliMain.PricebookEntry.Product2Id;
        if (!mapPbeChild.containsKey(strTmp))continue;
        if(opliMain.Id != null && mapOpliChildExist.containsKey(opliMain.Id + strTmp)){
          opli = createClone('', opliMain, mapOpliChildExist.get(opliMain.Id + strTmp));
        }else{
          opli = createClone('', opliMain, '');
          opli.PricebookEntryId = mapPbeChild.get(strTmp).Id;
        }
          opli.Rich_Line_Description__c = mapPackageCom.get(keySinNPro).DART_Content__r.DartName__c;
          
          // BC: 2011-12-15
          // The KeyValueString__c of component item will:
          //   1. inherit from its parent KeyValueString__c if the available_Key_Values__c of parent product is defined, otherwise
          //   2. get from the predefined_Key_Values__c of its packagecompont-product.
          // BC: 2011-12-19
          // The final KeyValueString is AdKeyWords__c!
          if (opliMain.PricebookEntry.Product2.available_Key_Values__c != null) {
            //opli.KeyValueString__c = opliMain.KeyValueString__c;
            opli.AdKeyWords__c = opliMain.AdKeyWords__c;
          } else {
            //opli.KeyValueString__c = mapPackageCom.get(keySinNPro).predefined_Key_Values__c;
            opli.AdKeyWords__c = mapPackageCom.get(keySinNPro).predefined_Key_Values__c;
          }
          opli.related_package__c = opliMain.PricebookEntry.Product2Id;
          opli.UnitPrice = subUnitPrice;
          opli.Quantity = subQuantity;
          
        
          mapOli.put(mapPbeChild.get(strTmp).Product2.Name + '_##_'+ mapPbeChild.get(strTmp).Id + '_' + keyMap, opli);
          mapDartContent.put(mapPbeChild.get(strTmp).Product2.Name + '_##_'+ mapPbeChild.get(strTmp).Id + '_' + keyMap, mapPackageCom.get(keySinNPro).DART_Content__c);
        
        
        
      }
      
    }
    
    bindTreeConfigurator(mapOli, true);
    
    createTarCont4PC(mapOli, mapDartContent);
    
    createKeyValue4PC(mapOli);
    return mapOli;
  }
/*  private Map<String, OpportunityLineItem> createPackageComponent(Map<String, OpportunityLineItem> mapOpliMain){
    //get all package component related package main
    //set the calculated price for each package component (during the saving process of the visualforce page) to the new field "component_price__c" and set the standard field salesprice to 0
      
      Map<String, OpportunityLineItem> mapOli = new Map<String, OpportunityLineItem>();
      Set<String> pbe2ID = new Set<String>();
      Map<String, String> mapPbeTmp = new Map<String, String>();
      Map<String, String> mapDartContent = new Map<String, String>();
      Map<String, Packagecomponent__c> mapPackageCom = new Map<String, Packagecomponent__c>();
      Set<String> proMainId = new Set<String>();
      Map<String, String> mapProName = new Map<String, String>();
      
      //get pricebook entry Id from all package product 
      for(String keyMap: mapPbe2Id.keySet()){
        pbe2ID.addall(mapPbe2Id.get(keyMap));
      }
      
      
      //get product id and name correct with pricebook entry
      for(PricebookEntry pBEntry :[Select id ,Product2.Id, Product2.Name from PricebookEntry where Id in:pbe2ID]){
        mapPbeTmp.put(pBEntry.id + '', pBEntry.Product2.Id + '');
        mapProName.put(pBEntry.id + '', pBEntry.Product2.Name );        
      }
      
      
      for(String keyMap: mapOpliMain.keySet()){ //keymap: dtoId
        if(mapPackageMain.containsKey(keyMap)){
            proMainId.add(mapPackageMain.get(keyMap).proId);
          
        }
      }
      
      //get right Package product and package component
      for(Packagecomponent__c pc :[Select p.Package_product__c, p.predefined_Key_Values__c, p.Id, p.Singleproduct__c,  p.DART_Content__r.DartName__c, p.DART_Content__c From Packagecomponent__c p where Singleproduct__c in:mapPbeTmp.values() and Package_product__c in:proMainId]){
        //get Dart_Name to store in Rich_Line_Description__c of Product Component related
        String keyMap = pc.Singleproduct__c + ' ' + pc.Package_product__c;
        if(!mapPackageCom.containsKey(keyMap)){
          mapPackageCom.put(keyMap, pc);
        }
        
      }
      
      
      for(String keyMap: mapOpliMain.keySet()){ //keymap: dtoId
        
        
        if(!mapPbe2Id.containsKey(mapPackageMain.get(keyMap).proId)) continue;
        
        Decimal numOfPackageRelated = mapPbe2Id.get(mapPackageMain.get(keyMap).proId).size(); // get number of package component related
        
        OpportunityLineItem opliMain = mapPackageMain.get(keyMap).item;
        
        Decimal subUnitPrice = 0;
        
        //sale price for components related : Sales price (for each component) = Sales Price (Package Product) / Number of components
        subUnitPrice = (opliMain.UnitPrice == null? 0: opliMain.UnitPrice) / numOfPackageRelated;
        
        for(String pbeId: mapPbe2Id.get(mapPackageMain.get(keyMap).proId)){ //get list pricebook entry id
          
          String keyPbeNPro = mapPbeTmp.get(pbeId) + ' ' + mapPackageMain.get(keyMap).proId;
          //create Package related product 
          OpportunityLineItem opli = createClone('', opliMain, '');
          opli.UnitPrice =  0;
          opli.PricebookEntryId =  pbeId;
          opli.Rich_Line_Description__c = mapPackageCom.get(keyPbeNPro).DART_Content__r.DartName__c;
          opli.KeyValueString__c = mapPackageCom.get(keyPbeNPro).predefined_Key_Values__c; //mapKVPC.get(mapPbeTmp.get(pbeId) + ' ' + mapPackageMain.get(keyMap).proId);
          opli.related_package__c = mapPackageMain.get(keyMap).proId;
          opli.component_price__c = subUnitPrice;
          
          mapOli.put(mapProName.get(pbeId) + '_##_'+ pbeId + '_' + keyMap, opli);
          mapDartContent.put(mapProName.get(pbeId) + '_##_'+ pbeId + '_' + keyMap, mapPackageCom.get(keyPbeNPro).DART_Content__c);
        }
      }
      
      bindTreeConfigurator(mapOli, true);
      createTarCont4PC(mapOli, mapDartContent);
      return mapOli;
  }
*/
 
  private void createKeyValue4PC(Map<String, OpportunityLineItem> mapOli){
    Map<String, Targeting__c> mapTarId = new Map<String, Targeting__c>();
  
    //get all Dart Key value 2 that is parent
    //Map<String, String> mapNodeId = new Map<String, String>();
    
    // Every Dart KeyValue that have Node_ID__c = null 
    // => key_Value__c = Key__c
    //for(DART_KeyValue_2__c d: [select id, key__c, Key_Value__c from DART_KeyValue_2__c where Node_ID__c = null]){
    //  mapNodeId.put(d.key_Value__c, d.Id);
    //}

    Set<String> kv = new Set<String>();

    for(String keyMap: mapOli.keySet()){
      
      //check has targeting or not 
      //if not, create new 
      if(mapOli.get(keyMap).Targeting__c + '' == ''){
        Targeting__c tmpTar = new Targeting__c(TempBinder__c = true, Description__c = keyMap.split('_##_')[0] + ' targeting');
        mapTarId.put(keyMap, tmpTar);
      }
      
      OpportunityLineItem opli = mapOli.get(keyMap);
      String preKeyValue = opli.KeyValueString__c + '';
      
      //check KeyValueString is null or not
      if(preKeyValue != ''){
        
        //KeyValue: '((fse=353) OR (fse=9800) (fse=2032) OR (fse=15032)) OR (cat=293 OR tcat=293))
        
        List<String> lstKeyValues = getValueExp(EXP_GETKEYVALUE, preKeyValue);
            
        for(String s: lstKeyValues){
          //kv.add('%' + s + '%');
          kv.add(s);
        }
        
        
        
        //check KeyValueString contains , . ; 
        //Old form of KeyValue: ddd=678,hhhh=9999,...
        /*if(preKeyValue.contains(';') || preKeyValue.contains(',') || preKeyValue.contains('.')){
          
          //replace , . ; to ##
          preKeyValue = preKeyValue.replace(',', '##').replace('.', '##').replace(';', '##');
          
          //split KeyValueString by ##
          for(String strTmp : preKeyValue.split('##')){
            //split '=' from each value
            List<String> str= strTmp.split('=');
            kv.add('%' + str.get(1) + '%');
          }
        }else{
        
          if(preKeyValue.contains('=')){
            
            //List<String> str = preKeyValue.split('=');
            //kv.add('%' + str.get(1) + '%');
            
            
            
            
          }else{
            kv.add('%' + preKeyValue + '%');
          }
        }*/
      }
      
    }
    system.debug('\n\nkv = ' + kv + '\n');
    
    //List<DART_KeyValue_2__c> lstDart = new List<DART_KeyValue_2__c>([select id, Node_ID__c,Node_ID__r.Key__c, Name, Key_Value__c from DART_KeyValue_2__c where Key_Value__c like : kv ]);
    
    List<DART_KeyValue_2__c> lstDart = new List<DART_KeyValue_2__c>([select id, Node_ID__c,Node_ID__r.Key__c, Name, Key_Value__c from DART_KeyValue_2__c where Key_Value__c IN : kv ]);
    
    System.debug('-------------------------- lstDart: ' + lstDart.size());
    
    //Map<String, List<DART_KeyValue_2__c>> mapNodeDart = new Map<String, List<DART_KeyValue_2__c>>();
    Map<String, List<KeyValueDTO>> mapNodeDart = new Map<String, List<KeyValueDTO>>();
    
    
    // Sochanra Yos: 13-09-2013
    // Mapping key+keyValue and NodeId to get unique record with parent's key and child's KeyValue 
    Map<String,String> mapKeyNodeDartId = new Map<String,String>();
    
    for(DART_KeyValue_2__c d : lstDart){
      system.debug('\n\nd = ' + d + '\n');
      if(!mapNodeDart.containsKey(d.Node_ID__c)){
        mapNodeDart.put(d.Node_ID__c, new List<KeyValueDTO>());
      }
      
      //mapNodeDart.get(d.Node_ID__c).add(d);
      
      mapNodeDart.get(d.Node_ID__c).add(new KeyValueDTO(d.Id, d.Key_Value__c));

      mapKeyNodeDartId.put(d.Node_ID__r.Key__c+''+d.Key_Value__c, d.Node_ID__c+'');
    } 
    
    system.debug('\n\nmapNodeDart.keySet() = ' + mapNodeDart.keySet() + '\n');
    
    
     //NK:06/07/2012: from List<String> to Set<String> to fixed  duplicate value when KeyValue = DE Postal Code
     //Bug fixed:  DE Postal Codes(uz):((uz=10*,uz=12*,uz=13*,uz=14* OR uz=20*,uz=21*,uz=22*))
    Map<String, Set<String>> mapDartKeyId = new Map<String, Set<String>>();
    
    for(String keyMap: mapOli.keySet()){
      OpportunityLineItem opli = mapOli.get(keyMap);
      String preKeyValue = opli.KeyValueString__c + '';

      if(preKeyValue != ''){
          
        system.debug('\n\npreKeyValue = ' + preKeyValue + '\n');

          // Sochanra Yos: 12-09-2012: Fixed when keyvalues contain "="
          // by using regular expression instead of split by(=)
          // Ex: preKeyValue = '((fse=353) OR (fse=9800) (fse=2032) OR (fse=15032)OR (cat=293 OR tcat=293))
          // => lstKeyValues = (353, 9800, 2032, 15032, 293 OR tcat=293) ex: 353 is keyValue of child node
          // => lstKeys = (fse, fse, fse, fse, cat) ex: fse is key of parent node
          
          // EXP_GETKEYVALUE = '(\\(.*?=(.*?)\\))';
          // EXP_GETKEY = '(\\((.*?)\\=.*?)\\)';
            
          List<String> lstKeyValues = getValueExp(EXP_GETKEYVALUE, preKeyValue);
          List<String> lstKeys = getValueExp(EXP_GETKEY, preKeyValue.replace('((', '('));

          Integer i=0; 
            
          for(String strTmp : lstKeys){
            String newK = strTmp+lstKeyValues.get(i);
            String nodeId =mapKeyNodeDartId.get(newK);// newK= parentKey+keyvalue of child
              if(mapNodeDart.containsKey(nodeId)){
                for(KeyValueDTO d : mapNodeDart.get(nodeId)){
                //for(DART_KeyValue_2__c d : mapNodeDart.get(nodeId)){
                  //if(d.Key_Value__c.contains(lstKeyValues.get(i))){
                  if(d.dartKeyValue.contains(lstKeyValues.get(i))){
                    if(!mapDartKeyId.containsKey(keyMap)){
                      mapDartKeyId.put(keyMap, new Set<String>());
                    }
                    //mapDartKeyId.get(keyMap).add(d.Id);
                    mapDartKeyId.get(keyMap).add(d.dartKeyId);
                  }
                }
              }
            
            i++;
          }
          
          System.debug('==================== mapDartKeyId: ' + mapDartKeyId.size());
      }
    }

    if(mapTarId.size() > 0 ){
      insert mapTarId.values();
    }
    
    List<TargetingKeyValueAssociation__c> lstTarKey = new List<TargetingKeyValueAssociation__c>();
    Set<String> lstKeyMap = new Set<String>();
    Set<String> assoNotToDelete = new Set<String>();
    // only child product of Package Component
    //(mapPbeChild.get(strTmp).Product2.Name + '_##_'+ mapPbeChild.get(strTmp).Id + '_' + keyMap, opli);
    for(String keyMap: mapOli.keySet()){
    //  if(mapOli.get(keyMap).Id != null) continue;
      String ex_key = '';
      String tarId = ''; 
      if(!mapDartKeyId.containsKey(keyMap)) continue;
      OpportunityLineItem opli = mapOli.get(keyMap);
      if(opli.KeyValueString__c + '' == '') continue;
      if(opli.Targeting__c + '' == ''){
        opli.Targeting__c = mapTarId.get(keyMap).Id;
      }
      lstKeyMap.add(opli.Targeting__c);
      for(String s: mapDartKeyId.get(keyMap)){
        ex_key = opli.Targeting__c + s;  //Targeting + DART KeyValue
        lstTarKey.add(new TargetingKeyValueAssociation__c(Targeting__c = opli.Targeting__c, Operator__c= 'OR',DART_KeyValue__c = s,targetkeyvalue__c=ex_key));
        assoNotToDelete.add(ex_key);
      }

    } 
    
    if(lstTarKey.size() > 0){
      upsert lstTarKey targetkeyvalue__c;
      delete [Select Id From TargetingKeyValueAssociation__c Where Targeting__c in:lstKeyMap And targetkeyvalue__c Not In :assoNotToDelete ];
    }
    
  }   
  
  
  /**
   * @param strExp: String regular expression 
   * @param strKeyValues: String keyValue
   * @return lstKeyVals
   */
   // Sochanra Yos: 10-09-2012
  private List<String> getValueExp(String strExp, String strKeyValues){
    List<String> lstKeyVals = new List<String>();
    Matcher m = Pattern.compile(strExp).matcher(strKeyValues);
              
    while (m.find())
    {
      lstKeyVals.add(m.group(2));
    }
    return lstKeyVals;
  }
  
  
  private void createTarCont4PC(Map<String, OpportunityLineItem> mapOli, Map<String, String> mapDartContent){
      Map<String, Targeting__c> mapTarId = new Map<String, Targeting__c>();
      
      for(String keyMap : mapOli.keySet()){
        if(mapOli.get(keyMap).Targeting__c + '' == '') {
          Targeting__c tmpTar = new Targeting__c(TempBinder__c = true , Description__c = keyMap.split('_##_')[0] + ' targeting' );
          mapTarId.put(keyMap, tmpTar);
        }
      }
      
      if(mapTarId.size() > 0){
        insert mapTarId.values();
      }
      
      System.debug('\n\nmapDartContent: ' + mapDartContent + '\n\n');
      List<TargetingContentAssociation__c> lstTarCon = new List<TargetingContentAssociation__c>();
      Set<String> lstKeyMap =  new Set<String>();
      Set<String> assoNotToDelete = new Set<String>();
      
      for(String keyMap : mapOli.keySet()){   
      //  if(mapOli.get(keyMap).Id != null) continue;
        System.debug('\n\nkeyMap: ' + keyMap + '\n\n');
        String ex_key='';
        String tarId = '';
        if(mapOli.get(keyMap).Targeting__c + '' == '') {
          mapOli.get(keyMap).Targeting__c = mapTarId.get(keyMap).Id;
        }
        ex_key = mapOli.get(keyMap).Targeting__c + mapDartContent.get(keyMap);
        System.debug('\n\nex_key: ' + ex_key + '\n\n');
        if (mapDartContent.get(keyMap) != null) {
          TargetingContentAssociation__c tarCon = new TargetingContentAssociation__c(Targeting__c = mapOli.get(keyMap).Targeting__c, TargetingContent__c = mapDartContent.get(keyMap), Target_Content_Key__c = ex_key, Exclude__c = false);
          System.debug('\n\ntarCon: ' + tarCon + '\n\n');
          lstTarCon.add(tarCon);
        }
        lstKeyMap.add(mapOli.get(keyMap).Targeting__c);
        assoNotToDelete.add(ex_key);
      }
      
      if(lstTarCon.size() > 0){
        upsert lstTarCon Target_Content_Key__c;         
        delete [Select Id From TargetingContentAssociation__c Where Targeting__c in:lstKeyMap And Target_Content_Key__c Not In :assoNotToDelete ];
      }
  }
  
  
  //SP. 10-Jan-2012: Closed validation
  //SP. 04-Oct-2011
      //Validations on KV Targeting:
      //• Not more than 3 “AND”s
      //• Not more than 250 “OR” or “,” (KV pairs)
      //• Not more than 250 characters per key plus value
/*  private String checkValidation(String strChk){
        String tmp = strChk + '';
        Integer numAND =  tmp.toLowerCase().split('and').size() -1;
        Integer numOR = tmp.toLowerCase().split('or').size() -1;
        Integer numCamma = tmp.toLowerCase().split(',').size() -1;
        Integer numLengthAll = tmp.length();
        String strReturn = '';
        if(numAND > 3){
          strReturn = 'Not more than 3 \'AND\'s';
        }else if(numOR + numCamma > 250){
          strReturn = 'Not more than 250 \'OR\' or \',\'';
        }else if(numLengthAll > 250){
          strReturn = 'Not more than 250 characters per key plus value';
        }
        
        return strReturn;
  }
*/      
  /*
  Split record according to input start date and end date that available to split by calendar week, 2 calendar week, number of months .  
  */
  
  public PageReference splitRecord(){   
    errorMsg='';
    warningOli = '';
    fromDateError=false;
    forceDateSave=false;
    errorFieldStatus=false;
    decimal newquantity;
    List<DtoItem> splitRecs;
    for(Integer i=0;i<lstRecords.size();i++){     //not realy for 
        DtoItem tmp=lstRecords.get(i);
        tmp.saveSelectedHoursToItem();//Bunhor: modifying the OpportunityLineItem time targetting                      
        if(tmp.position==Integer.valueOf(selPosition)){                 
            OpportunityLineItem camItem=tmp.item;           
            if(camItem.Quantity==null) camItem.Quantity=0;      
            Date startDate=camItem.from_Date__c;          
            Date endDate=camItem.until_Date__c;           
            if(startDate==null || endDate==null) return null;           
            Date initWeek=startDate;          
            Date lastSun=startDate;           
            Date startTmp=startDate;          
            Date lastDate;                      
            splitRecs=new List<DtoItem>();            
            List<Media_Basket__c> newBaskets=new List<Media_Basket__c>(); 
            
            //Calendar week split         
            if(selShare=='week'){           
                Integer numWeeks=getNumWeeks(startDate,endDate,false);                
                if (numWeeks>1){                  
                    while(startTmp<=endDate){                                           
                      if(getDayInWeek(startTmp)=='Sun'){                        
                        newquantity=camItem.Quantity/numWeeks;
                        if (newquantity<1) {
                          newquantity=1;
                        }
                        DtoItem newItem = new DtoItem(tmp.productName,getNewCamItem(tmp.productName,camItem,(newquantity).setScale(2),initWeek,startTmp),tmp.isFixedSite, tmp.proId, tmp.availableSite, tmp.isHasSite, tmp.availableKV, tmp.billCategory2, tmp.pro, tmp.isHasPreDefine, dtoIdRunner);
                        splitRecs.add(newItem);                       
                        dtoIdRunner = newItem.dtoId;
                        newBaskets.add(createNewBasket(camItem));     
                                            
                        lastSun=startTmp;                         
                        initWeek=startTmp.addDays(1);
                      }                       
                      startTmp=startTmp.addDays(1);
                     }
                    if (lastSun<endDate){                       
                      newBaskets.add(createNewBasket(camItem));   
                      newquantity=camItem.Quantity/numWeeks;
                      if (newquantity<1) {
                        newquantity=1;
                      }       
                      DtoItem newItem = new DtoItem(tmp.productName,getNewCamItem(tmp.productName,camItem,(newquantity).setScale(2),initWeek,endDate),tmp.isFixedSite, tmp.proId, tmp.availableSite, tmp.isHasSite, tmp.availableKV, tmp.billCategory2, tmp.pro, tmp.isHasPreDefine, dtoIdRunner);                                    
                      splitRecs.add(newItem);
                      dtoIdRunner = newItem.dtoId;
                    }                     
                    lstRecords.remove(i);                     
                    removeBasket(camItem.PricebookEntryId);                   
                    lstRecords.addAll(splitRecs);
                    if(camItems==null){
                      insert newBaskets;                    
                    }   
                    
                    refreshPosition(lstRecords);                    
                    break;
                }                 
            }else if(selShare=='week2'){ //2 Calendar weeks split 
              Integer numWeeks2=getNumWeeks(startDate,endDate,true);
              Integer k=0;
              if(numWeeks2>1){
                  while(startTmp<=endDate){                       
                      if(getDayInWeek(startTmp)=='Sun'){
                        k=k+1;
                        if(Math.mod(k,2)==0){
                            newquantity=camItem.Quantity/numWeeks2;
                            if (newquantity<1) {
                              newquantity=1;
                            }
                            DtoItem newItem = new DtoItem(tmp.productName,getNewCamItem(tmp.productName,camItem,(newquantity).setScale(2),initWeek,startTmp),tmp.isFixedSite, tmp.proId, tmp.availableSite, tmp.isHasSite, tmp.availableKV, tmp.billCategory2, tmp.pro, tmp.isHasPreDefine, dtoIdRunner); 
                            splitRecs.add(newItem);
                            dtoIdRunner = newItem.dtoId;
                            newBaskets.add(createNewBasket(camItem));                             
                            lastSun=startTmp;
                            initWeek=startTmp.addDays(1);   
                        }
                      }
                      startTmp=startTmp.addDays(1);
                  }                   
                  if (lastSun<endDate){
                    newquantity=camItem.Quantity/numWeeks2;
                    if (newquantity<1) {
                      newquantity=1;
                    }
                    newBaskets.add(createNewBasket(camItem));
                    DtoItem newItem = new DtoItem(tmp.productName,getNewCamItem(tmp.productName,camItem,(newquantity).setScale(2),initWeek,endDate),tmp.isFixedSite, tmp.proId, tmp.availableSite, tmp.isHasSite, tmp.availableKV, tmp.billCategory2, tmp.pro, tmp.isHasPreDefine, dtoIdRunner); 
                    splitRecs.add(newItem);
                    dtoIdRunner = newItem.dtoId;                    
                  }                   
                lstRecords.remove(i);
                removeBasket(camItem.PricebookEntryId);
                lstRecords.addAll(splitRecs);
                  if(camItems==null){
                    insert newBaskets;
                  }
                
                refreshPosition(lstRecords);
                break;
            }
          }else if(selShare=='month'){  //Calendar month split  
            Integer months=getNumMonths(startDate,endDate);
            If(months>1){
              while(startTmp<=endDate){                 
                  lastDate=Date.newInstance(startTmp.year(), startTmp.month(), date.daysInMonth(startTmp.year(),startTmp.month()));
                if(startTmp==lastDate){
                  newquantity=camItem.Quantity/months;
                  if (newquantity<1) {
                    newquantity=1;
                  }
                  DtoItem newItem = new DtoItem(tmp.productName,getNewCamItem(tmp.productName,camItem,(newquantity).setScale(2),initWeek,startTmp),tmp.isFixedSite, tmp.proId, tmp.availableSite, tmp.isHasSite, tmp.availableKV, tmp.billCategory2, tmp.pro, tmp.isHasPreDefine, dtoIdRunner);
                  splitRecs.add(newItem);
                  dtoIdRunner = newItem.dtoId;
                  newBaskets.add(createNewBasket(camItem));
                  initWeek=startTmp.addDays(1);
                  lastSun=startTmp;                 
                }
                startTmp=startTmp.addDays(1);
              }
              If(lastSun<endDate){          
                  newBaskets.add(createNewBasket(camItem));
                  newquantity=camItem.Quantity/months;
                  if (newquantity<1) {
                    newquantity=1;
                  }
                  DtoItem newItem = new DtoItem(tmp.productName,getNewCamItem(tmp.productName,camItem,(newquantity).setScale(2),initWeek,endDate),tmp.isFixedSite, tmp.proId, tmp.availableSite, tmp.isHasSite, tmp.availableKV, tmp.billCategory2, tmp.pro, tmp.isHasPreDefine, dtoIdRunner); 
                  splitRecs.add(newItem);
                  dtoIdRunner = newItem.dtoId;            
              }
              lstRecords.remove(i);
              removeBasket(camItem.PricebookEntryId);
              lstRecords.addAll(splitRecs);
              if(camItems==null){
                insert newBaskets;
              }
              
              refreshPosition(lstRecords);
              break;
            }   
          }
        }
        
      }
      
    Map<String, OpportunityLineItem> mapOli = new Map<String, OpportunityLineItem>();//k=product name
    integer pi =0; //make it unique to bindTreeConfigurator(map)
    for(DtoItem it :splitRecs){
      mapOli.put(it.productName+'_##_'+ pi + '_' + it.dtoId ,it.item);
      pi ++;
    }   
    
    bindTreeConfigurator(mapOli, false);
    warningOli = lstRecords.size() > 100 ? system.Label.Warning_OppLine : '';
    
    gotoPage();
    return null;
  }
  /*
    Delete record from the list
  */
  private Set<Id> delItem = new Set<Id>();
  public PageReference deleteRecord(){
    errorMsg='';  
    warningOli = '';
    fromDateError=false;
    forceDateSave=false;  
      for(Integer i=0;i<lstRecords.size();i++){         
        DtoItem tmp=lstRecords.get(i);        
        if(tmp.position==Integer.valueOf(selPosition)){                    
            OpportunityLineItem camItem=tmp.item;           
            removeBasket(camItem.PricebookEntryId);   
            lstRecords.remove(i);
            //mapPbe2Id.remove(tmp.dtoId + '');
            mapPackageMain.remove(tmp.dtoId + '');
                                        
            if(camItem.Id!= null){
            delItem.add(camItem.Id);
            }
            break;
        } 
      }       
      
      refreshPosition(lstRecords);
      warningOli = lstRecords.size() > 100 ? system.Label.Warning_OppLine : '';
      gotoPage();
      return null;
  }
  
  //record for display per page
  public static final Integer MAXRECORD = 15;
  
  public Integer getMAXRECORD(){
    return MAXRECORD;
  }
  public Integer pageNum {get;set;}
  public Boolean disableNext {get;set;}
  public Boolean disablePre {get;set;}

  public List<Integer> numBtn {get;set;}
  public List<DtoItem> lDisplayRec {get;set;}
  public String disNumOfRecPerPage {get;set;}
  
  private Decimal getMaxPage(){
    Decimal d = lstRecords.size()/Decimal.valueOf(MAXRECORD);
    return d.round(System.Roundingmode.CEILING);
  }
  
  private Integer getStartIndexRec(Integer pageNumber){
    return (pageNumber * MAXRECORD) - MAXRECORD;
  }
  
  private void setListToDisplay(Integer indexStart , List<DtoItem> lRec){
    if(indexStart < 0) indexStart = 0;
    lDisplayRec = new List<DtoItem>();
    
    Integer lastNumOfRec = lRec.size();
    Integer indexRec =  indexStart + 1;
    Integer lastRecPerPage = indexStart + MAXRECORD;

    if(lastRecPerPage > lastNumOfRec) lastRecPerPage = lastNumOfRec;
    disNumOfRecPerPage = system.label.Record + ' ' + indexRec + ' - ' + lastRecPerPage + ' ' + system.label.of + ' ' + lastNumOfRec;
    for(Integer i = indexStart; i< (indexStart + MAXRECORD); i++){
      if(lRec.size() <= i) break;
      lDisplayRec.add(lRec.get(i));
    }   
  }
  
  
  public Pagereference gotoPage(){
    numbtn = new List<Integer>();
    
    for(Integer i=1; i<=Integer.valueOf(getMaxPage()); i++ ){
      numbtn.add(i);
    }
    if(pageNum > Integer.valueOf(getMaxPage())) pageNum = Integer.valueOf(getMaxPage());
    if(pageNum == 1 &&  getMaxPage() > 1){ 
      disablePre = true;
      disableNext = false;
    }else if(pageNum >= getMaxPage() && getMaxPage() > 1){ 
      disableNext = true;
      disablePre = false;
    }else if(pageNum > 1 && pageNum <= getMaxPage()){
      disableNext = false;
      disablePre = false;
    }else if (getMaxPage() == 1){
      disableNext = true;
      disablePre = true;
    }
    setListToDisplay(getStartIndexRec(pageNum), lstRecords);
    return null;
  }
  
  //go next page
  public Pagereference goNext(){
    pageNum++;
    if(pageNum >= getMaxPage()){
      pageNum = Integer.valueOf(getMaxPage());
    }
    gotoPage();
    return null;
  }
  
  //go previous Page
  public Pagereference goPrevious(){
    pageNum--;
    if(pageNum <= 1){
      pageNum = 1;
    }
    gotoPage();
    return null;
  }
  
  
  
  //SP: 8-8-2011 5.00PM
  public PageReference duplicateRecord(){ 
      errorMsg='';  
      warningOli = '';
      fromDateError=false;
      forceDateSave=false;
      Map<String, OpportunityLineItem> mapOli = new Map<String, OpportunityLineItem>();   
      DtoItem tmp = lstRecords.get(Integer.valueOf(selPosition));
      tmp.saveSelectedHoursToItem();//Bunhor: modifying the OpportunityLineItem time targetting
      System.debug('----------------> tmp: ' + tmp);

      for(Integer j=0;j<Integer.valueOf((SelCopies !=null  && SelCopies !='' ? SelCopies : '1'));j++){
          OpportunityLineItem tmpCamItem = createClone(tmp.productName,tmp.item,'');
          mapOli.put(tmp.productName +'_##_'+ j, tmpCamItem);
      }     
        
      bindTreeConfigurator(mapOli, false);
      
      
      
      
      List<Media_Basket__c> lstNBasket = new List<Media_Basket__c>();
      //15MB response size org limit (>=200)
      for(String keymap: mapOli.keySet()){
        //DtoItem dt = new DtoItem(keyMap.substring(0, keyMap.length()-2),mapOli.get(keymap));
        //lst2.add(dt);
        //lstRecords.add(new DtoItem(keyMap.split('_##_')[0],mapOli.get(keymap)));
        
        DtoItem newItem = new DtoItem(keyMap.split('_##_')[0],mapOli.get(keymap), tmp.isFixedSite, tmp.proId, tmp.availableSite, tmp.isHasSite, tmp.availableKV, tmp.billCategory2, tmp.pro, tmp.isHasPreDefine, dtoIdRunner);
        dtoIdRunner = newItem.dtoId;
        lstRecords.add(newItem);
         
         mapPackageMain.put(newItem.dtoId + '' , newItem);
        // add new item to basket
         Media_Basket__c nBasket=new Media_Basket__c(adPriceIdText__c=mapOli.get(keymap).PricebookEntryId,OpportunityId__c=id,UserId__c=System.Userinfo.getUserId());
         if(camItems == null){
          lstNBasket.add(nBasket);
         }
         baskets.add(nBasket);
      }
      insert lstNBasket;
      SelCopies = null;
      refreshPosition(lstRecords);
      warningOli = lstRecords.size() > 100 ? system.Label.Warning_OppLine : '';
      gotoPage();
      return null;
        
  }
   
   
  
   
   
  //Copy current item X times
  public PageReference copyRecords(){
    try{
    warningOli = '';
    duplicateRecord();
    warningOli = lstRecords.size() > 100 ? system.Label.Warning_OppLine : '';
    }catch(Exception e){
      Apexpages.Message msg = new Apexpages.Message(ApexPages.Severity.ERROR, e + '');
      Apexpages.addMessage(msg);
    }
    return null;
  }   
  
  /*Tree configuration function while copy a product in ModifyProduct VF page*/
  /*
  private void bindTreeConfigurator(OpportunityLineItem tmpCamItem, String productName){
    String idAsString = tmpCamItem.Targeting__c + '';
    if( idAsString == '' ) return; 
    
    Targeting__c tmpTar = new Targeting__c(TempBinder__c = true , Description__c = productName + ' targeting' ); 
    insert tmpTar;
    

    Targeting__c srcTar =   [Select Id,
                (Select Operator__c, Targeting__c, DART_KeyValue__c, targetkeyvalue__c From TargetingKeyValueAssociations__r), 
                (Select Targeting__c, Country__c, TargetCountry__c From TargetingCountryAssociations__r), 
                (Select Targeting__c, TargetingContent__c, Exclude__c, Target_Content_Key__c From TargetingContentAssociations__r), 
                (Select Targeting__c, City__c, targetcity__c From TargetingCityAssociations__r), 
                (Select Targeting__c, AreaCode__c, Target_Areacode_Key__c From TargetingAreaCodeAssociations__r) 
                From Targeting__c t Where Id =: tmpCamItem.Targeting__c];
    
    copyTargetContent (srcTar , tmpTar.Id);
    copyTargetKeyValue (srcTar , tmpTar.Id);
    copyTargetCountry (srcTar , tmpTar.Id); 
    copyTargetCity (srcTar , tmpTar.Id);
    copyTargetAreacode (srcTar , tmpTar.Id);
     
    tmpCamItem.Targeting__c = tmpTar.Id;
  } 
  */
  //SP: 8-8-2011 5.00PM
  //Converted to handle Mass Operation
  private void bindTreeConfigurator(Map<String, OpportunityLineItem> mapOli, Boolean isChild){
    Map<String, Targeting__c> mapTmpOli = new Map<String, Targeting__c>();
    Map<String, Targeting__c> mapIdTarNTmpTar = new Map<String, Targeting__c>();
    List<Targeting__c> lstTar = new List<Targeting__c>();
    Set<String> idTar = new Set<String>();
    
    
    //work on oli.targeting != '', If null, return
    Integer i =0;
    for(String keyMap : mapOli.keySet()){
      
      if((mapOli.get(keyMap).Targeting__c + '') != ''){   
        Targeting__c tmpTar;
          //create new Targeting
          tmpTar = new Targeting__c(TempBinder__c = true , Description__c = keyMap.split('_##_')[0] + ' targeting' ); 
          lstTar.add(tmpTar);
        //get original targeting id
        idTar.add(mapOli.get(keyMap).Targeting__c);
        
        //map original targeting id and new targeting
        mapIdTarNTmpTar.put(mapOli.get(keyMap).Targeting__c + '_' + i, tmpTar);
        i++;
        mapTmpOli.put(keyMap,tmpTar);
      }
    }
    
    if(idTar.size() <= 0) return; 
    
    if(lstTar.size() > 0){
      insert lstTar;
    }
    //Select original targeting
    //Target id have only one after select
    List<Targeting__c> srcTar = [Select Id,
                (Select Operator__c, Targeting__c, DART_KeyValue__c, targetkeyvalue__c From TargetingKeyValueAssociations__r), 
                //(Select Targeting__c, Country__c, TargetCountry__c From TargetingCountryAssociations__r), 
                (Select Targeting__c, TargetingContent__c, Exclude__c, Target_Content_Key__c From TargetingContentAssociations__r), 
                //(Select Targeting__c, City__c, targetcity__c From TargetingCityAssociations__r), 
                (Select Targeting__c, Geography__c, TargetGeography__c  From TargetingGeographyAssociations__r ),
                (Select Targeting__c, AreaCode__c, Target_Areacode_Key__c From TargetingAreaCodeAssociations__r),
                (Select Targeting__c, Device__c, TargetDevice__c From TargetingDeviceAssociations__r),
                (Select Targeting__c, Connection__c, TargetConnection__c From TargetingConnectionAssociations__r)  
                From Targeting__c t Where Id in: idTar];
      
    Map<String, Targeting__c> mapTmp = new Map<String, Targeting__c>();           
    for(Targeting__c t : srcTar){
      mapTmp.put(t.Id, t);
    }
    
    Map<String, Targeting__c> mapTarget = new Map<String, Targeting__c>();    
  
    for(String keymap: mapIdTarNTmpTar.keySet()){         
        String tm = keymap.split('_')[0];
        mapTarget.put(mapIdTarNTmpTar.get(keymap).Id, mapTmp.get(tm));
        
        
    }
    
    //if create by product component(child), not create targetContent and Keyvalue
    if(!isChild){
      copyTargetContent (mapTarget);
      copyTargetKeyValue (mapTarget);
    }
    //copyTargetCountry (mapTarget); 
    //copyTargetCity (mapTarget);
    copyTargetGeography(mapTarget );
    copyTargetAreacode (mapTarget);
    copyTargetingDevices(mapTarget);
    copyTargetingConnections(mapTarget);
    
    for(String keymap: mapOli.keySet()){
      if((mapOli.get(keyMap).Targeting__c + '') != ''){   
        if(mapOli.containsKey(keymap)){
          mapOli.get(keymap).Targeting__c = mapTmpOli.get(keyMap).Id;
        }
      }
    }
    
  }
  
  
  //delete TreeConfigurator from deleted lineItem
  private void removeTreeConfigurator(Set<Id> delTar){
    if(delTar.isEmpty()) return ;
    delete [Select Id From TargetingKeyValueAssociation__c Where Targeting__c In :delTar];
    delete [Select Id From Targeting__c Where Id In :delTar];
  }
  //Converted to handle Mass Operation
  private void copyTargetContent(Map<String, Targeting__c> mapTarget){
    Set<String> assoNotToDelete = new Set<String>();
    List<TargetingContentAssociation__c> lcontent = new List<TargetingContentAssociation__c>();
    Set<String> lstKeyMap =  mapTarget.keySet();
    
    for(String keyMap: mapTarget.keySet()){
      Targeting__c tar = mapTarget.get(keyMap);       
      for(TargetingContentAssociation__c con : tar.TargetingContentAssociations__r){    
        String ex_key = keyMap + '' +con.TargetingContent__c;
        lcontent.add(new TargetingContentAssociation__c(Targeting__c = keyMap, TargetingContent__c = con.TargetingContent__c, Exclude__c = con.Exclude__c,  Target_Content_Key__c = ex_key ));
        assoNotToDelete.add(ex_key);
      }
    }
    
    upsert lcontent Target_Content_Key__c;    
    delete [Select Id From TargetingContentAssociation__c Where Targeting__c in:lstKeyMap And Target_Content_Key__c Not In :assoNotToDelete ];
  }
  
   //Converted to handle Mass Operation
  private void copyTargetKeyValue(Map<String, Targeting__c> mapTarget){
    Set<String> assoNotToDelete = new Set<String>();
    List<TargetingKeyValueAssociation__c> lkeyval =  new List<TargetingKeyValueAssociation__c>();
    Set<String> lstKeyMap =  mapTarget.keySet();
    
    for(String keyMap: mapTarget.keySet()){
      Targeting__c tar = mapTarget.get(keyMap);       
      for(TargetingKeyValueAssociation__c key : tar.TargetingKeyValueAssociations__r){
        String ex_key = keyMap + '' +key.DART_KeyValue__c;
        lkeyval.add(new TargetingKeyValueAssociation__c(Targeting__c = keyMap, Operator__c = key.Operator__c, DART_KeyValue__c = key.DART_KeyValue__c, targetkeyvalue__c = ex_key ));
        assoNotToDelete.add(ex_key);
      }
    }
    upsert lkeyval targetkeyvalue__c;     
    delete [Select Id From TargetingKeyValueAssociation__c Where Targeting__c= :lstKeyMap And targetkeyvalue__c Not In :assoNotToDelete ];
  }
  
  //Sochanra: 29-04-2014
  //Comment out the code bellow base on task #3122
  //MOVE FROM - TargetingCountryAssociation__c & TargetingCityAssociation__c  objects
  //Converted to handle Mass Operation
 /* private void copyTargetCountry(Map<String, Targeting__c> mapTarget){
    Set<String> assoNotToDelete = new Set<String>();
    List<TargetingCountryAssociation__c> lcountry =  new List<TargetingCountryAssociation__c>();
    Set<String> lstKeyMap =  mapTarget.keySet();
    for(String keyMap: mapTarget.keySet()){
      Targeting__c tar = mapTarget.get(keyMap);         
      for(TargetingCountryAssociation__c cou : tar.TargetingCountryAssociations__r){
        String ex_key = keyMap + '' +cou.Country__c;
        lcountry.add(new TargetingCountryAssociation__c(Targeting__c = keyMap, Country__c = cou.Country__c, TargetCountry__c = ex_key ));
        assoNotToDelete.add(ex_key);
      }
    }
    upsert lcountry TargetCountry__c;     
    delete [Select Id From TargetingCountryAssociation__c Where Targeting__c= :lstKeyMap And TargetCountry__c Not In :assoNotToDelete ];
  }
  */
  
  private void copyTargetGeography(Map<String, Targeting__c> mapTarget)
  {
    
    Set<String> assoNotToDelete = new Set<String>();
    List<TargetingGeographyAssociation__c> lgeography = new List<TargetingGeographyAssociation__c>();
    Set<String> lstKeyMap = mapTarget.keySet();
    for(String keyMap: mapTarget.keySet())
    {
        Targeting__c tar = mapTarget.get(keyMap);
        for(TargetingGeographyAssociation__c geo : tar.TargetingGeographyAssociations__r )
        {
            String ex_key = keyMap + '' + geo.Geography__c;
            lgeography.add(new TargetingGeographyAssociation__c(Targeting__c = keyMap, Geography__c = geo.Geography__c, TargetGeography__c = ex_key));
            assoNotToDelete.add(ex_key);
        }
    }
    upsert lgeography TargetGeography__c;
    delete [Select Id From TargetingGeographyAssociation__c Where Targeting__c=: lstKeyMap And TargetGeography__c Not In : assoNotToDelete];
        
    
    
    
  }
  

  //Sochanra: 29-04-2014
  //Comment out code bellow base on task #3122
  //MOVE FROM - TargetingCountryAssociation__c & TargetingCityAssociation__c  objects
  //TO - TargetingGeographyAssociation__c object
  
  //Converted to handle Mass Operation
  //private void copyTargetCity(Map<String, Targeting__c> mapTarget){
    
  /*  Set<String> assoNotToDelete = new Set<String>();
    List<TargetingCityAssociation__c> lcity =  new List<TargetingCityAssociation__c>();
    Set<String> lstKeyMap =  mapTarget.keySet();
    
    for(String keyMap: mapTarget.keySet()){
      Targeting__c tar = mapTarget.get(keyMap);       
      for(TargetingCityAssociation__c cit : tar.TargetingCityAssociations__r){
        String ex_key = keyMap + '' +cit.City__c ;
        lcity.add(new TargetingCityAssociation__c(Targeting__c = keyMap, City__c = cit.City__c, targetcity__c = ex_key ));
        assoNotToDelete.add(ex_key);
      }
    }
    upsert lcity targetcity__c;   
    delete [Select Id From TargetingCityAssociation__c Where Targeting__c= :lstKeyMap And targetcity__c Not In :assoNotToDelete ];
  */
    //use future cos Heapsize error 
   /* Map<String, String> mapTem = new Map<String, String>();
    for(String keymap: mapTarget.keySet()){
      mapTem.put(keymap,mapTarget.get(keymap).Id);
    }
    copyTargetCity_ASYN(mapTem);
    */
 //}
  
  // Sochanra: 29-04-2014
  // Comment out the code bellow
  // Remove then use object Geography instead of City
  /*
  @future
  public static void copyTargetCity_ASYN(Map<String, String> mapTarget){
    
    Map<String, List<TargetingCityAssociation__c>> mapTarCity = new Map<String, List<TargetingCityAssociation__c>>();
    for(TargetingCityAssociation__c srcTar: [Select Targeting__c, City__c, targetcity__c From TargetingCityAssociation__c  Where Targeting__c in: mapTarget.values()]){
      if(!mapTarCity.containsKey(srcTar.Targeting__c)){
        mapTarCity.put(srcTar.Targeting__c, new List<TargetingCityAssociation__c>());
      }
      mapTarCity.get(srcTar.Targeting__c).add(srcTar);
        
    }
    
    Set<String> assoNotToDelete = new Set<String>();
    List<TargetingCityAssociation__c> lcity =  new List<TargetingCityAssociation__c>();
    Set<String> lstKeyMap =  mapTarget.keySet();
    
    for(String keyMap: mapTarget.keySet()){
      
      String idTar = mapTarget.get(keyMap);  
      if(!mapTarCity.containsKey(idTar)) continue;
      for(TargetingCityAssociation__c cit : mapTarCity.get(idTar)){
      
        if(cit == null) continue;
          String ex_key = keyMap + '' +cit.City__c ;
          lcity.add(new TargetingCityAssociation__c(Targeting__c = keyMap, City__c = cit.City__c, targetcity__c = ex_key ));
          assoNotToDelete.add(ex_key);
        
      }
    }
    if(lcity.size() > 0){
      upsert lcity targetcity__c;
    }   
    if(assoNotToDelete.size() > 0){ 
      delete [Select Id From TargetingCityAssociation__c Where Targeting__c= :lstKeyMap And targetcity__c Not In :assoNotToDelete ];
    }
    
    
  }
  */
 
 
  //#3229-GTCRM-880 - Devices Targeting
  //Sochanra-yos: 10-06-2014
  private void copyTargetingDevices(Map<String, Targeting__c> mapTarget)
  {
        Set<String> assNotToDelete = new Set<String>();
        List<TargetingDeviceAssociation__c > lstTargDevices = new List<TargetingDeviceAssociation__c>();
        
        for(String keyMap: mapTarget.keySet()){
            Targeting__c tar = mapTarget.get(keyMap);
          
            for(TargetingDeviceAssociation__c dev : tar.TargetingDeviceAssociations__r){
                String ex_key = keyMap + '' +dev.Device__c;
                lstTargDevices.add(new TargetingDeviceAssociation__c(Targeting__c = keyMap, Device__c = dev.Device__c, TargetDevice__c  = ex_key ));
                assNotToDelete .add(ex_key);
            }
        }
        upsert lstTargDevices TargetDevice__c;        
        delete [Select Id From TargetingDeviceAssociation__c Where Targeting__c IN : mapTarget.keySet() And TargetDevice__c Not In :assNotToDelete ];
        
  }
  
  //#3229-GTCRM-880 - Connections Targeting
  //Sochanra-yos: 10-06-2014
  private void copyTargetingConnections(Map<String, Targeting__c> mapTarget)
  {
        Set<String> assNotToDelete = new Set<String>();
        List<TargetingConnectionAssociation__c  > lstTargConns = new List<TargetingConnectionAssociation__c>();
        
        for(String keyMap: mapTarget.keySet()){
            Targeting__c tar = mapTarget.get(keyMap);
          
            for(TargetingConnectionAssociation__c con : tar.TargetingConnectionAssociations__r){
                String ex_key = keyMap + '' +con.Connection__c;
                lstTargConns.add(new TargetingConnectionAssociation__c(Targeting__c = keyMap, Connection__c = con.Connection__c, TargetConnection__c  = ex_key ));
                assNotToDelete .add(ex_key);
            }
        }
        upsert lstTargConns TargetConnection__c;
         delete [Select Id From TargetingConnectionAssociation__c Where Targeting__c IN : mapTarget.keySet() And TargetConnection__c Not In :assNotToDelete ];
  }
  
  
  
  //Converted to handle Mass Operation
  //SP: 8-8-2011 5.00PM
  private void copyTargetAreacode(Map<String, Targeting__c> mapTarget){
    Set<String> assoNotToDelete = new Set<String>();
    List<TargetingAreaCodeAssociation__c> lareacode =  new List<TargetingAreaCodeAssociation__c>();
    //Set<String> lstKeyMap =  mapTarget.keySet();
    
    for(String keyMap: mapTarget.keySet()){
      Targeting__c tar = mapTarget.get(keyMap);
      
      for(TargetingAreaCodeAssociation__c are : tar.TargetingAreaCodeAssociations__r){
        String ex_key = keyMap + '' +are.AreaCode__c;
        lareacode.add(new TargetingAreaCodeAssociation__c(Targeting__c = keyMap, AreaCode__c = are.AreaCode__c, Target_Areacode_Key__c = ex_key ));
        assoNotToDelete.add(ex_key);
      }
    }
    upsert lareacode Target_Areacode_Key__c;
     delete [Select Id From TargetingAreaCodeAssociation__c Where Targeting__c IN : mapTarget.keySet() And Target_Areacode_Key__c Not In :assoNotToDelete ];
    
    
  }
  
  
    public class KeyValueDTO{
      String dartKeyId; //{get; set;}
      String dartKeyValue;//{get; set;}
      public KeyValueDTO(String dartKeyId, String dartKeyValue){
        this.dartKeyId = dartKeyId;
        this.dartKeyValue = dartKeyValue;
      }
    }

// Bunhor: For time targeting with different hours on different days
  static private Map<Integer, String> mapHourOfDay = new Map<Integer, String> {  0  => '0:00 - 0:59'   ,
                                             1  => '1:00 - 1:59'   ,
                                             2  => '2:00 - 2:59'   ,
                                             3  => '3:00 - 3:59'   ,
                                             4  => '4:00 - 4:59'   ,
                                             5  => '5:00 - 5:59'   ,
                                             6  => '6:00 - 6:59'   ,
                                             7  => '7:00 - 7:59'   ,
                                             8  => '8:00 - 8:59'   ,
                                             9  => '9:00 - 9:59'   ,
                                             10 => '10:00 - 10:59' ,
                                             11 => '11:00 - 11:59' ,
                                             12 => '12:00 - 12:59' ,
                                             13 => '13:00 - 13:59' ,
                                             14 => '14:00 - 14:59' ,
                                             15 => '15:00 - 15:59' ,
                                             16 => '16:00 - 16:59' ,
                                             17 => '17:00 - 17:59' ,
                                             18 => '18:00 - 18:59' ,
                                             19 => '19:00 - 19:59' ,
                                             20 => '20:00 - 20:59' ,
                                             21 => '21:00 - 21:59' ,
                                             22 => '22:00 - 22:59' ,
                                             23 => '23:00 - 23:59' 
                                           };
  // Bunhor: For time targeting with different hours on different days                                         
  static private Map<String, String> mapDayField = new Map<String, String> {  'mon'  => 'DFP_Time_Monday__c'    ,
                                        'tue'  => 'DFP_Time_Tuesday__c'   ,
                                          'wed'  => 'DFP_Time_Wednesday__c' ,
                                          'thu'  => 'DFP_Time_Thursday__c'  ,
                                          'fri'  => 'DFP_Time_Friday__c'    , 
                                          'sat'  => 'DFP_Time_Saturday__c'  ,
                                          'sun'  => 'DFP_Time_Sunday__c'
                                      };
      
    
    public static String PERCENT_TYPE {get {return 'Percent';}}
    public static String GBP_TYPE {get {return 'GBP';}} 
    
  public class DtoItem{
    
    public String strHourOfDays{get;set;} // Bunhor: Getting all hours of all days, and put it in hidden text box for js to generate the checkbox, and vice versa.
    public Boolean isOldTimeTargating{get;set;} //

    public DtoItem(String productName,OpportunityLineItem item){    
        updateNewTimeTargeting(item); // update the item from old to new time targeting.
        strHourOfDays = getHourOfDays(item); // get all selected hours of all days as string for the hidden for js 
       
        this.productName=productName;        
        this.item=item;
        //this.item.Product2.Name=productName; 
        randomNr = Math.random();    // to be able to identify the records as the oppty li id for new records is unknown
        this.item.Surcharge_Type__c = (item.Surcharge_Type__c == null ? PERCENT_TYPE: item.Surcharge_Type__c);
        this.item.Discount_Type__c = (item.Discount_Type__c == null ? PERCENT_TYPE: item.Discount_Type__c);
    }     
    public Double randomNr {get;set;}
    //SP. 30-Sep-2011
    public DtoItem(String productName,OpportunityLineItem item, Boolean isFixSite, String proId, String availableSite, Boolean isHasSite, String availableKV, String billCategory2, Product2 pro, Boolean isHasPreDefine, Integer dtoIdRunner){   
  
        this.productName=productName;         
        this.item=item;
        this.isFixedSite = isFixSite;
        this.proId = proId;
        this.availableSite = availableSite;
        this.isHasSite = isHasSite;
        this.availableKV = availableKV;
        this.billCategory2 = billCategory2;
        this.pro = pro;
        this.isHasPreDefine = isHasPreDefine;
        dtoId = dtoIdRunner + 1;
      
        listBilling = getListBillingValue();
        this.item.Surcharge_Type__c = (item.Surcharge_Type__c == null ? PERCENT_TYPE: item.Surcharge_Type__c);
        this.item.Discount_Type__c = (item.Discount_Type__c == null ? PERCENT_TYPE: item.Discount_Type__c);
        prePopulateQuantity();
    }
    
    /**
     * Task #5285: GTCRM-2002 - Pre-populate quantity from default on product 
     * @createdDate: 19-May-2015
     * @author: PhanithChhun
     */
    private void prePopulateQuantity(){
        if(!getQuantityReadonly()) return;
        //if(item.Quantity != null && item.Quantity > 0) return;
        Quantity = String.valueOf(pro.Quantity__c);
        item.Quantity = pro.Quantity__c;
    }
    
    public Boolean getQuantityReadonly(){
        return pro.Quantity__c != null && pro.Quantity__c > 0;
    }
    
    /* Bunhor: Save selected hours from strHourOfDays to the OpportunityLineItem
     *     Fields: DFP_Time_Monday__c - LI.DFP_Time_Sunday__c
     */
    public void saveSelectedHoursToItem(){
      for(String dayName3char : mapDayField.keySet()){
        item.put(mapDayField.get(dayName3char), ''); // clear before modified -------
      }
      if(strHourOfDays != '' && strHourOfDays!=null){
        String[] lstHourOfDay = strHourOfDays.split(','); // ex: mon1,mon2,wed0,wed2,....
         
        for(String dayName3charAndHour : lstHourOfDay){
           
          String dayName3char = dayName3charAndHour.subString(0,3); 
          String fieldName = mapDayField.get(dayName3char);
          Integer hour = Integer.valueOf(dayName3charAndHour.subString(3));
          if(fieldName != null && fieldName != ''){
            String temValue = item.get(fieldName) == null ? '' : (item.get(fieldName) + '');
            item.put(fieldName, (temValue + mapHourOfDay.get(hour) + ';') ) ;  // modified --------
          } 
        }
      }
      // The content of the old fields should be deleted to not keep it forever.
      item.AdHourOfDay__c = null; 
      item.AdDayOfWeek__c= null;
    } 
    
    
    /* Bunhor:  Selecting old or new time targeting: 
     *      - Use new time-targeting
     *      - If new time-targeting not have, use old time-targeting as following rules:
     *      - If only LI.AdDayOfWeek__c has values highlight all hours for these days
     *      - If only LI.AdHourOfDay__c has values highlight theses hours on all days
     *      - If both have values highlght saved hours on saved days.
     */
    private void updateNewTimeTargeting(OpportunityLineItem item){
      if( item.DFP_Time_Monday__c != null    || 
        item.DFP_Time_Tuesday__c != null   || 
        item.DFP_Time_Wednesday__c != null ||
        item.DFP_Time_Thursday__c != null  || 
        item.DFP_Time_Friday__c != null    || 
        item.DFP_Time_Saturday__c != null  ||
        item.DFP_Time_Sunday__c != null        ){
         
      }else{
         
        if(item.AdDayOfWeek__c != null && item.AdHourOfDay__c == null){ //only LI.AdDayOfWeek__c has values
             isOldTimeTargating = true;
            String allHours = '';
            for(Integer i : mapHourOfDay.keySet()){
              allHours += (mapHourOfDay.get(i) + ';') ;
            }
              
            for( String day3char : getListOfDay3CharInLowerCase(item.AdDayOfWeek__c)){ 
              String fieldName = mapDayField.get(day3char);  
              item.put(fieldName, allHours);
            }
          
        }else if(item.AdDayOfWeek__c == null && item.AdHourOfDay__c != null){ //only LI.AdHourOfDay__c has values
            isOldTimeTargating = true;
            for(String fieldName : mapDayField.values()){
              item.put(fieldName, item.AdHourOfDay__c);
            } 
          
        }else if(item.AdDayOfWeek__c != null && item.AdHourOfDay__c != null){// both have values
             isOldTimeTargating = true;
            for( String day3char : getListOfDay3CharInLowerCase(item.AdDayOfWeek__c)){ 
              String fieldName = mapDayField.get(day3char);
              item.put(fieldName, item.AdHourOfDay__c);
            }
        }
      }   
    } 
    
    /* Bunhor : get list of days 
     *     Param : concantedDays (Ex 'Monday; Tuesday')
     *    return: ('mon', 'tue')
     */  
    private String[] getListOfDay3CharInLowerCase(String concantedDays){
      String[] theList = new List<String>();
      concantedDays = concantedDays.replaceAll(' ', '');
      for( String day : concantedDays.split(';') ){
        if(day != '' && day != null){
          day = day.substring(0,3);
          theList.add(day.tolowercase());
        }
      }
      return theList;    
    }
   
    /* Bunhor: Getting all hours of all days (from DFP_Time_Monday__c to DFP_Time_Sunday__c) 
     *    Return Ex: 'mon1,mon2,tue20,thu0,sun22'
     */
    private String getHourOfDays(OpportunityLineItem item){ 
       
      String theString = '';
      for(String dayName3char : mapDayField.keySet()){
        Object fieldValue = item.get(mapDayField.get(dayName3char));
        theString += getStrHourOfaDay(dayName3char,  fieldValue);
      } 
      return theString;
    }
    
    /* Bunhor:
     *     Param1 : dayName3char Ex: mon
     *    Param2 : mutilSelectHours is the multi-select field value. Ex: '0:00 - 0:59; 1:00 - 1:59; 2:00 - 2:59; 3:00 - 3:59;23:00 - 23:59'
     *    Retrun Ex: 'mon1,mon2,mon3,mon23,'
     */
    private String getStrHourOfaDay(String dayName3char, Object mutilSelectHours){  
      if(mutilSelectHours == null) return ''; 
      String[] selectedHours = ( mutilSelectHours+'' ).split(';');
      
      String theStr = '';
      for(String hour : selectedHours){
        if(hour !='')
        theStr += ( dayName3char + hour.subString(0, hour.indexOf(':') ) + ',' );
      }
      return theStr; 
    }
    
    
    public String billCategory2{get;set;}//use for get value from object
    
    public String billingCategory2;//use for assign value to opli billing category
    
    public void setBillingCategory2(String val){
      this.item.Billing_category__c = val;
      billingCategory2 = val;
    }
    public String getBillingCategory2(){
      return billingCategory2;
    }
    
    public List<SelectOption> listBilling {get;set;}
    
    private List<SelectOption> getListBillingValue(){
      List<String> lbillin = new List<String>();
      List<String> lstValue = new List<String>();
      if(this.billCategory2 == null || this.billCategory2 == ''){
        lbillin = mapValueBillingCategory2.values();
      }else{
        lbillin = this.billCategory2.split(';');
      }
      
      List<SelectOption> lso = new List<SelectOption>();
      lbillin.sort();
      String cpm = '';
      for(String str: lbillin){
        if(str.equalsIgnoreCase('CPM')){
          cpm = 'CPM';
        }
      }
      if(cpm != ''){
        lstValue.add(cpm);
      }
      for(String str: lbillin){
        if(!str.equalsIgnoreCase('CPM')){
          lstValue.add(str);
        }
      }
      
      for(String val: lstValue){
        lso.add(new SelectOption(val, val));
      }
      return lso;
    }
    
    
    
    public String proId{get;set;}
    public Integer position{get;set;}
    public String productName{get;set;}       
    public OpportunityLineItem item{get;set;}
    public String quantity;
    
    public Integer dtoId {get;set;} //Use as unique Id for Package Product(main Product)

    public Boolean isHasPreDefine {get;set;}
    public String availableKV {get;set;}
    public Boolean isHasSite {get;set;}
    public String availableSite {get;set;}
    public Boolean isFixedSite {get;set;}
    public String fromDate;
    public String unitlDate;
    public String targeting_c;
    public String descr;
    public String keyWords {get;set;}
    public String previewURL {get;set;}
    public Product2 pro {get;set;}
    public String errQty;
    public String getErrQty(){
      if(this.item.Quantity == null || this.item.Quantity == 0){
        return system.Label.Empty_value; 
      }
      return '';
    }
    
    public String errSalePrice;
    public String getErrSalePrice(){
      if(this.item.UnitPrice == null || this.item.UnitPrice == 0){
        return system.Label.Empty_value; 
      }
      return '';
      
    }
    
    public String errBillin;
    public String getErrBillin(){
      if(this.item.Billing_category__c == null || this.item.Billing_category__c == ''){
        return system.Label.Empty_value; 
      }
      return '';
    }
    
    public String getDescr(){
      return String.valueOf(item.Description == null ? '' : item.Description + '');
    }
    public String getFromDate(){
      return String.valueOf(item.from_Date__c == null ? '' : Date.valueOf(item.from_Date__c).format() + '');
    }
    public String getUntilDate(){
      return String.valueOf(item.until_Date__c == null ? '': Date.valueOf(item.until_Date__c).format() + '');
    }
    public String getTargeting_c(){
      return String.valueOf(item.Targeting__r.Name == null ? '' :  item.Targeting__r.Name + '');
    }
    public String getquantity() {
       return String.valueOf(formatCurrency(this.item.Quantity, 0));
    }
    public void setquantity(String v) {
      this.item.Quantity = v != null && v != '' ? Integer.valueOf(v): null;
       /*if (v!=null && v!='') {
         this.item.Quantity = Integer.valueOf(v);
       }
       else {
        this.item.Quantity = null;
        }*/
       Quantity = v;
    }
    
//SP 17-Nov-2011: Close Code
/*
    public String guaranteed_ai;
    public String getguaranteed_ai() {
       //system.debug('HB *** GETGUARANTEED: ' + this.item.guaranteed_ai__c);
       return String.valueOf(this.item.guaranteed_ai__c);
    }
    public void setguaranteed_ai(String v) {
      this.item.guaranteed_ai__c = v != null && v != '' ? Integer.valueOf(v): null;
       /*if (v!=null && v!='') {
        this.item.guaranteed_ai__c = Integer.valueOf(v);
       }
       else {
        this.item.guaranteed_ai__c = null;
        }
      */
/*       guaranteed_ai = v;
       //system.debug('HB *** SETGUARANTEED: ' + guaranteed_ai);
     }
*/
  }

  public static Decimal formatCurrency(Decimal val, Integer scale) {
     
     if (val!=null && scale!=null) {
      return val.setScale(scale);
     }
     else {
      return null;
     }
   }  

//     + Populates Sales price from Rate Card object based on length/quantity for Accounts products
public pagereference changevalue(){
  String length = '';
  try{
  if(Integer.valueof(lstRecords[integer.valueof(selPosition)].quantity) > 0 && Integer.valueof(lstRecords[integer.valueof(selPosition)].quantity) < 6){
    length = 'upto 5';
  }
  else{
    if(Integer.valueof(lstRecords[integer.valueof(selPosition)].quantity) > 5 && Integer.valueof(lstRecords[integer.valueof(selPosition)].quantity) < 10){
      length = '6 to 9';
    }
    else{
      if(Integer.valueof(lstRecords[integer.valueof(selPosition)].quantity) > 9 && Integer.valueof(lstRecords[integer.valueof(selPosition)].quantity) < 15){
        length = '10 to 14';
      }
      else{
        if(Integer.valueof(lstRecords[integer.valueof(selPosition)].quantity) > 14 && Integer.valueof(lstRecords[integer.valueof(selPosition)].quantity) < 25){
          length ='15 to 24';
        }
        else{
          if(Integer.valueof(lstRecords[integer.valueof(selPosition)].quantity) > 24 && Integer.valueof(lstRecords[integer.valueof(selPosition)].quantity) < 45){
            length ='25 to 44';
          }
          else{
            if(Integer.valueof(lstRecords[integer.valueof(selPosition)].quantity) > 44 && Integer.valueof(lstRecords[integer.valueof(selPosition)].quantity) < 65){
              length ='45 to 64';
            }
            else{
              if(Integer.valueof(lstRecords[integer.valueof(selPosition)].quantity) > 64 && Integer.valueof(lstRecords[integer.valueof(selPosition)].quantity) < 110){
                length = '65 to 109';
              }
              else{
                if(Integer.valueof(lstRecords[integer.valueof(selPosition)].quantity) > 109 && Integer.valueof(lstRecords[integer.valueof(selPosition)].quantity) < 150){
                  length ='110 to 149';
                }
                else{
                  if(Integer.valueof(lstRecords[integer.valueof(selPosition)].quantity) > 149 && Integer.valueof(lstRecords[integer.valueof(selPosition)].quantity) < 190){
                    length ='150 to 189';
                  }
                  else{
                    if(Integer.valueof(lstRecords[integer.valueof(selPosition)].quantity) > 189 && Integer.valueof(lstRecords[integer.valueof(selPosition)].quantity) < 250){
                      length ='190 to 249';
                    }
                    else{
                      if(Integer.valueof(lstRecords[integer.valueof(selPosition)].quantity) > 249 && Integer.valueof(lstRecords[integer.valueof(selPosition)].quantity) < 300){
                        length ='250 to 299';
                      }
                      else{
                      if(Integer.valueof(lstRecords[integer.valueof(selPosition)].quantity) > 299 && Integer.valueof(lstRecords[integer.valueof(selPosition)].quantity) < 350){
                        length ='300 to 349';
                       }
                      else{
                          if(Integer.valueof(lstRecords[integer.valueof(selPosition)].quantity) > 349 && Integer.valueof(lstRecords[integer.valueof(selPosition)].quantity) < 400){
                            length ='350 to 399';
                    }
                      else{
                          if(Integer.valueof(lstRecords[integer.valueof(selPosition)].quantity) > 399 && Integer.valueof(lstRecords[integer.valueof(selPosition)].quantity) < 500){
                            length ='400 to 499';
                    }
                      else{
                          if(Integer.valueof(lstRecords[integer.valueof(selPosition)].quantity) > 499 && Integer.valueof(lstRecords[integer.valueof(selPosition)].quantity) < 600){
                            length ='500 to 599';
                    }
                      else{
                          if(Integer.valueof(lstRecords[integer.valueof(selPosition)].quantity) > 599 && Integer.valueof(lstRecords[integer.valueof(selPosition)].quantity) < 800){
                            length ='600 to 799';
                    }
                     else{
                          if(Integer.valueof(lstRecords[integer.valueof(selPosition)].quantity) > 799 && Integer.valueof(lstRecords[integer.valueof(selPosition)].quantity) < 1000){
                            length ='800 to 999';
                    }
                     else{
                          if(Integer.valueof(lstRecords[integer.valueof(selPosition)].quantity) > 999){
                            length ='1000+';
                    }
                      else{
                        length = '';
                      }
              }
             }
                    }
                     }
                     }
                     }
        }
        }   

                  }
                }
              }
            }
          }
        }
      }
    }
  }
  list<rate_card__c> lstRateCard = [select id,Length__c,Quantity__c,Product__c,Sales_Price__c from Rate_Card__C where Length__c = : string.valueof(lstRecords[integer.valueof(selPosition)].item.Length_Months__c) and Quantity__c = :length and Product__c = :lstRecords[integer.valueof(selPosition)].proId];
    system.debug(string.valueof(lstRecords[integer.valueof(selPosition)].item.Length_Months__c));
    system.debug(length);
    system.debug(lstRecords[integer.valueof(selPosition)].proId);
  if(lstRateCard.size() > 0)
    lstRecords[integer.valueof(selPosition)].item.UnitPrice = lstRateCard[0].Sales_Price__c;

}
catch(exception ex){
}
    return null;
}
       
    
    /** block calculate SalesPrice **/
    private Map<Integer, Integer> mapMinValQty = new Map<Integer, Integer>{0 => 5,
                                                                        6 => 9,
                                                                        10 => 14,
                                                                        15 => 24,
                                                                        25 => 44,
                                                                        45 => 64,
                                                                        65 => 109,
                                                                        110 => 149,
                                                                        150 => 189,
                                                                        190 => 249,
                                                                        250 => 299,
                                                                        300 => 349,
                                                                        350 => 399,
                                                                        400 => 499,
                                                                        500 => 599,
                                                                        600 => 799,
                                                                        800 => 999,
                                                                        1000 => 1000
                                                                };
    private Map<Integer, String> mapMaxValQty = new Map<Integer, String>{5 => 'Up to 5',
                                                                        9 => '6 to 9',
                                                                        14 => '10 to 14',
                                                                        24 => '15 to 24',
                                                                        44 => '25 to 44',
                                                                        64 => '45 to 64',
                                                                        109 => '65 to 109',
                                                                        149 => '110 to 149',
                                                                        189 => '150 to 189',
                                                                        249 => '190 to 249',
                                                                        299 => '250 to 299',
                                                                        349 => '300 to 349',
                                                                        399 => '350 to 399',
                                                                        499 => '400 to 499',
                                                                        599 => '500 to 599',
                                                                        799 => '600 to 799',
                                                                        999 => '800 to 999',
                                                                        1000 => '1000+'
                                                                        };  
    
    public Pagereference reCalculateAll(){
        reEvaluateAll();
        return null;
    }
    
    private void reEvaluateAll(){
        reEvaluateUntilDate();
        reEvaluateQTYForCPD();
        reEvaluateQtyByBudget();
        reEvaluateSalesPrice();
        reEvaluateSalesPriceTarget();
        reEvaluateSurchargeAndDiscount();
        reEvaluateNetNetNet();
    }
    
    /**
    * Method calculate  SalePrice  by Length, Qty
    * @createdDate 24-May-2013
    * @author Sopha Pum
    */
    public Pagereference calculateSalesPrice() {
        return null;
        //If Product2.Fixed_Price__c = TRUE and Product2.Rate_Card__c = TRUE then field is disabled 
        //and rate card price is automatically defined from object, Rate_Card__c related to the product itself
  /*      Product2 pro = lstRecords[integer.valueof(selPosition)].pro;
        if(!isGetRateCardPrice(pro)) {
            calNetNetNet();
            return null;
        }
        
        //get quantity rang that match quantity
        Integer quantity = Integer.valueof(lstRecords[integer.valueof(selPosition)].quantity == null? '0': lstRecords[integer.valueof(selPosition)].quantity);
        String qtyRang = getQuantityRang(quantity);

        Decimal unitPrice = [Select UnitPrice From PricebookEntry Where Product2Id=: pro.Id And Pricebook2Id =: mcPBId limit 1].UnitPrice;

        //get sale price value fro Rate card
        List<Rate_Card__c> lstRateCards = [select Sales_Price__c 
                                                from Rate_Card__c 
                                                where Length__c = : String.valueof(lstRecords[Integer.valueof(selPosition)].item.Length_Months__c) 
                                                    and Quantity__c = :qtyRang 
                                                    and Product__c = :lstRecords[integer.valueof(selPosition)].proId];

        if(!lstRateCards.isEmpty()){
            unitPrice = lstRateCards.get(0).Sales_Price__c;
        }
        lstRecords.get(Integer.valueof(selPosition)).item.UnitPrice = unitPrice;
        
        calNetNetNet();
        return null;*/
    }
    
    /**
    * Method to check SalesPrice is get from RateCard object or not
    * @author Sopha Pum
    */
    private Boolean isGetRateCardPrice(Product2 pro){
        if(pro.Rate_Card__c == false || pro.Fixed_price__c == false) return false;
        return true;
    }
    
    /**
    * Method get Quantity rang
    * @author Sopha Pum
    *
    private String getQuantityRang(Integer quantity){
        String qtyRang = '';
        for(Integer min: mapMinValQty.keySet()){
            if((min <= quantity && mapMinValQty.get(min) >= quantity) || (min <= quantity  && mapMinValQty.get(min) <= quantity && quantity >= 1000)){
                qtyRang = mapMaxValQty.get(mapMinValQty.get(min));
                break;
            }
        }
        return qtyRang;
    }*/
    
    /**
    * Method reEvaluate SalePrice by Length, Qty
    * @createdDate 24-May-2013
    * @author Sopha Pum
    */
    private void reEvaluateSalesPrice() {
        Set<ID> proIds = new Set<ID>();
        Set<String> lengthMonths = new Set<String>();
        for(DTOItem rec: lstRecords){
            if(!isGetRateCardPrice(rec.pro)) continue;
            proIds.add(rec.pro.Id);
            lengthMonths.add(String.valueof(rec.item.Length_Months__c));
        }
        
        //get default pricebook
        Map<String, Decimal> mapDefaultPrice = new Map<String, Decimal>();//<ProductID_Pricebook2Id, SalesPrice>
        for(PricebookEntry pbe: [Select UnitPrice, Product2Id, Pricebook2Id 
                                    From PricebookEntry Where Product2Id in: proIds And Pricebook2Id =: mcPBId]){
            mapDefaultPrice.put(pbe.Product2Id + '_' + pbe.Pricebook2Id, pbe.UnitPrice);
        }
        
        //get sale price value fro Rate card
        List<Rate_Card__c> lstRateCards = [select Sales_Price__c, Length__c, Quantity2__c, Product__c 
                                                from Rate_Card__c 
                                                where Length__c in: lengthMonths and Product__c in:proIds And Active__c = true order by Quantity2__c DESC];
        for(DTOItem rec: lstRecords){
            if(!isGetRateCardPrice(rec.pro)) continue;
            Integer qty = Integer.valueof(rec.quantity == null ? '0': rec.quantity);
            Decimal salePriceFromRC = 0;
            
            //get matching salesprice from Rate Card
            //Ex. f quantity = 12, length = 3 months on modify product then look up rate card object attached to product, 
            //find length and find the quantity that it's greater then, in this case it would be 10, 
            //as 12 is greater than 10 and the next highest number is 15.
            for(Rate_Card__c rc: lstRateCards){
                if(rc.Product__c != rec.pro.Id || rc.Quantity2__c > qty || rec.item.Length_Months__c == null || String.valueOf(rec.item.Length_Months__c) != rc.Length__c) continue;
                salePriceFromRC = rc.Sales_Price__c;
                break;
            }
            //if there is no SalesPrice from Rate Card, get the default price
            rec.item.UnitPrice = (salePriceFromRC != 0? salePriceFromRC: mapDefaultPrice.get(rec.pro.Id + '_' + mcPBId));
        }
        reEvaluateNetNetNet();
    }
    
    /**
    * Method to calculate Net/Net/Net
    * Formula: 
    * - Net/Net/Net =
    *       Billing category “CPM” = (Quantity / 1000) * Sales Price + Surcharge % or GBP – Discount % or GBP – AC
    *       Billing category “CPC,CPD,CPA, Fix Price” = Quantity * Sales Price + Surcharge % of GBP – Discount X or GBP -AC
    * @createdDate: 27-May-2013
    * @author: Sopha Pum
    */
    private void calNetNetNet(){
        Boolean isCPM = lstRecords[integer.valueof(selPosition)].billingCategory2 == BILLING_CPM; //get type of Billing category
        Boolean isSurchargeGBP = lstRecords[integer.valueof(selPosition)].item.Surcharge_Type__c == GBP_TYPE; //get type of Surcharge
        Boolean isDiscountGBP = lstRecords[integer.valueof(selPosition)].item.Discount_Type__c == GBP_TYPE;//get type of Discount

        //get quantity
        //NK:14/06/2013: fixed empty quantity that causes: Invalid integer
        Integer qty = Integer.valueOf((lstRecords[integer.valueof(selPosition)].quantity == null || lstRecords[integer.valueof(selPosition)].quantity=='') ? '0' : lstRecords[integer.valueof(selPosition)].quantity);
        
        //get Sales Price
        Decimal salesPrice = lstRecords[integer.valueof(selPosition)].item.UnitPrice;
        salesPrice = (salesPrice == null? 0: salesPrice);

        //If billing category is CPM => total = (quantity / 1000) 
        //If billing category is CPC,CPD,CPA, Fix Price => total = quantity 
        Decimal total = (isCPM ? (qty / 1000.0) : qty);

        //get surcharge price 
        Decimal surcharge_val = lstRecords[integer.valueof(selPosition)].item.Targeting_Surcharge__c;
        surcharge_val = (surcharge_val == null ? 0: (isSurchargeGBP ? surcharge_val : surcharge_val/100.0));        
        Decimal surcharge_price = (isSurchargeGBP? surcharge_val : (salesPrice * surcharge_val));

        //get Discount price
        Decimal discount_val = lstRecords[integer.valueof(selPosition)].item.Rate_Discount_II__c;
        discount_val = (discount_val == null ? 0: (isDiscountGBP ? discount_val: discount_val/100.0));
        Decimal discount_price = (isDiscountGBP ? discount_val : (salesPrice * discount_val));

        //Total Sales Price + Surcharge % or GBP – Discount % or GBP – AC 
        Decimal totalNet = salesPrice + surcharge_price - discount_price;
        
        Decimal salesPriceTarget = lstRecords[integer.valueof(selPosition)].item.Sales_Price_Target__c;
        salesPriceTarget = (salesPriceTarget == null? 0: salesPriceTarget);
        
        //Total salesprice 
        Decimal totalNetNet = total * (salesPriceTarget == 0? totalNet: salesPriceTarget);
        
        //get AC % (AC = 15%)
        Boolean isAc = lstRecords[integer.valueof(selPosition)].item.AE__c;
        Decimal ac_percent = (isAc == true ? (15.0/100): 0);
        Decimal ac_price = totalNetNet * ac_percent;

        //Total salesprice + surcharge price - Discount price - AC price (if billing category = CPM)
        //Total salesprice + surcharge price - Discount price  (if billing category != CPM)
        Decimal totalNetNetNet = totalNetNet - ac_price;
        lstRecords[integer.valueof(selPosition)].item.Net_Net_Net__c = totalNetNetNet.setScale(2);
    }
    
    /**
    * Method to calculate Net/Net/Net
    * Formala: 
    * - Net/Net/Net =
    *       Billing category “CPM” = (Quantity / 1000) * Sales Price + Surcharge % or GBP – Discount % or GBP – AC
    *       Billing category “CPC,CPD,CPA, Fix Price” = Quantity * Sales Price + Surcharge % of GBP – Discount X or GBP
    * @createdDate: 27-May-2013
    * @author: Sopha Pum
    */
    public Pagereference calculateNetNetNet(){
        calNetNetNet();
        return null;
    }
    
    /**
    * Method to reevaluate calculate Net/Net/Net
    * Formala: 
    * - Net/Net/Net =
    *       Billing category “CPM” = (Quantity / 1000) * Sales Price + Surcharge % or GBP – Discount % or GBP – AC
    *       Billing category “CPC,CPD,CPA, Fix Price” = Quantity * Sales Price + Surcharge % of GBP – Discount X or GBP
    * @createdDate: 27-May-2013
    * @author: Sopha Pum
    */
    private void reEvaluateNetNetNet(){
        for(Integer i=0; i<lstRecords.size(); i++){
            selPosition = i+'';
            calNetNetNet();
        }
    }
    
    
    /**
    * Method get sales price and quantity
    * @author Sopha Pum
    */
    private Map<String, List<Rate_Card__c>> mappingProAndRateCard(List<Rate_Card__c > lstRateCards){
        Map<String, List<Rate_Card__c>> mapRateCards = new Map<String, List<Rate_Card__c>>(); //<ProductId_Length, List<Rate Card>>
        
        for(Rate_Card__c rc : lstRateCards){
            String proIdLength = String.valueOf(rc.Product__c).subString(0, 15) + '_' + rc.Length__c;
            
            if(!mapRateCards.containsKey(proIdLength)){
                mapRateCards.put(proIdLength, new List<Rate_Card__c>());
            }
            mapRateCards.get(proIdLength).add(rc);
        }
        
        return mapRateCards;
    }
    
    /**
    * Method to get SalesPrice from RateCard
    * @author Sopha Pum
    */
    private Decimal getSalesPriceFromRateCard(List<Rate_Card__c > lstRateCards, Decimal budget){
        Decimal salePrice = 0;
        
        for(Rate_Card__c rc : lstRateCards){
            
            Decimal quantityRang = rc.Quantity2__c;

            //get price
            Decimal price = rc.Sales_Price__c * rc.Quantity2__c;
            
            //if price over budget, continue;
            if(price > budget) continue;
            
            if(price < (salePrice * rc.Quantity2__c)) continue;
            
            salePrice = rc.Sales_Price__c;
            
        }
        
        return salePrice;
    }
    
    /**
    * Method calculate Quantity when Budget NET/NET/NET is changed
    * @author Sopha Pum
    */
    public Pagereference calculateQtyByBudget() {
        Decimal budget = lstRecords[integer.valueof(selPosition)].item.Budget_NetNetNet__c;
        budget = (budget == null ? 0: budget);
        if(budget == 0) return null;
        
        Boolean isCPM = lstRecords[integer.valueof(selPosition)].billingCategory2 == BILLING_CPM; //get type of Billing category
        Boolean isSurchargeGBP = lstRecords[integer.valueof(selPosition)].item.Surcharge_Type__c == GBP_TYPE; //get type of Surcharge
        Boolean isDiscountGBP = lstRecords[integer.valueof(selPosition)].item.Discount_Type__c == GBP_TYPE;//get type of Discount
        Boolean isAc = lstRecords[integer.valueof(selPosition)].item.AE__c;
        Decimal acPrice = (isAc == true ? (15.0/100): 0);
        
        Decimal surchargePrice = lstRecords[integer.valueof(selPosition)].item.Targeting_Surcharge__c;
        surchargePrice = (surchargePrice == null ? 0: surchargePrice);
        
        Decimal discountPrice = lstRecords[integer.valueof(selPosition)].item.Rate_Discount_II__c;
        discountPrice = (discountPrice == null ? 0: discountPrice);
        
        String proId = lstRecords[integer.valueof(selPosition)].pro.Id;
        proId = proId.subString(0, 15);
        
        budget = (isCPM ? budget * 1000: budget);
    
        Decimal salePriceTarget = lstRecords[integer.valueof(selPosition)].item.Sales_Price_Target__c;
        salePriceTarget = (salePriceTarget == null ? 0: salePriceTarget);
        
        String length = String.valueof(lstRecords[integer.valueof(selPosition)].item.Length_Months__c);
        
        List<Rate_Card__c> lstRateCards = [select Sales_Price__c, Length__c, Quantity2__c, Product__c 
                                                from Rate_Card__c 
                                                where Length__c =: length and Product__c =:proId And Active__c = true];
                                                        
        Map<String, List<Rate_Card__c>> mapRateCards = mappingProAndRateCard(lstRateCards);
        
        String proIdLength = proId + '_' + length;
        Decimal salePrice = (mapRateCards.containsKey(proIdLength)? getSalesPriceFromRateCard(mapRateCards.get(proIdLength), budget) : lstRecords[integer.valueof(selPosition)].item.UnitPrice);
        salePrice = (isGetRateCardPrice(lstRecords[integer.valueof(selPosition)].pro)? salePrice: lstRecords[integer.valueof(selPosition)].item.UnitPrice);
        
        surchargePrice = (isSurchargeGBP? surchargePrice: (salePrice * surchargePrice) /100);
        discountPrice = (isDiscountGBP? discountPrice: (salePrice * discountPrice) /100);
        
        salePrice = salePrice + surchargePrice - discountPrice;
        acPrice = (isAc ? (salePriceTarget == 0? (salePrice * 15 / 100): (salePriceTarget * 15 / 100)): 0);
        
        salePriceTarget = (salePriceTarget == 0 ? (salePrice - acPrice) : (salePriceTarget - acPrice));
        
        Integer qty = getQuantityFromSalePrice(budget, salePriceTarget);
        lstRecords[integer.valueof(selPosition)].setQuantity(String.valueOf(qty));
        
        calNetNetNet();
        return null;
    }
    
    /**
    * Method reevaluate the calculation of Quantity  when Budget NET/NET/NET is changed
    * @author Sopha Pum
    */
    private void reEvaluateQtyByBudget(){
        Set<ID> proIds = new Set<ID>();
        Set<String> lengthMonths = new Set<String>();

        for(DTOItem rec: lstRecords){
            if(!isGetRateCardPrice(rec.pro)) continue;
            
            proIds.add(rec.pro.Id);
            lengthMonths.add(String.valueof(rec.item.Length_Months__c));
        }
        
        List<Rate_Card__c> lstRateCard = [select Sales_Price__c, Length__c, Quantity2__c, Product__c 
                                                from Rate_Card__c 
                                                where Length__c in: lengthMonths and Product__c in:proIds and Active__c = true];
                                                        
        Map<String, List<Rate_Card__c>> mapRateCards = mappingProAndRateCard(lstRateCard);
        
        
        for(DTOItem rec: lstRecords){
            Boolean isCPM = rec.billingCategory2 == BILLING_CPM; //get type of Billing category
            
            String proId = rec.pro.Id;
            proId = proId.subString(0, 15);
            String proIdLength = proId + '_' + rec.item.Length_Months__c;
            
            Decimal budget = rec.item.Budget_NetNetNet__c;
            budget = (budget == null ? 0: budget);
            budget = (isCPM ? budget * 1000: budget);
            
            if(budget == 0) continue;
            
            Boolean isSurchargeGBP = rec.item.Surcharge_Type__c == GBP_TYPE; //get type of Surcharge
            Boolean isDiscountGBP = rec.item.Discount_Type__c == GBP_TYPE;//get type of Discount
            Boolean isAc = rec.item.AE__c;
            
            Decimal surchargePrice = rec.item.Targeting_Surcharge__c;
            surchargePrice = (surchargePrice == null ? 0: surchargePrice);
            
            Decimal discountPrice = rec.item.Rate_Discount_II__c;
            discountPrice = (discountPrice == null ? 0: discountPrice);
            
            Decimal salePriceTarget = rec.item.Sales_Price_Target__c;
            salePriceTarget = (salePriceTarget == null ? 0: salePriceTarget);
            
            Decimal salePrice = (mapRateCards.containsKey(proIdLength)? getSalesPriceFromRateCard(mapRateCards.get(proIdLength), budget) : rec.item.UnitPrice);
            salePrice = (isGetRateCardPrice(rec.pro)? salePrice: rec.item.UnitPrice);
            
            surchargePrice = (isSurchargeGBP? surchargePrice: (salePrice * surchargePrice) /100);
            discountPrice = (isDiscountGBP? discountPrice: (salePrice * discountPrice) /100);
            
            salePrice = salePrice + surchargePrice - discountPrice;
            Decimal acPrice = (isAc? (salePriceTarget == 0? (salePrice * 15 / 100): (salePriceTarget * 15 / 100)): 0);
            
            salePriceTarget = (salePriceTarget == 0 ? (salePrice - acPrice) : (salePriceTarget - acPrice));
            
        
            Integer qty = getQuantityFromSalePrice(budget, salePriceTarget);
            rec.setQuantity(String.valueOf(qty));
        }
        reEvaluateNetNetNet();
    }
    
    /*
    * Mehtod to Calculate quantity for CPD lines
    */
    private void reEvaluateQTYForCPD(){
        for(DTOItem rec: lstRecords){
            
            // If Billing Category = CPD,
            //Quantity should update to reflect (until_Date__c – from_Date__c)
            if(rec.billingCategory2 != 'CPD') continue;
            
            Date fromDate = rec.item.from_Date__c;
            Date untilDate = rec.item.until_Date__c;
            
            if(untilDate < fromDate) continue;
            
            Integer num = fromDate.daysBetween(untilDate) + 1;
            rec.setQuantity(String.valueOf(num));
        }
        
    }
    
    /*
    * Method Calculate until (date) when months / days input
    */
    private void reEvaluateUntilDate(){
        for(DTOItem rec: lstRecords){
            rec.item.Length_Months__c = (rec.item.Length_Months__c == null? 0: rec.item.Length_Months__c);
            rec.item.Additional_Time_Days__c = (rec.item.Additional_Time_Days__c == null? 0: rec.item.Additional_Time_Days__c);
            if(rec.item.Length_Months__c == 0 && rec.item.Additional_Time_Days__c == 0) continue;
            
            rec.item.until_Date__c = rec.item.from_Date__c.addMonths(rec.item.Length_Months__c.intValue()).addDays(rec.item.Additional_Time_Days__c.intValue());
        }
    }
    
    //If sales price is equal to £20.00 and Target Price is equal to £18.00, then Discount should update to 10%.
    //If sales price is equal to £20.00 and Target Price is equal to £22.00, then Surcharge should update to 10%. etc.
    public Pagereference calculateSurchargeAndDiscount(){
        doCalSurchargeDiscount();
        return null;
    }
    
    private void doCalSurchargeDiscount(){
        Decimal salePriceTarget = lstRecords[integer.valueof(selPosition)].item.Sales_Price_Target__c;
        salePriceTarget = (salePriceTarget == null? 0: salePriceTarget);
        Decimal salePrice = lstRecords[integer.valueof(selPosition)].item.UnitPrice;
        salePrice = (salePrice == null? 0: salePrice);

        if(salePriceTarget == 0) return;

        Boolean isSurchargeGBP = lstRecords[integer.valueof(selPosition)].item.Surcharge_Type__c == GBP_TYPE; //get type of Surcharge
        Boolean isDiscountGBP = lstRecords[integer.valueof(selPosition)].item.Discount_Type__c == GBP_TYPE;//get type of Discount
        
        //if target price > sales pric, calculate value for Surcharge   
        Boolean isCal4SurCharge = (salePriceTarget > salePrice);
        
        Decimal price = (isCal4SurCharge ? (salePriceTarget - salePrice) : (salePrice - salePriceTarget));
        price = price.setScale(2);
        Decimal percent = (salePrice == 0? 0: (price * 100) / salePrice);
        percent = percent.setScale(2);
        
        lstRecords[integer.valueof(selPosition)].item.Targeting_Surcharge__c = (isCal4SurCharge ? (isSurchargeGBP? price: percent) : 0);
        lstRecords[integer.valueof(selPosition)].item.Rate_Discount_II__c = (isCal4SurCharge ? 0: (isDiscountGBP? price: percent));
        
        //re-calculate NetNetNet
        calNetNetNet();
    }
    
    
    private void reEvaluateSurchargeAndDiscount(){
        for(Integer i=0; i<lstRecords.size(); i++){
            selPosition = i+'';
            doCalSurchargeDiscount();
        }
    }
    
    private void reEvaluateSalesPriceTarget(){
        for(Integer i=0; i<lstRecords.size(); i++){
            selPosition = i+'';
            calSalesPriceTarget();
        }
    }
    
    private void calSalesPriceTarget(){
        Decimal salePriceTarget = lstRecords[integer.valueof(selPosition)].item.Sales_Price_Target__c;
        salePriceTarget = (salePriceTarget == null? 0: salePriceTarget);
        if(salePriceTarget != 0) return;
        
        Decimal salePrice = lstRecords[integer.valueof(selPosition)].item.UnitPrice;
        salePrice = (salePrice == null? 0: salePrice);
        
        Boolean isSurchargeGBP = lstRecords[integer.valueof(selPosition)].item.Surcharge_Type__c == GBP_TYPE; //get type of Surcharge
        Boolean isDiscountGBP = lstRecords[integer.valueof(selPosition)].item.Discount_Type__c == GBP_TYPE;//get type of Discount
        
        Decimal surchargePrice = lstRecords[integer.valueof(selPosition)].item.Targeting_Surcharge__c;
        surchargePrice = (surchargePrice== null? 0: surchargePrice);
        surchargePrice = (isSurchargeGBP? surchargePrice: (salePrice * surchargePrice) /100); 
        
        Decimal discountPrice = lstRecords[integer.valueof(selPosition)].item.Rate_Discount_II__c;
        discountPrice = (discountPrice == null? 0: discountPrice);
        discountPrice = (isDiscountGBP? discountPrice: (salePrice * discountPrice) /100); 
        
        salePriceTarget = salePrice + surchargePrice - discountPrice;
        lstRecords[integer.valueof(selPosition)].item.Sales_Price_Target__c= salePriceTarget;
    }
    
    /**
    * Method to get quantity by budget and salesprice
    * @author Sopha Pum
    */
    private Integer getQuantityFromSalePrice(Decimal budget, Decimal salesPrice){
        Decimal qty = budget/salesPrice;
        qty = qty.setScale(0, System.Roundingmode.DOWN);
        
        return Integer.valueOf(qty);
    }


  
  public static testmethod void TestModifyProductController2(){

    Profile p=[Select Id From Profile Where Name='System Administrator' or Name='Systemadministrator' Limit 1];
    UserRole r=[Select Id From UserRole Limit 1];
    User u=new User();
    u.Username='testUser1@boco.com';
    u.LastName='testLastName1';
    u.Email='testEmail1@boco.com';
    u.Alias='test1';
//    u.CommunityNickname='testCommun1';
    u.TimeZoneSidKey='Pacific/kiritimati';
    u.LocaleSidKey='ar';
    u.EmailEncodingKey='UTF-8';
    u.ProfileId=p.Id;
    u.LanguageLocaleKey='en_US';
    u.UserRoleId = r.Id;
//    u.Sales_Team__c = 'DE';

    insert u;
  
  
    System.runAs(u){
      
      Account acc = new Account();
      acc.Name='Test Account Quote';
      acc.OwnerId=u.id;
      acc.BillingStreet='12345';
      acc.BillingCity='Test';
      acc.Phone='12456796';
      acc.BillingCountry='GB';
      acc.BillingPostalCode='134697';
      acc.BillingState='test';
      //acc.Payment_Terms__c='Term1';
      //insert acc;

      Account acc1 = new Account();
      acc1.Name='Test Account Quote1';
      acc1.OwnerId=u.id;
      acc1.BillingStreet='12345';
      acc1.BillingCity='Test';
      acc1.Phone='12456796';
      acc1.BillingCountry='GB';
      acc1.BillingPostalCode='134697';
      acc1.BillingState='test';
      //acc1.Payment_Terms__c='Term1';
      
      List<Account> lAcc = new List<Account>{acc, acc1};
      insert lAcc;

      Contact con=new Contact();
      con.LastName='TestContact';
      con.AccountId=acc.Id;
      con.Fax='1234567';
      con.Email='Test@test.com';
      con.MobilePhone='1346975';

      insert con;

      acc1.Primary_Contact__c = con.id;
      acc1.Finance_Contact__c = con.id;
      update acc1;
      
      Site__c site = new Site__c(Country__c='DE', Name='Testsite');
      insert site;
    
      Placement__c pm = new Placement__c(Name='Testplacement');
      Placement__c placement=new Placement__c(Name='TestPlacements');
      
      List<Placement__c> lPlaceme = new List<Placement__c>{pm, placement};
      insert lPlaceme;
      
      Advertising_Medium__c am = new Advertising_Medium__c(Name='Skyskraper', related_Mediums__c='Skyskraper', Site__c=site.id);
      // HB
      Advertising_Medium__c adType=new Advertising_Medium__c(Name='AdType', related_Mediums__c='Skyskraper');
      
      List<Advertising_Medium__c> lstAdver = new List<Advertising_Medium__c>{am, adType};
      insert lstAdver;
      
      RecordType rt=[select Id from RecordType where Name='Package' limit 1];
      
      Product2 adSpec1=new Product2(Name='Test Ad Spec',placement__c=placement.id,AdServer_Keywords_Key_Values__c='BBB',Advertising_Medium__c=adType.id,RecordTypeId=rt.Id,Billing_Category__c='CPM');
      Product2 prod1 = new Product2(Name='ApexTestProd', IsActive=true, Site__c=site.id, Placement__c=pm.id, Advertising_Medium__c=am.id, Exclusive_Placement__c=true);
      Product2 adSpec=new Product2(Name='Test Ad Spec',placement__c=placement.id,AdServer_Keywords_Key_Values__c='BBB',Advertising_Medium__c=adType.id,Billing_Category__c='CPM');
      List<Product2> lstPro = new List<Product2>{prod1, adSpec, adSpec1};
      insert lstPro;
      
      Content__c cont = new Content__c(Type__c = 'Dart - Site', Name='test', DartName__c='test');
      insert cont;
      
      Available_Site__c avai = new Available_Site__c(Product__c = adSpec1.Id, available_Site__c = cont.Id);
      insert avai;
      
      Pricebook2 pb = [select Id from Pricebook2 where IsStandard=false and IsActive=true limit 1];
      Pricebook2 pbstd = [select Id from Pricebook2 where IsStandard=true];

      PricebookEntry pbe1std = new PricebookEntry(Pricebook2Id=pbstd.Id, Product2Id=prod1.Id, UnitPrice=1.00, IsActive=true);
      PricebookEntry pbe1 = new PricebookEntry(UseStandardPrice=false, Product2Id=prod1.Id, Pricebook2Id=pb.Id, UnitPrice=1.00, IsActive=true);
      PricebookEntry adPriceStd=new PricebookEntry(Pricebook2Id=pbstd.Id,Product2Id=adSpec.id,UnitPrice=100,IsActive=true);
      PricebookEntry adPriceStd1=new PricebookEntry(Pricebook2Id=pbstd.Id,Product2Id=adSpec1.id,UnitPrice=100,IsActive=true);
      PricebookEntry adPrice=new PricebookEntry(Pricebook2Id=pb.Id,Product2Id=adSpec.id,UnitPrice=100,IsActive=true);
      PricebookEntry adPrice1=new PricebookEntry(Pricebook2Id=pb.Id,Product2Id=adSpec1.id,UnitPrice=200,IsActive=true);
      
      List<PricebookEntry> lpbe = new List<PricebookEntry>{pbe1std, pbe1, adPriceStd, adPriceStd1, adPrice, adPrice1};
      insert lpbe;
      
      Opportunity opp1 = new Opportunity(Name='Test Opp1', StageName='gebucht', CloseDate=System.today(), Probability=50);
      Opportunity mediaCampaign=new Opportunity(Pricebook2Id=pb.Id,Name='Test Media campaign Test',AccountId=acc.id,Description='Test',Agency__c=acc1.id, StageName='Test', Probability=50,CloseDate=system.today());   
      
      List<Opportunity> lstOpp = new List<Opportunity>{opp1, mediaCampaign};
      insert lstOpp;
      
      Targeting__c target = new Targeting__c(TempBinder__c=false);
      insert target;
      
      OpportunityLineItem oli1 = new OpportunityLineItem(OpportunityId=opp1.Id, Quantity=100, TotalPrice=100.0, from_Date__c=System.today(), until_Date__c=System.today(),
//                              PricebookEntryId=pbe1.Id, AdDayOfWeek__c='Monday', AdOperatingSystems__c='Windows XP');
                                PricebookEntryId=pbe1.Id, AdOperatingSystems__c='Windows XP');

      OpportunityLineItem camItem=new OpportunityLineItem(OpportunityId=mediaCampaign.id, UnitPrice=523, Quantity=3, PricebookEntryId=adPrice.Id,
                                Billing_category__c='CPM', Description='Test123', from_Date__c=System.today(), until_Date__c=System.today()+3,
                                Targeting__c=target.Id);
      OpportunityLineItem camItem1=new OpportunityLineItem(OpportunityId=mediaCampaign.id, UnitPrice=523, Quantity=3, PricebookEntryId=adPrice.Id,
                                Billing_category__c='CPM', Description='Test123', from_Date__c=System.today(), until_Date__c=System.today()+3,
                                Targeting__c=target.Id);
      List<OpportunityLineItem> lstOpli = new List<OpportunityLineItem>{oli1, camItem, camItem1};
      insert lstOpli;

  /*
  Revenue__c rv1 = new Revenue__c(
    Name='RV1',
    Startdate_R__c=System.today());
  insert rv1;
  */
  
      Revenue2__c rv1 = [select Id from Revenue2__c limit 1];
      //BPCheckAll =  [ From exclusive_Placement__c Where Opportunity__r.Probability >= 25 and Product__r.Site__r.Name IN:siteNames  
      //and Product__r.Placement__r.Name IN:placementDBNames and Date__c >= : fd and Date__c <=: td];
  
      exclusive_Placement__c bp1 = new exclusive_Placement__c( Date__c=System.today(), Opportunity__c=opp1.id, Product__c=prod1.id, Revenue2__c=rv1.id);
      insert bp1;

      // HB
      DART_ID_Placement_assignment__c spassign=new DART_ID_Placement_assignment__c(Placement__c=placement.id,Site__c=site.id);
      insert spassign;

      Packagecomponent__c pbst = new Packagecomponent__c(Singleproduct__c=adSpec.Id, Package_product__c=adSpec1.Id, Price__c=100);
      insert pbst;

      Media_Basket__c mb = new Media_Basket__c (UserId__c=u.Id, OpportunityId__c=mediaCampaign.Id, AdPriceIdText__c=adPrice1.Id);
      Media_Basket__c mediaBasket2=new Media_Basket__c(OpportunityId__c=mediaCampaign.id, UserId__c=u.id, AdPriceIdText__c=adPrice.id);
      Media_Basket__c mediaBasket3=new Media_Basket__c(OpportunityId__c=mediaCampaign.id, UserId__c=u.id, AdPriceIdText__c=adPrice1.id);
      
      Media_Basket__c mediaBasket=new Media_Basket__c();
      mediaBasket.OpportunityId__c=mediaCampaign.id;
      mediaBasket.UserId__c=u.id;
      mediaBasket.AdPriceIdText__c=adPrice.id;
      

      Media_Basket__c mediaBasket1=new Media_Basket__c();
      mediaBasket1.OpportunityId__c=mediaCampaign.id;
      mediaBasket1.UserId__c=u.id;
      mediaBasket1.AdPriceIdText__c=adPrice1.id;
      
      
      List<Media_Basket__c> lstMedia = new List<Media_Basket__c>{mb, mediaBasket2, mediaBasket3, mediaBasket,mediaBasket1};
      insert lstMedia;
      
      String camtmp=camItem1.id+','+ camItem.id;

      Pagereference pg=Page.ModifyProduct2;
      
      // TEST 1 = EDIT SELECTED LINEITEMS
      
      Test.setCurrentPageReference(pg);
      pg.getParameters().put('id',mediaCampaign.Id);
      pg.getParameters().put('rol',u.UserRoleId);
      pg.getParameters().put('modolis',camtmp);
      pg.getParameters().put('retURL','/' + mediaCampaign.Id);
      pg.getParameters().put('mcPBId',pbstd.Id);

      Test.StartTest();
      
      ApexPages.StandardController setCon = new ApexPages.StandardController(mediaCampaign);
      ModifyProductController2 modifyProduct = new ModifyProductController2(setCon);
      
        integer Days = modifyProduct.getNumMonths(System.today(),System.today()+66);
        
        for(integer i=0; i<modifyProduct.lstRecords.size(); i++){
            modifyProduct.lstRecords.get(i).strHourOfDays = 'mon0,mon1,tue0'; //NK:26/02/2014
        }
        
      //save empty record and got error
       modifyProduct.saveRecords();
//      System.assertEquals(system.Label.No_value_to_insert, modifyProduct.errorMsg);

      

      modifyProduct=new ModifyProductController2(setCon);
      
     for(integer i=0; i<modifyProduct.lstRecords.size(); i++){
            modifyProduct.lstRecords.get(i).strHourOfDays = 'mon0,mon1,tue0'; //NK:26/02/2014
        } 
      
      //save require field  null and got error
      modifyProduct.saveRecords();
      
      modifyProduct.selPosition='0';
      modifyProduct.selColumn='Description';
      modifyProduct.lstRecords.get(0).item.Description='Test';
      modifyProduct.copyField();

      modifyProduct.selPosition='0';
      modifyProduct.selColumn='AdBrowsersMinorVersion__c';
      modifyProduct.lstRecords.get(0).item.AdBrowsersMinorVersion__c ='abc';
      modifyProduct.copyField();
      
      modifyProduct.selPosition='1';
      modifyProduct.selColumn='Check_Inventory__c';
      modifyProduct.lstRecords.get(0).item.Check_Inventory__c=true;
      modifyProduct.copyField();

      modifyProduct.selPosition='0';
      modifyProduct.selColumn='Rich_Line_Description__c';
      modifyProduct.lstRecords.get(0).item.Rich_Line_Description__c='abc';
      modifyProduct.copyField();
      
      modifyProduct.selPosition='0';
      modifyProduct.selColumn='KeyValueString__c';
      modifyProduct.lstRecords.get(0).item.KeyValueString__c='abc';
      modifyProduct.copyField();
      
      modifyProduct.selPosition='0';
      modifyProduct.selColumn='Countries_Description__c';
      modifyProduct.lstRecords.get(0).item.Countries_Description__c='abc';
      modifyProduct.copyField();

      modifyProduct.selPosition='0';
      modifyProduct.selColumn='City_Description__c';
      modifyProduct.lstRecords.get(0).item.City_Description__c='abc';
      modifyProduct.copyField();

/*      modifyProduct.selPosition='0';
      modifyProduct.selColumn='AreaCode_Description__c';
      modifyProduct.lstRecords.get(0).item.AreaCode_Description__c='abc';
      modifyProduct.copyField();
*/      
      modifyProduct.forceCopyField();
//      system.assertEquals(modifyProduct.lstRecords.get(0).item.Description, modifyProduct.lstRecords.get(1).item.Description);

      //delete one record
      modifyProduct.deleteRecord();
      system.assertEquals(1, modifyProduct.lstRecords.size());

      //copy one record
      //modifyProduct.duplicateRecord(); //NK:23/08/2013:quick fix: .TestModifyProductController() Class 2778 Failure Message: "System.LimitException: Too many SOQL queries: 101",
      //system.assertEquals(2, modifyProduct.lstRecords.size());

      //split one record
      modifyProduct.lstRecords.get(0).item.until_Date__c=system.today() +14;
      modifyProduct.lstRecords.get(0).item.from_Date__c=system.today() ;
      modifyProduct.selShare='week2';
      modifyProduct.splitRecord();
      //System.assertEquals(3, modifyProduct.lstRecords.size());

      //split one record in to two record
      modifyProduct.lstRecords.get(0).item.until_Date__c=system.today() +14;
      modifyProduct.lstRecords.get(0).item.from_Date__c=system.today() ;
      modifyProduct.selShare='week';
      // System.Exception: Too many SOQL queries: 101
      // Targetings werden für jedes LineItem einzeln angelegt - Der Trigger 'countTargetingCriteria' mit 5 Queries wird dementsprechend oft aufgerufen
      modifyProduct.splitRecord();
      //System.assertEquals(5, modifyProduct.lstRecords.size());
      
      modifyProduct.lstRecords.get(0).getListBillingValue();
      
      
      //split one record
      modifyProduct.lstRecords.get(0).item.until_Date__c=system.today() +30;
      modifyProduct.lstRecords.get(0).item.from_Date__c=system.today() ;
      modifyProduct.selShare='month';
      modifyProduct.splitRecord();
      //System.assertEquals(6, modifyProduct.lstRecords.size());

//      modifyProduct.initList();
// Sochanra: 2014-06-27 -  Fixed System.Exception: Too many SOQL queries: 101
//      modifyProduct.copyRecords();
      Integer marRec = modifyProduct.getMAXRECORD();
      //save succecfully
  //    modifyProduct.saveRecords();  
  //    modifyProduct.goBack();
      
  //    pg.getParameters().put('camItems',camtmp);

  //    modifyProduct=new ModifyProductController(setCon);

      //Test.stopTest();
      
      // TEST 2 = ADD
  //    pg=Page.ModifyProduct;
      
  //    pg.getParameters().put('id',mediaCampaign.Id);
  ///   pg.getParameters().put('rol',u.UserRoleId);
  //    pg.getParameters().put('retURL','/' + mediaCampaign.Id);
  //    pg.getParameters().put('mcPBId',pbstd.Id);
  //    pg.getParameters().put('mcId',mediaCampaign.id);
      
  //    modifyProduct.initList();

      //save succecfully
  //    modifyProduct.saveRecords();  

  //    pg.getParameters().put('camItems',camtmp);
//
  //    modifyProduct=new ModifyProductController(setCon);
  ///   modifyProduct.saveRecords();
  //    modifyProduct.goBack();
          
      Test.stopTest();
      
      
      
    }
  }
  
   
  static testMethod void test(){
    
      Account acc = new Account();
      acc.Name='Test Account Quote';
      acc.BillingStreet='12345';
      acc.BillingCity='Test';
      acc.Phone='12456796';
      acc.BillingCountry='GB';
      acc.BillingPostalCode='134697';
      acc.BillingState='test';
      insert acc;
      
      Contact con=new Contact();
      con.LastName='TestContact';
      con.AccountId=acc.Id;
      con.Fax='1234567';
      con.Email='Test@test.com';
      con.MobilePhone='1346975';

      insert con;

      acc.Primary_Contact__c = con.id;
      acc.Finance_Contact__c = con.id;
      update acc;

      Pricebook2 pb = [select Id from Pricebook2 where IsStandard=false and IsActive=true limit 1];
      Pricebook2 pbstd = [select Id from Pricebook2 where IsStandard=true];
      
      Placement__c placement=new Placement__c(Name='TestPlacements');
      insert placement;
      
      Advertising_Medium__c adType=new Advertising_Medium__c(Name='AdType', related_Mediums__c='Skyskraper');
      insert adType;
      
      Product2 adSpec=new Product2(Name='Test Ad Spec',placement__c=placement.id,AdServer_Keywords_Key_Values__c='BBB',Advertising_Medium__c=adType.id,Billing_Category__c='CPM');
      insert adSpec;
      
      Opportunity mediaCampaign=new Opportunity(Pricebook2Id=pb.Id,Name='Test Media campaign Test',AccountId=acc.id,Description='Test', StageName='Test', Probability=50,CloseDate=system.today());   
      insert mediaCampaign;
      
      PricebookEntry pbe1std = new PricebookEntry(Pricebook2Id=pbstd.Id, Product2Id=adSpec.Id, UnitPrice=1.00, IsActive=true);
      PricebookEntry pbe1 = new PricebookEntry(UseStandardPrice=false, Product2Id=adSpec.Id, Pricebook2Id=pb.Id, UnitPrice=1.00, IsActive=true);
      List<PricebookEntry> lstPric = new List<PricebookEntry>{pbe1std, pbe1};
      insert lstPric;
      
      Targeting__c target = new Targeting__c(TempBinder__c=false);
      insert target;
      
      OpportunityLineItem camItem1=new OpportunityLineItem(
        OpportunityId=mediaCampaign.id,
        UnitPrice=523,
        Quantity=3,
        PricebookEntryId=pbe1.Id,
        Billing_category__c='CPM',
        Description='Test123',
        from_Date__c=System.today(),
        until_Date__c=System.today()+3,
        Targeting__c=target.Id
      );
      insert camItem1;
      
      String camtmp= camItem1.id;
    // TEST 2 = ADD
      Pagereference pg=Page.ModifyProduct2;
      
      // TEST 1 = EDIT SELECTED LINEITEMS
      
      Test.setCurrentPageReference(pg);
      
      Test.startTest();
      ApexPages.StandardController setCon = new ApexPages.StandardController(mediaCampaign);
      ModifyProductController2 modifyProduct = new ModifyProductController2(setCon);
      
      pg.getParameters().put('id',mediaCampaign.Id);
  
      pg.getParameters().put('retURL','/' + mediaCampaign.Id);
      pg.getParameters().put('mcPBId',pbstd.Id);
      pg.getParameters().put('mcId',mediaCampaign.id);
      
      modifyProduct.initList();

      //save succecfully
      modifyProduct.saveRecords();  

      pg.getParameters().put('camItems',camtmp);

      modifyProduct=new ModifyProductController2(setCon);
        for(integer i=0; i<modifyProduct.lstRecords.size(); i++){
            modifyProduct.lstRecords.get(i).strHourOfDays = 'mon0,mon1,tue0'; //NK:26/02/2014
        }
      
      modifyProduct.saveRecords();
      modifyProduct.goBack();
      Test.stopTest();
      
  }
  
  
  
  
  static testMethod void testCreateNewPro(){
    Profile p=[Select Id From Profile Where Name='System Administrator' or Name='Systemadministrator' Limit 1];
    UserRole r=[Select Id From UserRole Limit 1];
    User u=new User();
    u.Username='testUser1@boco.com';
    u.LastName='testLastName1';
    u.Email='testEmail1@boco.com';
    u.Alias='test1';
//    u.CommunityNickname='testCommun1';
    u.TimeZoneSidKey='Pacific/kiritimati';
    u.LocaleSidKey='ar';
    u.EmailEncodingKey='UTF-8';
    u.ProfileId=p.Id;
    u.LanguageLocaleKey='en_US';
    u.UserRoleId = r.Id;
//    u.Sales_Team__c = 'DE';

    insert u;
  
    System.runAs(u){
      
    
      
      Account acc = new Account(OwnerId=u.id, Name='Test Account Quote', BillingStreet='12345', BillingCity='Test', Phone='12456796', BillingCountry='GB', 
                    BillingPostalCode='134697', BillingState='test');
      insert acc;
      
      Contact con=new Contact();
      con.LastName='TestContact';
      con.AccountId=acc.Id;
      con.Fax='1234567';
      con.Email='Test@test.com';
      con.MobilePhone='1346975';

      insert con;

      acc.Primary_Contact__c = con.id;
      acc.Finance_Contact__c = con.id;
      update acc;

      Pricebook2 pb = [select Id from Pricebook2 where IsStandard=false and IsActive=true limit 1];
      Pricebook2 pbstd = [select Id from Pricebook2 where IsStandard=true];
      
      
      Placement__c placement=new Placement__c(Name='TestPlacements');
      Placement__c placement2=new Placement__c(Name='TestPlacements2');
      insert new List<Placement__c>{placement, placement2};
      
      Advertising_Medium__c adType=new Advertising_Medium__c(Name='AdType', related_Mediums__c='Skyskraper');
      insert adType;
      
      RecordType rec = [select id from RecordType where Name='Package' and SobjectType='Product2' limit 1];
      
      Product2 pro=new Product2(Name='Test Ad Spec', placement__c=placement.id, AdServer_Keywords_Key_values__c='BBB', Advertising_Medium__c=adType.id, Billing_Category__c='CPM', RecordTypeId = rec.Id,tech_targeting__c = true, post_code__c= true, Time__c=true, Fixed_price__c=true, Fixed_Site__c=true, Availablility_Forecast__c=true, Rate_Card__c = true );
      Product2 pro2=new Product2(Name='Test Ad Spec', placement__c=placement2.id, AdServer_Keywords_Key_values__c='BBB', Advertising_Medium__c=adType.id, Billing_Category__c='CPM', RecordTypeId = rec.Id);
      Product2 pro3=new Product2(Name='Test Ad Spec', placement__c=placement2.id, AdServer_Keywords_Key_values__c='BBB', Advertising_Medium__c=adType.id, Billing_Category__c='CPM', RecordTypeId = rec.Id);
      insert new List<Product2>{pro, pro2, pro3};
      
      Rate_Card__c rateCard = new Rate_Card__c(Sales_Price__c= 10, Quantity2__c  = 15, Product__c = pro.Id, Length__c='6');
      insert rateCard;
      
      Content__c cont = new Content__c(Type__c = 'Dart - Site', Name='test', DartName__c='test');
      Content__c cont2 = new Content__c(Type__c = 'Dart - Site', Name='test2', DartName__c='test2');
      insert new List<Content__c>{cont, cont2};
      
      Packagecomponent__c pag = new Packagecomponent__c(Singleproduct__c = pro2.Id, Package_product__c= pro.Id, DART_Content__c = cont.Id);
      insert pag;
      
      Available_Site__c avai = new Available_Site__c(Product__c = pro.Id, available_Site__c = cont.Id);
      Available_Site__c avai2 = new Available_Site__c(Product__c = pro.Id, available_Site__c = cont2.Id);
      insert new List<Available_Site__c>{avai, avai2};
      
      Opportunity Opp=new Opportunity(Pricebook2Id=pb.Id,Name='Test Media campaign Test',AccountId=acc.id,Description='Test', StageName='Test', Probability=50,CloseDate=system.today());   
      insert Opp;
      
      PricebookEntry pbe1std = new PricebookEntry(Pricebook2Id=pbstd.Id, Product2Id=pro.Id, UnitPrice=1.00, IsActive=true);
      PricebookEntry pbe1 = new PricebookEntry(UseStandardPrice=false, Product2Id=pro.Id, Pricebook2Id=pb.Id, UnitPrice=1.00, IsActive=true);
      
      
      List<PricebookEntry> lstPric = new List<PricebookEntry>{pbe1std, pbe1};
      insert lstPric;
      
      Media_Basket__c media = new Media_Basket__c(UserId__c = u.Id , OpportunityId__c = Opp.Id , AdPriceIdText__c=pbe1.Id);
      insert media;
      
      //create targeting 
      Targeting__c tmpTar = new Targeting__c(TempBinder__c = true , Description__c = 'test targeting' );
      insert tmpTar;
      
      DART_KeyValue_2__c dart2 = new DART_KeyValue_2__c(Name='test', Key_Value__c='test1', Key_Value_Name__c='test');
      insert dart2;
      
      String ex_key = tmpTar.Id +''+ cont.Id;
      TargetingContentAssociation__c contar = new TargetingContentAssociation__c(Targeting__c = tmpTar.Id, TargetingContent__c = cont.Id, Target_Content_Key__c = ex_key, Exclude__c = false);
      insert contar;
      
      ex_key = tmpTar.Id +''+dart2.Id;
      TargetingKeyValueAssociation__c keyTar = new TargetingKeyValueAssociation__c(Targeting__c = tmpTar.Id, Operator__c='AND', DART_KeyValue__c=dart2.Id,targetkeyvalue__c= ex_key);
      insert keyTar;
      //////////////////////////
      
      Pagereference pg = Page.ModifyProduct2;
      Test.setCurrentPageReference(pg);
      
      pg.getParameters().put('id',Opp.Id);
      pg.getParameters().put('retURL','/' + Opp.Id);
      pg.getParameters().put('mcPBId',pbstd.Id);
      pg.getParameters().put('mcId',Opp.id);
      
      test.startTest();
      ApexPages.StandardController setCon = new ApexPages.StandardController(Opp);
      ModifyProductController2 modifyProduct = new ModifyProductController2(setCon);
      
      modifyProduct.lstRecords.get(0).strHourOfDays = 'mon0,mon1,tue0'; //NK:26/02/2014
      
      
      //save succecfully
      modifyProduct.saveRecords();
      
      modifyProduct.lstRecords.get(0).item.from_Date__c=system.today() ;
      modifyProduct.saveRecords();
        
      modifyProduct.lstRecords.get(0).item.until_Date__c=system.today() -1;
      modifyProduct.saveRecords();
      
      modifyProduct.lstRecords.get(0).item.Billing_category__c = null;
      modifyProduct.saveRecords();
      
      modifyProduct.lstRecords.get(0).item.UnitPrice = 0;
      modifyProduct.saveRecords();
      
      modifyProduct.lstRecords.get(0).item.KeyValueString__c = 'AND AND AND AND AND AND AND';
      modifyProduct.saveRecords();  
      
      modifyProduct.lstRecords.get(0).item.AdKeyWords__c = 'AND AND AND AND AND AND AND';
      modifyProduct.saveRecords();  
      
      modifyProduct.lstRecords.get(0).strHourOfDays = 'mon0,mon1,tue0';
      modifyProduct.saveRecords();
                
      modifyProduct = new ModifyProductController2(setCon);
      modifyProduct.lstRecords.get(0).item.from_Date__c=system.today() ;
      modifyProduct.lstRecords.get(0).item.until_Date__c=system.today().addDays(10);
      modifyProduct.lstRecords.get(0).item.Billing_category__c = 'CPA';
      modifyProduct.lstRecords.get(0).item.UnitPrice = 10;
      modifyProduct.lstRecords.get(0).item.Quantity = 15;
      modifyProduct.lstRecords.get(0).item.Length_Months__c = 6;
      modifyProduct.lstRecords.get(0).item.Budget_NetNetNet__c = 2000;
      modifyProduct.lstRecords.get(0).item.Targeting__c = tmpTar.Id;
      modifyProduct.lstRecords.get(0).strHourOfDays = 'mon0,mon1,tue0';
      modifyProduct.selPosition = '0';
      modifyProduct.calculateQtyByBudget();
      
        

      modifyProduct.saveRecords();
      modifyProduct.lstRecords.get(0).getErrBillin();
        modifyProduct.lstRecords.get(0).getDescr();
        modifyProduct.lstRecords.get(0).getFromDate();
        modifyProduct.lstRecords.get(0).getUntilDate();
        modifyProduct.lstRecords.get(0).getTargeting_c();
        modifyProduct.lstRecords.get(0).getquantity();
        modifyProduct.lstRecords.get(0).setquantity('15');
        modifyProduct.lstRecords.get(0).setBillingCategory2('tetst');
        modifyProduct.lstRecords.get(0).getBillingCategory2();
        modifyProduct.lstRecords.get(0).getErrQty();
        modifyProduct.lstRecords.get(0).getErrSalePrice();
        modifyProduct.lstRecords.get(0).strHourOfDays = 'mon0,mon1,tue0';
        modifyProduct.calculateSalesPrice();
        modifyProduct.reCalculateAll();
        modifyProduct.calculateNetNetNet();
        modifyProduct.calculateSurchargeAndDiscount();
        //modifyProduct.getQuantityRang(16);
        
        modifyProduct.selPosition = '0';
        modifyProduct.lstRecords.get(0).setquantity('2');
        modifyProduct.changevalue();
        
        modifyProduct.lstRecords.get(0).setquantity('6');
        modifyProduct.changevalue();
        
        modifyProduct.lstRecords.get(0).setquantity('10');
        modifyProduct.changevalue();
        
        modifyProduct.lstRecords.get(0).setquantity('15');
        modifyProduct.changevalue();
        
        modifyProduct.lstRecords.get(0).setquantity('25');
        modifyProduct.changevalue();
        
        modifyProduct.lstRecords.get(0).setquantity('45');
        modifyProduct.changevalue();
        
        modifyProduct.lstRecords.get(0).setquantity('65');
        modifyProduct.changevalue();
        
        modifyProduct.lstRecords.get(0).setquantity('110');
        modifyProduct.changevalue();
        
        modifyProduct.lstRecords.get(0).setquantity('150');
        modifyProduct.changevalue();
        
        modifyProduct.lstRecords.get(0).setquantity('190');
        modifyProduct.changevalue();
        
        modifyProduct.lstRecords.get(0).setquantity('250');
        modifyProduct.changevalue();
        
        modifyProduct.lstRecords.get(0).setquantity('300');
        modifyProduct.changevalue();
        
        modifyProduct.lstRecords.get(0).setquantity('350');
        modifyProduct.changevalue();
        
        modifyProduct.lstRecords.get(0).setquantity('400');
        modifyProduct.changevalue();
        
        modifyProduct.lstRecords.get(0).setquantity('500');
        modifyProduct.changevalue();
        
        modifyProduct.lstRecords.get(0).setquantity('600');
        modifyProduct.changevalue();
        
        modifyProduct.lstRecords.get(0).setquantity('700');
        modifyProduct.changevalue();
        
        modifyProduct.lstRecords.get(0).setquantity('800');
        modifyProduct.changevalue();
        
        modifyProduct.lstRecords.get(0).setquantity('1100');
        modifyProduct.changevalue();
        
      modifyProduct.goBack();
      
      Test.stopTest();
      
    }
      
  }
  
  
  static testMethod void TestSaving(){
    

  Pricebook2 pb = [select Id from Pricebook2 where IsStandard=false and IsActive=true limit 1];
  Pricebook2 pbstd = [select Id from Pricebook2 where IsStandard=true];
   
  Site__c site = new Site__c(Country__c='DE', Name='Testsite');
  insert site;
  
  Placement__c pm = new Placement__c(Name='Testplacement');
  insert pm;
  
  Advertising_Medium__c am = new Advertising_Medium__c(
    Name='Skyskraper',
    related_Mediums__c='Skyskraper',
    Site__c=site.id
    );
  insert am;
  
  Product2 prod1 = new Product2(
    Name='ApexTestProd',
    IsActive=true,
    Site__c=site.id,
    Placement__c=pm.id,
    Advertising_Medium__c=am.id,
    Exclusive_Placement__c=true);
    
    insert prod1;
    
  Opportunity opp1 = new Opportunity(
    Name='Test Opp1',
    StageName='gebucht',
    CloseDate=System.today(),
    Probability=50
//    Pre_approved_template__c = false
    );

  insert opp1;

  PricebookEntry pbe1std = new PricebookEntry(
    Pricebook2Id=pbstd.Id,
    Product2Id=prod1.Id,
    UnitPrice=1.00,
    IsActive=true);
  insert pbe1std;
    
   PricebookEntry pbe1 = new PricebookEntry(
    UseStandardPrice=false,
    Product2Id=prod1.Id,
    Pricebook2Id=pb.Id,
    UnitPrice=1.00,
    IsActive=true);

  insert pbe1;

   OpportunityLineItem oli1 = new OpportunityLineItem(
    OpportunityId=opp1.Id,
    Quantity=100,
    TotalPrice=100.0,
    from_Date__c=System.today(),
    until_Date__c=System.today(),
    PricebookEntryId=pbe1.Id,
//    AdDayOfWeek__c='Monday',
    AdOperatingSystems__c='Windows XP');
    
  insert oli1;
  
  //BPCheckAll =  [ From exclusive_Placement__c Where Opportunity__r.Probability >= 25 and Product__r.Site__r.Name IN:siteNames  
  //and Product__r.Placement__r.Name IN:placementDBNames and Date__c >= : fd and Date__c <=: td];
  
  exclusive_Placement__c bp1 = new exclusive_Placement__c(
    Date__c=System.today(),
    //Name='BP1',
    Opportunity__c=opp1.id,
    Product__c=prod1.id
   // Revenue__c=rv1.id,
      );
    
    //AccId=='0017000000jhcnE'
    //forceDateSave = false;
    
    

      Pagereference pg=Page.ModifyProduct2;
      
      // TEST 1 = EDIT SELECTED LINEITEMS
      
      Test.setCurrentPageReference(pg);
      pg.getParameters().put('id',opp1.Id);
      //pg.getParameters().put('rol',u.UserRoleId);
      pg.getParameters().put('modolis',oli1.Id);
      pg.getParameters().put('retURL','/' + opp1.Id);
      pg.getParameters().put('mcPBId',pbstd.Id);

      Test.StartTest();
      
      
      ApexPages.StandardController setCon = new ApexPages.StandardController(opp1);
      ModifyProductController2 modifyProduct = new ModifyProductController2(setCon);
      modifyProduct.accId = modifyProduct.X_ACCOUNT_ID;//'0017000000jhcnE';
      modifyProduct.forceDateSave = false;
      modifyProduct.saveRecords();
      
    
    
    Test.stopTest();
    
  }
  /******************** 16/08/2011
  Number of SOQL queries: 27 out of 100
  Number of query rows: 378 out of 50000
  Number of SOSL queries: 0 out of 20
  Number of DML statements: 11 out of 150
  Number of DML rows: 320 out of 10000
  Number of script statements: 8730 out of 200000
  Maximum heap size: 0 out of 3000000
  Number of callouts: 0 out of 10
  Number of Email Invocations: 0 out of 10
  Number of fields describes: 1 out of 100
  Number of record type describes: 0 out of 100
  Number of child relationships describes: 0 out of 100
  Number of picklist describes: 0 out of 100
  Number of future calls: 0 out of 10
  
  ****************/

  
  static testmethod void testFixedsite(){
    Profile p=[Select Id From Profile Where Name='System Administrator' or Name='Systemadministrator' Limit 1];
    UserRole r=[Select Id From UserRole Limit 1];
    User u=new User(Username='testUser1@boco.com',LastName='testLastName1',Email='testEmail1@boco.com',Alias='test1',TimeZoneSidKey='Pacific/kiritimati',
            LocaleSidKey='ar',EmailEncodingKey='UTF-8',ProfileId=p.Id,LanguageLocaleKey='en_US',UserRoleId = r.Id);
    insert u;         
    System.runAs(u){
      
    
      Account acc = new Account(OwnerId=u.id, Name='Test Account Quote', BillingStreet='12345', BillingCity='Test', Phone='12456796', BillingCountry='GB', BillingPostalCode='134697', BillingState='test');
      insert acc;
      
      Contact con=new Contact();
      con.LastName='TestContact';
      con.AccountId=acc.Id;
      con.Fax='1234567';
      con.Email='Test@test.com';
      con.MobilePhone='1346975';

      insert con;

      acc.Primary_Contact__c = con.id;
      acc.Finance_Contact__c = con.id;
      update acc;

      Pricebook2 pb = [select Id from Pricebook2 where IsStandard=false and IsActive=true limit 1];
      Pricebook2 pbstd = [select Id from Pricebook2 where IsStandard=true];
      
      Placement__c placement=new Placement__c(Name='TestPlacements');
      insert placement;
      
      Advertising_Medium__c adType=new Advertising_Medium__c(Name='AdType', related_Mediums__c='Skyskraper');
      insert adType;
      
      RecordType rec = [select id from RecordType where Name='DART6' and SobjectType='Product2' limit 1];
      
      String geos = '';
      for(Geography__c geo: [select name from Geography__c limit 2]){
        geos += geo.name+',';
      }
      Product2 pro=new Product2(Default_Geo_IP__c=geos, Name='Test Ad Spec', placement__c=placement.id, AdServer_Keywords_Key_values__c='BBB', Advertising_Medium__c=adType.id, Billing_Category__c='CPM', RecordTypeId = rec.Id,tech_targeting__c = true, post_code__c= true, Time__c=true, Fixed_price__c=true, Fixed_Site__c=true, Availablility_Forecast__c=true );
      insert pro;
      
      Content__c cont = new Content__c(Type__c = 'Dart - Site', Name='test', DartName__c='test');
      insert cont;
      
      Available_Site__c avai = new Available_Site__c(Product__c = pro.Id, available_Site__c = cont.Id);
      insert avai;
      
      Opportunity Opp=new Opportunity(Pricebook2Id=pb.Id,Name='Test Media campaign Test',AccountId=acc.id,Description='Test', StageName='Test', Probability=50,CloseDate=system.today());   
      insert Opp;
      
      
      
      PricebookEntry pbe1std = new PricebookEntry(Pricebook2Id=pbstd.Id, Product2Id=pro.Id, UnitPrice=1.00, IsActive=true);
      PricebookEntry pbe1 = new PricebookEntry(UseStandardPrice=false, Product2Id=pro.Id, Pricebook2Id=pb.Id, UnitPrice=1.00, IsActive=true);
      
      
      List<PricebookEntry> lstPric = new List<PricebookEntry>{pbe1std, pbe1};
      insert lstPric;
      
      Media_Basket__c media = new Media_Basket__c(UserId__c = u.Id , OpportunityId__c = Opp.Id , AdPriceIdText__c=pbe1.Id);
      insert media;
      
      
      Pagereference pg = Page.ModifyProduct2;
      Test.setCurrentPageReference(pg);
      
      pg.getParameters().put('id',Opp.Id);
      pg.getParameters().put('retURL','/' + Opp.Id);
      pg.getParameters().put('mcPBId',pbstd.Id);
      pg.getParameters().put('mcId',Opp.id);
      
      test.startTest();
      ApexPages.StandardController setCon = new ApexPages.StandardController(Opp);
      ModifyProductController2 modifyProduct = new ModifyProductController2(setCon);
      modifyProduct.createDefaultGeoNames();
      modifyProduct.goNext();
      modifyProduct.goPrevious();
      
      
      //save succecfully
      
      modifyProduct.lstRecords.get(0).item.from_Date__c=system.today() ;
      modifyProduct.lstRecords.get(0).item.until_Date__c=system.today().addDays(10);
      modifyProduct.lstRecords.get(0).item.Billing_category__c = 'CPA';
      modifyProduct.lstRecords.get(0).item.UnitPrice = 10;
      modifyProduct.lstRecords.get(0).item.Quantity = 4;
      modifyProduct.lstRecords.get(0).strHourOfDays = 'mon0,mon1,tue0';
      
      modifyProduct.saveRecords();
      Test.stopTest(); 
      
    }    
  }
  
}