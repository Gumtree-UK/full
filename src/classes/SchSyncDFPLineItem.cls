/**
 * R #2596 : referenced SyncDFPLineItem
 */
global class SchSyncDFPLineItem implements Schedulable{
    global void execute(SchedulableContext sc) {
        SyncDFPLineItem.startScheduler();
    }
}