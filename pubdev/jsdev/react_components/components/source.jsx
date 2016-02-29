var React               = require('react');
var Button              = require('react-bootstrap/lib/Button');
var ReactTags           = require('react-tag-input').WithContext;

var Source = React.createClass({
    getInitialState: function() {
        return {sourceEntry:false}
    },
    toggleSourceEntry: function () {
        if (this.state.sourceEntry == false) {
            this.setState({sourceEntry:true})
        } else if (this.state.sourceEntry == true) {
            this.setState({sourceEntry:false})
        };
    },
    render: function() {
        var rows = [];
        var id = this.props.id;
        var type = this.props.type;
        var data = this.props.data;
        for (var prop in data) {
            rows.push(<SourceDataIterator data={data[prop]} id={id} type={type} updated={this.props.updated} />);
        }
        return (
            <div>
                {rows}
                <Button bsStyle={'success'} onClick={this.toggleSourceEntry}><span className='glyphicon glyphicon-plus' ariaHidden='true'></span></Button>
                {this.state.sourceEntry ? <NewSource data={data} type={type} id={id} toggleSourceEntry={this.toggleSourceEntry} updated={this.props.updated}/>: null}
            </div>
        )
    }
});

var SourceDataIterator = React.createClass({
    getInitialState: function() {
        return {source:true}
    },
    sourceDelete: function() {
        $.ajax({
            type: 'delete',
            url: 'scot/api/v2/' + this.props.type + '/' + this.props.id + '/source/' + this.props.data.id,
            //data: json,
            success: function(data) {
                console.log('deleted source success: ' + data);
                this.props.updated();
            }.bind(this),
            error: function() {
                alert('Failed to delete the source - contact administrator');
            }.bind(this)
        });
        this.setState({source:false});
    },
    render: function() {
        data = this.props.data;
        return (
            <Button id="event_source" onClick={this.sourceDelete}><span style={{paddingRight:'3px'}} className="glyphicon glyphicon-ban-circle" ariaHidden="true"></span> {data.value}</Button>
        )
    }
});

var NewSource = React.createClass({
    getInitialState: function() {
        return {
            suggestions: this.props.options
        }
    },
    handleAddition: function(tag) {
        var newSourceArr = [];
        var data = this.props.data;
        for (var prop in data) {
            newSourceArr.push(data[prop].value);
        }
        newSourceArr.push(tag);
        $.ajax({
            type: 'put',
            url: 'scot/api/v2/' + this.props.type + '/' + this.props.id,
            data: JSON.stringify({'source':newSourceArr}),
            contentType: 'application/json; charset=UTF-8',
            success: function(data) {
                console.log('success: source added');
                this.props.toggleSourceEntry();
                this.props.updated();
                }.bind(this),
            error: function() {
                alert('Failed to add source - contact administrator');
                this.props.toggleSourceEntry();
            }.bind(this)
        });
    },
    handleInputChange: function(input) {
        var arr = [];
        this.serverRequest = $.get('/scot/api/v2/ac/source/' + input, function (result) {
            var result = result.records;
            for (var prop in result) {
                arr.push(result[prop].value)
            }
            this.setState({suggestions:arr})
        }.bind(this));
    },
    handleDelete: function () {
        //blank since buttons are handled outside of this
    },
    handleDrag: function () {
        //blank since buttons are handled outside of this
    },
    render: function() {
        var suggestions = this.state.suggestions;
        return (
            <span>
                <ReactTags
                    suggestions={suggestions}
                    handleAddition={this.handleAddition}
                    handleInputChange={this.handleInputChange}
                    handleDelete={this.handleDelete}
                    handleDrag={this.handleDrag}
                    minQueryLength={1}
                    customCSS={1}/>
            </span>
        )
    }
})

module.exports = Source;
