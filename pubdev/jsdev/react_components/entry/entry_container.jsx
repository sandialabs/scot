var React = require('react');
var EntryHeader = require('./entry_header.jsx');
var EntryWrapper = require('./entry_wrapper.jsx');

var EntryContainer = React.createClass({
    getEventData: function(id,type,datarows) {
        var jsonData = {};
        $.ajax({
            type: 'GET',
            url: '/scot/api/v2/' + type + '/'  + id,
            dataType: 'json', 
            async: false,
            success: function(data, status) {
                jsonData = data;
                datarows.push(<EntryHeader id={id} data={jsonData} type={type}/>);
            },
            error: function(err) {
                console.error(err.toString());
            }
        });
    },
    getEntryData: function(id,type,datarows) {
        var jsonData = {};
        $.ajax({
            type: 'GET',
            url: '/scot/api/v2/' + type + '/'+ id + '/entry',
            dataType: 'json',
            async: false,
            success: function(data, status) {
                jsonData = data.records;
                datarows.push(<EntryWrapper id={id} entrydata={jsonData} />);
            },
            error: function(err) {
                console.error(err.toString());
            }
        });
    },
    render: function() {
        var datarows = [];
        var ids = this.props.ids;
        var type = this.props.type;
        for (i=0; i < ids.length; i++) { 
            datarows.push(<EntryHeader id={ids[i]} type={type}/>);
            //this.getEventData(ids[i],type,datarows);
            //this.getEntryData(ids[i],type,datarows);
        }
        return (
            <div className="entry-container">
                {datarows}
            </div>
        );
    }
});

module.exports = EntryContainer;
