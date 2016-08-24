var React               = require('react');
var AppActions          = require('../flux/actions.jsx');
var ReactDateTime       = require('react-datetime');

var IncidentTable = React.createClass({
    getInitialState: function() {
            var dropdown =  {
                'Type': [
                    'Type 1 : Root Comprimise',
                    'Type 1 : User Compromise',
                    'Type 1 : Loss/Theft/Missing Desktop',
                    'Type 1 : Loss/Theft/Missing Laptop',
                    'Type 1 : Loss/Theft/Missing Media',
                    'Type 1 : Loss/Theft/Missing Other',
                    'Type 1 : Malicious Code Trojan',
                    'Type 1 : Malicious Code Virus',
                    'Type 1 : Malicious Code Worm',
                    'Type 1 : Malicious Code Other',
                    'Type 1 : Web Site Defacement',
                    'Type 1 : Denial of Service',
                    'Type 1 : Critical Infrastructure Protection',
                    'Type 1 : Unauthorized Use',
                    'Type 1 : Information Compromise',
                    'Type 2 : Attempted Intrusion',
                    'Type 2 : Reconnaissance Activity',
                ],
                'DOE Category': [
                    'NONE',
                    'IMI-1',
                    'IMI-2',
                    'IMI-3',
                    'IMI-4'
                ],
                'DOE Information Sensitivity': [
                    'NONE',
                    'OUO',
                    'PII',
                    'SUI',
                    'UCNI',
                    'Other'
                ],
                'DOE Security Category': [
                    'NONE',
                    'Low',
                    'Moderate',
                    'High'

                ]
        };
        var title_to_data_name = {
            'Type': 'type',
            'DOE Category': 'category',
            'DOE Information Sensitivity': 'sensitivity',
            'DOE Security Category': 'security_category'
        }; 
        var date_types = ['Occurred', 'Discovered', 'Reported', 'Closed'] 
        var report_types = {'DOE Report Id:':'doe_report_id'};
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
            error: function() {
                this.props.errorToggle('Failed to updated incident data') 
            }.bind(this)
        })
        console.log(event);
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
            for (i=0; i < this.state.dropdownOptions[dropdown_name].length; i++){
                var item = this.state.dropdownOptions[dropdown_name][i];
                //for (var prop in this.state.title_to_data_name) {
                    //var type = this.state.title_to_data_name[prop];
                    //if (type == this.state.title_to_data_name[dropdown_name]) {
                        //if (incidentData[type] != null) {
                            //if (incidentData[type] == item) {
                            //    arr.push(<option selected="selected">{item}</option>)
                            //} else {
                                arr.push(<option>{item}</option>)
                            //}
                        //}
                    //}
                //}
            }
            var datetype = this.state.title_to_data_name[dropdown_name];
            var selectValue = this.props.headerData[datetype];
            var dropdownTitle = dropdown_name+':'
            dropdownArr.push(<div><span className='incidentTableWidth'>{dropdownTitle}</span><span><select id={datetype} value={selectValue} onChange={this.onChange}>{arr}</select></span></div>)
        }.bind(this))
        for (i=0; i < this.state.date_types.length; i++) {
            var datetype = this.state.date_types[i];
            var typeLower = this.state.date_types[i].toLowerCase();
            var typeTitle = datetype + ':';
            var value = this.props.headerData[typeLower] * 1000;
            datesArr.push(<IncidentDates typeTitle={typeTitle} value={value} typeLower={typeLower} type={this.props.type} id={this.props.id}/>);
            //datesArr.push(<div style={{display:'flex',flexFlow:'row'}}><span>{typeTitle}</span><span style={{width:'250px'}}><input value={formatTime} onClick={this.showCalendar}/></span>{this.state.showCalendar ? <ReactInputMoment moment={moment} onSave={this.onSave}/> : null}</div>)
        }
        $(Object.getOwnPropertyNames(this.state.report_types)).each(function(index, report_type) {
            var reportTypeShort = this.state.report_types[report_type];
            var value = this.props.headerData[reportTypeShort];
            var arr = [];
            arr.push(<input onBlur={this.onChange} value={value} id={reportTypeShort}/>);
            reportingArr.push(<div><span className='incidentTableWidth'>{report_type}</span><span>{arr}</span></div>);
        }.bind(this))
        return (
            <div className='incidentTable'>
                {dropdownArr}
                {datesArr}
                {reportingArr}
            </div>
        )
    }
});

var IncidentDates = React.createClass({
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
            error: function() {
                this.props.errorToggle('Failed to updated incident data') 
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
