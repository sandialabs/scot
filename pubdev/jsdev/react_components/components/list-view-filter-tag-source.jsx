var React               = require('react');
var Button              = require('react-bootstrap/lib/Button');
var ReactTags           = require('react-tag-input').WithContext;

var TagSourceFilter = React.createClass({
    getInitialState: function() {
        var filterButtonArr = [];
        var filterButtonText = [];
        if (this.props.defaultValue != undefined) {
            filterButtonArr.push(<div id='filterButton' className='btn btn-xs btn-default'>{this.props.defaultValue}<span onClick={this.handleDelete} style={{paddingLeft:'3px'}} className="glyphicon glyphicon-remove" aria-hidden="true"></span></div>);
            filterButtonText.push(this.props.defaultValue);
            //this.props.handleFilter(this.props.defaultValue);
        }
        return {
            suggestions: this.props.options,
            filterButtonArr: filterButtonArr,
            filterButtonText: filterButtonText,
        }
    },
    handleFilterSuggestions: function(textInputValue, possibleSuggestionsArray) {
        var lowerCaseQuery = textInputValue.toLowerCase()
        return possibleSuggestionsArray.filter(function(suggestion)  {
            return suggestion.toLowerCase().includes(lowerCaseQuery)
        })
    },
    handleAddition: function(tag) {
        var currentButtons = this.state.filterButtonArr;
        var currentText = this.state.filterButtonText;
        currentButtons.push(<div id='filterButton' className='btn btn-xs btn-default'>{tag}<span onClick={this.handleDelete} style={{paddingLeft:'3px'}} className="glyphicon glyphicon-remove" aria-hidden="true"></span></div>);
        currentText.push(tag)
        this.setState({filterButtonArr:currentButtons, filterButtonText:currentText});
        this.props.handleFilter(currentText);
    },
    handleDelete: function(e) {
        var newFilterButtonArr = this.state.filterButtonArr;
        var newFilterButtonText = this.state.filterButtonText;
        for (var i=0; i < this.state.filterButtonText.length; i++) {
            if ($(e.target.parentElement).text() == this.state.filterButtonText[i]) {
                newFilterButtonArr.splice(i,1);
                newFilterButtonText.splice(i,1);
            }
        }
        this.setState({filterButtonArr:newFilterButtonArr, filterButtonText:newFilterButtonText});
        this.props.handleFilter(newFilterButtonText);
    },
    handleInputChange: function(input) {
        var arr = [];
        var tagSplit = input.split(/,|\!/);
        var inputSearch = tagSplit.pop();
        $.ajax({
            type:'get',
            url:'/scot/api/v2/ac/'+ this.props.columnsOne  + '/' + inputSearch, 
            success: function (result) {
                var result = result.records;
                for (var i=0; i < result.length; i++) {
                    arr.push(result[i])
                }
                this.setState({suggestions:arr})
            }.bind(this),
            error: function(data) {
                this.props.errorToggle('failed to get autocomplete data' , data)
            }.bind(this)
        })
    },
    handleDrag: function () {
        //blank since buttons are handled outside of this
    },
    render: function() {
        var suggestions = this.state.suggestions;
        var showFilterButtons = false;
        if (this.state.filterButtonArr[0] != undefined) {
            showFilterButtons = true;    
        }
        return (
            <span className='list-filtered' style={{width:'100%'}}>
                <ReactTags
                    suggestions={suggestions}
                    handleAddition={this.handleAddition}
                    handleDelete={this.handleDelete}
                    handleDrag={this.handleDrag}
                    handleInputChange={this.handleInputChange}
                    minQueryLength={1}
                    customCSS={0}
                    placeholder=''
                    handleFilterSuggestions={this.handleFilterSuggestions}
                    autofocus={false}/>
                {showFilterButtons ? this.state.filterButtonArr : null}
            </span>
        )
    }
})

module.exports = TagSourceFilter;
