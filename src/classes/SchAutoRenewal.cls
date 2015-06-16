global class SchAutoRenewal implements Schedulable{
  
  private String opli;
  public SchAutoRenewal(String opli){
    this.opli = opli;
  }
  
  public SchAutoRenewal(){} 
  
  global void execute(SchedulableContext BC){
    BatchAutoRenewal batch = (Test.isRunningTest()? new BatchAutoRenewal(opli): new BatchAutoRenewal());
    ID batchprocessid = Database.executeBatch(batch);
    BatchAutoRenewal.createErrorLog(batchprocessid);    
  }
}