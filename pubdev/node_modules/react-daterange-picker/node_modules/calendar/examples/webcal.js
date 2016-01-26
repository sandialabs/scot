#!/usr/bin/env node

var http = require('http')
  , Calendar = require('../').Calendar
  , cal = new Calendar()
  ;

var monthHTML = function monthHTML(year, month) {
    if (typeof year === "undefined") {
        var now = new Date();
        year = now.getFullYear();
        month = now.getMonth();
    };
    var getDayOrBlank = function getDayOrBlank(date) {
        return date.getMonth() === month ? date.getDate().toString() : "&nbsp;";
    };
    var weeks = cal.monthDates(year, month, getDayOrBlank,
        function (week) { return week.join("</td><td>") });
    return '<tr><td>'+weeks.join('</td></tr>\n<tr><td>')+'</td></tr>';
}

var page = function page(req, res) {
  res.writeHead(200, {'Content-Type': 'text/html'});
  res.end('<table style="text-align: center; border:2px solid #aaa;">'
    + monthHTML() + '</table>');
}

http.createServer(page).listen(1337, "127.0.0.1");
console.log('Calendar server running at http://127.0.0.1:1337/');
