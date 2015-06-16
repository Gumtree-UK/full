global class P2P_CommunitySignOn implements Auth.RegistrationHandler{
    
    public String getAccountNo(String fs){
        String accountNo = '';
        if (fs!=null) {
            accountNo = fs.replace('[','').replace(']','');
            List<String> accountsNO = accountNo.split(',');
            accountNo = accountsNO[0].trim();
        }
        return accountNo;
    }
    
    public String updateAccountKeys(Auth.UserData data){
        String email = data.email;
        String accountNo = getAccountNo(data.attributeMap.get('accountsId'));
        System.debug('accountNo>>>>>>>> ' + accountNo);
        List<Account> lacc = [Select Id, Primary_contact__c From Account Where AccountNumber =: accountNo];
        if(lacc.isEmpty()) throw new AuthorizationException('No Account found from this account number: ' + accountNo);
        List<Contact> lcont = [Select Id From Contact Where Email =: email And Id =: lacc[0].Primary_contact__c];
        if(lcont.isEmpty()) throw new AuthorizationException('No Contact found from this email: ' + email);
        
        /*UserData:[attributeMap={accountsId=[5495, 58774261], bapiKey=cedefd7ed7a20f1859581fa90415f9fe, email=jobs.dd1@hotmail.com, id=59245356, kind=gumtree#personOpenIdConnect, privateKey=a27dd12e931f37474f4f974400d8144c, sfdc_networkid=0DBw0000000CbZq}, email=jobs.dd1@hotmail.com, firstName=null, fullName=null, identifier=59245356, lastName=null, link=null, locale=null, provider=Open ID Connect, siteLoginUrl=null, username=null]*/
        Account acc = lacc[0];     
        acc.Bapi_Key__c = data.attributeMap.get('bapiKey');
        acc.Private_Key__c = data.attributeMap.get('privateKey');
        update acc;
        return lcont[0].Id;
    }
    
    public void mapUserInfo(Auth.UserData data, Contact c, User u){
        c.GT_UserId__c = data.identifier;
        
        Profile p = [select Id from Profile where name =: COMMUNITY_PROFILE_NAME];
        String accountNo = getAccountNo(data.attributeMap.get('accountsId'));
        u.username = c.email;
        u.email = c.email;
        u.lastName = c.LastName;
        u.firstName = c.FirstName;
        u.alias = c.Name;
        if(u.alias.length()>8){
            u.alias = u.alias.substring(0,8);
        }
        u.CompanyName = c.Account.Name;
        u.Title = c.Title;
        u.languagelocalekey = 'en_US';
        u.localesidkey = 'en_GB';
        u.emailEncodingKey = 'ISO-8859-1';
        u.timeZoneSidkey = 'Europe/London';
        u.profileId = p.Id;
        if(u.Id == null) u.contactId = c.Id;
        u.GT_UserId__c = data.identifier;
        u.GT_AccountNumber__c = accountNo;
    }
    
    /*Community CODE*/
    global final String COMMUNITY_PROFILE_NAME = 'Customer Community User Clone';
    
    global User createUser(Id portalId, Auth.UserData data){
        System.debug('createUser>>>>>>>>>>> ' + data);
        String cId = updateAccountKeys(data);
        Contact c = [Select Id, Name, LastName, FirstName, AccountId, Email, Account.Name, Title From Contact Where Id =: cId];
        User[] users = [Select Id From User Where ContactId =: cId];
        User u = users.isEmpty() ? new User() : users[0];
        mapUserInfo(data, c, u);
        update c;
        return u;
    }
    
    global void updateUser(Id userId, Id portalId, Auth.UserData data){
        System.debug('updateUser>>>>>>>>>>> ' + data);
        String cId = updateAccountKeys(data);
        Contact c = [Select Id, Name, LastName, FirstName, AccountId, Email, Account.Name, Title From Contact Where Id =: cId];
        User u = new User(Id = userId);
        mapUserInfo(data, c, u);
        update c;
        update u;

        //User usr = [Select IsActive From User Where Id=: userId];
        //if(!usr.IsActive){ 
            //usr.IsActive = true;
            //usr.contactId = cId;
            //update usr;
            //throw new AuthorizationException('This user is inActive: ' + userId);
        //}
    }
    
    global class AuthorizationException extends Exception{}
}