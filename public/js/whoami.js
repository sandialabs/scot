var searchboxtext = false
var whoami = '';
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
var entityPopUpHeight = '';
var entityPopUpWidth = '';
var amqdebug = false;
$.ajax({
    type: 'get',
    url:'scot/api/v2/whoami',
    success: function(result) {
        whoami=result.user;
    },
    error: function() {
        alert('Failed to detect user, please authenticate');
    }
});
