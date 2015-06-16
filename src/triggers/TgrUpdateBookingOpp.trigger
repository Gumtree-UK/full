trigger TgrUpdateBookingOpp on Opportunity (after update) {
  List<Opportunity> updateOpport=new List<Opportunity>();
  List<Opportunity> updateAutoOpport=new List<Opportunity>();
  for(Integer i=0;i<Trigger.new.size();i++){
    Opportunity oppNew=Trigger.new.get(i);
    Opportunity oppOld=Trigger.old.get(i);
    if(oppNew.StageName!=oppOld.StageName && oppNew.StageName==ClsBookingOppUpdate.ST_BOOKING){
      if(oppNew.Is_Converted__c){
        updateAutoOpport.add(oppNew);
      }else{
        updateOpport.add(oppNew);
      }
    }
  }
  if(!updateOpport.isEmpty()) ClsBookingOppUpdate.updateProductDate(updateOpport);
  if(!updateAutoOpport.isEmpty()) ClsConvertAutoDirectOpp.updateProductDate(updateAutoOpport);
}