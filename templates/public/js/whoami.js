var searchboxtext = false
var whoami = '';
var sensitivity = ''; 
var activemqwho = ''
var activemqid = ''
var activemqmessage = ''
var activemqtype = ''
var activemqaction = ''
var activemqguid = ''
var activemqhostname = ''
var activemqpid = ''
var alertgroupforentity = false
var activemqstate = ''
var activemqsetentry = 0
var activemqsetentrytype = '';
var activemqwall;
var activemqwhen;
var entityPopUpHeight = '';
var entityPopUpWidth = '';
var changeKey;
var amqdebug = false;
$.ajax({
    type: 'get',
    url:'/scot/api/v2/whoami',
    success: function(result) {
        whoami=result.user;
        if (result.data != undefined) {
            if (result.data.sensitivity != undefined) {
                sensitivity=result.data.sensitivity;
            }
        }
    },
    error: function() {
        alert('Failed to detect user, please authenticate');
    }
});
