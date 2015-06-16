/**
* Class 'RevenueBatch'
* Initial and scheduable Update for Revenues
*
* Erstellt: 19.12.2011
* Avendio GmbH
* Stefan Voß
**/
global class RevenueBatch implements Database.Batchable<SObject>, Schedulable{

    private string limitSQL = '';
    private string whereSQL = ' where LastModifiedDate >= YESTERDAY';
    private list<Revenue.Error> errorList = new list<Revenue.Error>();
    private dateTime zeit = system.now();

    public void setTest() {
        limitSQL = ' limit 10';
    }

    public void setWhere(String whereQuery) {
        whereSQL = ' ' + whereQuery;
    }

    global Database.QueryLocator start(Database.BatchableContext bc) {
        String query = '';
        query += 'select Id from OpportunityLineItem' + whereSQL + limitSQL;
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<sObject> scope){
        List<OpportunityLineItem> olis = (OpportunityLineItem[]) scope;

        Revenue.start(olis);
        for (Revenue.Error err : Revenue.errorList) {
            errorList.add(err);
        }
    }

    global void finish(Database.BatchableContext BC){
        system.debug('ERRORLIST: ' + errorList);
        sendMail();
    }

    private void sendMail() {
        if (!errorList.isEmpty()) {
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setToAddresses(new String[] {'steven@gumtree.com'});
            mail.setSubject('Revenue Erstellung (Ebay) - Fehler');
            mail.setSaveAsActivity(false);

            String mailText = 'Startzeit: ' + zeit.format('dd.MM.yyyy hh:mm') + '\nEnde: ' + system.now().format('dd.MM.yyyy hh:mm')+'\n\n';
            Integer i=0;
            for (Revenue.Error e : errorList) {
                i++;
                mailText += '*** Fehler '+i+' ***\n';
                mailText += e.errorMsg;
                if (e.obj!=null) {
                    mailText += '\nObjekt: ' + e.obj;
                }
                if (e.objList!=null) {
                    mailText += '\nObjektListe:\n';
                    for (SObject obj : e.objList) {
                        mailText += '  ' + obj;
                    }
                }
                if (e.objMap!=null) {
                    mailText += '\nObjektMap:\n';
                    for (Id key : e.objMap.keySet()) {
                        mailText += '  ' + key + ' -> '+ e.objMap.get(key);
                    }
                }
                mailText += '\n\n';
            }
            mail.setPlainTextBody(mailText);
            Messaging.sendEmail(new Messaging.Email[] {mail});
        }
    }

    // start Batch Method
    public void startBatch(Integer batchsize) {
        if (batchsize == null) {
            Database.executeBatch(this);
        }
        else {
            Database.executeBatch(this, batchsize);
        }
    }

    // daily update
    global void execute(SchedulableContext sc) {
        setWhere('where LastModifiedDate >= YESTERDAY');
        startBatch(25);
    }

    // Test Method
    static testMethod void testRevenueBatchSchedule() {
        Test.startTest();
        RevenueBatch p = new RevenueBatch();
        p.setTest();
        p.setWhere('');

        SchedulableContext sc;
        p.execute(sc);
        Test.StopTest();
    }

    static testMethod void testRevenueBatch() {
        Test.startTest();
        RevenueBatch p = new RevenueBatch();
        p.setWhere('');
        p.setTest();
        p.startBatch(null);
        Test.StopTest();
    }
}