var React     = require('react');
var ReactDOM  = require('react-dom');

//function getEvent(callback) {
function getEvent(id) {
        var jsonData = {};
        $.ajax({
            type: 'GET',
            url: '/scot/api/v2/event/'+ id + '/entry',
            dataType: 'json',
            async: false,
            success: function(data, status) {
            jsonData = data;
            //console.log(jsonData);
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

var TableHeader = React.createClass({
    render: function() {
        return (
            <div className="" style={{}}>
                <div className="" style={{}}>{this.props.item.id}</div>
            </div>
        );
    }
});

var TableSubData = React.createClass({
    render: function() {
        var rawMarkup = this.props.subitem.body_flair;
        return (
            <div className="row-fluid entry-outer todo_undefined_outer">
                <div dangerouslySetInnerHTML={{__html: rawMarkup}} />
            </div>
        );
    }
});

var TableSubRecursion = React.createClass({
    render: function() {
        var rows = [];
        var count = 0;
        console.log("in sub");
        recursiveIter(this.props.subitem);
        console.log("out of iteration");
        count ++;
        function recursiveIter(obj) {
            for (var prop in obj) {
                //console.log(obj[prop]);
                if (prop == "children") {
                    var childobj = obj[prop];
                    obj[prop].forEach(function(childobj) {                        
                        //console.log(childobj.body_flair);
                        //var childobjbody = childobj.body_flair;
                        rows.push(new Array(<TableSubData subitem = {childobj} />));
                        //for (var key in childobj) {
                            //rows.push(<TableData item = {childobj} />)
                        //}
                        recursiveIter(childobj);
                    });
                }
            }
        }
        return (
            <div>{rows}</div>
        )
    }
});

var TableData = React.createClass({
    render: function() {
        var rawMarkup = this.props.item.body_flair;
        return (
            <div className="row-fluid entry-outer todo_undefined_outer" style={{marginLeft: 'auto', marginRight: 'auto',width:'99.3%'}}>
                <div className="row-fluid entry-header todo_undefined">
                    <div className="entry-header-inner">{this.props.item.id} {this.props.item.when} by {this.props.item.owner}</div>
                </div>
                <div className="row-fluid entry-body">                    
                    <div dangerouslySetInnerHTML={{__html: rawMarkup}} />
                    //{this.props.item.body_flair}
                    <TableSubRecursion subitem = {this.props.item} />                    
                </div>
            </div>    
        );
    }
});

var Table = React.createClass({
    render: function() {
        var header = [];
        var rows = [];
        this.props.data.forEach(function(data) {  
            rows.push(<TableData item = {data} />)   
        });
        return ( 
            <div>
                <div width="100%" className="alerts events incidents tasks" style={{height: '800px', overflow: 'auto', display: 'block'}}>
                    <div>{header}</div>
                    <div>{rows}</div>
                </div>
            </div>
        );
    }
});

var displaydata = getEvent(3306);
/*console.log(displaydata);
for (i = 0; i < displaydata.length; i++) {
    console.log("object each item of object: " + displaydata[i].id)
}
console.log("for loop ended");
*/

ReactDOM.render(<Table data={displaydata}/>, document.getElementById('NewBottomDataPane'));
 
