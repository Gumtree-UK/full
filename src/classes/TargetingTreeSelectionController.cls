global  class TargetingTreeSelectionController {
	public DTOTreeItem  content{get;set;}
	public String jsonObject{get;set;}
	public String selectedContent{get;set;}
	global TargetingTreeSelectionController(){
		resetTree();
	}	
	 //for synchronize from page is tree select or not
    private void convertJsonToDTOTreeItem(){
    	content = (DTOTreeItem)JSON.deserialize(jsonObject,TargetingTreeSelectionController.DTOTreeItem.class);
    }
    //for control is tree select or not on page
    private void convertDTOTreItemToJson(){
    	jsonObject=   JSON.serialize(content);	
    }
    Set<String> setOldSelectedTargeting = new Set<String>();
    private void doSelectedTargeting(){
    	setOldSelectedTargeting = new Set<String>();
    	try{    		
		   targetId = ApexPages.currentPage().getParameters().get('targetId');			
			if( targetId == null || targetId==''){			 
				return;
			}
			
			for( TargetingContentAssociation__c tca: [ Select TargetingContent__c From TargetingContentAssociation__c Where Targeting__c = :targetId]){               
              setOldSelectedTargeting.add(tca.TargetingContent__c);
            }
    	}catch(Exception e){
	    		 ApexPages.Message lastNameMsg = new ApexPages.Message(ApexPages.Severity.Error, e.getMessage());
	             ApexPages.addMessage(lastNameMsg);
	    }    	
    }
    public void resetTree(){
    	 try{
    	 	doSelectedTargeting();
	   	 	initLstContent();	   	 	
	   	 }catch(Exception e){
	    		 ApexPages.Message lastNameMsg = new ApexPages.Message(ApexPages.Severity.Error, 'resetTree=='+e.getMessage() + '===' + e.getStackTraceString());
	             ApexPages.addMessage(lastNameMsg);
	    }   
    	
    }
   private    Set<String> setValidId = new Set<String>();  
   private set<String> setLv2 = new set<String>();
   private set<String> setLv3 = new set<String>();
   public String contentString{
   		get{
   			String s='';
   			for(String key: setValidId){
   				s = s+ key+',';
   			}
   			return s;
   		}
   		set;
   	
   }
   public String targetId{get;set;}
   public String tarText{get;set;}
   public Boolean isSaveError{get;set;}
   public Boolean isShowCancel{
		get{
			String froIfr = ApexPages.currentPage().getParameters().get('froIfr');
			return froIfr == null || froIfr=='' ? false : Boolean.valueOf( froIfr );
		}set;
	}
    private final String DART_ZONE_TYPE = 'Dart - Zone';
   public void saveRecords(){
   		try{
   			convertJsonToDTOTreeItem();   			
   			String lineItemId = ApexPages.currentPage().getParameters().get('itemId');			
			//targetId = ApexPages.currentPage().getParameters().get('targetId');	
			isSaveError = false;
			if( targetId == null || targetId==''){			 
				Targeting__c t = new Targeting__c(TempBinder__c = true, Description__c = 'TargetingTreeProduct');
	            insert t;
	            targetId = t.Id;
	            
			}	
			Set<String> setSelectedContent = new Set<String>();
			Set<String> sdartzone = new Set<String>();
		    tarText='';
			//get all selected content
			
		   	//-02-07-2014: 
		   	//- Save only parent if all child are selected
		   	//- Save only child if all child doesn't selected all
		    
			//Mapping parent and number of childs
			 Map<String, Integer> mapNumOfChilds = new Map<String, Integer>();
			 Map<String, Set<String>> mapSelectedChildCount = new Map<String, Set<String>>();
			 Map<String, Integer> mapChildOfTopParent = new Map<String, Integer>();
			 Integer totalNumChilds=0; // Number of child of top parent
			 
			 for(DTOTreeItem dto : content.lstChild){
			 	totalNumChilds++;
				if( dto.isSelected ){
					setSelectedContent.add(dto.treeId);
					mapNumOfChilds.put(dto.treeId, dto.lstChild.size());
					if( setValidDartZone.contains( dto.treeId ) ) sdartzone.add( dto.treeId );
					Set<String> setSelChilds  = new Set<String>();
					for(DTOTreeItem dtoChild : dto.lstChild){
						if( dtoChild.isSelected ){
							setSelChilds.add(dtoChild.treeId);
							setSelectedContent.add(dtoChild.treeId);
							if( setValidDartZone.contains( dtoChild.treeId ) ) sdartzone.add( dtoChild.treeId );
						}
					}
					mapSelectedChildCount.put(dto.treeId, setSelChilds);
				}
			 }
			 // Check if Number of top parent's child are all selected => save save top parent id
			 if(totalNumChilds == mapNumOfChilds.keySet().size()) setSelectedContent.add(content.treeId); // add top parent's id

			 for(String key : mapNumOfChilds.keySet())
			 {
			 	if(mapNumOfChilds.get(key) != mapSelectedChildCount.get(key).size()) setSelectedContent.remove(key);
			 	else
			 	{
			 		for(String s : mapSelectedChildCount.get(key))
			 		{
			 			setSelectedContent.remove(s);
			 		}
			 	} 
			 }
			  //for(Content__c c : [Select Id From Content__c Where Site_Content_Category__c In:  sdartzone ]){
		      //      setSelectedContent.add(c.Id);		           
        	  //}	
			  
			  // put text value to update to lineItem
        	  Map<String,Content__c> mContent = new Map<String,Content__c>( [Select Site_Content_Category__c ,DartName__c, Id, Type__c  From Content__c Where Id In : setSelectedContent] );
        	  for(String k : mContent.keySet())
        	  {
        	  		Content__c c = mContent.get(k);
        	  		if(c != null) tarText = tarText + c.DartName__c+','; 
        	  }			 
			
			  //All objects that are checked in the tree have to be related to the targeting record.
        	List<TargetingContentAssociation__c> lstored = new List<TargetingContentAssociation__c>();
		     //for deletion of tree nodes changed to unchecked status
        	Set<String> assoNotToDelete = new Set<String>();
        	
        	for(Content__c con: mContent.values() ){        		
        		 TargetingContentAssociation__c tca = new TargetingContentAssociation__c(Targeting__c = targetId ,TargetingContent__c = con.id  , Target_Content_Key__c = targetId + con.id);
                lstored.add(tca);
                assoNotToDelete.add(tca.Target_Content_Key__c);
        	}
        	
        	 if(!lstored.isEmpty()){
            	upsert lstored Target_Content_Key__c;
        	}
        	delete [Select Id From TargetingContentAssociation__c Where Targeting__c= :targetId And Target_Content_Key__c Not In :assoNotToDelete ];	        
        	if( lineItemId <> null && lineItemId != ''){
        		List<OpportunityLineItem> lstOppItem = [ Select Targeting__c,Rich_Line_Description__c From OpportunityLineItem Where Id =: lineItemId];
        		if( !lstOppItem.isEmpty() ){
        			tarText = tarText !='' ? tarText.substring(0, (tarText.length() -1)  ) : tarText;
        			 OpportunityLineItem oppLI = lstOppItem.get(0);
		            oppLI.Rich_Line_Description__c = tarText ;
		            oppLI.Targeting__c = targetId;
		            update oppLI;
        			
        		}		           
		    }
   		 }catch(Exception e){
	    		 ApexPages.Message lastNameMsg = new ApexPages.Message(ApexPages.Severity.Error, e.getMessage());
	             ApexPages.addMessage(lastNameMsg);
	             isSaveError = true;
	    }  	
   }
   public void addContent(){
	   	 try{
	   	 	if( selectedContent==null || selectedContent=='')return;
	   	 	convertJsonToDTOTreeItem();
	   	 	if( setLv2.contains( selectedContent ) ){
	   	 		for(DTOTreeItem dto : content.lstChild){
	   	 			if( dto.treeId == selectedContent ){
	   	 				dto.isExpand =  true;
	   	 				dto.isSelected = true;	
	   	 				content.isSelected = true; 
		   	 			for(DTOTreeItem childDto : dto.lstChild){
		   	 				childDto.isSelected = true;
		   	 			}
	   	 			}
	   	 			/*if( dto.treeId == selectedContent ){
	   	 				dto.isExpand =  true;
	   	 				dto.isSelected = true;	
	   	 				content.isSelected = true; 
	   	 			}*/
	   	 			  	 			
	   	 		}
	   	 	}else if( setLv3.contains( selectedContent )){
	   	 		for(DTOTreeItem dto : content.lstChild){
	   	 			for(DTOTreeItem childDto : dto.lstChild){
	   	 				if( childDto.treeId == selectedContent){
		   	 				dto.isExpand = true;
		   	 				childDto.isSelected = true;
		   	 				dto.isSelected = true;
		   	 				content.isSelected = true;
		   	 			
		   	 			}
	   	 			}
	   	 		}
	   	 	}else if( content.treeId == selectedContent ){
	   	 		content.isSelected = true;
	   	 	}
	   	 	convertDTOTreItemToJson();
	   	 }catch(Exception e){
	    		 ApexPages.Message lastNameMsg = new ApexPages.Message(ApexPages.Severity.Error, e.getMessage());
	             ApexPages.addMessage(lastNameMsg);
	    }   	
   }
    // JS Remoting action called when searching for a  country
    @RemoteAction
    global static List<Content__c > searchContent(String searchTerm,String contentString) { 
    	List<Content__c> lstTmp = new List<Content__c>();
    	try{   
    		Set<String> setContentId = new set<String>();
    		for(String key : contentString.split(',')){
    			setContentId.add(key);
    		}
    		searchTerm = searchTerm<> null ? searchTerm.trim() : '';     		
    		String queryName = '%' + searchTerm.trim() + '%'; 
    		String queryString = 'Select DartName__c, Id From Content__c where DartName__c Like :queryName and Id In : setContentId limit 20';	 	
    	   lstTmp =  Database.query( queryString );    		 	
    	}catch(Exception e){
    		 ApexPages.Message lastNameMsg = new ApexPages.Message(ApexPages.Severity.Error, e.getMessage());
             ApexPages.addMessage(lastNameMsg);
    	}
    	
    	return lstTmp;
    }
   	Set<String> setValidDartZone = new Set<String>();
	private void initLstContent(){		
		 String proId = Apexpages.currentPage().getParameters().get('proId');
		 if( proId == null || proId == ''){
		 	content = new DTOTreeItem( 0 , 'No content ', 'No content' , true,null, 1,false,true);
		 	ApexPages.Message lastNameMsg = new ApexPages.Message(ApexPages.Severity.Error, 'Invalid product id.' );
            ApexPages.addMessage(lastNameMsg);
		 	return;
		 }
		 List<Product2> lstPro= [Select Content__c From Product2  where id= : proId];
		 String conId = null;
		 if( !lstPro.isEmpty() && lstPro.get(0).Content__c == null ){
		 	content = new DTOTreeItem( 0 , 'No content ', 'No content' , true,null, 1,false,true);
		 	ApexPages.Message lastNameMsg = new ApexPages.Message(ApexPages.Severity.Error, 'No content found for this product.' );
            ApexPages.addMessage(lastNameMsg);
		 	return;
		 }else{
		 	conId = lstPro.get(0).Content__c;
		 }
		 
		 
		 Map<String, List<Content__c>> mapListConts = new Map<String, List<Content__c>>();
         for(Content__c c: [Select Id, Site_Content_Category__c From Content__c Where Id IN: setOldSelectedTargeting])
         {
        	if(!mapListConts.containskey(c.Site_Content_Category__c)) mapListConts.put(c.Site_Content_Category__c, new List<Content__c>());
            mapListConts.get(c.Site_Content_Category__c).add(c);
         }

         Set<String> parIds = new Set<String>();
         if(mapListConts.get(conId) != null){
	         for(Content__c c : mapListConts.get(conId))
	         {
	         	parIds.add(c.id);
	         }
         }
         
         // Get child to set the selected
         Set<String> allSelectedIds = new Set<String>();
         for(Content__c c : [Select Name,  DartName__c,Id ,(Select Id From Contents__r  ) From Content__c Where Id IN : parIds])
         {
         	for(Content__c cr : c.Contents__r)
         	{
         		allSelectedIds.add(cr.Id);
         	}
         }
         setOldSelectedTargeting.addAll(allSelectedIds);
         
		 setValidId = new Set<String>();
		 //HCS  change request by Sri
		 //Please can remove that validation we would like to show all the sites and zones of the type Content Category.
		 //12.08.2014
		 //List<Content__c> lstCon = [Select Name,  DartName__c,Id ,(Select Id From Contents__r  ) From Content__c where Type__c =: CONTENT_CATEGORY_TYPE and id =: conId order by DartName__c ];		 
		 List<Content__c> lstCon = [Select Name,  DartName__c,Id ,(Select Id From Contents__r  ) From Content__c where  id =: conId order by DartName__c ]; 
		 Set<String> setChildId = new Set<String>();
		 if( !lstCon.isEmpty() ){
		 	Content__c c = lstCon.get( 0 );
		 	content = new DTOTreeItem( 0 , c.id, c.DartName__c , true,null, 1,true,false);
		 	setValidId.add(c.id);		 	
		 	for(Content__c child : c.Contents__r){
		 		setChildId.add(child.id);
		 		setValidId.add(child.id);
		 	}
		 }
		 List<DTOTreeItem> lstTopChild = new List<DTOTreeItem>();
		 for(Content__c c : [Select Name,Type__c,  DartName__c,Id,(Select Id,DartName__c,Name,Type__c From Contents__r  )  From Content__c where id In :setChildId ] ){
		 	DTOTreeItem dtoItem = new DTOTreeItem(lstTopChild.size(), c.id, c.DartName__c , true,null, 2,false,false);
		 	setLv2.add(c.id);
		 	system.debug(' c.id==========='+  c.id);
		 	if( setOldSelectedTargeting.contains( c.id) ){
		 		dtoItem.isSelected = true;
		 		content.isSelected = true;
		 	}
		 	if( c.Type__c == DART_ZONE_TYPE )setValidDartZone.add( c.id );
		 	List<DTOTreeItem> lstChildItem = new List<DTOTreeItem>();
		 	for(Content__c child : c.Contents__r){
		 		system.debug(' child.id==========='+  child.id);
		 		if( child.Type__c == DART_ZONE_TYPE )setValidDartZone.add( child.id );
		 		DTOTreeItem dotChild = new DTOTreeItem( lstChildItem.size(), child.id, child.DartName__c , false ,c.id ,3,false,false);
		 		if( setOldSelectedTargeting.contains(child.id) ){
		 			dtoItem.isSelected = true;
		 			content.isSelected = true;
		 			dotChild.isSelected = true;
		 		}
		 		lstChildItem.add( dotChild );
		 		setValidId.add(child.id);
		 		setLv3.add(child.id);
		 	}
		 	dtoItem.lstChild = lstChildItem;
		 	lstTopChild.add( dtoItem );
		 }
		 if( !lstTopChild.isEmpty() ) content.lstChild = lstTopChild;
		 convertDTOTreItemToJson();
	}
	private final String CONTENT_CATEGORY_TYPE='Dart - ContentCategory';
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