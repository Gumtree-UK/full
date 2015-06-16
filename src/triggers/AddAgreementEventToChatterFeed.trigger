/*

Created By: Nick Hamm
Created Date: 04/01/2010
Description: Creates Chatter feeds based on Agreement Events for the Echosign Salesforce.com implementation

Change log:

1.

Modified by: T_SD12
Modified Date: 04/02/2010
Description: 

--- Bulk Enabled the trigger
--- Feed ParentId(fp2.ParentId,fp3.ParentId) made dynamic based on the Agreement Owner.
--- ServerUrl__c :- This is used to store the Server URL of a Salesforce.com instance to be used from the Agreement Event
                    trigger for Chatter feeds, as this property is not available from a Trigger.
--- Achieved required test coverage (TestAddAgreementEventToChatterFeed.cls)

*/

trigger AddAgreementEventToChatterFeed on echosign_dev1__SIGN_AgreementEvent__c (after insert)
{
    Set<Id> setESDSAEId = new Set<Id>();
    List<echosign_dev1__SIGN_AgreementEvent__c> lstESDSAE = new List<echosign_dev1__SIGN_AgreementEvent__c>();
    List<FeedPost> lstFeedPost = new List<FeedPost>();
    
    for(Integer i = 0; i < Trigger.new.size(); i++)
    {
        setESDSAEId.add(Trigger.new[i].Id);
    }
    
    lstESDSAE = [Select ServerUrl__c, echosign_dev1__SIGN_Agreement__r.OwnerId,echosign_dev1__Type__c,echosign_dev1__Description__c, Agreement_Name__c, echosign_dev1__SIGN_Agreement__c, echosign_dev1__SIGN_Agreement__r.echosign_dev1__Status__c from echosign_dev1__SIGN_AgreementEvent__c where id in: setESDSAEId];
       
    for(Integer i = 0; i <  lstESDSAE.size(); i++)
    {
        List<String> urlArray = new List<String>();
    
        //lstESDSAE[i].ServerUrl__c : This is used to store the Server URL of a Salesforce.com instance to be 
        //used from the Agreement Event trigger for Chatter feeds, as this property is not available from a Trigger.
        //urlArray = lstESDSAE[i].ServerUrl__c.split('/services');
        //urlArray = lstESDSAE[i].ServerUrl__c.split('.');
        //String url;
        //url = urlArray[0];
                
        String fpBody = 'No description entered ';
        if(lstESDSAE[i].echosign_dev1__Description__c!=null)
            fpBody = lstESDSAE[i].echosign_dev1__Description__c;

        String aName = lstESDSAE[i].Agreement_Name__c;
       
        FeedPost fp1 = new FeedPost();
        fp1.Type = 'TextPost';
        fpBody = fpBody.replace(aName, 'Agreement was ');
        fp1.Body = fpBody;
         //this will send it to the Agreement Feed
        fp1.ParentId = lstESDSAE[i].echosign_dev1__SIGN_Agreement__c;
        lstFeedPost.add(fp1);
      
        if (lstESDSAE[i].echosign_dev1__SIGN_Agreement__r.echosign_dev1__Status__c == 'SIGNED')
        {
            FeedPost fp2 = new FeedPost();    
            fp2.Type = 'LinkPost';
            fpBody = '"' + aName + '" is signed and filed!';        
            fp2.Body = fpBody;
            //this will send it to the User's Feed.  This needs to be made dynamic based on the Agreement Owner
            fp2.ParentId = lstESDSAE[i].echosign_dev1__SIGN_Agreement__r.OwnerId;
            fp2.Title = 'View agreement ...';
            //this needs to have the SFDC server URL preprended.  It may need to be stored as a custom setting.
            fp2.LinkURL = lstESDSAE[i].ServerUrl__c + 'salesforce.com/' + lstESDSAE[i].echosign_dev1__SIGN_Agreement__c;
            lstFeedPost.add(fp2);
        }
        else if (lstESDSAE[i].echosign_dev1__Type__c == 'SENT')
        {
            FeedPost fp3 = new FeedPost();    
            fp3.Type = 'LinkPost';
            fpBody = 'Just sent "' + aName + '" for signature.';        
            fp3.Body = fpBody;
            //this will send it to the User's Feed.  This needs to be made dynamic based on the Agreement Owner
            fp3.ParentId = lstESDSAE[i].echosign_dev1__SIGN_Agreement__r.OwnerId;
            fp3.Title = 'View agreement ...';
            //this needs to have the SFDC server URL preprended.  It may need to be stored as a custom setting.
            fp3.LinkURL = lstESDSAE[i].ServerUrl__c + 'salesforce.com/' + lstESDSAE[i].echosign_dev1__SIGN_Agreement__c;
            lstFeedPost.add(fp3);                  
        }       
    }

    if(lstFeedPost.size() > 0)
    {
        DataBase.SaveResult[]  res= DataBase.insert(lstFeedPost,false);
    
    }

}