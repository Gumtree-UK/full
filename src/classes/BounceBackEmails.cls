/**
 * Task #3630: bounceback emails from salesforce (GTCRM-1086)
 * BY CPN, Jully-24-2014
 * Remove all case/contact with contact name "mailer-daemon@salesforce.com"
 * Call From Trigger RemoveDummyCaseContact
 * Emails: 'mailer-daemon@salesforce.com;invitations@linkedin.com;invitations@sanebox.com;invitations+cjnjnkng@inv.interpals.net;invitations@boxbe.com;notify@twitter.com;connections@twitter.com;postmaster@dukepub.co.uk;postmaster@lloydstsb.co.uk;postmaster@cameronross.co.uk;postmaster@mediamessaging.o2.co.uk;postmaster@morrisandspottiswood.co.uk';
 */
public without sharing class BounceBackEmails {

    @future
    public static void doRemoveDummyRecords(){
        Set<String> DUMMY_IDEN = new Set<String>();
        if(BounceBackEmailsSetting__c.getAll() != null){ 
            for(String skey : BounceBackEmailsSetting__c.getAll().keySet()){
                if(BounceBackEmailsSetting__c.getInstance(skey).IsDummy__c) DUMMY_IDEN.add(skey);
            }
        }
        try{
        delete [Select Id From Case Where Contact.LastName IN: DUMMY_IDEN Order By CreatedDate Desc limit 2000];
        delete [Select Id From Contact Where LastName IN: DUMMY_IDEN Order By CreatedDate Desc limit 2000];
        }catch(Exception e){
            //nothing to do just bypass the error
        }
    }  
}