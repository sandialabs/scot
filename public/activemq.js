function s4() {
    return Math.floor((1 + Math.random()) * 0x10000)
        .toString(16)
        .substring(1);
};

function get_guid() {
    return s4() + s4() + s4() + s4() +
        s4() + s4() + s4() + s4();
}

var msgs_recieved = 0;
var clientId;
var attempt_number = 0;

function register_client() {
    attempt_number++;
    clientId = get_guid();
    $.ajax({
        type: 'POST',
        url: '/scotaq/amq',
        data: {
            message: 'chat',
            type: 'listen',
            clientId: clientId,
            destination: 'topic://activity',
        }
    }).done(function() {
	console.log('Registered client as ' +clientId);
        setTimeout(listen_for_changes, 0);
    }).fail(function() {
        console.log('ERROR: Failed to register client, trying again in 1 second');
	setTimeout(register_client, 1000);
    });
}

function listen_for_changes() {
    var now = new Date();
    $.ajax({
        type: 'GET',
        dataType: 'text',
        data: {
            clientId: clientId,
            timeout: 2000,
            d: now.getTime(),
            r: Math.random(),
            json: 'true',
	    username: username,
	    loc: location.hash
        },
        url: '/scotaq/amq'
    }).done(function(data) {
	console.log('recieved message(s)');
        setTimeout(listen_for_changes, 10);
        var messages = $(data).text().split('\n');
        $(messages).each(function(index, message) {
            if (message != "") {
                console.log(message);
                var json = JSON.parse(message);
                handle_update(json);
            }
        });
    }).fail(function(data) {
        console.log('ERROR: Failed to recieve message in listen_for_changes');
        setTimeout(register_client, 0);
    });
}

function get_entry(entry_id, callback) {
    $.ajax({
        type: 'GET',
        url: '/scot/entry/' + entry_id,
    }).done(function(response) {
        callback(response.data);
    });
}

function get_incident(incident_id, callback) {
    $.ajax({
        type: 'GET',
        url: '/scot/incident/' + incident_id,
    }).done(function(response) {
        callback(response.data);
    });
}

function get_intel(intel_id, callback) {
    $.ajax({
        type: 'GET',
        url: '/scot/intel/' + intel_id,
    }).done(function(response) {
        callback(response.data);
    });
}
function get_event(event_id, callback) {
    $.ajax({
        type: 'GET',
        url: '/scot/event/' + event_id,
    }).done(function(response) {
        callback(response.data);
    });
}

function get_alertgroup_row(alertgroup_id, callback, opts) {
    $.ajax({
        type: 'GET',
        url: '/scot/alertgroup/refresh/' + alertgroup_id,
    }).done(function(response) {
        callback(response.data, opts);
    });

}
function get_alertgroup(alertgroup_id, callback) {
    $.ajax({
        type: 'GET',
        url: '/scot/alertgroup/' + alertgroup_id,
    }).done(function(response) {
        callback(response.data);
    });

}

function get_alert(alert_id, callback) {
    $.ajax({
        type: 'GET',
        url: '/scot/alert/' + alert_id,
    }).done(function(response) {
        callback(response.data);
    });
}

function alertgroup_update(alertgroup) {
    $('#' + alertgroup.alertgroup_id + '_status').html(color_status_cell(alertgroup.status));
    $('#' + alertgroup.alertgroup_id + '_updated').html(fullDateFormat(format_epoch(alertgroup.updated)));
    $('#' + alertgroup.alertgroup_id + '_source').text(alertgroup.source);
    $('#' + alertgroup.alertgroup_id + '_subject').text(alertgroup.subject);
    $('#' + alertgroup.alertgroup_id + '_view_count').text(alertgroup.views);
    $('#' + alertgroup.alertgroup_id + '_tags').text(alertgroup.tags);

    if(bottom_mode == 'alert' && alert_mode == 'alertgroup') {
      if(current_id == alertgroup.alertgroup_id) {
        $('#event_status').text(alertgroup.status);
    
      }
    } 

}

function alertgroup_create(alertgroup, opts) {
    if(top_mode == 'alert') {
      if(opts.alerts != undefined && opts.alerts.length == 1) {
        alertgroup.alert_id = opts.alerts[0];
      }
      var ag = render_grid_row(alertgroup)
      $('#event_grid').prepend(ag);
    }
}

function alert_update(alert) {
    if ($('#event_id')) {
        var alert_id = $('#event_id').html();
        if (alert_id == alert.alert_id) {
            if (document.activeElement.id != "subjectEditor") {
                $('#subjectEditor').text(alert.subject);
            }
            var viewed_by = Object.keys(alert.viewed_by);
            $('#viewed_by').text(viewed_by.join(', '));
            $('#event_status').text(alert.status);
            if (document.activeElement.id != 'source') {
                $('#source').text(alert.source);
            }
            $('#bad').text(alert.downvotes.length);
            $('#bad').data('votes', alert.downvotes.join());
            $('#ok').text(alert.upvotes.length);
            $('#OK').data('votes', alert.upvotes.join());
            $('#event_tags2').select2('val', alert.tags);
        }

    }
    if($('#alert_'+alert.alert_id+'_status').length > 0) {
       var pre = '<b>';
       var post = '</b>';
       if(alert.status == 'promoted') {
          pre = '<button type="button" onclick="window.location=\'#/event/'+alert.events[0]+'\'" class="btn btn-mini">';
	  post = '</button>';
       }
       $('#alert_'+alert.alert_id+'_status').html(pre + color_status_cell(alert.status) + post);
    }
    var row = $('#' + alert.alert_id + '_status').parent();
    $(row).data('updated', new Date());
    $(row).addClass('recentlyUpdated');
    $('#' + alert.alert_id + '_status').html(color_status_cell(alert.status));
    $('#' + alert.alert_id + '_subject').text(alert.subject);
    $('#' + alert.alert_id + '_source').text(alert.source);
    $('#' + alert.alert_id + '_tags').text(alert.tags.join(','));
    $('#' + alert.alert_id + '_owner').text(alert.owner);
    $('#' + alert.alert_id + '_updated').html(fullDateFormat(format_epoch(alert.updated)));
    get_alertgroup_row(alert.alertgroup, alertgroup_update);
}

function entry_update(entry) {
    var entry_id = entry.entry_id;
    var inner = $('#entry_' + entry_id + '_inner');
    var outer = $('#entry_' + entry_id + '_outer');

    //Replace the body text of the entry with the new body text
    $('#entry_' + entry_id + '_inner').find('iframe')[0].contentDocument.body.innerHTML = entry.body_flaired;

    //generate HTML for new entry, so we can use it to update existing entry
    var new_entry = $(render_entry(entry.parent, entry))

    //Update the header bar (when time, updated, owned by) 
    var new_header_inner = new_entry.find('#entry_' + entry_id + '_status_text').html();
    $('#entry_' + entry_id + '_status_text').html(new_header_inner);
    //Copy classes from latest rendered entry to visible entry (todo status)
    if($('#entry_'+entry_id+'_outer').length > 0 && $('#entry_'+entry_id+'_outer')[0].className != undefined) {
       $('#entry_' + entry_id + '_outer')[0].className = new_entry[0].className;
       $('#entry_' + entry_id + '_outer').find('.entry-header')[0].className = new_entry.find('.entry-header')[0].className;
    }
    //Update permissions of entr
    var new_entry_write_permissions = new_entry.find('#entry_' + entry_id + '_permissions').find('.entry_write').val();
    $('#entry_' + entry_id + '_permissions').find('.entry_write').val(new_entry_write_permissions);
    var new_entry_read_permissions = new_entry.find('#entry_' + entry_id + '_permissions').find('.entry_read').val();
    $('#entry_' + entry_id + '_permissions').find('.entry_read').val(new_entry_read_permissions);
    toggle_entry_permissions(entry_id);
    toggle_entry_permissions(entry_id);
    $.ajax({
       type: 'GET',
       url:  '/scot/entity/entry/'+entry.entry_id,
    }).done(function(response) {
       var flairdata = response.data;
       var entities = $('#entry_'+entry_id+'_body').find('iframe').contents().find('.entity');
       for (var i=0; i< entities.length; i++) {
	  var entity = entities[i];
          handle_entity(entity, flairdata);
       }
    });
    if(entry.target_type == 'event') {
       get_event(entry.target_id, event_update);
    } 
  
   process_entries([entry]);
}

function entry_create(entry) {
    var entry_id = entry.entry_id;
    var entry_html = render_entry(entry.parent, entry);
    pentry(entry_html, entry.flairdata);
    var parent = entry.parent
    var saving = $('.saving');
    if(saving.length > 0){
      $(saving).each(function(idx, save) {
         if($(save).data('id') == entry.entry_id) {
           $(save).replaceWith(entry_html);
           $(save).removeClass('saving');
         }
         return 0;
      });
    } else if (document.getElementById('entry_' + parent + '_outer') != null) {
        $('#entry_' + parent + '_outer').append(entry_html);
    } else if($('#alert_'+entry.target_id+'_row').length > 0) {
	$('#alert_'+entry.target_id+'_row').next('tr').find('td').last().append(entry_html);
    } else {
        $('#BottomPane').append(entry_html);
    }
    //scroll_to_entry(entry.entry_id);
    if(entry.target_type == 'event') {
       get_event(entry.target_id, event_update);
    } 
    if(entry.target_type == 'event') {
       get_event(entry.target_id, event_update);
    } 

    process_entries([entry]);
}

function entry_delete(entry_id) {
    $('#entry_' + entry_id + '_outer').replaceWith($('#entry_' + entry_id + '_outer').find('.entry-outer'))
}

function event_create(event) {
  if((top_mode == 'event' || top_mode == 'intel') && $('#'+event.event_id+'_event_id').length == 0) {
    var evt = render_grid_row(event);
    $('#event_grid').prepend(evt);
  }
}

function incident_delete(incident_id) {
    if(bottom_mode == "incident") {
       var row = $('#' + incident_id + '_status').parent();
       $(row).remove();
       if(current_id == incident_id) {
          window.location = '/#/incident';
       }
    }
}

function event_delete(event_id) {
    var row = $('#' + event_id + '_status').parent();
    $(row).remove();
}

function event_update(event) {
    if ($('#event_id')) {
        var event_id = $('#event_id').html();
        //Update event (if user currently viewing it)
        if (event_id == get_id_from_obj(event)) {
            if (document.activeElement.id != "subjectEditor") {
                $('#subjectEditor').val(event.subject);
                sizeInput($('#subjectEditor').get(0));
            }
            $('#event_owner').text(event.owner);
            $('#event_status').text(event.status);
            $('#event_tags2').select2('val', event.tags);
            $('#event_source2').select2('val', event.sources);
	    move_entry_to_summary_position(event.summary_entry_id);
        }
     }
     if(top_mode == 'event' || top_mode == 'intel') {
       var tmp_id = get_id_from_obj(event); 
       //Update Grid
        $('#' + tmp_id + '_status').html(color_status_cell(event.status));
        $('#' + tmp_id + '_subject').text(event.subject);
        $('#' + tmp_id + '_sources').text(event.sources);
        $('#' + tmp_id + '_tags').text(event.tags.join(','));
        $('#' + tmp_id + '_owner').text(event.owner);
        $('#' + tmp_id + '_updated').text(fullDateFormat(format_epoch(event.updated)));
        $('#' + tmp_id + '_entries').text(event.entries.length);
    }
}

function event_view(id, view_count) {
    $('#' + id + '_view_count').html(view_count);
    var row = $('#' + id + '_status').parent();
    $(row).data('view-updated', new Date());
    $(row).addClass('recentlyViewed');
}

function incident_update(incident) {
    if ($('#event_id')) {
        var incident_id = $('#event_id').html();
        //Update incident (if user currently viewing it)
        if (incident_id == incident.incident_id) {
            if (document.activeElement.id != "subjecteEditor") {
                $('#subjectEditor').html(incident.subject);
            }
            $('#event_owner').html(incident.owner);
            $('#event_status').html(incident.status);
            //TODO: write code to update body

            $('#category').val(incident.category);
            $('#type').val(incident.type);
            $('#sensitivity').val(incident.sensitivity);
            $('#security_category').val(incident.security_category);
            //$('#discovered').datetimepicker('setDate', format_epoch(incident.discovered));
        }
        $('#' + incident.incident_id + '_subject').html(incident.subject);
        $('#' + incident.incident_id + '_reported').html(fullDateFormat(format_epoch(incident.reported)));
        $('#' + incident.incident_id + '_discovered').html(fullDateFormat(format_epoch(incident.discovered)));
        $('#' + incident.incident_id + '_occurred').html(fullDateFormat(format_epoch(incident.occurred)));
        $('#' + incident.incident_id + '_status').html(incident.status);
        $('#' + incident.incident_id + '_type').html(incident.type);
        $('#' + incident.incident_id + '_category').html(incident.category);
        $('#' + incident.incident_id + '_sensitivity').html(incident.sensitivity);
        $('#' + incident.incident_id + '_security_cateogry').html(incident.security_category);
        $('#' + incident.incident_id + '_reporting_deadline').html(incident.reporting_deadlinetype);




    }
}

function incident_create(incident) {

}

function incident_create(incident) {

}

function find_grid_row(event_id) {
    $('#event_grid').find('tr').each(function(index, row) {
        var row_id = $($(row).children()[0]).html();
        row_id = parseInt(row_id);
        if (event_id == row_id) {
            return row;
        }
    });
}


function alert_delete(id) {
  if($('#alert_'+id+'_status').length > 0) {
     $('#alert_'+id+'_status').closest('tr').remove();
  }
  var curr_id = parseInt($('#event_id').html());
  if (id == curr_id) {
    alert('This alertgroup has been deleted');
    $('#BottomPane').html('');
  }
}

function alert_view(id, json) {
  $('#'+id+'_view_count').text(json.viewcount);
}
function alertgroup_view(response, json) {
  $('#'+json.id+'_view_count').text(json.viewcount);
  $('#viewed_by').html(format_viewers(response.viewed_by));
}

function alertgroup_delete(id) {
  $('#row_'+id).remove();
  var curr_id = parseInt($('#event_id').html());
  if (id == curr_id) {
    alert('This alertgroup has been deleted');
    $('#BottomPane').html('');
  }
}

function display_notice(json) {
    // var div = $('<div></div>').text(json.text);
    // setTimeout(return function() { $(div).remove()  }, 5000);
    //  $('#admin_notices').append(div);
}

var previous_uids = new Array();
function handle_update(json) {
    var event_id = $('#event_id').html();
    if(json.hasOwnProperty('guid')) {
      if($.inArray(json.guid, previous_uids) >= 0) {
	 console.log('already processed this message based on UID '+ json.guid + ' skipping');
         return 0;
      }  else {
	 previous_uids.push(json.guid);
	 if(previous_uids.length > 20) {
	    previous_uids.shift();
	 }
      }
    }
    if (json.hasOwnProperty('type')) {
        console.log(json);
       /* if (json.action == 'update' || json.action == 'creation' || json.action == "deletion" || json.action == "close") {
            $.pnotify({
                title: json.type + ' ' + json.id + ' ' + json.action,
                text: '',
                delay: 3000,
                history: false,
                nonblock: true,
                nonblock_opacity: 0.2
            });
        }*/

        switch (json.type) {
            case 'entry': //Modifications to ENTRIES
                switch (json.action) {
                    case 'update':
                            get_entry(json.id, entry_update);
                        break;
                    case 'creation':
                            if(json.target_type == bottom_mode ) {
                                if(json.target_id == current_id || $('#alert_'+json.target_id+'_row').length > 0 ) {
                                  get_entry(json.id, entry_create);
                                }
                            }
                        break;
                    case 'deletion':
                        entry_delete(json.id);
                        break;
                }
                break;
            case 'event': //Modifications to EVENTS
                switch (json.action) {
                    case 'update':
                        get_event(json.id, event_update);
                        break;
                    case 'creation':
                        get_event(json.id, event_create);
                        break;
                    case 'deletion':
                        event_delete(json.id);
                    case 'view':
                        if (json.id != null) {
                            event_view(json.id, json.viewcount);
                        }
                }
                break;
            case 'intel': //Modifications to EVENTS
                switch (json.action) {
                    case 'update':
                        get_intel(json.id, event_update);
                        break;
                    case 'creation':
                        get_intel(json.id, event_create);
                        break;
                    case 'deletion':
                        event_delete(json.id);
                    case 'view':
                        if (json.id != null) {
                            event_view(json.id, json.viewcount);
                        }
                }
                break;
            case 'alert':
                switch (json.action) {
                    case 'update':
                    case 'close':
                        get_alertgroup_row(json.alertgroup, alertgroup_update, json);
                        get_alert(json.id, alert_update);
                        break;
                    case 'creation':
                        get_alert(json.id, alert_create);
                        break;
                    case 'deletion':
                        alert_delete(json.id);
                        break;
		    case 'view':
		        alert_view(json.id, json);
			break;
                }
                break;
            case 'incident':
                switch (json.action) {
                    case 'update':
                        get_incident(json.id, incident_update);
                        break;
                    case 'creation':
                        get_incident(json.id, incident_create);
                        break;
                    case 'deletion':
                        incident_delete(json.id);
                }
                break;
            case 'admin_notice':
                display_notice(json);
                break;
	    case 'alertgroup':
		switch (json.action) {
			case 'update':
				get_alertgroup_row(json.id, alertgroup_update, json);
			break;
			case 'view':
				if(json.id != null) {
				  get_alertgroup_row(json.id, alertgroup_view, json);
				}
			break;
			case 'deletion':
				alertgroup_delete(json.id);
			break;
			case 'creation':
				get_alertgroup_row(json.id, alertgroup_create, json);
			break;
		}
            break;
        }
    } else if (json.hasOwnProperty('test')) {
       $('#amq_test').show();
       msgs_recieved++;   
       $('#amq_test').val(msgs_recieved);
    }

}
