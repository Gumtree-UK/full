public class modifyproductpageredir {

string recordId;

    public modifyproductpageredir(ApexPages.StandardController controller)
    {recordId = controller.getId();}
     
    public Pagereference pageredirect()
    {
     if  (Userinfo.getProfileId() == '00e200000019dPcAAI' || 
          Userinfo.getProfileId() == '00e2000000109rWAAQ' ||
          Userinfo.getProfileId() == '00e20000001cgI7AAI' ||
          Userinfo.getProfileId() == '00e200000012BomAAE'
     )
    {
        Pagereference p = new PageReference ('/apex/modifyproduct');
        p.getParameters().put('Id', recordId);
        p.setredirect(true);
        return p;
    }
     
else if
        (Userinfo.getProfileId() == '00e20000001csY7AAI' ||
         Userinfo.getProfileId() == '00e20000001csWzAAI'
        )
     {
        Pagereference p = new PageReference ('/apex/modifyproductdailydeals');
        p.getParameters().put('Id', recordId);
        p.setredirect(true);
        return p;
     }  
else
     {
        Pagereference p = new PageReference ('/apex/modifyproductclassifieds');
        p.getParameters().put('Id', recordId);
        p.setredirect(true);
        return p;
     }
}       
}