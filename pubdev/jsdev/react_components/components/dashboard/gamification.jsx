let React = require( 'react' );
let Panel = require( 'react-bootstrap/lib/Panel.js' );
let Badge = require( 'react-bootstrap/lib/Badge.js' );
let Tooltip = require( 'react-bootstrap/lib/Tooltip.js' );
let OverlayTrigger = require( 'react-bootstrap/lib/OverlayTrigger.js' );

let Gamification = React.createClass( {
    getInitialState: function() {
        return {
            GameData: null
        };
    },
    componentDidMount: function() {
        $.ajax( {
            type: 'get',
            url: '/scot/api/v2/game',
            success: function( response ) {
                this.setState( {GameData:response} );
            }.bind( this ),
            error: function( data ) {
                this.props.errorToggle( 'unable to get game data', data );
            }.bind( this )
        } );
    },
    titleCase: function( string ) {
        let newstring = string.charAt( 0 ).toUpperCase() + string.slice( 1 );
        return (
            newstring
        );
    },
    render: function() {
        let GameRows = [];
        if ( this.state.GameData != null ) {
            for ( let key in this.state.GameData ) {
                let keyCapitalized = this.titleCase( key );
                GameRows.push(
                    <OverlayTrigger placement="top" overlay={<Tooltip id='tooltip'>{this.state.GameData[key][0].tooltip}</Tooltip>}>
                        <Panel header={keyCapitalized} >
                            <div>
                                <div>{this.state.GameData[key][0].username} <Badge>{this.state.GameData[key][0].count}</Badge></div>
                                <div>{this.state.GameData[key][1].username} <Badge>{this.state.GameData[key][1].count}</Badge></div>
                                <div>{this.state.GameData[key][2].username} <Badge>{this.state.GameData[key][2].count}</Badge></div>
                            </div>
                        </Panel>
                    </OverlayTrigger>
                );
            }
        }
        return (
            <div id='gamification' className="dashboard col-md-2">
                <div>
                    <h2>Leader Board</h2>
                </div>
                <div>
                    {GameRows}
                </div>
            </div>
        );
    }
} );

module.exports = Gamification;
