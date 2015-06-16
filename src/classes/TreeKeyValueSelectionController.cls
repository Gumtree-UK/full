global with sharing class TreeKeyValueSelectionController {	
	public Integer childPos{get;set;}
	public DTOTreeItem dtoKeyValue{get;set;}
	public String selectedKeyValue{get;set;}
	public String parrentKeyNode{get;set;}
	public String keyValueSelected{get;set;}
	global TreeKeyValueSelectionController(){
		resetTree();
	}
	
	private void doSelectKeyValue(){
		try{			
			targetId = ApexPages.currentPage().getParameters().get('targetId');				
			if( targetId == null || targetId==''){			 
				return;
			} 
			if(targetId != ''){
				String val='(';	
				
	           Set<String> setParrents = new Set<String>();
	           Map<String,List<TargetingKeyValueAssociation__c>> mapTarValue = new Map<String,List<TargetingKeyValueAssociation__c>>();
	           for(TargetingKeyValueAssociation__c tar:[ Select DART_KeyValue__r.Key_Value__c,DART_KeyValue__r.Node_ID__c, DART_KeyValue__r.Node_ID__r.Key_Value__c,Operator__c  From TargetingKeyValueAssociation__c Where Targeting__c = :targetId  ] ){
	           		String key = tar.DART_KeyValue__r.Node_ID__c;
	           		if( !mapTarValue.containskey( key)) mapTarValue.put(key, new List<TargetingKeyValueAssociation__c>());
	           		mapTarValue.get(key).add( tar);
	           }
	           Boolean isFirst = true;
	           for(String key : mapTarValue.keySet() ){
	           		List<TargetingKeyValueAssociation__c> lstTar = mapTarValue.get( key);
	           		if( !isFirst ) {
	           			val = val +') AND (';
	           		}
	           		for(Integer i=0; i< lstTar.size();i++){
	           			TargetingKeyValueAssociation__c tar = lstTar.get(i);
	           			val = val+ '(' + tar.DART_KeyValue__r.Node_ID__r.Key_Value__c +'='+tar.DART_KeyValue__r.Key_Value__c +')';
		            	if( i < lstTar.size()-1 ){
		            		val =  val + ' OR ';
		            	}
	           		}
	           		isFirst = false;
	           }
	           
	           if( !mapTarValue.isEmpty()) keyValueSelected = val +')';		                       
         	}
		}catch(Exception e){
			 ApexPages.Message lastNameMsg = new ApexPages.Message(ApexPages.Severity.Error, e.getMessage());
             ApexPages.addMessage(lastNameMsg);
		}		
	}
	 private void collapsedAllNode(){
	   		for(DTOTreeItem dtoNode: dtoKeyValue.lstChild ){
	   			dtoNode.isExpand = false;
	   		}
	  }
	   
	 public String keyValueString{
   		get{
   			String s='';
   			for(String key: setValidKeyValue){
   				s = s+ key+',';
   			}
   			return s;
   		}
   		set;
   	
   }
   
   private DTOTreeItem getItemOnTheFly(String itemId,Integer pos ){
   		DTOTreeItem dto= null;
   		List<DART_KeyValue_2__c> lstItem = [Select Key_Value__c,Id,Key_Value_Name__c,Node_ID__c From DART_KeyValue_2__c where id= : itemId];
   		if( !lstItem.isEmptY() ){
   			DART_KeyValue_2__c val = lstItem.get(0);
   			String label = val.Key_Value_Name__c+'('+val.Key_Value__c+')';
   			 dto = new DTOTreeItem(pos, val.id, label,val.Key_Value__c, false , itemId, 3,false,false);
   			 dto.isSelected = true;
   		}
   		return dto;
   }
   public void addKeyValue(){
   		try{   			
   			collapsedAllNode();   			
   			String selectedParrent = setValidKeyValue.contains( selectedKeyValue ) ? selectedKeyValue : parrentKeyNode;
   			if(selectedParrent== null || selectedParrent=='')return;
   			for(DTOTreeItem dtoNode: dtoKeyValue.lstChild ){
	   			if( dtoNode.treeId == selectedParrent){
	   					dtoNode.isExpand = true;	   					
	   					//check if selected child
	   					if( !setValidKeyValue.contains( selectedKeyValue ) ){
	   						Boolean isFound = false;
	   						for(DTOTreeItem dtoChild : dtoNode.lstChild){
	   							if( dtoChild.treeId == selectedKeyValue){
	   								dtoChild.isSelected = true;
	   								isFound = true;
	   							}
	   						}
	   						if( !isFound){
	   							Boolean isRemoveShowMore = false;
	   							if( !dtoNode.lstChild.isEmpty() && dtoNode.lstChild.get( dtoNode.lstChild.size()-1 ).treeId == SHOW_MORE ){
									 dtoNode.lstChild.remove( dtoNode.lstChild.size()-1 );
									 isRemoveShowMore = true;
								}
							   	DTOTreeItem dtoItemOnTheFly = getItemOnTheFly( selectedKeyValue , dtoNode.lstChild.size()  );
	   							if( dtoItemOnTheFly<> null ) dtoNode.lstChild.add( dtoItemOnTheFly );
	   							if( isRemoveShowMore ){
	   								dtoNode.lstChild.add( getShowMoreRecord( dtoNode.treeId , dtoNode.lstChild.size() ) ); 
	   							}
	   						}
	   						
	   					}
	   			}
	   		}  			
   			
   		}catch(Exception e){
    		 ApexPages.Message lastNameMsg = new ApexPages.Message(ApexPages.Severity.Error, e.getMessage());
             ApexPages.addMessage(lastNameMsg);
    	}
   }
   
	 @RemoteAction
    global static List<DART_KeyValue_2__c > searchKeyValue(String searchTerm,String validKeyValueId ) { 
    	List<DART_KeyValue_2__c> lstTmp = new List<DART_KeyValue_2__c>();
    	try{
    		Set<String> setKeyValudId = new set<String>();
    		for(String key : validKeyValueId.split(',')){
    			setKeyValudId.add(key);
    		}
    		searchTerm = searchTerm<> null ? searchTerm.trim() : '';   
    		String queryName = '%' + searchTerm.trim() + '%'; 
    		String queryString = 'Select Key_Value__c,Id,Key_Value_Name__c,Node_ID__c From DART_KeyValue_2__c where Key_Value_Name__c Like :queryName and  Node_ID__c In : setKeyValudId  limit 20';	 	
    	    lstTmp =  Database.query( queryString ); 
    		
    	}catch(Exception e){
    		 ApexPages.Message lastNameMsg = new ApexPages.Message(ApexPages.Severity.Error, e.getMessage());
             ApexPages.addMessage(lastNameMsg);
    	}
    	
    	return lstTmp;
    }
	
	public void resetTree(){
		try{
			doSelectKeyValue();
			initKeyValue();
		 }catch(Exception e){
    		 ApexPages.Message lastNameMsg = new ApexPages.Message(ApexPages.Severity.Error, e.getMessage());
             ApexPages.addMessage(lastNameMsg);
    	}
		
	}
	private final Integer CHILD_ROW_LIMIT = 20;
	private final String SHOW_MORE ='Show more';
	public Boolean isShowCancel{
		get{
			String froIfr = ApexPages.currentPage().getParameters().get('froIfr');
			return froIfr == null || froIfr=='' ? false : Boolean.valueOf( froIfr );
		}set;
	}
	private List<DTOTreeItem> getLstChild(String nodeId , set<String> setExistingNode){
		List<DTOTreeItem> lstChild = new List<DTOTreeItem>();
		String queryString = 'Select Key_Value__c,Id,Key_Value_Name__c From DART_KeyValue_2__c where Node_ID__c = :nodeId ';
		if( !setExistingNode.isEmpty() ) queryString = queryString +' and Id Not In : setExistingNode ';
		 queryString = queryString +' order by Name limit: CHILD_ROW_LIMIT ';	
		for(DART_KeyValue_2__c val :  Database.query( queryString )  ){
				String label = val.Key_Value_Name__c+'('+val.Key_Value__c+')';
		 		lstChild.add( new DTOTreeItem( lstChild.size() ,val.id ,label,val.Key_Value__c  , false , nodeId , 3, false , false) );
		}
		
		if( lstChild.size() == CHILD_ROW_LIMIT ){
			lstChild.add( getShowMoreRecord( nodeId , lstChild.size() ) ); 
		}
		return lstChild;
		
	}
	
	private Set<String> getExistingSetNode(List<DTOTreeItem> lstItem){
		Set<String> setExistingNode = new Set<String>();
		for(DTOTreeItem  dto: lstItem){
			if( dto.treeId == SHOW_MORE )continue ;
			setExistingNode.add( dto.treeId);
		}		
		return setExistingNode;
	}
	
	public String targetId{get;set;}
	public Boolean isSaveError{get;set;}
	public void saveRecords(){		
		try{		
			String lineItemId = ApexPages.currentPage().getParameters().get('itemId');			
			//targetId = ApexPages.currentPage().getParameters().get('targetId');
			isSaveError = false;
			if( targetId == null || targetId==''){
				 lineItemId = lineItemId==null ? '': lineItemId ; 			 
				 Targeting__c t = new Targeting__c(Description__c = 'Tar_LineItemId ' + lineItemId);
	            insert t;
	            targetId = t.Id;
			}
			
			 //----------- Select Dart keyValue by Keyword --------------
        
       		 String EXP_GETKEYVALUE = '(\\(.*?=(.*?)\\))';
      		String EXP_GETKEY = '(\\((.*?)\\=.*?)\\)';
        
       		 List<String> lstKeyVals = new List<String>();
        
    		Matcher matcherKeyValue = Pattern.compile(EXP_GETKEYVALUE).matcher( keyValueSelected );          
		    while (matcherKeyValue.find()){
		      lstKeyVals.add(matcherKeyValue.group(2));
		    }
		  
			Set<String> kv = new Set<String>();            
		    for(String s: lstKeyVals){		     
		      kv.add(s);
		    }
		    Map<String, String> mDartKey = new Map<String, String>();
		    Map<String,String> mapKeyNodeDartId = new Map<String,String>();
		    Map<String, List<KeyValueDTO>> mapNodeDart = new Map<String, List<KeyValueDTO>>();
		    List<KeyValueDTO> lstDTO = new List<KeyValueDTO>();     		
		    for(DART_KeyValue_2__c d :  [Select d.Node_ID__c, d.Key_Value__c, d.Key_Value_Name__c, d.Node_ID__r.Key_Value__c From DART_KeyValue_2__c d Where Key_Value__c IN : kv]){
		      if(!mapNodeDart.containsKey(d.Node_ID__c)){
		        mapNodeDart.put(d.Node_ID__c, new List<KeyValueDTO>());
		      }		     
		      mapNodeDart.get(d.Node_ID__c).add(new KeyValueDTO(d.Id, d.Key_Value__c));
		      mapKeyNodeDartId.put(d.Node_ID__r.Key_Value__c+''+d.Key_Value__c, d.Node_ID__c+'');
		    } 
		    
		     List<String> lstKeys = new List<String>();          
        	Matcher matcherKeys= Pattern.compile(EXP_GETKEY).matcher(keyValueSelected.replace('((', '('));          
		    while (matcherKeys.find()){
		      lstKeys.add(matcherKeys.group(2));
		    }
			
			
			 Integer i=0;  
		    for(String strTmp : lstKeys){
		      String newK = strTmp+lstKeyVals.get(i);
		      String nodeId =mapKeyNodeDartId.get(newK);// newK= parentKey+keyvalue of child
		        if(mapNodeDart.containsKey(nodeId)){		        	
		          for(KeyValueDTO d : mapNodeDart.get(nodeId)){
		             if(d.DARTKeyValue.contains(lstKeyVals.get(i))){		             	
		             	 mDartKey.put(d.dartKeyId, d.dartKeyId);		             	
		             }
		          }
		        }
		      
		      i++;
		    } 
		    
		     //All objects that are checked in the tree have to be related to the targeting record.
        	List<TargetingKeyValueAssociation__c> lstored = new List<TargetingKeyValueAssociation__c>();
            
	        //for deletion of tree nodes changed to unchecked status from opp lineitem
	        Set<String> assoNotToDelete = new Set<String>();        
	        for(String chk: mDartKey.keySet()){
		        //ex_key = opli.Targeting__c + s;  //Targeting + DART KeyValue
		        TargetingKeyValueAssociation__c tca = new TargetingKeyValueAssociation__c(Targeting__c = targetId ,DART_KeyValue__c  =chk , Operator__c= 'OR', targetkeyvalue__c = targetId + chk);
		        lstored.add(tca);
		        assoNotToDelete.add(tca.targetkeyvalue__c);
		    }
		    
		     if(!lstored.isEmpty()){           
            	upsert lstored targetkeyvalue__c;            
        	}
		    delete [Select Id From TargetingKeyValueAssociation__c Where Targeting__c= :targetId And targetkeyvalue__c Not In :assoNotToDelete ];
		 }catch(Exception e){
    		 ApexPages.Message lastNameMsg = new ApexPages.Message(ApexPages.Severity.Error, e.getMessage());
             ApexPages.addMessage(lastNameMsg);
             isSaveError = true;
    	}		
		
	}
	
	 public class KeyValueDTO{
      String dartKeyId;// {get; set;}
      String dartKeyValue;// {get; set;}
      public KeyValueDTO(String dartKeyId, String dartKeyValue){
        this.dartKeyId = dartKeyId;
        this.dartKeyValue = dartKeyValue;
      }
    }
	private DTOTreeItem getShowMoreRecord( String nodeId, Integer pos){
		return new DTOTreeItem( pos ,SHOW_MORE ,SHOW_MORE, SHOW_MORE  , true , nodeId , 2, false , true);
	}
	private List<DTOTreeItem> getItemMoreRecords(List<DTOTreeItem> lstOld, List<DTOTreeItem> lstNew ,Boolean isGetMore){
		//remove show more
		if( !lstOld.isEmpty() && lstOld.get( lstOld.size()-1 ).treeId == SHOW_MORE ){
			 lstOld.remove( lstOld.size()-1 );
		}
		Set<String> setIdExist = new Set<String>();
		List<DTOTreeItem> lstTmp = new List<DTOTreeItem>();
		if( !isGetMore){
			for(DTOTreeItem dto : lstOld){
				if( dto.isSelected ){
					setIdExist.add(dto.treeId);
					lstTmp.add( dto );			
				}
			}
		}else{
			lstTmp = lstOld;
		}		
		for(DTOTreeItem dto : lstNew){
			if( setIdExist.contains(dto.treeId) ) continue;
			dto.pos = lstTmp.size();
			lstTmp.add( dto );
		}
		
		return lstTmp;
	}
	
	private void doGetChildProcess(Boolean isGetMore){
		try{
			collapsedAllNode();
			String nodeId = dtoKeyValue.lstChild.get( childPos ).treeId;
			dtoKeyValue.lstChild.get( childPos ).isExpand = true;
			Set<String> setExistingRecords =   isGetMore ? getExistingSetNode( dtoKeyValue.lstChild.get( childPos ).lstChild ) : new set<String>();			
			dtoKeyValue.lstChild.get( childPos ).lstChild =    getItemMoreRecords( dtoKeyValue.lstChild.get( childPos ).lstChild , getLstChild( nodeId , setExistingRecords  ),isGetMore ) ;
		 }catch(Exception e){
    		 ApexPages.Message lastNameMsg = new ApexPages.Message(ApexPages.Severity.Error, e.getMessage());
             ApexPages.addMessage(lastNameMsg);
    	}		
		
	}	
	
	public void getMoreChildKeyValue(){
		doGetChildProcess(true);
	}
	public void getChildKeyValue(){
		doGetChildProcess(false );
	}
	private set<String> setValidKeyValue = new Set<String>();
	private void initKeyValue(){
		 String proId = Apexpages.currentPage().getParameters().get('proId');
		 try{
		 	setValidKeyValue = new Set<String>();
		 	if( proId== null ){
		 		 ApexPages.Message lastNameMsg = new ApexPages.Message(ApexPages.Severity.Error, 'Invalid product id.');
             	ApexPages.addMessage(lastNameMsg);
             	return;
		 	}
		 	List<Product2> lstProduct =[Select site__c,Available_Key_Values__c From Product2 where Available_Key_Values__c<> null and Id =: proId];		 	
		 	if( lstProduct.isEmpty() ){
		 		ApexPages.Message lastNameMsg = new ApexPages.Message(ApexPages.Severity.Error, 'No Key Values available for this product.');
             	ApexPages.addMessage(lastNameMsg);
             	return;
		 	}
		 	dtoKeyValue = new DTOTreeItem(1,'AllKeyValue','All KeyValue','All KeyValue' , true , null, 0, true , true);
		 	List<DTOTreeItem> lstChild = new List<DTOTreeItem>();
		 	List<String> lstAvailableKey = lstProduct.get(0).Available_Key_Values__c.split(';');
		 	for(DART_KeyValue_2__c val : [Select Key_Value__c,Id,Key_Value_Name__c From DART_KeyValue_2__c where Node_ID__c=null and  Name In : lstAvailableKey And Key__c<> null  order by Name] ){
		 		String label = val.Key_Value_Name__c+'('+val.Key_Value__c+')';
		 		lstChild.add( new DTOTreeItem( lstChild.size() ,val.id ,label,val.Key_Value__c  , true , 'All KeyValue', 2, false , true) );
		 		setValidKeyValue.add(val.id);
		 	}		 	
		 	dtoKeyValue.lstChild = lstChild;
		 }catch(Exception e){
    		 ApexPages.Message lastNameMsg = new ApexPages.Message(ApexPages.Severity.Error, e.getMessage());
             ApexPages.addMessage(lastNameMsg);
    	}
    	
	}
	public class DTOTreeItem {
		public Integer pos{get;set;}
		public String treeId{get;set;}
		public String treeName{get;set;}
		public String treeValue{get;set;}
		public String treeParrentId{get;set;}
		public List<DTOTreeItem> lstChild{get;set;}
		public Integer treeLv{get;set;}
		public Boolean isExpand{get;set;}
		public Boolean isHideCheckBox{get;set;}
		public Boolean isFolder{get;set;}
		public Boolean isSelected{get;set;}
		public DTOTreeItem(Integer pos,String treeId,String treeName,String treeValue,Boolean isFolder,String treeParrentId,Integer treeLv,Boolean isExpand,Boolean isHideCheckBox ){
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
			this.treeValue = treeValue;
		}		
	}

}