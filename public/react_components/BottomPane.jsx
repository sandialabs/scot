var React       = require('react');
var ReactDOM    = require('react-dom');
var ReactTime        = require('react-time');
var url         = "/scot/api/v2/event"
function getEntry(id) {
        var jsonData = {};
        $.ajax({
            type: 'GET',
            url: '/scot/api/v2/event/'+ id + '/entry',
            dataType: 'json',
            async: false,
            success: function(data, status) {
            jsonData = data;
        },
        error: function(err) {
            console.error(err.toString());
        }
        });
        return jsonData.records;
};

function DateConvert(inDate) {
    var date = new Date(0);
    date.setUTCSeconds(inDate);
    JSON.stringify(date);
    console.log(typeof date);
    console.log(date);
    return date;
}

var TableHeader = React.createClass({
    render: function() {
        return (
            <div className="" style={{}}>
                <div className="" style={{}}>{this.props.item.id}</div>
            </div>
        );
    }
});

var EntryParent = React.createClass({
    render: function() {
        var rawMarkup = this.props.subitem.body_flair
        return (
            <div className="row-fluid entry-body">
                <div className="row-fluid entry-body-inner" dangerouslySetInnerHTML={{__html: rawMarkup}}/>     
            </div>
        )
    }
});

var EntryData = React.createClass({
    render: function() { 
        var itemarr = [];
        var subitemarr = [];
        var items = this.props.items;
        //items.when = items.when * 1000; 
        itemarr.push(<EntryParent subitem = {items} />);
        for (var prop in items) {            
            childfunc(prop);
            function childfunc(prop){
                if (prop == "children") {
                    var childobj = items[prop];
                    items[prop].forEach(function(childobj) {
                        subitemarr.push(new Array(<EntryData items = {childobj} />));       
                    });
                }
            }    
        }   
        itemarr.push(subitemarr);
        return (                                                  
            <div className="row-fluid entry-outer todo_undefined_outer" style={{marginLeft: 'auto', marginRight: 'auto', width:'99.3%'}}>
                <div className="row-fluid entry-header todo_undefined">
                    <div className="entry-header-inner">{items.id} <ReactTime value={items.created * 1000} format="MM/DD/YYYY hh:mm:ss a" /> by {items.owner} (updated on <ReactTime value={items.updated * 1000} format="MM/DD/YYYY hh:mm:ss a" />)</div>
                </div>
                {itemarr}
            </div>
        );
    }
});

var EntryMain = React.createClass({
    render: function() {
        var header = []; 
        var masterrows = [];
        var ids = this.props.ids;
        for (i=0; i < ids.length; i++) {
            var idnum = ids[i];
            var data = getEntry(idnum);
            masterrows.push(<EntryWrapper data={data} id={idnum} />);
        }
        return (   
            <div>
                {header}
                {masterrows}
            </div> 
        );
    }
});
var EntryWrapper = React.createClass({
    render: function() {
        var rows = [];
        this.props.data.forEach(function(data) {  
            rows.push(new Array(<EntryData items = {data} />)); 
        });
        var rawMarkup = this.props.id;
        return (
            <div className="row-fluid entry-wrapper">
                <div className="row-fluid entry-wrapper-id">Event ID: {rawMarkup}</div>
                {rows}
            </div>
        );
    }
});


var ids = [3309,3308]
ReactDOM.render(<EntryMain ids={ids}/>, document.getElementById('NewBottomDataPane'));

