var flairState = true;
var globalFlairState = true;
var ctrlDown = false;
var current_user;
var timers = new Array();
/*$.ajaxPrefilter(function( options, originalOptions, jqXHR ) {

   originalOptions._error = originalOptions.error;

   // overwrite error handler for current request
   options.error = function( _jqXHR, _textStatus, _errorThrown ){

   if (_jqXHR.status != 401){

         if( originalOptions._error ) originalOptions._error( _jqXHR, _textStatus, _errorThrown );
         return;
      };

      // else... Call AJAX again with original options
//      $("#login_modal").data('originalOptions', originalOptions);
      if(current_user == undefined) {
        $("#login_modal").modal('show');
      }
      timers.push(function() {
         $.ajax(originalOptions);
      });
   };
});*/

var search;
var parsed = false;
var next_page;
var lastFocus;
var alert_mode;
var style = 'vertical';
var currentApiUrl = '';
var guide_id = 0;
var date_cols = ['occurred', 'discovered', 'reported', 'updated', 'created'];
var display_names = {
    'event_id': 'id',
    'view_count': 'views',
    'alertgroup_id': 'id',
    'viewcount': 'views',
    'incident_id': 'id',
    'doe_report_id': 'doe',
    'security_category': 'sec',
    'reporting_deadline': 'deadline',
    'target_type': 'type',
    'target_id': 'id',
    'entry_id': 'entry',
    'category': 'cat',
    'sensitivity': 'sen',
    'entrycount' : 'entries'
}
var column_types = {
    'event': ['event_id', 'status', 'created', 'updated', 'subject', 'sources', 'tags', 'owner', 'entrycount', 'view_count'],
    'alert': ['alertgroup_id', 'status', 'created', 'sources', 'subject', 'tags', 'view_count'],
    'incident': ['incident_id', 'doe_report_id', 'status', 'owner', 'subject', 'occurred', 'discovered', 'reported', 'type', 'category', 'sensitivity', 'security_category', 'reporting_deadline'],
    'task': ['target_type', 'target_id', 'status', 'owner', 'entry_id', 'updated'],
    'intel': ['intel_id', 'created', 'subject', 'sources', 'tags', 'view_count']
};
var current_id = 0;
var alert_ids = new Array();
var editing_reference_count = 0;
var last_start = 0;
var username = '';

function parseUrl(url) {
    var a = document.createElement('a');
    a.href = url;
    return a;
}
/*
//List of servers running SCOT
var servers = ['server1.example.com', 'server2.example.com'];

//Choose another server from the list and re-submit

function ajaxFlipServer(settings) {
    if(console != undefined) {
      console.log('Switching server AJAX talks to');
    }
    var url = parseUrl(settings.url);
    var pos = $.inArray(url.host, servers);
    var next_server = servers[(pos + 1) % servers.length];
    url.host = next_server;
    settings.url = url.href;
    $.ajax(settings);

}
*/


// when adding a new entry, scroll to it.
jQuery.fn.scrollMinimal = function() {
  var cParentTop =  this.parent().offset().top;
  var cTop = this.offset().top - cParentTop;
  var cHeight = this.outerHeight(true);
  var windowTop = $('#TopPane').offset().top;
  var visibleHeight = $('#TopPane').height();

  var scrolled = $('#TopPane').scrollTop();
  if (cTop < (scrolled)) {
    $('#TopPane').animate({'scrollTop': cTop-(visibleHeight/2)}, 'fast', '');
  } else if (cTop + cHeight + cParentTop> windowTop + visibleHeight) {
    $('#TopPane').animate({'scrollTop': (cTop + cParentTop) - visibleHeight + scrolled + cHeight}, 'fast', 'swing');
  }
};


function select2_clicked(e) {
    alert('stuff');

}
//When ajax call fails, switch to a different server & resubmit
/*$(document).ajaxError(function(event, jqxhr, settings, exception) {
   ajaxFlipServer(settings);
});*/

$.ajax({
    type: 'GET',
    contentType: "application/json",
    url: '/scot/whoami',
}).done(function(response) {
    username = response.user;
});

$(document).ready(function(f) {
    setInterval(function() {
    $('.clickTabs').toggleClass('glow');
  }, 150);
    setInterval(function() {
       $('#introText').toggle("fade");
    }, 1000);
    $.ajax({
        type: 'get',
        url: '/scot/current_handler'
    }).done(function(response) {
        $('#incident_handler').text(response.incident_handler);
    });
    $('#findAndReplace').popover({
        content: findAndReplace,
        html: true,
        placement: 'bottom'
    });
    $('#tableEditor').popover({
        content: selectTableSize,
        html: true,
        placement: 'bottom'
    });
    $("#linked_alerts").select2({
        tags: [""],
        tokenSeparators: [",", " "],
        onClick: select2_clicked,
        escapeMarkup :  function(input) { return input;}
    });
   /* $("#linked_events").select2({
        tags: [""],
        tokenSeparators: [",", " "]
    });*/
    $("#event_source2").select2({
        tags: [""],
        tokenSeparators: [",", " "]
    });

    locationHashChanged();

    // hot key functionality
    //grid_filter_updated(true);
    $('body').keydown(function(event) {
         var key = String.fromCharCode(event.which);
         if(key == 'F' ) {
               if(!event.target.className.contains('entry-body-inner') && event.target.nodeName != "INPUT" && event.target.nodeName != "TEXTAREA") {
                   fullscreen_content();
               }
        } else if(event.shiftKey) {
            ctrlDown = true;
        }
    });

    // are you holding the shift key down
    // ctrlDown is a legacy name
    $('body').keyup(function(event) {
        if(!event.shiftKey) {
            ctrlDown = false;
        }
    });


    // more hot keys
    // just for top grid
    $('#TopPane').keydown(function(event) {
        switch (event.keyCode) {
            case 40: //down
            case 74: //j
                $('.selectedRow').nextAll(':visible:first').click();
                break;
            case 38: //up
            case 75: //k
                $('.selectedRow').prevAll(':visible:first').click();
                break;
            case 67: //c close/open toggle
                open_close_event();
                break;
            case 86: //v view single alerts vertical toggle
                /*if ($('#vertical').is(':visible')) {
                    toggleVertical();
                }*/
                break;
            case 85: //u upvote
                if (top_mode == 'alert') {
                    upvote();
                }
                break;
            case 68: //d downvote
                if (top_mode == 'alert') {
                    downvote();
                }
                break;
            case 65: //a Add entry
                addEntry();
                break;

        }
    });

    // jquery function created to prevent 
    // sending an ajax call after every key press
    $('#subjectEditor').keyup(
		$.debounce(1000, update_subject)

	);

    $('#2search').keyup(
          $.debounce(100, submit_preview)
    );

    //$('#BottomPane').scroll(alert_entry_buttons);
});

/*function alert_entry_buttons() {
       if(bottom_mode == 'alert') {
          $('.entry_toolbar').removeClass('pull-right');
          $('.entry_toolbar').css({
            'left' : ($('#BottomPane').scrollLeft() + $(window).width() -  620) + 'px'
          });
       }
}*/

// lib function - perform a deep copy
function deepCopy(obj) {
    if (Object.prototype.toString.call(obj) === '[object Array]') {
        var out = [], i = 0, len = obj.length;
        for ( ; i < len; i++ ) {
            out[i] = arguments.callee(obj[i]);
        }
        return out;
    }
    if (typeof obj === 'object') {
        var out = {}, i;
        for ( i in obj ) {
            out[i] = arguments.callee(obj[i]);
        }
        return out;
    }
    return obj;
}


var sort_col = new Array(); // current sort column(s)
sort_col['alert'] = 'created';
sort_col['event'] = 'updated';
var sort_direction = new Array();
sort_direction['alert'] = -1;
sort_direction['event'] = -1;
var previous_filter = new Object();
var grid_page = new Array();
var filter = {};
// called as part of preview
function grid_filter_updated(initial_load, start) {
    if(filter[top_mode] == undefined) {
       filter[top_mode] = {};
    }
    if(initial_load == true) {
        var filter_names = Object.keys(filter[top_mode]);
        $('.grid_filter_inputs').each(function(filter_idx, filter_inp) {
           var filter_name = $(filter_inp).attr('name');
           if(jQuery.inArray(filter_name, filter_names) >= 0) {
             $('#filter_'+filter_name).val(filter[top_mode][filter_name]);
	    } else {
             $(filter_inp).val('');
           }
        });
	//load from filter[top_mode] back into inputs
       if(grid_page[top_mode] != undefined) {
	        $('#current_page').val(grid_page[top_mode]);
        } else {
           $('#current_page').val(0);
	    }
    }
    var strings = ['subject', 'owner', 'status', 'source'];
    var nums = ['alert_id', 'alertgroup_id', 'event_id', 'doe_report_id', 'incident_id', 'view_count'];
    var arrays = ['tags', 'sources'];
    $('.grid_filter_inputs').each(function(index, input) {
        if ($.inArray(input.name, strings) >= 0) {
            var key = input.name;
            var val = input.value;
            if (val.length > 0) {
                filter[top_mode][key] = val;
            } else {
		filter[top_mode][key] = undefined;
            }
        } else if ($.inArray(input.name, nums) >= 0) {
            var key = input.name;
            var val = input.value;
            if (val.length > 0) {
                filter[top_mode][key] = [val];
            } else {
		filter[top_mode][key] = undefined;
 	    }
        } else if ($.inArray(input.name, arrays) >= 0) {
            var key = input.name;
            var val = $(input).select2('val');
            if (val.length > 0) {
                filter[top_mode][key] = val;
            } else {
		filter[top_mode][key] = undefined;
            }
        } else if (date_cols.indexOf(input.name) >= 0) {
            var key = input.name;
            var val = input.value;
            var dates = val.split(" - ");
            if (dates[0] != undefined && dates[1] != undefined) {
                var start = dates[0].split('/');
                var end = dates[1].split('/');
                var start_date = new Date(start[2], start[0] - 1, start[1]);
                var end_date = new Date(end[2], end[0] - 1, end[1], 23, 59, 59, 99);
                var start_epoch = Math.round(start_date.getTime() / 1000); //JS getTime() returns epoch in milliseconds
                var end_epoch = Math.round(end_date.getTime() / 1000); //JS getTime() returns epoch in milliseconds
                filter[top_mode][key] = {
                    begin: start_epoch,
                    end: end_epoch
                };
            } else {
		filter[top_mode][key] = undefined;
	    }
        }
    });

    var num_per_page = parseInt($('#num_per_page').val()) || 30;
    var current_page = parseInt($('#current_page').val()) || 0;
    grid_page[top_mode] = current_page;
    var options = {
        limit: num_per_page
    };
    if(!(objectEquals(filter, previous_filter))) { //If the filters changed, reset the page back to 0;
      start = undefined;
      current_page = 0;
      $('#current_page').val('0');
      previous_filter = deepCopy(filter);
    }
    last_start = start;
    options.start = (num_per_page * current_page);

    if (sort_col[top_mode] != undefined) {
        options.sort_ref = {};
        options.sort_ref[sort_col[top_mode]] = sort_direction[top_mode];
    }
    $('#TopPane').attr('disabled', true);
    $('#paging').hide();
    $('#TopPane').css('opacity', 0.2);
    var grid_type = top_mode;
    if (top_mode == 'alert') {
        grid_type = 'alertgroup';
    }
    $.ajax({
        type: 'GET',
        url: '/scot/' + grid_type,
        data: {
            grid: JSON.stringify(options),
            filter: JSON.stringify(filter[top_mode]),
        },
        success: function(data, status, headers, config) {
            grid_update_ajax_response(data, status, headers, config, start, initial_load, date_cols);
            $('#TopPane').attr('disabled', false);
            $("#paging").show();
            $('#TopPane').css('opacity', 1);
            var num_per_page = parseInt($('#num_per_page').val()) || 30;
            $('#num_pages').text(Math.floor(data.total_records / num_per_page));
            goto_page('initial');
        },
        error: function(data, status, headers, config) {
            alert('error getting data');
        },
    });


}

// render columns to determine width with sorting error and set as minimum
function adjust_grid_header_widths(cols) {
  $(cols).each(function(index, column) {
  var displayName = column;
        if (display_names[column] != undefined) {
            displayName = display_names[column];
        }
  $('#invisible').html($('<span>'+displayName + '<img src="/images/asc.gif" class="sort_arrow"></img></span>'));
  var width = $('#invisible').find('span').last().width();


    var property = 'min-width';
    var ruleClass = '.'+column;
    var updated_rule = false;
    // modify the css stylesheet 
    for (var s = 0; s < document.styleSheets.length; s++) {
        var sheet = document.styleSheets[s];
            var rules = sheet.cssRules ? sheet.cssRules : sheet.rules;
            if (rules != null) {
                for (var i = 0; i < rules.length; i++) {
                    if (rules[i].selectorText == ruleClass) {
                         rules[i].style[property] = width+'px';
			 updated_rule = true;
			 if(console != undefined) {
			    console.log("setting min-width of column " + displayName + ' = ' + rules[i].style[property]);
			 }
                    }
                }
            }
    }
    if(!updated_rule) {
       var sheet = document.styleSheets[0];
       sheet.insertRule("."+column + " {min-width: " + width+"px }", 1);
    }
  });
}

function initial_grid_load(cols, date_cols) {
        $('#filters-inner').html('');
    $(cols).each(function(index, column) {
        var displayName = column;
        if (display_names[column] != undefined) {
            displayName = display_names[column];
        }
	var sort = '';
	if (sort_col[top_mode] != undefined && sort_col[top_mode] == column) {
	  var arrow_type = 'desc';
	  if(sort_direction[top_mode] != undefined && sort_direction[top_mode] == -1) {
	      arrow_type = 'asc';
	  }
	  sort = '<img src="/images/'+arrow_type+'.gif" class="sort_arrow"></img>';
        }
         var val = '';
         if(filter != undefined && filter[top_mode] != undefined && filter[top_mode][column] != undefined) {
            val = filter[top_mode][column];
         }
        $('#filters-inner').append($('<th class="filter_column sort" class="'+column+'" onclick="sort_column(event,\'' + column + '\', this)"><div class="tableHeader">' + displayName + sort+'<br> <input type=text id="filter_'+column+'" name="' + column + '" class="filter_select2  grid_filter_inputs" onchange="grid_filter_updated(this)" value="'+val+'" ></div></th>'));

    });
    $('#filters-inner').children().find('input[name="sources"]').select2({
        tags: ['']
    });
    $('#filters-inner').children().find('input[name="tags"]').select2({
        tags: ['lazyLoadTags'],
        tokenSeparators: [",", " "]
    });
    $(date_cols).each(function(index, col_name) {
        try {
            var filter = $('#filters-inner').find('input[name="' + col_name + '"]');
            filter.datepick({
                rangeSelect: true,
                onClose: function(dates) {
                    grid_filter_updated(false);
                }
            });
        } catch (err) {

        }

    });

}

function color_status_cell(cellVal) {
    if( cellVal == undefined || cellVal == '') {
        return '';
    } else if (cellVal == 'open') {
        cellVal = '<font color="red">' + cellVal + '</font>';
    } else if (cellVal == 'closed' || cellVal == 'completed') {
        cellVal = '<font color="green">' + cellVal + '</font>';
    } else if (cellVal == 'promoted' || cellVal == 'assigned') {
        cellVal = '<font color="orange">' + cellVal + '</font>';
    } else {
        cellVal = '';
    }

    return cellVal;
}

function get_id_from_obj(obj) {
    var id = -1;
    if (obj.event_id != undefined) {
        id = obj.event_id;
    } else if(obj.intel_id != undefined) {
        id = obj.intel_id;
    } else if (obj.incident_id != undefined) {
        id = obj.incident_id;
    } else if (obj.target_type != undefined && obj.target_id != undefined) {
        id = obj.target_type + '/' + obj.target_id;
    } else if (obj.alertgroup_id != undefined) {
        id = obj.alertgroup_id;
    } else if (obj.alert_id != undefined) {
        id = obj.alert_id;
    }
    return id;
}


function objectEquals(x, y) {
    // if both are function
    if (x instanceof Function) {
        if (y instanceof Function) {
            return x.toString() === y.toString();
        }
        return false;
    }
    if (x === null || x === undefined || y === null || y === undefined) { return x === y; }
    if (x === y || x.valueOf() === y.valueOf()) { return true; }

    // if one of them is date, they must had equal valueOf
    if (x instanceof Date) { return false; }
    if (y instanceof Date) { return false; }

    // if they are not function or strictly equal, they both need to be Objects
    if (!(x instanceof Object)) { return false; }
    if (!(y instanceof Object)) { return false; }

    var p = Object.keys(x);
    return Object.keys(y).every(function (i) { return p.indexOf(i) !== -1; }) ?
            p.every(function (i) { return objectEquals(x[i], y[i]); }) : false;
}

function render_grid_row(f) {
    //Get ID wehether alert or even
    var id = get_id_from_obj(f);
    var entry_id = '';
    if (f.entry_id != undefined) {
        entry_id = '/' + f.entry_id;
    }
    var cols = column_types[top_mode];
    var selected = '';
    if (current_id == id) {
        selected = ' selectedRow ';
    }
    var up_votes = 0;
    var down_votes = 0;
    if (f['upvotes'] != undefined) {
        up_votes = f['upvotes'].length;
    }
    if (f['downvotes'] != undefined) {
        down_votes = f['downvotes'].length;
    }
    var overall = up_votes - down_votes;
    var extra = '';
    if (f.alertgroup_id != undefined) {
        extra = '/group';
    }
    var escaped_id = id;
    if(escaped_id.replace != undefined) {
       var escaped_id = escaped_id.replace('/', '_');
    }
    var tmpTr = $('<tr></tr>').attr('id', 'row_' + escaped_id).data('alertgroup', f['alertgroup_id']).addClass('table_row').addClass('alertgroup_'+f['alertgroup_id']).addClass(selected).click(function() {  window.location='/#/'+top_mode+extra+'/'+id+entry_id; });
    var aid = id;
    if(f['alertgroup_id'] != undefined) {
      aid = f['alertgroup_id'];
    }
    for (var i = 0; i < cols.length; i++) {
        var cellVal = f[cols[i]];
        if (cols[i] == 'status') {
            cellVal = color_status_cell(cellVal);
        } else if (date_cols.indexOf(cols[i]) >= 0) {
            var d = new Date(0);
            d.setUTCSeconds(cellVal + 0);
            cellVal = fullDateFormat(d);
        } else if (cols[i] == 'tags') {
	    if(cellVal instanceof Array) {
              cellVal = cellVal.join(', ');
	    }
        } else if (cols[i] == 'alertgroup_id') {
            if (cellVal == undefined) {
                cellVal = f['alert_id'];
            }
        } else if (cols[i] == 'viewcount') { // account for variety in server
            if (cellVal == undefined) {
		if(f['view_count'] != undefined) {
                  cellVal = f['view_count'];
		} else if (f['views'] != undefined) {
		  cellVal = f['views'];
		}
            }
        }
        var tmpTd = $('<td></td>').attr('id', aid + '_' + cols[i]).addClass(cols[i])
        if(cols[i] == 'status' ) {
            tmpTd.html(cellVal);
        }else  {
            tmpTd.text(cellVal);
        }
        //str += '<td id="' + aid + '_' + cols[i] + '" class="' + cols[i] + '" >' + cellVal + '</td>';
        tmpTr.append(tmpTd);
    }
    //str += '</tr>';
    //return str;
    return tmpTr;
}

// data = response
function grid_update_ajax_response(data, status, headers, config, start, initial_load, date_cols) {
    var cols = column_types[top_mode]; //Array of strings, names of columns

    //Clear out old results if not getting next page of results
    if (start == undefined) {
        $('#event_grid').html('');
    }

    //Load columns if they haven't already been
    if (initial_load == true) {
        initial_grid_load(cols, date_cols);
    }
    adjust_grid_header_widths(cols);
    //Populate the grid with results

    $(data.data).each(function(index, f) {
        var str = render_grid_row(f);
        var ren = $(str);
        if(isiOS) {
           $(ren).doubletap(fullscreen_content);
        }
        $('#event_grid').append(ren);
    });


    //Adjust UI layouts
    setTimeout("adjustTable()", 50);
    update_bottom_pane_height()

}

function loadIframe(obj) {
   // can't resize from inside iframe so see what size it needs
   resizeIframe(obj);
   // look for links and change external links to our confirmation page
    $(obj.contentDocument.body).find('a').each(function(index, link) {
       if($.isUrlExternal(link.href)) {
        $(link).attr('href', '/scot/confirm/'+btoa(link));
	    }
    });
    $(obj.contentDocument.body).find('a').attr('target', '_blank'); //Normal links will open in a new tab/window
    $(obj.contentDocument.body).append('<iframe id="targ" style="display:none;" name="targ"></iframe>'); //Entitites have an iframe to target.  Couldn't be in ancestor without allowing top navigation which is possibly dangerous
    $(obj.contentDocument.body).find('a').find('.entity').wrap("<a href='about:blank' target='targ'></a>");  //entities inside a link are wrapped in another link targeting an iframe in the parent that the browser security will not allow to navigate.  This prevents a click on the entity from opening the new link
}

function resizeIframe(iframe) {
   if(iframe.id == 'alert_html') {
      return;
   }
   // obj.contentWindow.document.body.height = obj.contentWindow.document.body.ScrollHeight+15;
    var hei = $(iframe.contentDocument.documentElement).height();
    var ifr = $(iframe);
    ifr.height( hei);
    ifr.parent().height(hei+5);
}

// click for more: when entry is big
function set_entry_overflow(obj, type) {
  if(type == 'button') {
    $(obj).find('.entry-body-inner').each(function(index, inner_body) {
      inner_body = $(inner_body);
      if(inner_body.height() >= 500) {
         if(inner_body.parent().find('.overflow').length == 0) {
               inner_body.parent().append('<center><div class="overflow" onclick="expand_entry(this)">Show More</div></center>');
         }
      } else {
         inner_body.parent().find('.overflow').parent().remove();
         inner_body.css('max-height', '500px');
      } 
        
        });
    }
}

// main important function... handles html of all entries
function render_entry(parent_id, entryin) {
        var entry = entryin;
        if (entry.task == undefined) {
            entry.task = {
                status: 'undefined'
            };
        }

        var draft = '';
        if (supports_html5_storage()) {
            if (localStorage[entry.entry_id] != undefined) {
                draft = ' entry_has_draft ';
            }
        }

        var entry_str = '<div class="row-fluid entry-outer ' + draft + '  todo_' + entry.task.status + '_outer " data-target-id="'+entry.target_id+'" data-entry-id="' + entry.entry_id + '" data-parent-id=' + parent_id + ' id="entry_' + entry.entry_id + '_outer" style="margin-left:auto; margin-right:auto; width:99.3%" >'
        entry_str = entry_str + '<div class="row-fluid entry-header todo_' + entry.task.status + '">';
        entry_str = entry_str + '<div class="entry-header-inner"> <span><span id="entry_' + entry.entry_id + '_status_text">  [<a style="color:black;" href="/#/event/'+entry.target_id+'/' + entry.entry_id + '">' + entry.entry_id + '</a>] ' + fullDateFormat(format_epoch(entry.when)) + ' by ' + entry.owner;
        if ((entry.task.who != undefined) && (entry.task.who != '')) {
            entry_str = entry_str + ' -- Task Owner ' + entry.task.who + ' ';
        }
        if (entry.updated != undefined) {
            entry_str = entry_str + ' (updated on ' + fullDateFormat(format_epoch(entry.updated)) + ')';
        }

        entry_str = entry_str + '</span><span class="pull-right btn-group entry_toolbar" id=' + entry.entry_id + '_toolbar>';
        entry_str = entry_str + '<input type="button" value="Cancel" style="display:none;" class="orange  when_editing" onclick="cancel_entry(\'' + entry.entry_id + '\')"></input>';
        entry_str = entry_str + '<input type="button" value="Save" style="display:none;" class="orange when_editing" onclick="save_entry(\'' + entry.entry_id + '\')"></input>';
        // entry_str = entry_str + '<input type="button" value="Full Screen" class="orange orange-left when_not_editing" onclick="fullscreen_entry(\'' + entry.entry_id + '\', this)" ></input>';
        entry_str = entry_str + '<input type="button" value="Edit" class="orange  when_not_editing" onclick="edit_entry(\'' + entry.entry_id + '\', this)" ></input>';
        entry_str = entry_str + '<input type="button" value="Reply" class="orange" onclick="reply_entry(\'' + entry.entry_id + '\')"></input>';
        entry_str = entry_str + '<input type="button" data-toggle="dropdown" onmousedown="prepareEntryDropdown(\'' + entry.entry_id + '\',this)" class="orange orange-right  nCaret"></input>';
        entry_str = entry_str + '<ul class="dropdown-menu" id="entry_' + entry.entry_id + '_dropdown">';
        entry_str = entry_str + '<li class="already_saved"><a onmousedown="prepare_move_entry()" onclick="move_entry(\'' + entry.entry_id + '\')">Move</a></li>';
        entry_str = entry_str + '<li class="already_saved"><a  onclick="delete_entry(\'' + entry.entry_id + '\')">Delete</a></li>';
        entry_str = entry_str + '<li class="already_saved"><a  onclick="make_summary(\'' + entry.entry_id + '\')">Mark as Summary</a></li>';
        entry_str = entry_str + '<li class="task_related already_saved when_completed"><a  onclick="update_task(\'' + entry.entry_id + '\', \'open\', \'\')">Reopen Task</a></li>';
        entry_str = entry_str + '<li class="task_related already_saved when_unassigned"><a  onclick="update_task(\'' + entry.entry_id + '\', \'open\')">Make Task</a></li>';
        entry_str = entry_str + '<li class="task_related already_saved when_open when_assigned"><a  onclick="update_task(\'' + entry.entry_id + '\', \'assigned\', \'me\')">Assign task to me</a></li>';
        entry_str = entry_str + '<li class="task_related already_saved when_open when_assigned"><a  onclick="update_task(\'' + entry.entry_id + '\', \'completed\')">Close Task</a></li>';
        entry_str = entry_str + '<li class="already_saved" ><a  onclick="toggle_entry_permissions(\'' + entry.entry_id + '\')">Permissions</a></li>';
        entry_str = entry_str + '</ul>';
        entry_str = entry_str + '</span>';
        entry_str = entry_str + '<span id="entry_' + entry.entry_id + '_permissions" class="entry_permissions" style="display:none;">&nbsp; &nbsp;Write Groups:<input class="entry_write" value="' + entry.modifygroups + '"></input>&nbsp;&nbsp;Read Groups:<input class="entry_read" value="' + entry.readgroups + '"></input> </span></span><span class="pull-right" style="padding-right:10px" id="entry_' + entry.entry_id + '_status"></span>';
        entry_str = entry_str + '</div></div><div class="row-fluid entry-body" id="entry_' + entry.entry_id + '_body" ondragexit="drop_noop(event)" ondragover="drop_noop(event)" ondragenter="drop_noop(event)" ondrop="dropped_on_entry(event, this)"  >';
        entry_str = entry_str + '<div class="entry-body-inner" id="entry_' + entry.entry_id + '_inner" onmouseup="saveSelection(this)" onkeyup="saveSelection(this)" ';
        entry_str = entry_str + '>';
        entry_str = entry_str + '</div>';
        entry_str = entry_str + '</div></div></div></div>';
        var entry_dom = $(entry_str);
        var edt = entry.open_editable ? 'true' : 'false';
        var ifr = $('<iframe style="width:100%;" frameborder="0" onload="javasript:loadIframe(this);" sandbox="allow-popups allow-same-origin"></iframe>').attr('srcdoc', '<link rel="stylesheet" type="text/css" href="sandbox.css"></link><body contenteditable="'+ edt + '">' + entry.body_flaired + '</body>');
        if (entry.open_editable) {
    //        $(ifr).contents().find('body').prop('contenteditable', true);
        }


        $(entry_dom).find('.entry-body-inner').append(ifr);

        if (entry.children) {
            for (var i = 0; i < entry.children.length; i++) {
                $(entry_dom).append(render_entry(entry.entry_id, entry.children[i]));
            }
        }

        return entry_dom;
}

    //library
    jQuery.fn.center = function() {
        this.css("position", "absolute");
        this.css("top", Math.max(0, (($(window).height() - $(this).outerHeight()) / 2) +
            $(window).scrollTop()) + "px");
        this.css("left", Math.max(0, (($(window).width() - $(this).outerWidth()) / 2) +
            $(window).scrollLeft()) + "px");
        return this;
    }

    //library
    function showLoadingGif() {
        $('#BottomPane').append('<img id="loadingGif" style="width:100px; height:100px;" src="loading.gif"></img>');
        $('#loadingGif').center();
        $('#BottomPane').hide();
        $('#BottomPane').show();
    }
    var prev_cmd_tag = '';

    // called on ready
    function populate_tags(tags) {
        $("#event_tags2").val(tags);
        $("#event_tags2").select2({
            tags: ['lazyLoadTags'],
            tokenSeparators: [",", " "]
        });

        $("#read_permissions").on("change", function(e) {
            var read = $("#read_permissions").select2('val');
            update_event({
                readgroups: read
            });
        });

        // TODO: need to change to update_neutral when Intel is added
        $("#write_permissions").on("change", function(e) {
            var write = $("#write_permissions").select2('val');
            update_event({
                modifygroups: write
            });
        });

        $("#event_source2").on("change", function(e) {
            var sources = $("#event_source2").select2('val');
            update_neutral({
                sources: sources
            });
        });
        $("#event_tags2").on("change", function(e) {
            var tag_text = '';
            var cmd = '';
            if (e.added != undefined) {
                tag_text = $.trim(e.added.text);
                cmd = 'addtag';
            } else if (e.removed != undefined) {
                tag_text = e.removed.text;
                cmd = 'rmtag';
            } else {
                return;
            }
            var cmd_tag = cmd + tag_text;
            if (prev_cmd_tag != cmd_tag) {
                update_neutral({
                    cmd: cmd,
                    tags: [tag_text]
                });
                prev_cmd_tag = cmd_tag;
            }

        });
    }

    //no longer used, but useful for future
    function render_alert_body_vert(entry) {
        var keys = Object.keys(entry);
        var result = $('<div class="alertTable"></div>')
        $(keys).each(function(index, key) {
            var value = entry[key];
            $(result).append('<div><span>' + key + '</span><span>' + value + '</span></div>');
        });
        if ($.cookie("vertical") == 1) {
            $(result).show();
        } else {
            $(result).hide();
        }
        return result;
    }

    function render_alert_body_html(alerts, entries, flairdata) {
        var content = alerts[0].data_with_flair.alert;
        content += '<link rel="stylesheet" type="text/css" href="sandbox.css"></link>';
        var ifr = $('<iframe id="alert_html" sandbox="allow-same-origin" style="overflow-y:hidden; border:0px solid transparent;  width:100%;"></iframe>').attr('srcdoc', content);
        $(ifr).data('alert_id', alerts[0].alert_id);
        pentry(ifr, flairdata); // pentry should be named "entry ready"

        return ifr;
    }

    function render_alert_body(entries, real_entries) {

        if (!(entries instanceof Array)) {
            entries = new Array(entries);
        }

        var result = $('<div class="tablesorter alertTableHorizontal"></div>');
        var table = $('<table width="100%"></table>');
        var thead = $('<thead></thead>');
        var tbody = $('<tbody></tbody>');
        var theadrow = $('<tr></tr>');
        table.append(thead);
        thead.append(theadrow);
        var col_names = entries[0].columns.slice(0); //slice forces a copy of array
        col_names.unshift('status'); //Add status to front
        $(col_names).each(function(keyNum, key) {
            var key = $('<th></th>').text(key);
            key.dblclick(function() {
                var index = $(this).parent().children().index($(this));
                $(tbody).find('tr').each(function(rowNum, row) {
                    var cell = $($(row).find('td,th')[index]);
                    if (cell.attr('nowrap') == "") {
                        cell.removeAttr('nowrap');
                    } else {
                        cell.attr('nowrap', '');
                    }

                });
            });
            key.click(function() {
                //Put sort code here
            });
            theadrow.append(key);
        });

        // experimetal
        var valColor = new Object();
        var valCount = new Object();

        for (var i = 0; i < entries.length; i++) {
            var tbodyrow = $('<tr id="alert_'+entries[i].alert_id+'_row"></tr>');
            var data = entries[i].data_with_flair;
            var keys = entries[0].columns;
        tbodyrow.data('alert_id', entries[i].alert_id);
        pre_status = '';
        post_status = '';
        if(entries[i].status == 'promoted') {
        if(entries[i].events != undefined && entries[i].events.length > 0) {
            var promoted_event = entries[i].events[0];
            pre_status = '<button type="button" onclick="window.location=\'#/event/'+promoted_event+'\'" class="btn btn-mini">';
            post_status = '</button>';
        }
        }
        var entries_string = '';
        if(real_entries != undefined && real_entries.length > 0) {
        $(real_entries).each(function(index, real_entry) {
            if(real_entry.target_type == 'alert' && real_entry.target_id == entries[i].alert_id) {
        entries_string += render_entry(0, real_entry);
            }
        });
        }
        var aa = $('<td valign="top" style="margin-right:4px;"></td>').html('<div class="alert_data_cell" id="alert_'+ entries[i].alert_id + '_status"><b>'+pre_status + color_status_cell( entries[i].status) + post_status + '</b></div>');
        tbodyrow.append(aa);
            $(keys).each(function(keyNum, key) {
                var value = data[key] + "";
                if (valCount[value] == undefined) {
                    valCount[value] = 1;
                } else {
                    valCount[value] += 1;
                }
                value = value.replace(/\n/g, '<br />');
                var tmp = $('<td valign="top" style="margin-right:4px;"></td>').html('<div class="alert_data_cell">' + value + '</div>');
                tbodyrow.append(tmp);
            });
            tbody.append(tbodyrow);
        tbody.append('<tr class="not_selectable"><td></td><td colspan="50">'+entries_string+'</td></tr>');
        }
        table.append(tbody);
        result.append(table);
        if(entries[0] != undefined && entries[0].data != undefined && entries[0].data.search != undefined) {
        var search = $('<div class="alertTableHorizontal"></div>').text('plunk Search: '+entries[0].data.search);
        result.after(search);
        }
        if (($.cookie("vertical") == 1) && (alert_mode != 'alertgroup')) {
            $(result).hide();
        }
        return result;
    }

    function unBold() {
        $('#viewed_by').find('a').each(function(index, username) {
            var last_access_int = $(username).data('last-access');
            var last_access = new Date(0);
            last_access.setUTCSeconds(last_access_int);
            var now = new Date();
            if ((now - last_access) > 60000) {
                $(username).css('font-weight', 'normal');
            }
        });
    }


    function format_title(obj) {
        var user = $(obj);
        var last_access_int = $(user).data('last-access');
        var last_access = new Date(0);
        last_access.setUTCSeconds(last_access_int);
        if (last_access > 50) {
            var ago = jQuery.timeago(last_access);
            $(user).attr('title', ago);
        }
    }

    function format_viewers(viewed_by) {
        var viewers = Object.keys(viewed_by);
        var color_viewers = new Array();
        $(viewers).each(function(index, username) {
            var last_access_int = viewed_by[username]['when'] + 0;
            var last_access = new Date(0);
            last_access.setUTCSeconds(last_access_int);
            var now = new Date();
            if ((now - last_access) < 60000) {
                color_viewers.push('<a data-toggle="tooltip" style="color:inherit" onmouseover="format_title(this)"  data-last-access="' + last_access_int + '"><b>' + username + '</b><a>');
            } else {
                color_viewers.push('<a data-toggle="tooltip" style="color:inherit" onmouseover="format_title(this)" data-last-access="' + last_access_int + '">' + username + '</a>');
            }
        });

        return color_viewers.join(', ');
    }

    var ajaxPreview;
    var ajaxPreviewHelper;

    function entity_click(event) {
        event.stopPropagation();
        event.preventDefault();
        infopop(this);
    }


    //similar to pentry
    // extracts entity spans and allows clicks inside iframe
    function handle_entity(entity, flairdata, bindclick) {
                        var entity_type = $(entity).data('entity-type');
                        var entity_value = $(entity).data('entity-value');
                        // #event_id is legacy, could be called just id 
                        var id = $('#event_id').html();
                        $(entity).unbind('click');
                if(bindclick) {
                        entity.onclick = entity_click;
                }
                        if (flairdata != undefined && flairdata[entity_value] != undefined) {
                            if (flairdata[entity_value].block_data != undefined && flairdata[entity_value].block_data.type != undefined) {
                                // append image to span
                                var type = flairdata[entity_value].block_data.type;
                    if(type != 'allowed' && type != 'whitelist') {
                                $(entity).append('<img class="noselect" src="/images/flair/'+type+'.png"></img>');
                    }
                            }
                            ref_text = '';
                            var types = ['event', 'alert']; // TODO: , 'intel'
                            $(types).each(function(index, type) {
                                if (flairdata[entity_type] != undefined && flairdata[entity_type][type + 's'] != undefined) {
                                    flairdata[entity_value][type + 's'].each(function(index, item) {
                                        ref_text += type + ': ' + item[type + '_id'] + ' - ' + item.subject;
                                    });
                                }
                            });
                            var reference_count = (flairdata[entity_value].alerts_count + flairdata[entity_value].events_count + flairdata[entity_value].intel_count);
                            if (reference_count > 1) {
                                // noselect prevents copying in copy paste 
                                var circle = $('<span class="noselect">').attr('alt', ref_text).attr('title', ref_text);
                                circle.addClass('circleNumber');
                    circle.addClass('extras');
                                circle.text(reference_count);
                                $(entity).append(circle);
                            }
                            var notes = flairdata[entity_value].notes;
                            if (notes != undefined && Object.keys(notes).length > 0) {
                                var note_data = '';
                                $(Object.keys(notes)).each(function(index, note_author) {
                                    note_data += note_author + ': ' + notes[note_author] + '\n';
                                });
                                var note = $('<img class="noselect">').attr('src', '/images/note.gif');
                    note.addClass('extras');
                                note.attr('title', note_data).attr('alt', note_data);
                                note.click(function(e) {
                                    add_notes()
                                });
                                $(entity).append(note);
                            }
                            if (entity_type == 'ipaddr' || entity_type == 'domain') {

                                if (flairdata[entity_value] != undefined) {
                                    if (flairdata[entity_value].geo_data != undefined && flairdata[entity_value].geo_data.country_code != undefined) {
                                        var country_code = flairdata[entity_value].geo_data.country_code;
                                        var flag = $('<img class="noselect">').attr('src', '/images/flags/' + country_code.toLowerCase() + '.png');
                        flag.addClass('extras');
                                        $(entity).append(flag);
                                    }
                                    if (flairdata[entity_value].reputation != undefined) {
                                        $(entity).append('<img class="extras" src="/images/bug.png"></img>');
                                    }
                                }
                            }
                        }
                    }


    function updateSecondMenuStatus(dt) {
    if( !(parsed) ||  dt.finderSelect('selected').length > 0) {
        $('.alert_checked').show();
        } else {
        $('.alert_checked').hide();
        }
    if(!parsed) {
        $('.alert_parsed').hide();

    }
    }

    // green alert grid details highlighting stuff
    function enableDataRowSelection() {
    var dt = $('#BottomPane').find('tbody');
    if(dt.length  == 0) {
        updateSecondMenuStatus();
        return;
    }
    dt.finderSelect();
    $('#BottomPane').click(function(e) {
        if($(e.target).closest('.alertTableHorizontal').length <= 0) { //If you didn't click on the data table
        dt.finderSelect('unHighlightAll');
        }
        updateSecondMenuStatus(dt);
    });
    dt.finderSelect('addHook', 'highlight:after', function(el) {
        updateSecondMenuStatus(dt);
        });
    }

    //library
    function findPos(obj) {
        var curleft = curtop = 0;
        if (obj.offsetParent) {
            do {
                curleft += obj.offsetLeft;
                curtop += obj.offsetTop;
            }
            while (obj = obj.offsetParent);
            return [curleft, curtop];
        }
    }


    //library
    // find the position of item
    function findPosRelativeToViewport(obj) {
        var pos= findPos(obj);
        //var root= document.compatMode=='BackCompat'? document.body : document.documentElement;
        var root = $(obj).closest('html')[0];
        pos = pos[1] - root.scrollTop;
        return pos;
    }


    // due to iframe can't just bind a click on an entity
    // so look for color change (that css allows in iframe)
    // when we see red, the user clicked

    function checkFlairHover(iframe) {
    if(iframe.contentDocument != null) {
        $(iframe).contents().find('.entity').each(function(index, entity) {
            if($(entity).css('background-color') == 'rgb(255, 0, 0)') {
            $(entity).data('state', 'down');
            } else if($(entity).data('state') == 'down') {
            $(entity).data('state', 'up');
            var ba = $('#BottomPane').offset().top;
            var vaa = findPosRelativeToViewport(entity);

            var tmp = $(entity).get(0);
            // where to create popup
            var height = ($(tmp).height() / 2);
            var left = $(tmp).width() + $(entity).offset().left;
            //while($(tmp).parent().size() > 0) {
            //   height += $(tmp).offset().top;
            //   left += $(tmp).offset().left;
            //   tmp = $(tmp).parent();
            // }
            height += $(entity).offset().top; //nrp test
            height += $(iframe).offset().top;
            left   += $(iframe).offset().left;

            infopop(entity, undefined, left, height, iframe);
            }

        });
        // detect clicks outside of entity popup and clear popup
        var iframebg = $(iframe.contentDocument.body).css('background-color');
        if((iframebg != "rgba(0, 0, 0, 0)") && (iframebg != 'transparent')) {
            $('.qtip').remove();
       }
       resizeIframe(iframe);
       saveSelection(iframe, iframe.contentWindow);
       }
    }


// big function that does lots
// called on every iframe after initial load /and or change

function pentry(ifr, flairdata) {
    $(ifr).find('iframe').addBack('iframe').load(function() {
        var iframe = this;
        var ext = ($('#BottomPane').width() - $(iframe.contentDocument.body).width()) < 200 && bottom_mode == 'alert' ? 20 : 0;
        $(iframe).height($(iframe.contentDocument.documentElement).height() + ext);
        $(iframe).parent().height($(iframe.contentDocument.documentElement).height()+5 );
        $(iframe).mouseenter(function() {
        var intervalID = setInterval(checkFlairHover, 100, iframe);
        $(iframe).data('intervalID', intervalID);
        console.log('Now watching iframe ' + intervalID);
        });
            $(iframe).mouseleave(function() {
            var intervalID = $(this).data('intervalID');
            window.clearInterval(intervalID);
            console.log('No longer watching iframe ' + intervalID);
            });

            $(iframe.contentDocument.body).find('.entity').each(function(index, entity) {
                handle_entity(entity, flairdata);
            });

            set_entry_overflow($(iframe).parent().parent(), 'button');
    });
}


    function display_entries(entries, summary_entry_id, flairdata) {
            var BottomPane = $('#BottomPane');
            var entr = '';
                        for (var i = 0; i < entries.length; i++) {
                //TODO: For speeding up initial load of large events, could only display top 10, and use scroll position detection to append an iframe as it comes into position.
                    var ifr = render_entry(i, entries[i]);
                //var ifr = $('<iframe sandbox=""></iframe>').attr('srcdoc', untrusted_entry_text);
                pentry(ifr, flairdata);
                BottomPane.append(ifr);
                        }
            process_entries(entries, summary_entry_id, flairdata);
    }

    function render_history_entry(history_entry, context) {
        var dateTime = fullDateFormat(format_epoch(history_entry.when));
        var history_div = $('<div></div>');
        var context_str = '';
        if(context.event_id != undefined) {
            context_str = 'Event ' + context.event_id;
        }else if(context.entry_id != undefined) {
            context_str = 'Entry ' + context.entry_id;
        }else if(context.alert_id != undefined) {
            context_str = 'Alert ' + context.alert_id;
        }
        history_div.text(context_str + ' - ' + dateTime + ' - ' + history_entry.who + ' - ' + history_entry.what);
        return history_div;
    }

    function append_history(response) {
    var result = $('<div></div>');
    if(response != undefined && response.data != undefined && response.data.history != undefined) {
        $(response.data.history).each(function(index, history_entry) {
                $(result).append(render_history_entry(history_entry, response.data));
        });
    }
    if(response != undefined && response.data != undefined && response.data.alerts != undefined) {
        $(response.data.alerts).each(function(index, alert) {
            if(alert.history != undefined) {
                $(alert.history).each(function(index2, history_alert) {
                    $(result).append(render_history_entry(history_alert, alert));
                });
            }
        });
    }if(response != undefined && response.data != undefined && response.data.entries != undefined) {
        $(response.data.entries).each(function(index, entry) {
            if(entry.history != undefined) {
                $(entry.history).each(function(index2, history_entry) {
                    $(result).append(render_history_entry(history_entry, entry));
                });
            }
        });
    }
    return result;
    }

    function process_entries(entries, summary_entry_id, flairdata) {
    /*                 $("#BottomPane").find("a:urlExternal").click(function(event) {
                        event.preventDefault();
                        var to = $(this).attr('href');
                        $("#external_site_modal").data('url', to);
                        $("#external_site_modal").modal('show');

                    });
    */
            var entities = new Array();
            $('iframe').each(function(index, iframe) {
            set_entry_overflow($(iframe).parent().parent(), 'button');

            $(iframe.contentDocument.body).find('.entity').each(function(entityIdx, entity) {
                handle_entity(entity, flairdata);
            });
            });
            $('.entity').each(function(entityIdx, entity) {
                handle_entity(entity, flairdata, true);
            });
           

            //var entities = $('#BottomPane').find('.entity');
            //for(var i=0; i<entities.length; i++) {
            //   handle_entity(entities[i], flairdata);
        //	}

        /*	$('.entry_has_draft').each(function(index, entry_d) {
                        var entry_id = $(entry_d).data('entry-id');
                        restore_draft(entry_id);
                    });
        */
                if(summary_entry_id != undefined) {
            move_entry_to_summary_position(summary_entry_id);
            }

    }


    // kind of main()
    function preview(type, id, entry_id) {

        globalFlairState = true;    // turning flair on or off for a thing
        alert_mode = type;
        editing_reference_count = 0;
        current_id = id;
        try {
            ajaxPreview.abort();    // aborts previous ajax call and load 
        } catch (e) {}
        try {
            ajaxPreviewHelper.abort();
        } catch (e) {}
        if($('#event_id').html() == current_id && previous_type == bottom_mode) {
        $('#BottomPane').scrollTo($('#entry_' + entry_id + '_outer'), 500); // take you directly to entry
        return 0;
        }
        if($('#edit_toolbar:visible').length>0) {
            if(!confirm('You have unsaved entries, and if you continue they may be lost.  Continue?')) {
                window.history.back();
                return -1;
            }
        }

        var title = type.charAt(0) + '-' + id;
        window.document.title = title.charAt(0).toUpperCase() + title.slice(1);
        $('#BottomPane').empty();
        $('#edit_toolbar').hide();
        $('#checklist_toolbar').hide();
        $('#move_entry_toolbar').hide();
        $('.selectedRow').removeClass('selectedRow');
        $('#row_'+type+'_' + id).addClass('selectedRow');
        $('#row_' + id).addClass('selectedRow');
        if($('#row_'+id).length > 0) {
        $('#row_'+id).scrollMinimal(true);
        }
        var alertgroup = $('#row_' + id).data('alertgroup');

        if ($('#loadingGif').size() == 0) {
            showLoadingGif();
        }

        if (type == 'alertgroup') {
            ajaxPreviewHelper = $.ajax({
                type: 'GET',
                url: '/scot/alertgroup/refresh/' + id
            }).done(function(response) {
                $('#event_id').text(response.data.alertgroup_id);
                $('#event_status').text(response.data.status);
                $('#subjectEditor').val(response.data.subject);
                sizeInput($('#subjectEditor').get(0));
            window.document.title = window.document.title + '-' + response.data.subject;
                populate_tags(response.data.tags);
                $('#event_source2').select2('val', response.data.sources);
            $('#viewed_by').html(format_viewers(response.data.viewed_by));
            });
        }

        currentApiUrl = '/scot/' + type + '/' + id;
        ajaxPreview = $.ajax({
            type: 'GET',
            url: currentApiUrl,
            data: {
                columns: [
                    "status",
                    "tags",
                    "modifygroups",
                    "readgroups",
                    "source",
                    "alertgroup_id",
                    "subject",
                    "alert_id",
                    "views",
                    "data",
                ]
            },
            success: function(data, status, headers, config) {
                var BottomPane = $('#BottomPane');
                BottomPane.empty();
                var contents;
                if (data.status == "ok") {
                    if (type == "event" || type == "intel") {
                    $.ajax({
                        type: 'GET',
                        url:  '/scot/viewed/'+ type + '/' + get_id_from_obj(data.data),
                    }).done(function() {
                if(console != undefined) {
                            console.log('view logged for ' + type + ' ' + get_id_from_obj(data.data));
                }
                    });
                        $('#event_id').text(get_id_from_obj(data.data));
                        $('#subjectEditor').val(data.data.subject);
                        sizeInput($('#subjectEditor').get(0));

                    window.document.title = window.document.title + '-' + data.data.subject;
                        $('#event_owner').text(data.data.owner);
                        $('#event_status').text(data.data.status);
                        populate_tags(data.data.tags);
                        $('#write_permissions').val(data.data.modifygroups);
                        $('#read_permissions').val(data.data.readgroups);
                        $('#event_source2').select2('val', data.data.sources);
                var previous_aid = -1;
                var range_start  = -1;
                var ranges = new Array();
                        if(data.data.alerts != undefined) {
                for(var k=0;k<data.data.alerts.length;k++) {
                    var aid = parseInt(data.data.alerts[k]);
                    if(((previous_aid+1) != aid) || (k >= data.data.alerts.length -1) ) {
                    if(range_start > -1) {
                        if(previous_aid > range_start) {
                        ranges.push(range_start + '-' + previous_aid);
                    } else {
                        ranges.push(previous_aid);
                    }
                    } else if(data.data.alerts.length == 1) {
                    ranges.push(aid);
                    }
                        range_start = aid;
                    }
                    previous_aid = aid;
                }
                        }
                        for(var l=0; l<ranges.length; l++) {
                        var rgs = (""+ranges[l]).split('-');
                        ranges[l] = '<a href="#/alert/'+rgs[0]+'">' + ranges[l] + '</a>';
                        }
                $('#linked_alerts').select2('val', ranges);
                        $('#linked_alerts').select2('link', alert);
                try {
                        if (data.data.alerts.length <= 0) {
                            $('#linked_alerts').data('select2').container.parent().hide();
                            $('#linked_alerts_title').hide();
                        } else {
                            $('#linked_alerts').data('select2').container.parent().show();
                            $('#linked_alerts_title').show();
                        }
                } catch(e) {
                    if(console != undefined) {
                    console.log('trouble with select2 module showing linked alerts');
                }
                }
                        if(data.data.incidents != undefined && data.data.incidents.length > 0) {
                        $('#linked_incidents').text(data.data.incidents.join(', '));
                        $('#linked_incidents_title').show();
                        $('#linked_incidents').show();
                        } else {
                        $('#linked_incidents_title').hide();
                        $('#linked_incidents').hide();
                        }
                    display_entries(data.data.entries, data.data.summary_entry_id, data.data.flairdata);
            } else if (type == "alertgroup") {
                        $.ajax({
                            type: 'GET',
                            url:  '/scot/viewed/alertgroup/'+ id,
                        }).done(function() {
                    if(console != undefined) {
                            console.log('view logged');
                }
                        });

                    contents = $('<div></div>');
                    $('#viewSource').data('html', data.data.body_html);
                    $('#viewSource').data('plain', data.data.body_plain);
                        guide_id = data.data.alerts[0].guide_id;
                parsed = data.data.parsed;;
                if(parsed) {
                        contents.append(render_alert_body(data.data.alerts, data.data.entries));
                } else {
                    contents.append(render_alert_body_html(data.data.alerts, data.data.entries, data.data.flairdata));
                }
                        $('#BottomPane').append(contents);
                        $('#write_permissions').val(data.data.modifygroups);
                        $('#read_permissions').val(data.data.readgroups);
                enableDataRowSelection();
                    process_entries(data.data.entries, data.data.summary_entry_id, data.data.flairdata);
    //		    setInterval(100, checkFlairHoverParsed);
                    }
                    append_history(data);
                } else if (data.status == "fail") {
                    showBottomPaneNotAuthorized();
                }

                if (entry_id != undefined && entry_id != '') {
                    $('#BottomPane').scrollTo($('#entry_' + entry_id + '_outer'), 500);
                }

            $('.alertTableHorizontal').find('table').tablesorter();
            },
            error: function(event, xhr) {
                if (xhr == 'abort') {

                } else {
                    showBottomPaneError();
                }
            }
        });
    }

    function visit_site_confirmed(dialog) {
        var url_to_open = $('#external_site_modal').data('url');
        window.open(url_to_open, '_blank');
    }

    function toolbarButtonVisibility(entry_id, isEditing) {
        var toolbar_buttons = $('#' + entry_id + '_toolbar').find('input');
        var editing_buttons = toolbar_buttons.filter('.when_editing');
        var non_editing_buttons = toolbar_buttons.filter('.when_not_editing');
        if (isEditing) {
            editing_buttons.show();
            non_editing_buttons.hide();
            $('#edit_toolbar').show();
            editing_reference_count++;
        } else {
            editing_buttons.hide();
            non_editing_buttons.show();
            editing_reference_count--;
            if (editing_reference_count < 0) {
                editing_reference_count = 0;
            }
            if (editing_reference_count == 0) {
                $('#edit_toolbar').hide();
            }
        }
        var visible_buttons = toolbar_buttons.filter(function(index) {
            return this.style.display != 'none'
        });
        toolbar_buttons.removeClass('orange-left');
        toolbar_buttons.removeClass('orange-right');
        $(visible_buttons[0]).addClass('orange-left');
        $(visible_buttons).last().addClass('orange-right');
    }
    var notSavedCounter = 0;

    function reply_entry(entry_id) {
        if (!isInt(entry_id)) {
            alert('You must save this entry before you can reply to it');

            return;
        }
        var curr = new Date();
        var epoch = curr.getTime() / 1000;
        var new_entry_id = 'Not_Saved_' + notSavedCounter;
        var new_entry_html = render_entry(entry_id, {
            entry_id: new_entry_id,
            owner: 'You',
            body_flaired: '&nbsp;',
            when: epoch,
            text: '',
            open_editable: true,
            task: {
                "status": ""
            }
        });
        var new_entry_id = $(new_entry_html).data('entry-id');
        $('#entry_' + entry_id + '_body').append(new_entry_html);

        var target_id = $('#entry_'+entry_id+'_outer').data('target-id');
        $('#entry_'+new_entry_id+'_outer').data('ids', target_id);
        $('#BottomPane').scrollTo($('#entry_'+new_entry_id+'_outer'), 500);
        toolbarButtonVisibility(new_entry_id, true);
        notSavedCounter++;
        pentry($('#entry_'+new_entry_id+'_body'));
        $('#entry_'+new_entry_id+'_inner').focus();
    }

    function prepare_move_entry() {
        $('#destinationPicker').html('<option value="INVALID">---Choose Destionation Event---</option>');
        $.ajax({
            type: 'GET',
            url: '/scot/event/',
        }).success(function(response) {
            $.each(response.data, function(key, val) {
                $('#destinationPicker').append(
                    $("<option></option>", {
                        'value': val.event_id,
                        'text': val.event_id + ' - ' + val.subject,
                    })
                );
            });
        });

    }

    function move_entry(entry_id) {
        $('#entryToMove').text(entry_id);
        $('#move_entry_toolbar').show();

    }

    function delete_incident() {
        var incident_id = $('#event_id').text();
        $("#delete_incident_modal").attr('data-incident-id', incident_id);
        $("#delete_incident_modal").modal('show');
    }

    function delete_alert() {
        var alert_id = $('#event_id').text();
        $("#delete_alert_modal").attr('data-alert-id', alert_id);
        $("#delete_alert_modal").modal('show');
    }

    function delete_event() {
        var event_id = $('#event_id').text();
        $("#delete_event_modal").attr('data-event-id', event_id);
        $("#delete_event_modal").modal('show');
    }

    function delete_alert_confirmed(dialog) {
        var ids = $('#delete_alert_modal').attr('data-alert-ids');
        multiple_alerts('delete', $('#delete_alerts')[0]);
    }

    function delete_incident_confirmed(dialog) {
        var incident_id_to_delete = $('#delete_incident_modal').attr('data-incident-id');
        $.ajax({
            type: 'DELETE',
            url: '/scot/incident/' + incident_id_to_delete
        });
    }
    function delete_event_confirmed(dialog) {
        var event_id_to_delete = $('#delete_event_modal').attr('data-event-id');
        $.ajax({
            type: 'DELETE',
            url: '/scot/event/' + event_id_to_delete
        });
    }

    function delete_entry(entry_id) {
        $("#delete_modal").attr('data-entry-id', entry_id);
        $("#delete_modal").modal('show');
    }

    function delete_entry_confirmed(dialog) {
        var entry_id_to_delete = $('#delete_modal').attr('data-entry-id');
        $.ajax({
            type: 'DELETE',
            url: '/scot/entry/' + entry_id_to_delete
        });
    }

    function prepareEntryDropdown(entry_id, entry_dropdown) {
        var dropdown_children = $('#entry_' + entry_id + '_dropdown').children('li');
        var entry_classes = $('#entry_' + entry_id + '_outer').attr('class').split(/\s+/);
        $('.already_saved').show();
        dropdown_children.filter('.task_related').hide();
        if (isInt(entry_id)) {
        if (entry_classes.indexOf('todo_completed_outer') >= 0) {
            dropdown_children.filter('.when_completed').show();
        } else if (entry_classes.indexOf('todo_assigned_outer') >= 0) {
            dropdown_children.filter('.when_assigned').show();
        } else if (entry_classes.indexOf('todo_open_outer') >= 0) {
            dropdown_children.filter('.when_open').show();
        }else {
            dropdown_children.filter('.when_unassigned').show();
        }
        } else {
        $('.already_saved').hide();
        }
    }


    function supports_html5_storage() {
        try {
            return 'localStorage' in window && window['localStorage'] !== null;
        } catch (e) {
            return false;
        }
    }


    function save_draft(entry_inner, entry_id) {
        if (!supports_html5_storage()) {
            return -1;
        }
        localStorage.setItem(entry_id, $(entry_inner).html());
    }

    function edit_entry(entry_id, button) {
        $.ajax({
            type: 'GET',
            url: '/scot/entry/' + entry_id + '?type=event',
        }).done(function(data) {
            toolbarButtonVisibility(entry_id, true);
            var entry_inner = $('#entry_' + entry_id + '_inner');
            entry_inner.data('origional', entry_inner.find('iframe').contents().find('body').html()); //bind origional HTML to the entry's inner element
            var entry_iframe = $(entry_inner).find('iframe')[0].contentDocument;
            entry_iframe.body.innerHTML = data.data.body;
            $(entry_iframe.body).attr('contenteditable', true);
            entry_inner.keyup($.debounce(250, function() {
                save_draft(entry_inner, entry_id)
            }));
            saveSelection(entry_inner, $(entry_inner).find('iframe')[0].contentWindow);
            entry_inner.focus();
            resizeIframe($(entry_inner).find('iframe').first());
        }).fail(function(stuff) {
            alert('Error retrieving non-flaired entry, which we need before you can edit an entry.  Go tell a SCOT admin to fix their stuff!');
        });
    }

    function closeEntityToolbar() {
        $("#entity_toolbar").hide();
    }

    function closePermissionsToolbar() {
        $('#permissions_toolbar').hide();
    }

    function openPermissionsToolbar() {
        $('#permissions_toolbar').show();
        $('#read_permissions').select2({
            tags: ['lazyLoadGroups']
        });
        $('#write_permissions').select2({
            tags: ['lazyLoadGroups']
        });
    }

    function openChecklistToolbar() {
        var ct = $('#checklist_toolbar_options');
        ct.html('');
        $.ajax({
            type: 'GET',
            url: '/scot/checklist',
        }).done(function(data, textStatus, jqXHR) {
            $('#checklist_toolbar_options').html('<option>-- Choose Checklist to Add --</option>');
            for (var i = 0; i < data.data.length; i++) {
                var subject = data.data[i].checklist_subject;
                var checklist_id = data.data[i].checklist_id;
                $('#checklist_toolbar_options').append('<option value="' + checklist_id + '">' + subject + '</option>');
            }
            $('#checklist_toolbar').show();
        });
    }

    function clearStatus(entry_id) {
        $('#entry_' + entry_id + '_status').fadeOut('slow', function() {
            $(this).html('');
            $(this).fadeIn('slow');

        });
    }

    function save_entry(entry_id) {
        $('#entry_' + entry_id + '_status').html('<img src="loading.gif" style="width:20px; height:20px"></img>Saving');
        var parent_id = $('#entry_' + entry_id + '_outer').attr('data-parent-id');

        var ajaxType;
        var ajaxProcessData;
        var ajaxUrl;
        var ajaxData;
        var entry_obj = $('#entry_' + entry_id + '_inner');
        if (entry_obj.find('iframe').first().data('isHtml') == 1) {
            entry_obj.find('iframe').first().contents().find('body')[0].innerHTML = $(entry_obj).find('iframe').first().contents().find('body').text();
            entry_obj.find('iframe').first().contents().find('body').prop('contenteditable', false);
            entry_obj.find('iframe').first().data('isHtml', 0);
        }

        var entry_contents = $('#entry_' + entry_id + '_inner').find('iframe').first().contents().find('body').html();
    //    var entry_contents = $('#entry_' + entry_id + '_inner').html();

        if (!isInt(entry_id)) { //If this is a new entry that hasn't been saved
            ajaxType = 'POST';
            ajaxUrl = '/scot/entry';
            ajaxProcessData = true;
            var entry_type = bottom_mode;
            ajaxData = {
                body: entry_contents,
                target_type: entry_type,
                parent: parent_id,
                readgroups: default_read_groups(),
                modifygroups: default_modify_groups(),
            };

        } else { //update to an existing entry

            ajaxType = 'PUT';
            ajaxUrl = '/scot/entry/' + entry_id;
            ajaxProcessData = false;
            ajaxData = {
                body: entry_contents
            };

        }

        var failureMessage = "Error: Couldn't save your changes to this event, please try again";
        var id = $('#entry_'+entry_id+'_outer').data('ids');
        if(id != undefined) {
            ajaxData['target_id'] = id;
        }
            $.ajax({
            type: ajaxType,
            processData: ajaxProcessData,
            url: ajaxUrl,
            data: JSON.stringify(ajaxData)
            }).done(function(data, textStatus, jqXHR) {
            if (data.id != undefined) {
                $('#entry_'+entry_id+'_outer').data('id', data.id).addClass('saving');
                        if($('#entry_'+data.id+'_outer').length > 0) {
                        $('#entry_'+entry_id+'_outer').remove();
                        }
            }
            $('#entry_' + entry_id + '_status').html('Saved ' + formatAMPM(new Date()));
            toolbarButtonVisibility(entry_id, false);
            var entry_inner = $('#entry_' + entry_id + '_inner');
            setTimeout('clearStatus("' + entry_id + '")', 10000);
            entry_inner.find('iframe').contents().first().find('body').removeAttr('contenteditable');
            if (supports_html5_storage()) {
                localStorage.removeItem(entry_id);
            }
            }).fail(function(jqXHR, textStatus, errorThrown) {
            $('#entry_' + entry_id + '_status').html('<b>Unable to save</b> ' + formatAMPM(new Date()));
            setTimeout('clearStatus("' + entry_id + '")', 10000);
            alert(failureMessage);
            });

    }

    function moveEntryConfirmed() {
        var entry_id = $('#entryToMove').html();
        var destination_event_id = parseInt($('#destinationPicker option:selected').val());
        $.ajax({
            type: 'PUT',
            url: '/scot/entry/' + entry_id,
            data: JSON.stringify({
                'target_id': destination_event_id,
                'target_type' : 'event'
            }),
        }).done(function() {
            $('#move_entry_toolbar').hide();
        }).fail(function() {
            alert("Error: Couldn't move entry");
        });
    }

    function sketch_entry(entry_id) {
    var inner = $('entry_'+entry_id+'_inner');
    edit_text('insertHTML','<span><div id="entry_'+entry_id+'_sketch" style="background:red;">STUFF</div></span>');
    }

    function cancel_entry(entry_id) {
        if(confirm('Are you sure you want to cancel this entry?')) {
        toolbarButtonVisibility(entry_id, false);
            if (!isInt(entry_id)) {
            $('#entry_' + entry_id + '_outer').remove();
        } else {
            var entry_inner = $('#entry_' + entry_id + '_inner');
        entry_inner.find('iframe').contents().first().find('body').removeAttr('contenteditable');
            (entry_inner.find('iframe').contents().first().find('body')[0]).innerHTML = entry_inner.data('origional');
        pentry(entry_inner.find('iframe'), undefined);
        }
        if (supports_html5_storage()) {
            localStorage.removeItem(entry_id);
        }
        }
    }

    function addEntry() {
    var ids = new Array();
    if(bottom_mode == 'alert') {
        var dt = $('.alertTableHorizontal').find('tbody');
        var selected = dt.finderSelect('selected');
        $(selected).each(function(index, row) {
        var id = parseInt($(row).data('alert_id'));
        ids.push(id);
        });
    }else {
        ids.push(parseInt(current_id));
    }

    $(ids).each(function(index, id) {
        var entry_id = 'Not_Saved_' + notSavedCounter;
        var entry = $(render_entry(0, {
            entry_id: entry_id,
            when: new Date(),
        body_flaired: '&nbsp;',
            owner: 'You',
            text: '',
            open_editable: true,
            task: {
                'status': ''
            }
        }));
        $(entry).data('ids', id);
    pentry(entry);
    if(bottom_mode == 'alert') {
      var td = $('<td colspan=50></td>').html(entry);
      if($('#alert_'+id+'_row').next('.not_selectable').length > 0) {
         var comment_row = $('#alert_'+id+'_row').next('tr');
	 var comment_td = $(comment_row).find('td').last();
 	 comment_td.append(entry);
         comment_row.show();

      }
    } else {
      $('#BottomPane').append(entry);
    }
    toolbarButtonVisibility(entry_id, true);
    notSavedCounter++;
    $(entry).find('.entry-body-inner').focus();
    $('#BottomPane').scrollTo($(entry).find('.entry-body-inner'), 500, {over: -10, offsetTop: 200 });
    });
}

function update_task(entry_id, new_status, assignee) {
    var data_obj = {
        cmd: 'maketask',
        taskstatus: new_status,
    };
    if (assignee == 'me') {
        $.ajax({
            type: 'GET',
            url: '/scot/whoami',
            async: false,
        }).done(function(data) {
            data_obj.assignee = data.user;
        });
    } else if (assignee == '') {
        data_obj.assignee = '';
    }

    update_entry(entry_id, data_obj);
}

function checkValidDestinationEvent() {
    if (isInt($('#destinationPicker :selected').val())) {
        $('#move_entry_button').removeAttr('disabled');
    } else {
        $('#move_entry_button').attr('disabled', '');
    }
}

function hide_move_entry_toolbar() {
    $('#move_entry_toolbar').hide();
}

function update_source() {
    var subject = $('#source').html();
    update_neutral({
        'source': subject
    });
}


function update_subject() {
      var subject = $('#subjectEditor').val();
      sizeInput($('#subjectEditor').get(0));
      update_neutral({
        'subject': subject
      });
}

function update_entry(entry_id, data_obj) {
    $.ajax({
        type: 'PUT',
        url: '/scot/entry/' + entry_id,
        data: JSON.stringify(data_obj),
    }).fail(function() {
        alert('Error: Unable to update field for entry ' + entry_id);
    });
}

function update_event(data_obj) {
    update_neutral(data_obj, 'event');
}

function update_neutral(data_obj, updateType, method, callback) {
    $('body').addClass('wait');
    if (updateType == undefined) {
        updateType = bottom_mode;
        if (updateType == "alert") {
            updateType = alert_mode;
        }
    }
    var id = current_id;
    if (method == undefined) {
       method = 'PUT';
    }
    $.ajax({
        type: method,
        url: '/scot/' + updateType + '/' + id,
        data: JSON.stringify(data_obj),
    }).done(function(response) {
       $('body').removeClass('wait');
       if(callback != undefined) {
	  callback(response);
	}
    }).fail(function() {
       $('body').removeClass('wait');
        alert('Error: Unable to update field for ' + updateType + ' ' + id);
    });
}

function load_owner_dropdown_menu() {
    $.ajax({
        type: 'GET',
        url: '/scot/user/',
        async: false,
    }).done(function(data) {
        $(data.data).each(function(index, user) {
            var already_in = 0 != $('#event_owner option[value=' + user.username + ']').length
            if (!already_in) {
                $('#event_owner').append('<option value="' + user.username + '" >' + user.username + '</option>');
            }
        });
    });
}

function new_owner() {
    var new_owner = $('#event_owner').val();
    update_event({
        owner: new_owner
    });
}

function open_close_event() {
    var id = $('#event_id').html();
    close(id);
}

function status_complete(response) {
   if(response.status.toLowerCase() == "ok") {
     $('.status_wait').remove();
   } else {
     $('.status_wait').attr('src', '/images/close_toolbar.png');
   }
}

function close(id) {
    var current_state = $('#event_status').html();
    $('#event_status').append('<img src="/loading.gif" style="width:15px; height:15px;" class="status_wait"></img>');
    if (current_state == "closed" || (current_state.substr(0, 1) == '0')) {
        update_neutral({
            status: 'open'
        }, undefined, undefined, status_complete);
    } else {
        var cur_date_epoch = Math.round(new Date().getTime() / 1000);
        update_neutral({
            status: 'closed',
            closed: cur_date_epoch
        }, undefined, undefined, status_complete);
    }
}

function take_ownership() {
    $("#take_ownership_modal").modal('show');
}

function take_ownership_confirmed() {
    $.ajax({
        type: 'GET',
        url: '/scot/whoami',
    }).done(function(data) {
        update_event({
            owner: data.user
        });
    });
}


function uploadFile() {
    var file_obj = document.getElementById('uploadFile');
    if (file_obj.files.length > 0) {
        var notes = prompt("Please enter a breif description of this file i.e. 'PCAP for 2/7/2015 from 10.2.4.2'", "");
        var fd = new FormData();
        fd.append("upload", document.getElementById('uploadFile').files[0]);
        fd.append("target_type", "event");
        fd.append("notes", notes);
        fd.append("target_id", $("#event_id").html());
        fd.append("modifygroups", default_modify_groups());
        fd.append("readgroups", default_read_groups());
        var xhr = new XMLHttpRequest();
        xhr.upload.addEventListener("progress", uploadProgress, false);
        xhr.addEventListener("load", uploadComplete, false);
        xhr.addEventListener("error", uploadFailed, false);
        xhr.addEventListener("abort", uploadCanceled, false);
        xhr.open("POST", "/scot/file/upload");
        xhr.send(fd);
    }
    $('#uploadFile').val('');
}


function openFileUploadDialog() {
    $("#legacy_upload_target_type").val(bottom_mode);
    $("#legacy_upload_target_id").val(current_id);
    $("#legacy_upload_read_groups").val(default_read_groups());
    $("#legacy_upload_modify_groups").val(default_modify_groups());
    $("#file_upload_modal").modal('show');
}

function drop_noop(evt) {
    evt.stopPropagation();
    evt.preventDefault();
}

function dropped_on_entry(evt, entry) {
    evt.stopPropagation();
    evt.preventDefault();

    var files = evt.dataTransfer.files;
    var count = files.length;
    var entry_id = $(entry).parent().data('entry-id');
    var event_id = $('#event_id').html();

    var notes = prompt("Please enter a breif description of this file i.e. 'PCAP for 2/7/2015 from 10.2.4.2'", "");
    var fd = new FormData();
    for (var i = 0; i < count; i++) {
        fd.append("upload", files[i]);
	fd.append("target_type", "event");
	fd.append("entry_id", entry_id);
	fd.append("notes", notes);
	fd.append("target_id", event_id);
	fd.append("readgroups", default_read_groups());
        var xhr = new XMLHttpRequest();
        xhr.upload.addEventListener("progress", uploadProgress, false);
        xhr.addEventListener("load", uploadComplete, false);
        xhr.addEventListener("error", uploadFailed, false);
        xhr.addEventListener("abort", uploadCanceled, false);
        xhr.open("POST", "/scot/file/upload");
        xhr.send(fd);
    }
}

function uploadProgress(e) {
   $('#uploadProgress').show();
   var percent = Math.floor((e.loaded * 100.0) / e.total);
   $('#uploadProgress').progressbar({
	value: percent
   });
}

function uploadComplete() {
    $('#uploadProgress').hide();
    alert('File uploaded successfully');
}

function uploadCanceled() {
}

function uploadFailed() {
    alert('upload failed');
}

function focusOn(object_id) {
    $('#' + object_id).focus();
}

function open_select2(object_id) {
    $('#' + object_id).select2('open');
}

function showBottomPaneError() {
    $('#BottomPane').html('<br><br><center><h3>Error showing event</h3><p>An error occurred on the server while opening this event.  This must be fixed by a SCOT administrator, please go let them know so they can fix this for you.</p></center>');
}

function showBottomPaneNotAuthorized() {
    $('#BottomPane').html('<br><br><center><h3>Not Authorized</h3><p>You do not have permission to access this event.  Please contact the owner of this event to obtain access.</p></center>');
}

function toggle_entry_permissions(entry_id) {
    var entry_permissions_obj = $('#entry_' + entry_id + '_permissions');
    entry_permissions_obj.toggle();
    entry_permissions_obj.children().filter('input').each(function(index, input) {
        var select = $(input).select2({
            tags: ['lazyLoadGroups']
        });
        var select2_selector = $(input).data('select2').containerSelector;
        var select2 = $(select2_selector);
        select2.addClass('entry_select2');
        var type = input.classList.contains('entry_write') ? 'modifygroups' : 'readgroups';
        $(input).on("change", function(e) {
            var permissions = $(input).select2('val');
            var update_obj = {};
            update_obj[type] = permissions;
            update_entry(entry_id, update_obj);
        });

    });
}

function checklist_selection_changed() {
    var checklist_selected = $('#checklist_toolbar_options :selected').val();
    if (isInt(checklist_selected)) {
        $('#add_checklist_button').removeAttr('disabled');
    } else {
        $('#add_checklist_button').attr('disabled', '');
    }
}

function confirm_add_checklist() {
    var event_id = $('#event_id').html();
    var checklist_to_add = $('#checklist_toolbar_options :selected').val();
    $.ajax({ //Get list of items in checklist
        type: 'GET',
        url: '/scot/checklist/' + checklist_to_add,
    }).done(function(data) {
        var item_keys = Object.keys(data.data.items);
        $(item_keys).each(function(index, item_key) {
            var item_text = data.data.items[item_key];
            $.ajax({ //Add singular checklist item to event as entry
                type: 'POST',
                url: '/scot/entry',
                processData: true,
                data: {
                    text: item_text,
                    target_id: parseInt(event_id),
                    target_type: 'event',
                    readgroups: default_read_groups,
                    modifygroups: default_modify_groups,
                }
            });
        });
    });


}

function default_read_groups() {
    var read_permissions = ['scot', 'ir'];
    if ($('#read_permissions').length > 0 && $('#read_permissions').val().length > 0) {
        read_permissions = $('#read_permissions').val().split(',');
    }
    return read_permissions;
}

function default_modify_groups() {
    var write_permissions = ['scot', 'ir'];
    if ($('#write_permissions').length > 0 && $('#write_permissions').val().length > 0) {
        write_permissions = $('#write_permissions').val().split(',');
    }
    return write_permissions;
}

function add_notes() {
    $('#entity_toolbar_notes').toggle();
}

function isArray(obj) {
   if( Object.prototype.toString.call( obj ) === '[object Array]' ) {
      return true;
   }
   return false;

}

function promote() {
    var alert_id = $('#event_id').html();
    $.ajax({
        type: 'PUT',
        url: '/scot/promote',
        data: JSON.stringify({
            'thing': alert_mode,
            'id': parseInt(alert_id)
        })
    }).done(function(response) {
        window.location = '#/event/' + response.id;
    }).fail(function() {
        alert('Error: Unable to promote alert');
    });
}

function make_incident() {
    var event_id = $('#event_id').html();
    $.ajax({
        type: 'PUT',
        url: '/scot/promote',
        data: JSON.stringify({
            'thing': 'event',
            'id': parseInt(event_id)
        })
    }).done(function(response) {
        window.location = '#/incident/' + response.id;
    }).fail(function() {
        alert('Error: Unable to promote event to incident');
    });
}

function sliderMoved(event, ui, entry_id, history, origional) {
    $('#entry_' + entry_id + '_revision_number').text('Rev#' + ui.value);
    if (ui.value <= history.length) {
        $('#entry_' + entry_id + '_inner').html(history[(ui.value - 1)].old[0].text);
    } else {
        $('#entry_' + entry_id + '_inner').html(origional);
    }
}

function view_revisions(entry_id) {
    $.ajax({
        type: 'GET',
        url: '/scot/entry/' + entry_id,
    }).done(function(response) {
        var numRevisions = response.data.history.length;
        $('#' + entry_id + '_toolbar').after('<span style="width:200px; float:right; display:block; margin-top:5px; margin-right:25px;" id="entry_' + entry_id + '_revision_slider"></span><span id="entry_' + entry_id + '_revision_number" style="float:right;margin-right:20px;">Rev#' + (numRevisions + 1) + '</span>');
        $('#entry_' + entry_id + '_revision_slider').slider({
            range: 'max',
            min: 1,
            max: numRevisions + 1,
            value: numRevisions + 1,
            slide: function(event, ui) {
                sliderMoved(event, ui, entry_id, response.data.history, response.data.html)
            },

        });
    });
}

function get_text_nodes(obj) {
   return $(obj).find(':not(iframe)').addBack().contents().filter(function() {
	return (this.nodeType == 3 && $(this).text().trim().length > 0);
   });
}

function sort_column(e, column_name, th) {
    if ($(e.target).is('.tableHeader')) {
        sort_col[top_mode] = column_name;

        text_nodes = get_text_nodes(th);
	$('.sort_arrow').remove();
        if (sort_direction[top_mode] == 1) {
            sort_direction[top_mode] = -1;
            text_nodes.after('<img src="/images/asc.gif" class="sort_arrow"></img>');
        } else {
            sort_direction[top_mode] = 1;
	    text_nodes.after('<img src="/images/desc.gif" class="sort_arrow"></img>');
        }
        grid_filter_updated(false);
    }
}


function toggleFlairGlobal() {
    $('iframe').each(function(index, ifr) {
       if(ifr.contentDocument != null) {
          var ifrContents = $(ifr).contents();
          var off = ifrContents.find('.entity-off');
          var on = ifrContents.find('.entity');
          if (globalFlairState == false) {
             ifrContents.find('.extras').show();
             ifrContents.find('.flair-off').hide();
             off.each(function(index, entity) {
                $(entity).addClass('entity');
                $(entity).removeClass('entity-off');
             });
          } else {
             ifrContents.find('.extras').hide();
             ifrContents.find('.flair-off').show();
             on.each(function(index, entity) {
                $(entity).addClass('entity-off');
                $(entity).removeClass('entity');
             });

          }

       }
    });
    var off = $('.entity-off');
    var on = $('.entity');
    if (!globalFlairState) {
        globalFlairState = true;
        $('.extras').show();
        $('.flair-off').hide();
        off.each(function(index, entity) {
            $(entity).addClass('entity');
            $(entity).removeClass('entity-off');
        });
    } else {
        $('.extras').hide();
        $('.flair-off').show();
        globalFlairState = false;
        on.each(function(index, entity) {
            $(entity).addClass('entity-off');
            $(entity).removeClass('entity');
        });
    }
}

function setFlairSingle(state, iframe) {
    if(state == undefined || iframe == undefined) {
       console.log('ERROR: call to setFlairSingle with state or iframe undefined');
       return -1;
    }
    if(iframe.contentDocument != null) {
       var ifrContents = $(iframe).contents();
       var off = ifrContents.find('.entity-off');
       var on = ifrContents.find('.entity');
       if (state && globalFlairState) {
          ifrContents.find('.extras').show();
          ifrContents.find('.flair-off').hide();
          flairState = true;
          off.each(function(index, entity) {
             $(entity).addClass('entity');
             $(entity).removeClass('entity-off');
          });
       } else  {
          ifrContents.find('.extras').hide();
          ifrContents.find('.flair-off').show();
          flairState = false;
          on.each(function(index, entity) {
             $(entity).addClass('entity-off');
             $(entity).removeClass('entity');
          });
       }
    }
}

function close_toolbar(toolbar_btn) {
    $(toolbar_btn).parent().hide();
}

function upvote() {
    update_neutral({
        'cmd': 'upvote'
    }, 'alert');
}

function downvote() {
    update_neutral({
        'cmd': 'downvote'
    }, 'alert');
}

function findAndReplace(button) {
    var sdiv = $('<span style="color:black"></span');
    sdiv.append('<table><tr><td>Find:</td><td><input name="find"></input></td></tr><tr><td>Replace:</td><td><input name="replace"></input></td></tr><tr><td ><input type="button" value="Make it so"></input></td></tr></table>');
    sdiv.find('input[type=button]').click(function(evt) {
        var find = $(sdiv).find('input[name=find]').val();
        var replace = $(sdiv).find('input[name=replace]').val();
        //var isRegex = $(sdiv).find('input[name=regex]').is(':checked');
        var specials = new RegExp("[.*+?|()\\[\\]{}\\\\]", "g"); // .*+?|()[]{}\
        find = find.replace(specials, "\\$&");
        var pattern = new RegExp(find, 'g');
        findAndReplaceDOMText(
            pattern,
            savedElement.contentDocument.body,
            function(fill, matchIndex, fullFill) {
                var el = $('<span></span>');
                $(el).html(replace);
                return el[0];
            }
        );

    });
    return sdiv;
}

function selectTableSize(button) {
    var sdiv = $('<span class="tablePicker"><font color="black">Rows:<span id="numRows"></span>&nbsp; &nbsp;Cols:<span id="numCols"></span></font></span>');
    var table = $('<table></table>');
    var tableSize = 20;
    for (var rowNum = 0; rowNum < tableSize; rowNum++) {
        var row = $('<tr></tr>');
        for (var colNum = 0; colNum < tableSize; colNum++) {
            var cell = $('<td data-row="' + rowNum + '" data-col="' + colNum + '"><a  style="width:5px; height:5px; display:block;"></a></td>');
            cell.hover(function() {
                var numCols = $(this).data('col');
                $('#numCols').text(numCols + 1);

                var numRows = $(this).data('row');
                $('#numRows').text(numRows + 1);

                colorCells(table, numRows + 1, numCols + 1);
            });
            cell.click(function() {
                var numCols = $(this).data('col');
                var numRows = $(this).data('row');
                createTable(numRows + 1, numCols + 1);
            });
            row.append(cell);
        }
        table.append(row);
    }
    sdiv.append(table);
    return sdiv;
}

function createTable(numRows, numCols) {

    var table = $('<table border="1">');
    for (var rowNum = 0; rowNum < numRows; rowNum++) {
        var row = $('<tr></tr>');
        for (var colNum = 0; colNum < numCols; colNum++) {
            $(row).append('<td>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</td>');
        }
        table.append(row);
    }
    var full = $('<div></div>').append(table);
    edit_text('insertHTML', full.html());
}

function colorCells(table, numRows, numCols) {
    $('.hoverCell').removeClass('hoverCell');
    for (var rowNum = 0; rowNum < numRows; rowNum++) {
        var row = $(table).find('tr')[rowNum];
        for (var colNum = 0; colNum < numCols; colNum++) {
            var cell = $(row).find('td')[colNum];
            $(cell).addClass('hoverCell');
        }
    }

}

function entryFocused(entry) {
    lastFocus = entry;
}

function incident_preview(incidentNum) {
    current_id = incidentNum;
    $('.selectedRow').removeClass('selectedRow');
    $('#row_' + current_id).addClass('selectedRow')
    $.ajax({
        type: 'GET',
        url: '/scot/incident/' + incidentNum,
        success: function(response) {
            $('#BottomPane').html('');
            var incident_div = $('<div></div>').addClass('incidentTable');
            var data = response.data;
            $('#event_id').text(data['incident_id']);
            $('#subjectEditor').val(data['subject']);
            sizeInput($('#subjectEditor').get(0));
            $('#event_owner').text(data['owner']);
            $('#event_status').text(data['status']);
            $('#linked_events').text(data['events']);
           $('#write_permissions').val(data.modifygroups);
                    $('#read_permissions').val(data.readgroups);
            //List of dropdowns and their available options

            var dropdown_options = {};

            //Mapping between human readable names and programming names
            var title_to_data_name = {};

	    if(typeof custom_incident_dropdown_options == 'function') {
               dropdown_options = custom_incident_dropdown_options();
            }
       	    if(typeof custom_incident_dropdown_mapping == 'function') {
                title_to_data_name = custom_incident_dropdown_mapping();
            }

            //Generate dropdowns and handle changes
            $(Object.keys(dropdown_options)).each(function(index, dropdown_name) {
                var match = "";

                //Get text of current selected option as saved on server i.e. IMI-3
                if (data[title_to_data_name[dropdown_name]] != undefined) {
                    match = data[title_to_data_name[dropdown_name]];
                }

                var data_name = title_to_data_name[dropdown_name];
                var key = $('<span></span>').text(dropdown_name + ':');
                var val = $('<span></span>');
                var dropdown = $('<select></select>');
                $(dropdown).attr('id', title_to_data_name[dropdown_name]);
                //Handle updating the server when a new option is selected
                dropdown.change(function() {
                    var new_value = $(this).val();
                    if (new_value != $(dropdown).data('previous')) {
                        var update_obj = new Object();
                        update_obj[data_name] = new_value;
                        update_neutral(update_obj); //makes the ajax call to make specified changes on server
                    }
                });

                //Add each of the options to the dropdown
                $(dropdown_options[dropdown_name]).each(function(index, option_text) {
                    var option = $('<option></option>').text(option_text);
                    if (match.toLowerCase() == option_text.toLowerCase()) {
                        $(option).attr('selected', '');
                        $(dropdown).data('previous', option_text);
                    }
                    $(dropdown).append(option);
                });
                $(val).append(dropdown);
                var row = $('<div></div>');
                $(row).append(key);
                $(row).append(val);

                //Append the latest dropdown and label to be shown
                $(incident_div).append(row);
            });

            //Dates
            var date_types = ['Occurred', 'Discovered', 'Reported', 'Closed'];
            $(date_types).each(function(index, date_type) {
                if (index > 0) {
                    var prev_date_type = date_types[index - 1];
                }
                var dt = $('<input></input>').attr('id', date_type.toLowerCase());
                var key = $('<span></span>').append(dt);
                var value = $('<span></span>').append(date_type + ':');
                var row = $('<div></div>').append(value).append(key);
                $(incident_div).append(row);
                $(dt).datetimepicker({
                    maxDateTime: new Date(),
                    timeFormat: 'hh:mm tt',
                });
                try {
                    var cur_date_str = data[date_type.toLowerCase()];
                    var d = new Date(0);
                    d.setUTCSeconds(cur_date_str);
                    $(dt).datetimepicker('setDate', d);
                } catch (err) {
		    if(console != undefined) {
                       log.console('unable to set origional date');
		    }
                }
                $(dt).change(function() {
                    var date = $(this).datetimepicker('getDate');
                    $(date).data('updated', date);
                    var update_obj = new Object();
                    update_obj[date_type.toLowerCase()] = (date.getTime() / 1000);
                    update_neutral(update_obj);
                });
            });
            var doe_id = $('<input></input>').val(data['doe_report_id']);
            $(doe_id).change(function() {
                var new_val = $(this).val();
                update_neutral({
                    doe_report_id: new_val
                });
            });
            var key = $('<span></span>').append('DOE Report Id:');
            var value = $('<span></span>').append(doe_id);
            var row = $('<div></div>').append(key).append(value);
            $(incident_div).append(row);
            $('#BottomPane').append(incident_div);
    	   display_entries(response.data.entries);
        }
    });
}

/*
function toggleVertical() {
    $('.alertTableHorizontal').toggle();
    $('.alertTable').toggle();
    if ($.cookie("vertical") == 1) {
        $.cookie("vertical", null);
    } else {
        $.cookie("vertical", 1);
    }
}
*/

function alert_checked(checkbox) {
    var alert_checked = false;
    $('.alert_checkboxes').each(function(index, checkbox) {
        if ($(checkbox).is(':checked')) {
            $('.alert_checked').show();
            alert_checked = true;
            return false;
        }
    });
    if (!(alert_checked)) {
        $('.alert_checked').hide();
    }
    return alert_checked;
}

function table2csv(grid, optionalHeaders) {
    var csv = '';
    if(optionalHeaders != undefined && optionalHeaders.length > 0) {
       csv += optionalHeaders.join(',') + '\n';
    }
    $(grid).find('tr').each(function(rowNum, row) {
        var cellVals = new Array();
        $(row).find('td,th').each(function(colNum, cell) {
                var copy = $(cell).clone(false); //We are going to be editing this cell, so we need to copy as to preserve what is on the screen
	 	$(copy).find('.extras').remove();  //Remove any flair, it won't make sense when exported
                var value = $(copy).text();  //Get text only of the cleaned cell
                value = value.replace(/,/g, '|');  //Replace any commas, as that would mess up the CSV
		value = value.replace(/(\r\n|\n|\r)/gm," ") //Replace any line breaks the text() command created (like from <br> and such)
                cellVals.push(value);
        });
        csv += cellVals.join() + '\n';
    });
    var data_uri_string = 'data:text/csv;base64,' + $.base64.encode(csv);
    return data_uri_string;
}

function export_grid() {
    var grid = $('#event_grid');
    var headers = new Array();
    $('#filters-inner').find('th').each(function(index, th) {
      headers.push($(th).text().trim());
    });
    window.open(table2csv(grid, headers));

}

function create_intel() {
    $.ajax({
        type: 'POST',
        url: '/scot/intel/',
        data: JSON.stringify({
            subject: 'No_Subject',
            source: ['No_Source']
        })
    }).done(function(response) {
        var intel_id = response.id;
        window.location = '#/intel/' + intel_id;
    });
}

function create_event() {
    $.ajax({
        type: 'POST',
        url: '/scot/event/',
        data: JSON.stringify({
            subject: 'No_Subject',
            source: ['No_Source']
        })
    }).done(function(response) {
        var event_id = response.id;
        window.location = '#/event/' + event_id;
    });
}

function clear_filters() {
    $('#filters-inner').find('input').each(function(index, input) {
        if ($(input).data('select2') != undefined) {
            $(input).select2('val', '');
        }
        $(input).val('');
    });
    grid_filter_updated(false);
}

function showAlertGuide(button) {
    var popup = window.open('/guide.html#' + guide_id);
}

function restore_draft(entry_id) {
    var text = localStorage[entry_id];
    toolbarButtonVisibility(entry_id, true);
    var entry_inner = $('#entry_' + entry_id + '_inner');
    entry_inner.data('origional', entry_inner.html()); //bind origional HTML to the entry's inner element
    entry_inner.html(text);
    entry_inner.attr('contenteditable', true);
    entry_inner.keyup($.debounce(250, function() {
        save_draft(entry_inner, entry_id)
    }));
}


window.onbeforeunload = function(e) {
  if($('#edit_toolbar:visible').length > 0) {
    return "You have unsaved entries, are you sure you want to leave?";
  }
}

function parse_legacy_upload_results() {
 var success = 0;
   try{
       var results = $('#legacy_upload_iframe').contents().find('body').text();
       if(results != '') {
         var parsed = JSON.parse(results)[0];
            $('#done_legacy_upload').click();
       }
   } catch (e) {
      alert('Error uploading your file');
   }
}

function move_entry_to_summary_position(entry_id) {
  var entry_outer = $('#entry_'+entry_id+'_outer');
  $('.summary_entry').removeClass('summary_entry'); //remove summary class from previous
  entry_outer.addClass('summary_entry');  //apply summary class to new summary entry
  $('#BottomPane').prepend(entry_outer);

}

function make_summary(entry_id) {
  if(bottom_mode == 'event') {
    move_entry_to_summary_position(entry_id);
    $('#BottomPane').scrollTo($('#entry_' + entry_id + '_outer'), 500);
    update_neutral({summary_entry_id: entry_id});
  }
}

function export_alert_data() {
  var rows = $('.alertTableHorizontal').finderSelect('selected').clone(true);
  var header = $('.alertTableHorizontal').find('tr').first().clone(true);
  var table = $('<table></table');
  table.append(header);
  table.append(rows);
  window.open(table2csv(table));

}

function multiple_alerts(action, caller) {
  var spinner = $('<img src="/loading.gif" style="width:15px; height:15px;"></img>');
  $(caller).append(spinner);
  var ids = new Array();
  if(parsed) {
var dt = $('#BottomPane').find('tbody');
  var selected = dt.finderSelect('selected');
  $(selected).each(function(index, row) {
    var id = ($(row).data('alert_id') + 0);
    ids.push(id);
  });
  } else {
    ids = [ $('#alert_html').data('alert_id') ];
  }
var total = ids.length;
var soFar = 0;
$(ids).each(function(index, alert_id) {
   var type = 'PUT';
   var data = new Object();
   if (action == 'close') {
          var cur_date_epoch = Math.round(new Date().getTime() / 1000);
          data = JSON.stringify({
              status: 'closed',
              closed: cur_date_epoch
          });
   } else if(action == 'open') {
       data = JSON.stringify({
	      status: 'open'
	  });
   } else if (action == 'delete') {
     type = 'DELETE';
   }

    $.ajax({
	type: type,
	url: '/scot/alert/' + alert_id,
	data: data
    }).success(function (response) {
	soFar++;
	if(soFar == total) {
          spinner.remove();
	}
     });
});
}

function promote_alerts(event_id, caller) {
  var spinner = $('<img src="/loading.gif" style="width:15px; height:15px;"></img>');
  $(caller).append(spinner);
  var dt = $('#BottomPane').find('tbody');
  var selected = dt.finderSelect('selected');
  var ids = new Array();
  $(selected).each(function(index, row) {
    var id = ($(row).data('alert_id') + 0);
    ids.push(id);
  });
  if(!parsed) {
    ids = [ $('#alert_html').data('alert_id') ];
  }
  var data = {
		id:    ids,
		thing: 'alert',
  };
  if(event_id != undefined) {
     data.target_id = parseInt(event_id);
     data.target_type = 'event';
  }
  var error = "Error: Couldn't promote the selected alert(s). Please make sure you have permissions to modify the alerts to be promoted, and the event they are being added to if any.";
  $.ajax({
    type: 'PUT',
    url:  '/scot/promote',
    data: JSON.stringify(data)
  }).done(function(response) {
      $(spinner).remove();
      if(response.status == 'ok') {
         window.location = '/#/event/'+response.id;
      } else {
	alert(error);
      }
  }).fail(function(response) {
     $(spinner).remove();
     alert(error);
  });
}

function promote_to_existing(caller) {
  var event_id = prompt("Please enter Event ID to promote into");
  if(event_id != undefined) {
    promote_alerts(event_id, caller);
  }
}

function delete_alerts(button_clicked) {
 var dt = $('#BottomPane').find('tbody');
  var selected = dt.finderSelect('selected');
  var ids = new Array();
  $(selected).each(function(index, row) {
    var id = ($(row).data('alert_id') + 0);
    ids.push(id);
  });
   $("#delete_alert_modal").attr('data-alert-ids', ids );
    $("#delete_alert_modal").modal('show');
}

function scroll_to_entry(entry_id) {
    $('#BottomPane').scrollTo($('#entry_'+entry_id+'_outer'), 300);
}

function scroll_to_alert_row(alert_id) {
    $('#BottomPane').scrollTo($('#alert_'+alert_id+'_status'), 300, {over: -10});
}

function toggle_next_column(clicked_button) {
  $(clicked_button).closest('tr').next().toggle(200);
}

function submit_preview(evt) {
  var term = $('#2search').val();
  if(search != undefined) {
    $('#searching_gif').remove();
    search.abort();
  }
  submit_search(term, 0);
}

function fullscreen_content() {
   $('#paging').toggle();
$('#filters').toggle();
$('#TopPane').toggle()
 $('#TopMenu').toggle();
}

function scot_popup_navigate(type, key, entry_id, new_page) {
   if(type == 'alert') {
      $.ajax({
	type: 'GET',
	url: '/scot/aglookup/'+key,
      }).done(function(response) {
	 var group = response.alertgroup_id;
	 if(new_page) {
	   window.open('/#/alert/group/'+group);
	 } else {
           window.location = '/#/alert/group/'+group;
	 }
      });
   } else {
      if(type == 'alertgroup') {
	type = 'alert/group';
      }

      if(entry_id != undefined) {
	if(new_page) {
	  window.open('/#/'+type+'/'+key+'/'+entry_id);
	} else {
	  window.location = '/#/'+type+'/'+key+'/'+entry_id;
	}
      }else {
	if(new_page) {
	  window.open('/#/'+type+'/'+key);
	} else {
          window.location = '/#/'+type+'/'+key;
	}
      }
   }
}

function popout_search_results() {
 var val = $('#2search').val();
 var win =  window.open('/search.html#'+val, 'search_results');
 $(win.document).find('#popout').remove();
}

function show_hide_filters() {
  if($('.grid_filter_inputs:visible').length > 0) {
     $('#filters-inner').find('.select2-container').hide();
     $('.grid_filter_inputs').addClass('init');
     clear_filters();
  } else {
     $('.init').removeClass('init');
     $('#filters-inner').find('.select2-container').show();
     $('#clear_filters').show();
  }
}

function linked_event(linked) {
  var id = $(linked).text();
  window.location = '#/event/'+id;
}

function linked_incident(linked) {
  var id = $(linked).text();
  window.location = '#/incident/'+id;
}

function viewSource(button) {
  var plain = $('#viewSource').data('plain');
  var html = $('#viewSource').data('html');
  var win = window.open('viewSource.html', '_blank');
  win.onload = function() {
    if(html != undefined) {
       $(win.document).find('#html').text(html);
    } else {
       $(win.document).find('.html').remove();
    }
    if(plain != undefined) {
       $(win.document).find('#plain').text(plain);
    } else {
       $(win.document).find('.plain').remove();
    }
  }
}

function close_results() {
  $('#closer').remove();
  $('#live_results').hide();
}

function alert_parsing() {
  $.ajax({
    type: 'GET',
    url: currentApiUrl
  }).done(function(response) {
    var body = response.data.body_html;
    var dom = $('<span></span>').html(body);
    $('#alert_parsed').append(walk_dom(dom));
    $('#alert_parsed').find('*').click(function(evt) {
       console.log(evt);
    });
    $('#alert_parsing_html').text(body);
    $('#alert_parsing_modal').modal('show');
    $('#alert_parsing_to').data('subject', response.data.subject);
    $('#alert_parsing_to').data('source', response.data.sources[0]);
    change_alert_parsing_type();
   });
}

function walk_dom(elem) {
  elem = $(elem);
  var result = $('<span></span>');
//  result.append('<span></span>').text(elem.text());
  if(elem.contents().length > 0) {
    $(elem.contents()).each(function(index, child) {
	var child_res = walk_dom(child);
        var new_span = $('<span class="elem" style="margin-left:20px;">'+child.nodeName+'</span>').append(child_res);
	result.append(new_span);
    });
  } else {
    if(elem.text().trim().length > 0) {
       return $('<div class="elem final_elem"></div>').text(elem.text());
    } else {
       return undefined;
    }
  }
  return result;
}


function openHistory() {
 $("#history_modal").modal('show');
 $.ajax({
    type: 'GET',
    url: currentApiUrl
  }).done(function(response) {
    var history = append_history(response);
    $('#history_modal').find('.modal-body').html(history);
  });
}

function sizeInput(input) {
   $('#invisible').html($('<span></span>').text(input.value));
   input.style.width = ($('#invisible').width() + 5) + 'px';
}

var htmlEntities = function(str) {
    if(str == undefined) {
                  return 0;
      return '';
    }
    return str.replace(/[\u00A0-\u99999<>\&]/gim, function(i) {
        return '&#'+i.charCodeAt(0)+';';
    });
};

function list_entities() {
  var url = '/scot/';
  if(bottom_mode == 'event') {
    url += 'event/';
  } else if (bottom_mode == 'alertgroup') {
    url += 'alertgroup/';
  }
  url += current_id;
  $.ajax({
    type: 'GET',
    url:  url
  }).done(function(response) {
    var flairdata = response.data.flairdata;
    var entity_keys = Object.keys(flairdata);
    var entities_by_type = new Object();
    $(entity_keys).each(function(index, entity) {
       var type = flairdata[entity].entity_type;
       if(entities_by_type[type] == undefined) {
          entities_by_type[type] = new Array();
       }
       entities_by_type[type].push(htmlEntities(entity));
    });
    var entity_types = Object.keys(entities_by_type);
    var entity_text_p = $('#list_entities_text');
    $(entity_text_p).html('');
    $(entity_types).each(function(index, entity_type) {
        var entity_name_div = $('<div style="font-weight:bold; margin:5px; border:1px solid black;"></div>');
        $(entity_name_div).text(entity_type);
        var entity_data = $('<div style="font-weight:normal; max-height:200px; overflow-y:auto;"></div>');
        $(entity_data)[0].innerHTML +=entities_by_type[entity_type].join("<br>");
        $(entity_name_div).append(entity_data);
        entity_text_p.append(entity_name_div);
    });
    $('#list_entities_modal').modal('show');
  });
}

function login(button) {
  var dialog = $(button).parents('.modal');
//  var originalOptions = $(button).parents('.modal').data('originalOptions');
  $('.loading').remove();
  $(button).append('<img src="/loading.gif"  style="width:20px;" class="loading"></img>');
  var data = new Object();
  data.user = $('#username').val();
  data.pass = $('#password').val();
  $.ajax({
    url: '/scot/login',
    type: 'POST',
    data:  JSON.stringify(data)
  }).done(function(response) {
   $('#login_status').prepend('<span style="float:right; color: green; font-weight:bold;">'+formatAMPM(new Date())+' -- Login Success</span><br>');
   current_user = data.user;
   $(timers).each(function(index, funct) {
     funct();
   });
   $('#login_modal').modal('hide');
  }).fail(function(response) {
   $(button).find('.loading').remove();
   $('#login_status').prepend('<span style="float:right; color: red; font-weight:bold;">'+formatAMPM(new Date())+' -- Login Failed</span><br>');
  });
}

function default_button(dialog) {
  if(event.keyCode == 13) {
    $(dialog).find('.btn-primary').each(function(btn_idx, button) {
      $(button).click();
    });
  }
}


function test_parsing() {
  var alert_parsing_js = $('#alert_parsing_js');
  var alert_html = $('#alert_parsing_html').text();
  var dom = $('<span></span>').html(alert_html);
  $('#debugDiv').text('');
  $('#alert_parsing_results').text('');

  var result = '';
if (typeof console  != "undefined")
    if (typeof console.log != 'undefined')
        console.olog = console.log;
    else
        console.olog = function() {};

console.log = function(message) {
    console.olog(message);
    $('#debugDiv').append(formatAMPM(new Date()) + ' -- ' + JSON.stringify(message, null, '\t') + '<br>');
};
console.debug = console.info =  console.log;

  try {
     eval(alert_parsing_js.val());
  } catch(err) {
      var loc = '';
      var err_line = err.stack.split('\n')[1];
      if(err_line.indexOf('<anonymous>') >= 0) {
         var splits = err_line.split(':');
         var len = splits.length;
	 var loc = ' (line:' + splits[len-2]+', character:'+splits[len-1];
      }
      $('#debugDiv').append(formatAMPM(new Date()) + ' -- ' + err.message.replace("\n", "<br />","g") + loc +'<br>');
      console.error(err);
  }
  var ok = false;
  /*if($.isArray(result)) {
    $(result).each(function(resultindex, result_element_55) {

    });
  }*/
  console.log = console.olog;
  console.error = console.debug = console.info =  console.log;

  $('#alert_parsing_results').text(JSON.stringify(result,null,'\t'));
  var preview = new Array();
  $(result).each(function(occ_idx, occurance) {
     var tmp = new Object();
     tmp.data_with_flair = new Object();
     $(Object.keys(occurance)).each(function(key_idx, key) {
        tmp.data_with_flair[key] = occurance[key];
     });
     tmp.alert_id = 0;
     tmp.status  = 'open';
     tmp.columns = Object.keys(occurance);
     preview.push(tmp);
  });
  var res = render_alert_body(preview);
  $('#alert_parsing_preview').html(res);
/*  var worker = new Worker('parser.js');
  worker.addEventListener('message', function(e) {
    if(e.data.type == 'result') {
       $('#alert_parsing_results').text(JSON.stringify(e.data.result,null,'\t'));
    } else {
      $('#debugDiv').append(formatAMPM(new Date()) + ' -- ' + e.data.error.replace("\n", "<br />","g") + '<br>');
    }
  }, false);
//  worker.postMessage({'js':alert_parsing_js.val(), 'dom':dom});
  worker.postMessage({'js':alert_parsing_js.val(), 'dom':alert_html});
*/
}

function parser_type_change(select) {
  var type = $(select).find(':selected').val();
  if(type != 'custom') {
     $(select).data('custom', $('#alert_parsing_js').val());
  } else {
     $('#alert_parsing_js').val($(select).data('custom'));
  }
if (type == 'table') {
    $('#alert_parsing_js').val("\
var ths = new Array(); \n\
$(dom).find('th').each(function(th_idx, th) {\n\
   ths.push(th.innerText); \n\
}); \n\
var result = new Array(); \n\
$(dom).find('tr').slice(1).each(function(tr_idx, tr) { \n\
   var occurance = new Object();\n\
   $(tr).find('td').each(function(td_idx, td) {\n\
      var key = ths[td_idx];\n\
      occurance[key] =  td.innerText;\n\
   });\n\
   result.push(occurance);\n\
});\n");
  }
}

function toggle_alert_dom() {
  $('#alert_parsed').toggle();
}

function change_alert_parsing_type() {
  var type = $('#alert_parsing_type').find(':selected').val();
  var newval = $('#alert_parsing_to').data(type);
  $('#alert_parsing_to').val(newval);
}

function save_parsing() {
  var condition_type = $('#alert_parsing_type :selected').val();
  var condition_comparator  = $('#alert_parsing_comparator').val();
  var condition_match = $('#alert_parsing_to').val();
  var js  = $('#alert_parsing_js').val();

  $.ajax ({
    type: 'POST',
    url:  '/scot/parser',
    data:  JSON.stringify({'condition_match': condition_match, 'condition_type': condition_type, 'condition_comparator': condition_comparator, 'js': js})
  }).done(function(response) {
    $('#alert_parsing_modal').modal('hide');
  }).error(function(response) {
    alert('unable to save new parser');
  });
}

function text2html(text) {
           text = text.replace(/ /g, '&nbsp;');
           text = text.replace(/(?:\r\n|\r|\n)/g, '<br />');
           text = text.replace(/\t/, '&#09;');
            return text;
        }
function expand_entry(expand_btn) {
  var entry_inner = $(expand_btn).parent().siblings('.entry-body-inner').first();
  if(entry_inner.height() > 500) {
    entry_inner.css('max-height', '500px');
    $(expand_btn).text('Show More');
    $(expand_btn).css('opacity', 1);
  } else {
    entry_inner.css('max-height', '999999px');
    $(expand_btn).text('Show Less');
    $(expand_btn).css('opacity', 0.3);
  }
}

function fullscreen_entry(entry_id, fullscreen_btn) {
  var htmlToColorbox = $('#entry_'+entry_id+'_inner').html();
  jQuery.colorbox({html : htmlToColorbox, width: "95%", height: "95%"});
}
