#!/usr/bin/env node

var Calendar = require('../').Calendar
  , cal = new Calendar()
  , month = "";

if (process.argv.length === 4) {
    // Arguments are month and year, as in cal
    // January is month 1 for the user, but 0 in JavaScript Date objects
    month = cal.monthText(parseInt(process.argv[3]),
                          parseInt(process.argv[2])-1);
} else {
    month = cal.monthText();
}

console.log(month);
