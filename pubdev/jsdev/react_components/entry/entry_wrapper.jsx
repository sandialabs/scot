var React = require('react');
var ReactDOM = require('react-dom');
var EntryData = require('./entry_data.jsx');

var EntryWrapper = React.createClass({
    render: function() {
        var rows = [];
        var data = this.props.entrydata; 
        data.forEach(function(data) {
            rows.push(new Array(<EntryData items = {data}/>));
        });
        return (
        <div>
            <div className="row-fluid entry-wrapper">        
                {rows}
            </div>
        </div>
        );
    }
});

module.exports = EntryWrapper;
