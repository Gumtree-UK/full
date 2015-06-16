global class TreeConnectionSelectionController {
	
	public List<DTOTreeItem> lstConnections{get;set;}
    public String selectedConnection{get; set;}
    
    public String targetId{get;set;}
    public Boolean isSaveError{get;set;}
    public String connectionDes{get;set;}
    public Boolean isExistSelected{get; set;}
    //store jsonobject on page
    public String jsonObject{get;set;}
    
    private Set<String> setOldSelectedConns = new Set<String>();
    private Map<String, List<Connection__c>> mapExtParentChilds = new Map<String, List<Connection__c>>();
    private Set<String> setParentIds = new Set<String>();
	
	global TreeConnectionSelectionController()
	{
		resetConnection();
	}
	
	public Boolean isShowCancel{
        get{
            String froIfr = ApexPages.currentPage().getParameters().get('froIfr');
            return froIfr == null || froIfr=='' ? false : Boolean.valueOf( froIfr );
        }set;
    }
    
    // get existing selected connection
    private void doSelectedConns()
    {
    	setOldSelectedConns = new Set<String>();
        try{
            
            targetId = ApexPages.currentPage().getParameters().get('targetId');                 
            if( targetId == null || targetId==''){           
                return;
            }
            
            //Level 1
             for( TargetingConnectionAssociation__c targeting: [Select Connection__c, Connection__r.Id, Connection__r.Node_ID__c , Connection__r.Name   From TargetingConnectionAssociation__c  Where Targeting__c=:targetId And Connection__r.Node_ID__c = null])
             {
                setOldSelectedConns.add(targeting.Connection__c);
             }
             
             Set<String> setExistConnIds = new Set<String>();
             for( TargetingConnectionAssociation__c targeting: [Select Connection__c, Connection__r.Id, Connection__r.Node_ID__c , Connection__r.Name   From TargetingConnectionAssociation__c  Where Targeting__c=:targetId])
             {
                setExistConnIds.add(targeting.Connection__c);
             }
             
             for(Connection__c conn :[Select Name, Id, Node_ID__c, (Select id, Name, Node_ID__c From Connections__r limit 1) From Connection__c where id IN: setExistConnIds])
             {
                if(!mapExtParentChilds.containskey(conn.Node_ID__c)) mapExtParentChilds.put(conn.Node_ID__c, new List<Connection__c>());
                mapExtParentChilds.get(conn.Node_ID__c).add(conn);
             }
             
             
        }catch(Exception e){
             ApexPages.Message lastNameMsg = new ApexPages.Message(ApexPages.Severity.Error, e.getMessage());
             ApexPages.addMessage(lastNameMsg);
        }
    	
    	
    }
    
    //Get all connection && existing selected connection into the tree
    private void initConnection()
    {
    	lstConnections = new List<DTOTreeItem>();
    	if(!mapExtParentChilds.values().isEmpty()) isExistSelected = true;
        for(Connection__c conn : [Select Id, Name From Connection__c Where Node_ID__c=null order by Name]){
        	setParentIds.add(conn.id);
            String key = conn.id;

            DTOTreeItem dto =new DTOTreeItem(lstConnections.size(), conn.id, conn.Name, true , null,1,false, false);
            //for Connection Top Level
            if(setOldSelectedConns.contains(key))
            {
                dto.isSelected = true;
                dto.isExpand = true;
            }
            // Add Exist child to tree
            doSetExistValueToTree(dto, key);
            
            lstConnections.add(dto);
        }
        jsonObject=   JSON.serialize(lstConnections);   
    }
    
    // Adding Existing TargetingAssociation to tree when page loaded
    private void doSetExistValueToTree(DTOTreeItem dto, String key)
    {
        if(mapExtParentChilds.containsKey(key))
        {
            for(Connection__c conn : mapExtParentChilds.get(key))
            {
                DTOTreeItem dtoChild =  new DTOTreeItem(dto.lstChild.size(), conn.Id , conn.Name, !conn.Connections__r.isEmpty() , key ,null,false,false); 
                dtoChild.isExpand = true;   
                dtoChild.isSelected = true;
                dto.lstChild.add(dtoChild);
                
                doSetExistValueToTree(dtoChild ,conn.id);
            }
        }   
    }
    
    //All objects that are checked in the tree have to be related to the targeting record.
    List<TargetingConnectionAssociation__c> lstTargConns;
    //All ids of association to be deleted
    Set<String> assoNotToDelete;
    
    //process when click on save action
    public void saveRecords()
    {
    	
    	try{
            lstTargConns = new List<TargetingConnectionAssociation__c>();
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
            
            connectionDes='';
            
            for(DTOTreeItem  dto: lstConnections){
                if(dto.isSelected){
                     String conId = dto.treeId;
                     TargetingConnectionAssociation__c tca = new TargetingConnectionAssociation__c(Targeting__c = targetId ,Connection__c  = conId , TargetConnection__c  = targetId + conId);
                     lstTargConns.add(tca);
                     connectionDes = connectionDes + dto.treeName +',';
                     assoNotToDelete.add(tca.TargetConnection__c);
                     //call to create child devices  
                     createdTarAssFromSelectedValue(dto.lstChild);   
                }
            }

            if(!lstTargConns.isEmpty()){        
                 upsert lstTargConns TargetConnection__c ;            
            }

            delete [Select Id From TargetingConnectionAssociation__c Where Targeting__c= :targetId And TargetConnection__c Not In :assoNotToDelete ];
                        
            jsonObject=   JSON.serialize(lstConnections);   
            
            if( lineItemId <> null && lineItemId != ''){
                List<OpportunityLineItem> lstOppItem = [ Select Device_Targeting__c From OpportunityLineItem Where Id =: lineItemId];
                if(!lstOppItem.isEmpty() ){
                     connectionDes = connectionDes !='' ? connectionDes.substring(0, (connectionDes.length() -1)) : connectionDes;
                     
                     OpportunityLineItem oppLI = lstOppItem.get(0);
                     oppLI.Connection_Targeting__c  = connectionDes ;
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
    private void createdTarAssFromSelectedValue(List<DTOTreeItem> lstConns)
    {
    	
    	for(DTOTreeItem conn: lstConns)
        {
            if(conn.isSelected)
            {
                TargetingConnectionAssociation__c targ = new TargetingConnectionAssociation__c(Targeting__c = targetId ,Connection__c  = conn.treeId , TargetConnection__c  = targetId + conn.treeId);
                lstTargConns.add(targ);
                assoNotToDelete.add(targ.TargetConnection__c);
                connectionDes = connectionDes + conn.treeName +',';
            }
            createdTarAssFromSelectedValue(conn.lstChild);
        }
    	
    }
    
    // JS Remoting action called when searching for a connection
    @RemoteAction
    global static List<Connection__c> searchConnection(String searchTerm) { 
        List<Connection__c> lstTmp = new List<Connection__c>();
        try{
            searchTerm = searchTerm<> null ? searchTerm.trim() : '';     		
    		String queryName = '%' + searchTerm.trim() + '%'; 
    		String queryString = 'Select Id, Name, DFP_API_Name__c From Connection__c where Name Like :queryName limit 20';	 	
    	    lstTmp =  Database.query( queryString ); 
               
        }catch(Exception e){
             ApexPages.Message lastNameMsg = new ApexPages.Message(ApexPages.Severity.Error, e.getMessage());
             ApexPages.addMessage(lastNameMsg);
        }
        
        return lstTmp;
    }
    
    private Map<String, Connection__c> mapLevelConns = new Map<String, Connection__c>();
    private void getLevelMapping(String nodeId)
    {
        List<Connection__c> lstCon = [Select Id, Name, Node_ID__c, (Select Id From Connections__r limit 1) From Connection__c where id =: nodeId];
        if(!lstCon.isEmpty() && lstCon.get(0).Node_Id__c != null)
        {
            String nId = lstCon.get(0).Node_Id__c+'';
            mapLevelConns.put(nId, lstCon.get(0));
            getLevelMapping(nId);
        }
    }
    
    
    // Adding Device to tree when seached device found
    public void addConnection()
    {
    	
    	try{    
            if(selectedConnection== null || selectedConnection=='')return;       
            convertJsonToDTOTreeItem();
            collapsedAllNode(lstConnections);         
            if(setParentIds.contains(selectedConnection)){
                Integer posCon = null;
                for(DTOTreeItem dto: lstConnections){
                    if( dto.treeId == selectedConnection){
                        posCon = dto.pos;
                    }               
                }
                if(posCon != null)
                {
                    lstConnections.get(posCon).isExpand = true;
                    lstConnections.get(posCon).isSelected = true;
                }
                
            }else{
                //case searchFilter for child level
                List<Connection__c> lstSelectedCon =[Select id,Name, Node_ID__c, (Select Id From Connections__r limit 1)  From Connection__c where id=: selectedConnection ];
                if(!lstSelectedCon.isEmpty())
                {
                    Connection__c d =  lstSelectedCon.get(0);
                    getLevelMapping(d.Node_ID__c);
                    // Add itself to map
                    mapLevelConns.put(d.Node_ID__c, d);
                    for(DTOTreeItem dto: lstConnections )
                    {
                        if(mapLevelConns.containsKey(dto.treeId))
                        {
                            dto.isExpand = true;
                            dto.isSelected = true;
                            addSearchConnToTree(dto, dto.treeId, d); 
                        }     
                    }
                }               
            }
            jsonObject=   JSON.serialize(lstConnections);
            saveRecords();
            mapLevelConns = new Map<String, Connection__c>();
        }catch(Exception e){
             ApexPages.Message lastNameMsg = new ApexPages.Message(ApexPages.Severity.Error,  e.getMessage()); //e.getStackTraceString()
             ApexPages.addMessage(lastNameMsg);
        }	
    }
    
    private void addSearchConnToTree(DTOTreeItem dto, String key, Connection__c d)
    {
   		Connection__c conChild = mapLevelConns.get(key); 
        if(conChild != null)
        {
    		Boolean isAlreadyExistChild = isExistingKey(dto.lstChild, conChild.Id);

            DTOTreeItem dtoChild =  !isAlreadyExistChild ? new DTOTreeItem(dto.lstChild.size(), conChild.Id , conChild.Name, !conChild.Connections__r.isEmpty() , conChild.Node_ID__c ,2, !conChild.Connections__r.isEmpty() ,false) 
                                    : getExistingTreeItem(dto.lstChild ,conChild.Id);
            dtoChild.isExpand = true;
            dtoChild.isSelected = true;
            if(!isAlreadyExistChild)
            {
            	dto.lstChild.add(dtoChild); 
            }
            addSearchConnToTree(dtoChild, conChild.id, d);
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
    
    //reset connection
    public void resetConnection()
    {
    	try{
            //getExisting Connection
            doSelectedConns();
            //generate tree 
            initConnection();
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
    
    List<DTOTreeItem> dtoChildConn;
    //Process when clicking on each connection(folder)
    public void getConnections()
    {
    	try
        {
            convertJsonToDTOTreeItem();
            collapsedAllNode(lstConnections);
            getMapExistDto(lstConnections);
            dtoChildConn = new List<DTOTreeItem>();
            for(Connection__c d: [select id, name, (Select id  From Connections__r limit 1) from Connection__c where Node_ID__c= : selectedConnection order by Name]){
                String key = d.id;
                DTOTreeItem dto = mapExistItem.containskey(key) ? mapExistItem.get(key) : new DTOTreeItem(dtoChildConn.size(), d.id , d.name ,!d.Connections__r.isEmpty(), selectedConnection ,null,false ,false);
                dtoChildConn.add(dto);
                
            } 

            if(!dtoChildConn.isEmpty()){
                addChildToParent(lstConnections);
            }

            convertDTOTreItemToJson();
        }catch(Exception e)
        {
             ApexPages.Message lastNameMsg = new ApexPages.Message(ApexPages.Severity.Error, e.getMessage());
             ApexPages.addMessage(lastNameMsg);
        }
    }
    
    // Call to add list of childs to parent node tree
    private void addChildToParent(List<DTOTreeItem> lstDto)
    {
    	
        for(DTOTreeItem  dtoTree: lstDto)
        {
            if(dtoTree.treeId.equals(selectedConnection))
            {
                dtoTree.lstChild = dtoChildConn;
            }
            dtoTree.isExpand = true;
            addChildToParent(dtoTree.lstChild);
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
        lstConnections = (List<DTOTreeItem>)JSON.deserialize(jsonObject, List<DTOTreeItem>.class); 
    }
    
    //for control is tree select or not on page
    private void convertDTOTreItemToJson()
    {
        jsonObject=   JSON.serialize(lstConnections);   
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