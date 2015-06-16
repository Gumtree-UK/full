/**

GTCRM-222 - Automate client reporting for AdSales

Change log:
- Additional column for eCPM in Summary & Daily Reporting

**/

public with sharing class ExcelReportHelper { 
  
  
  // Additional column for eCPM in Daily Reporting
  // public static final String ADDITIONAL_COL ='Line Description; Frequency Cap; Booked Amount; Delivered Amount; Rate; Delivery Index';
  
  public static final String ADDITIONAL_COL ='Line Description; Frequency Cap; Booked Amount; Delivered Amount; Rate; Delivery Index; eCPM';
  public static final String BILL_CAT_CPM ='CPM';
     public static final String BILL_CAT_CPO ='CPO';
    public static final String BILL_CAT_CPC ='CPC';
    public static final String BILL_CAT_FIXPRICE ='Fix Price';
  public static final String CURRENCY_ISO_EUR ='EUR';
  public static final String CONTACT_ROLE_REPORT_RECEIVER ='Reporting Receiver';
  public static final String CONTACT_ROLE_OTHER ='Media Planner';
  public static final String INTERVAL_WEEKLY ='Weekly';
    public static final String INTERVAL_MONTHLY ='Monthly';
    public static final String PRO_RECORD_TYPE_PACKAGE ='Package';
  public static final String REPORT_LANGUAGE_GE ='German';
  public static final String REPORT_LANGUAGE_EN ='English'; 
    public static final String WEEKDAY_TUE ='Tuesday';
  
    public static final Set<String> SET_CMPFIXPRICE = new Set<String>{BILL_CAT_CPM, BILL_CAT_FIXPRICE};// for if conditions in loop
    
    //for return record_type id
    Static Set<String> setRecordTypeName= new Set<String>{PRO_RECORD_TYPE_PACKAGE};
    Static Map<String, String> mapRecordTypeNameId = new Map<String, String>();
    public static String getRecordTypeId(String name){
      if(mapRecordTypeNameId.isEmpty()){
        List<RecordType> listRecordType=[Select Id, Name From RecordType where Name IN :setRecordTypeName];
      for(RecordType r:listRecordType){mapRecordTypeNameId.put(r.Name, r.id);}
      }
      return mapRecordTypeNameId.get(name);
    }
    
  //Store currency code-sign
  public static Map<String, String> mapCurrencyCodeSign= new Map<String, String>{
        'AUD'=>'$',
        'CAD'=>'$',
        'CHF'=>'Fr.',
        'EUR'=>'€',
        'GBP'=>'£',
        'HKD'=>'$',
        'INR'=>'र',
        'MYR'=>'$',
        'PHP'=>'₱',
        'PLN'=>'zł',
        'SGD'=>'$',
        'USD'=>'$'
  };
    
  /**  
    *   division and return string
    *       @param1 is dividing number
    *       @param2 is divider
    */
    public static String divisionAsString(String num, String divider){
        Double result;
        Try{
            result=Double.valueOf(num)/Double.valueOf(divider);
        }catch(Exception e){
            return '';
        }
        return String.valueOf(result);
    }
    
    /**
    *   multi and return string
    *       @param1  
    *       @param2
    */
    public static String multiAsString(String num1, String num2){
        Double result;
        Try{
            result=Double.valueOf(num1)*Double.valueOf(num2);
        }catch(Exception e){
            return '';
        }
        return String.valueOf(result);
    }
    
    /** Check the current column: if it is 'Delivered Impressions' or 'Click Rate'.
    *   and 'Billing Category'=CPC)  
    *       @param1  column's name
    *       @param2  Billing Category
    */
    public static boolean isCPC(String column, String billCat){
        if((column==ExcelReport.COL_DELIV_IMPR || column==ExcelReport.COL_CLICK_RATE)&& billCat==BILL_CAT_CPC){
            return true;
        }
        return false; 
    }
   
    /** Check the current column: if it is 'Click Rate'
    *   and 'Billing Category'=CPM or Fix Price)    
    *       @param1  column's name
    *       @param2  Billing Category
    
    public static boolean isCpmFixprice(String column, String billCat){
        if(column=='Click Rate' && SET_CMPFIXPRICE.contains(billCat)){
            return true;
        }
        return false;
    }
    */
    
  //This string is xml spreedsheet
  public static final String XML='<?xml version="1.0"?>'+
                '<?mso-application progid="Excel.Sheet"?>'+
                '<Workbook xmlns="urn:schemas-microsoft-com:office:spreadsheet"'+
                ' xmlns:o="urn:schemas-microsoft-com:office:office"'+
                ' xmlns:x="urn:schemas-microsoft-com:office:excel"'+
                ' xmlns:ss="urn:schemas-microsoft-com:office:spreadsheet"'+
                ' xmlns:html="http://www.w3.org/TR/REC-html40">'+
                ' <DocumentProperties xmlns="urn:schemas-microsoft-com:office:office">'+
                '  <Author></Author>'+
                '  <LastAuthor></LastAuthor>'+
                '  <TotalTime></TotalTime>'+
                '  <LastPrinted></LastPrinted>'+
                '  <Created></Created>'+
                '  <LastSaved></LastSaved>'+
                '  <Version></Version>'+
                ' </DocumentProperties>'+
                ' <OfficeDocumentSettings xmlns="urn:schemas-microsoft-com:office:office">'+
                '  <Colors>'+
                '   <Color>'+
                '    <Index>38</Index>'+ 
                '    <RGB>#EBEBF7</RGB>'+
                '   </Color>'+
                '  </Colors>'+
                ' </OfficeDocumentSettings>'+
                ' <ExcelWorkbook xmlns="urn:schemas-microsoft-com:office:excel">'+
                '  <WindowHeight>8445</WindowHeight>'+
                '  <WindowWidth>12120</WindowWidth>'+
                '  <WindowTopX>360</WindowTopX>'+
                '  <WindowTopY>270</WindowTopY>'+
                '  <ProtectStructure>False</ProtectStructure>'+
                '  <ProtectWindows>False</ProtectWindows>'+
                ' </ExcelWorkbook>'+
                ' <Styles>'+
                '  <Style ss:ID="Default" ss:Name="Normal">'+
                '   <Alignment ss:Vertical="Bottom"/>'+
                '   <Borders/>'+
                '   <Font ss:FontName="Arial"/>'+
                '   <Interior/>'+
                '   <NumberFormat/>'+
                '   <Protection/>'+
                '  </Style>'+
                '  <Style ss:ID="s16" ss:Name="Comma">'+
                '   <NumberFormat ss:Format="_(* #,##0.00_);_(* \\(#,##0.00\\);_(* &quot;-&quot;??_);_(@_)"/>'+
                '  </Style>'+
                '  <Style ss:ID="s18" ss:Name="Currency">'+
                '   <NumberFormat'+
                '    ss:Format="_-* #,##0.00\\ &quot;{!@#}&quot;_-;\\-* #,##0.00\\ &quot;{!@#}&quot;_-;_-* &quot;-&quot;??\\ &quot;{!@#}&quot;_-;_-@_-"/>'+
                '  </Style>'+
                '  <Style ss:ID="s17" ss:Name="Percent">'+
                '   <NumberFormat ss:Format="0%"/>'+
                '  </Style>'+
                '  <Style ss:ID="s19">'+
                '   <Alignment ss:Horizontal="Left" ss:Vertical="Bottom"/>'+
                '  </Style>'+
                '  <Style ss:ID="s20">'+
                '   <Borders>'+
                '    <Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1"'+
                '     ss:Color="#000000"/>'+
                '    <Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1"'+
                '     ss:Color="#000000"/>'+
                '    <Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1"'+
                '     ss:Color="#000000"/>'+
                '    <Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="1"'+
                '     ss:Color="#000000"/>'+
                '   </Borders>'+
                '   <NumberFormat ss:Format="#,##0"/>'+
                '  </Style>'+
                '  <Style ss:ID="s21">'+
                '   <NumberFormat ss:Format="#,##0"/>'+
                '  </Style>'+
                '  <Style ss:ID="s22">'+
                '   <Alignment ss:Horizontal="Right" ss:Vertical="Bottom"/>'+
                '   <Borders/>'+
                '   <Interior ss:Color="#FFFFFF" ss:Pattern="Solid"/>'+
                '  </Style>'+
                '  <Style ss:ID="s23">'+
                '   <Alignment ss:Horizontal="Right" ss:Vertical="Bottom"/>'+
                '   <Borders/>'+
                '   <Interior ss:Color="#FFFFFF" ss:Pattern="Solid"/>'+
                '   <NumberFormat ss:Format="#,##0"/>'+
                '  </Style>'+
                '  <Style ss:ID="s24">'+
                '   <Alignment ss:Horizontal="Left" ss:Vertical="Bottom"/>'+
                '   <Borders/>'+
                '   <Interior ss:Color="#FFFFFF" ss:Pattern="Solid"/>'+
                '  </Style>'+
                '  <Style ss:ID="s25">'+
                '   <Alignment ss:Horizontal="Left" ss:Vertical="Bottom"/>'+
                '   <Borders/>'+
                '   <Font ss:FontName="Arial" x:Family="Swiss" ss:Bold="1"/>'+
                '   <Interior ss:Color="#FFFFFF" ss:Pattern="Solid"/>'+
                '  </Style>'+
                '  <Style ss:ID="s26">'+
                '   <Alignment ss:Vertical="Bottom"/>'+
                '   <Font ss:FontName="Arial" x:Family="Swiss" ss:Color="#222222"/>'+
                '  </Style>'+
                '  <Style ss:ID="s27">'+
                '   <Alignment ss:Vertical="Bottom" ss:WrapText="1"/>'+
                '   <Borders/>'+
                '   <Font ss:FontName="Arial" x:Family="Swiss"/>'+
                '   <Interior ss:Color="#FFFFFF" ss:Pattern="Solid"/>'+
                '  </Style>'+
                '  <Style ss:ID="s28">'+
                '   <Alignment ss:Horizontal="Left" ss:Vertical="Bottom"/>'+
                '   <Font ss:FontName="Arial" x:Family="Swiss" ss:Color="#222222"/>'+
                '  </Style>'+
                '  <Style ss:ID="s29">'+
                '   <Alignment ss:Horizontal="Left" ss:Vertical="Bottom" ss:Indent="1"/>'+
                '   <Borders>'+
                '    <Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1"'+
                '     ss:Color="#000000"/>'+
                '    <Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1"'+
                '     ss:Color="#000000"/>'+
                '    <Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1"'+
                '     ss:Color="#000000"/>'+
                '   </Borders>'+
                '   <NumberFormat ss:Format="[ENG][$-409]d\\-mmm\\-yy;@"/>'+
                '  </Style>'+
                '  <Style ss:ID="s30">'+
                '   <Font ss:FontName="Arial" x:Family="Swiss" ss:Color="#222222"/>'+
                '  </Style>'+
                '  <Style ss:ID="s32" ss:Parent="s17">'+
                '   <Alignment ss:Horizontal="Right" ss:Vertical="Bottom"/>'+
                '   <Borders/>'+
                '   <Font ss:FontName="Arial"/>'+
                '   <Interior ss:Color="#FFFFFF" ss:Pattern="Solid"/>'+
                '   <NumberFormat ss:Format="Percent"/>'+
                '  </Style>'+
                '  <Style ss:ID="s33" ss:Parent="s17">'+
                '   <Font ss:FontName="Arial"/>'+
                '   <NumberFormat ss:Format="Percent"/>'+
                '  </Style>'+
                '  <Style ss:ID="s34">'+
                '   <Font ss:FontName="Arial" x:Family="Swiss"/>'+
                '  </Style>'+
                '  <Style ss:ID="s35">'+
                '   <Alignment ss:Horizontal="Right" ss:Vertical="Bottom"/>'+
                '   <Borders/>'+
                '   <Font ss:FontName="Arial" x:Family="Swiss" ss:Bold="1"/>'+
                '   <Interior ss:Color="#FFFFFF" ss:Pattern="Solid"/>'+
                '  </Style>'+
                '  <Style ss:ID="s36">'+
                '   <Font ss:FontName="Arial" x:Family="Swiss" ss:Bold="1"/>'+
                '  </Style>'+
                '  <Style ss:ID="s37">'+
                '   <Alignment ss:Horizontal="Left" ss:Vertical="Bottom" ss:Indent="1"/>'+
                '   <Borders>'+
                '    <Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1"'+
                '     ss:Color="#000000"/>'+
                '    <Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1"'+
                '     ss:Color="#000000"/>'+
                '    <Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1"'+
                '     ss:Color="#000000"/>'+
                '    <Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="1"'+
                '     ss:Color="#000000"/>'+
                '   </Borders>'+
                '   <Font ss:FontName="Arial" x:Family="Swiss"/>'+
                '   <NumberFormat ss:Format="[ENG][$-409]d\\-mmm\\-yy;@"/>'+
                '  </Style>'+
                '  <Style ss:ID="s38">'+
                '   <Alignment ss:Horizontal="Left" ss:Vertical="Bottom"/>'+
                '   <Borders/>'+
                '   <Font ss:FontName="Arial" x:Family="Swiss"/>'+
                '   <Interior ss:Color="#FFFFFF" ss:Pattern="Solid"/>'+
                '  </Style>'+
                '  <Style ss:ID="s39">'+
                '   <Alignment ss:Horizontal="Left" ss:Vertical="Bottom" ss:Indent="1"/>'+
                '   <Borders>'+
                '    <Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1"'+
                '     ss:Color="#000000"/>'+
                '    <Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1"'+
                '     ss:Color="#000000"/>'+
                '    <Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1"'+
                '     ss:Color="#000000"/>'+
                '   </Borders>'+
                '   <Font ss:FontName="Arial" x:Family="Swiss"/>'+
                '  </Style>'+
                '  <Style ss:ID="s40">'+
                '   <Borders>'+
                '    <Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1"/>'+
                '    <Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1"/>'+
                '    <Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1"/>'+
                '    <Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="1"/>'+ 
                '   </Borders>'+
                '   <Font ss:FontName="Arial" x:Family="Swiss"/>'+
                '   <NumberFormat'+
                '    ss:Format="_-* #,##0.00\\ &quot;{!@#}&quot;_-;\\-* #,##0.00\\ &quot;{!@#}&quot;_-;_-* &quot;-&quot;??\\ &quot;{!@#}&quot;_-;_-@_-"/>'+
                '  </Style>'+
                '  <Style ss:ID="s41">'+
                '   <Borders>'+
                '    <Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1"'+
                '     ss:Color="#000000"/>'+
                '   </Borders>'+
                '   <Font ss:FontName="Arial" x:Family="Swiss"/>'+
                '   <NumberFormat'+
                '    ss:Format="_-* #,##0.00\\ &quot;{!@#}&quot;_-;\\-* #,##0.00\\ &quot;{!@#}&quot;_-;_-* &quot;-&quot;??\\ &quot;{!@#}&quot;_-;_-@_-"/>'+
                '  </Style>'+
                '  <Style ss:ID="s42" ss:Parent="s16">'+
                '   <Borders>'+
                '    <Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1"/>'+
                '    <Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1"/>'+
                '    <Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="1"/>'+
                '   </Borders>'+
                '   <Font ss:FontName="Arial" x:Family="Swiss" ss:Color="#000000"/>'+
                '   <NumberFormat'+
                '    ss:Format="_-* #,##0.00\\ &quot;{!@#}&quot;_-;\\-* #,##0.00\\ &quot;{!@#}&quot;_-;_-* &quot;-&quot;??\\ &quot;{!@#}&quot;_-;_-@_-"/>'+
                '  </Style>'+
                '  <Style ss:ID="s43">'+
                '   <Borders>'+
                '    <Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1"'+
                '     ss:Color="#000000"/>'+
                '    <Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1"'+
                '     ss:Color="#000000"/>'+
                '    <Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="1"'+
                '     ss:Color="#000000"/>'+
                '   </Borders>'+
                '   <Font ss:FontName="Arial" x:Family="Swiss"/>'+
                '   <NumberFormat ss:Format="_(* #,##0_);_(* \\(#,##0\\);_(* &quot;-&quot;??_);_(@_)"/>'+
                '  </Style>'+
                '  <Style ss:ID="s44">'+
                '   <Borders>'+
                '    <Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1"'+
                '     ss:Color="#000000"/>'+
                '    <Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1"'+
                '     ss:Color="#000000"/>'+
                '    <Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1"'+
                '     ss:Color="#000000"/>'+
                '    <Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="1"'+
                '     ss:Color="#000000"/>'+
                '   </Borders>'+
                '   <Font ss:FontName="Arial" x:Family="Swiss"/>'+
                '   <NumberFormat ss:Format="#,##0"/>'+
                '  </Style>'+
                '  <Style ss:ID="s45" ss:Parent="s17">'+
                '   <Borders>'+
                '    <Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1"'+
                '     ss:Color="#000000"/>'+
                '    <Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1"'+
                '     ss:Color="#000000"/>'+
                '    <Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1"'+
                '     ss:Color="#000000"/>'+
                '   </Borders>'+
                '   <Font ss:FontName="Arial" x:Family="Swiss"/>'+
                '   <NumberFormat ss:Format="#,##0"/>'+
                '  </Style>'+
                '  <Style ss:ID="s46" ss:Parent="s16">'+
                '   <Borders>'+
                '    <Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1"/>'+
                '    <Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1"/>'+
                '    <Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1"/>'+
                '    <Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="1"/>'+
                '   </Borders>'+
                '   <Font ss:FontName="Arial" x:Family="Swiss" ss:Color="#000000"/>'+
                '   <NumberFormat ss:Format="Percent"/>'+
                '  </Style>'+
                '  <Style ss:ID="s47">'+
                '   <Borders>'+
                '    <Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1"'+
                '     ss:Color="#000000"/>'+
                '    <Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1"/>'+
                '    <Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1"/>'+
                '    <Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="1"'+
                '     ss:Color="#000000"/>'+
                '   </Borders>'+
                '   <Font ss:FontName="Arial" x:Family="Swiss"/>'+
                '   <NumberFormat'+
                '    ss:Format="_-* #,##0.00\\ &quot;{!@#}&quot;_-;\\-* #,##0.00\\ &quot;{!@#}&quot;_-;_-* &quot;-&quot;??\\ &quot;{!@#}&quot;_-;_-@_-"/>'+
                '  </Style>'+
                '  <Style ss:ID="s48">'+
                '   <Borders>'+
                '    <Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1"'+
                '     ss:Color="#000000"/>'+
                '    <Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1"/>'+
                '    <Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1"/>'+
                '   </Borders>'+
                '   <Font ss:FontName="Arial" x:Family="Swiss"/>'+
                '   <NumberFormat'+
                '    ss:Format="_-* #,##0.00\\ &quot;{!@#}&quot;_-;\\-* #,##0.00\\ &quot;{!@#}&quot;_-;_-* &quot;-&quot;??\\ &quot;{!@#}&quot;_-;_-@_-"/>'+
                '  </Style>'+
                '  <Style ss:ID="s49">'+
                '   <Alignment ss:Horizontal="Left" ss:Vertical="Bottom" ss:Indent="1"/>'+
                '   <Borders>'+
                '    <Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1"'+
                '     ss:Color="#000000"/>'+
                '    <Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1"'+
                '     ss:Color="#000000"/>'+
                '    <Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1"'+
                '     ss:Color="#000000"/>'+
                '   </Borders>'+
                '   <Font ss:FontName="Arial" x:Family="Swiss" ss:Bold="1"/>'+
                '   <NumberFormat ss:Format="[ENG][$-409]d\\-mmm\\-yy;@"/>'+
                '  </Style>'+
                '  <Style ss:ID="s50">'+
                '   <Borders>'+
                '    <Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1"'+
                '     ss:Color="#000000"/>'+
                '    <Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1"'+
                '     ss:Color="#000000"/>'+
                '    <Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="1"'+
                '     ss:Color="#000000"/>'+
                '   </Borders>'+
                '   <Font ss:FontName="Arial" x:Family="Swiss" ss:Bold="1"/>'+
                '   <NumberFormat ss:Format="#,##0"/>'+
                '  </Style>'+
                '  <Style ss:ID="s51" ss:Parent="s17">'+
                '   <Borders>'+
                '    <Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1"/>'+
                '    <Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1"/>'+
                '    <Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1"/>'+
                '   </Borders>'+
                '   <Font ss:FontName="Arial" x:Family="Swiss"/>'+
                '   <NumberFormat ss:Format="0"/>'+
                '  </Style>'+
                '  <Style ss:ID="s52">'+
                '   <Font ss:FontName="Arial" x:Family="Swiss" ss:Color="#FF0000"/>'+
                '  </Style>'+
                '  <Style ss:ID="s54">'+
                '   <Alignment ss:Horizontal="Right" ss:Vertical="Bottom"/>'+
                '   <Font ss:FontName="Arial" x:Family="Swiss" ss:Color="#FF0000"/>'+
                '  </Style>'+
                '  <Style ss:ID="s55">'+
                '   <Alignment ss:Horizontal="Right" ss:Vertical="Bottom"/>'+
                '   <Borders/>'+
                '   <Font ss:FontName="Arial" x:Family="Swiss" ss:Color="#FF0000"/>'+
                '   <Interior/>'+
                '  </Style>'+
                '  <Style ss:ID="s56">'+
                '   <Alignment ss:Horizontal="Left" ss:Vertical="Bottom"/>'+
                '   <Borders/>'+
                '   <Font ss:FontName="Arial" x:Family="Swiss" ss:Color="#FF0000"/>'+
                '   <Interior/>'+
                '  </Style>'+
                '  <Style ss:ID="s58">'+
                '   <Alignment ss:Horizontal="Left" ss:Vertical="Bottom" ss:WrapText="1"/>'+
                '   <Font ss:FontName="Arial" x:Family="Swiss" ss:Color="#FF0000"/>'+
                '  </Style>'+
                '  <Style ss:ID="s59">'+
                '   <Alignment ss:Horizontal="Left" ss:Vertical="Bottom" ss:Indent="1"/>'+
                '   <Borders/>'+
                '   <Font ss:FontName="Arial" x:Family="Swiss"/>'+
                '  </Style>'+
                '  <Style ss:ID="s60">'+
                '   <Alignment ss:Horizontal="Left" ss:Vertical="Bottom" ss:Indent="1"/>'+
                '   <Borders/>'+
                '   <Font ss:FontName="Arial" x:Family="Swiss"/>'+
                '   <NumberFormat ss:Format="[ENG][$-409]d\\-mmm\\-yy;@"/>'+
                '  </Style>'+
                '  <Style ss:ID="s61">'+
                '   <Borders/>'+
                '   <Font ss:FontName="Arial" x:Family="Swiss"/>'+
                '   <NumberFormat ss:Format="[ENG][$-409]d\\-mmm\\-yy;@"/>'+
                '  </Style>'+
                '  <Style ss:ID="s62">'+
                '   <Borders/>'+
                '   <Font ss:FontName="Arial" x:Family="Swiss"/>'+
                '   <NumberFormat ss:Format="mmm\\-yy"/>'+
                '  </Style>'+
                '  <Style ss:ID="s63">'+
                '   <Borders/>'+
                '   <Font ss:FontName="Arial" x:Family="Swiss"/>'+
                '   <NumberFormat'+
                '    ss:Format="_-* #,##0.00\\ &quot;{!@#}&quot;_-;\\-* #,##0.00\\ &quot;{!@#}&quot;_-;_-* &quot;-&quot;??\\ &quot;{!@#}&quot;_-;_-@_-"/>'+
                '  </Style>'+
                '  <Style ss:ID="s64" ss:Parent="s18">'+
                '   <Borders/>'+
                '   <Font ss:FontName="Arial" x:Family="Swiss"/>'+
                '   <NumberFormat/>'+
                '  </Style>'+
                '  <Style ss:ID="s65" ss:Parent="s16">'+
                '   <Borders/>'+
                '   <Font ss:FontName="Arial" x:Family="Swiss" ss:Color="#000000"/>'+
                '   <NumberFormat'+
                '    ss:Format="_-* #,##0.00\\ &quot;{!@#}&quot;_-;\\-* #,##0.00\\ &quot;{!@#}&quot;_-;_-* &quot;-&quot;??\\ &quot;{!@#}&quot;_-;_-@_-"/>'+
                '  </Style>'+
                '  <Style ss:ID="s66">'+
                '   <Borders/>'+
                '   <Font ss:FontName="Arial" x:Family="Swiss"/>'+
                '   <NumberFormat ss:Format="_(* #,##0_);_(* \\(#,##0\\);_(* &quot;-&quot;??_);_(@_)"/>'+
                '  </Style>'+
                '  <Style ss:ID="s67">'+
                '   <Borders/>'+
                '   <Font ss:FontName="Arial" x:Family="Swiss"/>'+
                '   <NumberFormat ss:Format="#,##0"/>'+
                '  </Style>'+
                '  <Style ss:ID="s68" ss:Parent="s17">'+
                '   <Borders/>'+
                '   <Font ss:FontName="Arial" x:Family="Swiss"/>'+
                '   <NumberFormat ss:Format="#,##0"/>'+
                '  </Style>'+
                '  <Style ss:ID="s69" ss:Parent="s16">'+
                '   <Borders/>'+
                '   <Font ss:FontName="Arial" x:Family="Swiss" ss:Color="#000000"/>'+
                '   <NumberFormat ss:Format="Percent"/>'+
                '  </Style>'+
                '  <Style ss:ID="s70" ss:Parent="s17">'+
                '   <Borders/>'+
                '   <Font ss:FontName="Arial" x:Family="Swiss"/>'+
                '   <NumberFormat ss:Format="0"/>'+
                '  </Style>'+
                '  <Style ss:ID="s71">'+
                '   <Alignment ss:Horizontal="Center" ss:Vertical="Bottom"/>'+
                '   <Borders>'+
                '    <Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1"'+
                '     ss:Color="#000000"/>'+
                '    <Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1"'+
                '     ss:Color="#000000"/>'+
                '    <Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1"'+
                '     ss:Color="#000000"/>'+
                '    <Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="1"'+
                '     ss:Color="#000000"/>'+
                '   </Borders>'+
                '   <Font ss:FontName="Arial" x:Family="Swiss"/>'+
                '   <NumberFormat ss:Format="[ENG][$-409]d\\-mmm\\-yy;@"/>'+
                '  </Style>'+
                '  <Style ss:ID="s72">'+
                '   <Alignment ss:Horizontal="Center" ss:Vertical="Bottom"/>'+
                '   <Borders>'+
                '    <Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1"/>'+
                '    <Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1"/>'+
                '    <Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1"/>'+
                '    <Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="1"/>'+
                '   </Borders>'+
                '   <Font ss:FontName="Arial" x:Family="Swiss"/>'+
                '   <NumberFormat ss:Format="mmm\\-yy"/>'+
                '  </Style>'+
                '  <Style ss:ID="s73" ss:Parent="s18">'+
                '   <Alignment ss:Horizontal="Center" ss:Vertical="Bottom"/>'+
                '   <Borders>'+
                '    <Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1"/>'+
                '    <Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1"/>'+
                '    <Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1"/>'+
                '    <Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="1"/>'+
                '   </Borders>'+
                '   <Font ss:FontName="Arial" x:Family="Swiss"/>'+
                '   <NumberFormat/>'+
                '  </Style>'+
                '  <Style ss:ID="s75">'+
                '   <Alignment ss:Vertical="Bottom"/>'+
                '   <Font ss:FontName="Arial" x:Family="Swiss"/>'+
                '  </Style>'+
                '  <Style ss:ID="s76">'+
                '   <Alignment ss:Horizontal="Left" ss:Vertical="Bottom"/>'+
                '   <Font ss:FontName="Arial" x:Family="Swiss"/>'+
                '  </Style>'+
                '  <Style ss:ID="s83">'+
                '   <Alignment ss:Vertical="Center"/>'+
                '  </Style>'+
                '  <Style ss:ID="s84">'+
                '   <Alignment ss:Horizontal="Center" ss:Vertical="Bottom"/>'+
                '   <Font ss:FontName="Arial" x:Family="Swiss" ss:Color="#FF0000"/>'+
                '  </Style>'+
                '  <Style ss:ID="s85">'+
                '   <Alignment ss:Horizontal="Center" ss:Vertical="Bottom"/>'+
                '   <Borders/>'+
                '   <Interior ss:Color="#FFFFFF" ss:Pattern="Solid"/>'+
                '  </Style>'+
                '  <Style ss:ID="s86">'+
                '   <Alignment ss:Horizontal="Center" ss:Vertical="Bottom"/>'+
                '   <Borders>'+
                '    <Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1"'+
                '     ss:Color="#000000"/>'+
                '    <Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1"'+
                '     ss:Color="#000000"/>'+
                '    <Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1"'+
                '     ss:Color="#000000"/>'+
                '    <Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="1"'+
                '     ss:Color="#000000"/>'+
                '   </Borders>'+
                '   <NumberFormat ss:Format="[ENG][$-409]d\\-mmm\\-yy;@"/>'+
                '  </Style>'+
                '  <Style ss:ID="s87">'+
                '   <Alignment ss:Horizontal="Center" ss:Vertical="Bottom"/>'+
                '   <Borders>'+
                '    <Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1"'+
                '     ss:Color="#000000"/>'+
                '    <Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1"'+
                '     ss:Color="#000000"/>'+
                '    <Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1"'+
                '     ss:Color="#000000"/>'+
                '    <Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="1"'+
                '     ss:Color="#000000"/>'+
                '   </Borders>'+
                '   <Font ss:FontName="Arial" x:Family="Swiss" ss:Bold="1"/>'+
                '   <NumberFormat ss:Format="[ENG][$-409]d\\-mmm\\-yy;@"/>'+
                '  </Style>'+
                '  <Style ss:ID="s88">'+
                '   <Alignment ss:Horizontal="Center" ss:Vertical="Bottom"/>'+
                '  </Style>'+
                '  <Style ss:ID="s89">'+
                '   <Alignment ss:Horizontal="Left" ss:Vertical="Bottom" ss:Indent="1"/>'+
                '  </Style>'+
                '  <Style ss:ID="s90">'+
                '   <Alignment ss:Horizontal="Left" ss:Vertical="Bottom" ss:Indent="1"/>'+
                '   <Borders/>'+
                '   <Interior ss:Color="#FFFFFF" ss:Pattern="Solid"/>'+
                '  </Style>'+
                '  <Style ss:ID="s91">'+
                '   <Alignment ss:Horizontal="Left" ss:Vertical="Bottom" ss:Indent="1"/>'+
                '   <Borders>'+
                '    <Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1"/>'+
                '    <Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1"/>'+
                '    <Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1"/>'+
                '   </Borders>'+
                '   <Font ss:FontName="Arial" x:Family="Swiss" ss:Color="#222222"/>'+
                '  </Style>'+
                '  <Style ss:ID="s92">'+
                '   <Alignment ss:Horizontal="Left" ss:Vertical="Bottom" ss:Indent="1"/>'+
                '   <Borders>'+
                '    <Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1"/>'+
                '    <Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1"/>'+
                '    <Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1"/>'+
                '   </Borders>'+
                '   <Font ss:FontName="Arial" x:Family="Swiss" ss:Color="#222222" ss:Bold="1"/>'+
                '  </Style>'+
                '  <Style ss:ID="s93">'+
                '   <Alignment ss:Horizontal="Center" ss:Vertical="Bottom"/>'+
                '   <Borders>'+
                '    <Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1"'+
                '     ss:Color="#000000"/>'+
                '    <Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1"'+
                '     ss:Color="#000000"/>'+
                '    <Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1"'+
                '     ss:Color="#000000"/>'+
                '   </Borders>'+
                '  </Style>'+
                '  <Style ss:ID="s94">'+
                '   <Alignment ss:Horizontal="Center" ss:Vertical="Bottom"/>'+
                '   <Borders>'+
                '    <Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1"'+
                '     ss:Color="#000000"/>'+
                '    <Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1"'+
                '     ss:Color="#000000"/>'+
                '    <Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1"'+
                '     ss:Color="#000000"/>'+
                '   </Borders>'+
                '   <Font ss:FontName="Arial" x:Family="Swiss" ss:Bold="1"/>'+
                '  </Style>'+
                '  <Style ss:ID="s95" ss:Parent="s17">'+
                '   <Alignment ss:Horizontal="Center" ss:Vertical="Bottom"/>'+
                '   <Font ss:FontName="Arial"/>'+
                '   <NumberFormat ss:Format="Percent"/>'+
                '  </Style>'+
                '  <Style ss:ID="s96" ss:Parent="s17">'+
                '   <Alignment ss:Horizontal="Center" ss:Vertical="Bottom"/>'+
                '   <Borders/>'+
                '   <Font ss:FontName="Arial"/>'+
                '   <Interior ss:Color="#FFFFFF" ss:Pattern="Solid"/>'+
                '   <NumberFormat ss:Format="Percent"/>'+
                '  </Style>'+
                '  <Style ss:ID="s97" ss:Parent="s17">'+
                '   <Alignment ss:Horizontal="Center" ss:Vertical="Bottom"/>'+
                '   <Borders>'+
                '    <Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1"'+
                '     ss:Color="#000000"/>'+
                '    <Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1"'+
                '     ss:Color="#000000"/>'+
                '    <Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1"'+
                '     ss:Color="#000000"/>'+
                '   </Borders>'+
                '   <Font ss:FontName="Arial"/>'+
                '   <NumberFormat ss:Format="Percent"/>'+
                '  </Style>'+
                '  <Style ss:ID="s98" ss:Parent="s17">'+
                '   <Alignment ss:Horizontal="Center" ss:Vertical="Bottom"/>'+
                '   <Borders>'+
                '    <Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1"'+
                '     ss:Color="#000000"/>'+
                '    <Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1"'+
                '     ss:Color="#000000"/>'+
                '    <Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1"'+
                '     ss:Color="#000000"/>'+
                '   </Borders>'+
                '   <Font ss:FontName="Arial" x:Family="Swiss" ss:Bold="1"/>'+
                '   <NumberFormat ss:Format="Percent"/>'+
                '  </Style>'+
                '  <Style ss:ID="s142">'+
                '   <Alignment ss:Horizontal="Center" ss:Vertical="Center" ss:WrapText="1"/>'+
                '   <Borders>'+
                '    <Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="2"/>'+
                '    <Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="2"/>'+
                '    <Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="2"/>'+
                '    <Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="2"/>'+
                '   </Borders>'+
                '   <Font ss:FontName="Arial" x:Family="Swiss" ss:Bold="1"/>'+
                '   <Interior ss:Color="#C0C0C0" ss:Pattern="Solid"/>'+
                '  </Style>'+
                '  <Style ss:ID="s143">'+
                '   <Alignment ss:Horizontal="Center" ss:Vertical="Center"/>'+
                '   <Borders>'+
                '    <Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="2"/>'+
                '    <Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="2"/>'+
                '    <Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="2"/>'+
                '    <Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="2"/>'+
                '   </Borders>'+
                '   <Font ss:FontName="Arial" x:Family="Swiss" ss:Color="#222222" ss:Bold="1"/>'+
                '   <Interior ss:Color="#BFBFBF" ss:Pattern="Solid"/>'+
                '  </Style>'+
                '  <Style ss:ID="s144">'+
                '   <Alignment ss:Horizontal="Center" ss:Vertical="Center"/>'+
                '   <Borders>'+
                '    <Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="2"/>'+
                '    <Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="2"/>'+
                '    <Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="2"/>'+
                '    <Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="2"/>'+
                '   </Borders>'+
                '   <Font ss:FontName="Arial" x:Family="Swiss" ss:Bold="1"/>'+
                '   <Interior ss:Color="#BFBFBF" ss:Pattern="Solid"/>'+
                '  </Style>'+
                '  <Style ss:ID="s145">'+
                '   <Alignment ss:Horizontal="Center" ss:Vertical="Center" ss:WrapText="1"/>'+
                '   <Borders>'+
                '    <Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="2"/>'+
                '    <Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="2"/>'+
                '    <Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="2"/>'+
                '    <Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="2"/>'+
                '   </Borders>'+
                '   <Font ss:FontName="Arial" x:Family="Swiss" ss:Bold="1"/>'+
                '   <Interior ss:Color="#C0C0C0" ss:Pattern="Solid"/>'+
                '   <NumberFormat ss:Format="#,##0"/>'+
                '  </Style>'+
                '  <Style ss:ID="s146" ss:Parent="s17">'+
                '   <Alignment ss:Horizontal="Center" ss:Vertical="Center" ss:WrapText="1"/>'+
                '   <Borders>'+
                '    <Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="2"/>'+
                '    <Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="2"/>'+
                '    <Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="2"/>'+
                '    <Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="2"/>'+
                '   </Borders>'+
                '   <Font ss:FontName="Arial" x:Family="Swiss" ss:Bold="1"/>'+
                '   <Interior ss:Color="#C0C0C0" ss:Pattern="Solid"/>'+
                '   <NumberFormat ss:Format="Percent"/>'+
                '  </Style>'+
                '  <Style ss:ID="s147">'+
                '   <Alignment ss:Horizontal="Center" ss:Vertical="Bottom"/>'+
                '   <Borders>'+
                '    <Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="2"/>'+
                '    <Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="2"/>'+
                '    <Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="2"/>'+
                '    <Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="2"/>'+
                '   </Borders>'+
                '   <Font ss:FontName="Arial" x:Family="Swiss" ss:Color="#222222" ss:Bold="1"/>'+
                '   <Interior ss:Color="#BFBFBF" ss:Pattern="Solid"/>'+
                '  </Style>'+
                '  <Style ss:ID="DateWithoutBorder">'+
                '   <Alignment ss:Horizontal="Left" ss:Vertical="Bottom"/>'+
                '   <NumberFormat ss:Format="[ENG][$-409]d\\-mmm\\-yy;@"/>'+
                '  </Style>'+
'  <Style ss:ID="ss16" ss:Name="Comma2">'+
'   <NumberFormat ss:Format="_(* #,##0.00_);_(* \\(#,##0.00\\);_(* &quot;-&quot;??_);_(@_)"/>'+
'  </Style>'+
'  <Style ss:ID="ss18" ss:Name="Currency2">'+
'   <NumberFormat'+
'    ss:Format="_-* #,##0.00\\ &quot;{!@#}&quot;_-;\\-* #,##0.00\\ &quot;{!@#}&quot;_-;_-* &quot;-&quot;??\\ &quot;{!@#}&quot;_-;_-@_-"/>'+
'  </Style>'+
'  <Style ss:ID="ss20" ss:Name="Percent2">'+
'   <NumberFormat ss:Format="0%"/>'+
'  </Style>'+
'  <Style ss:ID="ss99">'+
'   <Interior/>'+
'  </Style>'+
'  <Style ss:ID="ss100">'+
'   <Alignment ss:Horizontal="Center" ss:Vertical="Bottom"/>'+
'   <Interior/>'+
'  </Style>'+
'  <Style ss:ID="ss101">'+
'   <Alignment ss:Horizontal="Left" ss:Vertical="Bottom" ss:Indent="1"/>'+
'   <Interior/>'+
'  </Style>'+
'  <Style ss:ID="ss102">'+
'   <Interior/>'+
'   <NumberFormat ss:Format="#,##0"/>'+
'  </Style>'+
'  <Style ss:ID="ss103" ss:Parent="ss20">'+
'   <Alignment ss:Horizontal="Center" ss:Vertical="Bottom"/>'+
'   <Font ss:FontName="Arial"/>'+
'   <Interior/>'+
'   <NumberFormat ss:Format="Percent"/>'+
'  </Style>'+
'  <Style ss:ID="ss144">'+
'   <Alignment ss:Horizontal="Left" ss:Vertical="Bottom" ss:Indent="1"/>'+
'   <Borders>'+
'    <Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="2"/>'+
'    <Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1"/>'+
'    <Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1"/>'+
'    <Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="1"/>'+
'   </Borders>'+
'   <Font ss:FontName="Arial" x:Family="Swiss" ss:Bold="1"/>'+
'   <Interior/>'+
'  </Style>'+
'  <Style ss:ID="ss145">'+
'   <Alignment ss:Horizontal="Left" ss:Vertical="Bottom" ss:Indent="1"/>'+
'   <Borders>'+
'    <Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="2"/>'+
'    <Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1"/>'+
'    <Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1"/>'+
'    <Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="1"/>'+
'   </Borders>'+
'   <Font ss:FontName="Arial" x:Family="Swiss" ss:Bold="1"/>'+
'   <Interior/>'+
'   <NumberFormat ss:Format="[ENG][$-409]d\\-mmm\\-yy;@"/>'+
'  </Style>'+
'  <Style ss:ID="ss146">'+
'   <Alignment ss:Horizontal="Center" ss:Vertical="Bottom"/>'+
'   <Borders>'+
'    <Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="2"/>'+
'    <Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1"/>'+
'    <Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1"/>'+
'    <Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="1"/>'+
'   </Borders>'+
'   <Font ss:FontName="Arial" x:Family="Swiss" ss:Bold="1"/>'+
'   <Interior/>'+
'   <NumberFormat ss:Format="[ENG][$-409]d\\-mmm\\-yy;@"/>'+
'  </Style>'+
'  <Style ss:ID="ss147">'+
'   <Alignment ss:Horizontal="Center" ss:Vertical="Bottom"/>'+
'   <Borders>'+
'    <Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="2"/>'+
'    <Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1"/>'+
'    <Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1"/>'+
'    <Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="1"/>'+
'   </Borders>'+
'   <Font ss:FontName="Arial" x:Family="Swiss" ss:Bold="1"/>'+
'   <Interior/>'+
'   <NumberFormat ss:Format="mmm\\-yy"/>'+
'  </Style>'+
'  <Style ss:ID="ss148">'+
'   <Borders>'+
'    <Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="2"/>'+
'    <Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1"/>'+
'    <Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1"/>'+
'    <Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="1"/>'+
'   </Borders>'+
'   <Font ss:FontName="Arial" x:Family="Swiss" ss:Bold="1"/>'+
'   <Interior/>'+
'   <NumberFormat'+
'    ss:Format="_-* #,##0.00\\ &quot;{!@#}&quot;_-;\\-* #,##0.00\\ &quot;{!@#}&quot;_-;_-* &quot;-&quot;??\\ &quot;{!@#}&quot;_-;_-@_-"/>'+
'  </Style>'+
'  <Style ss:ID="ss149" ss:Parent="ss18">'+
'   <Alignment ss:Horizontal="Center" ss:Vertical="Bottom"/>'+
'   <Borders>'+
'    <Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="2"/>'+
'    <Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1"/>'+
'    <Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1"/>'+
'    <Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="1"/>'+
'   </Borders>'+
'   <Font ss:FontName="Arial" x:Family="Swiss" ss:Bold="1"/>'+
'   <Interior/>'+
'   <NumberFormat/>'+
'  </Style>'+
'  <Style ss:ID="ss150" ss:Parent="ss16">'+
'   <Borders>'+
'    <Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="2"/>'+
'    <Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1"/>'+
'    <Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1"/>'+
'    <Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="1"/>'+
'   </Borders>'+
'   <Font ss:FontName="Arial" x:Family="Swiss" ss:Color="#000000" ss:Bold="1"/>'+
'   <Interior/>'+
'   <NumberFormat'+
'    ss:Format="_-* #,##0.00\\ &quot;{!@#}&quot;_-;\\-* #,##0.00\\ &quot;{!@#}&quot;_-;_-* &quot;-&quot;??\\ &quot;{!@#}&quot;_-;_-@_-"/>'+
'  </Style>'+
'  <Style ss:ID="ss151">'+
'   <Borders>'+
'    <Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="2"/>'+
'    <Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1"/>'+
'    <Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1"/>'+
'    <Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="1"/>'+
'   </Borders>'+
'   <Font ss:FontName="Arial" x:Family="Swiss" ss:Bold="1"/>'+
'   <Interior/>'+
'   <NumberFormat ss:Format="_(* #,##0_);_(* \\(#,##0\\);_(* &quot;-&quot;??_);_(@_)"/>'+
'  </Style>'+
'  <Style ss:ID="ss152">'+
'   <Borders>'+
'    <Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="2"/>'+
'    <Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1"/>'+
'    <Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1"/>'+
'    <Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="1"/>'+
'   </Borders>'+
'   <Font ss:FontName="Arial" x:Family="Swiss" ss:Bold="1"/>'+
'   <Interior/>'+
'   <NumberFormat ss:Format="#,##0"/>'+
'  </Style>'+
'  <Style ss:ID="ss153" ss:Parent="ss20">'+
'   <Borders>'+
'    <Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="2"/>'+
'    <Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1"/>'+
'    <Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1"/>'+
'    <Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="1"/>'+
'   </Borders>'+
'   <Font ss:FontName="Arial" x:Family="Swiss" ss:Bold="1"/>'+
'   <Interior/>'+
'   <NumberFormat ss:Format="#,##0"/>'+
'  </Style>'+
'  <Style ss:ID="ss154" ss:Parent="ss16">'+
'   <Borders>'+
'    <Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="2"/>'+
'    <Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1"/>'+
'    <Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1"/>'+
'    <Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="1"/>'+
'   </Borders>'+
'   <Font ss:FontName="Arial" x:Family="Swiss" ss:Color="#000000" ss:Bold="1"/>'+
'   <Interior/>'+
'   <NumberFormat ss:Format="Percent"/>'+
'  </Style>'+
'  <Style ss:ID="ss155" ss:Parent="ss20">'+
'   <Borders>'+
'    <Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="2"/>'+
'    <Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1"/>'+
'    <Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1"/>'+
'    <Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="1"/>'+
'   </Borders>'+
'   <Font ss:FontName="Arial" x:Family="Swiss" ss:Bold="1"/>'+
'   <Interior/>'+
'   <NumberFormat ss:Format="0"/>'+
'  </Style>'+
'  <Style ss:ID="ss156">'+
'   <Alignment ss:Horizontal="Left" ss:Vertical="Bottom"/>'+
'   <Borders>'+
'    <Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="2"/>'+
'    <Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1"/>'+
'    <Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1"/>'+
'    <Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="1"/>'+
'   </Borders>'+
'   <Font ss:FontName="Arial" x:Family="Swiss" ss:Bold="1"/>'+
'   <Interior/>'+
'  </Style>'+
                ' </Styles>'+
                ' <Worksheet ss:Name="'+System.Label.excel_sheet_summary+'">'+
                '  <Table x:FullColumns="1" x:FullRows="1" ss:DefaultColumnWidth="120">'+
                '   <Column ss:AutoFitWidth="0" ss:Width="25"/>'+
                '   <Column ss:Width="188"/>'+
                '   <Column ss:Width="376"/>'+
                '   <Column ss:Width="68.25"/>'+
                '   <Column ss:Width="64.5"/>'+
                '   <Column ss:Width="83.25"/>'+
                '   <Column ss:Width="117"/>'+
                '   <Column ss:Width="95.25"/>'+
                '   <Column ss:Width="90.75"/>'+
                '   <Column ss:Width="99.75"/>'+
                '   <Column ss:Width="84.75"/>'+
                '   <Column ss:Width="111.75"/>'+
                '   <Column ss:Width="81.75"/>'+
                '   <Column ss:Width="53.25"/>'+
                '   <Column ss:Width="78"/>'+
                '   <Row ss:AutoFitHeight="0" ss:Height="59.25"><Cell ss:Index="2" ss:StyleID="s25"><Data ss:Type="String"></Data></Cell></Row>'+
                '    '+
                '   <Row>'+
                '    <Cell ss:Index="2" ss:StyleID="s25"><Data ss:Type="String">'+System.Label.excel_header_date+'</Data></Cell>'+
                '    <Cell ss:StyleID="DateWithoutBorder"><Data ss:Type="DateTime">{!date}</Data></Cell>'+
                '   </Row>'+
                '   <Row>'+
                '    <Cell ss:Index="2" ss:StyleID="s25"><Data ss:Type="String">'+System.Label.excel_header_campaign+'</Data></Cell>'+
                '    <Cell ss:StyleID="s75"><Data ss:Type="String">{!campaign}</Data></Cell>'+
                '   </Row>'+
                '   <Row>'+
                '    <Cell ss:Index="2" ss:StyleID="s25"><Data ss:Type="String">'+System.Label.excel_header_accname+'</Data></Cell>'+
                '    <Cell ss:StyleID="s75"><Data ss:Type="String">{!accname}</Data></Cell>'+
                '   </Row>'+
                '   <Row>'+ 
                '    <Cell ss:Index="2" ss:StyleID="s25"><Data ss:Type="String">'+System.Label.excel_header_agency+'</Data></Cell>'+
                '    <Cell ss:StyleID="s27"><Data ss:Type="String">{!agency}</Data></Cell>'+
                '   </Row>'+
                '   <Row>'+
                '    <Cell ss:Index="2" ss:StyleID="s25"><Data ss:Type="String">'+System.Label.excel_header_sale+'</Data></Cell>'+
                '    <Cell ss:StyleID="s27"><Data ss:Type="String">{!sale}</Data></Cell>'+
                '   </Row>'+
                '   <Row>'+
                '    <Cell ss:Index="2" ss:StyleID="s25"><Data ss:Type="String">'+System.Label.excel_header_start_campaign+'</Data></Cell>'+
                '    <Cell ss:StyleID="DateWithoutBorder"><Data ss:Type="DateTime">{!start}</Data></Cell>'+
                '   </Row>'+
                '   <Row>'+
                '    <Cell ss:Index="2" ss:StyleID="s25"><Data ss:Type="String">'+System.Label.excel_header_end_campaign+'</Data></Cell>'+
                '    <Cell ss:StyleID="DateWithoutBorder"><Data ss:Type="DateTime">{!end}</Data></Cell>'+
                '   </Row>'+
                '   <Row>'+
                '    <Cell ss:Index="2" ss:StyleID="s25"><Data ss:Type="String">'+System.Label.excel_header_offer_number+'</Data></Cell>'+
                '    <Cell ss:StyleID="s34"><Data ss:Type="String">{!offernum}</Data></Cell>'+
                '   </Row>'+
                '   <Row/>'+
                '   <Row/>'+
                '   <Row/>'+
                '   <Row/>'+
                '   <Row ss:Height="13.5">'+
                '    <Cell/>'+
                '    <Cell><Data ss:Type="String">{!ColumnHeader}</Data></Cell>'+
                '   </Row>'+
                '   <Row><Cell><Data ss:Type="String">{!rows}</Data></Cell></Row>'+
                '   <Row/>'+
                '   <Row>'+
                '    <Cell ss:Index="2" ss:StyleID="s38"><Data ss:Type="String">'+System.Label.excel_note+'</Data></Cell>'+
                '   </Row>'+
                '  </Table>'+
                '  <WorksheetOptions xmlns="urn:schemas-microsoft-com:office:excel">'+
                '   <Print>'+
                '    <ValidPrinterInfo/>'+
                '    <HorizontalResolution>300</HorizontalResolution>'+
                '    <VerticalResolution>300</VerticalResolution>'+
                '   </Print>'+
                '   <Selected/>'+
                '   <DoNotDisplayGridlines/>'+
                '   <Panes>'+
                '    <Pane>'+
                '     <Number>3</Number>'+
                '     <ActiveRow>16</ActiveRow>'+
                '     <ActiveCol>12</ActiveCol>'+
                '    </Pane>'+
                '   </Panes>'+
                '   <ProtectObjects>False</ProtectObjects>'+
                '   <ProtectScenarios>False</ProtectScenarios>'+
                '  </WorksheetOptions>'+
                ' </Worksheet>'+
                ' <Worksheet ss:Name="'+System.Label.excel_sheet_detail+'">'+
                '  <Table x:FullColumns="1" x:FullRows="1" ss:DefaultColumnWidth="60">'+
                '   <Column ss:AutoFitWidth="0" ss:Width="25"/>'+
                '   <Column ss:Width="106.5"/>'+
                '   <Column ss:Width="188.00"/>'+
                '   <Column ss:Width="376.00"/>'+
                '   <Column ss:Width="60.75"/>'+
                '   <Column ss:Width="81.75"/>'+
                '   <Column ss:Width="120"/>'+
                '   <Column ss:Width="81.75"/>'+
                '   <Column ss:Width="53.25"/>'+
                '   <Column ss:Width="67.5"/>'+
                '   <Row/>'+
                '   <Row/>'+
                '   <Row/>'+
                '   <Row ss:Height="26.25" ss:StyleID="s83">'+
                '    <Cell/>'+   
                '    <Cell><Data ss:Type="String">{!ColumnHeaderDetail}</Data></Cell>'+ 
                '   </Row>'+
                '   <Row><Cell><Data ss:Type="String">{!rowsDetail}</Data></Cell></Row>'+ 
                '  </Table>'+
                '  <WorksheetOptions xmlns="urn:schemas-microsoft-com:office:excel">'+
                '   <PageSetup>'+
                '    <Header x:Margin="0.3"/>'+
                '    <Footer x:Margin="0.3"/>'+
                '    <PageMargins x:Bottom="0.78740157499999996" x:Left="0.7" x:Right="0.7"'+
                '     x:Top="0.78740157499999996"/>'+
                '   </PageSetup>'+
                '   <Zoom>85</Zoom>'+
                '   <DoNotDisplayGridlines/>'+
                '   <Panes>'+
                '    <Pane>'+
                '     <Number>3</Number>'+
                '     <ActiveRow>10</ActiveRow>'+
                '     <ActiveCol>2</ActiveCol>'+
                '    </Pane>'+
                '   </Panes>'+
                '   <ProtectObjects>False</ProtectObjects>'+
                '   <ProtectScenarios>False</ProtectScenarios>'+
                '  </WorksheetOptions>'+
                ' </Worksheet>'+
                '</Workbook>';
                
                
}