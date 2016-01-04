var savedRange, isInFocus, savedElement;
var top_mode;
var bottom_mode;
var previous_type = 'init';

function locationHashChanged(e) {
    var hash = window.location.hash;
    window.document.title = 'SCOT3';
    if (hash != "" && hash != '#') {
        hash = hash.substr(1);
        var parts = hash.split('/');
        if (parts.length >= 2) {
            var reload = false;
	        $('.viewing').hide();
            $('.hideOnSwitch').hide();
            if (top_mode == undefined || top_mode != parts[1]) {
                top_mode = parts[1];
                reload = true;
                previous_type = bottom_mode;
                bottom_mode = parts[1];
                $('#nav1').find('.nav').find('a').each(function(index, a) {
                    var linkText = $(a).text().toLowerCase();
		    if(linkText.length > 0) {
                       $('.' + linkText).hide();
                    }
                });
                $('#nav1').find('a').each(function(index, a) {
                    var linkText = $(a).text().toLowerCase();
                    if (($(a).text().toUpperCase() == (top_mode + 's').toUpperCase()) || ($(a).text().toUpperCase() == top_mode.toUpperCase()) ){
                        $(a).addClass('active_tab');
                        $('.' + linkText).each(function(index, item) {
                            if (!(item.classList.contains('hideOnSwitch') || item.classList.contains('viewing'))) {
                                $(item).show();
                            }
                        });
                    } else {
                        $(a).removeClass('active_tab');
                        //     $('.'+linkText).hide();
                    }
                });
            }
            if (parts.length >= 3) {
 	            $('.viewing').show();
		        $('.hideOnSwitch').hide();
                $('#event_info').show();
                $('#BottomPane').show();
                switch (parts[1]) {
                    case 'event':
                    case 'intel':
                        bottom_mode = parts[1];
                        if (parts[3] != undefined && parts[3] != '') {
                          preview(parts[1], parts[2], parts[3]);
                        } else {
                          preview(parts[1], parts[2]);
			            }
                        break;
                    case 'alert':
                        bottom_mode = parts[1];
                        if (parts[2] == 'group') {
                            preview('alertgroup', parts[3]);
                        } else {
			      var oldURL = '';
		              if(e != undefined) {
			        oldURL = $('<a></a>').attr('href', e.oldURL).get(0).hash;
			      }
			       $.ajax({
         			 type: 'GET',
			          url:  '/scot/alert/'+parts[2]
			       }).done(function(response) {
			           var url = '#/alert/group/'+response.data.alertgroup;
				   if(oldURL != url) {
			             window.location = url;
				   } else {
  					window.history.back();
				   }
			       });
			       return 1;
			}
                        break;
                    case 'incident':
                        bottom_mode = parts[1];
                        incident_preview(parts[2]);
                        break;
                    case 'task':
                        bottom_mode = parts[2];
			 $('.' + bottom_mode + 's, .' + bottom_mode).each(function(index, item) {
                            if (!(item.classList.contains('hideOnSwitch') || item.classList.contains('viewing'))) {
                                $(item).show();
                            }
                        });

                        preview(parts[2], parts[3], parts[4]);
                        break;
                }
            } else {  //parts.length == 2
                $('.hideOnSwitch').hide();
                $('#event_info').hide();
                $('#BottomPane').hide();
                window.document.title = top_mode.charAt(0).toUpperCase() + top_mode.slice(1) + 's';
                if($('#TopPane:visible').length <= 0) {
                    $('#paging').show();
                    $('#filters').show();
                    $('#TopMenu').show();
                    $('#TopPane').show();
                    $('#TopPane').css('height', '300px');
		        }
            }
            if (reload) {
                grid_filter_updated(true);
            }
        }
    } else {
        $('.hideOnSwitch').hide();
        // $('#BottomPane').hide();
        $('#event_info').hide();
        $('.viewing').hide();
        $('.alerts').hide();
        $('.intel').hide();
        $('.events').hide();
    }
}

window.onhashchange = locationHashChanged;

function load_notifications() {
    var notes = ["first", "second", "another notification with <a href='#'>link</a> in it"];
    var html = '';
    $.each(notes, function(index, note) {
        html += note + '<hr style="margin:0px;">';
    });
    return html;
}



$(document).ready(function() {
    setInterval(function() {
        $('.recentlyUpdated').each(function(index, row) {
            var updated = $(row).data('updated').getTime();
            var now = new Date();
            now = now.getTime();
            var percent = Math.max(0, ((50 - ((now - updated) / 100)) / 100));
            $(row).find('td').css('background-color', 'rgba(255,255,0,' + percent + ')');
            if (percent == 0) {
                $(row).removeClass('recentlyUpdated');
                $(row).find('td').css('background-color', '');
            }
        });
        $('.recentlyViewed').each(function(index, row) {
            if (!(row.classList.contains('recentlyUpdated'))) {
                var updated = $(row).data('view-updated').getTime();
                var now = new Date();
                now = now.getTime();
                var percent = Math.max(0, ((50 - ((now - updated) / 100)) / 100));
                $(row).find('td').css('background-color', 'rgba(0,0,255,' + percent + ')');
                if (percent == 0) {
                    $(row).removeClass('recentlyViewed');
                }
            }
        });
    }, 200);
});

$(document).ready(function() {
    register_client();
    $('#notifications').popover({
        content: load_notifications,
        html: true
    });
    $(':not(#anything)').on('click', function(e) {
        $('.popover-link').each(function() {
            //the 'is' for buttons that trigger popups
            //the 'has' for icons and other elements within a button that triggers a popup
            if (!$(this).is(e.target) && $(this).has(e.target).length === 0 && $('.popover').has(e.target).length === 0 && $(this).data('popover') != undefined) {
                $(this).popover('hide');
                return;
            }
        });
    });
    $('#BottomPane').resize(function() {
        update_bottom_pane_height();
    });
    $('#event_info').resize(function() {
        update_bottom_pane_height();
    });
    $('#TopPane').resize(function() {
        update_bottom_pane_height();
    });
});

function isInt(n) {
    return n % 1 === 0;
}

var startY;
var offsetY;

function drag_splitter(e) {

    //$('#TopPane').css('height', offsetY + e.clientY - startY);
    var adjustment = 0;
    if ($('#paging').is(':visible')) {
        adjustment = ($('#paging').height() + 5);
    }
    var new_height = (e.clientY - $('#TopPane').offset().top - adjustment);
    $('#TopPane').css('height', new_height + 'px');
    if (e.clientY <= ($('#paging').height() + $('#filters').height()  + $('#navbar').height())) {
        $('#paging').hide();
        $('#filters').hide();
        $('#TopPane').hide();
    } else {
        $('#TopPane').show();
        $('#paging').show();
        $('#filters').show();
    }
}

function update_bottom_pane_height() {
    var BottomPane = $('#BottomPane');
    BottomPane.css('height', window.innerHeight - BottomPane.offset().top - 10 + "px");
}
var previous_top_pane_height;

function click_splitter() {
    if (previous_top_pane_height != undefined) {
        $('#TopPane').height(previous_top_pane_height + "px");
        $('#filters').show();
        previous_top_pane_height = undefined;
    } else {
        previous_top_pane_height = $('#TopPane').height();
        $('#TopPane').height('0px');
        $('#filters').hide();
    }
}

function start_drag_splitter(e) {
    if (e == null) {
        e = window.event;
    } else {
        e.preventDefault();
    };
    startY = e.clientY;
    document.onmousemove = drag_splitter;
    document.onmouseup = stop_drag_splitter;
    //offsetY = parseInt(target.style.top);
}

function stop_drag_splitter(e) {
    document.onmousemove = null;
    $.cookie('event_grid_height', $('#TopPane').height());
    adjustTable();
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

$(document).ready(function() {
    $('.entry-body-inner').each(function(index, element) {
        DoubleScroll(element);
    })

});


function DoubleScroll(element) {
    if (Math.abs(element.scrollWidth - $(element).width()) > 20) {
        var scrollbar = document.createElement('div');
        scrollbar.appendChild(document.createElement('div'));
        scrollbar.style.overflow = 'auto';
        scrollbar.style.overflowY = 'hidden';
        scrollbar.firstChild.style.width = element.scrollWidth + 'px';
        scrollbar.firstChild.style.height = '0px';
        scrollbar.firstChild.style.paddingTop = '0px';
        scrollbar.firstChild.appendChild(document.createTextNode('\xA0'));
        scrollbar.onscroll = function() {
            element.scrollLeft = scrollbar.scrollLeft;
        };
        element.onscroll = function() {
            scrollbar.scrollLeft = element.scrollLeft;
        };
        element.parentNode.insertBefore(scrollbar, element);
    }
}

$(window).resize(function() {
    update_bottom_pane_height();
    adjustTable();
});
//$(window).resize(update_bottom_pane_height);



function adjustTable() {
    var colCount = $($('.table_row')[0]).children().filter('td').length; //get total number of column

    var m = 0;
    var n = 0;
    var brow = 'mozilla';
    jQuery.each(jQuery.browser, function(i, val) {
        if (val == true) {

            brow = i.toString();
        }
    });
    $('.tableHeader').each(function(i) {
        if (m < colCount) {

            if (brow == 'mozilla') {

                $(this).css('width', $('#table_div td:eq(' + (m) + ')').innerWidth() - 5); //for assigning width to table Header div
                $(this).children().filter('input').css('width', $('#table_div td:eq(' + (m) + ')').innerWidth() - 19);
            } else if (brow == 'msie') {

                $(this).css('width', $('#table_div td:eq(' + m + ')').width()+5 ); //In IE there is difference of 2 px
                $(this).children().filter('input').css('width', $('#table_div td:eq(' + m + ')').innerWidth()-20 );
            } else if (brow == 'safari') {

                $(this).css('width', $('#table_div td:eq(' + m + ')').width() - 5);
                $(this).children().filter('input').css('width', $('#table_div td:eq(' + m + ')').width() - 15);
            } else {

                $(this).css('width', $('#table_div td:eq(' + m + ')').innerWidth() - 5);
                $(this).children().filter('input').css('width', $('#table_div td:eq(' + m + ')').innerWidth() - 19);
            }
        }
        m++;
    });

};

function editSubject() {
    $('#subjectEditor').trigger('focus');
}

function font_color(palette_type) {
    var palette = "<table><tr>";
    var colors = ['#ff6', '#aff', '#9f9', '#f99', '#f6f', '#800', '#0a0', '#860', '#049', '#909', '#000', '#fff'];
    $(colors).each(function(index, color) {
        palette += '<td ><button onclick="font_' + palette_type + '_color_exec(this)" class="swatch" style="background-color:' + color + ';"></button></td>';
        if ((index % 4) == 3) {
            palette += '</tr><tr>';
        }
    });
    palette += '</tr></table>';


    $('#font_' + palette_type + '_color_btn').clickover({
        'content': palette,
        title: 'Font ' + palette_type + ' Color',
        trigger: 'click',
        placement: 'bottom',
        html: true
    });
}


function font_background_color_exec(swatch) {
    edit_text('backColor', $(swatch).css("background-color"));
}

function font_foreground_color_exec(swatch) {
    edit_text('foreColor', $(swatch).css("background-color"));
}

function add_code() {
   edit_text('formatBlock', 'pre');

}

function add_link() {
    var url = prompt("Please enter URL", "http://www.google.com");
    if (url.substring(0, 4) == "http") {
        edit_text('createLink', url);
    } else {
        alert('Your link must begin with "http"');
    }
}

function edit_text(action) {
    restoreSelection();
    savedElement.contentDocument.execCommand(action, false);
    saveSelection(document.activeElement);
}

function edit_text(action, options) {
    restoreSelection();
    savedElement.contentDocument.execCommand(action, false, options);
    saveSelection(document.activeElement);
}


function get_entry_content(object) {
    while ((object != undefined)) {
        if (object.parentNode == undefined) {
            return undefined;
        }

        var content_obj = $(object.parentNode).find('.entry-body-inner');
        if (content_obj.length > 0) {
            return content_obj[0];
        } else {
            return get_entry_content(object.parentNode);
        }

    }
}

function change_timezone(new_timezone) {
    $.ajax({
        type: 'PUT',
        url: '/scot/user',
        data: JSON.stringify({
            'tzpref': new_timezone
        }),
    }).fail(function() {
        alert('Error: Unable to update your prefered timezone')
    });
}

function robtexIP(entity_value) {
  var loc = 'https://www.robtex.com/ip/' + entity_value + '.html';
  window.open(loc);
}

function robtexDomain(entity_value) {
  var loc = 'https://www.robtex.com/dns/' + entity_value + '.html';
  window.open(loc);
}



function add_menu_option(title, functionCall) {
    var option = $('<button class="btn btn-inverse">').text(title);
    option.click(functionCall);
    $('#entity_toolbar_menu').append(option);
}


function scot(search_for) {
    $.ajax({
        type: 'POST',
        url: '/scot/search',
        data: {
            query: search_for
        }
    }).done(function(response) {
        search_results(response);
    });
}

function plugin() {
  //Create popup prompt
  //Add options to popup prompt


}


$.fn.serializeObject = function()
{
    var o = {};
    var a = this.serializeArray();
    $.each(a, function() {
        if (o[this.name] !== undefined) {
            if (!o[this.name].push) {
                o[this.name] = [o[this.name]];
            }
            o[this.name].push(this.value || '');
        } else {
            o[this.name] = this.value || '';
        }
    });
    return o;
};


function plugin_go(popup, options_td) {
 var entity_value = $(popup).data('entity_value');
 var entity_type = $(popup).data('entity_type');
 var plugin = $(popup).data('plugin');

 var data = {'value': entity_value,
             'type' : entity_type,
             'plugin_id'   : plugin.plugin_id};

 if(options_td != undefined) {
    var options = $(options_td).find('iframe').contents().find('body').find('*').serializeObject();
    data['options'] = options;
 }
 if(plugin.alert_id != undefined) {
    data['target_id'] = plugin.alert_id;
    data['target_type'] = 'alert';
    data['parent'] = 0;
  }
 if(plugin.entry_id != undefined) {
    data['target_id'] = parseInt(current_id);
    data['target_type'] = bottom_mode;
    data['parent'] = plugin.entry_id;
  }

  if(console != undefined) {
     console.log(data);
  }

 $.ajax({
    type: 'POST',
    url:  '/scot/plugininstance',
    data: JSON.stringify(data)
 }).done(function(response) {
     $(popup).find('#plugin_options').html('<h5>Submit Sucessfull :)</h5>');
     $(popup).resize();
 }).fail(function(response) {
     alert('Unable to save plugin request, please inform SCOT admin about this error.');
 });
}

function plugin_handler(entity_value, entity_type, plugin, popup) {
  $(popup).data('plugin', plugin);
  $(popup).data('entity_value', entity_value);
  $(popup).data('entity_type', entity_type);

  $('#plugin_options').remove();
  if(plugin.plugin_html != undefined && plugin.plugin_html != '') {
     var options_td = $('<td colspan="15" style="font-size: 12pt; line-height:12pt;"></td>');
     var options_tr = $('<tr id="plugin_options"></tr>').append(options_td);
     $(popup).find('table').first().append(options_tr);
     var tmpSpan = $('<span style="font-size:12pt"></span>').text(plugin.name);
     $(tmpSpan).append('<br>');
     var tmpInnerSpan = $('<span style="position:relative; left:15px;"></span>');
     var style="<style> body {color:white;}</style>";
     $(tmpInnerSpan).append($('<iframe style="border: 0px solid transparent;" sandbox="allow-same-origin"></iframe>').attr('srcdoc', style + ' ' + plugin.plugin_html));
     $(tmpSpan).append(tmpInnerSpan);
     $(options_td).append(tmpSpan);
     var done = $('<button class="btn">Submit</button>');
     $(done).on('click', function() {
         plugin_go(popup, options_td);
     });
     var cancel = $('<button  style="margin-left:10px;" class="btn">Cancel</button>');
     $(cancel).on('click', function() {
         $(popup).find('#plugin_options').remove();
     });
     $(options_td).append('<br>');
     $(options_td).append(done);
     $(options_td).append(cancel);
     $(popup).resize();
  } else {
     plugin_go(popup);
  }
}

function add_actions(actions, actions_span, entity_value, entity_type,  html, tooltip) {
   $(actions_span).find('.loading').remove();
   $(actions).each(function(index, btn) {
      var button = $('<button style="width:100%" class="btn btn-mini"></button>');
      $(button).text(btn.title);
      if(btn.external) {
          $(button).append('&nbsp; <img style="height:15px;" src="/images/warning.png"></img>');
      }
      button.click(function() {
         btn.funct(entity_value, entity_type, btn.other, html)
      });
      $(actions_span).append(button);
   });
   if(tooltip != undefined) {
     $(tooltip).resize();
   } else {
     setTimeout(function() {  $(tooltip).resize(); }, 500);
   }
}

function add_js_actions(actions_span, entity_value, entity_type, all, tooltip) {
    var actions = new Array();
        actions.push({
            title: 'Search SCOT',
            funct: scot
        });

        if(typeof add_simple_custom_plugins == 'function') {
          actions = actions.concat(add_simple_custom_plugins(entity_type, entity_value));
        }

        switch (entity_type) {
            case "ipaddr":
                actions.push({
                    title: 'Robtex Lookup',
                    funct: robtexIP,
                    external: true
                });
                break;
            case "domain":
                actions.push({
                    title: 'Robtex Lookup',
                    funct: robtexDomain,
                    external: true
                });
                break;
            default:
                break;
        }

        add_actions(actions, actions_span, entity_value, entity_type, all, tooltip);
}

function show_all_references(btn) {
  $(btn).closest('table').find('tr').show();
}

function generate_references_table(response) {
      var types = ['events', 'intels', 'alertgroups'];
      var refs = $('<table style="max-width:350px; display:block; max-height:300px; overflow:auto;" border=1><tr><th>Type</th><th>ID</th><th>Subject</th></tr></table>');
      for(var i = 0; i < types.length; i++) {
            var reference_type = types[i];
            var references = response.data[0][reference_type];
            reference_type = reference_type.substring(0, reference_type.length - 1);
            if (references != undefined) {
                var reference_keys = Object.keys(references);
                var processed = 0;
                $(reference_keys).each(function(index2, reference_key) {
                    processed++;
                    var reference = references[reference_key];
	                var tref = reference_type;
                    if(tref == 'alertgroup') {
            			tref = 'alert/group';
		             }
                    var url = '/#/'+tref+'/'+reference_key;
                    var link = $('<a></a>').attr('href', url).css('color', 'inherit');

                    var tmpTr = $('<tr></tr>');

                    var firstTd = $('<td></td>').append($(link).clone().text(reference_type));
                    $(tmpTr).append(firstTd);

                    var secondTd = $('<td></td>').css('color', 'yellow').append($(link).clone().text(reference_key));
                    $(tmpTr).append(secondTd);

                    var thirdTd = $('<td></td>').css('color', 'lime').append($(link).clone().text(reference.subject));
                    $(tmpTr).append(thirdTd);

                    $(refs).append(tmpTr);
                });
            }
        }
   return refs;
}

function render_notes(response) {
  var user_notes = '';

        var notes = $('<span></span>');
        var notes_data = response.data[0].notes;
        $(Object.keys(notes_data)).each(function(index, note_author) {
            if (note_author == username) {
                user_notes = notes_data[note_author];;
            }
        });
        var entity_value = response.data[0].value;
        var textarea = $('<textarea style="vertical-align:top; font-size:12px; margin-bottom:0px;"></textarea>');
        textarea.text(user_notes);
        var btn = $('<button style="width:100%; margin-bottom:3px;" class="btn btn-mini">Save</button>');
        btn.click(function() {
	    $('.saved_note').remove();
            $(textarea).parent().parent().append('<img style="width:30px; height:30px;" class="saving_note" src="/loading.gif"></img>');
            save_note($(textarea).parent().parent().find('textarea').val(), entity_value);
        });

        var line = $('<b>' + username + ':</b><br>').append('<br>').append(textarea).append('<br>').append(btn);
        var note_div = $('<td></td>').append(line);
        $(Object.keys(notes_data)).each(function(index, note_author) {
            if (note_author != username) {
                note_div.append($('<div></div>').text(note_author + ':' +  notes_data[note_author]));
            }
        });
     return note_div;
}

function addToEntry(entry_id, objToAdd) {
  $(objToAdd).find('button').first().remove();
  var htmlToAppend = $(objToAdd).html();

  $.ajax({
     type: 'GET',
     url:  '/scot/entry/'+entry_id
  }).done(function(response) {
     if(console != undefined) { console.log(response) };
     var newEntry = {body: htmlToAppend, target_type: response.data.target_type, parent: response.data.entry_id, target_id: response.data.target_id, readgroups: response.data.readgroups, modifygroups: response.data.modifygroups};
     $.ajax({
        type: 'POST',
        url: '/scot/entry',
        data: JSON.stringify(newEntry)
     });
  });
}

function infopop(clicked_element, e, left_, top_, ifr) {
    var entity_value = $(clicked_element).data('entity-value');
    var entity_type = $(clicked_element).data('entity-type');
    var alert_id = $(clicked_element).closest('tr').data('alert_id');
    var entry_id = $(ifr).closest('.entry-outer').data('entryId');
    $('.qtip').remove();
    var limit = 100;
    var truncatedNotice = ' (limit = 100 results, hold SHIFT when clicking on flair for full list)';
    if(ctrlDown) {
      limit = -1;
      truncatedNotice = '';
    }
    var promise = $('<span></span>');
    var all = $('<table style="border-right-width:0px;" cellpadding="3" cellspacing="3" border="1"><tr><th>Actions</th><th>References'+truncatedNotice+'</th><th>notes</th><th>other</th></tr><tr><td id="actions"></td><td id="references"></td><td id="notes"></td><td id="other" style="padding-right:20px;"></td></tr></table>');
    $(all).find('tr').last().find('td').each(function(td_idx, td) {
      $(td).append('<img src="/loading.gif" style="width:20px;" class="loading"></img>');
    });
    var actions_span = $(all).find('#actions');
    var references_span = $(all).find('#references');
    var notes_span = $(all).find('#notes');
    var other_span = $(all).find('#other');
    $(promise).append(all);
    var tooltip = $(clicked_element).qtip({
       content: $(promise),
       style: {
          classes: 'qtip-scot'
       },
          hide: 'unfocus',
          position: {
             viewport: $(window),
             adjust: {
                method: 'shift',
             },
            target: [left_, top_]
        },
          show: {
             ready: true,
             event: 'click'
          }
    });

    //Add actions defined in javascript, usually opening a new webpage, or something that doesn't need server interaction
    add_js_actions(actions_span, entity_value, entity_type, promise, tooltip);

     //Check with the server to see which plugins we can run for this entity & add them to the menu
     $.ajax({
       type: 'GET',
       url:  '/scot/plugin/'+entity_type+'/'+entity_value,
    }).done(function(response) {
       if(response != undefined && response.data != undefined) {
           var actions = new Array();
           var plugins = response.data;
           $(plugins).each(function(plugin_index, plugin) {
              plugin.entry_id = entry_id;
              plugin.alert_id = alert_id;
              actions.push({
                 title: plugin.name,
                 funct: plugin_handler,
                 other: plugin
              });
           });
           add_actions(actions, actions_span, entity_value, entity_type, promise, tooltip);
        }
    });
    $.ajax({
        type: 'GET',
        url: '/scot/entity/?match={"entity_value":["' + entity_value + '"]}&limit='+limit,
    }).done(function(response) {
        var html = $('<span></span>');
        var actions = new Array();
        var stuff = $(all).find('tr:nth-child(2)');

        //Generate HTML table with all REFERNCES & add to popup
        var refs = generate_references_table(response);
        $(references_span).html(refs);
        $(tooltip).resize();

        //Generate ui for NOTES
        var notes = render_notes(response);
        $(notes_span).replaceWith(notes);
        $(tooltip).resize();

        // OTHER includes GEO DATA, REPUTATION, ICK DATA, etc.
        $(other_span).html('');
        var addToEntryBtn = $('<button>Add to entry</button>');
        addToEntryBtn.on('click', function() {
            addToEntry(entry_id, other_span);
        });
        $(other_span).append(addToEntryBtn);

        var other = other_span;
        if (response.data[0]['geo_data'] != undefined) {
            $(other).append('<br><div style="font-weight:bold; color:lime;">Geo Location</div><table>');
            var geo = response.data[0].geo_data;

	    $(other).append(tableize(geo));
        }
        if (response.data[0]['reputation'] != undefined) {
            var reputation = response.data[0]['reputation'];
            var reputation_keys = Object.keys(reputation);
            $(reputation_keys).each(function(reputation_index, reputation_key) {
                $(other).append('<div>' + reputation_key + ': ' + reputation[reputation_key] + '</div>');

            });
        }
        if(typeof add_custom_to_popupinfo == 'function') {
           add_custom_to_popupinfo(response.data[0], other);
        }
        if (response.data[0]['proxy'] != undefined) {
            var proxy = response.data[0]['proxy'];
            var proxy_keys = Object.keys(proxy);
            $(proxy_keys).each(function(proxy_index, proxy_key) {
                $(other).append('<div>' + proxy_key + ': ' + proxy[proxy_key] + '</div>');

            });
        }
        $(tooltip).resize();
    });
}

function tableize(obj, stopkeys) {
   if(Object.prototype.toString.call (obj ) === '[object Object]') {
   var keys = Object.keys(obj);
   var str = '<table border=1 style="width:100%" class="reasonable_table">';
   var row_num = 1;
   $(keys).each(function(idx, key) {
      if($.inArray(key, stopkeys) == -1) {
         row_num++;
         var val = obj[key];
         if(typeof val == 'object' && val != null && JSON.stringify(val) != '[]') {
             if(Object.prototype.toString.call( val ) === '[object Array]') {
	        var ree = '';
                $(val).each(function(idx, part) {
                  ree += tableize(part);
                });
		val = ree;
             } else {
                val = tableize(val);
             }
         }
         if(key == 'photo') {
            val = '<img src="'+val+'" style="width:75px;"></img>';
         }
         var color = '#000';
         if(row_num % 2 == 0) {
           color = '#444';
         }
         str += '<tr style="background-color:'+color+'; padding-bottom:1px; padding-top:1px;"><td style="margin-left:3px; padding-right:3px; font-weight:bold; color: #CFF;">' + key + '</td><td style="margin-left:3px; padding-right:3px;">' + val + '</td></tr>';
      }
   });
   str += '</table>';
   return str;
   } else {
      return ' '+ obj + ' ';
   }
}

function saveSelection(obj, winIN) {
    var win = winIN == undefined ? window : winIN;

    if (win.getSelection) //non IE Browsers
    {
        var selec = win.getSelection();
        if(selec.type != "None" && selec.isCollapsed == false) {
           console.log('Debug: unflairing selection');
           if(flairState) { 
              setFlairSingle(false, obj);
           }
           savedRange = selec.getRangeAt(0);
           savedElement = obj;
        } else {
           if(!flairState) {
              setFlairSingle(true, obj);
           }
        }
    } else if (document.selection) //IE
    {
        savedRange = document.selection.createRange();
        savedElement = obj;
    }
}

function restoreSelection() {
    isInFocus = true;
    savedElement.focus();
    if (savedRange != null) {
        if (window.getSelection) //non IE and there is already a selection
        {
            var s = window.getSelection();
            if (s.rangeCount > 0)
                s.removeAllRanges();
            s.addRange(savedRange);
        } else
        if (document.createRange) //non IE and no selection
        {
            window.getSelection().addRange(savedRange);
        } else
        if (document.selection) //IE
        {
            savedRange.select();
        }
    }
}

function save_note(new_val, entity_value) {
    $.ajax({
        type: 'PUT',
        url: '/scot/entity',
        data: JSON.stringify({
            'note': new_val,
            'entity_value': entity_value
        })
    }).done(function(response) {
       $('.saving_note').replaceWith('<img src="check.png" class="saved_note" style="height:30px; width:30px;"></img>');
    });
}
//this part onwards is only needed if you want to restore selection onclick
var isInFocus = false;

function onDivBlur() {
    isInFocus = false;
}

function cancelEvent(e) {
    if (isInFocus == false && savedRange != null) {
        if (e && e.preventDefault) {
            //alert("FF");
            e.stopPropagation(); // DOM style (return false doesn't always work in FF)
            e.preventDefault();
        } else {
            window.event.cancelBubble = true; //IE stopPropagation
        }
        restoreSelection();
        return false; // false = IE style
    }
}

function uniqueStrings(ArrayInput) {

    var uniqueArray = [];
    var arrayLength = ArrayInput.length;

    for (var i = 0; i < arrayLength; i++) {
        if (uniqueArray.indexOf(ArrayInput[i]) == -1) {
            uniqueArray.push(ArrayInput[i]);
        }
    }
    return uniqueArray;
}


function goto_page(adjustment) {
    //adjustment can be 'first', 'previous', 'next', 'last'
    var page = 0;
    var current_page = 0;
    var first_page = 0;
    var last_page = 0;
    current_page = parseInt($('#current_page').val()) || 0;
    page = current_page;
    last_page = parseInt($('#num_pages').text()) || current_page;


    switch (adjustment) {
        case 'first':
            page = first_page;
            break;
        case 'previous':
            if (current_page >= (first_page + 1)) {
                page = (current_page - 1);
            } else {
                page = first_page;
            }
            break;
        case 'next':
            if (current_page <= (last_page - 1)) {
                page = (current_page + 1);
            } else {
                page = last_page;
            }
            break;
        case 'last':
            page = last_page;
            break

    }
    $('#current_page').val(page);
    $('#first').prop('disabled', (page <= first_page));
    $('#previous').prop('disabled', (page <= first_page));
    $('#next').prop('disabled', (page >= last_page));
    $('#last').prop('disabled', (page >= last_page));
    if (current_page != page) {
        current_page = page;
        grid_filter_updated(false);
    }

}

function html_edit() {
    restoreSelection();
    var doc = document.activeElement;
    if ($(doc).data('isHtml') == 1) {
        var text = $(doc).contents().find('body').text();
        $(doc).contents().find('body')[0].innerHTML = text;
        $(doc).data('isHtml', 0);
    } else {
        var html = $(doc).contents().find('body').html();
        $(doc).contents().find('body').text(html);
        $(doc).data('isHtml', 1);
    }
}

//This will intercept paste events in non FireFox browsers
// to support conversion of images to the data:uri convention
function nonFireFoxPaste(event) {
  var items = (event.clipboardData || event.originalEvent.clipboardData).items;
  var blob = items[0].getAsFile();
  var reader = new FileReader();
  //Element where paste was initiated from inside the entry
  var addTo = event.target;
  reader.onload = function(event){
    //File ahs finished reading, contents are in event.target.result
    //Append image as data:uri
    $(addTo).append('<img src="'+event.target.result+'"></img>');
  }
  reader.readAsDataURL(blob);
}
var isiOS = false;

$(document).ready(function() {
   var isChrome = /Chrome/.test(navigator.userAgent) && /Google Inc/.test(navigator.vendor);
   var isSafari = /Safari/.test(navigator.userAgent) && /Apple Computer/.test(navigator.vendor);

   if(isChrome || isSafari) {
      document.onpaste = nonFireFoxPaste;
   }
	var agent = navigator.userAgent.toLowerCase();
	if(agent.indexOf('iphone') >= 0 || agent.indexOf('ipad') >= 0){
		   isiOS = true;
	}

	$.fn.doubletap = function(onDoubleTapCallback, onTapCallback, delay){
		var eventName, action;
		delay = delay == null ? 500 : delay;
		eventName = isiOS == true ? 'touchend' : 'click';

		$(this).bind(eventName, function(event){
			var now = new Date().getTime();
			var lastTouch = $(this).data('lastTouch') || now + 1 /** the first time this will make delta a negative number */;
			var delta = now - lastTouch;
			clearTimeout(action);
			if(delta < 500 && delta>0){
				if(onDoubleTapCallback != null && typeof onDoubleTapCallback == 'function'){
					onDoubleTapCallback(event);
				}
			}else{
				$(this).data('lastTouch', now);
				action = setTimeout(function(evt){
					if(onTapCallback != null && typeof onTapCallback == 'function'){
						onTapCallback(evt);
					}
					clearTimeout(action);   // clear the timeout
				}, delay, [event]);
			}
			$(this).data('lastTouch', now);
		});
	};
});
