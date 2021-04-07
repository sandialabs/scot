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
        //this.handleNodeAddition = this.handleNodeAddition.bind(this);
        this.state = {
            graph: {
                nodes: [],
                links: []
            },
            nodeinfo: ''
        };
    }

    componentDidMount() {
        console.log("componentDidMount");
        // this.loadGraph("event",10002,2);
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
        console.log(`Adding ${uri} to graph`); 
        const existing_graph = JSON.parse(JSON.stringify(this.state.graph));
        axios.get(uri).then(
            response => {
                let new_nodes = response.data.nodes;
                let new_links = response.data.links;
                let existing_nodes  = existing_graph.nodes;
                let existing_links  = existing_graph.links;

                let new_graph_nodes = merge_arrays(new_nodes, existing_nodes);
                let new_graph_links = merge_arrays(new_links, existing_links);
                let new_graph = {
                    nodes: new_graph_nodes,
                    links: new_graph_links
                };
                this.setState({ graph: new_graph });
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

    handleNodeAddition(e) {
        e.preventDefault();
        console.log("event is");
        console.log(e);
        const data = new FormData(e.target);
        console.log("node addition");
        console.log(data);
        this.add_to_graph(data.thingtype, data.thingid, data.depth);
    }

    handle_node_add = (event) => {
        event.preventDefault();
        console.log("event.target.elements");
        console.log(event.target.elements);
        this.add_to_graph(
            event.target.elements.thingtype.value,
            event.target.elements.thingid.value,
            event.target.elements.depth.value
        );
    }

    render() {
        console.log("render");
        let nodeinfo = `${this.state.nodeinfo}`;
        // console.log("nodeinfo =>");
        // console.log(nodeinfo);
        return (
            <div style={{display: 'flex', flexDirection: 'row'}}>
                <div id="infocontrols" style={{minWidth: 300}}>
                    <div id="controls">
                        <h3>Graph Control</h3>
                        <form onSubmit={this.handle_node_add}>
                            <label htmlFor="thingtype">Enter Type:</label>
                            <input id="thingtype" name="thingtype" type="text"/>
                            <label htmlFor="thingid">Enter ID:</label>
                            <input id="thingid" name="thingid" type="text"/>
                            <label htmlFor="depth">Enter Depth:</label>
                            <input id="depth" name="depth" type="text"/>
                            <button>Go!</button>
                        </form>
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
        );
    }
}
export default withSnackbar(withStyles(styles)(ScotForceGraph));
