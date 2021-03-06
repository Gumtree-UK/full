//Generated by wsdl2apex

public class DART6_COMPANYSERVICE {

    public DART6_COMPANYSERVICE(){String s;}
	
    public class CommonError {
        public String reason;
        private String[] reason_type_info = new String[]{'reason','https://www.google.com/apis/ads/publisher/v201411',null,'0','1','false'};
        private String[] apex_schema_type_info = new String[]{'https://www.google.com/apis/ads/publisher/v201411','true','false'};
        private String[] field_order_type_info = new String[]{'reason'};
    }
    public class InternalApiError {
        public String reason;
        private String[] reason_type_info = new String[]{'reason','https://www.google.com/apis/ads/publisher/v201411',null,'0','1','false'};
        private String[] apex_schema_type_info = new String[]{'https://www.google.com/apis/ads/publisher/v201411','true','false'};
        private String[] field_order_type_info = new String[]{'reason'};
    }
    public class SetValue {
        public DART6_COMPANYSERVICE.Value[] values;
        private String[] values_type_info = new String[]{'values','https://www.google.com/apis/ads/publisher/v201411',null,'0','-1','false'};
        private String[] apex_schema_type_info = new String[]{'https://www.google.com/apis/ads/publisher/v201411','true','false'};
        private String[] field_order_type_info = new String[]{'values'};
    }
    public class StringLengthError {
        public String reason;
        private String[] reason_type_info = new String[]{'reason','https://www.google.com/apis/ads/publisher/v201411',null,'0','1','false'};
        private String[] apex_schema_type_info = new String[]{'https://www.google.com/apis/ads/publisher/v201411','true','false'};
        private String[] field_order_type_info = new String[]{'reason'};
    }
    public class DateTime_x {
        public DART6_COMPANYSERVICE.Date_x date_x;
        public Integer hour;
        public Integer minute;
        public Integer second;
        public String timeZoneID;
        private String[] date_x_type_info = new String[]{'date','https://www.google.com/apis/ads/publisher/v201411',null,'0','1','false'};
        private String[] hour_type_info = new String[]{'hour','https://www.google.com/apis/ads/publisher/v201411',null,'0','1','false'};
        private String[] minute_type_info = new String[]{'minute','https://www.google.com/apis/ads/publisher/v201411',null,'0','1','false'};
        private String[] second_type_info = new String[]{'second','https://www.google.com/apis/ads/publisher/v201411',null,'0','1','false'};
        private String[] timeZoneID_type_info = new String[]{'timeZoneID','https://www.google.com/apis/ads/publisher/v201411',null,'0','1','false'};
        private String[] apex_schema_type_info = new String[]{'https://www.google.com/apis/ads/publisher/v201411','true','false'};
        private String[] field_order_type_info = new String[]{'date_x','hour','minute','second','timeZoneID'};
    }
    public class Date_x {
        public Integer year;
        public Integer month;
        public Integer day;
        private String[] year_type_info = new String[]{'year','https://www.google.com/apis/ads/publisher/v201411',null,'0','1','false'};
        private String[] month_type_info = new String[]{'month','https://www.google.com/apis/ads/publisher/v201411',null,'0','1','false'};
        private String[] day_type_info = new String[]{'day','https://www.google.com/apis/ads/publisher/v201411',null,'0','1','false'};
        private String[] apex_schema_type_info = new String[]{'https://www.google.com/apis/ads/publisher/v201411','true','false'};
        private String[] field_order_type_info = new String[]{'year','month','day'};
    }
    public class BooleanValue {
        public Boolean value;
        private String[] value_type_info = new String[]{'value','https://www.google.com/apis/ads/publisher/v201411',null,'0','1','false'};
        private String[] apex_schema_type_info = new String[]{'https://www.google.com/apis/ads/publisher/v201411','true','false'};
        private String[] field_order_type_info = new String[]{'value'};
    }
    public class AppliedLabel {
        public Long labelId;
        public Boolean isNegated;
        private String[] labelId_type_info = new String[]{'labelId','https://www.google.com/apis/ads/publisher/v201411',null,'0','1','false'};
        private String[] isNegated_type_info = new String[]{'isNegated','https://www.google.com/apis/ads/publisher/v201411',null,'0','1','false'};
        private String[] apex_schema_type_info = new String[]{'https://www.google.com/apis/ads/publisher/v201411','true','false'};
        private String[] field_order_type_info = new String[]{'labelId','isNegated'};
    }
    public class UniqueError {
        private String[] apex_schema_type_info = new String[]{'https://www.google.com/apis/ads/publisher/v201411','true','false'};
        private String[] field_order_type_info = new String[]{};
    }
    public class CompanyError {
        public String reason;
        private String[] reason_type_info = new String[]{'reason','https://www.google.com/apis/ads/publisher/v201411',null,'0','1','false'};
        private String[] apex_schema_type_info = new String[]{'https://www.google.com/apis/ads/publisher/v201411','true','false'};
        private String[] field_order_type_info = new String[]{'reason'};
    }
    public class RequiredError {
        public String reason;
        private String[] reason_type_info = new String[]{'reason','https://www.google.com/apis/ads/publisher/v201411',null,'0','1','false'};
        private String[] apex_schema_type_info = new String[]{'https://www.google.com/apis/ads/publisher/v201411','true','false'};
        private String[] field_order_type_info = new String[]{'reason'};
    }
    public class FeatureError {
        public String reason;
        private String[] reason_type_info = new String[]{'reason','https://www.google.com/apis/ads/publisher/v201411',null,'0','1','false'};
        private String[] apex_schema_type_info = new String[]{'https://www.google.com/apis/ads/publisher/v201411','true','false'};
        private String[] field_order_type_info = new String[]{'reason'};
    }
    public class AuthenticationError {
        public String reason;
        private String[] reason_type_info = new String[]{'reason','https://www.google.com/apis/ads/publisher/v201411',null,'0','1','false'};
        private String[] apex_schema_type_info = new String[]{'https://www.google.com/apis/ads/publisher/v201411','true','false'};
        private String[] field_order_type_info = new String[]{'reason'};
    }
    public class PermissionError {
        public String reason;
        private String[] reason_type_info = new String[]{'reason','https://www.google.com/apis/ads/publisher/v201411',null,'0','1','false'};
        private String[] apex_schema_type_info = new String[]{'https://www.google.com/apis/ads/publisher/v201411','true','false'};
        private String[] field_order_type_info = new String[]{'reason'};
    }
    public class PublisherQueryLanguageSyntaxError {
        public String reason;
        private String[] reason_type_info = new String[]{'reason','https://www.google.com/apis/ads/publisher/v201411',null,'0','1','false'};
        private String[] apex_schema_type_info = new String[]{'https://www.google.com/apis/ads/publisher/v201411','true','false'};
        private String[] field_order_type_info = new String[]{'reason'};
    }
    public class String_ValueMapEntry {
        public String key;
        public DART6_COMPANYSERVICE.Value value;
        private String[] key_type_info = new String[]{'key','https://www.google.com/apis/ads/publisher/v201411',null,'0','1','false'};
        private String[] value_type_info = new String[]{'value','https://www.google.com/apis/ads/publisher/v201411',null,'0','1','false'};
        private String[] apex_schema_type_info = new String[]{'https://www.google.com/apis/ads/publisher/v201411','true','false'};
        private String[] field_order_type_info = new String[]{'key','value'};
    }
    public class Value {
        public String Value_Type;
        private String[] Value_Type_type_info = new String[]{'Value.Type','https://www.google.com/apis/ads/publisher/v201411',null,'0','1','false'};
        private String[] apex_schema_type_info = new String[]{'https://www.google.com/apis/ads/publisher/v201411','true','false'};
        private String[] field_order_type_info = new String[]{'Value_Type'};
    }
    public class getCompaniesByStatementResponse_element {
        public DART6_COMPANYSERVICE.CompanyPage rval;
        private String[] rval_type_info = new String[]{'rval','https://www.google.com/apis/ads/publisher/v201411',null,'0','1','false'};
        private String[] apex_schema_type_info = new String[]{'https://www.google.com/apis/ads/publisher/v201411','true','false'};
        private String[] field_order_type_info = new String[]{'rval'};
    }
    public class CompanyPage {
        public Integer totalResultSetSize;
        public Integer startIndex;
        public DART6_COMPANYSERVICE.Company[] results;
        private String[] totalResultSetSize_type_info = new String[]{'totalResultSetSize','https://www.google.com/apis/ads/publisher/v201411',null,'0','1','false'};
        private String[] startIndex_type_info = new String[]{'startIndex','https://www.google.com/apis/ads/publisher/v201411',null,'0','1','false'};
        private String[] results_type_info = new String[]{'results','https://www.google.com/apis/ads/publisher/v201411',null,'0','-1','false'};
        private String[] apex_schema_type_info = new String[]{'https://www.google.com/apis/ads/publisher/v201411','true','false'};
        private String[] field_order_type_info = new String[]{'totalResultSetSize','startIndex','results'};
    }
    public class updateCompaniesResponse_element {
        public DART6_COMPANYSERVICE.Company[] rval;
        private String[] rval_type_info = new String[]{'rval','https://www.google.com/apis/ads/publisher/v201411',null,'0','-1','false'};
        private String[] apex_schema_type_info = new String[]{'https://www.google.com/apis/ads/publisher/v201411','true','false'};
        private String[] field_order_type_info = new String[]{'rval'};
    }
    public class AvailableBillingError {
        public String reason;
        private String[] reason_type_info = new String[]{'reason','https://www.google.com/apis/ads/publisher/v201411',null,'0','1','false'};
        private String[] apex_schema_type_info = new String[]{'https://www.google.com/apis/ads/publisher/v201411','true','false'};
        private String[] field_order_type_info = new String[]{'reason'};
    }
    public class TypeError {
        private String[] apex_schema_type_info = new String[]{'https://www.google.com/apis/ads/publisher/v201411','true','false'};
        private String[] field_order_type_info = new String[]{};
    }
    public class NumberValue {
        public String value;
        private String[] value_type_info = new String[]{'value','https://www.google.com/apis/ads/publisher/v201411',null,'0','1','false'};
        private String[] apex_schema_type_info = new String[]{'https://www.google.com/apis/ads/publisher/v201411','true','false'};
        private String[] field_order_type_info = new String[]{'value'};
    }
    public class SoapResponseHeader {
        public String requestId;
        public Long responseTime;
        private String[] requestId_type_info = new String[]{'requestId','https://www.google.com/apis/ads/publisher/v201411',null,'0','1','false'};
        private String[] responseTime_type_info = new String[]{'responseTime','https://www.google.com/apis/ads/publisher/v201411',null,'0','1','false'};
        private String[] apex_schema_type_info = new String[]{'https://www.google.com/apis/ads/publisher/v201411','true','false'};
        private String[] field_order_type_info = new String[]{'requestId','responseTime'};
    }
    public class NotNullError {
        public String reason;
        private String[] reason_type_info = new String[]{'reason','https://www.google.com/apis/ads/publisher/v201411',null,'0','1','false'};
        private String[] apex_schema_type_info = new String[]{'https://www.google.com/apis/ads/publisher/v201411','true','false'};
        private String[] field_order_type_info = new String[]{'reason'};
    }
    public class updateCompanies_element {
        public DART6_COMPANYSERVICE.Company[] companies;
        private String[] companies_type_info = new String[]{'companies','https://www.google.com/apis/ads/publisher/v201411',null,'0','-1','false'};
        private String[] apex_schema_type_info = new String[]{'https://www.google.com/apis/ads/publisher/v201411','true','false'};
        private String[] field_order_type_info = new String[]{'companies'};
    }
    public class DateTimeValue {
        public DART6_COMPANYSERVICE.DateTime_x value;
        private String[] value_type_info = new String[]{'value','https://www.google.com/apis/ads/publisher/v201411',null,'0','1','false'};
        private String[] apex_schema_type_info = new String[]{'https://www.google.com/apis/ads/publisher/v201411','true','false'};
        private String[] field_order_type_info = new String[]{'value'};
    }
    public class CompanyCreditStatusError {
        public String reason;
        private String[] reason_type_info = new String[]{'reason','https://www.google.com/apis/ads/publisher/v201411',null,'0','1','false'};
        private String[] apex_schema_type_info = new String[]{'https://www.google.com/apis/ads/publisher/v201411','true','false'};
        private String[] field_order_type_info = new String[]{'reason'};
    }
    public class Statement {
        public String query;
        public DART6_COMPANYSERVICE.String_ValueMapEntry[] values;
        private String[] query_type_info = new String[]{'query','https://www.google.com/apis/ads/publisher/v201411',null,'0','1','false'};
        private String[] values_type_info = new String[]{'values','https://www.google.com/apis/ads/publisher/v201411',null,'0','-1','false'};
        private String[] apex_schema_type_info = new String[]{'https://www.google.com/apis/ads/publisher/v201411','true','false'};
        private String[] field_order_type_info = new String[]{'query','values'};
    }
    public class getCompaniesByStatement_element {
        public DART6_COMPANYSERVICE.Statement filterStatement;
        private String[] filterStatement_type_info = new String[]{'filterStatement','https://www.google.com/apis/ads/publisher/v201411',null,'0','1','false'};
        private String[] apex_schema_type_info = new String[]{'https://www.google.com/apis/ads/publisher/v201411','true','false'};
        private String[] field_order_type_info = new String[]{'filterStatement'};
    }
    public class PublisherQueryLanguageContextError {
        public String reason;
        private String[] reason_type_info = new String[]{'reason','https://www.google.com/apis/ads/publisher/v201411',null,'0','1','false'};
        private String[] apex_schema_type_info = new String[]{'https://www.google.com/apis/ads/publisher/v201411','true','false'};
        private String[] field_order_type_info = new String[]{'reason'};
    }
    public class ApiError {
        public String fieldPath;
        public String trigger_x;
        public String errorString;
        public String ApiError_Type;
        private String[] fieldPath_type_info = new String[]{'fieldPath','https://www.google.com/apis/ads/publisher/v201411',null,'0','1','false'};
        private String[] trigger_x_type_info = new String[]{'trigger','https://www.google.com/apis/ads/publisher/v201411',null,'0','1','false'};
        private String[] errorString_type_info = new String[]{'errorString','https://www.google.com/apis/ads/publisher/v201411',null,'0','1','false'};
        private String[] ApiError_Type_type_info = new String[]{'ApiError.Type','https://www.google.com/apis/ads/publisher/v201411',null,'0','1','false'};
        private String[] apex_schema_type_info = new String[]{'https://www.google.com/apis/ads/publisher/v201411','true','false'};
        private String[] field_order_type_info = new String[]{'fieldPath','trigger_x','errorString','ApiError_Type'};
    }
    public class SoapRequestHeader {
        public String networkCode;
        public String applicationName;
        private String[] networkCode_type_info = new String[]{'networkCode','https://www.google.com/apis/ads/publisher/v201411',null,'0','1','false'};
        private String[] applicationName_type_info = new String[]{'applicationName','https://www.google.com/apis/ads/publisher/v201411',null,'0','1','false'};
        private String[] apex_schema_type_info = new String[]{'https://www.google.com/apis/ads/publisher/v201411','true','false'};
        private String[] field_order_type_info = new String[]{'networkCode','applicationName'};
    }
    public class TeamError {
        public String reason;
        private String[] reason_type_info = new String[]{'reason','https://www.google.com/apis/ads/publisher/v201411',null,'0','1','false'};
        private String[] apex_schema_type_info = new String[]{'https://www.google.com/apis/ads/publisher/v201411','true','false'};
        private String[] field_order_type_info = new String[]{'reason'};
    }
    public class ObjectValue {
        private String[] apex_schema_type_info = new String[]{'https://www.google.com/apis/ads/publisher/v201411','true','false'};
        private String[] field_order_type_info = new String[]{};
    }
    public class createCompaniesResponse_element {
        public DART6_COMPANYSERVICE.Company[] rval;
        private String[] rval_type_info = new String[]{'rval','https://www.google.com/apis/ads/publisher/v201411',null,'0','-1','false'};
        private String[] apex_schema_type_info = new String[]{'https://www.google.com/apis/ads/publisher/v201411','true','false'};
        private String[] field_order_type_info = new String[]{'rval'};
    }
    public class ApiException extends Exception {
        public DART6_COMPANYSERVICE.ApiError[] errors;
        private String[] errors_type_info = new String[]{'errors','https://www.google.com/apis/ads/publisher/v201411',null,'0','-1','false'};
        private String[] apex_schema_type_info = new String[]{'https://www.google.com/apis/ads/publisher/v201411','true','false'};
        private String[] field_order_type_info = new String[]{'errors'};
    }
    public class Company {
        public Long id;
        public String name;
        public String type_x;
        public String address;
        public String email;
        public String faxPhone;
        public String primaryPhone;
        public String externalId;
        public String comment;
        public String creditStatus;
        public DART6_COMPANYSERVICE.AppliedLabel[] appliedLabels;
        public Boolean enableSameAdvertiserCompetitiveExclusion;
        public Long primaryContactId;
        public Long[] appliedTeamIds;
        public Integer thirdPartyCompanyId;
        public DART6_COMPANYSERVICE.DateTime_x lastModifiedDateTime;
        private String[] id_type_info = new String[]{'id','https://www.google.com/apis/ads/publisher/v201411',null,'0','1','false'};
        private String[] name_type_info = new String[]{'name','https://www.google.com/apis/ads/publisher/v201411',null,'0','1','false'};
        private String[] type_x_type_info = new String[]{'type','https://www.google.com/apis/ads/publisher/v201411',null,'0','1','false'};
        private String[] address_type_info = new String[]{'address','https://www.google.com/apis/ads/publisher/v201411',null,'0','1','false'};
        private String[] email_type_info = new String[]{'email','https://www.google.com/apis/ads/publisher/v201411',null,'0','1','false'};
        private String[] faxPhone_type_info = new String[]{'faxPhone','https://www.google.com/apis/ads/publisher/v201411',null,'0','1','false'};
        private String[] primaryPhone_type_info = new String[]{'primaryPhone','https://www.google.com/apis/ads/publisher/v201411',null,'0','1','false'};
        private String[] externalId_type_info = new String[]{'externalId','https://www.google.com/apis/ads/publisher/v201411',null,'0','1','false'};
        private String[] comment_type_info = new String[]{'comment','https://www.google.com/apis/ads/publisher/v201411',null,'0','1','false'};
        private String[] creditStatus_type_info = new String[]{'creditStatus','https://www.google.com/apis/ads/publisher/v201411',null,'0','1','false'};
        private String[] appliedLabels_type_info = new String[]{'appliedLabels','https://www.google.com/apis/ads/publisher/v201411',null,'0','-1','false'};
        private String[] enableSameAdvertiserCompetitiveExclusion_type_info = new String[]{'enableSameAdvertiserCompetitiveExclusion','https://www.google.com/apis/ads/publisher/v201411',null,'0','1','false'};
        private String[] primaryContactId_type_info = new String[]{'primaryContactId','https://www.google.com/apis/ads/publisher/v201411',null,'0','1','false'};
        private String[] appliedTeamIds_type_info = new String[]{'appliedTeamIds','https://www.google.com/apis/ads/publisher/v201411',null,'0','-1','false'};
        private String[] thirdPartyCompanyId_type_info = new String[]{'thirdPartyCompanyId','https://www.google.com/apis/ads/publisher/v201411',null,'0','1','false'};
        private String[] lastModifiedDateTime_type_info = new String[]{'lastModifiedDateTime','https://www.google.com/apis/ads/publisher/v201411',null,'0','1','false'};
        private String[] apex_schema_type_info = new String[]{'https://www.google.com/apis/ads/publisher/v201411','true','false'};
        private String[] field_order_type_info = new String[]{'id','name','type_x','address','email','faxPhone','primaryPhone','externalId','comment','creditStatus','appliedLabels','enableSameAdvertiserCompetitiveExclusion','primaryContactId','appliedTeamIds','thirdPartyCompanyId','lastModifiedDateTime'};
    }
    public class QuotaError {
        public String reason;
        private String[] reason_type_info = new String[]{'reason','https://www.google.com/apis/ads/publisher/v201411',null,'0','1','false'};
        private String[] apex_schema_type_info = new String[]{'https://www.google.com/apis/ads/publisher/v201411','true','false'};
        private String[] field_order_type_info = new String[]{'reason'};
    }
    public class DateValue {
        public DART6_COMPANYSERVICE.Date_x value;
        private String[] value_type_info = new String[]{'value','https://www.google.com/apis/ads/publisher/v201411',null,'0','1','false'};
        private String[] apex_schema_type_info = new String[]{'https://www.google.com/apis/ads/publisher/v201411','true','false'};
        private String[] field_order_type_info = new String[]{'value'};
    }
    public class ApplicationException extends Exception{
        public String message;
        public String ApplicationException_Type;
        private String[] message_type_info = new String[]{'message','https://www.google.com/apis/ads/publisher/v201411',null,'0','1','false'};
        private String[] ApplicationException_Type_type_info = new String[]{'ApplicationException.Type','https://www.google.com/apis/ads/publisher/v201411',null,'0','1','false'};
        private String[] apex_schema_type_info = new String[]{'https://www.google.com/apis/ads/publisher/v201411','true','false'};
        private String[] field_order_type_info = new String[]{'message','ApplicationException_Type'};
    }
    public class CrossSellError {
        public String reason;
        private String[] reason_type_info = new String[]{'reason','https://www.google.com/apis/ads/publisher/v201411',null,'0','1','false'};
        private String[] apex_schema_type_info = new String[]{'https://www.google.com/apis/ads/publisher/v201411','true','false'};
        private String[] field_order_type_info = new String[]{'reason'};
    }
    public class ApiVersionError {
        public String reason;
        private String[] reason_type_info = new String[]{'reason','https://www.google.com/apis/ads/publisher/v201411',null,'0','1','false'};
        private String[] apex_schema_type_info = new String[]{'https://www.google.com/apis/ads/publisher/v201411','true','false'};
        private String[] field_order_type_info = new String[]{'reason'};
    }
    public class ParseError {
        public String reason;
        private String[] reason_type_info = new String[]{'reason','https://www.google.com/apis/ads/publisher/v201411',null,'0','1','false'};
        private String[] apex_schema_type_info = new String[]{'https://www.google.com/apis/ads/publisher/v201411','true','false'};
        private String[] field_order_type_info = new String[]{'reason'};
    }
    public class LabelEntityAssociationError {
        public String reason;
        private String[] reason_type_info = new String[]{'reason','https://www.google.com/apis/ads/publisher/v201411',null,'0','1','false'};
        private String[] apex_schema_type_info = new String[]{'https://www.google.com/apis/ads/publisher/v201411','true','false'};
        private String[] field_order_type_info = new String[]{'reason'};
    }
    public class ServerError {
        public String reason;
        private String[] reason_type_info = new String[]{'reason','https://www.google.com/apis/ads/publisher/v201411',null,'0','1','false'};
        private String[] apex_schema_type_info = new String[]{'https://www.google.com/apis/ads/publisher/v201411','true','false'};
        private String[] field_order_type_info = new String[]{'reason'};
    }
    public class StatementError {
        public String reason;
        private String[] reason_type_info = new String[]{'reason','https://www.google.com/apis/ads/publisher/v201411',null,'0','1','false'};
        private String[] apex_schema_type_info = new String[]{'https://www.google.com/apis/ads/publisher/v201411','true','false'};
        private String[] field_order_type_info = new String[]{'reason'};
    }
    public class TextValue {
        public String value;
        private String[] value_type_info = new String[]{'value','https://www.google.com/apis/ads/publisher/v201411',null,'0','1','false'};
        private String[] apex_schema_type_info = new String[]{'https://www.google.com/apis/ads/publisher/v201411','true','false'};
        private String[] field_order_type_info = new String[]{'value'};
    }
    public class InvalidEmailError {
        public String reason;
        private String[] reason_type_info = new String[]{'reason','https://www.google.com/apis/ads/publisher/v201411',null,'0','1','false'};
        private String[] apex_schema_type_info = new String[]{'https://www.google.com/apis/ads/publisher/v201411','true','false'};
        private String[] field_order_type_info = new String[]{'reason'};
    }
    public class createCompanies_element {
        public DART6_COMPANYSERVICE.Company[] companies;
        private String[] companies_type_info = new String[]{'companies','https://www.google.com/apis/ads/publisher/v201411',null,'0','-1','false'};
        private String[] apex_schema_type_info = new String[]{'https://www.google.com/apis/ads/publisher/v201411','true','false'};
        private String[] field_order_type_info = new String[]{'companies'};
    }
    public class CompanyServiceInterfacePort {
        public String endpoint_x = 'https://ads.google.com/apis/ads/publisher/v201411/CompanyService';
        public Map<String,String> inputHttpHeaders_x;
        public Map<String,String> outputHttpHeaders_x;
        public String clientCertName_x;
        public String clientCert_x;
        public String clientCertPasswd_x;
        public Integer timeout_x;
        public DART6_COMPANYSERVICE.SoapRequestHeader RequestHeader;
        public DART6_COMPANYSERVICE.SoapResponseHeader ResponseHeader;
        private String RequestHeader_hns = 'RequestHeader=https://www.google.com/apis/ads/publisher/v201411';
        private String ResponseHeader_hns = 'ResponseHeader=https://www.google.com/apis/ads/publisher/v201411';
        private String[] ns_map_type_info = new String[]{'https://www.google.com/apis/ads/publisher/v201411', 'DART6_COMPANYSERVICE'};
        public DART6_COMPANYSERVICE.Company[] updateCompanies(DART6_COMPANYSERVICE.Company[] companies) {
            DART6_COMPANYSERVICE.updateCompanies_element request_x = new DART6_COMPANYSERVICE.updateCompanies_element();
            request_x.companies = companies;
            DART6_COMPANYSERVICE.updateCompaniesResponse_element response_x;
            Map<String, DART6_COMPANYSERVICE.updateCompaniesResponse_element> response_map_x = new Map<String, DART6_COMPANYSERVICE.updateCompaniesResponse_element>();
            response_map_x.put('response_x', response_x);
            WebServiceCallout.invoke(
              this,
              request_x,
              response_map_x,
              new String[]{endpoint_x,
              '',
              'https://www.google.com/apis/ads/publisher/v201411',
              'updateCompanies',
              'https://www.google.com/apis/ads/publisher/v201411',
              'updateCompaniesResponse',
              'DART6_COMPANYSERVICE.updateCompaniesResponse_element'}
            );
            response_x = response_map_x.get('response_x');
            return response_x.rval;
        }
        public DART6_COMPANYSERVICE.CompanyPage getCompaniesByStatement(DART6_COMPANYSERVICE.Statement filterStatement) {
            DART6_COMPANYSERVICE.getCompaniesByStatement_element request_x = new DART6_COMPANYSERVICE.getCompaniesByStatement_element();
            request_x.filterStatement = filterStatement;
            DART6_COMPANYSERVICE.getCompaniesByStatementResponse_element response_x;
            Map<String, DART6_COMPANYSERVICE.getCompaniesByStatementResponse_element> response_map_x = new Map<String, DART6_COMPANYSERVICE.getCompaniesByStatementResponse_element>();
            response_map_x.put('response_x', response_x);
            WebServiceCallout.invoke(
              this,
              request_x,
              response_map_x,
              new String[]{endpoint_x,
              '',
              'https://www.google.com/apis/ads/publisher/v201411',
              'getCompaniesByStatement',
              'https://www.google.com/apis/ads/publisher/v201411',
              'getCompaniesByStatementResponse',
              'DART6_COMPANYSERVICE.getCompaniesByStatementResponse_element'}
            );
            response_x = response_map_x.get('response_x');
            return response_x.rval;
        }
        public DART6_COMPANYSERVICE.Company[] createCompanies(DART6_COMPANYSERVICE.Company[] companies) {
            DART6_COMPANYSERVICE.createCompanies_element request_x = new DART6_COMPANYSERVICE.createCompanies_element();
            request_x.companies = companies;
            DART6_COMPANYSERVICE.createCompaniesResponse_element response_x;
            Map<String, DART6_COMPANYSERVICE.createCompaniesResponse_element> response_map_x = new Map<String, DART6_COMPANYSERVICE.createCompaniesResponse_element>();
            
			if(!Test.isRunningTest()) 
 		    { response_map_x.put('response_x', response_x);
              WebServiceCallout.invoke(
				  this,
				  request_x,
				  response_map_x,
				  new String[]{endpoint_x,
				  '',
				  'https://www.google.com/apis/ads/publisher/v201411',
				  'createCompanies',
				  'https://www.google.com/apis/ads/publisher/v201411',
				  'createCompaniesResponse',
				  'DART6_COMPANYSERVICE.createCompaniesResponse_element'}
				);
		    }else{
			     response_map_x.put('response_x', DARTMockUp.getMockDart6CompanyResponse_x()); 
			}
            response_x = response_map_x.get('response_x');
            return response_x.rval;
        }
    }
}