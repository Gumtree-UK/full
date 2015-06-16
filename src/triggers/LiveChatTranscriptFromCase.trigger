trigger LiveChatTranscriptFromCase on LiveChatTranscript (before insert, before update, after insert, after update) {
    if(trigger.isBefore && (trigger.isInsert || trigger.isUpdate))
    PreChatFormController.PopulateLiveChatTranscriptFields(trigger.new);
    
    //MS 2014-06-30: update case.User_Source__c = LiveChatTranscript.Platform
    if(trigger.isAfter && trigger.isUpdate){
        List<LiveChatTranscript> lstLiveChart = new List<LiveChatTranscript>();
        for(LiveChatTranscript lct : trigger.new){
            if(trigger.oldMap.get(lct.Id) != trigger.newMap.get(lct.Id)){
                lstLiveChart.add(lct);
            }
        }
        if(!lstLiveChart.isEmpty()){
            PreChatFormController.updateCaseUserSource(lstLiveChart);
        }   
    }
    
    if(trigger.isAfter && trigger.isInsert){
        PreChatFormController.updateCaseUserSource(trigger.new);
    }
    //End MS 2014-06-30 
    
}