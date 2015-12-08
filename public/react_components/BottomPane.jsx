var React     = require('react');
var ReactDOM  = require('react-dom');

//function getEvent(callback) {
function getEvent() {
        var jsonData = {};
        $.ajax({
            type: 'GET',
            url: '/scot/api/v2/entry',
            dataType: 'json',
            async: false,
            success: function(data, status) {
            jsonData = data;
            //handleData(data);
        },
        error: function(err) {
            console.error(err.toString());
        }
        });
        return jsonData.records;
    /*var xhttp = new XMLHttpRequest();
    xhttp.onreadystatechange = function(){
        if (xhttp.readyState == 4 && xhttp.status == 200) {
            callback(xhttp.responseText);        
        }
    };
    xhttp.open("GET", "/scot/api/v2/entry", true);
    xhttp.send();*/
};

var TableData = React.createClass({
    render: function() {
        return (
            <tr>
                <td className="col-md-6 stat-col-num">{this.props.item.body}</td>
            </tr>
        );
    }
});

var Table = React.createClass({
    render: function() {
        var rows = [];
        this.props.data.forEach(function(data) { 
            rows.push(<TableData item = {data} />)
        });
        return (
            <table width="100%" className="info-box-margin">
                <thead>Entry Table Header</thead>
                <tbody>{rows}</tbody>
            </table>
        );
    }
});

var displaydata = getEvent();
console.log(displaydata);
for (i = 0; i < displaydata.length; i++) {
    console.log("object each item of object: " + displaydata[i].body)
}
console.log("for loop ended");


ReactDOM.render(<Table data={displaydata}/>, document.getElementById('NewBottomDataPane'));
 
