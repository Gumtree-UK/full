/**
* Trigger 'changeOppName'
* Sets up opportunity name using different criteria/field values
**/

trigger changeOppName on Opportunity (before insert, before update) {

    public String date2english(Date indate) {
        
        String outdate;
        Map<String, String> monthname = new Map<String, String>{'1' => 'Jan',
                                                                '2' => 'Feb', 
                                                                '3' => 'Mar', 
                                                                '4' => 'Apr',
                                                                '5' => 'May',
                                                                '6' => 'Jun',
                                                                '7' => 'Jul',
                                                                '8' => 'Aug',
                                                                '9' => 'Sep',
                                                                '10'=> 'Oct',
                                                                '11'=> 'Nov',
                                                                '12'=> 'Dec'};
        
        String day = String.valueOf(indate.day());
        String mon = String.valueOf(indate.month());
        String yea = String.valueOf(indate.year());
        
        if (day.length()<2) {
            day='0'+day;
        }
        
        mon = monthname.get(mon);
        
        if (yea.length()<2) {
            yea='0'+yea;
        }
        else if (yea.length()==4) {
            yea=yea.substring(2);
        }
    
        outdate=mon+yea;
            
        return outdate;
    }

    //system.debug('HB *** OppCount: '+trigger.new.size());

    Set<Id> oppIds = new Set<Id>();
    Set<Id> agencyIds = new Set<Id>();
    Set<Id> accountIds = new Set<Id>();

    for (Opportunity opp : trigger.new) {
              
        // check if needed Data changed
        if (!trigger.isInsert &&
            opp.name == trigger.oldMap.get(opp.Id).name &&
            opp.Agency__c           == trigger.oldMap.get(opp.Id).Agency__c &&
            opp.AccountId           == trigger.oldMap.get(opp.Id).AccountId &&
            opp.Campaign_Start__c   == trigger.oldMap.get(opp.Id).Campaign_Start__c &&
            opp.Campaign_End__c     == trigger.oldMap.get(opp.Id).Campaign_End__c &&
            opp.Net_Net__c              == trigger.oldMap.get(opp.Id).Net_Net__c/*check Olis for Country - workaround*/) {
    
            continue;
        }
        
        
        if (!oppIds.contains(opp.Id)) {
            oppIds.add(opp.Id); 
        }
        if (opp.Agency__c<>null && !agencyIds.contains(opp.Agency__c)) {
            agencyIds.add(opp.Agency__c); 
        }
        if (opp.AccountId<>null && !accountIds.contains(opp.AccountId)) {
            accountIds.add(opp.AccountId); 
        }
    }
    
    if (oppIds.isEmpty()) { // no changes
        return;
    }
    
    // *** get agency names ******************************************************
    
    //system.debug('HB *** AgencyIds: '+agencyIds);
    
    list<Account> agencies = [SELECT Id,Name from Account WHERE Id in :agencyIds];
    
    Map<Id, String> id2agency = new Map<Id, String>();
    for (Account agency : agencies) {
             
       if (id2agency.get(agency.Id)==null && agency.Id<>null && agency.Name<>null) {
            id2agency.put(agency.Id,agency.Name); 
        }       
    }
    
    //system.debug('HB *** id2agency: '+id2agency);
 
    // *** get account names ******************************************************
    
    //system.debug('HB *** AccountIds: '+accountIds);
    
    list<Account> accounts = [SELECT Id,Name from Account WHERE Id in :accountIds];
    
    Map<Id, String> id2account = new Map<Id, String>();
    for (Account account : accounts) {
            
       if (id2account.get(account.Id)==null && account.Id<>null && account.Name<>null) {
            id2account.put(account.Id,account.Name); 
        }       
    }
    
    //system.debug('HB *** id2account: '+id2account);
        
    // *** process opportunities ****************************************************

    for (Opportunity opp : trigger.new) {
              
        String agency = id2agency.get(opp.Agency__c);
        
        //system.debug('HB *** agency: '+agency);
                    
        String customer = id2account.get(opp.AccountId);
        
        //system.debug('HB *** customer: '+customer);
                        
        String extcampn=opp.name;
        
        String campstart;
        if (opp.Campaign_Start__c!=null) {
            campstart=date2english(opp.Campaign_Start__c);
//            campstart=string.valueOf(opp.Campaign_Start__c.year());
        }
        String campend;
        if (opp.Campaign_End__c!=null) {
            campend=date2english(opp.Campaign_End__c);
        }
        
        String newoppname='';

        if (customer<>null) {
            newoppname+=customer+'_';
        }
        if (extcampn<>null) {
            newoppname+=extcampn+'_';
        }
        if (campstart<>null) {
            newoppname+=campstart;
        }
        if (campstart<>null && campend<>null) {
            newoppname+='-';
        }
        if (campend<>null) {
            newoppname+=campend;
        }
    
        if (newoppname.length()>120) {
            newoppname=newoppname.substring(0,104)+'_';

            if (campstart<>null && campend<>null) {
                newoppname+='-';
            }
            if (campend<>null) {
                newoppname+=campend;
            }
        }
            
        system.debug('HB *** oldname: '+opp.Name);
            
        opp.Campaign_Name__c=newoppname;
        
        system.debug('HB *** newname: '+newoppname);

    }
}