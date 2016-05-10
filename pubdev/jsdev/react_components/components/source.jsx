var React               = require('react');
var Button              = require('react-bootstrap/lib/Button');
var ReactTags           = require('react-tag-input').WithContext;
var AppActions          = require('../flux/actions.jsx');

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
        for (i=0; i < data.length; i++) {
            rows.push(<SourceDataIterator key={data[i].id} data={data[i]} id={id} type={type} updated={this.props.updated} />);
        }
        return (
            <div>
                {rows}
                {this.state.sourceEntry ? <NewSource data={data} type={type} id={id} toggleSourceEntry={this.toggleSourceEntry} updated={this.props.updated}/>: null}
                {this.state.sourceEntry ? <Button bsSize={'xsmall'} bsStyle={'danger'} onClick={this.toggleSourceEntry}><span className='glyphicon glyphicon-minus' ariaHidden='true'></span></Button> : <Button bsSize={'xsmall'} bsStyle={'success'} onClick={this.toggleSourceEntry}><span className='glyphicon glyphicon-plus' ariaHidden='true'></span></Button>} 
            </div>
        )
    }
});

var SourceDataIterator = React.createClass({
    getInitialState: function() {
        return {
            source:true,
            key:this.props.id,
        }
    },
    sourceDelete: function() {
        $.ajax({
            type: 'delete',
            url: 'scot/api/v2/' + this.props.type + '/' + this.props.id + '/source/' + this.props.data.id, 
            success: function(data) {
                console.log('deleted source success: ' + data);
                var key = this.state.key;
                AppActions.updateItem(key,'headerUpdate');
            }.bind(this),
            error: function() {
                this.props.updated('error','Failed to delete the source');
            }.bind(this)
        });
        this.setState({source:false});
    },
    render: function() {
        data = this.props.data;
        return (
            <Button id="event_source" bsSize={'xsmall'} onClick={this.sourceDelete}>{data.value} <span style={{paddingLeft:'3px'}} className="glyphicon glyphicon-remove" ariaHidden="true"></span></Button>
        )
    }
});

var NewSource = React.createClass({
    getInitialState: function() {
        return {
            suggestions: this.props.options,
            key:this.props.id,
        }
    },
    handleAddition: function(tag) {
        var newSourceArr = [];
        var data = this.props.data;
        for (i=0; i < data.length; i++) {
            newSourceArr.push(data[i].value);
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
                var key = this.state.key;
                AppActions.updateItem(key,'headerUpdate');    
            }.bind(this),
            error: function() {
                this.props.updated('error','Failed to add source');
                this.props.toggleSourceEntry();
            }.bind(this)
        });
    },
    handleInputChange: function(input) {
        var arr = [];
        this.serverRequest = $.get('/scot/api/v2/ac/source/' + input, function (result) {
            var result = result.records;
            for (i=0; i < result.length; i++) {
                arr.push(result[i].value)
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
            <span className='tag-new'>
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
