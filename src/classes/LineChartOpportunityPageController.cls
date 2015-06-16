/**

Change log:
- 2014-01-22 - Added Net_Net_Net_forecast__c to chart

**/
public with sharing class LineChartOpportunityPageController {
  
  private String oppId;
  //for create new date by java script do not change this format
  private final static String DATE_FORMAT='yyyy/MM/dd';
 
  
  //for show format date on visual page
  private final static String DATE_FORMAT_LABEL='dd-MM-yyyy';
  
  //constructor
  public LineChartOpportunityPageController(ApexPages.StandardController stdController){  
     oppId=  stdController.getRecord().id;
     sumFirstTab();
     initAllProduct();
     initLineItemDescription();
  }
  
  //Store date for date slider on visual page
  public Map<String,String> mapDate {get;set;}
  
  //store lineitem line description
  //store lineitem line description
  private static Map<String,OpportunityLineItem> mapLineItemDescription = new Map<String,OpportunityLineItem>();
  
  private void initLineItemDescription(){
    
    mapLineItemDescription =  new Map<String,OpportunityLineItem>( [Select id,Product_Name__c, Description From OpportunityLineItem o where opportunityId =: oppId ]);
    
    
  }
  
  //check is No data or not
  public Boolean isNoData {get{ return lstFirstTab.isEmpty(); }set;}
  
  //get valid AVG of OSI
  private Decimal getValidDecimal(AggregateResult result){
    
    try{
      return Decimal.valueOf(''+result.get('Avg'));      
    }catch(Exception e){
      return 0;
    }
    
  }
  
  
  
  private void sumFirstTab(){
     lstFirstTab = new List<LineChart>();
      mapDate = new Map<String,String>();    
    for(AggregateResult result:[Select  sum(Net_Net_Net__c) NetExp, 
                      sum(Net_Net_Net_delivered__c) NetDel,
                      AVG(OSI_RSD__c) Avg,
                      Day__c 
                      From Revenue_Schedule_daily2__c r 
                      where Opportunity__c=: oppId 
                      GROUP BY Day__c 
                      ORDER BY Day__c]){
            
                                                
          Decimal netExp = result.get('NetExp')<> null ? Decimal.valueOf( ''+result.get('NetExp')) : 0;
          Decimal netDel = result.get('NetDel')<> null ? Decimal.valueOf( ''+result.get('NetDel')) : 0;
          
          lstFirstTab.add( new LineChart( netExp  , netDel , getValidDecimal( result ) , Date.valueOf(''+result.get('Day__c'))  ) ) ;
            
    }  
    
    initMapDate(  !lstFirstTab.isEmpty() ? lstFirstTab.get(0).dayForJavaScript : DateTime.now().format( DATE_FORMAT )  , '#dateSlider_Min'); 
    initMapDate(  !lstFirstTab.isEmpty() ? lstFirstTab.get(lstFirstTab.size() -1).dayForJavaScript : DateTime.now().format(DATE_FORMAT) , '#dateSlider_Max');
    
     
  }
  
  private void initMapDate( String dayLabel , String key){    
    mapDate.put( key   , dayLabel);    
  }
  
 
  /* new code fixed  Aggregate query does not support queryMore(), use LIMIT to restrict the results to a single batch" */
  private void initAllProduct(){
     mapchildProduct = new Map<String,List<LineChart>>();
     lstTabs = new List<ProductTab>();
    Integer i =1;
    
    Map<String,List<String>> mapChildOrderDate = new Map<String,List<String>>();
        
    Map<String,Map<String,List<Revenue_Schedule_daily2__c>>> mapRevenueTmp = new Map<String,Map<String,List<Revenue_Schedule_daily2__c>>>();
    //split revenue by product name
  for(Revenue_Schedule_daily2__c reven :[select Revenue2__r.LineItemId__c,Net_Net_Net__c, Net_Net_Net_delivered__c,OSI_RSD__c,Day__c  
                           from Revenue_Schedule_daily2__c  where Opportunity__c=: oppId  and Day__c<> null and Revenue2__r.LineItemId__c<> null ORDER BY Revenue2__r.LineItemId__c,Product__r.Name ,Day__c ]){
      
          String key = reven.Revenue2__r.LineItemId__c ;
          Date date2 = reven.Day__c;
          String childKey = DateTime.newInstance(date2.year(), date2.month(),date2.day()).format( DATE_FORMAT) ;
        if( !mapRevenueTmp.containskey(key)){
          mapRevenueTmp.put( key , new Map<String,List<Revenue_Schedule_daily2__c>>());
          mapChildOrderDate.put(key , new List<String>());
        }
        
        if( !mapRevenueTmp.get(key).containskey(childKey) ) {
          mapRevenueTmp.get(key).put( childKey , new List<Revenue_Schedule_daily2__c>());
          mapChildOrderDate.get(key).add(childKey);
        }
        
        mapRevenueTmp.get(key).get(childKey).add(reven);
        
    } 
    
    for(String key  :mapRevenueTmp.keyset()){
      Date minDate = null, maxDate = null ;
      String sliderKey ='#dateSlider_'+ i;
      if( !mapchildProduct.containskey(key)){
        mapchildProduct.put( key , new List<LineChart>());
        lstTabs.add( new ProductTab( i , key ) );
        i++;
      }
      
      for(String  childKey: mapChildOrderDate.get(key)){  
        Decimal netDel = 0;
        Decimal netExp = 0;
        Date day2 = null;  
        Integer rowCount = 0;  
        Decimal avgOSI = 0;  
        for(Revenue_Schedule_daily2__c reven: mapRevenueTmp.get(key).get(childKey)){
          netDel =  reven.Net_Net_Net_delivered__c ==null ? netDel : (netDel + reven.Net_Net_Net_delivered__c);
          netExp =  reven.Net_Net_Net__c== null? netExp : (netExp + reven.Net_Net_Net__c);
          avgOSI = reven.OSI_RSD__c == null? avgOSI :   (avgOSI + reven.OSI_RSD__c) ;  
          day2 = day2== null ? reven.Day__c :  day2;        
          rowCount++;
          
          minDate = minDate== null ? reven.Day__c : ( minDate > reven.Day__c ?  reven.Day__c : minDate );
          maxDate = maxDate== null ? reven.Day__c : ( maxDate < reven.Day__c ?  reven.Day__c : maxDate );
          
        }
        
        mapchildProduct.get(key).add( new LineChart(netExp ,netDel , (rowCount==0 ? avgOSI : avgOSI / rowCount )  ,  day2 )  );        
      }
      if( minDate== null || maxDate == null ) continue;
      initMapDate(  DateTime.newInstance(minDate.year(), minDate.month(),minDate.day()).format( DATE_FORMAT)   , sliderKey+'_Min'); 
      initMapDate(  DateTime.newInstance(maxDate.year(), maxDate.month(),maxDate.day()).format( DATE_FORMAT) , sliderKey+'_Max');
      
    }    
    
  }
  
  
  
  public Map<String,List<LineChart>> mapchildProduct {get;set;}
  public List<LineChart> lstFirstTab{get;set;}
  public List<ProductTab> lstTabs{get;set;}
  
  public class LineChart{
    public Decimal netExp{get;set;}
    public Decimal netDel{get;set;}  
    public Decimal valOSI{get;set;}     
    public String dayLabel{ get; set;}
    public String dayForJavaScript{get;set;}
    
    public LineChart(Decimal netExp, Decimal netDel,Decimal valOSI, Date date2){
      this.netExp = netExp;
      this.netDel = netDel;
      this.valOSI = valOSI;    
      this.dayLabel = DateTime.newInstance(date2.year(), date2.month(),date2.day()).format( DATE_FORMAT_LABEL);
      this.dayForJavaScript =  DateTime.newInstance(date2.year(), date2.month(),date2.day()).format( DATE_FORMAT);
    }    
    
    public LineChart(Decimal netExp, Decimal netDel, Date date2){
      this.netExp = netExp;
      this.netDel = netDel;    
      this.dayLabel = DateTime.newInstance(date2.year(), date2.month(),date2.day()).format( DATE_FORMAT);
    }    
  }
  
  public static String getTabLable(String name){
    OpportunityLineItem  oppItem = mapLineItemDescription.get(name);
    if( oppItem==  null ) return name;
    String lable = oppItem.Description <> null && oppItem.Description<> ''  ?  oppItem.Description : oppItem.Product_Name__c;
    
    
    if(lable.length()> 10){
      lable = lable.substring(0, 5) + '..'+ lable.substring( lable.length()-5 , lable.length());
    }
    
    return lable;
  }
  
  public class ProductTab{
    public Integer pos{get;set;}
    public String name{get;set;}
    public String key{
      get{
        return '#dateSlider_'+pos;
      }      
      set;}
    
    public String description{
      get{
        OpportunityLineItem  oppItem = mapLineItemDescription.get(name);
        if( oppItem==  null ) return name;        
        return  oppItem.Description;
      }
      set;
    }
    
    public String proName{
      get{
        OpportunityLineItem  oppItem = mapLineItemDescription.get(name);
        if( oppItem==  null ) return name;        
        return  oppItem.Product_Name__c;
      }
      set;
    }
      
    
    public String label{
      get{
        return getTabLable( name );
      }
      set;}
    
    public ProductTab(Integer pos , String name){
      this.pos = pos;
      this.name = name;
    }
    
  }
  

}