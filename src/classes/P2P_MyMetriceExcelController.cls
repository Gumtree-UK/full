/**
 * @Description: to generate excel file from MyMetrice page Ads Breakdown tab
 * @CreatedDate: 08/01/2015
 */
public class P2P_MyMetriceExcelController {
    
    public P2P_MyMetricsController metricCon{get;set;}
    public P2P_MyMetriceExcelController() {
        
        String accId = Apexpages.currentPage().getParameters().get('accId');
        String filterData = Apexpages.currentPage().getParameters().get('filter');
        Map<String, Object>mFilter = (Map<String, Object>)JSON.deserializeUntyped(filterData);
        
        Apexpages.Standardcontroller stdCon = new Apexpages.Standardcontroller([select Id, Name from Account where Id=:accId]);
        metricCon = new P2P_MyMetricsController(stdCon);
        
        //reset filter 
        metricCon.location = (String)mFilter.get('Location');
        metricCon.pmFromDatestr = (String)mFilter.get('FromDate');
        metricCon.pmEndDatestr = (String)mFilter.get('EndDate');
        metricCon.displayType = (String)mFilter.get('Display');
        metricCon.currentSoredField = (String)mFilter.get('SortField');
        metricCon.isSortByASC = (String)mFilter.get('isSortByASC') == 'true';
        metricCon.sortFieldName = metricCon.currentSoredField;
        
        metricCon.getPerfMetrice2Display();
        
    }
}