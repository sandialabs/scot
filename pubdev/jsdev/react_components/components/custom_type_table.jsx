var React               = require('react');
var ReactDateTime       = require('react-datetime');

var CustomTypeTable = React.createClass({
    getInitialState: function() {
        
        return {
            data: [
                {
                    type: 'dropdown',
                    key: 'sensitivity',
                    value: [{value: 'FYI', selected: 1}, {value: 'none', selected: 0}],
                    label: 'DOE Information Sensitivity'
                },
                {
                    type: 'input',
                    key: 'doe_report_id',
                    value: 'default string',
                    label: 'DOE Report Category',
                },
                {
                    type: 'calendar',
                    key: 'occurred',
                    value: 1494018000,
                    label: 'Occurred'
                }
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
         
        for ( let i=0; i < this.state.data.length; i++ )  {
            switch ( this.state.data[i]['type'] ) {
                case 'dropdown':
                    dropdownArr.push(<DropdownComponent onChange={this.onChange} label={this.state.data[i].label} id={this.state.data[i].key} value={this.state.data[i].value}/>)
                    break;

                case 'input':
                    inputArr.push(<InputComponent onBlur={this.onChange} value={this.state.data[i].value} id={this.state.data[i].key} label={this.state.data[i].label} />)
                    break;

                case 'calendar':
                    let value = this.state.data[i].value * 1000
                    datesArr.push(<Calendar typeTitle={this.state.data[i].label} value={value} typeLower={this.state.data[i].key} type={this.props.type} id={this.props.id}/>);
                    break;

                case 'textarea':
                    break;
                
                case 'input_multi':
                    break;
            }
        }

        return (
            <div className='incidentTable'>
                {dropdownArr}
                {datesArr}
                {inputArr}
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
            <div>
                <span className='incidentTableWidth'>
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
            <div>
                <span className='incidentTableWidth'>
                    {this.props.label}
                </span>
                <span>
                    <input id={this.props.id} onBlur={this.props.onBlur} onChange={this.inputOnChange} value={this.state.value} />
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
            <div style={{display:'flex',flexFlow:'row'}}>
                <span className='incidentTableWidth'>
                    {this.props.typeTitle}:
                </span>
                <ReactDateTime value={this.props.value} onChange={this.onChange}/> 
            </div>
        )
    }
});


module.exports = CustomTypeTable;
