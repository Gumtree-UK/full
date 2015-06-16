global class TreeDeviceSelectionController {
	
	public List<DTOTreeItem> lstDevices{get;set;}
    public String selectedDevice{get; set;}
    
    public String targetId{get;set;}
    public Boolean isSaveError{get;set;}
    public String deviceDes{get;set;}
    public Boolean isExistSelected{get; set;}
    //store jsonobject on page
    public String jsonObject{get;set;}
    
    private Set<String> setOldSelectedDevices = new Set<String>();
    private Map<String, List<Devices__c>> mapExtParentChilds = new Map<String, List<Devices__c>>();
    private Set<String> setParentIds = new Set<String>();
    String proId;
    List<Product2> lstPro = new List<Product2>();
	
	global TreeDeviceSelectionController()
	{
		proId = Apexpages.currentPage().getParameters().get('proId');
		lstPro= [Select Devices__c, Fixed_device__c From Product2  where id= : proId];
		resetDevice();
	}
	
	
	public Boolean isShowCancel{
        get{
            String froIfr = ApexPages.currentPage().getParameters().get('froIfr');
            return froIfr == null || froIfr=='' ? false : Boolean.valueOf( froIfr );
        }set;
    }
    
    Set<String> setExistDevIds = new Set<String>();
    // get existing selected device 
    private void doSelectedDevices()
    {	
    	
    	setOldSelectedDevices = new Set<String>();
        try{
            
            targetId = ApexPages.currentPage().getParameters().get('targetId');                 
            if( targetId == null || targetId==''){           
                return;
            }

            for( TargetingDeviceAssociation__c targeting: [Select Device__c, Device__r.Id, Device__r.Node_ID__c , Device__r.Name   From TargetingDeviceAssociation__c  Where Targeting__c=:targetId])
            {
                setExistDevIds.add(targeting.Device__c);
                
                if(targeting.Device__r.Node_ID__c == null) //Level 1
                {
                	setOldSelectedDevices.add(targeting.Device__c);
                }
            }
             
            for(Devices__c dev :[Select Name, Id, Node_ID__c, (Select id, Name, Node_ID__c From Devices__r limit 1) From Devices__c where id IN: setExistDevIds])
            {
                if(!mapExtParentChilds.containskey(dev.Node_ID__c)) mapExtParentChilds.put(dev.Node_ID__c, new List<Devices__c>());
                mapExtParentChilds.get(dev.Node_ID__c).add(dev);
            }
             
             
        }catch(Exception e){
             ApexPages.Message lastNameMsg = new ApexPages.Message(ApexPages.Severity.Error, e.getMessage());
             ApexPages.addMessage(lastNameMsg);
        }
    	
    	
    }
    
    //Get all device && existing selected device into the tree
    private void initDevice()
    {
    	// 16-07-2014:
    	// #1.If PriceBookEntry.Product2.Devices__c = FALSE 
    	//    then the user cannot select any devices in the tree.
        // #2.If PriceBookEntry.Product2.Devices__c = TRUE && PriceBookEntry.Product2.Fixed_Device__c = FALSE 
        //    then the user can select from all of the devices in the Device__c.object
        // #3.If PriceBookEntry.Product2.Devices__c = TRUE && PriceBookEntry.Product2.Fixed_Device__c = TRUE 
        //    then the system should automatically select and add the devices to the TargetingDeviceAssociation.object related to the OpportunityLineItem

    	lstDevices = new List<DTOTreeItem>();
    	
    	List<Devices__c> lstDevToDisplay = new List<Devices__c>();

		if( proId == null || proId == ''){
		 	ApexPages.Message lastNameMsg = new ApexPages.Message(ApexPages.Severity.Error, 'Invalid product id.' );
            ApexPages.addMessage(lastNameMsg);
		 	return;
		}
    	
    	if(!lstPro.isEmpty() && !lstPro.get(0).Devices__c) // #1
    	{
		 	ApexPages.Message lastNameMsg = new ApexPages.Message(ApexPages.Severity.Error, 'No related device for this product.' );
            ApexPages.addMessage(lastNameMsg);
		 	return;
    	}
    	else if(!lstPro.isEmpty() && lstPro.get(0).Devices__c && lstPro.get(0).Fixed_device__c) // #3
    	{
    		Set<String> avalDevIds = new Set<String>();
    		Set<String> devNodeIds = new Set<String>();
    		// Get available Device From specific product
    		for(Available_Device__c avDev : [Select Available_Device__r.Id,  Available_Device__r.Node_ID__c, Available_Device__c From Available_Device__c Where Product__c=:proId])
    		{
    			avalDevIds.add(avDev.Available_Device__r.Id);
    			if(avDev.Available_Device__r.Node_ID__c != null) devNodeIds.add(avDev.Available_Device__r.Node_ID__c);
    		}
            // Need to retreive all parents Id even they not in availeDevice
    		getNodeDeviceParentIds(devNodeIds);
    		existDevParIds.addAll(devNodeIds);

    		// Device parent
            for(Devices__c dev :[Select Id, Dart_ID__c, Name, DFP_API_Name__c From Devices__c Where Id IN : existDevParIds])
            {   
            	setOldSelectedDevices.add(dev.id);
            }

            existDevParIds.addAll(avalDevIds);
            // Mapping to display when loading tree
            for(Devices__c dev :[Select Name, Id, Node_ID__c, (Select id, Name, Node_ID__c From Devices__r limit 1) From Devices__c where (id IN: existDevParIds And id NOT IN:setExistDevIds)])
            {
                if(!mapExtParentChilds.containskey(dev.Node_ID__c)) mapExtParentChilds.put(dev.Node_ID__c, new List<Devices__c>());
                mapExtParentChilds.get(dev.Node_ID__c).add(dev);
            }

    	}

    	if(!mapExtParentChilds.values().isEmpty()) isExistSelected = true;
        for(Devices__c dev : [Select Id, Name From Devices__c Where Node_ID__c=null order by Name]){ //[Select Id, Name From Devices__c Where Node_ID__c=null order by Name]
        	setParentIds.add(dev.id);
            String key = dev.id;
            //pos,treeId,treeName,ParrentId,treeLv,isExpand,isHideCheckBox
            DTOTreeItem dto =new DTOTreeItem(lstDevices.size(), dev.id, dev.Name, true , null,1,false, false);
            //for country Top Level
            if(setOldSelectedDevices.contains(key))
            {
                dto.isSelected = true;
                dto.isExpand = true;
            }
            // Add Exist child to tree
            doSetExistValueToTree(dto, key);
            
            lstDevices.add(dto);
        }
        jsonObject=   JSON.serialize(lstDevices);   
    }
    
    Set<String> existDevParIds = new Set<String>();
    private void getNodeDeviceParentIds(Set<String> devIds)
    {
    	Set<String> parIds = new Set<String>();
    	for(Devices__c d :[Select Id, Name, Node_ID__c From Devices__c where id IN: devIds])
    	{
    		if(d.Node_ID__c != null) 
    		{
    			parIds.add(d.Node_ID__c);
    			existDevParIds.add(d.Node_ID__c);
    		}
    	}
    	if(!parIds.isEmpty()) getNodeDeviceParentIds(parIds);
    }
    
    // Adding Existing TargetingAssociation to tree when page loaded
    private void doSetExistValueToTree(DTOTreeItem dto, String key)
    {
        if(mapExtParentChilds.containsKey(key))
        {
            for(Devices__c dev : mapExtParentChilds.get(key))
            {
                DTOTreeItem dtoChild =  new DTOTreeItem(dto.lstChild.size(), dev.Id , dev.Name, !dev.Devices__r.isEmpty() , key ,null,false,false); 
                dtoChild.isExpand = true;   
                dtoChild.isSelected = true;
                dto.lstChild.add(dtoChild);
                
                doSetExistValueToTree(dtoChild ,dev.id);
            }
        }   
    }
    
    
    //All objects that are checked in the tree have to be related to the targeting record.
    List<TargetingDeviceAssociation__c> lstTargDevices;
    //All ids of association to be deleted
    Set<String> assoNotToDelete;
    
    //process when click on save action
    public void saveRecords()
    {
    	
    	try{
            lstTargDevices = new List<TargetingDeviceAssociation__c>();
            assoNotToDelete = new Set<String>();
            
            convertJsonToDTOTreeItem();          
            String lineItemId = ApexPages.currentPage().getParameters().get('itemId');          
            isSaveError = false;

            if( targetId == null || targetId==''){
                lineItemId = lineItemId == null ? '' : lineItemId;           
                Targeting__c t = new Targeting__c(Description__c = 'Tar_LineItemId ' + lineItemId);
                insert t;
                targetId = t.Id;
            }
            
            deviceDes='';
            
            for(DTOTreeItem  dto: lstDevices){
                if(dto.isSelected){
                     String conId = dto.treeId;
                     TargetingDeviceAssociation__c tca = new TargetingDeviceAssociation__c(Targeting__c = targetId ,Device__c  = conId , TargetDevice__c  = targetId + conId);
                     lstTargDevices.add(tca);
                     deviceDes = deviceDes + dto.treeName +',';
                     assoNotToDelete.add(tca.TargetDevice__c);
                     //call to create child devices  
                     createdTarAssFromSelectedValue(dto.lstChild);   
                }
            }

            if(!lstTargDevices.isEmpty()){        
                 upsert lstTargDevices TargetDevice__c ;            
            }

            delete [Select Id From TargetingDeviceAssociation__c Where Targeting__c= :targetId And TargetDevice__c Not In :assoNotToDelete ];
                        
            jsonObject=   JSON.serialize(lstDevices);   
            
            if( lineItemId <> null && lineItemId != ''){
                List<OpportunityLineItem> lstOppItem = [ Select Device_Targeting__c From OpportunityLineItem Where Id =: lineItemId];
                if(!lstOppItem.isEmpty() ){
                     deviceDes = deviceDes !='' ? deviceDes.substring(0, (deviceDes.length() -1)) : deviceDes;
                     
                     OpportunityLineItem oppLI = lstOppItem.get(0);
                     oppLI.Device_Targeting__c = deviceDes ;
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
    private void createdTarAssFromSelectedValue(List<DTOTreeItem> lstDev)
    {
        for(DTOTreeItem dev: lstDev)
        {
            if(dev.isSelected)
            {
                TargetingDeviceAssociation__c targ = new TargetingDeviceAssociation__c(Targeting__c = targetId ,Device__c  = dev.treeId , TargetDevice__c  = targetId + dev.treeId);
                lstTargDevices.add(targ);
                assoNotToDelete.add(targ.TargetDevice__c);
                deviceDes = deviceDes + dev.treeName +',';
            }
            createdTarAssFromSelectedValue(dev.lstChild);
        }
    }
    
    // JS Remoting action called when searching for a  country
    @RemoteAction
    global static List<Devices__c> searchDevice(String searchTerm) { 
        List<Devices__c> lstTmp = new List<Devices__c>();
        try{
            searchTerm = searchTerm<> null ? searchTerm.trim() : '';     		
    		String queryName = '%' + searchTerm.trim() + '%'; 
    		String queryString = 'Select Id, Name, DFP_API_Name__c From Devices__c where Name Like :queryName limit 20';	 	
    	    lstTmp =  Database.query( queryString ); 
               
        }catch(Exception e){
             ApexPages.Message lastNameMsg = new ApexPages.Message(ApexPages.Severity.Error, e.getMessage());
             ApexPages.addMessage(lastNameMsg);
        }
        
        return lstTmp;
    }
    
    private Map<String, Devices__c> mapLevelDevices = new Map<String, Devices__c>();
    private void getLevelMapping(String nodeId)
    {
        List<Devices__c> lstDev = [Select Id, Name, Node_ID__c, (Select Id From Devices__r limit 1) From Devices__c where id =: nodeId];
        if(!lstDev.isEmpty() && lstDev.get(0).Node_Id__c != null)
        {
            String nId = lstDev.get(0).Node_Id__c+'';
            mapLevelDevices.put(nId, lstDev.get(0));
            getLevelMapping(nId);
        }
    }
    
    // Adding Device to tree when seached device found
    public void addDevice()
    {
    	
    	try{    
            if(selectedDevice== null || selectedDevice=='')return;       
            convertJsonToDTOTreeItem();
            collapsedAllNode(lstDevices);         
            if(setParentIds.contains(selectedDevice)){
                Integer posCon = null;
                for(DTOTreeItem dto: lstDevices){
                    if( dto.treeId == selectedDevice){
                        posCon = dto.pos;
                    }               
                }
                if(posCon != null)
                {
                    lstDevices.get(posCon).isExpand = true;
                    lstDevices.get(posCon).isSelected = true;
                }
                
            }else{
                //case searchFilter for child level
                List<Devices__c> lstSelectedDev =[Select id,Name, Node_ID__c, (Select Id From Devices__r limit 1)  From Devices__c where id=: selectedDevice ];
                if(!lstSelectedDev.isEmpty())
                {
                    Devices__c d =  lstSelectedDev.get(0);
                    getLevelMapping(d.Node_ID__c);
                    // Add itself to map
                    mapLevelDevices.put(d.Node_ID__c, d);
                    for(DTOTreeItem dto: lstDevices )
                    {
                        if(mapLevelDevices.containsKey(dto.treeId))
                        {
                            dto.isExpand = true;
                            dto.isSelected = true;
                            
                            addSearchDevToTree(dto, dto.treeId, d); 
                        }     
                    }
                }               
            }
            jsonObject=   JSON.serialize(lstDevices);
            saveRecords();
            mapLevelDevices = new Map<String, Devices__c>();
        }catch(Exception e){
             ApexPages.Message lastNameMsg = new ApexPages.Message(ApexPages.Severity.Error,  e.getMessage()); //e.getStackTraceString()
             ApexPages.addMessage(lastNameMsg);
        }	
    }
    
    private void addSearchDevToTree(DTOTreeItem dto, String key, Devices__c d)
    {
   		Devices__c devChild = mapLevelDevices.get(key); 
        if(devChild != null)
        {
    		Boolean isAlreadyExistChild = isExistingKey(dto.lstChild, devChild.Id);

            DTOTreeItem dtoChild =  !isAlreadyExistChild ? new DTOTreeItem(dto.lstChild.size(), devChild.Id , devChild.Name, !devChild.Devices__r.isEmpty() , devChild.Node_ID__c ,2, !devChild.Devices__r.isEmpty() ,false) 
                                    : getExistingTreeItem(dto.lstChild ,devChild.Id);
            dtoChild.isExpand = true;
            dtoChild.isSelected = true;
            if(!isAlreadyExistChild)
            {
            	dto.lstChild.add(dtoChild); 
            }
            addSearchDevToTree(dtoChild, devChild.id, d);
        }
    }
    
    private DTOTreeItem getExistingTreeItem(List<DTOTreeItem> lstDTOTreeItem,String key){    
        for(DTOTreeItem dto: lstDTOTreeItem){
            if(dto.treeId == key )return dto;
        }  
        return null;  
    }
    
    private Boolean isExistingKey(List<DTOTreeItem> lstDTOTreeItem,String key){
        if( lstDTOTreeItem.isEmpty() )return false;
        for(DTOTreeItem dto: lstDTOTreeItem){
            if(dto.treeId == key )return true;
        }       
        return false;
    }
    
    //reset Device
    public void resetDevice(){
        try{
            //getExisting Device
            doSelectedDevices();
            //generate tree 
            initDevice();
        }catch(Exception e){
             ApexPages.Message lastNameMsg = new ApexPages.Message(ApexPages.Severity.Error, e.getMessage());
             ApexPages.addMessage(lastNameMsg);
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
    
    
    List<DTOTreeItem> dtoChildDevice;
    //Process when clicking on each Device(folder)
    public void getDevices()
    {
    	try
        {
            convertJsonToDTOTreeItem();
            collapsedAllNode(lstDevices);
            getMapExistDto(lstDevices);
            dtoChildDevice = new List<DTOTreeItem>();
            for(Devices__c d: [select id, name, (Select id  From Devices__r limit 1) from Devices__c where Node_ID__c= : selectedDevice order by Name]){
                String key = d.id;
                DTOTreeItem dto = mapExistItem.containskey(key) ? mapExistItem.get(key) : new DTOTreeItem(dtoChildDevice.size(), d.id , d.name ,!d.Devices__r.isEmpty(), selectedDevice ,null,false ,false);
                dtoChildDevice.add(dto);
                
            } 

            if(!dtoChildDevice.isEmpty()){
                addChildToParent(lstDevices, null);
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
            if(dtoTree.treeId.equals(selectedDevice))
            {
                dtoTree.lstChild = dtoChildDevice;
            }
            dtoTree.isExpand = true;
            addChildToParent(dtoTree.lstChild, dtoTree);
            
        }
    }
    
    // collapse tree node
    private void collapsedAllNode(List<DTOTreeItem> lstDto)
    {
        for(DTOTreeItem  treeLv: lstDto)
        {
            treeLv.isExpand= false;
            collapsedAllNode(treeLv.lstChild);
        }
    }
    
    //for synchronize from page is tree select or not
    private void convertJsonToDTOTreeItem()
    {
        lstDevices = (List<DTOTreeItem>)JSON.deserialize(jsonObject, List<DTOTreeItem>.class); 
    }
    
    //for control is tree select or not on page
    private void convertDTOTreItemToJson()
    {
        jsonObject=   JSON.serialize(lstDevices);   
    }
    
    public void saveAvailableDevice()
    {
    	// Automatically adding Available Device to TargetingDeviceAssociation when loading tree
    	// In case : PriceBookEntry.Product2.Devices__c = TRUE && PriceBookEntry.Product2.Fixed_Device__c = TRUE 
    	if(!lstPro.isEmpty() && lstPro.get(0).Devices__c && lstPro.get(0).Fixed_device__c)
    	{
    		saveRecords();
    	}
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
        public DTOTreeItem(Integer pos,String treeId,String treeName,Boolean isFolder,String treeParrentId,Integer treeLv,Boolean isExpand,Boolean isHideCheckBox ){
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