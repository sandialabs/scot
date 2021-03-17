import React from 'react';
import Typography from '@material-ui/core/Typography';
import { withSnackbar } from 'notistack';
import { withStyles } from '@material-ui/core/styles';
import axios from 'axios';
import Button from '@material-ui/core/Button';
import Card from '@material-ui/core/Card';
import CardContent from '@material-ui/core/CardContent';
import GraphControl from './GraphControl';
import NodeInfo from './NodeInfo';
import { ForceGraph2D, ForceGraph3D, ForceGraphVR, ForceGraphAR } from 'react-force-graph';

const styles = theme => ({
    card: {
        minWidth: 800,
        marginBottom: 20
    },
    ScotForceGraphDisplay: {
        display: "flex",
        "flex-direction": "row"
    },
});

function merge_arrays(a, b, key) {
    let reduced = a.filter( aitem => ! b.find( bitem => aitem[key] === bitem[key]) )
    return reduced.concat(b);
}

class ScotForceGraph extends React.Component {

    constructor(props) {
        super(props);
        this.state = {
            graph: null,
            nodeinfo: ''
        };
    }

    componentDidMount() {
        console.log("componentDidMount");
        this.loadGraph("event",10002,2);
    }

    loadGraph = (type, id, depth) => {
        console.log("loading graph");
        let uri = `/scot/api/v2/graph/${type}/${id}/${depth}`;
        axios.get(uri).then(
            response => {
                console.log(response);
                // this.state.graph = response.data;
                console.log(this.state.graph);
                this.setState({ graph: response.data });
            }
        );
    }

    add_to_graph = (type, id, depth) => {
        let uri = `/scot/api/v2/graph/${type}/${id}/${depth}`;
        axios.get(uri).then(
            response => {
                let new_nodes = response.data.nodes;
                let new_links = response.data.links;
                let existing_nodes  = this.graph.nodes;
                let existing_links  = this.graph.links;
                let new_graph_nodes = merge_arrays(new_nodes, existing_nodes);
                let new_graph_links = merge_arrays(new_links, existing_links);
                this.state.graph = {
                    nodes: new_graph_nodes,
                    links: new_graph_links
                };
            }
        );
    }

    draw_to_canvas = (node, ctx, globalScale) => {
        const label = node.id
        const fontSize = 12/globalScale;
        ctx.font = `${fontSize}px Sans-Serif`;
        const textWidth = ctx.measureText(label).width;
        const bckgDimensions = [textWidth, fontSize].map(n => n + fontSize *0.2);
        if ( node.id.match(/entity/) ) {
            ctx.fillStyle = 'rgba(255,80,80,0.8)';
            ctx.beginPath(); ctx.arc(node.x,node.y,8, 0, 2*Math.PI, false);
            ctx.fill();
        } else {
            if ( node.id.match(/intel/) ) {
                ctx.fillStyle = 'rgba(30,30,200,0.6)';
            }
            else if ( node.id.match(/event/)) {
                ctx.fillStyle = 'rgba(0,255,0,0.6)';
            }
            else {
                ctx.fillStyle = 'rgba(255,255,255,0.8)';
            }
            ctx.fillRect(node.x - bckgDimensions[0] /2, 
                        node.y -bckgDimensions[1] /2, 
                        ...bckgDimensions);
        }
        ctx.textAlign = 'center';
        ctx.textBaseline = 'middle';
        ctx.fillStyle = 'black';
        //ctx.fillStyle = node.color;
        ctx.fillText(label, node.x, node.y);
        node.__bckgDimensions = bckgDimensions;
    }

    node_paint = (node, color, ctx) => {
        ctx.fillStyle = color;
        const bckgDimensions = node.__bckgDimensions;
        bckgDimensions && 
            ctx.fillRect(
                node.x - bckgDimensions[0]/2, 
                node.y - bckgDimensions[1]/2, 
                ...bckgDimensions
            );
    }

    handleNodeHover = node => {
        if (node) {
            const target_type   = node.target_type;
            const target_id     = node.target_id;
            const uri = `/scot/api/v2/${target_type}/${target_id}`;
            console.log(`requesting info about ${target_type} ${target_id}`);
            axios.get(uri).then(
                response => {
                    const data = response.data;
                    console.log("got data");
                    console.log(data);
                    data["sourcetype"] = target_type;
                    this.setState({ nodeinfo: data });
                }
            );
        }
    }

    render() {
        console.log("render");
        let nodeinfo = `${this.state.nodeinfo}`;
        // console.log("nodeinfo =>");
        // console.log(nodeinfo);
        return this.state.graph ? (
            <div style={{display: 'flex', flexDirection: 'row'}}>
                <div id="infocontrols" style={{minWidth: 300}}>
                    <div id="controls">
                        <h3>Graph Control</h3>
                    </div>
                    <div id="info">
                        <NodeInfo
                         nodeInfo={this.state.nodeinfo}
                        />
                    </div>
                </div>
                <ForceGraph2D
                 graphData={this.state.graph}
                 nodeCanvasObject={(node, ctx, globalScale) => { this.draw_to_canvas(node,ctx, globalScale)}}
                 nodePointerAreaPaint={(node, color, ctx) => { this.node_paint(node,color,ctx) }}
                 onNodeHover={this.handleNodeHover}
                />
            </div>
        ) :
        ( <div>Loading...</div>);
    }
}
export default withSnackbar(withStyles(styles)(ScotForceGraph));
