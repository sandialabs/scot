var React               = require('react');
var Button              = require('react-bootstrap/lib/Button');
var ReactTags           = require('react-tag-input').WithContext;

var Tag = React.createClass({
    getInitialState: function() {
        return {tagEntry:false}
    },
    toggleTagEntry: function () {
        if (this.state.tagEntry == false) {
            this.setState({tagEntry:true})
        } else if (this.state.tagEntry == true) {
            this.setState({tagEntry:false})
        };
    },
    render: function() {
        var rows = [];
        var id = this.props.id;
        var type = this.props.type;
        var data = this.props.data;
        for (var prop in data) {
            rows.push(<TagDataIterator key={data[prop].id} data={data[prop]} id={id} type={type} updated={this.props.updated} />);
        }
        return (
            <div>
                {rows}
                {this.state.tagEntry ? <NewTag data={data} type={type} id={id} toggleTagEntry={this.toggleTagEntry} updated={this.props.updated}/>: null}
                {this.state.tagEntry ? <Button bsSize={'xsmall'} bsStyle={'danger'} onClick={this.toggleTagEntry}><span className='glyphicon glyphicon-minus' ariaHidden='true'></span></Button> : <Button bsSize={'xsmall'} bsStyle={'success'} onClick={this.toggleTagEntry}><span className='glyphicon glyphicon-plus' ariaHidden='true'></span></Button>}
                
            </div>
        )
    }
});

var TagDataIterator = React.createClass({
    getInitialState: function() {
        return {tag:true}
    },
    tagDelete: function() {
        $.ajax({
            type: 'delete',
            url: 'scot/api/v2/' + this.props.type + '/' + this.props.id + '/tag/' + this.props.data.id,
            success: function(data) {
                console.log('deleted tag success: ' + data);
                this.props.updated();
            }.bind(this),
            error: function() {
                alert('Failed to delete the tag - contact administrator');
            }.bind(this)
        });
        this.setState({tag:false});
        },
    render: function() {
        data = this.props.data;
        return (
            <Button id="event_tag" bsSize={'xsmall'} onClick={this.tagDelete}>{data.value} <span style={{paddingLeft:'3px'}} className="glyphicon glyphicon-remove" ariaHidden="true"></span></Button>
        )
    }
});

var NewTag = React.createClass({
    getInitialState: function() {
        return {
            suggestions: this.props.options
        }
    },
    handleAddition: function(tag) {
        var newTagArr = [];
        var data = this.props.data;
        for (var prop in data) {
            newTagArr.push(data[prop].value);
        }
        newTagArr.push(tag);
        $.ajax({
            type: 'put',
            url: 'scot/api/v2/' + this.props.type + '/' + this.props.id,
            data: JSON.stringify({'tag':newTagArr}),
            contentType: 'application/json; charset=UTF-8',
            success: function(data) {
                console.log('success: tag added');
                this.props.toggleTagEntry();
                this.props.updated();
                }.bind(this),
            error: function() {
                alert('Failed to add tag - contact administrator');
                this.props.toggleTagEntry();
            }.bind(this)
        });
    },
    handleInputChange: function(input) {
        var arr = [];
        this.serverRequest = $.get('/scot/api/v2/ac/tag/' + input, function (result) {
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
            <span className='tag-new'>
                <ReactTags
                    suggestions={suggestions}
                    handleAddition={this.handleAddition}
                    handleDelete={this.handleDelete}
                    handleDrag={this.handleDrag}
                    handleInputChange={this.handleInputChange}
                    minQueryLength={1}
                    customCSS={1}/>
            </span>
        )
    }
})

module.exports = Tag;
