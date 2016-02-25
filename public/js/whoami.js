var whoami = '';
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
