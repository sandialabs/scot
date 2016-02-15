var React           = require('react');
var ReactTime       = require('react-time');
var SplitButton     = require('react-bootstrap/lib/SplitButton.js');
var DropdownButton  = require('react-bootstrap/lib/DropdownButton.js');
var MenuItem        = require('react-bootstrap/lib/MenuItem.js');
var Button          = require('react-bootstrap/lib/Button.js');
var AddEntryModal   = require('../modal/add_entry.jsx');
var DeleteEntry     = require('../modal/delete.jsx').DeleteEntry;

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
    updated: function () {
        this.headerRequest = $.get('scot/api/v2/' + this.props.type + '/' + this.props.id + '/entry', function(result) {
            var entryResult = result.records;
            this.setState({showEntryData:true, entryData:entryResult})
        }.bind(this));
        console.log('Ran update');
    },
    render: function() { 
        var data = this.state.entryData; 
        var type = this.props.type;
        var id = this.props.id;
        return (
            <div className="row-fluid entry-wrapper"> 
                {this.state.showEntryData ? <EntryIterator data={data} type={type} id={id} updated={this.updated} /> : null}
            </div>       
        );
    }
});

var EntryIterator = React.createClass({
    render: function() {
        var rows = [];
        var data = this.props.data;
        var type = this.props.type;
        var id = this.props.id; 
        var updated = this.props.updated;
        data.forEach(function(data) {
            rows.push(new Array(<EntryParent items={data} type={type} id={id} updated={updated} />));
        });
        return (
            <div>
                {rows}
            </div>
        )
    }
});

var EntryParent = React.createClass({
    getInitialState: function() {
        return {
            entryToolbar:false,   
            deleteToolbar:false
        }
    },
    entryToggle: function() {
        if (this.state.entryToolbar == false) {
            this.setState({entryToolbar:true})
        } else {
            this.setState({entryToolbar:false})
        } 
    },
    deleteToggle: function() {
        if (this.state.deleteToolbar == false) {
            this.setState({deleteToolbar:true})
        } else {
            this.setState({deleteToolbar:false})
        }
    }, 
    render: function() {
        var itemarr = [];
        var subitemarr = [];
        var items = this.props.items;
        var type = this.props.type;
        var id = this.props.id; 
        var updated = this.props.updated;
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
                                <SplitButton bsSize='xsmall' title="Reply" key={items.id} id={'Reply '+items.id} onClick={this.entryToggle}>
                                    <MenuItem eventKey='1' onClick={this.entryToggle}>Move</MenuItem>
                                    <MenuItem eventKey='2' onClick={this.deleteToggle}>Delete</MenuItem>
                                    <MenuItem eventKey='3'>Mark as Summary</MenuItem>
                                    <MenuItem eventKey='4'>Make Task</MenuItem>
                                    <MenuItem eventKey='5'>Permissions</MenuItem>
                                </SplitButton>
                                <Button bsSize='xsmall' onClick={this.entryToggle}>Edit</Button>
                            </span>
                        </div>
                    </div>
                {itemarr}
                </div>
                {this.state.entryToolbar ? <AddEntryModal type={type} id={id} entryToggle={this.entryToggle} /> : null}
                {this.state.deleteToolbar ? <DeleteEntry type={type} id={id} deleteToggle={this.deleteToggle} entryid={items.id} updated={updated} /> : null}
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
