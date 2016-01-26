var React           = require('react');
var ReactTime       = require('react-time');
var EntryParent     = require('./entry_parent.jsx');

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

module.exports = EntryData;
