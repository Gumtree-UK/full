/**

GTCRM-222 - Automate client reporting for AdSales

Change log:
- 

**/

public with sharing class ExcelReportBatch implements Database.batchable<sObject>{
    
    //Generally the automatic sending will only be activated for opportunities where “opp.Reporting_Active__c” = True.
    String query = 'Select Final_Reporting__c, id, Weekday__c, Interval__c, Campaign_Start__c, Campaign_End__c, Reporting_Start_Date__c, Reporting_End_Date__c '+
                   'From Opportunity '+
                   'Where Reporting_Active__c=TRUE '+
                          'and Campaign_Start__c!=null '+
                          'and Campaign_End__c!=null '+
                          'and Campaign_End__c >'+String.valueOf(System.Today().addDays(-5));
    
    /** 
    *   Constructor default  
    */
    public ExcelReportBatch(){ 
        
    }
    
    /**
    *   Implement Interface method
    */
    public Database.QueryLocator start(Database.BatchableContext BC){
        return Database.getQueryLocator(query);
    }
    
    /**
    *   Implement Interface method
    */
    public void execute(Database.BatchableContext BC, List<Opportunity> scope){
        
        Set<String> setOppID = new Set<String>(); 
        
        for(Opportunity opp:scope){
            
            //If fields “opp.Reporting_Start_Date__c” and “opp.Reporting_End_Date__c” are populated
            //“During campaign” is defined as “Reporting_Start_Date__c” to “Reporting_End_Date__c”.
            Date reportStart=null;
            Date reportEnd=null;
            if(opp.Reporting_Start_Date__c!=null && opp.Reporting_End_Date__c!=null && opp.Reporting_Start_Date__c<=opp.Reporting_End_Date__c){
                reportStart=opp.Reporting_Start_Date__c;
                reportEnd=opp.Reporting_End_Date__c;
            }else{
                reportStart=opp.Campaign_Start__c;
                reportEnd=opp.Campaign_End__c;
            }
             
            //check after campaign============= 
            //“After campaign” is defined as two days after end date (reportEnd +2)         
            if(isAfter(reportEnd)){
                
                //If “opp.Final_Reporting__c” = True, then reports are sent out during and after campaign, when False only during campaign.
                if(opp.Final_Reporting__c){setOppID.add(opp.id);}
                
            //check during campaign==============   
            }else if(isDuring(reportStart, reportEnd)){
                 
                //“During campaign” is defined as two days after start date (reportStart +2) to end date (reportEnd).
                //=====if(reportStart.addDays(2)==System.today()){ 
                    //====setOppID.add(opp.id); 
                    
                //This interval is defined in field “opp.Interval__c”. If the interval is “Weekly” the weekday is defined in field “opp.Weekday__c”.
                // If this field is empty the default weekday is Monday.
                // If the interval is “Monthly” the date of month is always the 3rd day of the month.
                //====}else  
                if(opp.Interval__c!=null){ 
                    if(isMonthly(opp.Interval__c)){                     
                        setOppID.add(opp.id);
                    }else if(isWeekly(opp.Interval__c,opp.Weekday__c)){
                        setOppID.add(opp.id);
                                        
                    }else if(opp.Interval__c=='Daily'){
                        setOppID.add(opp.id);                                       
                    }                    
                }   
            }
        }  
        
        for(String oppID : setOppID){
            ExcelReportEmail mail= new ExcelReportEmail(oppID);
            mail.sendMail();
        }
            
    } 
    
    /**
    *   Implement Interface method
    */
    public void finish(Database.BatchableContext BC){
            
    }
    
    /**
    *   check is After campaign?
    *       @param1: date of campaign_end        
    */
    boolean isAfter(Date endDate){
        return endDate.addDays(2)==System.today()?true:false;
    }
    
    /**
    *   check is During campaign?
    *       @param1: date of campaign_start   
    *       @param2: date of campaign_end      
    */
    boolean isDuring(Date startDate, Date endDate){
      //return (System.today()>=startDate && System.today()<=endDate)?true:false;
      
      //Bunhor: edit on 7-jan-14
      //"During campaign" is defined as two days after start date (opp.Campaign_Start__c +2) to end date     
        return (System.today()>=startDate.addDays(2) && System.today()<=endDate)?true:false;
    }
    
    /**
    *   check is Interval__c='monthly' and it is on day=3
    *       @param1: string of Interval__c     
    */
    boolean isMonthly(String interval){ 
        return (interval.toLowerCase()=='monthly' && System.today().day()==3)?true:false;
    }
    
    /**
    *   check is Interval__c='Weekly' and Weekday__c(default='Monday')
    *       @param1: string of Interval__c 
    *       @param2: string of Weekday__c 
    */
    boolean isWeekly(String interval, object weekDay){
        String wDay = (weekDay==null?'Monday':String.valueOf(weekDay)).toLowerCase();
        
        Datetime dt = DateTime.newInstance(System.today(), Time.newInstance(0, 0, 0, 0));
        String today = dt.format('EEEE').toLowerCase(); 
        
        return (interval=='Weekly' && today==wDay)?true:false;
    }   
      
}