global  class TreeGeographySelectingController {
    
    final static String TYPE_LEVEL1 = 'COUNTRY';
    
    public List<DTOTreeItem> lstCountry{get;set;}
    public String selectedGeography{get; set;}
    public String searchFilter{get;set;}
    public Boolean isExistSelected{get; set;}
      
    global TreeGeographySelectingController(){
    	 
        resetCountry(); 
        searchFilter='country';  
    } 
    
     
    public Boolean isShowCancel{
        get{
            String froIfr = ApexPages.currentPage().getParameters().get('froIfr');
            return froIfr == null || froIfr=='' ? false : Boolean.valueOf( froIfr );
        }set;
    }
    private Set<String> setOldSelectedCountry = new Set<String>();
    private Map<String ,Map<String,List<TargetingGeographyAssociation__c>>> mapOldSelectedCity = new Map<String ,Map<String,List<TargetingGeographyAssociation__c>>>();
    private Map<String, List<Geography__c>> mapExtParentChilds = new Map<String, List<Geography__c>>();

    Set<String> setExistIdsLv2 = new Set<String>();
    
    
    //for get the value that selected 
    private void doSelectedGeographies(){
        setOldSelectedCountry = new Set<String>(); 
         
        try{ 
            targetId = ApexPages.currentPage().getParameters().get('targetId');                 
            if( targetId == null || targetId==''){           
                return;
            }

             Set<String> setExistGeoIds = new Set<String>(); 
             for( TargetingGeographyAssociation__c targeting: [Select Geography__c, Geography__r.Id, Geography__r.Node_ID__c ,Geography__r.Type__c, Geography__r.Name   From TargetingGeographyAssociation__c  Where Targeting__c=:targetId])
             {
             	if(targeting.Geography__r.Node_ID__c == null)  //Level 1
             	{
             		setOldSelectedCountry.add(targeting.Geography__c);
             	}
                setExistGeoIds.add(targeting.Geography__c);
             }
             
             for(Geography__c geo :[Select Name, Id, Node_ID__c, (Select id, Name, Node_ID__c From Geographies__r limit 1) From Geography__c where id IN: setExistGeoIds])
             {
                if(!mapExtParentChilds.containskey(geo.Node_ID__c)) mapExtParentChilds.put(geo.Node_ID__c, new List<Geography__c>());
                mapExtParentChilds.get(geo.Node_ID__c).add(geo);
             }
             
             
        }catch(Exception e){
             ApexPages.Message lastNameMsg = new ApexPages.Message(ApexPages.Severity.Error, e.getMessage());
             ApexPages.addMessage(lastNameMsg);
        }
    }
    
    
    //get all country, existing city into the tree
    private void initCountry(){
        
        lstCountry = new List<DTOTreeItem>();
        if(!mapExtParentChilds.values().isEmpty()) isExistSelected = true;
        for(Geography__c con : [Select Id, Name From Geography__c Where Type__c=:TYPE_LEVEL1 And Node_ID__c=null  order by Name]){
            String key = con.id;
            //pos,treeId,treeName,ParrentId,treeLv,isExpand,isHideCheckBox
             
            
            DTOTreeItem dto =new DTOTreeItem( lstCountry.size(), con.id, con.Name, true , null,1,false, false);
            //for country Top Level
            if( setOldSelectedCountry.contains( key ))
            {
                dto.isSelected = true;
                dto.isExpand = true;
            }
            // Add Exist child to tree
            doSetExistValueToTree(dto, key);
            lstCountry.add( dto);
        }
        jsonObject=   JSON.serialize(lstCountry);   
                    
    }
    
    // Adding Existing TargetingAssociation to tree when page loaded
    private void doSetExistValueToTree(DTOTreeItem dto, String key)
    {
        if(mapExtParentChilds.containsKey(key))
        {
            for(Geography__c geo : mapExtParentChilds.get(key))
            {
                DTOTreeItem dtoChild =  new DTOTreeItem(dto.lstChild.size(), geo.Id , geo.Name, !geo.Geographies__r.isEmpty() , key ,null,false,false); 
                dtoChild.isExpand = true;   
                dtoChild.isSelected = true;
                dto.lstChild.add(dtoChild);
                
                doSetExistValueToTree(dtoChild ,geo.id);
                
                // Bunhor @ 23-July-2014: auto expand a country if its city default selected.
                dto.isExpand = true;
            }
        }   
    }
    
    public String targetId{get;set;}
    public Boolean isSaveError{get;set;}
    public String strValue{get;set;}
    public String countryValue{get;set;}
    
    //All objects that are checked in the tree have to be related to the targeting record.
    List<TargetingGeographyAssociation__c> lstTgGeographies;
    //All ids of association to be deleted
    Set<String> assoNotToDelete;
    
    //process when click on save action
    public void saveRecords(){
        
        try{
            lstTgGeographies = new List<TargetingGeographyAssociation__c>();
            assoNotToDelete = new Set<String>();
            
            convertJsonToDTOTreeItem();          
            String lineItemId = ApexPages.currentPage().getParameters().get('itemId');          
            isSaveError = false;

            if( targetId == null || targetId==''){
                lineItemId = lineItemId == null ? '' : lineItemId;           
                Targeting__c t = new Targeting__c(Description__c = 'Tar_LineItemId ' + lineItemId);
                insert t;
                targetId = t.Id;
                System.debug('============Targeting__c.id========'+t.id);
            }
            
            strValue='';
            countryValue = '';
            
            for(DTOTreeItem  dto: lstCountry){
                if(dto.isSelected){
                     String conId = dto.treeId;
                     TargetingGeographyAssociation__c tca = new TargetingGeographyAssociation__c(Targeting__c = targetId ,Geography__c  = conId , TargetGeography__c  = targetId + conId);
                     lstTgGeographies.add(tca);
                     countryValue = countryValue + dto.treeName +',';
                     assoNotToDelete.add(tca.TargetGeography__c);  
                       
                }
                //for cities
                createdTarAssFromSelectedValue(dto.lstChild); // Bunhor @ 22-July-2014 (take out of IF above since save the city even the country not selected)
            }

            if(!lstTgGeographies.isEmpty()){        
                 upsert lstTgGeographies TargetGeography__c ;            
            }

            delete [Select Id From TargetingGeographyAssociation__c Where Targeting__c= :targetId And TargetGeography__c Not In :assoNotToDelete ];
                        
            jsonObject=   JSON.serialize(lstCountry);   
            
            if( lineItemId <> null && lineItemId != ''){
                List<OpportunityLineItem> lstOppItem = [ Select City_Description__c From OpportunityLineItem Where Id =: lineItemId];
                if( !lstOppItem.isEmpty() ){
                     strValue = strValue !='' ? strValue.substring(0, (strValue.length() -1)  ) : strValue;
                     countryValue = countryValue !='' ? countryValue.substring(0, (countryValue.length() -1)  ) : countryValue;
                     OpportunityLineItem oppLI = lstOppItem.get(0);
                     oppLI.City_Description__c = strValue ;
                     oppLI.Countries_Description__c = countryValue;
                     update oppLI;
                    
                }                  
            }
        }catch(Exception e){
             ApexPages.Message lastNameMsg = new ApexPages.Message(ApexPages.Severity.Error, e.getMessage());
             ApexPages.addMessage(lastNameMsg);
             isSaveError = true;
        }       
    }
    
    // Pre-creating TargetingAssociation from selected value in tree
    private void createdTarAssFromSelectedValue(List<DTOTreeItem> lstGeo)
    {
        for(DTOTreeItem geo: lstGeo)
        {
            if(geo.isSelected)
            {
                TargetingGeographyAssociation__c targ = new TargetingGeographyAssociation__c(Targeting__c = targetId ,Geography__c  = geo.treeId , TargetGeography__c  = targetId + geo.treeId);
                lstTgGeographies.add(targ);
                assoNotToDelete.add(targ.TargetGeography__c);
                strValue = strValue + geo.treeName +',';
            }
            createdTarAssFromSelectedValue(geo.lstChild);
        }
    }
    
    // JS Remoting action called when searching for a  country
    @RemoteAction
    global static List<Geography__c> searchCountry(String searchTerm) { 
        List<Geography__c> lstTmp = new List<Geography__c>();
        try{
            searchTerm = searchTerm<> null ? searchTerm.trim() : '';     		
    		String queryName = '%' + searchTerm.trim() + '%'; 
    		String queryString = 'Select Id, Name, Type__c From Geography__c where Name Like :queryName limit 20';	 	
    	    lstTmp =  Database.query( queryString ); 
               
        }catch(Exception e){
             ApexPages.Message lastNameMsg = new ApexPages.Message(ApexPages.Severity.Error, e.getMessage());
             ApexPages.addMessage(lastNameMsg);
        }
        
        return lstTmp;
    }
    
    private Boolean isExistingKey(List<DTOTreeItem> lstDTOTreeItem,String key){
        if( lstDTOTreeItem.isEmpty() )return false;
        for(DTOTreeItem dto: lstDTOTreeItem){
            if(dto.treeId == key )return true;
        }       
        return false;
    }
    
    private Map<String, Geography__c> mapLevelGeo = new Map<String, Geography__c>();
    private void getLevelMapping(String nodeId)
    {
        List<Geography__c> lstGeographies = [Select Id, Name, Node_ID__c, (Select Id From Geographies__r limit 1) From Geography__c where id =: nodeId];
        if(!lstGeographies.isEmpty() && lstGeographies.get(0).Node_Id__c != null)
        {
            String nId = lstGeographies.get(0).Node_Id__c+'';
            mapLevelGeo.put(nId, lstGeographies.get(0));
            getLevelMapping(nId);
        }
    }
    
    private DTOTreeItem getExistingTreeItem(List<DTOTreeItem> lstDTOTreeItem,String key){    
        for(DTOTreeItem dto: lstDTOTreeItem){
            if(dto.treeId == key )return dto;
        }  
        return null;  
    }
    //store jsonobject on page
    public String jsonObject{get;set;}
    //add country into tree when search found
    public void addCountry(){
        try{    
            if( selectedGeography== null || selectedGeography=='')return;       
            convertJsonToDTOTreeItem();
            collapsedAllNode(lstCountry);         
            if(TYPE_LEVEL1.equals(searchFilter)){
                Integer posCon = null;
                for(DTOTreeItem dto: lstCountry){
                    if( dto.treeId == selectedGeography){
                        posCon = dto.pos;
                    }               
                }
                if(posCon != null)
                {
                    lstCountry.get(posCon).isExpand = true;
                    lstCountry.get(posCon).isSelected = true;
                }
                
            }else{
                //case searchFilter for child level
                List<Geography__c> lstSelectedGeo =[Select id,Name, Node_ID__c, Type__c,(Select Id From Geographies__r limit 1)  From Geography__c where id=: selectedGeography ];
                if(!lstSelectedGeo.isEmpty())
                {
                    Geography__c c =  lstSelectedGeo.get(0);
                    getLevelMapping(c.Node_ID__c);
                    // Add itself to map
                    mapLevelGeo.put(c.Node_ID__c, c);
                    for(DTOTreeItem dto: lstCountry )
                    {
                        if(mapLevelGeo.containsKey(dto.treeId))
                        {
                            dto.isExpand = true;
                            dto.isSelected = true;
                            
                            addSearchGeoToTree(dto, dto.treeId, c); 
                        }     
                    }
                }               
            }
            jsonObject=   JSON.serialize(lstCountry);
            saveRecords();
            mapLevelGeo = new Map<String, Geography__c>();
        }catch(Exception e){
             ApexPages.Message lastNameMsg = new ApexPages.Message(ApexPages.Severity.Error,  e.getMessage()); //e.getStackTraceString()
             ApexPages.addMessage(lastNameMsg);
        }
    }
    
   private void addSearchGeoToTree(DTOTreeItem dto, String key, Geography__c c)
   {
   		Geography__c geoChild = mapLevelGeo.get(key); 
        if(geoChild != null)
        {
    		Boolean isAlreadyExistChild = isExistingKey(dto.lstChild, geoChild.Id);

            DTOTreeItem dtoChild =  !isAlreadyExistChild ? new DTOTreeItem(dto.lstChild.size(), geoChild.Id , geoChild.Name, !geoChild.Geographies__r.isEmpty() , geoChild.Node_ID__c ,2, !geoChild.Geographies__r.isEmpty() ,false) 
                                    : getExistingTreeItem(dto.lstChild ,geoChild.Id);
            dtoChild.isExpand = true;
            dtoChild.isSelected = true;
            if(!isAlreadyExistChild)
            {
            	dto.lstChild.add(dtoChild); 
            }
            addSearchGeoToTree(dtoChild, geoChild.id, c);
        }
   }   
    //reset country
   public void resetCountry(){
        try{
            //getExisting country and city
            doSelectedGeographies();
            //generate tree 
            initCountry();
        }catch(Exception e){
             ApexPages.Message lastNameMsg = new ApexPages.Message(ApexPages.Severity.Error, e.getMessage());
             ApexPages.addMessage(lastNameMsg);
        }
        
    }
    
    //for map existing dto item 
    private Map<String,DTOTreeItem> getMapExistDTOItem(List<DTOTreeItem> lstItem){
        Map<String,DTOTreeItem> mapExistItem = new Map<String,DTOTreeItem>();
        for(DTOTreeItem dto : lstItem ){
            dto.isExpand = true;
            mapExistItem.put(dto.treeId, dto);
        }
        return mapExistItem;
    }
    
    List<DTOTreeItem> dtoChildGeo;
    //Process when clicking on each Geography(folder)
    public void getGeographies()
    {
        try
        {
            convertJsonToDTOTreeItem();
            collapsedAllNode(lstCountry);
            getMapExistDto(lstCountry);
            dtoChildGeo = new List<DTOTreeItem>();
            for(Geography__c c: [select id, name, (Select id, Type__c From Geographies__r limit 1) from Geography__c where Node_ID__c= : selectedGeography order by Name]){
                String key = c.id;
                DTOTreeItem dto = mapExistItem.containskey(key) ? mapExistItem.get(key) : new DTOTreeItem(dtoChildGeo.size(), c.id , c.name ,!c.Geographies__r.isEmpty(), selectedGeography ,null,false ,false);
                dtoChildGeo.add(dto);
                
            } 

            if(!dtoChildGeo.isEmpty()){
                addChildToParent(lstCountry, null);
            }
            
            
            convertDTOTreItemToJson();
        }catch(Exception e)
        {
             ApexPages.Message lastNameMsg = new ApexPages.Message(ApexPages.Severity.Error, e.getMessage());
             ApexPages.addMessage(lastNameMsg);
        }
    }
    
    // Call to add list of childs to parent node tree
    private void addChildToParent(List<DTOTreeItem> lstDto, DTOTreeItem dto)
    {
        for(DTOTreeItem  dtoTree: lstDto)
        {
            if(dtoTree.treeId.equals(selectedGeography))
            {
                dtoTree.lstChild = dtoChildGeo;
                //dtoTree.isExpand = true;
                //if(dto != null) dto.isExpand = true;
            }
            dtoTree.isExpand = true;
           // else dtoTree.isExpand = false;
           // System.debug('----------------->>dtoTree:'+dtoTree);
            addChildToParent(dtoTree.lstChild, dtoTree);
            
        }
    }
    
    // Get Mapping existing Dto item selected
    Map<String,DTOTreeItem> mapExistItem = new Map<String,DTOTreeItem>();
    private void getMapExistDto(List<DTOTreeItem> lstItem){
        
        for(DTOTreeItem dto : lstItem){
            dto.isExpand = true;
            mapExistItem.put(dto.treeId, dto);
            getMapExistDto(dto.lstChild);
            
        }
    }
    
    
    //for collape All node of tree
    private void collapsedAllNode(){
        for(DTOTreeItem  treeLv1: lstCountry ){
            treeLv1.isExpand= false;
            for(DTOTreeItem treelv2: treeLv1.lstChild){
                treelv2.isExpand= false;
                for(DTOTreeItem treelv3: treeLv2.lstChild){
                    treelv3.isExpand = false;
                }
            }
        }
    }
    
    private void collapsedAllNode(List<DTOTreeItem> lstDto)
    {
        for(DTOTreeItem  treeLv: lstDto)
        {
            treeLv.isExpand= false;
            collapsedAllNode(treeLv.lstChild);
        }
    }
    
    //for synchronize from page is tree select or not
    private void convertJsonToDTOTreeItem(){
        lstCountry = (List<DTOTreeItem>)JSON.deserialize(jsonObject,List<DTOTreeItem>.class);
    }
    //for control is tree select or not on page
    private void convertDTOTreItemToJson(){
        jsonObject=   JSON.serialize(lstCountry);   
    }
    
    
    
    public class DTOTreeItem {
        public Integer pos{get;set;}
        public String treeId{get;set;}
        public String treeName{get;set;}
        public String treeParrentId{get;set;}
        public List<DTOTreeItem> lstChild{get;set;}
        public Integer treeLv{get;set;}
        public Boolean isExpand{get;set;}
        public Boolean isHideCheckBox{get;set;}
        public Boolean isFolder{get;set;}
        public Boolean isSelected{get;set;}
        public DTOTreeItem(Integer pos,String treeId,String treeName,Boolean isFolder,String treeParrentId,Integer treeLv,Boolean isExpand,Boolean isHideCheckBox){
            this.treeId = treeId;
            this.treeName = treeName;
            this.treeParrentId = treeParrentId;
            this.pos = pos;
            this.treeLv = treeLv;
            this.isExpand = isExpand;
            this.isFolder = isFolder;
            this.isHideCheckBox = isHideCheckBox;
            this.lstChild = new List<DTOTreeItem>();
            this.isSelected = false;
        }       
    }
}