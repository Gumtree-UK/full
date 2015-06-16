global  class TreeCountryAndCitySelectingController {
	public List<DTOTreeItem> lstCountry{get;set;}
	public String selectedCountry{get;set;}
	public String selectedRegion{get;set;}
	public String selectCityLetter{get;set;}
	public Integer parPos{get;set;}
	public Integer childPos{get;set;}
	public Integer lastChildPos{get;set;}
	public String searchFilter{get;set;}
	global TreeCountryAndCitySelectingController(){		
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
	private Map<String ,Map<String,List<TargetingCityAssociation__c>>> mapOldSelectedCity = new Map<String ,Map<String,List<TargetingCityAssociation__c>>>();
	private Map<String,Integer> mapCountryChildCount = new Map<String,Integer>();
	//for get the value that selected 
	private void doSelectedCountryAndCity(){
		setOldSelectedCountry = new Set<String>();
		mapOldSelectedCity = new Map<String ,Map<String,List<TargetingCityAssociation__c>>>();
		mapCountryChildCount = new Map<String,Integer>();
		try{
			
			targetId = ApexPages.currentPage().getParameters().get('targetId');					
			if( targetId == null || targetId==''){			 
				return;
			}
			//for country
			 for( TargetingCountryAssociation__c targeting: [Select Country__c From TargetingCountryAssociation__c  where Targeting__c=:targetId]){
			 	setOldSelectedCountry.add( targeting.Country__c);
			 }
			 //for city
			 Set<String> setRegionId = new Set<String>();
			 for( TargetingCityAssociation__c c: [Select Id,City__c,City__r.State_Region__c,City__r.id,City__r.name ,City__r.Country__c From TargetingCityAssociation__c Where Targeting__c = :targetId order by City__r.Country__c,City__r.State_Region__c,City__r.name ASC ]){                
			 	String key = c.City__r.Country__c;
			 	String childKey = c.City__r.State_Region__c;
			 	if( !mapOldSelectedCity.containskey(key) ) mapOldSelectedCity.put(key, new Map<String,List<TargetingCityAssociation__c>>());
			 	if( !mapOldSelectedCity.get(key).containskey(childKey)  ) mapOldSelectedCity.get(key).put(childKey, new List<TargetingCityAssociation__c>());
			 	mapOldSelectedCity.get(key).get(childKey).add(c);
			 	setRegionId.add( childKey );			 	
			 }
			 //count city of country
			 if( !setRegionId.isEmpty()){
    			for(AggregateResult result:[Select State_Region__c,Country__c,COUNT(Id) total From City__c where Country__c In : mapOldSelectedCity.keySet() And   State_Region__c In : setRegionId GROUP BY Country__c,State_Region__c ORDER BY Country__c,State_Region__c ] ){
			 	 	String key = result.get('Country__c')+'--'+ result.get('State_Region__c');
			 	 	Integer val = Integer.valueOf( result.get('total') +'');			 	 	
			 	 	mapCountryChildCount.put(key, val);
			 	 }               
			 	
			 	
			 }
     		
		}catch(Exception e){
			 ApexPages.Message lastNameMsg = new ApexPages.Message(ApexPages.Severity.Error, e.getMessage());
             ApexPages.addMessage(lastNameMsg);
		}
	}
	//split List TargetingCityAssociation__c into Map by first letter of city.name
	private Map<String,List<TargetingCityAssociation__c>> getChildRecordByAlphabet( List<TargetingCityAssociation__c> lstTargets){
		Map<String,List<TargetingCityAssociation__c>> mapChildRecords = new Map<String,List<TargetingCityAssociation__c>>();
		for(TargetingCityAssociation__c c:  lstTargets ){
				String key = c.City__r.name;
				key = key.subString(0,1);	
				if( !mapChildRecords.containskey(key) ) mapChildRecords.put(key, new List<TargetingCityAssociation__c>() );
				mapChildRecords.get(key).add(c);
		}
		return mapChildRecords;
	}	
	
	public String targetId{get;set;}
	public Boolean isSaveError{get;set;}
	public String strValue{get;set;}
	public String countryValue{get;set;}
	//process when click on save action
	public void saveRecords(){
		try{
			convertJsonToDTOTreeItem();			 
			String lineItemId = ApexPages.currentPage().getParameters().get('itemId');			
			 isSaveError = false;
			//targetId = ApexPages.currentPage().getParameters().get('targetId');
			
			if( targetId == null || targetId==''){
				lineItemId = lineItemId == null ? '' : lineItemId;			 
				 Targeting__c t = new Targeting__c(Description__c = 'Tar_LineItemId ' + lineItemId);
	            insert t;
	            targetId = t.Id;
			}
			//All objects that are checked in the tree have to be related to the targeting record.
        	List<TargetingCountryAssociation__c> lstTgCountries = new List<TargetingCountryAssociation__c>();
        	 //All objects that are checked in the tree have to be related to the targeting record.
        	List<TargetingCityAssociation__c> lstTgCities = new List<TargetingCityAssociation__c>();
        	 //for deletion of tree nodes changed to unchecked status from opp lineitem
        	Set<String> assoNotToDelete = new Set<String>();
        	Set<String> assoNotToDeleteForCity = new Set<String>();
            strValue='';
            countryValue = '';
			 for(DTOTreeItem  dto: lstCountry){
			 	if( dto.isSelected ){
			 		String conId = dto.treeId;
			 		 TargetingCountryAssociation__c tca = new TargetingCountryAssociation__c(Targeting__c = targetId ,Country__c  = conId , TargetCountry__c  = targetId + conId);
                	lstTgCountries.add(tca);
                	 countryValue = countryValue + dto.treeName +',';
               		assoNotToDelete.add(tca.TargetCountry__c);  
               		//for cities
               		for(DTOTreeItem region: dto.lstChild){
               			for(DTOTreeItem dtoCity: region.lstChild){
               				//case child lv 3
               				if( !dtoCity.isHideCheckBox && dtoCity.isSelected){
               					 TargetingCityAssociation__c ca = new TargetingCityAssociation__c(Targeting__c = targetId ,City__c  = dtoCity.treeId , targetcity__c  = targetId + dtoCity.treeId);
                				 lstTgCities.add(ca);
               					 assoNotToDeleteForCity.add(ca.targetcity__c);
               					 strValue = strValue + dtoCity.treeName +',';
               				}else{//case child lv4
               					for(DTOTreeItem lastCity: dtoCity.lstChild){
               						if(  lastCity.isSelected){
               							 TargetingCityAssociation__c ca = new TargetingCityAssociation__c(Targeting__c = targetId ,City__c  = lastCity.treeId , targetcity__c  = targetId + lastCity.treeId);
                				 		 lstTgCities.add(ca);
                				 		 assoNotToDeleteForCity.add(ca.targetcity__c);
                				 		  strValue = strValue + lastCity.treeName +',';
               						}
               					}
               				}
               			}
               		}      
			 	}
			 }
			 if(!lstTgCountries.isEmpty()){           
           		 upsert lstTgCountries TargetCountry__c;            
        	 }
        	  if(!lstTgCities.isEmpty()){           
            	upsert lstTgCities targetcity__c;            
       		 }
        	delete [Select Id From TargetingCountryAssociation__c Where Targeting__c= :targetId And TargetCountry__c Not In :assoNotToDelete ];
        	delete [Select Id From TargetingCityAssociation__c Where Targeting__c= :targetId And targetcity__c Not In :assoNotToDeleteForCity ];        	
			jsonObject=   JSON.serialize(lstCountry);	
			
			if( lineItemId <> null && lineItemId != ''){
        		List<OpportunityLineItem> lstOppItem = [ Select City_Description__c From OpportunityLineItem Where Id =: lineItemId];
        		if( !lstOppItem.isEmpty() ){
        			strValue = strValue !='' ? strValue.substring(0, (strValue.length() -1)  ) : strValue;
        			 OpportunityLineItem oppLI = lstOppItem.get(0);
		             oppLI.City_Description__c = strValue ;
		            update oppLI;
        			
        		}		           
		    }
		}catch(Exception e){
			 ApexPages.Message lastNameMsg = new ApexPages.Message(ApexPages.Severity.Error, e.getMessage());
             ApexPages.addMessage(lastNameMsg);
             isSaveError = true;
		}		
	}
	
	
	//get all country, existing city into the tree
	private void initCountry(){
		lstCountry = new List<DTOTreeItem>();
		for(Country__c con : [ Select Name, Id From Country__c order by name ] ){
			//pos,treeId,treeName,ParrentId,treeLv,isExpand,isHideCheckBox
			DTOTreeItem dto =new DTOTreeItem( lstCountry.size(), con.id, con.Name, true , null,1,false, false);
			String key = con.id;
			//for country
			if( setOldSelectedCountry.contains( key ) ){
				dto.isSelected = true;
				dto.isExpand = true;
			}
			//for city
			if( mapOldSelectedCity.containskey( key ) ){
				dto.isSelected = true;
				dto.isExpand = true;
				//add region
				for(String region : mapOldSelectedCity.get(key).keySet()){
					  DTOTreeItem dtoChild =  new DTOTreeItem( dto.lstChild.size(), region , region, true , key ,2,false,true);	
					  dtoChild.isExpand = true;	
					  String keyChildCount = key+'--'+region;	
					  if( !mapCountryChildCount.containskey( keyChildCount ) )continue;		
					  Integer childCount =  mapCountryChildCount.get( keyChildCount ); 
					  List<TargetingCityAssociation__c> lstTargets = mapOldSelectedCity.get(key).get(region);
					  //case child <= 100 add child direct
					  if( childCount <= CITY_LIMIT_ROW){
					  	for(TargetingCityAssociation__c c:  lstTargets ){
						  	DTOTreeItem dtoChildCity =  new DTOTreeItem( dtoChild.lstChild.size(), c.City__r.id , c.City__r.name ,false, region ,3,false ,false);
						  	dtoChildCity.isSelected = true;
						  	dtoChild.lstChild.add( dtoChildCity );
					  	}					  	
					  }else{//case child >100 need add to alphabet letter
					  	Map<String,List<TargetingCityAssociation__c>> mapExistingItems = getChildRecordByAlphabet(lstTargets);
					  	List<String> lstOrder = new List<String> ();
						lstOrder.addAll(  mapExistingItems.keySet());
						lstOrder.sort();
					  	for(String itemKey : lstOrder ){
					 		DTOTreeItem dtoChildCity =  new DTOTreeItem( dtoChild.lstChild.size(), itemKey , itemKey ,true, region ,3,false ,true);
					 		dtoChildCity.isExpand = true;
					 		for(TargetingCityAssociation__c c : mapExistingItems.get(itemKey ) ){
					 			DTOTreeItem dtoLastCity =  new DTOTreeItem( dtoChildCity.lstChild.size(), c.City__r.id , c.City__r.name ,false, itemKey ,4,false ,false);
					 			dtoLastCity.isSelected = true;
					 			dtoChildCity.lstChild.add(dtoLastCity);
					 		}
					  		dtoChild.lstChild.add( dtoChildCity );
					  	}					  	
					  }	   
					dto.lstChild.add(dtoChild);
				}
			}
			lstCountry.add( dto);
		}
		jsonObject=   JSON.serialize(lstCountry);	
					
	}
	// JS Remoting action called when searching for a  country
    @RemoteAction
    global static List<DTOSearchItem > searchCountry(String searchTerm) { 
    	List<DTOSearchItem> lstTmp = new List<DTOSearchItem>();
    	try{
    		
    		searchTerm = searchTerm<> null ? searchTerm.trim() : ''; 
       		String searchquery='find \'*' + searchTerm + '*\'IN ALL FIELDS RETURNING Country__c(id,name),City__c(id,name) limit 20'; 
			List<List<SObject>>searchList=search.query(searchquery);
			for(SObject country : searchList.get(0) ){
				lstTmp.add( new DTOSearchItem(country.get('Name')+'' , country.get('Id')+'', 'country') );
			}
			for(SObject city : searchList.get(1) ){
				lstTmp.add( new DTOSearchItem(city.get('Name')+'' , city.get('Id')+'', 'city') );
			}    		
    	    		 	
    	}catch(Exception e){
    		 ApexPages.Message lastNameMsg = new ApexPages.Message(ApexPages.Severity.Error, e.getMessage());
             ApexPages.addMessage(lastNameMsg);
    	}
    	
    	return lstTmp;
    }
    
     global  class DTOSearchItem{
     	public String name{get;set;}
     	public String id{get;set;}
     	public String itemType{get;set;}
     	public DTOSearchItem(String name, String id,String itemType){
     		this.name = name;
     		this.id = id;
     		this.itemType = itemType;
     	}
     	
     }
    
    private Boolean isExistingKey(List<DTOTreeItem> lstDTOTreeItem,String key){
    	if( lstDTOTreeItem.isEmpty() )return false;
    	for(DTOTreeItem dto: lstDTOTreeItem){
    		if(dto.treeId == key )return true;
    	}    	
    	return false;
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
    		if( selectedCountry== null || selectedCountry=='')return;		
    		convertJsonToDTOTreeItem();
    		collapsedAllNode();    		
    		if( searchFilter== 'country' ){
    			for(DTOTreeItem dto: lstCountry){
	    			if( dto.treeId == selectedCountry){
	    				dto.isExpand = true;
	    				dto.isSelected = true;
	    			}    			
    			}
    		}else{
    			//case searchFilter = city
    			List<City__c> lstCitys =[Select State_Region__c,Country__c,id,name From City__c where id=: selectedCountry ];
    			if( !lstCitys.isEmpty() ){
    				City__c c =  lstCitys.get(0);
    				List<AggregateResult> lstResult =[Select State_Region__c,Country__c,COUNT(Id) total From City__c where Country__c = : c.Country__c And   State_Region__c = : c.State_Region__c GROUP BY Country__c,State_Region__c ORDER BY Country__c,State_Region__c ];
    				if( !lstResult.isEmpty() ){
    					for(DTOTreeItem dto: lstCountry){
			    			if( dto.treeId == c.Country__c){
			    				dto.isExpand = true;
			    				dto.isSelected = true;
			    				Boolean  isAlreadyExist = isExistingKey(dto.lstChild ,c.State_Region__c );
			    				DTOTreeItem dtoChild;
			    				//check if not existing key
			    				dtoChild =   !isAlreadyExist ? new DTOTreeItem( dto.lstChild.size(), c.State_Region__c , c.State_Region__c, true , c.Country__c ,2,false,true) 
			    											 : getExistingTreeItem(dto.lstChild ,c.State_Region__c );
			    				dtoChild.isExpand = true;
			    				if( !isAlreadyExist){
				    				dto.lstChild.add( dtoChild );	
			    				}			    				
			    				Integer childCount =  Integer.valueOf(lstResult.get( 0 ).get('total') +'');		    				
			    				if( childCount <= CITY_LIMIT_ROW){	
			    					Boolean isChildExisting = isExistingKey( dtoChild.lstChild , c.id );		    					
			    				 	DTOTreeItem dtoChildCity =  !isChildExisting ? new DTOTreeItem( dtoChild.lstChild.size(), c.id , c.name ,false, c.State_Region__c ,3,false ,false)
																				 : getExistingTreeItem(dtoChild.lstChild ,c.id );
								  	dtoChildCity.isSelected = true;
								  	if( !isChildExisting) dtoChild.lstChild.add( dtoChildCity );
			    				}else{	
			    					String key = c.name;
									key = key.subString(0,1);
			    					Boolean isChildExisting = isExistingKey( dtoChild.lstChild ,  key);		    					
									DTOTreeItem dtoChildCity =  !isChildExisting ? new DTOTreeItem( dtoChild.lstChild.size(), key , key ,true, c.State_Region__c ,3,false ,true)
																				 : getExistingTreeItem(dtoChild.lstChild ,key );
					 				dtoChildCity.isExpand = true;	
					 				//start last child
					 				Boolean isLastChildExisting = isExistingKey( dtoChildCity.lstChild,c.id);
					 				DTOTreeItem dtoLastCity = !isChildExisting? new DTOTreeItem( dtoChildCity.lstChild.size(), c.id , c.name ,false, key ,4,false ,false)
					 														:  getExistingTreeItem(dtoChildCity.lstChild ,c.id );
						 			dtoLastCity.isSelected = true;
						 			if( !isLastChildExisting ) dtoChildCity.lstChild.add(dtoLastCity);
					 				//end last child
			    					if( !isChildExisting ) dtoChild.lstChild.add( dtoChildCity );
			    				} 
			    			}    			
    					}
    					
    				}				
    				
    			}    			
    		}
    		
    		jsonObject=   JSON.serialize(lstCountry);	
    		
    	}catch(Exception e){
    		 ApexPages.Message lastNameMsg = new ApexPages.Message(ApexPages.Severity.Error, e.getMessage());
             ApexPages.addMessage(lastNameMsg);
    	}
    	
    }
    //reset country
   public void resetCountry(){
    	try{
    		//getExisting country and city
			doSelectedCountryAndCity();
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
  	//process when click on the country 
    public void getStageRegion(){
    	try{    		
    		convertJsonToDTOTreeItem();
    		collapsedAllNode();
    		List<DTOTreeItem> lstChildCity = new List<DTOTreeItem>();
    		//get all existing region
    		Map<String,DTOTreeItem> mapExistRegion = getMapExistDTOItem( lstCountry.get( parPos ).lstChild );
    		for(AggregateResult result:[Select State_Region__c From City__c where Country__c =: selectedCountry GROUP BY State_Region__c ORDER BY State_Region__c ] ){
    			String key = result.get('State_Region__c')+'';
    			DTOTreeItem dto = mapExistRegion.containskey(key ) ? mapExistRegion.get( key ) : new DTOTreeItem( lstChildCity.size(),  key ,  key , true , selectedCountry ,2,false,true) ;
    			dto.pos = lstChildCity.size();
    			lstChildCity.add( dto );
    		}
    		if( !lstChildCity.isEmpty() ){
    			lstCountry.get( parPos ).isExpand= true;
    			lstCountry.get( parPos ).lstChild = lstChildCity;	
    		}  
    		convertDTOTreItemToJson();	
    	}catch(Exception e){
    		 ApexPages.Message lastNameMsg = new ApexPages.Message(ApexPages.Severity.Error, e.getMessage());
             ApexPages.addMessage(lastNameMsg);
    	}
    	
    }
    //for collape All node of tree
    private void collapsedAllNode(){
    	for(DTOTreeItem  treeLv1: lstCountry ){
    		treeLv1.isExpand= false;
    		for(DTOTreeItem treelv2: treeLv1.lstChild ){
    			treelv2.isExpand= false;
    			for(DTOTreeItem treelv3: treeLv2.lstChild){
    				treelv3.isExpand = false;
    			}
    		}
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
	private static final  Integer CITY_LIMIT_ROW =100;	
	private List<String> lstOrderTreeByAlphabet = new List<String>{'A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z'};
	//process when click on the region 
	public void getCity(){
		try{
			convertJsonToDTOTreeItem();
			collapsedAllNode();
			Map<String,DTOTreeItem> mapExistCity = getMapExistDTOItem( lstCountry.get( parPos ).lstChild.get( childPos ).lstChild );
    		List<City__c> lstCity = [ select id, name from City__c where State_Region__c= : selectedRegion and Country__c =: selectedCountry order by Name limit :CITY_LIMIT_ROW  ]; 
    		List<DTOTreeItem> lstChildCity = new List<DTOTreeItem>();
    		if( lstCity.size() >= CITY_LIMIT_ROW){
    			for(String k: lstOrderTreeByAlphabet ){
    				DTOTreeItem dto = mapExistCity.containskey( k ) ? mapExistCity.get( k ) : new DTOTreeItem( lstChildCity.size(), k , k ,true, selectedRegion ,3,false , true);
    				lstChildCity.add( dto );
    			}
    		}else{    			
    			for(City__c c: lstCity){
    				  DTOTreeItem dto = mapExistCity.containskey( c.id ) ? mapExistCity.get( c.id) : new DTOTreeItem( lstChildCity.size(), c.id , c.name ,false, selectedRegion ,3,false ,false);
    				  lstChildCity.add( dto );
    			}    			
    		}
    		
    		if( !lstChildCity.isEmpty() ){
    				lstCountry.get( parPos ).isExpand= true;
    				lstCountry.get( parPos ).lstChild.get( childPos ).isExpand = true;
    				lstCountry.get( parPos ).lstChild.get( childPos ).lstChild = lstChildCity;	    				
    		}
    		convertDTOTreItemToJson();	
    	}catch(Exception e){
    		 ApexPages.Message lastNameMsg = new ApexPages.Message(ApexPages.Severity.Error, e.getMessage());
             ApexPages.addMessage(lastNameMsg);
    	}
	}
	
	//process when click on the alphabet letter 
	public void getCityByLetter(){
		try{
			convertJsonToDTOTreeItem();
			collapsedAllNode();
			Map<String,DTOTreeItem> mapExistCity = new Map<String,DTOTreeItem>();
			for(DTOTreeItem dto: lstCountry.get( parPos ).lstChild.get( childPos ).lstChild){
    					if(dto.treeName == selectCityLetter){
    						mapExistCity = getMapExistDTOItem( dto.lstChild );
    						break;
    					}
    		}    		
			String queryName = selectCityLetter +'%';
			List<DTOTreeItem> lstChildCity = new List<DTOTreeItem>();
			for(City__c c:[ select id, name from City__c where State_Region__c= : selectedRegion and Country__c =: selectedCountry and name like : queryName order by name]){
				DTOTreeItem dto = mapExistCity.containskey( c.id ) ? mapExistCity.get( c.id) : new DTOTreeItem( lstChildCity.size(), c.id , c.name ,false, selectCityLetter ,4,false ,false);
				lstChildCity.add( dto );
			}
			
			if( !lstChildCity.isEmpty() ){
    				lstCountry.get( parPos ).isExpand= true;
    				lstCountry.get( parPos ).lstChild.get( childPos ).isExpand = true;    				
    				for(DTOTreeItem dto: lstCountry.get( parPos ).lstChild.get( childPos ).lstChild){
    					if(dto.treeName == selectCityLetter){
    						dto.lstChild = lstChildCity;
    						dto.isExpand = true;	
    					}
    				}    				
    		}
    		convertDTOTreItemToJson();	
		}catch(Exception e){
    		 ApexPages.Message lastNameMsg = new ApexPages.Message(ApexPages.Severity.Error, e.getMessage());
             ApexPages.addMessage(lastNameMsg);
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