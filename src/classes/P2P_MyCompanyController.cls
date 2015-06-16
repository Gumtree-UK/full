/**
 * Task #4180: My Company (GTCRM-1295)
 * @description: attached doc "My Company (GIS).docx"
 * @author: CPN
 * @createdDate: Oct-27-2014
 */
public class P2P_MyCompanyController{
    
    public static final String CONTACT_STATUS_ACTIVE = 'Active';
    public static final String CONTACT_STATUS_LEFT_COMPNAY = 'Left Company';
    
    public Account acc { get; set; }
    public List<DTOCompanyContact>lstComContacts{get;set;}
    public Integer editedIndex{get;set;}
    public String activeSince{get;set;}
    public String filterType { get; set; }
    public String billingAddress{get{return getBillingAddress();}set;}
    
    public Boolean isSuccessSave{get;set;}
    public Boolean isAddNewMode{get;set;}
    public Boolean isEditedProfile{get;set;}
    public Boolean isEditedContact{get;set;}
    
    public Contact primaryCon{get;set;}
    public Contact financeCon{get;set;}
    public Contact contactAdd{get;set;}
    
    public String getPrimaryConProfilePhoto(){
        return P2P_Utils.attachmentPhoto(primaryCon.Id);
    }
    
    public String getFinanceConProfilePhoto(){
        return P2P_Utils.attachmentPhoto(financeCon.Id);
    }
    
    //key = company contact Id, value = company contact type picklist value
    public Map<Id, String>mConType{get;set;}
    
    public P2P_GumtreeBAPI.GumtreeImage adImage{get;set;}
    public String fullImageURL{get;set;}
    
    public P2P_MyCompanyController(){
        String accId = P2P_Utils.retrieveCommunityAccountId();
        
        acc = new Account(Id = accId);
        initAccPriFinContact();
        
        //fetch default ad image
        adImage = new P2P_GumtreeBAPI.GumtreeImage();
        P2P_GumtreeBAPI.getDefaultImage(acc.AccountNumber, adImage, acc.Private_Key__c, acc.Bapi_Key__c);
        
        //calculate Active Since Date
        activeSince = System.now().addDays(-acc.Active_Since__c.intValue()).format('yyyy');
        
        filterType = CONTACT_STATUS_ACTIVE;
        sortByField = 'Name';
        currentSoredField = sortByField;
        isDESC = false;
        
        defaultPaginationProperties();
        queryWithSortedList(currentSoredField, isDESC);
        
        isSuccessSave = false;
        isAddNewMode = false;
        isEditedContact = false;
        isEditedProfile = false;
        
        initPackages();
    }
    
    /**
     *  Select Primary & Finance Contact
     */
    private void initAccPriFinContact(){
        
        acc = [Select Id, RecordTypeId, Charity_Number__c, Company_Reg_No__c, Name, AccountNumber, Account_Status__c, Feed_Provider__c, Outstanding_Debt_Fiqas__c,
            Package_Status__c, Company_VAT_No__c, Website, Feed_Provider_Manual__c, Description, Company_Logo__c, Active_Since__c, 
            BillingStreet, BillingCity, BillingCountry, BillingState, BillingPostalCode,  
            Owner.Email, Owner.Phone, Owner.Title, Owner.Name, Owner.FullPhotoUrl ,
            Primary_contact__c, Finance_contact__c, Bapi_Key__c, Private_Key__c 
            From Account Where Id =: acc.Id];
        acc.Bapi_Key__c = acc.Bapi_Key__c == null ? 'fakeKey' : acc.Bapi_Key__c;
        acc.Private_Key__c = acc.Private_Key__c == null ? 'fakeKey' : acc.Private_Key__c;
        //Primary Contact
        List<Contact>lstCons = [select Primary_Contact__c, Finance_Contact__c, Standard__c, Name, Title, Phone, Email, Profile_Photo__c, Contact_Status__c from Contact where Id=:acc.Primary_contact__c];
        primaryCon = lstCons.isEmpty() ? null : lstCons.get(0);
        
        //Finance Contact
        lstCons = [select Primary_Contact__c, Finance_Contact__c, Standard__c, Name, Title, Phone, Email, Profile_Photo__c, Contact_Status__c from Contact where Id=:acc.Finance_contact__c];
        financeCon = lstCons.isEmpty() ? null : lstCons.get(0);
        
    }
    
    /**
     *  Filter Change action
     */
    public PageReference filterChange(){
        defaultPaginationProperties();
        loadComContacts();
        return null;
    }
    
    /**
     *  Edited Account Profile
     */
    public Pagereference editProfile(){
        isEditedProfile = true;
        return null;
    }
    
    /**
     *  Cancel Edited Profile
     */
    public Pagereference cancelEditProfile(){
        isEditedProfile = false;
        initAccPriFinContact();
        return null;
    }
    
    /**
     *  Save Account
     */
    public Pagereference saveProfile(){
        isSuccessSave = checkSaveStatus(new List<Database.Saveresult>{Database.update(acc)});
        if(isSuccessSave){ 
            initAccPriFinContact();
            isEditedProfile = false;
        }
        return null;
    }
    
    /**
     *  Save Company Ad Image
     */
    public Pagereference saveAdImage(){
        fullImageURL = replaceUploadImage(acc.Company_Logo__c, acc.Id, true);
        return null;
    }
    
    public Pagereference uploadAdImage(){
        P2P_GumtreeBAPI.uploadImageByUrl(fullImageURL, adImage, acc.Private_Key__c, acc.Bapi_Key__c);
        if(adImage.isSuccess) P2P_GumtreeBAPI.setDefaultImage(acc.AccountNumber, adImage, acc.Private_Key__c, acc.Bapi_Key__c);
        return null;
    }
    
    /**
     *  Delete Company Ad Image
     */
    public Pagereference deleteAdImage(){
        
        P2P_GumtreeBAPI.deleteDefaultImage(acc.AccountNumber, adImage, acc.Private_Key__c, acc.Bapi_Key__c);
        if(adImage.isSuccess){
            List<Attachment>lstAtts = [select Body from Attachment where ParentId=:acc.Id and Name='Upload Image'];
            if(!lstAtts.isEmpty()) delete lstAtts;
            
            adImage.imageId = null; 
            adImage.imageURL = null;
        }
        return null;
    }
    
    /**
     *  Add new Contact
     */
    public Pagereference addComContact(){
        contactAdd = new Contact(Contact_Status__c=CONTACT_STATUS_ACTIVE, AccountId=acc.Id, Standard__c=true);
        
        //for bind contact type on new add contact only
        mConType.put(acc.Id, getConType(contactAdd));
        
        isAddNewMode = true;
        isEditedContact = false;
        return null;
    }
    
    /**
     *  Cancel Add new Contact
     */
    public Pagereference cancelAddComContact(){
        isAddNewMode = false;
        return null;
    }
    
    /**
     *  Save New Contact Added
     */
    public Pagereference saveNewContact(){
        
        /*  prevent store base64String to Rich TextArea
        *   crash when use dml statement
        */
        String profilePhoto = contactAdd.Profile_Photo__c;
        contactAdd.Profile_Photo__c = null;
        
        setContactType(contactAdd);
        
        //find if dublicate contact email
        Contact existContact = findExistContact(contactAdd);
        
        if(existContact == null){
            isSuccessSave = checkSaveStatus(new List<Database.Saveresult>{Database.insert(contactAdd)});
        }else{
            contactAdd = existContact;
            isSuccessSave = checkSaveStatus(new List<Database.Saveresult>{Database.update(contactAdd)});
        }
        
        if(isSuccessSave){ 
            
            //set Contact Profile photo with Attachment
            contactAdd.Profile_Photo__c = profilePhoto;
            String newPhotoUrl = replaceUploadImage(contactAdd.Profile_Photo__c, contactAdd.Id, false);
            
            if(newPhotoUrl != null) contactAdd.Profile_Photo__c = replaceUploadImage(contactAdd.Profile_Photo__c, contactAdd.Id, false);
            update contactAdd;
            
            isAddNewMode = false;
            contactAdd = null;
            
            //reinit Primary & Finance Contact for find is new set to Primary or Finance contact type
            initAccPriFinContact();
            //reinit list for show new add contact
            queryWithSortedList(currentSoredField, isDESC);
        }
        return null;
    }
    
    /**
     *  Find dublicate contact by email called on add new contact & update contact
     *  IF found replace all field values and return found contact
     */
    private Contact findExistContact(Contact con){
        
        List<Contact>lstCons = [Select Id, Name, Title, Primary_Contact__c, Finance_Contact__c, Standard__c, Phone, LastName, FirstName, Email, Contact_Status__c, Profile_Photo__c from Contact where Email=:con.Email and Contact_Status__c=:CONTACT_STATUS_LEFT_COMPNAY limit 1];
        if(!lstCons.isEmpty()){
            lstCons.get(0).FirstName = con.FirstName;
            lstCons.get(0).LastName = con.LastName;
            lstCons.get(0).Contact_Status__c = CONTACT_STATUS_ACTIVE;
            lstCons.get(0).Phone = con.Phone;
            lstCons.get(0).Title = con.Title;
            
            return lstCons.get(0);
        }
        return null;
    }
    
    /**
     *  Set Type of Contact with Picklist choose
     */
    private void setContactType(Contact con){
        
        //contact Id == null is new add contact
        String conType = con.Id == null ? mConType.get(acc.Id) : mConType.get(con.Id);
        
        con.Primary_Contact__c = false;
        con.Finance_Contact__c = false;
        
        if(conType == 'Account') con.Primary_Contact__c = true;
        if(conType == 'Finance') con.Finance_Contact__c = true;
        if(conType == 'Account/Finance'){ 
            con.Primary_Contact__c = true;
            con.Finance_Contact__c = true;
        }
    }
    
    /**
     *  Edited Company Contact by Row
     */
    public Pagereference editedComContact(){
        DTOCompanyContact dtoComCon = lstComContacts.get(editedIndex);
        dtoComCon.isEdited = true;
        isEditedContact = true;
        isAddNewMode = false;
        return null;
    }
    
    /**
     *  Cancel Edited Company Contact by Row
     */
    public Pagereference cancelEditedComContact(){
        DTOCompanyContact dtoComCon = lstComContacts.get(editedIndex);
        dtoComCon.isEdited = false;
        isEditedContact = false;
        queryWithSortedList(currentSoredField, isDESC);
        return null;
    }
    
    /**
     *  Save Edited Company Contact
     */
    public Pagereference saveEditedComContact(){
        
        DTOCompanyContact dtoComCon = lstComContacts.get(editedIndex);
        
        setContactType(dtoComCon.contact);
        String newPhotoUrl = replaceUploadImage(dtoComCon.contact.Profile_Photo__c, dtoComCon.contact.Id, false);
        if(newPhotoUrl != null) dtoComCon.contact.Profile_Photo__c = newPhotoUrl;
        
        //System should provide validation and error message to ensure the account always has both
        if(!checkAccountHasPrimaryAndFinance(dtoComCon.contact)){
            //Customer can select a contact who has left the company as a primary / finance contact
            dtoComCon.errorStatus = '';
            if(!checkLeftComPriFinContact(dtoComCon.contact)){
                isSuccessSave = checkSaveStatus(new List<Database.Saveresult>{Database.update(dtoComCon.contact)});
                
                if(isSuccessSave){
                    dtoComCon.isEdited = false;
                    isEditedContact = false;
                    
                    //reinit Primary & Finance Contact for find is new set to Primary or Finance contact type
                    initAccPriFinContact();
                    //reinit list for show new add contact
                    queryWithSortedList(currentSoredField, isDESC);
                }
            }else{
                dtoComCon.errorStatus = 'Please select another contact as your primary or finance contact before you change this status to left company';
                isSuccessSave = false;
            }
        }else{
            //add error message
            Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Account must have both related Primary & Financial Contact.'));
            isSuccessSave = false;
        }
        return null;
    }
    
    private Boolean checkLeftComPriFinContact(Contact con){
        return (con.Contact_Status__c == CONTACT_STATUS_LEFT_COMPNAY && (con.Primary_Contact__c || con.Finance_Contact__c));
    }
    
    //System should provide validation and error message to ensure the account always has both
    private Boolean checkAccountHasPrimaryAndFinance(Contact con){
        Contact oldContact = [select id, Primary_Contact__c, Finance_Contact__c from Contact where Id = :con.Id];
        if(oldContact.Primary_Contact__c || oldContact.Finance_Contact__c){
            if(!con.Primary_Contact__c && !con.Finance_Contact__c){
                return true;
            }
        }
        
        //for Account/Finance Type
        if((oldContact.Primary_Contact__c && oldContact.Finance_Contact__c) && (con.Primary_Contact__c && con.Finance_Contact__c)) return false;
        if((oldContact.Primary_Contact__c && oldContact.Finance_Contact__c) && (con.Primary_Contact__c || con.Finance_Contact__c)) return true; 
        return false;
    }
    
    /**
     *  Check new upload image and save it as Attachment
     */
    private static String baseURL = 'https://'+ApexPages.currentPage().getHeaders().get('Host') + Site.getPathPrefix();
    private static final String UPLOAD_IMAGE_PREFIX = 'data:image';
    private static final String UPLOAD_IMAGE_SUFFIX = 'base64,';
    
    private static final String TEXTAREA_IMAGEURL = '<img alt="User-added image" src="/servlet/servlet.FileDownload?file={0}"></img>';
    
    //https://gumtree--pro--c.cs18.content.force.com/servlet/servlet.ImageServer?id=01511000000PMoi&oid=00D110000008MjU
    private static String docURL = baseURL + '/servlet/servlet.ImageServer?id={0}&oid=' + Userinfo.getOrganizationId();
                                    
    private String replaceUploadImage(String base64String, Id parentId, Boolean isAdImage){
        
        if(base64String == null || !base64String.startsWith(UPLOAD_IMAGE_PREFIX)) return null;
        
        String replaceString = UPLOAD_IMAGE_PREFIX + base64String.substringBetween(UPLOAD_IMAGE_PREFIX,UPLOAD_IMAGE_SUFFIX) + UPLOAD_IMAGE_SUFFIX;
        base64String = base64String.replace(replaceString,'');
        
        if(isAdImage){
            
            List<Document>lstDocs = [select Id from Document where Name=:parentId];
            if(!lstDocs.isEmpty()) delete lstDocs;
            
            //standard salesforce folder
            Folder f = [select Id from Folder where Name='Public Folder' limit 1];
            Document doc = new Document(Name=parentId, FolderId=f.Id, IsPublic=true, ContentType='image/png', Body=Encodingutil.base64Decode(base64String));
            insert doc;
            
            return String.format(docURL, new String[] { doc.Id });
        }else{
            
            //create Attachment from base64 string of upload image
            List<Attachment>lstAtts = [select Id from Attachment where ParentId=:parentId and Name=:parentId];
            if(!lstAtts.isEmpty()) delete lstAtts;
            
            Attachment att = new Attachment(Name=parentId, ParentId = parentId, Body=Encodingutil.base64Decode(base64String));
            insert att;
            
            return String.format(TEXTAREA_IMAGEURL, new String[] { att.Id });
        }
    }
    
    /**
     *  Check DML Statement process success or not
     */
    private Boolean checkSaveStatus(List<Database.Saveresult>lstResults){
        for(Database.Saveresult result : lstResults){
            if(!result.isSuccess()) return false;
        }
        return true;
    }
    
    /**
     *  Get Contact Type picklist
     */
    public List<SelectOption> getContactType(){
        return new List<SelectOption>{
            new SelectOption('Standard', 'Standard'),
            new SelectOption('Account', 'Account'),
            new SelectOption('Finance', 'Finance'),
            new SelectOption('Account/Finance', 'Account/Finance')
        };
    }
    
    /**
     *  Get Contact Status picklist
     */
    public List<SelectOption> getContactStatus(){
        return new List<SelectOption>{
            new SelectOption('Active', 'Active'),
            new SelectOption('Left Company', 'Left Company')
        };
    }
    
    /**
     *  Get the string of billingAddress
     *  @return String
     */
    public String getBillingAddressDisplay(){
        String addr = (String.isBlank(acc.BillingStreet)?'':acc.BillingStreet +'<br/>')+
                      (String.isBlank(acc.BillingCity)?'':acc.BillingCity +'<br/>')+                      
                      (String.isBlank(acc.BillingState)?'':acc.BillingState +'<br/>')+
                      (String.isBlank(acc.BillingPostalCode)?'':acc.BillingPostalCode+', ')+
                      (String.isBlank(acc.BillingCountry)?'':acc.BillingCountry);

        return addr;
    }
    
    public String getBillingAddress(){
        String addr = (String.isBlank(acc.BillingStreet)?'':acc.BillingStreet +'\n')+
                      (String.isBlank(acc.BillingCity)?'':acc.BillingCity +'\n')+                     
                      (String.isBlank(acc.BillingState)?'':acc.BillingState +'\n')+
                      (String.isBlank(acc.BillingPostalCode)?'':acc.BillingPostalCode +', ')+
                      (String.isBlank(acc.BillingCountry)?'':acc.BillingCountry);
        return addr;
    }
    
    /**
     *  Class manage index of list company contact
     */
    class DTOCompanyContact{
        public Integer index{get;set;}
        public Contact contact{get;set;}
        public Boolean isEdited{get;set;}
        public String errorStatus{get;set;}
        public DTOCompanyContact(Integer ind, Contact con){
            this.index = ind;
            this.contact = con;
            this.isEdited = false;
            this.errorStatus = '';
        }
        
        public String getProfilePhoto(){
            return P2P_Utils.attachmentPhoto(contact.Id);
        }
    }
    
    /**
     *  Company Contact Records Sorted
     */
    public String sortByField { get; set; }
    public Boolean isDESC { get; set; }
    private String currentSoredField; 
    
    public PageReference sortComContact(){
        if(currentSoredField == sortByField){ 
            //Sort on same column
            isDESC = !isDESC; 
        }else{
            //Sort another column
            currentSoredField = sortByField;
            isDESC = true;
        }
        queryWithSortedList(currentSoredField, isDESC);
        return null;
    }
    
    private void queryWithSortedList(String colName, Boolean byDESC){
        
        String accId = acc.Id;
        
        String queryWhere = 'Where AccountId=:accId and Contact_Status__c=:filterType ';
        queryWhere += 'order by '+ colName + (byDESC ? ' desc' : ' asc');
        List<Contact> lstContacts = DataBase.query('Select Id From Contact ' + queryWhere);
        
        totalResultSize = lstContacts.size();
        pageNumList = new List<Integer>();
        mPaging = new Map<Integer, List<Id>>();
        
        Integer p = 1;
        for(Contact con : lstContacts){
            if(!mPaging.containsKey(p)){
                mPaging.put(p, new List<Id>());
                pageNumList.add(p);
            }
            if(mPaging.get(p).size() == listSize){
                p++;
                mPaging.put(p, new List<Id>());
                pageNumList.add(p);
            }
            mPaging.get(p).add(con.Id);
        }
        
        curPage = 1;
        if(mPaging.get(curPage) == null){
            mPaging.put(curPage, new List<Id>());
        }
        
        List<Id> pageList = mPaging.get(curPage);
        createResultRowsList(pageList);
    }
    
    private void createResultRowsList(List<Id> listIds){
        lstComContacts = new List<DTOCompanyContact>();
        mConType = new Map<Id, String>();
        
        String queryWhere = 'Where Id IN: listIds order by ' + currentSoredField + (isDESC ? ' desc' : ' asc');
        List<Contact>lstContacts = DataBase.query('Select Id, Name, Title, Primary_Contact__c, Finance_Contact__c, Standard__c, Phone, LastName, FirstName, Email, Contact_Status__c, Profile_Photo__c From Contact ' + queryWhere);
        
        Integer index = 0;
        for(Contact con : lstContacts){
            lstComContacts.add(new DTOCompanyContact(index, con));
            mConType.put(con.Id, getConType(con));
            index++;                        
        }
    }
    
    private String getConType(Contact con){
        if(con.Primary_Contact__c){
            if(con.Finance_Contact__c) return 'Account/Finance';
            else return 'Account';
        }else{ 
            if(con.Finance_Contact__c) return 'Finance';
        }
        return 'Standard';
    }
    
    /**
     *  Company Contact Paging
     */
    public Integer listSize{get;set;}
    public List<SelectOption> listSizeOptions { get; set; }
    public Integer curPage { get; set; }
    public Map<Integer, List<Id>> mPaging { get; set; }
    private Integer totalResultSize = 0;
    public List<Integer> pageNumList { get; set;}
    
    public PageReference loadComContacts(){
        currentSoredField = sortByField;
        isDESC = true;
        queryWithSortedList(currentSoredField, isDESC);
        return null;
    }
    
    private void defaultPaginationProperties(){
        listSize = 10;
        listSizeOptions = new List<SelectOption>();
        listSizeOptions.add(new SelectOption('10', '10 per page'));
        listSizeOptions.add(new SelectOption('20', '20 per page'));
        listSizeOptions.add(new SelectOption('50', '50 per page'));
    }
    
    public Integer getStartIndex() {
        return curPage == 0 || curPage == 1? curPage : ((curPage - 1) * listSize) + 1;
    }
    
    public Integer getEndIndex() {
        Integer endInd = getStartIndex() + listSize - 1;
        return endInd > totalResultSize ? totalResultSize : endInd;
    }
     
    public Integer getTotalResultSize(){
        return totalResultSize;
    }
    
    public Integer getTotalPageSize(){
        return mPaging.size();
    }
    
    public PageReference goToPage(){
        createResultRowsList(mPaging.get(curPage));
        return null;
    }
    
    public PageReference goNextPage() {
        if(totalResultSize > curPage * listSize) {
            curPage++;
            createResultRowsList(mPaging.get(curPage));
        }
        return null;
    }    
    
    public PageReference goPreviousPage() {   
        if(curPage > 1){
            curPage--;
            createResultRowsList(mPaging.get(curPage));
        }
        return null;
    }
     
    public boolean getPrevRequired() {
        return curPage > 1; 
    }
    
    public boolean getNextRequired() {
        return curPage * listSize < totalResultSize;
    }
    
    //*************  Packages  - Get from Gumtree BAPI ****************
    public List<P2P_GumtreeBAPI.GumtreePackage> retrievePackages { get; set; }//List returned by webservice
    public List<P2P_GumtreeBAPI.GumtreePackage> lstOveralPackages { get; set; } //List after filters
    public List<P2P_GumtreeBAPI.GumtreePackage> lstPackages { get; set; }// List after paging
    private final String ALL_PKG_STATUS = 'All package status';
    private final String ACTIVE_PKG_STATUS = 'Active packages';
    private final String EXP_PKG_STATUS = 'Expired packages';
    public String pkgStatus { get; set; }
    public List<SelectOption> lpkgOptions { get; set; }
    public String searchPkgKey { get; set; }
    public String errPkgRetrieveMsg { get; set; }
    
    private void initPackages(){
        searchPkgKey = '';
        pkgStatus = ACTIVE_PKG_STATUS;
        lpkgOptions = new List<SelectOption>();
        lpkgOptions.add(new SelectOption(ALL_PKG_STATUS, ALL_PKG_STATUS));
        lpkgOptions.add(new SelectOption(ACTIVE_PKG_STATUS, ACTIVE_PKG_STATUS));
        lpkgOptions.add(new SelectOption(EXP_PKG_STATUS, EXP_PKG_STATUS));
        retrievePackages();
        defaultPaginationPropertiesPackage();
        
        filterPackageChanged();
        sortByFieldPackage = 'name';
        loadPackageToList();
        
    }
    
    public void loadPackageToList(){
        currentSoredFieldPackage = sortByFieldPackage;
        isDESCPackage = true;
        queryWithSortedPackageList(currentSoredFieldPackage, isDESCPackage);
    }
    
    public void retrievePackages(){
        String accNumber = [Select AccountNumber From Account Where Id =: acc.Id].AccountNumber;
        retrievePackages = new List<P2P_GumtreeBAPI.GumtreePackage>();
        P2P_GumtreeBAPI.retrievePackagesList(accNumber, retrievePackages, acc.Private_Key__c, acc.Bapi_Key__c);
        errPkgRetrieveMsg = '';
        if(retrievePackages.size() == 1 && !retrievePackages[0].isSuccess){
            errPkgRetrieveMsg = retrievePackages[0].errMsg;
        }
    }
    
    public PageReference filterPackageChanged(){
        searchPkgKey = '';
        lstOveralPackages = new List<P2P_GumtreeBAPI.GumtreePackage>();
        for(P2P_GumtreeBAPI.GumtreePackage pck : retrievePackages){
            if(!pck.isSuccess) continue;
            if(pkgStatus == ALL_PKG_STATUS){
                lstOveralPackages.add(pck);
            }else{
                 if(pkgStatus == ACTIVE_PKG_STATUS && pck.end_date >= Date.today()){
                    lstOveralPackages.add(pck);
                 }else if(pkgStatus == EXP_PKG_STATUS && pck.end_date < Date.today()){
                    lstOveralPackages.add(pck);
                 }
            }
        }
        loadPackageToList();
        return null;
    }
    
    public PageReference doPackageSearch(){
        pkgStatus = ALL_PKG_STATUS;
        lstOveralPackages = new List<P2P_GumtreeBAPI.GumtreePackage>();
        for(P2P_GumtreeBAPI.GumtreePackage pck : retrievePackages){
            if(!pck.isSuccess) continue;
            if(
                pck.pkgName.contains(searchPkgKey) ||
                pck.pkgId.contains(searchPkgKey) ||
                pck.package_type_id.contains(searchPkgKey)
            ) lstOveralPackages.add(pck);
        }
        loadPackageToList();
        return null;
    }
    
    /**
     *  Package Records Sorted
     */
    public String sortByFieldPackage { get; set; }
    public Boolean isDESCPackage { get; set; }
    private String currentSoredFieldPackage; 
    
    public PageReference sortPackage(){
        if(currentSoredFieldPackage == sortByFieldPackage){ 
            //Sort on same column
            isDESCPackage = !isDESCPackage; 
        }else{
            //Sort another column
            currentSoredFieldPackage = sortByFieldPackage;
            isDESCPackage = true;
        }
        queryWithSortedPackageList(currentSoredFieldPackage, isDESCPackage);
        return null;
    }
    
    private void queryWithSortedPackageList(String colName, Boolean byDESC){
        totalResultSizePackage = lstOveralPackages.size();
        pageNumListPackage = new List<Integer>();
        mPagingPackage = new Map<Integer, List<P2P_GumtreeBAPI.GumtreePackage>>();
        
        Integer p = 1;
        for(P2P_GumtreeBAPI.GumtreePackage pck : lstOveralPackages){
            if(!mPagingPackage.containsKey(p)){
                mPagingPackage.put(p, new List<P2P_GumtreeBAPI.GumtreePackage>());
                pageNumListPackage.add(p);
            }
            if(mPagingPackage.get(p).size() == listSizePackage){
                p++;
                mPagingPackage.put(p, new List<P2P_GumtreeBAPI.GumtreePackage>());
                pageNumListPackage.add(p);
            }
            mPagingPackage.get(p).add(pck);
        }
        
        curPagePackage = 1;
        if(mPagingPackage.get(curPagePackage) == null){
            mPagingPackage.put(curPagePackage, new List<P2P_GumtreeBAPI.GumtreePackage>());
        }
        
        List<P2P_GumtreeBAPI.GumtreePackage> pageList = mPagingPackage.get(curPagePackage);
        createResultRowsListPackage(pageList);
    }
    
    private void createResultRowsListPackage(List<P2P_GumtreeBAPI.GumtreePackage> listGtP){
        //Generally this method query all fields from by given Ids in SF, but this time is special with DTO
        lstPackages = listGtP;
        //lstPackages = lstOveralPackages;
    }
    
    /**
     *  Package Paging
     */
    public Integer listSizePackage{get;set;}
    public List<SelectOption> listSizeOptionsPackage { get; set; }
    public Integer curPagePackage { get; set; }
    public Map<Integer, List<P2P_GumtreeBAPI.GumtreePackage>> mPagingPackage { get; set; }
    private Integer totalResultSizePackage = 0;
    public List<Integer> pageNumListPackage { get; set;}
    
    private void defaultPaginationPropertiesPackage(){
        listSizePackage = 10;
        listSizeOptionsPackage = new List<SelectOption>();
        listSizeOptionsPackage.add(new SelectOption('10', '10 per page'));
        listSizeOptionsPackage.add(new SelectOption('20', '20 per page'));
        listSizeOptionsPackage.add(new SelectOption('50', '50 per page'));
    }
    
    public Integer getStartIndexPackage() {
        return curPagePackage == 0 || curPagePackage == 1? curPagePackage : ((curPagePackage - 1) * listSizePackage) + 1;
    }
    
    public Integer getEndIndexPackage() {
        Integer endInd = getStartIndexPackage() + listSizePackage - 1;
        return endInd > totalResultSizePackage ? totalResultSizePackage : endInd;
    }
     
    public Integer gettotalResultSizePackage(){
        return totalResultSizePackage;
    }
    
    public Integer getTotalPageSizePackage(){
        return mPagingPackage.size();
    }
    
    public PageReference goToPagePackage(){
        createResultRowsListPackage(mPagingPackage.get(curPagePackage));
        return null;
    }
    
    public PageReference goNextPagePackage() {
        if(totalResultSizePackage > curPagePackage * listSizePackage) {
            curPagePackage++;
            createResultRowsListPackage(mPagingPackage.get(curPagePackage));
        }
        return null;
    }    
    
    public PageReference goPreviousPagePackage() {   
        if(curPagePackage > 1){
            curPagePackage--;
            createResultRowsListPackage(mPagingPackage.get(curPagePackage));
        }
        return null;
    }
     
    public PageReference goFirstPagePackage() {
        curPagePackage = 1;
        createResultRowsListPackage(mPagingPackage.get(curPagePackage));
        return null;
    }    
     
    public PageReference goLastPagePackage() {   
        curPagePackage = mPagingPackage.size();
        createResultRowsListPackage(mPagingPackage.get(curPagePackage));
        return null;
    }

    public boolean getPrevRequiredPackage() {
        return curPagePackage > 1; 
    }
    
    public boolean getNextRequiredPackage() {
        return curPagePackage * listSizePackage < totalResultSizePackage;
    }
     
    public boolean getFirstRequiredPackage() {
        return curPagePackage > 1;
    }
    
    public boolean getLastRequiredPackage() {
        return curPagePackage < mPagingPackage.size();
    }
    
    // Alert banner at top of the page - Work in progress by Steve Paul
    public List<PKB_Status_Message__c> msgErr {
        get {
            List<PKB_Status_Message__c> systemMsg = new List<PKB_Status_Message__c>(); 
            for(PKB_Status_Message__c sm: [SELECT MessageText__c, Message_Type__c, Message_Start_DateTime__c, Message_End_DateTime__c, Module__c, Account__c
                                                  FROM PKB_Status_Message__c
                                                 WHERE Status__c = 'Active'
                                                  AND Module__c = 'Company'
                                                  AND (Account__c = :acc.id OR Account__c = '')
                                                  AND ((Message_Start_DateTime__c < :system.now() AND
                                                        Message_End_DateTime__c   > :system.now())
                                                  OR   (Message_Start_DateTime__c = null AND
                                                        Message_End_DateTime__c   = null)) order by CreatedDate desc LIMIT 1
                                                  ]){
                systemMsg.add(sm);
            }
            return systemMsg;
        } 
        set;
    }   
    
    // get user agent for Google Analytics tracking
    public String getUA() {
        return ApexPages.currentPage().getHeaders().get('User-Agent');
    } 
}