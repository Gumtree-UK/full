public class SortOpplineController {
    
    public List<String> item {get;set;}
    public List<String> items {get;set;}
    public String idProAfterSort {get;set;}
    public String idSelected {get;set;}
    public String idOpp;
    private List<SelectOption> listKeyOli = new List<SelectOption>();
    
    public SortOpplineController(ApexPages.StandardController controller){
        idOpp = ApexPages.currentPage().getParameters().get('id');
        idProAfterSort = '';
        idSelected = '';
        
        init();
    }
    
    
    private Pagereference init(){ 
        lstDtoLineItem=new List<DtoLineItem> ();
            for(OpportunityLineItem oli: [Select SortOrder, Id,PricebookEntry.Name, PricebookEntry.Product2.Name, Quantity, Description, from_Date__c, until_Date__c From OpportunityLineItem where OpportunityId=:idOpp order by SortOrder]){
                
                String description='';
                String body = oli.PricebookEntry.Name + ' - ' + system.label.Quantity + ': ' + Integer.valueOf((oli.Quantity == null? 0: oli.Quantity)) + ' - ' + system.label.From_Date + ': ' + Date.valueOf(oli.from_Date__c).format() + ' - ' + system.label.Until_Date+ ': ' + Date.valueOf(oli.until_Date__c).format();
                if(oli.Description != null && String.valueOf(oli.Description).length() <= 150){
                    body += ' - ' + system.label.Description + ': ' + oli.Description;
                    description=oli.Description;
                }else if(oli.Description != null  && String.valueOf(oli.Description).length() > 150){
                    body += ' - ' + system.label.Description + ': ' + String.valueOf(oli.Description).substring(0,150) + '...';
                    description=String.valueOf(oli.Description).substring(0,150) + '...';
                }
                
                
                listKeyOli.add(new SelectOption(oli.Id, body));     
                
                //new DtoLineItem
                DtoLineItem newItem=new DtoLineItem(oli.Id,(oli.SortOrder==null? '':oli.SortOrder + ''),oli.PricebookEntry.Name,Integer.valueOf((oli.Quantity == null? 0: oli.Quantity))+'',+Date.valueOf(oli.from_Date__c).format(),Date.valueOf(oli.until_Date__c).format(),description,oli.Description);
                lstDtoLineItem.add(newItem);
            }

        
        return null;
    }
    
    public List<SelectOption> getSubItem(){
        return listKeyOli;
    }
    
    public Pagereference cancelPage(){
        return new Pagereference('/' + idOpp);
    }
    
    
    
    
    
    public Pagereference doSave(){
        if(listKeyOli.isEmpty()){
            return new Pagereference('/'+idOpp);
        }

        String duel0 = ''; //sort list order
        for(String str: idProAfterSort.split(',')){
            str = str.trim();           
            duel0 += str.substring(0,str.length() -3) + '%2C';
        }

        duel0 = duel0.substring(0,duel0.length() -3);
        //String URL = 'https://tapp0.salesforce.com/oppitm/lineitemsort.jsp?id=' + idOpp + '&retURL=%2F' + idOpp + '&duel0=' + duel0 + '&save_new_url=%2Foppitm%2Flineitemsort.jsp%3FretURL%3D%252F' + idOpp + '&oli_Select=' + item + '&save=+Save+';
        
        //https://tapp0.salesforce.com/oppitm/lineitemsort.jsp?id=006T0000008PYvl&retURL=%2F006T0000008PYvlIAG&duel0=00kT0000006XMGR%2C00kT0000006XMGS&save_new_url=%2Foppitm%2Flineitemsort.jsp%3FretURL%3D%252F006T0000008PYvlIAG&duel_select_0=00kT0000006XMGS&save=+Save+
        //https://tapp0.salesforce.com/oppitm/lineitemsort.jsp?id=006T0000008PYvl&retURL=/006T0000008PYvlIAG&duel0=00kT0000006XMGR,00kT0000006XMGS&save_new_url=/oppitm/lineitemsort.jsp?retURL=/006T0000008PYvlIAG&oli_Select=00kT0000006XMGS&save=+Save+
        idSelected = idSelected.substring(0, idSelected.length() -3);
        
        String url_sorder =  SORTORDER_URL;
         
        
        url_sorder = url_sorder.replace('$OPPID$',idOpp).replace('$ITEMIDS$',duel0).replace('$RETID$',idOpp).replace('$RETID2$',idOpp).replace('$SELIITEM$',idSelected);
        
        return new Pagereference(url_sorder);
    }
    
    final static String SORTORDER_URL = '/oppitm/lineitemsort.jsp?id=$OPPID$&retURL=%2F$RETID$&duel0=$ITEMIDS$&save_new_url=%2Foppitm%2Flineitemsort.jsp%3FretURL%3D%252F=$RETID2$&oli_Select=$SELIITEM$&save=+Save+';
    
    
    
    
    
    
    //@Kim Soksamnang 26-08-2011: Update UI 
    
    //Data Model
    
    public List<DtoLineItem> lstDtoLineItem{get;set;}
    public class DtoLineItem{
        public DtoLineItem(
         String pId,
         String pSortOrder,
         String pProduct2Name,
         String pQuantity,
         String pfrom_Date,
         String puntil_Date,
         String pDescription,
         String pFullDescription){
             this.pId=pId;
            this.pSortOrder=pSortOrder;
            this.pProduct2Name=pProduct2Name;
            this.pQuantity=pQuantity;
            this.pfrom_Date=pfrom_Date;
            this.puntil_Date=puntil_Date;
            this.pDescription=pDescription;
            this.pFullDescription=pFullDescription;
            
            
            
        }
        public String pid{get;set;}
        public String pSortOrder{get;set;}
        public String pProduct2Name{get;set;}
        public String pQuantity{get;set;}
        public String pfrom_Date{get;set;}
        public String puntil_Date{get;set;}
        public String pDescription{get;set;}
        public String pFullDescription{get;set;}
        

    }
    
    
    private static testmethod void test(){
        Account acc = new Account(Name='test1', BillingStreet='Test Street1', BillingCity='Test city1', 
        BillingPostalCode='1234', BillingCountry='CA');
        insert acc;
    
        Contact con = new Contact();
        con.LastName='TestContact';
        con.AccountId=acc.Id;
        con.Fax='1234567';
        con.Email='Test@test.com';
        con.MobilePhone='1346975';
        insert con;
    
        acc.Primary_Contact__c = con.id;
        acc.Finance_Contact__c = con.id;
        update acc;
    
        Product2 pro = new product2(name='Test Product');
        insert pro;
        
        Pricebook2 stdPb = [select Id,Name from Pricebook2 where isStandard=true limit 1];
        
        Site__c site = new Site__c(Name='Testsite');
        insert site;
        
        Placement__c pm = new Placement__c(Name='Testplacement');
        insert pm;
        
        Advertising_Medium__c am = new Advertising_Medium__c(Name='Skyscraper');
        insert am;
        
        Product2 prod1 = new Product2(Name='ApexTestProd', IsActive=true, Site__c=site.id, Placement__c=pm.id, Advertising_Medium__c=am.id, Exclusive_Placement__c=true);
        insert prod1;
    
        Opportunity opp1 = new Opportunity(Type='Existing Business',AccountId = acc.id,Name='Test Opp1', StageName='Erstes Interesse', CloseDate=System.today(), Probability=10);
        insert opp1;
    
        PricebookEntry pbe1std = new PricebookEntry(Pricebook2Id=stdPb.Id, Product2Id=pro.Id, UnitPrice=1.00, IsActive=true);
        insert pbe1std;
        
        List<OpportunityLineItem> loli = new List<OpportunityLineItem>();
        OpportunityLineItem oli1 = new OpportunityLineItem(OpportunityId=opp1.Id, Quantity=100, TotalPrice=100.0, from_Date__c=System.today(), until_Date__c=System.today(), PricebookEntryId=pbe1std.Id, AdWeekDays__c='Monday', AdOperatingSystems__c='Windows XP');
        loli.add(oli1);
        
        OpportunityLineItem oli2 = new OpportunityLineItem(OpportunityId=opp1.Id, Quantity=100, TotalPrice=100.0, from_Date__c=System.today(), until_Date__c=System.today(), PricebookEntryId=pbe1std.Id, AdWeekDays__c='Monday', AdOperatingSystems__c='Windows XP');
        loli.add(oli2);
        insert loli;
        
        ApexPages.StandardController stand = new ApexPages.StandardController(opp1);
        
        SortOpplineController sOliC = new SortOpplineController(stand);
//        sOliC.idProAfterSort = oli2 + ',' + oli1 ;
        
        sOliC.doSave();
        sOliC.idOpp = opp1.Id;
        System.debug('==================================id:' + sOliC.idOpp);
        sOliC.init();
        sOliC.getSubItem();
        sOliC.cancelPage();
    }
    
}