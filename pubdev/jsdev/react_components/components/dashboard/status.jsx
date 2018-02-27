let React = require( 'react' );
let Panel = require( 'react-bootstrap/lib/Panel.js' );
let Badge = require( 'react-bootstrap/lib/Badge.js' );

let Status = React.createClass( {
    getInitialState: function() {
        return {
            StatusData: null
        };
    },
    componentDidMount: function() {
        $.ajax( {
            type: 'get',
            url: '/scot/api/v2/status',
            success: function( response ) {
                this.setState( {StatusData:response} );
            }.bind( this ),
            error: function( data ) {
                this.props.errorToggle( 'failed to get status', data );
            }.bind( this )
        } );
    },
    render: function() {
        let StatusRows = [];
        if ( this.state.StatusData != null ) {
            for ( let key in this.state.StatusData ) {
                let className = 'dashboardStatusDetail';
                if ( this.state.StatusData[key] == 'Not Running' ) {
                    className = 'dashboardStatusDetailNotRunning';
                } else if ( this.state.StatusData[key] == 'Running' ) {
                    className = 'dashboardStatusDetailRunning';
                }
                StatusRows.push(
                    <Panel header={key} >
                        <div className='dashboardStatusChild'>
                            <div className={className}>{this.state.StatusData[key]}</div>
                        </div>
                    </Panel>
                );
            }
        } else {
            StatusRows.push(
                <Panel header={'SCOT 3.5 Status'}>
                    <br/>
                    <div style={{fontWeight:'bold'}}>Coming Soon</div>
                    <br/>
                </Panel>
            );
        }
        return (
            <div id='status' className="dashboardStatusParent">
                <div>
                    <h2>Status</h2>
                </div>
                <div>
                    {StatusRows}
                </div>
            </div>
        );
    }
} );

module.exports = Status;
