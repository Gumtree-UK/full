/*
 * CalendarWeek:
 *  This class provides following methodes:
 *  - get the ISO week number, date.
 *
 * Author:
 *  Benhui.Chen@avendio.de
 */
public class CalendarWeek {

  // DayOfYearNumber
    private static final Map<Integer, Integer> DayOfYearNumber = new Map<Integer, Integer> { 
    1 =>   0, 2 =>  31, 3 =>  59,  4 =>  90,  5 => 120,  6 => 151,
    7 => 181, 8 => 212, 9 => 243, 10 => 273, 11 => 304, 12 => 334 
    };

  // Constructor.
    private CalendarWeek() {
    }
        
    // Get ISO Week Number of a given day.
  public static Integer getISOWeekNumber(Date d) {
    Map<String, Integer> ywd = getYearWeekDate(d);
    return ywd.get('Week');  
  }
  
    // Get ISO Week Date of a given day.
  public static String getISOWeekDate(Date d) {
    Map<String, Integer> ywd = getYearWeekDate(d);
    
    String res = String.valueOf(ywd.get('Year'));
    
    if (ywd.get('Week') < 10) {
      res += '-W0' + String.valueOf(ywd.get('Week'));
    } else {
      res += '-W' + String.valueOf(ywd.get('Week'));
    }
    
    res += '-' + String.valueOf(ywd.get('Day'));
    
    return res;  
  }

  private static Map<String, Integer> getYearWeekDate(Date d) {
    Map<String, Integer> ywd = new Map<String, Integer>();
    
      Integer yearNumber = d.year();
      Integer weekNumber = 0;
      Integer dayNumber  = 1;

      Integer year  = d.year();  
      Integer month = d.month(); // 1 == Jan.
      Integer day   = d.day(); 
      
      // DayOfYear.
      /*
      Integer doy = day + DayOfYearNumber.get(month);
      if (Date.isLeapYear(year) && month > 2) {
        doy += 1;
      }
      */
      Integer doy = d.dayOfYear();
      
      // Find the week day of the begin of the year.      
      Integer YY        = Math.mod((year - 1), 100);
      Integer C         = (year - 1) - YY;
      Integer G         = YY + YY / 4;
      Integer dowOffset = 1 + Math.mod(((Math.mod((C / 100), 4) * 5) + G), 7);
      
      // Find the week day of given date.
      Integer H = doy + (dowOffset - 1);
      dayNumber = 1 + Math.mod((H - 1), 7);
      
      // Find if given date falls in last year, WeekNumber 52 or 53
      if (doy <= (8 - dowOffset) && dowOffset > 4) {
        yearNumber = year - 1;
        if (dowOffset == 5 || (dowOffset == 6 && Date.isLeapYear(year-1))) {
               weekNumber = 53;
        } else { 
               weekNumber = 52;
        }
      }

    // Find if given date falls in next year, WeekNumber 1
    if (yearNumber == year) {
      Integer I = 365;
      if (Date.isLeapYear(year)) {
        I += 1;
      }
      if ((I - doy) < (4 - dayNumber)) {
        yearNumber = year + 1;
        weekNumber = 1;
      }
    }
    
    // Find if given date in year, WeekNumber 1 through 53
    if (yearNumber == year) {
      Integer J = doy + (7 - dayNumber) + (dowOffset - 1);
      weekNumber = J / 7;
      if (dowOffset > 4) {
        weekNumber -= 1;
      }
    }
      
      ywd.put('Year', yearNumber);
      ywd.put('Week', weekNumber);
      ywd.put('Day',  dayNumber);

      return ywd;
  }
    
  
  // Test Method
  static testMethod void myTest() {
    Date d1 = Date.today();
    getISOWeekNumber(d1);
    System.debug('\nISO Week Date of date ' + String.valueOf(d1) + ' is ' + getISOWeekDate(d1));
              
    Date d2 = Date.newInstance(2010, 1, 1);
    getISOWeekNumber(d2);    
    System.debug('\nISO Week Date of date ' + String.valueOf(d2) + ' is ' + getISOWeekDate(d2));

    Date d3 = Date.newInstance(2010, 12, 31);
    getISOWeekNumber(d3);    
    System.debug('\nISO Week Date of date ' + String.valueOf(d3) + ' is ' + getISOWeekDate(d3));

    Date d4 = Date.newInstance(2011, 1, 1);
    getISOWeekNumber(d4);    
    System.debug('\nISO Week Date of date ' + String.valueOf(d4) + ' is ' + getISOWeekDate(d4));
  }
  
}