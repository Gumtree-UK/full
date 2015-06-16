global class GT_CreditsUsed_Update implements Schedulable {

    global void execute(SchedulableContext sc) {
           
		GumtreeAPI_Batch apiBatch = new GumtreeAPI_Batch();
        apiBatch.query = 'SELECT Id, AccountNumber FROM Account WHERE (RecordTypeId = \'01220000000Disx\' OR RecordTypeId = \'012200000005MbL\' OR RecordTypeId = \'01220000000DqON\' OR RecordTypeId = \'01220000000YDMy\') AND AccountNumber <> \'\' AND Account_Migrated__c = true';
        Database.executeBatch(apiBatch, 1);
		        
    }
}