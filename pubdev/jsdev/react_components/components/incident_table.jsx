//This is deprecated and is no longer used. 
//Use custom_metadata_table.jsx instead

let React               = require( 'react' );
let ReactDateTime       = require( 'react-datetime' );

let IncidentTable = React.createClass( {
    getInitialState: function() {
        let dropdown =  {
            'Type': [
                'NONE',
                'FYI',
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
        let title_to_data_name = {
            'Type': 'type',
            'DOE Category': 'category',
            'DOE Information Sensitivity': 'sensitivity',
            'DOE Security Category': 'security_category'
        }; 
        let date_types = ['Occurred', 'Discovered', 'Reported', 'Closed']; 
        let report_types = {'DOE Report Id:':'doe_report_id'};
        let reportValue = ''; 
        let reportTypeShort = '';
        let reportType = '';
        $( Object.getOwnPropertyNames( report_types ) ).each( function( index, report_type ) {
            reportTypeShort = report_types[report_type];
            if ( this.props.headerData != null ) {
                reportValue = this.props.headerData[reportTypeShort];
            }
            reportType = report_type;
        }.bind( this ) ); 
        
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
        };
    },
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
                console.log( 'successfully changed incident data' );
            }.bind( this ),
            error: function( data ) {
                this.props.errorToggle( 'Failed to updated incident data', data ); 
            }.bind( this )
        } );
    },
    inputOnChange: function( event ) {
        this.setState( {reportValue:event.target.value} );
    },
    render: function() {
        let incidentData = this.props.headerData;
        let dropdownArr = [];
        let datesArr = [];
        let reportingArr = [];
        $( Object.getOwnPropertyNames( this.state.dropdownOptions ) ).each( function( index, dropdown_name ) {
            let arr = [];
            for ( let i=0; i < this.state.dropdownOptions[dropdown_name].length; i++ ){
                let item = this.state.dropdownOptions[dropdown_name][i];
                arr.push( <option>{item}</option> );
            }
            let datetype = this.state.title_to_data_name[dropdown_name];
            let selectValue = this.props.headerData[datetype];
            let dropdownTitle = dropdown_name+':';
            dropdownArr.push( <div><span className='incidentTableWidth'>{dropdownTitle}</span><span><select id={datetype} value={selectValue} onChange={this.onChange}>{arr}</select></span></div> );
        }.bind( this ) );
        for ( let i=0; i < this.state.date_types.length; i++ ) {
            let datetype = this.state.date_types[i];
            let typeLower = this.state.date_types[i].toLowerCase();
            let typeTitle = datetype + ':';
            let value = this.props.headerData[typeLower] * 1000;
            datesArr.push( <IncidentDates typeTitle={typeTitle} value={value} typeLower={typeLower} type={this.props.type} id={this.props.id}/> );
        }
        let arr = [];
        arr.push( <input onBlur={this.onChange} onChange={this.inputOnChange} value={this.state.reportValue} id={this.state.reportTypeShort}/> );
        reportingArr.push( <div><span className='incidentTableWidth'>{this.state.reportType}</span><span>{arr}</span></div> );
        return (
            <div className='incidentTable'>
                {dropdownArr}
                {datesArr}
                {reportingArr}
            </div>
        );
    }
} );

let IncidentDates = React.createClass( {
    getInitialState: function() {
        return {
            showCalendar: false,
        };
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
                console.log( 'successfully changed incident data' );
            }.bind( this ),
            error: function( data ) {
                this.props.errorToggle( 'Failed to updated incident data', data ); 
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
            <div style={{display:'flex',flexFlow:'row'}}>
                <span className='incidentTableWidth'>
                    {this.props.typeTitle}
                </span>
                <ReactDateTime value={this.props.value} onChange={this.onChange}/> 
            </div>
        );
    }
} );


module.exports = IncidentTable;
