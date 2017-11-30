var React               = require('react');
var ReactDateTime       = require('react-datetime');

var IncidentTable = React.createClass({
    getInitialState: function() {
        
        return {
            dropdownOptions: dropdown,
            title_to_data_name: title_to_data_name,
            date_types: date_types,
            report_types: report_types,
            occurred: 0,
            discovered: 0,
            reported: 0,
            closed: 0,
            reportId: 0,
            reportValue: reportValue,
            reportTypeShort: reportTypeShort,
            reportType: reportType,
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
                console.log('successfully changed incident data');
            }.bind(this),
            error: function(data) {
                this.props.errorToggle('Failed to updated incident data', data) 
            }.bind(this)
        })
    },

    inputOnChange: function(event) {
        this.setState({reportValue:event.target.value});
    },

    render: function() {
        var incidentData = this.props.headerData;
        var wholeTable = [];
        var dropdownArr = [];
        var datesArr = [];
        var reportingArr = [];
        var incidentProps = Object.getOwnPropertyNames(incidentData);
        $(Object.getOwnPropertyNames(this.state.dropdownOptions)).each(function(index, dropdown_name) {
            var arr = [];
            for (var i=0; i < this.state.dropdownOptions[dropdown_name].length; i++){
                var item = this.state.dropdownOptions[dropdown_name][i];
                arr.push(<option>{item}</option>)
            }
            var datetype = this.state.title_to_data_name[dropdown_name];
            var selectValue = this.props.headerData[datetype];
            var dropdownTitle = dropdown_name+':'
            dropdownArr.push(<div><span className='incidentTableWidth'>{dropdownTitle}</span><span><select id={datetype} value={selectValue} onChange={this.onChange}>{arr}</select></span></div>)
        }.bind(this))
        for (var i=0; i < this.state.date_types.length; i++) {
            var datetype = this.state.date_types[i];
            var typeLower = this.state.date_types[i].toLowerCase();
            var typeTitle = datetype + ':';
            var value = this.props.headerData[typeLower] * 1000;
            datesArr.push(<Dates typeTitle={typeTitle} value={value} typeLower={typeLower} type={this.props.type} id={this.props.id}/>);
        }
        var arr = [];
        arr.push(<input onBlur={this.onChange} onChange={this.inputOnChange} value={this.state.reportValue} id={this.state.reportTypeShort}/>);
        reportingArr.push(<div><span className='incidentTableWidth'>{this.state.reportType}</span><span>{arr}</span></div>);
        return (
            <div className='incidentTable'>
                {dropdownArr}
                {datesArr}
                {reportingArr}
            </div>
        )
    }
});

var Dates = React.createClass({
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
                console.log('successfully changed incident data');
            }.bind(this),
            error: function(data) {
                this.props.errorToggle('Failed to updated incident data', data) 
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
                    {this.props.typeTitle}
                </span>
                <ReactDateTime value={this.props.value} onChange={this.onChange}/> 
            </div>
        )
    }
});


module.exports = IncidentTable;
