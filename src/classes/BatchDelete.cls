global class BatchDelete implements Database.Batchable<sObject> {
   public String query;

   global Database.QueryLocator start(Database.BatchableContext BC){
      return Database.getQueryLocator(query);
   }

   global void execute(Database.BatchableContext BC, List<sObject> scope){
      delete scope;
      DataBase.emptyRecycleBin(scope);
   }

   global void finish(Database.BatchableContext BC){
   }

   static testMethod void myTest() {
 BatchDelete BDel = new BatchDelete();
 BDel.query = 'SELECT Id FROM EmailMessage limit 1';
 Test.startTest();
  ID batchprocessid = Database.executeBatch(BDel);
 Test.stopTest(); 
  }
}