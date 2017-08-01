calendar.js
============

Functions inspired by the calendar module from the Python standard library.

The `monthDates` function builds an array of weeks to display one month,
starting on Sunday (default) or Monday. Each week is an array of seven Date
instances, including dates from the month before or after, as needed to fill
the first and last weeks. An optional formatting function may be passed as
third argument.

The `monthDays` function calls `monthDates` passing a simple function which
returns the day number from a date, or zero if the date does not belong to the
month.

    > cMon = new Calendar(1); // weeks starts on Monday
    > mdc = cMon.monthDays(2012, 1);
    > for (i=0; i<mdc.length; i++) console.log(mdc[i]);
    [0, 0, 1, 2, 3, 4, 5]
    [6, 7, 8, 9, 10, 11, 12]
    [13, 14, 15, 16, 17, 18, 19]
    [20, 21, 22, 23, 24, 25, 26]
    [27, 28, 29, 0, 0, 0, 0]
