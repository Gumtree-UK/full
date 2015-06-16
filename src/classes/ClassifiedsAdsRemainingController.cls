public class ClassifiedsAdsRemainingController {

private String soql {get;set;}

public String site;
public String siteName;
public String getSite() { return this.site; }
public void setSite(String s) { this.site = s; }
 
public String pstatus = 'Overusage';
public String getPstatus() { return this.pstatus; }
public void setPstatus(String ps) { this.pstatus = ps; }

public String accstatus = 'Active';
public String getaccstatus() { return this.accstatus; }
public void setaccstatus(String accs) { this.accstatus = accs; }

public Decimal burnrate = 100.0;
public Decimal getBurnrate() { return this.burnrate; }
public void setBurnRate(Decimal br) { this.burnrate = br; }

public Integer creditr = 5000;
public Integer getcreditr() { return this.creditr; }
public void setcreditr(Integer cr) { this.creditr = cr; }

public Integer dayr = 5000;
public Integer getdayr() { return this.dayr; }
public void setdayr(Integer cr) { this.dayr = cr; }

public map<id,string> SiteMap = new map<id,string>();

public String sortField {
    get  { if (sortField == null) {sortField = 'lastName'; } return sortField;  }
    set;
  }
  
// format the soql for display on the visualforce page
  public String debugSoql {
    get { return soql + ' Package Status: ' + pstatus + ' Account Status: ' + accstatus + ' Credits Remain: ' + creditr + ' Burn Rate: ' + burnrate + ' LIMIT 20'; }
    set;
  }

public List<SelectOption> getSites() {
  List<SelectOption> optionList = new List<SelectOption>();
     optionList.add(new SelectOption('','- None -'));
      for (Site__c site : [select name from Site__c WHERE RecordTypeId = '01220000000YaOgAAK' ORDER BY name]){
          optionList.add(new SelectOption(site.id,site.name));
          SiteMap.put(site.id,site.name);
      }
  return optionList;     
}

public string getSiteName (){
    siteName = SiteMap.get(site);
    return siteName;
}

public List<SelectOption> getpstatuses() {
  List<SelectOption> optionList = new List<SelectOption>();
      for (OpportunityLineItem pstatus : [select Package_Status__c from OpportunityLineItem LIMIT 1])
        optionList.add(new SelectOption('Overusage', 'Overusage'));
        optionList.add(new SelectOption('Active', 'Active'));        
        optionList.add(new SelectOption('Expired', 'Expired'));
  return optionList;     
}

public List<SelectOption> getaccstatuses() {
  List<SelectOption> optionList = new List<SelectOption>();
      for (OpportunityLineItem accstatus : [select Opportunity.Account.Account_Status__c from OpportunityLineItem LIMIT 1])
        optionList.add(new SelectOption('Active', 'Active'));
        optionList.add(new SelectOption('Suspended - Bad Debt', 'Suspended'));        
        optionList.add(new SelectOption('Collection Agency', 'Collection Agency'));
  return optionList;     
}

public List<SelectOption> getburnrates() {
  List<SelectOption> optionList = new List<SelectOption>();
      for (OpportunityLineItem burnrate : [select Credit_Burn_Rate__c from OpportunityLineItem LIMIT 1])
        optionList.add(new SelectOption('1000', '- None -'));
        optionList.add(new SelectOption('0.26', '< 0.25'));
        optionList.add(new SelectOption('0.51', '< 0.50'));
        optionList.add(new SelectOption('0.76', '< 0.75'));
        optionList.add(new SelectOption('1.01', '< 1.00'));
        optionList.add(new SelectOption('1.26', '< 1.25'));
        optionList.add(new SelectOption('1.51', '< 1.50'));
        optionList.add(new SelectOption('1.76', '< 1.75'));
        optionList.add(new SelectOption('2.01', '< 2.00'));
        optionList.add(new SelectOption('2.56', '< 2.50'));
        optionList.add(new SelectOption('3.01', '< 3.00'));
        optionList.add(new SelectOption('3.56', '< 3.50'));
        optionList.add(new SelectOption('4.01', '< 4.00'));
        optionList.add(new SelectOption('4.51', '< 4.50'));
        optionList.add(new SelectOption('5.01', '< 5.00'));                                                                     
  return optionList;     
}

public List<SelectOption> getcreditsr() {
  List<SelectOption> optionList = new List<SelectOption>();
      for (OpportunityLineItem creditr : [select Credits_Remaining__c from OpportunityLineItem LIMIT 1])
        optionList.add(new SelectOption('5000', '- None -'));
        optionList.add(new SelectOption('0','0'));
        optionList.add(new SelectOption('11', '< 10'));
        optionList.add(new SelectOption('21', '< 20'));
        optionList.add(new SelectOption('31', '< 30'));        
        optionList.add(new SelectOption('41', '< 40'));                
        optionList.add(new SelectOption('51', '< 50'));                
  return optionList;     
}

public List<SelectOption> getdaysr() {
  List<SelectOption> optionList = new List<SelectOption>();
      for (OpportunityLineItem dayr : [select Days_Remaining__c from OpportunityLineItem LIMIT 1])
        optionList.add(new SelectOption('365', '- None -'));
        optionList.add(new SelectOption('0', '0'));
        optionList.add(new SelectOption('8', '< 7'));
        optionList.add(new SelectOption('15', '< 14'));
        optionList.add(new SelectOption('31', '< 30'));        
        optionList.add(new SelectOption('61', '< 60'));                
        optionList.add(new SelectOption('91', '< 90'));                
  return optionList;     
}

       public list<OpportunityLineItem> getolistdcredit() {
           return [SELECT Id, Opportunity.Account.Name, Opportunity.Account.Owner.Id, Opportunity.Account.Package_Status__c,
                              Opportunity.Account.Account_Status__c, PricebookEntry.Product2.ProductCode, PricebookEntry.Product2.Name, 
                              Quantity, Credits_Used__c, Credits_Remaining__c, Package_Status__c, Credit_Burn_Rate__c,
                              Days_remaining__c, PricebookEntry.Product2.Product_Subtype__c, until_Date__c, PriceBookEntry.Product2.Site__r.Name,
                              Length_Months__c
                              FROM OpportunityLineItem
                   WHERE (PricebookEntry.Product2.ProductCode = 'STD' OR PricebookEntry.Product2.ProductCode = 'STDROUK')
                   AND Package_Status__c = :pstatus
                   AND Opportunity.Account.Owner.Id = :UserInfo.getUserId()
                   AND Days_Remaining__c < :dayr
                   AND PriceBookEntry.Product2.Site__c = :site
                   AND Opportunity.Account.Account_Status__c = :accstatus
                   AND Credit_Burn_Rate__c < :burnrate
                   AND Credits_Remaining__c < :creditr
                   ORDER BY Credits_Remaining__c ASC
                   LIMIT 100];
      }
      
    public list<OpportunityLineItem> getoliftd3credit() {
           return [SELECT Id, Opportunity.Account.Name, Opportunity.Account.Owner.Id, Opportunity.Account.Package_Status__c,
                              Opportunity.Account.Account_Status__c, PricebookEntry.Product2.ProductCode, PricebookEntry.Product2.Name, 
                              Quantity, Credits_Used__c, Credits_Remaining__c, Package_Status__c, Credit_Burn_Rate__c,
                              Days_remaining__c, PricebookEntry.Product2.Product_Subtype__c, until_Date__c, PriceBookEntry.Product2.Site__r.Name,
                              Length_Months__c 
                              FROM OpportunityLineItem
                   WHERE (PricebookEntry.Product2.ProductCode = 'FTD3' OR PricebookEntry.Product2.ProductCode = 'FTD3ROUK')
                   AND Package_Status__c = :pstatus
                   AND Opportunity.Account.Owner.Id = :UserInfo.getUserId()
                   AND Days_Remaining__c < :dayr
                   AND PriceBookEntry.Product2.Site__c = :site
                   AND Opportunity.Account.Account_Status__c = :accstatus
                   AND Credit_Burn_Rate__c < :burnrate
                   AND Credits_Remaining__c < :creditr
                   ORDER BY Credits_Remaining__c ASC
                   LIMIT 100];
      }    
              
    public list<OpportunityLineItem> getoliftd7credit() {
           return [SELECT Id, Opportunity.Account.Name, Opportunity.Account.Owner.Id, Opportunity.Account.Package_Status__c,
                              Opportunity.Account.Account_Status__c, PricebookEntry.Product2.ProductCode, PricebookEntry.Product2.Name, 
                              Quantity, Credits_Used__c, Credits_Remaining__c, Package_Status__c, Credit_Burn_Rate__c,
                              Days_remaining__c, PricebookEntry.Product2.Product_Subtype__c, until_Date__c, PriceBookEntry.Product2.Site__r.Name,
                              Length_Months__c
                              FROM OpportunityLineItem
                   WHERE (PricebookEntry.Product2.ProductCode = 'FTD7' OR PricebookEntry.Product2.ProductCode = 'FTD7ROUK')
                   AND Package_Status__c = :pstatus
                   AND Opportunity.Account.Owner.Id = :UserInfo.getUserId()
                   AND Days_Remaining__c < :dayr
                   AND PriceBookEntry.Product2.Site__c = :site
                   AND Opportunity.Account.Account_Status__c = :accstatus
                   AND Credit_Burn_Rate__c < :burnrate
                   AND Credits_Remaining__c < :creditr
                   ORDER BY Credits_Remaining__c ASC
                   LIMIT 100];
      }
         
   public list<OpportunityLineItem> getoliftd14credit() {
           return [SELECT Id, Opportunity.Account.Name, Opportunity.Account.Owner.Id, Opportunity.Account.Package_Status__c,
                              Opportunity.Account.Account_Status__c, PricebookEntry.Product2.ProductCode, PricebookEntry.Product2.Name, 
                              Quantity, Credits_Used__c, Credits_Remaining__c, Package_Status__c, Credit_Burn_Rate__c,
                              Days_remaining__c, PricebookEntry.Product2.Product_Subtype__c, until_Date__c, PriceBookEntry.Product2.Site__r.Name,
                              Length_Months__c
                              FROM OpportunityLineItem
                   WHERE (PricebookEntry.Product2.ProductCode = 'FTD14' OR PricebookEntry.Product2.ProductCode = 'FTD14ROUK')
                   AND Package_Status__c = :pstatus
                   AND Opportunity.Account.Owner.Id = :UserInfo.getUserId()
                   AND Days_Remaining__c < :dayr
                   AND PriceBookEntry.Product2.Site__c = :site
                   AND Opportunity.Account.Account_Status__c = :accstatus
                   AND Credit_Burn_Rate__c < :burnrate
                   AND Credits_Remaining__c < :creditr
                   ORDER BY Credits_Remaining__c ASC
                   LIMIT 100];
      }  
         
   public list<OpportunityLineItem> getoliftdspotcredit() {
           return [SELECT Id, Opportunity.Account.Name, Opportunity.Account.Owner.Id, Opportunity.Account.Package_Status__c,
                              Opportunity.Account.Account_Status__c, PricebookEntry.Product2.ProductCode, PricebookEntry.Product2.Name, 
                              Quantity, Credits_Used__c, Credits_Remaining__c, Package_Status__c, Credit_Burn_Rate__c,
                              Days_remaining__c, PricebookEntry.Product2.Product_Subtype__c, until_Date__c, PriceBookEntry.Product2.Site__r.Name,
                              Length_Months__c
                              FROM OpportunityLineItem
                   WHERE (PricebookEntry.Product2.ProductCode = 'FTDSPOT' OR PricebookEntry.Product2.ProductCode = 'FTDSPOTROUK')
                   AND Package_Status__c = :pstatus
                   AND Opportunity.Account.Owner.Id = :UserInfo.getUserId()
                   AND Days_Remaining__c < :dayr
                   AND PriceBookEntry.Product2.Site__c = :site
                   AND Opportunity.Account.Account_Status__c = :accstatus
                   AND Credit_Burn_Rate__c < :burnrate
                   AND Credits_Remaining__c < :creditr
                   ORDER BY Credits_Remaining__c ASC
                   LIMIT 100];
      }
             
   public list<OpportunityLineItem> getoliftdurgcredit() {
           return [SELECT Id, Opportunity.Account.Name, Opportunity.Account.Owner.Id, Opportunity.Account.Package_Status__c,
                              Opportunity.Account.Account_Status__c, PricebookEntry.Product2.ProductCode, PricebookEntry.Product2.Name, 
                              Quantity, Credits_Used__c, Credits_Remaining__c, Package_Status__c, Credit_Burn_Rate__c,
                              Days_remaining__c, PricebookEntry.Product2.Product_Subtype__c, until_Date__c, PriceBookEntry.Product2.Site__r.Name,
                              Length_Months__c
                              FROM OpportunityLineItem
                   WHERE (PricebookEntry.Product2.ProductCode = 'FTDURG' OR PricebookEntry.Product2.ProductCode = 'FTDURGROUK')
                   AND Package_Status__c = :pstatus
                   AND Opportunity.Account.Owner.Id = :UserInfo.getUserId()
                   AND Days_Remaining__c < :dayr
                   AND PriceBookEntry.Product2.Site__c = :site
                   AND Opportunity.Account.Account_Status__c = :accstatus
                   AND Credit_Burn_Rate__c < :burnrate
                   AND Credits_Remaining__c < :creditr
                   ORDER BY Credits_Remaining__c ASC
                   LIMIT 100];
      }
      
      public list<OpportunityLineItem> getoliftdurlcredit() {
           return [SELECT Id, Opportunity.Account.Name, Opportunity.Account.Owner.Id, Opportunity.Account.Package_Status__c,
                              Opportunity.Account.Account_Status__c, PricebookEntry.Product2.ProductCode, PricebookEntry.Product2.Name, 
                              Quantity, Credits_Used__c, Credits_Remaining__c, Package_Status__c, Credit_Burn_Rate__c,
                              Days_remaining__c, PricebookEntry.Product2.Product_Subtype__c, until_Date__c, PriceBookEntry.Product2.Site__r.Name,
                              Length_Months__c
                              FROM OpportunityLineItem
                   WHERE (PricebookEntry.Product2.ProductCode = 'FTDURL' OR PricebookEntry.Product2.ProductCode = 'FTDURLROUK')
                   AND Package_Status__c = :pstatus
                   AND Opportunity.Account.Owner.Id = :UserInfo.getUserId()
                   AND Days_Remaining__c < :dayr
                   AND PriceBookEntry.Product2.Site__c = :site
                   AND Opportunity.Account.Account_Status__c = :accstatus
                   AND Credit_Burn_Rate__c < :burnrate
                   AND Credits_Remaining__c < :creditr
                   ORDER BY Credits_Remaining__c ASC
                   LIMIT 100];
      }
      
}