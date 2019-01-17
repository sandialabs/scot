let React = require( 'react' );

let Visualization = React.createClass( {
    componentDidMount: function() {
        /*var g = {
            nodes: [],
            edges: [],
        };
        var s = new sigma({
            graph: g,
            renderer: {
                container: document.getElementById('main-detail-container'),
                type: 'canvas'
            },
        });*/
        //sigma.parsers.json('/scot/api/v2/graph/'+this.props.type+'/'+this.props.id+'/'+this.props.depth, {
        
        sigma.parsers.json( 'arctic.json', {
            container: 'visualization'
        } );   
    },
    render: function() {
        return (
            <div id='visualization' style={{position:'absolute',top:0,bottom:0,right:0,left:0, height:'90vh', width:'90vw'}}> 
            </div>
        );
    }
} );

module.exports = Visualization;
