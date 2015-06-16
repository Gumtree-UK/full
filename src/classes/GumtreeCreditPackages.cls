public with sharing class GumtreeCreditPackages {

	public List<GumtreeCreditPackage> packages {
		get { return packages; }
		set { packages = value; }
	}
	
	public GumtreeCreditPackages(List<GumtreeCreditPackage> packs) {
		this.packages = packs;
	}

	static testmethod void test() {
		List<GumtreeCreditPackage> packs = new List<GumtreeCreditPackage>();
		GumtreeCreditPackages gcp = new GumtreeCreditPackages(packs);
		packs = gcp.packages;
	}
}