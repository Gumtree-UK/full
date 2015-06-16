public with sharing class GumtreeCreditPackage {
	
	public Long id{
		get { return id; }
		set { id = value; }
	}
		
	public Long package_type_id{
		get { return package_type_id; }
		set { package_type_id = value; }
	}
	
	public Long account_id{
		get { return account_id; }
		set { account_id = value; }
	}
	
	public String salesforce_id{
		get { return salesforce_id; }
		set { salesforce_id = value; }
	}
	
	public String start_date{
		get { return start_date; }
		set { start_date = value; }
	}
	
	public String end_date{
		get { return end_date; }
		set { end_date = value; }
	}
	
	public Long initial_credits{
		get { return initial_credits; }
		set { initial_credits = value; }
	}
	
	public Long adjusted_credits{
		get { return adjusted_credits; }
		set { adjusted_credits = value; }
	}
	
	public Long used_credits{
		get { return used_credits; }
		set { used_credits = value; }
	}
	
	public String name{
		get { return name; }
		set { name = value; }
	}
	
	public Boolean unlimited{
		get { return unlimited; }
		set { unlimited = value; }
	}
	
	public GumtreeCreditPackage(Long id, Long ptId, Long aId, String sfId, String sDate, 
	String eDate, Long iCredits, Long aCredits, Long uCredits, String name, Boolean unlimited ){
		
		this.id = id;
		this.package_type_id = ptId;
		this.account_id = aId;
		this.salesforce_id = sfId;
		this.start_date = sDate;
		this.end_date = eDate;
		this.initial_credits = iCredits;
		this.adjusted_credits = aCredits;
		this.used_credits = uCredits;
		this.name = name;
		this.unlimited = unlimited;
	}
	
	static testmethod void test() {
		GumtreeCreditPackage pack = new GumtreeCreditPackage(1, 2, 3, '4', '5', '6', 7, 8, 9, '10', true);
		System.assertEquals(pack.id, 1);
		System.assertEquals(pack.package_type_id, 2);
		System.assertEquals(pack.account_id, 3);
		System.assertEquals(pack.salesforce_id, '4');
		System.assertEquals(pack.start_date, '5');
		System.assertEquals(pack.end_date, '6');
		System.assertEquals(pack.initial_credits, 7);
		System.assertEquals(pack.adjusted_credits, 8);
		System.assertEquals(pack.used_credits, 9);
		System.assertEquals(pack.name, '10');
		System.assertEquals(pack.unlimited, true);
	}

}