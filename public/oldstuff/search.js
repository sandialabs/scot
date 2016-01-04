function search_results_scot(results, fullResults, outputLocation) {
   var results_html = "";
   var num_results = 0;
   results_html += '<table id="live_results_table" class="display" >'; //class="grid-table table table-scot-striped table-bordered table-condensed results-table">';
   results_html += '<thead><tr><th>Type</th><th>Id</th><th>Subject</th><th>Snippet(s)</th></tr></thead><tfoot style="display:none"><tr><th>Type</th><th>Id</th><th>Subject</th><th>Snippet(s)</th></tr></tfoot><tbody>';
   var types = new Array('event', 'alertgroup');
   $(types).each(function(index, type) {
     if(results.data[type] == undefined) {
       return 0;
     }
     var result_ids = Object.keys(results.data[type]);
     $(result_ids).each(function(result_idx, result_id) {
       var result = results.data[type][result_id];
       var subject = result.subject;
       var hash_type = type;
       if(type == 'alertgroup') {
          hash_type = 'alert/group';
       }
       var url = '/#/'+hash_type+'/'+result_id;
       var snippet = '';
       $(result.res).each(function(res_id, re) {
           var additional = '';
           if(type == 'event') {
              additional = '/'+re.id;
           }
           snippet += ' ...<a href="'+url+additional+'">'+re.snippet+'</a>...<br> ';
       });

       if(subject != undefined) {
          var row = '<tr>';
          row += td_link([type, result_id, subject ], url, []);
          row += '<td style="white-space:nowrap; font-family:courier; width:50%;">'+snippet+'</td>';
          row += '</tr>';
          num_results++;
          results_html += row;
       }
     });
   });
   results_html += '</tbody></table>';
   if(!fullResults) {
     results_html = '<div><span onclick="popout_search_results()" style="text-decoration:underline; color:blue; cursor:pointer; font-size:12pt;">Run full search in new window <img src="/images/popout.png" id="popout"></img></span><br>This is just a preview (top 100 events & top 100 alerts)</div><br>' + results_html;
   }
   var res = $('<span></span>').html(results_html);
   $(outputLocation).show();
   $(outputLocation).html(results_html);
   if(!fullResults) {
      $('body').append('<div id="closer" onclick="close_results()" style="height:100%; width:100%; display:block; position:absolute; top:0px; left:0px; z-index:500"></div>');
   }
   $('#live_results_table').dataTable({
      "order" : [[0, "desc"],[1, "desc"]],
      "lengthChange" : false,
      "scrollY": 400,
      "paging": false
   }).columnFilter({
       sPlaceHolder : "head:after",
       aoColumns: [
        { type: "select",
          values: ['alertgroup', 'event']
        },
        { type: "number"
        },
        {type : "text"},
        {type : "text"}
       ]
   });
}

function submit_search(term, fullResults) {
  var data = {query: term};
  if(fullResults) {
     data['limit'] = -1;
  } 
  var outputLocation = $('#live_results');
  if(fullResults) {
    outputLocation = $('body');
  }
  $(outputLocation).html('<center><img src="/loading.gif"></img><br>Loading Results...</center>');
  $('#2search').after('<img src="/loading.gif" style="width:15px; position:absolute; right:20px; top:7px; height:15px" id="searching_gif"></img>');
  search = $.ajax({
     url: '/scot/ssearch',
     type: 'POST',
     data: data
  }).done(function(response) {
     $('#searching_gif').remove();
     search_results_scot(response, fullResults, outputLocation);
  }).fail(function(response) {
    outputLocation.html('<center><h2>Error running search</h2></center>'); 
    $('#searching_gif').attr('src', '/images/close_toolbar.png');
  });
}

function td_link(texts, link, noSanitizeList) {
  var result = '';
  $(texts).each(function(index,text) {
     var sanitized_text = text;
     if(jQuery.inArray(text, noSanitizeList) == -1) {
        sanitized_text = htmlEntities(text);
     }
     result += '<td><a href="'+link+'">'+sanitized_text+'</a></td>';
  });
  return result;
}

var htmlEntities = function(str) {
    if(str == undefined) 
       return '';
    return str.replace(/[\u00A0-\u99999<>\&]/gim, function(i) {
        return '&#'+i.charCodeAt(0)+';';
    });
};
