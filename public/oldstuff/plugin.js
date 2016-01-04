var clicked_plugin_div;
$(document).ready(doeet);

function bind_rename(plugin_div) {
  $(plugin_div).on('keypress blur paste keyup', function(data) {
    var plugin_id = $(plugin_div).data('plugin_id');
    var new_plugin_name = $(plugin_div).text();
    $.ajax({
       type: 'PUT',
       url:  '/scot/plugin/'+plugin_id,
       data: JSON.stringify({name: new_plugin_name})
    });
  });
  return plugin_div;
}

function newPlugin() {
  var plugin_div = $('<div contenteditable></div>').text('Rename Me').click(plugin_click);
  plugin_div = bind_rename(plugin_div);
  $('#plugin_list').append(plugin_div);
  $.ajax({
    type: 'POST',
    url:  '/scot/plugin',
    data: JSON.stringify({name: 'Rename Me', 'readgroups':['scot'], 'modifygroups':['scot']})
  }).done(function(data) {
    console.log(data);
    var id = parseInt(data.id);
    if(id == NaN) {
       alert('error creating plugin, make sure you are connected to the network and try again.');
       $(plugin_div).remove();
    } else {
       $(plugin_div).data('plugin_id', id);
    }
  });
}

function deletePlugin() {
  var plugin_id = $('#plugin_id').val();
  if (plugin_id != undefined && plugin_id != '') {
    if(clicked_plugin_div != undefined) {
      $(clicked_plugin_div).remove();
    }
    $('#delete_button').hide();
    $.ajax({
      type: 'DELETE',
      url:  '/scot/plugin/'+plugin_id
    });
  }
}

$(function() {
    $( document ).tooltip({items: "img[title]",
        content: function() { 
		return $(this).attr("title")
	 }}
    );
});

function preview_html(){
   $('#preview').html('');
   if($('#preview_checkbox').prop('checked')) {
     var plugHTML = $('#plugin_html').val();
     var ifr = $('<iframe></iframe').attr('srcdoc', plugHTML).attr('sandbox', '').css('width', '100%'); 
     $('#preview').append(ifr);
   } 
   
}

function plugin_click(e) {
  $('.loading').remove();
  clicked_plugin_div = e.target;
  $('#delete_button').show();
  $('#details').hide();
  $('#plugin_html').html('');
  $('#plugin_id').val('');
  var plugin = $(e.target).data();
  var plugin_name = plugin.name;
  $('#plugin_id').val(plugin.plugin_id);
  console.log(plugin_name);
  $('#file_field').val(plugin.file_field);
  $('input:radio, input:checkbox').each(function(index, radio) {
     radio.checked = false;
  });
  if(plugin.type != undefined) {
     $('input:radio[name=type][value='+plugin.type+']').prop('checked', true);
  }
  $('#submitURL').val(plugin.submitURL);
  $('#statusURL').val(plugin.statusURL);
  $('#plugin_html').on('keyup', preview_html);
  $('#plugin_html').text(plugin.plugin_html);
  $('#run').val(plugin.run);
  $('#edit').val(plugin.edit);
  $(plugin.entity_types).each(function(index, entity) {
     $('input:checkbox[name=entity_types][value='+entity+']')[0].checked = true;
  });
  var file = $('input:checkbox[name=entity_types][value=file]')[0];
  toggle_file_form_name(file); 
  preview_html();
  $('#details').show();
}

function doeet() {
  $.ajax({
    type: 'GET',
    url:  '/scot/plugin'
  }).done(function(response) {
     $(response.data).each(function(index, plugin) {
        var plugin_name = plugin.name;
        var plugin_div = $('<div contenteditable></div>').text(plugin_name).click(plugin_click);
        plugin_div = bind_rename(plugin_div);
        $(plugin_div).data(plugin);
        $('#plugin_list').append(plugin_div);
     });
  });
}

$.fn.serializeObject = function()
{
   var o = {};
   var a = this.serializeArray();
   $.each(a, function() {
       if (o[this.name]) {
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


function save() {
  var data =  $('#plugin_details_form').serializeObject();
  var plugin_id = $('#plugin_id').val();
  $('#save').append('<span class="loading">SaViNg...<img style="width:20px;" src="/loading.gif" ></img></span>');
  if(typeof data.entity_types === 'string') {
     data.entity_types = [data.entity_types];
  }
  $.ajax({
    type: 'PUT',
    url: '/scot/plugin/'+ plugin_id,
    data: JSON.stringify(data)
  }).complete(function() {
     $('.loading').html('Saved ' + new Date);
  }); 
}

function test() {
  alert('Sorry, this test functionality has not yet been implemented');
}

function toggle_file_form_name(checkbox) {
  if(checkbox.checked) {
     $('#file_form_name').show();
  } else {
     $('#file_form_name').hide();
  }
}
