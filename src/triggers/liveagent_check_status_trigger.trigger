trigger liveagent_check_status_trigger on LiveChatTranscript (after insert) {
    //store case id when status of chat  ='Missed' 
    Set<String> setCaseId= new Set<String>();
    for(LiveChatTranscript  t: Trigger.New){
         if(t.status=='Missed' && t.caseId <> null ){
             setCaseId.add(t.caseId);
         }
    }
    
    if( !setCaseId.isEmpty()){
    	//delete case
        delete [select id from Case where Id In: setCaseId ];
    }

}