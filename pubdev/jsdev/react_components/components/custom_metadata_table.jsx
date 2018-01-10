var React               = require('react');
var ReactDateTime       = require('react-datetime');
import Button from 'react-bootstrap/lib/Button.js';

var CustomMetaDataTable = React.createClass({
    getInitialState: function() {
        
        return {
            data: [
                {
                    type: 'dropdown',
                    key: 'sensitivity',
                    value_type: { type: 'static', url: null, key: 'sensitivity'}, 
                    value: [{value: 'FYI', selected: 1}, {value: 'none', selected: 0}],
                    label: 'DOE Information Sensitivity',
                    help: 'help text',
                },
                {
                    type: 'input',
                    key: 'doe_report_id',
                    value_type: { type: 'static', url: null, key: 'doe_report_id'}, 
                    value: 'default string',
                    label: 'DOE Report Category',
                    help: 'help text',
                },
                {
                    type: 'calendar',
                    key: 'occurred',
                    value_type: { type: 'static', url: null, key: 'occurred'}, 
                    value: 1494018000,
                    label: 'Occurred',
                    help: 'help text',
                },
                {
                    type: 'textarea',
                    key: 'description',
                    value_type: { type: 'static', url: null, key: 'description'}, 
                    value: 'string here',
                    label: 'Description',
                    help: 'help text',
                },
                {
                    type: 'input_multi',
                    key: 'signature_group',
                    value_type: { type: 'static', url: null, key: 'signature_group'}, 
                    value: ['string1', 'string2'],
                    label: 'Signature Group',
                    help: 'help text',
                },
                {
                    type: 'boolean',
                    key: 'active',
                    value_type: { type: 'static', url: null, key: 'active'}, 
                    value: true,
                    label: 'Active',
                    help: 'help text',
                },
            ],
        }
    },

    onChange: function(event) {
        var k  = event.target.id;
        var v = event.target.value;
        var json = {};
        json[k] = v;
        $.ajax({
            type: 'put',
            url: 'scot/api/v2/' + this.props.type + '/' + this.props.id,
            data: JSON.stringify(json),
            contentType: 'application/json; charset=UTF-8',
            success: function(data) {
                console.log('successfully changed custom table data');
                this.forceUpdate();
            }.bind(this),
            error: function(data) {
                this.props.errorToggle('Failed to updated custom table data', data) 
            }.bind(this)
        })
    },
    
    shouldComponentUpdate: function(nextProps, nextState) {
        //Only update the metadata if the headerData is different
        if (this.props.headerData === nextProps.headerData) { 
            return false;
        } else { 
            return true;
        }

    },

    render: function() {
        var dropdownArr = [];
        var datesArr = [];
        var inputArr = [];
        var textAreaArr = [];
        var inputMultiArr = [];
        var booleanArr = [];
        if ( this.props.form ) {
            for ( let i=0; i < this.props.form.length; i++ )  {
                let value = this.props.form[i]['value'];
                let url = this.props.form[i]['value_type']['url'];
                if (url) {
                    url = url.replace('%s', this.props.id);
                }
                if (this.props.form[i]['value_type']['key'].split('.').reduce((o,i)=>o[i], this.props.headerData)) {
                    value = this.props.form[i]['value_type']['key'].split('.').reduce((o,i)=>o[i], this.props.headerData)
                }
                
                switch ( this.props.form[i]['type'] ) {
                    case 'dropdown':
                        if ( this.props.form[i]['value_type']['type'] == 'static' ) {
                            dropdownArr.push(<DropdownComponent onChange={this.onChange} label={this.props.form[i].label} id={this.props.form[i].key} referenceKey={this.props.form[i]['value_type']['key']} value={value} dropdownValues={this.props.form[i]['value']}/>)
                        } else { 
                            dropdownArr.push(<DropdownComponent onChange={this.onChange} label={this.props.form[i].label} id={this.props.form[i].key} referenceKey={this.props.form[i]['value_type']['key']} fetchURL={url} dynamic={true}/> )
                        }
                        break;

                    case 'input':
                        if ( this.props.form[i]['value_type']['type'] == 'static' ) {
                            inputArr.push(<InputComponent onBlur={this.onChange} value={value} id={this.props.form[i].key} label={this.props.form[i].label} />)
                        } else {
                            inputArr.push(<InputComponent onBlur={this.onChange} id={this.props.form[i].key} label={this.props.form[i].label} referenceKey={this.props.form[i]['value_type']['key']} fetchURL={url} dynamic={true}/>)
                        }
                        break;

                    case 'calendar':
                        if ( this.props.form[i]['value_type']['type'] == 'static' ) {
                            let calendarValue = value * 1000
                            datesArr.push(<Calendar typeTitle={this.props.form[i].label} value={calendarValue} typeLower={this.props.form[i].key} type={this.props.type} id={this.props.id}/>);
                        } else {
                            datesArr.push(<Calendar typeTitle={this.props.form[i].label} typeLower={this.props.form[i].key} type={this.props.type} id={this.props.id} fetchURL={url} dynamic={true} referenceKey={this.props.form[i]['value_type']['key']}/>);
                        }
                        break;

                    case 'textarea':
                        if ( this.props.form[i]['value_type']['type'] == 'static' ) {
                            textAreaArr.push(<TextAreaComponent id={this.props.form[i].key} value={value} onBlur={this.onChange} label={this.props.form[i].label} />)
                        } else {
                            textAreaArr.push(<TextAreaComponent id={this.props.form[i].key} onBlur={this.onChange} label={this.props.form[i].label} fetchURL={url} dynamic={true} referenceKey={this.props.form[i]['value_type']['key']}/>)
                        }
                        break;
                    
                    case 'input_multi':
                        if ( this.props.form[i]['value_type']['type'] == 'static' ) {
                            inputMultiArr.push(<InputMultiComponent id={this.props.form[i].key} value={value} errorToggle={this.props.errorToggle} mainType={this.props.type} mainId={this.props.id} label={this.props.form[i].label} />)
                        } else {
                            inputMultiArr.push(<InputMultiComponent id={this.props.form[i].key} errorToggle={this.props.errorToggle} mainType={this.props.type} mainId={this.props.id} label={this.props.form[i].label} fetchURL={url} dynamic={true} referenceKey={this.props.form[i]['value_type']['key']} />)
                        }
                        break;
                    
                    case 'boolean':
                        if ( this.props.form[i]['value_type']['type'] == 'static' ) {
                            booleanArr.push(<BooleanComponent id={this.props.form[i].key} value={value} onChange={this.onChange} label={this.props.form[i].label} />)
                        } else {
                            booleanArr.push(<BooleanComponent id={this.props.form[i].key} onChange={this.onChange} label={this.props.form[i].label} fetchURL={url} dynamic={true} referenceKey={this.props.form[i]['value_type']['key']}/>)
                        }
                        break;
                }
            }
        }
        
        return (
            <div>
                { this.props.form ? 
                    <div className='custom-metadata-table container'>
                        <div className='row'>
                            {dropdownArr}
                            {datesArr}
                            {inputArr}
                            {textAreaArr}
                            {inputMultiArr}
                            {booleanArr}
                        </div>
                    </div>
                :
                    null 
                }
            </div>
            
        )
    }
});

let DropdownComponent = React.createClass({
    getInitialState: function() {
        return {
            selected: null,
            options: [],
        }
    },
    
    componentWillMount: function() {
        if ( this.props.dynamic ) {
			this.getDynamic(); 
        } else {
            let arr = [];
            let selected = '';

            for (var j=0; j < this.props.dropdownValues.length; j++){
                if ( this.props.value == this.props.dropdownValues[j]['value'] ) {
                    selected = this.props.value;
                }

                arr.push(<option>{this.props.dropdownValues[j]['value']}</option>)
            }
            
            this.setState({ selected: selected, options: arr });
        }
    },
	
	getDynamic: function() {
		$.ajax({
			type: 'get',
			url: this.props.fetchURL,
			success: function ( result ) {
				let arr = [];
				let selected = '';
				let referenceKey = this.props.referenceKey;
				if ( referenceKey == 'qual_sigbody_id' || referenceKey == 'prod_sigbody_id' ) {
					arr.push(<option>0</option>);
					for ( let key in result['version'] ) {
						if ( result['version'][key]['revision'] == result[referenceKey] ) {
							selected = result[referenceKey];
						}
						arr.push(<option>{result['version'][key]['revision']}</option>)
					}
				} else {
					for (var j=0; j < result[this.props.referenceKey].length; j++){
						if ( result[this.props.referenceKey][j].selected == 1 ) {
							selected = result[this.props.referenceKey][j].value;
						}

						arr.push(<option>{result[this.props.referenceKey][j].value}</option>)
					}
				}

				this.setState({ selected: selected, options: arr });

			}.bind(this)
		});
	},   
 
    componentWillReceiveProps: function(nextProps) {
        if ( nextProps.dynamic ) {
            this.getDynamic();
        } else {
            this.setState({selected: nextProps.value});
        }
	},

    onChange: function( event ) {
        this.props.onChange( event );
        this.setState({ selected: event.target.value });
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
            </div>

        )
    }
});

let InputComponent = React.createClass({
    getInitialState: function() {
        return {
            value: ''
        }
    },
   
    componentWillMount: function() {
        if ( this.props.dynamic ) {
			this.getDynamic(); 
        } else {
            this.setState({ value: this.props.value});
        }
    },
    
    getDynamic: function() {
		$.ajax({
			type: 'get',
			url: this.props.fetchURL,
			success: function(result) {
				let value = '';
				value = result[this.props.referenceKey];
				this.setState({value: value});
			}.bind(this)
		}); 
    },

    inputOnChange: function(event) {
        this.setState({value:event.target.value});
    },
    
    componentWillReceiveProps: function(nextProps) {
        if ( nextProps.dynamic ) {
            this.getDynamic();
        } else {
            this.setState({value: nextProps.value});
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
            </div>
        )
    }
});

var Calendar = React.createClass({
    getInitialState: function() {
        let loading = false;
		if ( this.props.dynamic ) {
			loading = true
		}

		return {
            showCalendar: false,
            loading: loading,
			value: '',
        }
    },
	
    componentWillMount: function() {
        if ( this.props.dynamic ) {
        	this.getDynamic();
		} else {
            this.setState({ value: this.props.value});
        }
    },
	
	getDynamic: function() {
		$.ajax({
			type: 'get',
			url: this.props.fetchURL,
			success: function(result) {
				let value = result[this.props.referenceKey] * 1000;
				this.setState({value: value, loading: false});
			}.bind(this)
		});
	},	   
	
	componentWillReceiveProps: function(nextProps) {
        if ( nextProps.dynamic ) {
            this.getDynamic();
        } else {
            this.setState({value: nextProps.value});
        }
    },
	 
    onChange: function(event) {
        var k  = this.props.typeLower;
        var v = event._d.getTime()/1000;
        var json = {};
        json[k] = v;
        $.ajax({
            type: 'put',
            url: 'scot/api/v2/' + this.props.type + '/' + this.props.id,
            data: JSON.stringify(json),
            contentType: 'application/json; charset=UTF-8',
            success: function(data) {
                console.log('successfully changed custom table data');
            }.bind(this),
            error: function(data) {
                this.props.errorToggle('Failed to updated custom table data', data) 
            }.bind(this)
        })

    },

    showCalendar: function() {
        if (this.state.showCalendar == false) {
            this.setState({showCalendar:true})    
        } else {
            this.setState({showCalendar:false})
        }
    },

    render: function() {
        return(
            <div className='custom-metadata-table-component-div' style={{display:'flex',flexFlow:'row'}}>
                <span className='custom-metadata-tableWidth'>
                    {this.props.typeTitle}:
                </span>
				{ !this.state.loading ? 
					<ReactDateTime className='custom-metadata-input-width' value={this.state.value} onChange={this.onChange}/> 
                :
		            <span>
                        Loading Placeholder
                    </span>
                }
            </div>
        )
    }
});

let TextAreaComponent = React.createClass({
    getInitialState: function() {
        return {
            value: ''
        }
    },
    
    componentWillMount: function() {
		if ( this.props.dynamic ) {
           this.getDynamic(); 
        } else {
            this.setState({ value: this.props.value});
        }
    },
	
	getDynamic: function() {
		$.ajax({
			type: 'get',
			url: this.props.fetchURL,
			success: function(result) {
				let value = result[this.props.referenceKey];
				this.setState({value: value});
			}.bind(this)
		});
	},

    componentWillReceiveProps: function(nextProps) {
        if ( nextProps.dynamic ) {
            this.getDynamic();
        } else {
            this.setState({value: nextProps.value});
        }
    },

    inputOnChange: function(event) {
        this.setState({value:event.target.value});
    },

    render: function() {
        
        return (
            <div className='custom-metadata-table-component-div'>
                <span className='custom-metadata-tableWidth'>
                    {this.props.label}
                </span>
                <span>
                    <textarea id={this.props.id} onBlur={this.props.onBlur} onChange={this.inputOnChange} value={this.state.value} className='custom-metadata-textarea-width'/>
                </span>
            </div>
        )
    }
});

let InputMultiComponent = React.createClass({
    getInitialState: function() {
        return {
            inputValue: '',
            value: [],
        }
    },

    componentWillMount: function() {
        if ( this.props.dynamic ) {
        	this.getDynamic();
		} else {
            this.setState({ value: this.props.value});
        }
    },

	getDynamic: function() {
		$.ajax({
			type: 'get',
			url: this.props.fetchURL,
			success: function(result) {
				let value = result[this.props.referenceKey];
				this.setState({value: value});
			}.bind(this)
		});
	},

	componentWillReceiveProps: function(nextProps) {
        if ( nextProps.dynamic ) {
            this.getDynamic();
        } else {
            this.setState({value: nextProps.value});
        }
    },

    handleAddition: function(group) {
        var groupArr = [];
        var data = this.state.value;
        for (var i=0; i < data.length; i++) {
            if (data[i] != undefined) {
                if (typeof(data[i]) == 'string') {
                    groupArr.push(data[i]);
                } else {
                    groupArr.push(data[i].value);
                }
            }
        }
        groupArr.push(group.target.value);
        
        let newData = {};
        newData[this.props.id] = groupArr;
        
        $.ajax({
            type: 'put',
            url: 'scot/api/v2/'+ this.props.mainType + '/' + this.props.mainId,
            data: JSON.stringify(newData),
            contentType: 'application/json; charset=UTF-8',
            success: function(data) {
                console.log('success: group added');
                this.setState({inputValue: '', value: newData[this.props.id]});
            }.bind(this),
            error: function(data) {
                this.props.errorToggle('Failed to add group', data);
            }.bind(this)
        });
    },
    
    InputChange: function(event) {
        this.setState({inputValue: event.target.value});
    },
    
    handleDelete: function(event) {
        var data = this.state.value;
        var clickedThing = event.target.id;
        var groupArr= [];
        for (var i=0; i < data.length; i++) {
            if (data[i] != undefined) {
                if (typeof(data[i]) == 'string') {
                    if (data[i] != clickedThing) {
                        groupArr.push(data[i]);
                    }
                } else {
                    if (data[i].value != clickedThing) {
                        groupArr.push(data[i].value);
                    }
                }
            }
        }

        let newData = {};
        newData[this.props.id] = groupArr;

        $.ajax({
            type: 'put',
            url: 'scot/api/v2/'+ this.props.mainType + '/' + this.props.mainId,
            data: JSON.stringify(newData),
            contentType: 'application/json; charset=UTF-8',
            success: function(data) {
                this.setState({value: newData[this.props.id]});
                console.log('deleted group success: ' + data);
            }.bind(this),
            error: function(data) {
                this.props.errorToggle('Failed to delete group', data);
            }.bind(this)
        });
    },

    render: function() {
        var data = this.state.value;
        var groupArr = [];
        var value;
        for (var i=0; i < data.length; i++) {
            if (typeof(data[i]) == 'string') {
                value = data[i];
            } else if (typeof(data[i]) == 'object') {
                if (data[i] != undefined) {
                    value = data[i].value;
                }
            }
            groupArr.push(<span id="event_signature" className='tagButton'>{value} <i id={value} onClick={this.handleDelete} className="fa fa-times tagButtonClose"/></span>);
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
            </div>
        )
    }
})

let BooleanComponent = React.createClass({    
    getInitialState: function() {
        return {
            value: false
        }
    },
    
    componentWillMount: function() {
		if ( this.props.dynamic ) {
        	this.getDynamic(); 
        } else {
            this.setState({ value: this.props.value});
        } 
    },

	getDynamic: function() {
		$.ajax({
			type: 'get',
			url: this.props.fetchURL,
			success: function(result) {
				let value = result[this.props.referenceKey];
				this.setState({value: value});
			}.bind(this)
		});
	},

    componentWillReceiveProps: function(nextProps) {
        if ( nextProps.dynamic ) {
            this.getDynamic();
        } else {
            this.setState({value: nextProps.value});
        }
    },

    onChange: function(e) {
        let value;
        if (e.target.value == 'true') {
            value = 1;
        } else {
            value = 0;
        }

        let obj = {};
        obj['target'] = {}
        obj['target']['id'] = this.props.id;
        obj['target']['value'] = value;

        this.props.onChange(obj); 
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
            </div>
        )
    },
})


module.exports = CustomMetaDataTable;
