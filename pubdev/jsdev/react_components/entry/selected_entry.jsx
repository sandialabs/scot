var React           = require('react');
var ReactTime       = require('react-time');
var SplitButton     = require('react-bootstrap/lib/SplitButton.js');
var DropdownButton  = require('react-bootstrap/lib/DropdownButton.js');
var MenuItem        = require('react-bootstrap/lib/MenuItem.js');
var Button          = require('react-bootstrap/lib/Button.js');
var SelectedEntry = React.createClass({
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
            <div className="row-fluid entry-wrapper"> 
                {this.state.showEntryData ? <EntryIterator data={data}/> : null}
            </div>       
        );
    }
});

var EntryIterator = React.createClass({
    render: function() {
        var rows = [];
        var data = this.props.data 
        data.forEach(function(data) {
            rows.push(new Array(<EntryParent items={data}/>));
        });
        return (
            <div>
                {rows}
            </div>
        )
    }
});

var EntryParent = React.createClass({
    render: function() {
        var itemarr = [];
        var subitemarr = [];
        var items = this.props.items;
        itemarr.push(<EntryData subitem = {items} />);
        for (var prop in items) {
            childfunc(prop);
            function childfunc(prop){
                if (prop == "children") {
                    var childobj = items[prop];
                    items[prop].forEach(function(childobj) {
                        subitemarr.push(new Array(<EntryParent items = {childobj} />));  
                    });
                }
            }
        };
        itemarr.push(subitemarr);
        return (
            <div> 
                <div className="row-fluid entry-outer todo_undefined_outer" style={{marginLeft: 'auto', marginRight: 'auto', width:'99.3%'}}>
                    <span className="anchor" id={items.id}/>
                    <div className="row-fluid entry-header todo_undefined">
                        <div className="entry-header-inner">[<a style={{color:'black'}} href={"#"+items.id}>{items.id}</a>] <ReactTime value={items.created * 1000} format="MM/DD/YYYY hh:mm:ss a" /> by {items.owner} (updated on <ReactTime value={items.updated * 1000} format="MM/DD/YYYY hh:mm:ss a" />)
                            <span className='pull-right'>
                                <SplitButton bsSize='xsmall' title="Reply" key={items.id} id={'Reply '+items.id}>
                                    <MenuItem eventKey='1' onClick={this.props.entryToggle}>Move</MenuItem>
                                    <MenuItem eventKey='2'>Delete</MenuItem>
                                    <MenuItem eventKey='3'>Mark as Summary</MenuItem>
                                    <MenuItem eventKey='4'>Make Task</MenuItem>
                                    <MenuItem eventKey='5'>Permissions</MenuItem>
                                </SplitButton>
                                <Button bsSize='xsmall'>Edit</Button>
                            </span>
                        </div>
                    </div>
                {itemarr}
            </div>
            </div>
        );
    }
});

var EntryData = React.createClass({
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

module.exports = SelectedEntry;
