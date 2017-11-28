
function add_permitted_sender() {
	$('#permitted_senders').append('<tr><td><button onclick="save_permitted_sender(this)" type="button" class="sender_btn">Save</button></td><td><input type="text" name="permitted_user" placeholder="Username (optional)" style="width:172px;"></input></td><td>@</td><td><input type="text" name="permitted_domain" style="width:120px;" placeholder="Example.com"></input></td></tr>');
}

function render_permitted_sender(username, domain) {
	var row = $('<tr><td><button  class="sender_btn btn" type="button"><img src="/images/remove.png"></img></button></td></tr>');
	var user = $('<td style="text-align:right;"></td>').text(username);
	var domain = $('<td style="text-align:left;"></td>').text(domain);
	$(row).append(user);
	$(row).append('<td>@</td>');
	$(row).append(domain);
	return row; 
}

function save_permitted_sender(save_btn) {
	var tr  = $(save_btn).closest('tr');
	var inputs = tr.find('input');
	var username = inputs.first().val();
	var domain = inputs.last().val();
	console.log('adding new permitted sender ' + username + ':' + domain);
	var row = render_permitted_sender(username, domain);
	$('#permitted_senders').append(row); 
	$(tr).remove();
}

function format_epoch(epoch_int) {
	var dt = new Date(0);
	dt.setUTCSeconds(epoch_int);
	return dt;
}

function formatAMPM(date) {
	var hours = date.getHours();
	var minutes = date.getMinutes();
	var seconds = date.getSeconds();
	var ampm = hours >= 12 ? 'pm' : 'am';
	hours = hours % 12;
	hours = hours ? hours : 12; // the hour '0' should be '12'
	minutes = minutes < 10 ? '0' + minutes : minutes;
	seconds = seconds < 10 ? '0' + seconds : seconds;
	var strTime = hours + ':' + minutes + ':' + seconds + ' ' + ampm;
	return strTime;
}

function fullDateFormat(dateObject) {
	return (dateObject.getMonth() + 1) + '/' + dateObject.getDate() + '/' + dateObject.getFullYear() + ' ' + formatAMPM(dateObject);
}


function restore_confirm() {
	$('#restore_btn').find('img').remove();
	$('#restore_btn').prop('disabled', true).append('<img src="./loading.gif" style="width:20px;"></img>');
	var fd = new FormData();
	fd.append("upload", document.getElementById('restore_file').files[0]);
	$('#progress_restoring').show();
	var xhr = new XMLHttpRequest();
	xhr.upload.addEventListener("progress", restoreUploadProgress, false);
	xhr.addEventListener("load", restoreUploadComplete, false);
	xhr.addEventListener("error", restoreUploadFailed, false);
	xhr.addEventListener("abort", restoreUploadCanceled, false);
	xhr.open("POST", "/scot/admin/restore");
	xhr.send(fd);
}

function ldap_to_json() {
	var data = new Object();
	var form = $('#ldap_form');
	data.ldap_type    = $(form).find('select[name="ldap_type"] :selected').val();
	data.host         = $(form).find('input[name="host"]').val();
	data.port         = $(form).find('input[name="port"]').val();
	data.basedn       = $(form).find('input[name="basedn"]').val();
	data.uid          = $(form).find('input[name="uid"]').val();
	data.binddn       = $(form).find('input[name="binddn"]').val();
	data.bindpassword = $(form).find('input[name="bindpassword"]').val(); 
	data.membership   = $(form).find('input[name="attr"]').val();
	data.user_to_test = $(form).find('input[name="testuser"]').val();
	return data;
}

function test_ldap() {
	var data = ldap_to_json(); 
	$.ajax({
		type: "POST",
		url:  "/scot/admin/auth/ldap/test",
		data: JSON.stringify(data)
	}).done(function(response) {
		if(response.status == 'success') {
			$('#test_ldap_btn').hide();
			$('#save_ldap_btn').css('display', 'block');
		} else {
			alert("Error:"+response.error);
		}
	}).error(function(response) {
		alert('Unable to test LDAP settings, please try again');
	});
}

function save_ldap() {
	var data = ldap_to_json();
	$.ajax({
		type: "POST",
		url:  "/scot/admin/auth/ldap",
		data: JSON.stringify(data)
	}).done(function(response) {
		alert('Settings successfully saved');
	}).error(function(response) {
		alert('Unable to save LDAP settings');
	});
}

function update_confirm() {
	var fd = new FormData();
	fd.append("upload", document.getElementById('update_file').files[0]);
	$('#progress_uploading').show();
	var xhr = new XMLHttpRequest();
	xhr.upload.addEventListener("progress", updateUploadProgress, false);
	xhr.addEventListener("load", updateUploadComplete, false);
	xhr.addEventListener("error", updateUploadFailed, false);
	xhr.addEventListener("abort", updateUploadCanceled, false);
	xhr.open("POST", "/scot/admin/update");
	xhr.send(fd);
}

function restoreUploadProgress(evt) {
	if (evt.lengthComputable) {
		var percentComplete = Math.round(evt.loaded * 100 / evt.total);
		document.getElementById('restoreProgressNumber').innerHTML = percentComplete.toString() + '%';
		$('#restoreProgressbar').progressbar({value: percentComplete});
	}
	else {
		document.getElementById('restoreProgressNumber').innerHTML = 'unable to compute';
	}
}

function restoreUploadComplete(evt) {
	/* This event is raised when the server send back a response */
	$('#progress_restoring').hide();
	var response = JSON.parse(evt.target.responseText); 
	if(response.status != 'ok') {
		alert('Error uploading SCOT restore bundle');
		$('#restore_btn').find('img').attr('src', '/images/close_toolbar.png');
	} else {
		alert('Restore Complete');
	}
	$('#restore_btn').prop('disabled', false);
	$('#restore_btn').find('img').remove();
}

function restoreUploadFailed(evt) {
	alert("There was an error attempting to upload the file.");
	$('#restore_btn').prop('disabled', false);
	$('#restore_btn').find('img').attr('src', '/images/close_toolbar.png');
}

function restoreUploadCanceled(evt) {
	alert("The upload has been canceled by the user or the browser dropped the connection.");
	$('#restore_btn').prop('disabled', false);
	$('#restore_btn').find('img').attr('src', '/images/close_toolbar.png');
}


function updateUploadProgress(evt) {
	if (evt.lengthComputable) {
		var percentComplete = Math.round(evt.loaded * 100 / evt.total);
		document.getElementById('progressNumber').innerHTML = percentComplete.toString() + '%';
		$('#updateProgressbar').progressbar({value: percentComplete});
	}
	else {
		document.getElementById('progressNumber').innerHTML = 'unable to compute';
	}
}

function updateUploadComplete(evt) {
	/* This event is raised when the server send back a response */
	$('#progress_uploading').hide();
	var response = evt.target.responseText;
	if(response.status != 'ok') {
		alert('Error uploading SCOT Update');
	} else {
		alert('Upload Sucessfull, update in progress...');
	}
}

function updateUploadFailed(evt) {
	alert("There was an error attempting to upload the file.");
}

function updateUyploadCanceled(evt) {
	alert("The upload has been canceled by the user or the browser dropped the connection.");
}


Date.prototype.timeNow = function(){     return ((this.getHours() < 10)?"0":"") + ((this.getHours()>12)?(this.getHours()-12):this.getHours()) +":"+ ((this.getMinutes() < 10)?"0":"") + this.getMinutes() +":"+ ((this.getSeconds() < 10)?"0":"") + this.getSeconds() + ((this.getHours()>12)?('PM'):'AM'); }



function offline_update() {
	$('#offline_upload_input').slideToggle();

}

function group_modal(groupname, group_members, all_users, group_type, id, description) {
	$('.loading').remove();
	$('#group_modal').find('input[name=id]').val(id);
	$('#group_modal').find('input[name=groupname]').val(groupname);
	$('#group_modal').find('input[name=description]').val(description);
	$('#users option').remove();
	$('#all_users option').remove();
	var group_members_by_user = new Array();
	$(group_members).each(function(user_index, user) {
		var fullname = user.fullname;
		var username = user.username;
		var userid   = user.userid;
		var user_option = $('<option></option>').val(username).text(username).attr('name', 'users').attr('id',userid);
		$('#users').append(user_option);
		group_members_by_user.push(username);
	});
	for (i=0; i < all_users.length; i++) {
		// $(Object.keys(all_users)).each(function(user_index, username) {
		if($.inArray(all_users[i].username, group_members_by_user) < 0) {
			var fullname = all_users[i].fullname;
			var user_option = $('<option></option>').val(all_users[i].username).text(all_users[i].username).attr('name', 'all_users').attr('id',all_users[i].id);
			$('#all_users').append(user_option);
		}
		//});
	}
	$('#users option:selected').removeAttr("selected");
	$('#group_modal').data('group_type', group_type);
	$('#group_label').text(group_type + ' Group');
	$('#group_modal').modal('show'); 
}

function user_modal(username, fullname, active, locked, user_groups, all_groups, user_type, id) {
	$('.loading').remove();
	$('#user_modal').find('input[name=id]').val(id);
	$('#user_modal').find('input[name=fullname]').val(fullname);
	$('#user_modal').find('input[name=username]').val(username);
	$('#user_modal').find('input[type=password]').val('');
	$('#user_modal').find('input[name=active]').prop('checked', (active && (!(locked))));
	$('#groups option').remove();
	$('#all_groups option').remove();
	$(user_groups).each(function(group_index, groupname) {
		var group_option = $('<option></option>').val(groupname).text(groupname).attr('name', 'groups');
		$('#groups').append(group_option);
	});
	for (i=0; i < all_groups.length; i++) {
		//$(Object.keys(all_groups)).each(function(group_index, groupname) {
		if($.inArray(all_groups[i].name, user_groups) < 0) {
			var group_option = $('<option></option>').val(all_groups[i].name).text(all_groups[i].name).attr('name', 'all_groups');
			$('#all_groups').append(group_option);
		}
		//});
	}
	if(locked) {
		$('#user_locked').show();
	} else {
		$('#user_locked').hide();
	}
	$('#groups option:selected').removeAttr("selected");
	$('#user_modal').data('user_type', user_type);
	$('#user_label').text(user_type + ' User');
	$('#user_modal').modal('show'); 
}


function populate_local_users_n_groups() {
	var allGroups;
	var users;
	$.ajax({
		type:'GET',
		url: '/scot/api/v2/user',
		data: {limit:0}
	}).done(function(response) {
		//var auth_method = response.data.method;
		var auth_method = 'local';
		if(auth_method == 'local') {
			users = response.records;
			//var groups = response.data.groups;
			$('#users_table').html('<tr><th></th><th></th><th>User</th><th>Full Name</th><th>Active</th></tr>');
			for (i=0; i < users.length; i++) {
				//if(!(users[username].local_acct))
				//   return true;
				var active_img = '/images/close_toolbar.png';
				if(users[i].active != undefined && users[i].active == 1 && ( users[i].lockouts == undefined || (users[i].lockouts == 0) )) {
					active_img = '/images/ok.png';
				}
				var trow = $('<tr class="row"><td><img src="/images/edit.png" style="max-width:inherit;"></img></td><td>'+users[i].username+'</td><td>'+users[i].fullname+'</td><td><img src="'+active_img+'" style="width:15px;"></img></td></tr>');
				var user = users[i];
				$(trow).data('username', users[i].username).click({param1:user}, function(event){
					var active = event.data.param1.active;
					if (active == 1) {active = true} else {active = false}
					user_modal(event.data.param1.username, event.data.param1.fullname, active, (event.data.param1.lockouts > 0), event.data.param1.groups, allGroups, 'Edit', event.data.param1.id);
				});
				$('#users_table').append(trow); 
			}
		}
	});
	$.ajax({
		type:'GET',
		url: '/scot/api/v2/group',
		data: {limit:0}
	}).done(function(response) {
		allGroups = response.records;
		var auth_method = 'local';
		if (auth_method == 'local') {
			//var group = response.records;
			$('#groups_table').html('<tr><th></th><th></th><th>Group</th><th>Description</th></tr>');
			for (j=0; j < response.records.length; j++) {                  
				//var count = groups[groupname].length;
				var description = response.records[j].description;
				var trow = $('<tr class="row"><td><img src="/images/edit.png" style="max-width:inherit;"></img></td><td>'+response.records[j].name+'</td><td>'+description+'</td></tr>');
				var group = response.records[j];
				$(trow).data('groupname', group.name).click({param1:group}, function(event) {
					//var group = groups[j].name;
					var group_users = new Array();
					var groupname = event.data.param1.name;
					$.ajax({
						type:'GET',
						url: '/scot/api/v2/group/' + event.data.param1.id + '/user',
					}).done(function(response){
						for (z=0; z < response.records.length; z++) {
							group_users.push({username : response.records[z].username, fullname: response.records[z].fullname, userid: response.records[z].id});    
						}
						group_modal(groupname, group_users, users, 'Edit', event.data.param1.id, event.data.param1.description);
					})
				});
				$('#groups_table').append(trow);
			}

		}
	})
}

function text2html(text) {
	text = text.replace(/ /g, '&nbsp;');
	text = text.replace(/(?:\r\n|\r|\n)/g, '<br />');
	text = text.replace(/\t/, '&#09;');
	return text;
}

function load_alert_settings() {
	$.ajax({
		type : 'GET',
		url  : '/scot/admin/alerts'
	}).done(function(response) {
		var eo = $('#email_options');
		eo.find('[name="address"]').val(response.email.hostname);
		eo.find('[name="port"]').val(response.email.port);
		eo.find('[name="username"]').val(response.email.username);
		var cb = $('#collector_form').find('[name="email"]');
		cb.prop('checked', 'response.email.active');
		cb.change();
	}).error(function(response) {
		alert("couldn't load current email settings");
	});


}


function check_for_updates() {

	$.ajax({
		type: 'GET',
		url: "https://getscot.sandia.gov/updates/",
		async: false,
		jsonpCallback: 'updates',
		contentType: "application/json",
		dataType: 'jsonp',
		success: function(json) {
			console.dir(json);
		},
		error: function(e) {
			console.log(e.message);
		}
	});
}

$(document).ready(function() {
	//$('#method_tabs').tab();
	populate_local_users_n_groups();
	// $('#method_tabs a:first').tab('show');
	//$('#permitted_senders').append(render_permitted_sender('', '*.*'));
	//  check_for_updates();

});
function hashchange() {
	$('.section').hide();
	var hash = location.hash;
	$('#admin_nav').find('.active').removeClass('active');
	$('#admin_nav').find(hash).addClass('active').parent().addClass('active');
	$(hash).fadeIn({duration:200});
	if(hash == '#auth') {
		//load_ldap_settings();
	} else if (hash == '#alerts') {
		//load_alert_settings();
	}
}

function load_ldap_settings() {
	$.ajax({
		type: 'get',
		url: '/scot/admin/auth/ldap'
	}).done(function(response) {
		var data = response.data;
		$('#ldap_form').find('input[name=host]').val(data.hostname);
		$('#ldap_form').find('input[name=basedn]').val(data.basedn);
		$('#ldap_form').find('input[name=uid]').val(data.uid);
		$('#ldap_form').find('input[name=attr]').val(data.attrs);
		$('#ldap_form').find('input[name=binddn]').val(data.binddn);
	});

}


function delete_backup(backup_id) {
	$.ajax({
		type: 'delete',
		url:  '/scot/admin/backup/'+backup_id
	});

}
$(document).ready(function() {

	$('.comming_soon').html('<h4>Feature coming soon</h4>');
	if(location.hash == '') {
		location.hash = '#info';
	}
	$('#collector_form input:checkbox').change(function() {
		var control_group = $(this).parents('.form-group');
		if($(this).prop('checked')) {

			control_group.find('.options').slideDown();
			control_group.find('.controls').animate({'margin-left': '120px'});
			control_group.find('.control-label').animate({width: '100px'});
		} else {
			control_group.find('.options').slideUp();
			control_group.find('.controls').animate({'margin-left': '180px'});
			control_group.find('.control-label').animate({width: '160px'});
		}
	});
	hashchange();
	window.onhashchange = hashchange; 

	function list_backups(initial) {
		$.ajax({
			type: 'get',
			url:  '/scot/admin/backup/'
		}).done(function(response) {
			if(initial) {
				$('#schedule').val(response.data.cron.schedule);
				$('#max_disk').val(response.data.cron.max_disk);
				$('#enable_backups').prop('checked',response.data.cron.active == 1);
			}	
			$('#backups').html('<div class="row"><span>Delete</span><span>Date</span><span>Size</span><span>Download</span><span>Restore</span></div>');
			$(response.data.files).each(function(backup_idx, backup) {
				$('#backups').append('<div class="row"><span><button class="btn" onclick="delete_backup(\''+backup.id+'\')"><b style="font-family:cursive; margin-left:2px; margin-right:2px; font-size:10pt;">X</b></button></span><span>'+fullDateFormat(format_epoch(backup.created_epoch))+'</span><span>'+backup.size_human+'</span><span><a href="/scot/admin/backup/'+backup.id+'"><button style="width:45px;" class="btn"><img src="/images/down.png" style="height:15px;"></img></a></button></span><span><button class="btn"><img src="/images/refresh.png" style="height:20px;"></img></button></span></div>');
			});
		});
	}

	//list_backups(true);
	//setInterval(list_backups, 2000);
	$('#email_options input').change(function() {
		$('#email_options').find('button').first().show();
		$('#email_options').find('button').last().hide();

	});
	//update_stats();
	//setInterval(update_stats, 5000);


	$('#ldap_form').find('input, select').change(function() {
		$('#test_ldap_btn').show();
		$('#save_ldap_btn').hide();

	});
});

function change_ldap_inputs() {

}

function update_stats() {
	$.ajax({
		type: "get",
		url:  "/scot/admin/stats"
	}).done(function(response) {
		$('#stats').html(text2html(response.data.overview));  
	});
}

function add_option_to_select(selector, value, text, id) {
	var new_option = $('<option></option>').val(value).text(text).attr('name', 'groups').attr('id',id);
	$(selector).append(new_option);
}

function remove_option_from_select(selector, value, id) {
	$(selector).find('option[value='+'"'+value+'"'+']').remove();
}

function add_users() {
	move_options('#all_users', '#users');
	remove_validate($('#users'));
}

function remove_users() {
	move_options('#users', '#all_users');
}


function add_groups() {
	move_options('#all_groups', '#groups');
}

function remove_groups() {
	move_options('#groups', '#all_groups');
}


function move_options(from, to) {
	$(from).find("option:selected").each(function(selected_group_index, selected_group) {
		add_option_to_select(to, $(selected_group).val(), $(selected_group).text(), $(selected_group)[0].id);
		remove_option_from_select(from, $(selected_group).val(), $(selected_group)[0].id);
	});

}



function remove_validate(dom_obj) {
	dom_obj.parent().find('.validate').remove();
}

function display_warn(dom_obj, name) {
	dom_obj.parent().append('<span class="validate">You need to supply '+name+'</span>');
	$(dom_obj).keydown(function() {
		remove_validate(dom_obj);
	});
}

function empty(dom_obj, name){
	if(dom_obj.val() != undefined && dom_obj.val().length == 0) {
		display_warn(dom_obj, name);
		return 1;
	}
	return 0;
}

function save_user_changes(button) {
	$('.loading').remove();
	var user_type = $('#user_modal').data('user_type');
	var ajax_type = 'PUT';
	var url;
	if(user_type == 'New') {
		//TODO: make sure this username isn't already taken
		var username_input = $('#user_form').find('input[name=username]'); 
		var password_input = $('#user_form').find('input[type=password]'); 
		if(empty(username_input, 'username')) {  return 1;}
		if(empty(password_input, 'password')) {  return 1;}
		//TODO: make sure password isn't empty
		ajax_type = 'POST';
		url = '/scot/api/v2/user/';
	}
	$(button).append('<img class="loading" src="./loading.gif"></img>');
	var id             = $('#user_modal').find('input[name=id]').val();
	var username = $('#user_modal').find('input[name=username]').val();
	var fullname = $('#user_modal').find('input[name=fullname]').val();
	var active   = $('#user_modal').find('input[name=active]').prop('checked');
	var password = $('#user_modal').find('input[name=password]').val();
	if(password.length > 0) {
		password = password;
	}
	if (active == true) {
		active = 1;
	} else {
		acitve = 0;
	}
	var group   = $('#user_form').find('select[name=groups]').find('option').map(function() { return $(this).attr('value'); }).toArray(); //grab the values from each option (selected or not) in the groups select into array 
	if (id != undefined) {
		url = '/scot/api/v2/user/' + id;
	}
	var json = {'username':username,'fullname':fullname, 'active':active, 'password':password, 'groups':group}
	$.ajax({
		type: ajax_type,
		async: true,
		url:  url,
		data: JSON.stringify(json),
		contentType: 'application/json; charset=UTF-8',
	}).done(function(response) {
		$('#user_modal').modal('hide');
		populate_local_users_n_groups();
	}).error(function(response) {
		$('.loading').attr('src', '/images/close_toolbar.png');
	});

	return false;
}

function save_group_changes(button) {
	$('.loading').remove();
	var ajax_type = 'PUT';
	var url;
	var group_type = $('#group_modal').data('group_type');
	if(group_type == 'New') {
		//TODO: make sure this username isn't already taken
		var groupname_input = $('#group_form').find('input[name=groupname]'); 
		if($('#users option').length < 1) {
			display_warn($('#users'), 'at least one user for this group');
			return 1;
		} 
		if(empty(groupname_input, 'groupname')) {  return 1;}
		ajax_type = 'POST'  		  
		url = '/scot/api/v2/group/';
	}
	$(button).append('<img class="loading" src="./loading.gif"></img>');
	var id = $('#group_modal').find('input[name=id]').val();
	var groupname = $('#group_modal').find('input[name=groupname]').val();
	var description = $('#group_modal').find('input[name=description]').val();
	var selectedusers   = $('#group_form').find('select')[0];
	selectedusers = $(selectedusers).find('option').map(function() { return $(this).attr('value'); }).toArray(); //grab the values from the left (selected) side in the users select into array 
	var unselectedusers = $('#group_form').find('select')[1];
	unselectedusers = $(unselectedusers).find('option').map(function() { return $(this).attr('value'); }).toArray(); //grab the values from the right (unselected) side in the users select into array
	var selectedusersid = $('#group_form').find('select')[0];
	selectedusersid = $(selectedusersid).find('option').map(function() { return parseInt($(this).attr('id')); }).toArray();
	var unselectedusersid = $('#group_form').find('select')[1]
	unselectedusersid = $(unselectedusersid).find('option').map(function() { return parseInt($(this).attr('id')); }).toArray();
	if (id != undefined) {
		url = '/scot/api/v2/group/' + id;
	}
	var json = {'name':groupname, 'description':description}
	$.ajax({
		type: ajax_type,
		async: true,
		url:  url,
		data: JSON.stringify(json),
		contentType: 'application/json; charset=UTF-8',
	}).done(function(response) {
		$.ajax({
			type: 'get',
			url:  '/scot/api/v2/user',
			data: {limit:0},
		}).done(function(response) {
			for (i=0; i < response.records.length; i++) {
				if (selectedusersid.indexOf(response.records[i].id) !== -1) {
					if (response.records[i].groups.indexOf(groupname) === -1) {
						var currentGroup = response.records[i].groups;
						currentGroup.push(groupname);
						//todo check if group is already there and skip if it is. 
						var url = '/scot/api/v2/user/' + response.records[i].id;
						var json = {'groups':currentGroup};
						$.ajax({
							type: 'put',
							async: true,
							url:  url,
							data: JSON.stringify(json),
							contentType: 'application/json; charset=UTF-8',
						}).done(function(response) {
							populate_local_users_n_groups();
						}).error(function(response) {
							$('.loading').attr('src', '/images/close_toolbar.png');
						});
					}
				}
				if (unselectedusersid.indexOf(response.records[i].id) !== -1) {
					console.log(i);
					if (response.records[i].groups.indexOf(groupname) !== -1) { 
						var currentGroup = response.records[i].groups;
						var index = currentGroup.indexOf(groupname);
						if (index !== -1) {
							currentGroup.splice(index,1)
							var url = '/scot/api/v2/user/' + response.records[i].id;
							var json = {'groups':currentGroup}
							$.ajax({
								type: 'put',
								asynx: true,
								url: url,
								data: JSON.stringify(json),
								contentType: 'application/json; charset=UTF-8'
							}).done(function(response) {
								console.log('removing from group')
							}).error(function(response) {
								$('.loading').attr('src','/images/close_toolbar.png');
							});
						}
					}
				}
			}

			$('#group_modal').modal('hide');
			populate_local_users_n_groups();
		}).error(function(response) {
			$('.loading').attr('src', '/images/close_toolbar.png');
		});
		return false;
	})
}


function new_user() {
	$.ajax({
		type: 'GET',
		url:  '/scot/api/v2/group',
		data: {limit:0}
	}).done(function(response) {
		user_modal('', '', true, false, [], response.records, 'New'); 
	});

}

function options(options_img) {
	$(options_img).parents('.form-group').find('.details').slideToggle();
}

function help(question_img) {
	$(question_img).parents('.form-group').find('.details').slideToggle();
}

function restore_selected() {
	if($('#restore_file').val().length > 0) {
		$('#restore_btn').show();
	} else {
		$('#restore_btn').hide();
	}
}

function new_group() {
	$.ajax({
		type: 'GET',
		url:  '/scot/api/v2/user',
		data: {limit:0}
	}).done(function(response) {
		users = response.records;		
		group_modal('', '', users, 'New'); 
	});

}

function restore_warn() {
	$('#restore_warn_modal').modal('show');
}

function restore_warn() {
	$('#restore_warn_modal').modal('show');
}
function update_warn() {
	$('#update_warn_modal').modal('show');
}
function ssl_upload_warn() {
	$('#ssl_upload_warn_modal').modal('show');
}

function create_backup() {
	$('#create_btn').find('img').remove();
	$('#create_btn').prop('disabled', true).append('<img src="./loading.gif" style="width:20px;"></img>');
	$.ajax({
		type: 'post',
		url:  '/scot/admin/backup'
	}).done(function(response) {
		$('#create_btn').prop('disabled', false).find('img').remove();
	}).error(function(response) {
		$('#create_btn').prop('disabled', false).find('img').attr('src', '/images/close_toolbar.png');
		alert('ERROR: Could not start backup');
	});
}

function upload_file_changed() {
	if($('#update_file').val() != '') {
		$('#update_warn_btn').show();
	} else {
		$('#update_warn_btn').hide();
	}
}

function update_backup_schedule() {
	$('#schedule_btn').find('img').remove();
	$('#schedule_btn').append('<img  style="width:20px;" src="./loading.gif"></img>');
	var data = {'schedule' : $('#schedule').val(), 'max_disk' : $('#max_disk').val(), 'enable_backups' : $('#enable_backups').prop('checked')};
	$.ajax({
		type: 'POST',
		url: '/scot/admin/backup/schedule',
		data: JSON.stringify(data)
	}).error(function(response) {
		var img = $('#schedule_btn').find('img');
		img.attr('src', '/images/close_toolbar.png');
		setTimeout(function() {
			img.remove();
		}, 5000);
	}).done(function(response) {
		var img = $('#schedule_btn').find('img');
		img.attr('src', '/check.png');
		setTimeout(function() {
			img.remove();
		}, 5000);
	});
}

function email_settings(type) {
	$('#'+type+'_email_btn').find('img').remove();
	$('#'+type+'_email_btn').append('<img  style="width:20px;" src="./loading.gif"></img>');
	var form = $('#email_options');
	var email_hostname = form.find('input[name=address]').val();
	var email_port = form.find('input[name=port]').val();
	var email_ssl = form.find('input[name=email_ssl]').prop('checked');
	var email_username = form.find('input[name=username]').val();
	var email_password = form.find('input[name=password]').val();
	var data = {'username' : email_username, 'hostname' : email_hostname, 'port' : email_port, 'ssl' : email_ssl};
	if(email_password != '') {
		data.password = email_password;
	}
	$.ajax({
		type: 'POST',
		url:  '/scot/admin/alerts/'+ type + '/email',
		data: JSON.stringify(data)
	}).done(function(response) {
		var img = $('#'+type+'_email_btn').find('img');
		img.attr('src', '/check.png');
		setTimeout(function() {
			img.remove();
		}, 5000);
		$('#set_email_btn').show();
	}).error(function(response) {
		var img = $('#'+type+'_email_btn').find('img');
		img.attr('src', '/images/close_toolbar.png');
		setTimeout(function() {
			img.remove();
		}, 5000);
		alert('error, could not ' + type + ' email settings, check that the SCOT server is running');
	});
}

// Register click handlers on document ready
$(document).ready( function() {
	// Update functions
	$( "#update_file" ).change( upload_file_changed );
	$( "#update_warn_btn" ).click( update_warn );
	$( "#update_confirm_btn" ).click( ( event ) => update_confirm( event.currentTarget ) );

	// Backup functions
	$( "#create_backup_btn" ).click( create_backup );
	$( "#restore_file" ).change( restore_selected );
	$( "#restore_backup_btn" ).click( restore_warn );
	$( "#restore_backup_confirm_btn" ).click( ( event ) => restore_confirm( event.currentTarget ) );
	$( "#schedule_backup_btn" ).click( update_backup_schedule );

	// User functions
	$( "#new_user_btn" ).click( new_user );
	$( "#add_group_user_btn" ).click( add_groups );
	$( "#remove_group_user_btn" ).click( remove_groups );
	$( "#save_user_btn" ).click( ( event ) => save_user_changes( event.currentTarget ) );

	// Group functions
	$( "#new_group_btn" ).click( new_group );
	$( "#add_user_group_btn" ).click( add_users );
	$( "#remove_user_group_btn" ).click( remove_users );
	$( "#save_group_btn" ).click( ( event ) => save_group_changes( event.currentTarget ) );

	// LDAP functions
	$( "#test_ldap_btn" ).click( test_ldap );
	$( "#save_ldap_btn" ).click( save_ldap );

	// Collectors functions
	$( "#test_email_btn" ).click( () => email_settings('test') );
	$( "#set_email_btn" ).click( () => email_settings('set') );
	$( "#sender_email_btn" ).click( add_permitted_sender );

	// SSL Cert
	$( "#upload_ssl_btn" ).click( ssl_upload_warn );
	$( "#confirm_ssl_btn" ).click( ( event ) => ssl_upload_confirm( event.currentTarget ) );

	// Help buttons in forms
	$( ".control-label img" ).click( ( event ) => help( event.currentTarget ) );
})
