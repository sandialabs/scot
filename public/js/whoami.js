var searchboxtext = ''
var whoami = '';
var activemqwho = ''
var activemqid = ''
var activemqmessage = ''
var activemqtype = ''
var alertgroupforentity = false
var activemqstate = ''
var activemqsetentry = 0
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
