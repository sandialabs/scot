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
                    value_type: { type: 'static', source: 'selected_row', url: null, key: 'sensitivity'}, 
                    value: [{value: 'FYI', selected: 1}, {value: 'none', selected: 0}],
                    label: 'DOE Information Sensitivity',
                    help: 'help text',
                },
                {
                    type: 'input',
                    key: 'doe_report_id',
                    value_type: { type: 'static', source: 'selected_row', url: null, key: 'doe_report_id'}, 
                    value: 'default string',
                    label: 'DOE Report Category',
                    help: 'help text',
                },
                {
                    type: 'calendar',
                    key: 'occurred',
                    value_type: { type: 'static', source: 'selected_row', url: null, key: 'occurred'}, 
                    value: 1494018000,
                    label: 'Occurred'
                    help: 'help text',
                },
                {
                    type: 'textarea',
                    key: 'description',
                    value_type: { type: 'static', source: 'selected_row', url: null, key: 'description'}, 
                    value: 'string here',
                    label: 'Description',
                    help: 'help text',
                },
                {
                    type: 'input_multi',
                    key: 'signature_group',
                    value_type: { type: 'static', source: 'selected_row', url: null, key: 'signature_group'}, 
                    value: ['string1', 'string2'],
                    label: 'Signature Group',
                    help: 'help text',
                },
                {
                    type: 'boolean',
                    key: 'active',
                    value_type: { type: 'static', source: 'selected_row', url: null, key: 'active'}, 
                    value: true,
                    label: 'Active',
                    help: 'help text',
                },
            ],
        }
    },

    componentWillMount: function() {
        /*$.ajax({
            type: 'get',
            url: 'scot/api/v2/' + this.props.type + '/' + this.props.id + '/',
            success: function(data) {
                this.setState({data: data.table});
            }.bind(this),
            error: function(data) {
                this.props.errorToggle('Failed to get custom table data', data);
            }.bind(this),
        })*/
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
            }.bind(this),
            error: function(data) {
                this.props.errorToggle('Failed to updated custom table data', data) 
            }.bind(this)
        })
    },

    render: function() {
        var dropdownArr = [];
        var datesArr = [];
        var inputArr = [];
        var textAreaArr = [];
        var inputMultiArr = [];
        var booleanArr = [];

        for ( let i=0; i < this.state.data.length; i++ )  {
            switch ( this.state.data[i]['type'] ) {
                case 'dropdown':
                    switch ( this.state.[i]['value_type']['type'] ) {
                        case 'static':
                            dropdownArr.push(<DropdownComponent onChange={this.onChange} label={this.state.data[i].label} id={this.state.data[i].key} value={this.state.data[i].value}/>)
                            break;
                        
                        case 'dynamic':
                            dropdownArr.push(DropdownComponent onChange={this.onChange} label={this.state.data[i].label} id={this.state.data[i]['value_type']['key']} fetchURL={this.state.data[i]['value_type']['url']} /> )
                            break;
                    
                    }
                case 'input':
                    inputArr.push(<InputComponent onBlur={this.onChange} value={this.state.data[i].value} id={this.state.data[i].key} label={this.state.data[i].label} />)
                    break;

                case 'calendar':
                    let value = this.state.data[i].value * 1000
                    datesArr.push(<Calendar typeTitle={this.state.data[i].label} value={value} typeLower={this.state.data[i].key} type={this.props.type} id={this.props.id}/>);
                    break;

                case 'textarea':
                   textAreaArr.push(<TextAreaComponent id={this.state.data[i].key} value={this.state.data[i].value} onBlur={this.onChange} label={this.state.data[i].label} />)
                   break;
                
                case 'input_multi':
                    inputMultiArr.push(<InputMultiComponent id={this.state.data[i].key} value={this.state.data[i].value} errorToggle={this.props.errorToggle} mainType={this.props.type} mainId={this.props.id} label={this.state.data[i].label} />)
                    break;
                
                case 'boolean':
                    booleanArr.push(<BooleanComponent id={this.state.data[i].key} value={this.state.data[i].value} onChange={this.onChange} label={this.state.data[i].label} />)
                    break;
            }
        }

        return (
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
        var arr = [];
        let selected = '';
        for (var j=0; j < this.props.value.length; j++){
            if ( this.props.value[j].selected == 1 ) {
                selected = this.props.value[j].value;
            }

            arr.push(<option>{this.props.value[j].value}</option>)
        }
        this.setState({ selected: selected, options: arr });
    
    },

    onChange: function( event ) {
        console.log( 'selected id: ' + event.target.id + '. selected value: ' + event.target.value);
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
            value: this.props.value
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
                    <input className='custom-metadata-input-width' id={this.props.id} onBlur={this.props.onBlur} onChange={this.inputOnChange} value={this.state.value} />
                </span>
            </div>
        )
    }
});

var Calendar = React.createClass({
    getInitialState: function() {
        return {
            showCalendar: false,
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
                <ReactDateTime className='custom-metadata-input-width' value={this.props.value} onChange={this.onChange}/> 
            </div>
        )
    }
});

let TextAreaComponent = React.createClass({
    getInitialState: function() {
        return {
            value: this.props.value
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
        }
    },

    handleAddition: function(group) {
        var groupArr = [];
        var data = this.props.value;
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
                this.setState({inputValue: ''});
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
        var data = this.props.value;
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
                console.log('deleted group success: ' + data);
            }.bind(this),
            error: function(data) {
                this.props.errorToggle('Failed to delete group', data);
            }.bind(this)
        });
    },

    render: function() {
        var data = this.props.value;
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
                    <input type='checkbox' className='custom-metadata-input-width' id={this.props.id} name={this.props.id} value={this.props.value} onClick={this.onChange}/>
                </span>
            </div>
        )
    },
})


module.exports = CustomMetaDataTable;
