let React               = require( 'react' );
let ReactTags           = require( 'react-tag-input' ).WithContext;

let TagSourceFilter = React.createClass( {
    getInitialState: function() {
        let filterButtonArr = [];
        let filterButtonText = [];
        if ( this.props.defaultValue != undefined ) {
            filterButtonArr.push( <div id='filterButton' className='btn btn-xs btn-default'>{this.props.defaultValue}<span onClick={this.handleDelete} style={{paddingLeft:'3px'}} className="glyphicon glyphicon-remove" aria-hidden="true"></span></div> );
            filterButtonText.push( this.props.defaultValue );
            //this.props.handleFilter(this.props.defaultValue);
        }
        return {
            suggestions: this.props.options,
            filterButtonArr: filterButtonArr,
            filterButtonText: filterButtonText,
        };
    },
    handleFilterSuggestions: function( textInputValue, possibleSuggestionsArray ) {
        let lowerCaseQuery = textInputValue.toLowerCase();
        return possibleSuggestionsArray.filter( function( suggestion )  {
            return suggestion.toLowerCase().includes( lowerCaseQuery );
        } );
    },
    handleAddition: function( tag ) {
        let currentButtons = this.state.filterButtonArr;
        let currentText = this.state.filterButtonText;
        currentButtons.push( <div id='filterButton' className='btn btn-xs btn-default'>{tag}<span onClick={this.handleDelete} style={{paddingLeft:'3px'}} className="glyphicon glyphicon-remove" aria-hidden="true"></span></div> );
        currentText.push( tag );
        this.setState( {filterButtonArr:currentButtons, filterButtonText:currentText} );
        this.props.handleFilter( currentText );
    },
    handleDelete: function( e ) {
        let newFilterButtonArr = this.state.filterButtonArr;
        let newFilterButtonText = this.state.filterButtonText;
        for ( let i=0; i < this.state.filterButtonText.length; i++ ) {
            if ( $( e.target.parentElement ).text() == this.state.filterButtonText[i] ) {
                newFilterButtonArr.splice( i,1 );
                newFilterButtonText.splice( i,1 );
            }
        }
        this.setState( {filterButtonArr:newFilterButtonArr, filterButtonText:newFilterButtonText} );
        this.props.handleFilter( newFilterButtonText );
    },
    handleInputChange: function( input ) {
        let arr = [];
        let tagSplit = input.split( /,|\!/ );
        let inputSearch = tagSplit.pop();
        $.ajax( {
            type:'get',
            url:'/scot/api/v2/ac/'+ this.props.columnsOne  + '/' + inputSearch, 
            success: function ( result ) {
                for ( let i=0; i < result.records.length; i++ ) {
                    arr.push( result.records[i] );
                }
                this.setState( {suggestions:arr} );
            }.bind( this ),
            error: function( data ) {
                this.props.errorToggle( 'failed to get autocomplete data' , data );
            }.bind( this )
        } );
    },
    handleDrag: function () {
        //blank since buttons are handled outside of this
    },
    render: function() {
        let suggestions = this.state.suggestions;
        let showFilterButtons = false;
        if ( this.state.filterButtonArr[0] != undefined ) {
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
        );
    }
} );

module.exports = TagSourceFilter;
