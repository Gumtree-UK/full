/**

GTCRM-222 - Automate client reporting for AdSales

Change log:
- 

**/

public with sharing class ExcelReportScheduler implements Schedulable{

  /**
  *  Implement Interface method
  */
  public void execute(SchedulableContext SC) {
    ID batchProcessID=Database.executeBatch(new ExcelReportBatch(), 5);
  }
}