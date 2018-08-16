let React               = require( 'react' );
let ReactDateTime       = require( 'react-datetime' );

import { Button, Tooltip, OverlayTrigger, FormControl } from 'react-bootstrap';

//Add data into this metadata field by entering in the form layout in scot.cfg.pl. 

let CustomMetaDataTable = React.createClass( {

    onChange: function( event ) {
        let k  = event.target.id;
        let v = event.target.value;
        let json = {};
        json[k] = v;
        $.ajax( {
            type: 'put',
            url: 'scot/api/v2/' + this.props.type + '/' + this.props.id,
            data: JSON.stringify( json ),
            contentType: 'application/json; charset=UTF-8',
            success: function( ) {
                console.log( 'successfully changed custom table data' );
                this.forceUpdate();
            }.bind( this ),
            error: function( data ) {
                this.props.errorToggle( 'Failed to updated custom table data', data ); 
            }.bind( this )
        } );
    },
    
    shouldComponentUpdate: function( nextProps, nextState ) {
        //Only update the metadata if the headerData is different
        if ( this.props.headerData === nextProps.headerData ) { 
            return false;
        } else { 
            return true;
        }

    },

    render: function() {
        let multiSelectArr = [];
        let dropdownArr = [];
        let datesArr = [];
        let inputArr = [];
        let textAreaArr = [];
        let inputMultiArr = [];
        let booleanArr = [];
        let formType = this.props.form[this.props.headerData["data_fmt_ver"]];
        if ( formType ) {
            for ( let i=0; i < formType.length; i++ )  {
                let value = formType[i]['value'];
                let url = formType[i]['value_type']['url'];
                if ( url ) {
                    url = url.replace( '%s', this.props.id );
                }
                if ( formType[i]['value_type']['key'].split( '.' ).reduce( ( o,i )=>o[i], this.props.headerData ) ) {
                    value = formType[i]['value_type']['key'].split( '.' ).reduce( ( o,i )=>o[i], this.props.headerData );
                }
                
                switch ( formType[i]['type'] ) {
                case 'dropdown':
                    if ( formType[i]['value_type']['type'] == 'static' ) {
                        dropdownArr.push( <DropdownComponent onChange={this.onChange} label={formType[i].label} id={formType[i].key} referenceKey={formType[i]['value_type']['key']} value={value} dropdownValues={formType[i]['value']} help={formType[i].help}/> );
                    } else { 
                        dropdownArr.push( <DropdownComponent onChange={this.onChange} label={formType[i].label} id={formType[i].key} referenceKey={formType[i]['value_type']['key']} fetchURL={url} dynamic={true} help={formType[i].help}/> );
                    }
                    break;

                case 'input':
                    if ( formType[i]['value_type']['type'] == 'static' ) {
                        inputArr.push( <InputComponent onBlur={this.onChange} value={value} id={formType[i].key} label={formType[i].label} help={formType[i].help} /> );
                    } else {
                        inputArr.push( <InputComponent onBlur={this.onChange} id={formType[i].key} label={formType[i].label} referenceKey={formType[i]['value_type']['key']} fetchURL={url} dynamic={true} help={formType[i].help}/> );
                    }
                    break;

                case 'calendar':
                    if ( formType[i]['value_type']['type'] == 'static' ) {
                        let calendarValue = value * 1000;
                        datesArr.push( <Calendar typeTitle={formType[i].label} value={calendarValue} typeLower={formType[i].key} type={this.props.type} id={this.props.id} help={formType[i].help}/> );
                    } else {
                        datesArr.push( <Calendar typeTitle={formType[i].label} typeLower={formType[i].key} type={this.props.type} id={this.props.id} fetchURL={url} dynamic={true} referenceKey={formType[i]['value_type']['key']} help={formType[i].help}/> );
                    }
                    break;

                case 'textarea':
                    if ( formType[i]['value_type']['type'] == 'static' ) {
                        textAreaArr.push( <TextAreaComponent id={formType[i].key} value={value} onBlur={this.onChange} label={formType[i].label} help={formType[i].help}/> );
                    } else {
                        textAreaArr.push( <TextAreaComponent id={formType[i].key} onBlur={this.onChange} label={formType[i].label} fetchURL={url} dynamic={true} referenceKey={formType[i]['value_type']['key']} help={formType[i].help}/> );
                    }
                    break;
                    
                case 'input_multi':
                    if ( formType[i]['value_type']['type'] == 'static' ) {
                        inputMultiArr.push( <InputMultiComponent id={formType[i].key} value={value} errorToggle={this.props.errorToggle} mainType={this.props.type} mainId={this.props.id} label={formType[i].label} help={formType[i].help} /> );
                    } else {
                        inputMultiArr.push( <InputMultiComponent id={formType[i].key} errorToggle={this.props.errorToggle} mainType={this.props.type} mainId={this.props.id} label={formType[i].label} fetchURL={url} dynamic={true} referenceKey={formType[i]['value_type']['key']} help={formType[i].help} /> );
                    }
                    break;
                    
                case 'boolean':
                    if ( formType[i]['value_type']['type'] == 'static' ) {
                        booleanArr.push( <BooleanComponent id={formType[i].key} value={value} onChange={this.onChange} label={formType[i].label} help={formType[i].help} /> );
                    } else {
                        booleanArr.push( <BooleanComponent id={formType[i].key} onChange={this.onChange} label={formType[i].label} fetchURL={url} dynamic={true} referenceKey={formType[i]['value_type']['key']} help={formType[i].help}/> );
                    }
                    break;
                        
                case 'multi_select':
                    if ( formType[i]['value_type']['type'] == 'static' ) {
                        multiSelectArr.push( <MultiSelectComponent onChange={this.onChange} label={formType[i].label} id={formType[i].key} referenceKey={formType[i]['value_type']['key']} value={value} dropdownValues={formType[i]['value']} help={formType[i].help} mainType={this.props.type} mainId={this.props.id}/> );
                    } else {
                        multiSelectArr.push( <MultiSelectComponent onChange={this.onChange} label={formType[i].label} id={formType[i].key} referenceKey={formType[i]['value_type']['key']} fetchURL={url} dynamic={true} help={formType[i].help} mainType={this.props.type} mainId={this.props.id}/> );
                    }
                    break;
                }
            }
        }
        
        return (
            <div>
                { formType ? 
                    <div className='custom-metadata-table container'>
                        <div className='row'>
                            {dropdownArr}
                            {datesArr}
                            {inputArr}
                            {textAreaArr}
                            {inputMultiArr}
                            {booleanArr}
                            {multiSelectArr}
                        </div>
                    </div>
                    :
                    null 
                }
            </div>
            
        );
    }
} );

let DropdownComponent = React.createClass( {
    getInitialState: function() {
        return {
            selected: null,
            options: [],
        };
    },
    
    componentWillMount: function() {
        if ( this.props.dynamic ) {
            this.getDynamic(); 
        } else {
            let arr = [];
            let selected = '';

            for ( let j=0; j < this.props.dropdownValues.length; j++ ){
                if ( this.props.value == this.props.dropdownValues[j]['value'] ) {
                    selected = this.props.value;
                }

                arr.push( <option>{this.props.dropdownValues[j]['value']}</option> );
            }
            
            this.setState( { selected: selected, options: arr } );
        }
    },
	
    getDynamic: function() {
        $.ajax( {
            type: 'get',
            url: this.props.fetchURL,
            success: function ( result ) {
                let arr = [];
                let selected = '';
                let referenceKey = this.props.referenceKey;
                if ( referenceKey == 'qual_sigbody_id' || referenceKey == 'prod_sigbody_id' ) {
                    arr.push( <option>0</option> );
                    for ( let key in result['version'] ) {
                        if ( result['version'][key]['revision'] == result[referenceKey] ) {
                            selected = result[referenceKey];
                        }
                        arr.push( <option>{result['version'][key]['revision']}</option> );
                    }
                } else {
                    for ( let j=0; j < result[this.props.referenceKey].length; j++ ){
                        if ( result[this.props.referenceKey][j].selected == 1 ) {
                            selected = result[this.props.referenceKey][j].value;
                        }

                        arr.push( <option>{result[this.props.referenceKey][j].value}</option> );
                    }
                }

                this.setState( { selected: selected, options: arr } );

            }.bind( this )
        } );
    },   
 
    componentWillReceiveProps: function( nextProps ) {
        if ( nextProps.dynamic ) {
            this.getDynamic();
        } else {
            this.setState( {selected: nextProps.value} );
        }
    },

    onChange: function( event ) {
        this.props.onChange( event );
        this.setState( { selected: event.target.value } );
    },

    render: function() {
        return (
            <div className='custom-metadata-table-component-div'>
                <span className='custom-metadata-tableWidth'>
                    { this.props.label }
                </span>
                <span>
                    <select id={ this.props.id } value={ this.state.selected } onChange={ this.onChange }>
                        { this.state.options }
                    </select>
                </span>
                <span>
                    <OverlayTrigger placement='top' overlay={<Tooltip id={this.props.id}><div dangerouslySetInnerHTML={{__html: this.props.help}} bsClass="popover helpPopup"/></Tooltip>}>
                        <i className="fa fa-question-circle-o" aria-hidden="true" style={{paddingLeft: '5px'}}></i>
                    </OverlayTrigger>
                </span>
            </div>

        );
    }
} );

let InputComponent = React.createClass( {
    getInitialState: function() {
        return {
            value: ''
        };
    },
   
    componentWillMount: function() {
        if ( this.props.dynamic ) {
            this.getDynamic(); 
        } else {
            this.setState( { value: this.props.value} );
        }
    },
    
    getDynamic: function() {
        $.ajax( {
            type: 'get',
            url: this.props.fetchURL,
            success: function( result ) {
                let value = '';
                value = result[this.props.referenceKey];
                this.setState( {value: value} );
            }.bind( this )
        } ); 
    },

    inputOnChange: function( event ) {
        this.setState( {value:event.target.value} );
    },
    
    componentWillReceiveProps: function( nextProps ) {
        if ( nextProps.dynamic ) {
            this.getDynamic();
        } else {
            this.setState( {value: nextProps.value} );
        }
    },

    render: function() {
        
        return (
            <div className='custom-metadata-table-component-div'>
                <span className='custom-metadata-tableWidth'>
                    {this.props.label}
                </span>
                <span>
                    <input className='custom-metadata-input-width' id={this.props.id} onBlur={this.props.onBlur} onChange={this.inputOnChange} value={this.state.value} />
                </span>
                <span>
                    <OverlayTrigger placement='top' overlay={<Tooltip id={this.props.id}><div dangerouslySetInnerHTML={{__html: this.props.help}} bsClass="popover helpPopup"/></Tooltip>}>
                        <i className="fa fa-question-circle-o" aria-hidden="true" style={{paddingLeft: '5px'}}></i>
                    </OverlayTrigger>
                </span>
            </div>
        );
    }
} );

let Calendar = React.createClass( {
    getInitialState: function() {
        let loading = false;
        if ( this.props.dynamic ) {
            loading = true;
        }

        return {
            showCalendar: false,
            loading: loading,
            value: '',
        };
    },
	
    componentWillMount: function() {
        if ( this.props.dynamic ) {
            this.getDynamic();
        } else {
            this.setState( { value: this.props.value} );
        }
    },
	
    getDynamic: function() {
        $.ajax( {
            type: 'get',
            url: this.props.fetchURL,
            success: function( result ) {
                let value = result[this.props.referenceKey] * 1000;
                this.setState( {value: value, loading: false} );
            }.bind( this )
        } );
    },	   
	
    componentWillReceiveProps: function( nextProps ) {
        if ( nextProps.dynamic ) {
            this.getDynamic();
        } else {
            this.setState( {value: nextProps.value} );
        }
    },
 
    onChange: function( event ) {
        let k  = this.props.typeLower;
        let v = event._d.getTime()/1000;
        let json = {};
        json[k] = v;
        $.ajax( {
            type: 'put',
            url: 'scot/api/v2/' + this.props.type + '/' + this.props.id,
            data: JSON.stringify( json ),
            contentType: 'application/json; charset=UTF-8',
            success: function( ) {
                console.log( 'successfully changed custom table data' );
            }.bind( this ),
            error: function( data ) {
                this.props.errorToggle( 'Failed to updated custom table data', data ); 
            }.bind( this )
        } );

    },

    showCalendar: function() {
        if ( this.state.showCalendar == false ) {
            this.setState( {showCalendar:true} );    
        } else {
            this.setState( {showCalendar:false} );
        }
    },

    render: function() {
        return(
            <div className='custom-metadata-table-component-div' style={{display:'flex',flexFlow:'row'}}>
                <span className='custom-metadata-tableWidth'>
                    {this.props.typeTitle}
                </span>
                { !this.state.loading ? 
                    <ReactDateTime className='custom-metadata-input-width' value={this.state.value} onChange={this.onChange}/> 
                    :
                    <span>
                        Loading...
                    </span>
                }
                <span>
                    <OverlayTrigger placement='top' overlay={<Tooltip id={this.props.id}><div dangerouslySetInnerHTML={{__html: this.props.help}} bsClass="popover helpPopup"/></Tooltip>}>
                        <i className="fa fa-question-circle-o" aria-hidden="true" style={{paddingLeft: '5px'}}></i>
                    </OverlayTrigger>
                </span>
            </div>
        );
    }
} );

let TextAreaComponent = React.createClass( {
    getInitialState: function() {
        return {
            value: ''
        };
    },
    
    componentWillMount: function() {
        if ( this.props.dynamic ) {
            this.getDynamic(); 
        } else {
            this.setState( { value: this.props.value} );
        }
    },
	
    getDynamic: function() {
        $.ajax( {
            type: 'get',
            url: this.props.fetchURL,
            success: function( result ) {
                let value = result[this.props.referenceKey];
                this.setState( {value: value} );
            }.bind( this )
        } );
    },

    componentWillReceiveProps: function( nextProps ) {
        if ( nextProps.dynamic ) {
            this.getDynamic();
        } else {
            this.setState( {value: nextProps.value} );
        }
    },

    inputOnChange: function( event ) {
        this.setState( {value:event.target.value} );
    },

    render: function() {
        
        return (
            <div className='custom-metadata-table-component-div'>
                <span className='custom-metadata-tableWidth'>
                    {this.props.label}
                    <OverlayTrigger placement='top' overlay={<Tooltip id={this.props.id}> {this.props.help}</Tooltip>}>
                        <i className="fa fa-question-circle-o" aria-hidden="true" style={{paddingLeft: '5px'}}></i>
                    </OverlayTrigger>
                </span>
                <span>
                    <textarea id={this.props.id} onBlur={this.props.onBlur} onChange={this.inputOnChange} value={this.state.value} className='custom-metadata-textarea-width'/>
                </span>
            </div>
        );
    }
} );

let InputMultiComponent = React.createClass( {
    getInitialState: function() {
        return {
            inputValue: '',
            value: [],
        };
    },

    componentWillMount: function() {
        if ( this.props.dynamic ) {
            this.getDynamic();
        } else {
            this.setState( { value: this.props.value} );
        }
    },

    getDynamic: function() {
        $.ajax( {
            type: 'get',
            url: this.props.fetchURL,
            success: function( result ) {
                let value = result[this.props.referenceKey];
                this.setState( {value: value} );
            }.bind( this )
        } );
    },

    componentWillReceiveProps: function( nextProps ) {
        if ( nextProps.dynamic ) {
            this.getDynamic();
        } else {
            this.setState( {value: nextProps.value} );
        }
    },

    handleAddition: function( group ) {
        let groupArr = [];
        let data = this.state.value;
        for ( let i=0; i < data.length; i++ ) {
            if ( data[i] != undefined ) {
                if ( typeof( data[i] ) == 'string' ) {
                    groupArr.push( data[i] );
                } else {
                    groupArr.push( data[i].value );
                }
            }
        }
        groupArr.push( group.target.value );
        
        let newData = {};
        newData[this.props.id] = groupArr;
        
        $.ajax( {
            type: 'put',
            url: 'scot/api/v2/'+ this.props.mainType + '/' + this.props.mainId,
            data: JSON.stringify( newData ),
            contentType: 'application/json; charset=UTF-8',
            success: function( ) {
                console.log( 'success: group added' );
                this.setState( {inputValue: '', value: newData[this.props.id]} );
            }.bind( this ),
            error: function( data ) {
                this.props.errorToggle( 'Failed to add group', data );
            }.bind( this )
        } );
    },
    
    InputChange: function( event ) {
        this.setState( {inputValue: event.target.value} );
    },
    
    handleDelete: function( event ) {
        let data = this.state.value;
        let clickedThing = event.target.id;
        let groupArr= [];
        for ( let i=0; i < data.length; i++ ) {
            if ( data[i] != undefined ) {
                if ( typeof( data[i] ) == 'string' ) {
                    if ( data[i] != clickedThing ) {
                        groupArr.push( data[i] );
                    }
                } else {
                    if ( data[i].value != clickedThing ) {
                        groupArr.push( data[i].value );
                    }
                }
            }
        }

        let newData = {};
        newData[this.props.id] = groupArr;

        $.ajax( {
            type: 'put',
            url: 'scot/api/v2/'+ this.props.mainType + '/' + this.props.mainId,
            data: JSON.stringify( newData ),
            contentType: 'application/json; charset=UTF-8',
            success: function( data ) {
                this.setState( {value: newData[this.props.id]} );
                console.log( 'deleted group success: ' + data );
            }.bind( this ),
            error: function( data ) {
                this.props.errorToggle( 'Failed to delete group', data );
            }.bind( this )
        } );
    },

    render: function() {
        let data = this.state.value;
        let groupArr = [];
        let value;
        for ( let i=0; i < data.length; i++ ) {
            if ( typeof( data[i] ) == 'string' ) {
                value = data[i];
            } else if ( typeof( data[i] ) == 'object' ) {
                if ( data[i] != undefined ) {
                    value = data[i].value;
                }
            }
            groupArr.push( <span id="event_signature" className='tagButton'>{value} <i id={value} onClick={this.handleDelete} className="fa fa-times tagButtonClose"/></span> );
        }
        return (
            <div className='custom-metadata-table-component-div'>
                <span className='custom-metadata-tableWidth'>
                    {this.props.label}
                </span>
                <span>
                    <input className='custom-metadata-input-width' id={this.props.id} onChange={this.InputChange} value={this.state.inputValue} />
                    {this.state.inputValue != '' ? <Button bsSize='xsmall' bsStyle='success' onClick={this.handleAddition} value={this.state.inputValue}>Submit</Button> : <Button bsSize='xsmall' bsType='submit' disabled>Submit</Button>}
                </span>
                <span className='custom-metadata-multi-input-tags'>
                    {groupArr}
                </span>
                <span>
                    <OverlayTrigger placement='top' overlay={<Tooltip id={this.props.id}> {this.props.help}</Tooltip>}>
                        <i className="fa fa-question-circle-o" aria-hidden="true" style={{paddingLeft: '5px'}}></i>
                    </OverlayTrigger>
                </span>
            </div>
        );
    }
} );

let BooleanComponent = React.createClass( {    
    getInitialState: function() {
        return {
            value: false
        };
    },
    
    componentWillMount: function() {
        if ( this.props.dynamic ) {
            this.getDynamic(); 
        } else {
            this.setState( { value: this.props.value} );
        } 
    },

    getDynamic: function() {
        $.ajax( {
            type: 'get',
            url: this.props.fetchURL,
            success: function( result ) {
                let value = result[this.props.referenceKey];
                this.setState( {value: value} );
            }.bind( this )
        } );
    },

    componentWillReceiveProps: function( nextProps ) {
        if ( nextProps.dynamic ) {
            this.getDynamic();
        } else {
            this.setState( {value: nextProps.value} );
        }
    },

    onChange: function( e ) {
        let value;
        if ( e.target.value == 'true' ) {
            value = 1;
        } else {
            value = 0;
        }

        let obj = {};
        obj['target'] = {};
        obj['target']['id'] = this.props.id;
        obj['target']['value'] = value;

        this.props.onChange( obj ); 
    },
    
    render: function() {
        return (
            <div className='custom-metadata-table-component-div'>
                <span className='custom-metadata-tableWidth'>
                    {this.props.label}
                </span>
                <span>
                    <input type='checkbox' className='custom-metadata-input-width' id={this.props.id} name={this.props.id} value={this.state.value} onClick={this.onChange}/>
                </span>
                <span>
                    <OverlayTrigger placement='top' overlay={<Tooltip id={this.props.id}> {this.props.help}</Tooltip>}>
                        <i className="fa fa-question-circle-o" aria-hidden="true" style={{paddingLeft: '5px'}}></i>
                    </OverlayTrigger>
                </span>
            </div>
        );
    },
} );

let MultiSelectComponent = React.createClass( {    
    getInitialState: function() {
        return {
            options: []
        };
    },
    
    componentWillMount: function() {
        if ( this.props.dynamic ) {
            this.getDynamic();
        } else {
            this.makeForm(); 	 
        }
    },	
	
    makeForm: function( nextProps ) {
        let props = this.props;
        if ( nextProps ) { props = nextProps; }
		
        let arr = [];
        for ( let j=0; j < props.dropdownValues.length; j++ ){
            if ( props.value.includes( props.dropdownValues[j]['value'] ) ) {
                arr.push( <option selected>{props.dropdownValues[j]['value']}</option> );
            } else {
                arr.push( <option>{props.dropdownValues[j]['value']}</option> );
            }
        }

        this.setState( { options: arr } );
    }, 

    getDynamic: function() {
        $.ajax( {
            type: 'get',
            url: this.props.fetchURL,
            success: function ( result ) {
                let arr = [];
                for ( let j=0; j < result[this.props.referenceKey].length; j++ ){
                    if ( result[this.props.referenceKey][j].selected == 1 ) {
                        arr.push( <option selected>{result[this.props.referenceKey][j].value}</option> );
                    } else {
                        arr.push( <option>{result[this.props.referenceKey][j].value}</option> );
                    }

                }

                this.setState( { options: arr } );

            }.bind( this )
        } );
    },
	
    componentWillReceiveProps: function( nextProps ) {
        if ( nextProps.dynamic ) {
            this.getDynamic();
        } else {
        	this.makeForm( nextProps );
        }
    },

 	
    onChange: function( event ) {
        let multiSelectArr = [];
        for ( let i=0; i < event.target.options.length; i++ ) {
            if ( event.target.options[i] != undefined ) {
                if ( event.target.options[i].selected == true ) {
                    multiSelectArr.push( event.target.options[i].value );
                } else {
                	continue;
                }
            }
        }
       	 
        let newData = {};
        newData[this.props.id] = multiSelectArr;
        
        $.ajax( {
            type: 'put',
            url: 'scot/api/v2/'+ this.props.mainType + '/' + this.props.mainId,
            data: JSON.stringify( newData ),
            contentType: 'application/json; charset=UTF-8',
            success: function( ) {
                console.log( 'success: multi select added' );
            }.bind( this ),
            error: function( data ) {
                this.props.errorToggle( 'Failed to add multi select', data );
            }.bind( this )
        } );
        this.setState( { selected: event.target.value } );
    },
    
    render: function() {
        return (
            <div className='custom-metadata-table-component-div'>
                <span className='custom-metadata-tableWidth'>
                    {this.props.label}
                </span>
                <span>
                    <FormControl id={this.props.id} componentClass='select' placeholder='select' bsClass='custom-metadata-multi-select-width' multiple onChange={this.onChange} size={this.state.options.length}>
                    	{this.state.options} 
                    </FormControl>
                </span>
                <span>
                    <OverlayTrigger placement='top' overlay={<Tooltip id={this.props.id}> {this.props.help}</Tooltip>}>
                        <i className="fa fa-question-circle-o" aria-hidden="true" style={{paddingLeft: '5px'}}></i>
                    </OverlayTrigger>
                </span>
            </div>
        );
    },
} );

module.exports = CustomMetaDataTable;
