let React = require( 'react' );
let Panel = require( 'react-bootstrap/lib/Panel.js' );

let Online = React.createClass( {
    getInitialState: function() {
        return {
            OnlineData: null
        };
    },
    componentDidMount: function() {
        $.ajax( {
            type: 'get',
            url: '/scot/api/v2/who',
            success: function( response ) {
                this.setState( {OnlineData:response.records} );
            }.bind( this ),
            error: function( data ) {
                this.props.errorToggle( 'failed to get current user', data );
            }.bind( this )
        } );
    },
    render: function() {
        let OnlineRows = [];
        if ( this.state.OnlineData != null ) {
            for ( let i=0; i < this.state.OnlineData.length; i++ ) {
                let timeago = timeSince( this.state.OnlineData[i].last_activity );
                OnlineRows.push(
                    <Panel header={this.state.OnlineData[i].username} >
                        <div style={{display:'flex', flexFlow:'column'}}>
                            <div>{timeago} ago</div>
                        </div>
                    </Panel>
                );
            }
        } else {
            OnlineRows.push(
                <Panel header={'SCOT 3.5 Online'}>
                    <br/>
                    <div style={{fontWeight:'bold'}}>Coming Soon</div>
                    <br/>
                </Panel>
            );
        }
        return (
            <div id='online' className="dashboard col-md-2">
                <div style={{textAlign:'center'}}>
                    <h2>Activity</h2>
                </div>
                <div>
                    {OnlineRows}
                </div>
            </div>
        );
    }
} );

module.exports = Online;
