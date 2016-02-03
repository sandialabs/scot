var React           = require('react');
var ReactTime       = require('react-time');

var EntryWrapper = React.createClass({
    getInitialState: function() {
        return {
            showEntryData:false,
            entryData:''
        }
    },
    componentDidMount: function() {
        this.headerRequest = $.get('scot/api/v2/' + this.props.type + '/' + this.props.id + '/entry', function(result) {
            var entryResult = result.records;
            this.setState({showEntryData:true, entryData:entryResult})
        }.bind(this));
    },
    render: function() { 
        var data = this.state.entryData; 
        return (
        <div>
            <div className="row-fluid entry-wrapper">
                {this.state.showEntryData ? <EntryIterator data={data}/> : null}
            </div>
        </div>
        );
    }
});

var EntryIterator = React.createClass({
    render: function() {
        var rows = [];
        var data = this.props.data
        data.forEach(function(data) {
            rows.push(new Array(<EntryData items={data}/>));
        });
        return (
            <div>{rows}</div>
        )
    }
});

var EntryData = React.createClass({
    render: function() {
        var itemarr = [];
        var subitemarr = [];
        var items = this.props.items;
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
        };
        itemarr.push(subitemarr);
        return (
            <div className="row-fluid entry-outer todo_undefined_outer" style={{marginLeft: 'auto', marginRight: 'auto', width:'99.3%'}}>
                <span className="anchor" id={items.id} />
                    <div className="row-fluid entry-header todo_undefined">
                        <div className="entry-header-inner">[<a style={{color:'black'}} href={"#"+items.id}>{items.id}</a>] <ReactTime value={items.created * 1000} format="MM/DD/YYYY hh:mm:ss a" /> by {items.owner} (updated on <ReactTime value={items.updated * 1000} format="MM/DD/YYYY hh:mm:ss a" />)</div>
                    </div>
                {itemarr}
            </div>
        );
    }
});

var EntryParent = React.createClass({
    /*iframe: function() {
        var rawMarkup = this.props.subitem.body_flair
       var ifr = $('<iframe style={{width:"100%"}} sandbox="allow-popups allow-same-origin"></iframe>').attr('srcdoc', '<link rel="stylesheet" type="text/css" href="sandbox.css"></link><body>' + rawMarkup + '</body>');
        var iframe = '<iframe srcDoc="dangerouslySetInnerHTML={{ __html: '+{rawMarkup}+'}}"></iframe>'
        console.log(rawMarkup);
        console.log(iframe);
        return ifr
    },
    norender: function() {
        var rawMarkup = this.props.subitem.body_flair;
        return (
            <div>
                <iframe srcDoc={rawMarkup}></iframe>
            </div>
        )
    },*/
    render: function() {
        var rawMarkup = this.props.subitem.body_flair;
        return (
            <div className="row-fluid entry-body">
                <div className="row-fluid entry-body-inner" style={{marginLeft: 'auto', marginRight: 'auto', width:'99.3%'}} dangerouslySetInnerHTML={{ __html: rawMarkup }}/>
            </div>
        )
    }
});

module.exports = EntryWrapper;
