/**
NK:07/04/2014
GTCRM-766) get the Geo- Iocation based on ip for webform
*/
public without sharing class LiveAgentGEO{

    //@future(callout=true)
    public static void fetchVisitorGEO(Case vCase, String visitorIp)
    {
        try{
            //http://freegeoip.net/json/iphere
            HTTPWrapper.SimpleRequest req = new HTTPWrapper.SimpleRequest('http://freegeoip.net/json/'+visitorIp,'GET','');
            SimpleGEOResponse res = new SimpleGEOResponse(req);
            
            System.debug('>>>>>>>res.getResBody():'+res.getResBody());
            
            GEOInfo geoJson = new GEOInfo();//So test coverage can go through 'New'
            geoJson = (GEOInfo)JSON.deserialize(res.getResBody(), GEOInfo.class); 
            
            //LiveChatTranscript lctUpdate = new LiveChatTranscript(Id=liveChatTranscriptId,Visitor_GEO_Lat__c=geoJson.latitude,Visitor_GEO_Lon__c=geoJson.longitude);
            //update lctUpdate;
            vCase.UMgeolocalization__Latitude__s =  Decimal.valueOf(geoJson.latitude);
            vCase.UMgeolocalization__Longitude__s = Decimal.valueOf(geoJson.longitude);
            //vCase.IP_Address__c = geoJson.ip; // form already save it?!!!
            vCase.Country_Name__c = geoJson.country_name;
            vCase.City__c = geoJson.city;
            vCase.Region__c = geoJson.region_name;
            vCase.Postcode__c = geoJson.zipcode;
            vCase.Area_Code__c = geoJson.area_code; 
            
        }catch(Exception ex)
        {
            System.debug('>>>>>>>fetchVisitorGEO Eror:'+ex);
        }
        //System.debug('>>>>>>>geoJson:'+geoJson);
        
    }

    
    class GEOInfo{
         public String ip;
         public String country_code;
         public String country_name;
         public String region_code;
         public String region_name;
         public String city;
         public String zipcode;
         public String latitude;
         public String longitude;
         public String metro_code;
         public String area_code;
     
         public GEOInfo(){}
            
        }
        
        
    class SimpleGEOResponse extends HTTPWrapper.AbstractResponse{
        
        public SimpleGEOResponse(IRequest req)
        {
            super(req); 
            excecute();
        }
        public override String getMockedBody()
        {
            return '{"ip":"127.0.0.1","country_code":"LH","country_name":"LocalHost","region_code":"11","region_name":"LocalHost","city":"LocalHost","zipcode":"","latitude":11.11,"longitude":22.22,"metro_code":"","area_code":""}';
        }
        
    } 
}