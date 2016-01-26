var jan_1_2012 = new Date(2012,Calendar.JAN,1);

test('January 1, 2012 is Sunday', function() {
    var calSun = new Calendar(); // calendar with Sunday as first day of the week
    equal(jan_1_2012.toISOString().slice(0,10), '2012-01-01', 'month 0 is January');
    equal(jan_1_2012.getDay(), 0, 'weekday 0 is Sunday');
});
test('weekStartDate, Sunday', function() {
    var calSun = new Calendar(); // calendar with Sunday as first day of the week
    deepEqual(calSun.weekStartDate(jan_1_2012), jan_1_2012, 'Jan. 1st 2012 is the start of a week');
    deepEqual(calSun.weekStartDate(new Date(2012,0,2)), jan_1_2012, 'first week of 2012 starts on Jan. 1st');
    deepEqual(calSun.weekStartDate(new Date(2012,0,7)), jan_1_2012, 'first week of 2012 starts on Jan. 1st');
    deepEqual(calSun.weekStartDate(new Date(2012,0,8)), new Date(2012,0,8), 'second week of 2012 starts on Jan. 8th');
    deepEqual(calSun.weekStartDate(new Date(2012,0,10)), new Date(2012,0,8), 'second week of 2012 starts on Jan. 8th');
});
test('weekStartDate, Monday', function() {
    var calMon = new Calendar(1); // calendar with Monday as first day of the week
    deepEqual(calMon.weekStartDate(jan_1_2012), new Date(2011,11,26),
        'December. 26th 2011 is the start of the first week of 2012');
    deepEqual(calMon.weekStartDate(new Date(2012,0,2)), new Date(2012,0,2),
        'second week of 2012 starts on Jan. 2nd');
    deepEqual(calMon.weekStartDate(new Date(2012,0,8)), new Date(2012,0,2),
        'second week of 2012 starts on Jan. 2nd');
    deepEqual(calMon.weekStartDate(new Date(2012,0,9)), new Date(2012,0,9),
        'third week of 2012 starts on Jan. 9th');
});
test('monthDates, Sunday', function() {
    var calSun = new Calendar(); // calendar with Sunday as first day of the week
    var mdc_jan_2012 = calSun.monthDates(2012,0);
    var mdc_feb_2012 = calSun.monthDates(2012,1);
    equal(mdc_jan_2012.length, 5, 'January 2012 spans 5 calendar weeks');
    equal(mdc_feb_2012.length, 5, 'February 2012 spans 5 calendar weeks');
    deepEqual(mdc_jan_2012[0][0], jan_1_2012, 'first Sunday is Jan. 1st. = '+mdc_jan_2012[0][0]);
    deepEqual(mdc_jan_2012[1][0], new Date(2012,0,8), 'second Sunday is Jan. 8th.');
    deepEqual(mdc_jan_2012[mdc_jan_2012.length-1][6], new Date(2012,1,4), 'last Saturday Feb. 4th.');
    deepEqual(mdc_feb_2012[mdc_feb_2012.length-1][6], new Date(2012,2,3), 'last Saturday Mar. 3rd. ='+mdc_feb_2012[4][6]);
});
test('monthDates, Monday', function() {
    var calMon = new Calendar(1); // calendar with Monday as first day of the week
    var mdc_jan_2012 = calMon.monthDates(2012,0);
    var mdc_feb_2012 = calMon.monthDates(2012,1);
    equal(mdc_jan_2012.length, 6, 'January 2012 spans 6 calendar weeks');
    equal(mdc_feb_2012.length, 5, 'February 2012 spans 5 calendar weeks');
    deepEqual(mdc_jan_2012[0][0], new Date(2011,11,26), 'first Monday is Dec. 26th. = '+mdc_jan_2012[0][0]);
    deepEqual(mdc_jan_2012[1][0], new Date(2012,0,2), 'second Monday is Jan. 2nd.');
    deepEqual(mdc_jan_2012[mdc_jan_2012.length-1][6], new Date(2012,1,5), 'last Sunday Feb. 5th.');
    deepEqual(mdc_feb_2012[mdc_feb_2012.length-1][6], new Date(2012,2,4), 'last Sunday Mar. 4th. ='+mdc_feb_2012[4][6]);
});
test('monthDays, Sunday', function() {
    var calSun = new Calendar(); // calendar with Sunday as first day of the week
    var mdc_jan_2012 = calSun.monthDays(2012,0);
    var mdc_feb_2012 = calSun.monthDays(2012,1);
    equal(mdc_jan_2012.length, 5, 'January 2012 spans 5 calendar weeks');
    deepEqual(mdc_jan_2012[0], [1,2,3,4,5,6,7], 'first week is Jan. 1st to 7th');
    deepEqual(mdc_jan_2012[4], [29,30,31,0,0,0,0], 'last week is Jan. 29th to Feb 4th');
    deepEqual(mdc_feb_2012[0], [0,0,0,1,2,3,4,], 'first week is Jan. 29th to Feb 4th');
});
test('monthText, Sunday', function() {
    var calSun = new Calendar(); // calendar with Sunday as first day of the week
    equal(calSun.monthText(2012,1), ["          1  2  3  4",
                                     " 5  6  7  8  9 10 11",
                                     "12 13 14 15 16 17 18",
                                     "19 20 21 22 23 24 25",
                                     "26 27 28 29         "].join("\n"));
});