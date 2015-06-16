/** 2013-01-30 - set as inactive as longer required - will be deleted
* Class 'SchedulerStart'
* SchedulerQuickstart
*
* Created: 10.12.2010
* Avendio GmbH
* Stefan Voß
**/

public class SchedulerStart {
/*	
	// Monatsumsatz UniqueKey Init
	public static void init_Rev_UniqueKey(boolean test) {
        Integer min = system.now().minute()+1;
        Integer std = system.now().hour();
        Integer tag = system.now().day();
        Integer mon = system.now().month();
        Integer jahr = system.now().year();
        
        init_Rev_UniqueKey(min, std, tag, mon, jahr, test);
    }

    public static void init_Rev_UniqueKey(Integer min, Integer std, Integer tag, Integer mon, Integer jahr, boolean test) {
        String i = String.valueOf(min);
        String h = String.valueOf(std);
        String d = String.valueOf(tag);
        String m = String.valueOf(mon);
        String j = String.valueOf(jahr);

        Revenue_UniqueKey_Schedule bpb= new Revenue_UniqueKey_Schedule();
        if (test) {
            bpb.setTest(true);
        }
        String sch = '0 ' + i + ' ' + h + ' ' + d + ' ' + m + ' ? ' + j;
        String jobName = 'Revenue-UniqueKey Initiation ' + d + '.' + m +'. - ' + h + ':' + i;
        system.schedule(jobName, sch, bpb);
    }

    static testMethod void schedulerStart () {
        SchedulerStart.init_Rev_UniqueKey(true);
    }
*/    
}