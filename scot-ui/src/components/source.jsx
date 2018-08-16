let React               = require( 'react' );
let Button              = require( 'react-bootstrap/lib/Button' );
let ReactTags           = require( 'react-tag-input' ).WithContext;

let Source = React.createClass( {
    getInitialState: function() {
        return {sourceEntry:false};
    },
    toggleSourceEntry: function () {
        if ( this.state.sourceEntry == false ) {
            this.setState( {sourceEntry:true} );
        } else if ( this.state.sourceEntry == true ) {
            this.setState( {sourceEntry:false} );
        }
    },
    render: function() {
        let rows = [];
        let id = this.props.id;
        let type = this.props.type;
        let data = this.props.data;
        
        //Don't show if guide
        if ( this.props.type == 'guide' ) {
            return ( <th/> );
        } 
        
        if ( data != undefined ) {
            for ( let i=0; i < data.length; i++ ) {
                rows.push( <SourceDataIterator data={data} dataOne={data[i]} id={id} type={type} updated={this.props.updated} key={i} /> );
            }
        }
        return (
            <th>
                <th>
                Sources:
                </th>
                <td>
                    {rows}
                    {this.state.sourceEntry ? <NewSource data={data} type={type} id={id} toggleSourceEntry={this.toggleSourceEntry} updated={this.props.updated}/>: null}
                    {this.state.sourceEntry ? <span className='add-source-button'><Button bsSize={'xsmall'} bsStyle={'danger'} onClick={this.toggleSourceEntry}><span className='glyphicon glyphicon-minus' aria-hidden='true'></span></Button></span> : <span className='remove-source-button'><Button bsSize={'xsmall'} bsStyle={'success'} onClick={this.toggleSourceEntry}><span className='glyphicon glyphicon-plus' aria-hidden='true'></span></Button></span>} 
                </td>
            </th>
        );
    }
} );

let SourceDataIterator = React.createClass( {
    sourceDelete: function() {
        let data = this.props.data;
        let newSourceArr = [];
        for ( let i=0; i < data.length; i++ ) {
            if ( data[i] != undefined ) {
                if ( typeof( data[i] ) == 'string' ) {
                    if ( data[i] != this.props.dataOne ) {
                        newSourceArr.push( data[i] );
                    }
                } else {
                    if ( data[i].value != this.props.dataOne.value ) {
                        newSourceArr.push( data[i].value );
                    }
                }
            }
        }
        $.ajax( {
            type: 'put',
            url: 'scot/api/v2/' + this.props.type + '/' + this.props.id, 
            data: JSON.stringify( {'source':newSourceArr} ),
            contentType: 'application/json; charset=UTF-8',
            success: function( data ) {
                console.log( 'deleted source success: ' + data );
            }.bind( this ),
            error: function( data ) {
                this.props.errorToggle( 'Failed to delete the source', data );
            }.bind( this )
        } );
    },
    render: function() {
        let dataOne = this.props.dataOne;
        let value;
        if ( typeof( dataOne ) == 'string' ) {
            value = dataOne;
        } else if ( typeof( dataOne ) == 'object' ) {
            if ( dataOne != undefined ) {
                value = dataOne.value;
            }
        }
        return (
            <span id="event_source" className='sourceButton'>{value} <span className='sourceButtonClose'><i onClick={this.sourceDelete} className="fa fa-times"/></span></span>
        );
    }
} );

let NewSource = React.createClass( {
    getInitialState: function() {
        return {
            suggestions: this.props.options,
        };
    },
    handleAddition: function( source ) {
        let newSourceArr = [];
        let data = this.props.data;
        for ( let i=0; i < data.length; i++ ) {
            if ( data[i] != undefined ) {
                if( typeof( data[i] ) == 'string' ) {
                    newSourceArr.push( data[i] );
                } else {
                    newSourceArr.push( data[i].value );
                }
            }
        }
        newSourceArr.push( source );
        $.ajax( {
            type: 'put',
            url: 'scot/api/v2/' + this.props.type + '/' + this.props.id,
            data: JSON.stringify( {'source':newSourceArr} ),
            contentType: 'application/json; charset=UTF-8',
            success: function( data ) {
                console.log( 'success: source added' );
                this.props.toggleSourceEntry();
            }.bind( this ),
            error: function( data ) {
                this.props.errorToggle( 'Failed to add source', data );
                this.props.toggleSourceEntry();
            }.bind( this )
        } );
    },
    handleInputChange: function( input ) {
        let arr = [];
        $.ajax( {
            type:'get',
            url:'/scot/api/v2/ac/source/' + input, 
            success: function ( result ) {
                var result = result.records;
                for ( let i=0; i < result.length; i++ ) {
                    arr.push( result[i] );
                }
                this.setState( {suggestions:arr} );
            }.bind( this ),
            error: function( data ) {
                this.props.errorToggle( 'failed to get source autocomplete data', data );
            }.bind( this )
        } );
    },
    handleDelete: function () {
        //blank since buttons are handled outside of this
    },
    handleDrag: function () {
        //blank since buttons are handled outside of this
    },
    render: function() {
        let suggestions = this.state.suggestions;
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
        );
    }
} );

module.exports = Source;
