/**
 * Controller for page P2P_Template.page.
 * Change the inner page for template.
 * @author Kakada KHAN
 * @date 06-Jan-2015
 */
 
public class P2P_TemplateController {
    public String reqPage{get;set;}
    public Account act{get;set;}
    
    /**
     * Constructor:
     * Get account id from URL and select an account. 
     * Each page will be use follow 
     * class name below and id = comp
     * on tag body.
            'manage'
            'replies'
            'details'
            'company'
            'metrics'
            'financials'
            'store'
            'support'
     */
    public P2P_TemplateController(){
        String acid = P2P_Utils.retrieveCommunityAccountId();
        act = [SELECT Id, Name, RecordType.Name FROM Account WHERE Id =: acid];
    }
    
    /**
     * Change the page content 
     * follow the reqPageuest from user click the nav.
     * @return PageReference
     */
    public PageReference changeContent(){
        return null; 
    }
    
    private final String PARAM_AUTH = 'GT_15=00';
    
    public PageReference doAuthorize(){
        List<String> paramAUTH = PARAM_AUTH.split('=');
        String paramAuthVal = Apexpages.currentPage().getParameters().get(paramAUTH[0]);
        String authUrl = P2P_Utils.generateAuthGTBusAccURL(ApexPages.currentPage().getUrl(), Site.getBaseUrl(), PARAM_AUTH);
        if(String.isEmpty(authUrl) || paramAUTH[1] == paramAuthVal) return null;
        PageReference pg = new PageReference(authUrl);
        pg.setRedirect(true);
        return pg;
    }
    
    public String getSitePrefix(){
        return P2P_Utils.getSitePrefix();
    }
    
   
}