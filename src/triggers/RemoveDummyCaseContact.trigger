trigger RemoveDummyCaseContact on Case (after insert) {
    
    //SF_Gumtree_SOW_001 for checking duplicate contact from case creation
    if([select Id FROM AsyncApexJob where methodname='doRemoveDummyRecords' and Status in ('Queued','Processing') limit 1].size()<1) {
       BounceBackEmails.doRemoveDummyRecords();
       Integer count = System.purgeOldAsyncJobs(Date.today());
    }
}