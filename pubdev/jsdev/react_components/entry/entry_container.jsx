var React = require('react');
var EntryHeader = require('./entry_header.jsx');
var EntryWrapper = require('./entry_wrapper.jsx');

var EntryContainer = React.createClass({
    getEventData: function(id,datarows) {
        var jsonData = {};
        $.ajax({
            type: 'GET',
            url: '/scot/api/v2/event/' + id,
            dataType: 'json', 
            async: false,
            success: function(data, status) {
                jsonData = data;
                datarows.push(<EntryHeader id={id} data={jsonData} />);
            },
            error: function(err) {
                console.error(err.toString());
            }
        });
    },
    getEntryData: function(id,datarows) {
        var jsonData = {};
        $.ajax({
            type: 'GET',
            url: '/scot/api/v2/event/'+ id + '/entry',
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
        for (i=0; i < ids.length; i++) { 
            this.getEventData(ids[i],datarows);
            this.getEntryData(ids[i],datarows);
        }
        return (
            <div className="entry-container">
                {datarows}
            </div>
        );
    }
});

module.exports = EntryContainer;
