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
import * as THREE from 'three';
import SpriteText from 'three-spritetext';

const styles = theme => ({
    card:   {
        minWidth: 800,
        marginBottom: 10,
    },
});

const nodeinfostyle = {
    backgroundColor: 'white',
    color: 'black'
};

const sidebyside = {
    display: "flex",
    flexDirection: "row"
};

class SFG extends React.Component {

    constructor(props) {
        super(props);
        this.state = {
            graph: {
                nodes: [],
                links: []
            },
            nodeinfo: {},
            graphtype: '2D',
            highlightNodes: [],
            highlightLinks: [],
            hoverNode: ''
        };
    }

    add_to_graph = (type, id, depth) => {
        const uri = `/scot/api/v2/graph/${type}/${id}/${depth}`;
        const graphcopy = JSON.parse(JSON.stringify(this.state.graph));
        axios.get(uri).then(
            response => {
                this.update_graph(response, graphcopy);
            }
        );
    }

    update_graph = (response, graphcopy) => {
        const response_graph = response.data;
        let new_graph = {
            nodes: this.merge_arrays(response_graph.nodes, graphcopy.nodes),
            links: this.merge_arrays(response_graph.links, graphcopy.links)
        };
        this.setState({graph: new_graph});
    }

    merge_arrays = (a, b, k) => {
        let reduced = a.filter(
            a_item => ! b.find( 
                b_item => a_item[k] === b_item[k]
            )
        );
        return reduced.concat(b);
    }

    handle_node_add = (event) => {
        event.preventDefault();
        this.add_to_graph(
            event.target.elements.thingtype.value,
            event.target.elements.thingid.value,
            event.target.elements.depth.value
        );
    }

    handleNodeHover = node => {
        console.log("Node Hover");
        console.log(node);
        if ( node ) {
            //this.setState({hoverNode: node});
            //this.setState({highlightNodes: []});
            //this.setState({highlightLinks: []});
            const uri = `/scot/api/v2/${node.target_type}/${node.target_id}`;
            axios.get(uri).then(
                response => {
                    const data = response.data;
                    data["sourcetype"] = node.target_type;
                    this.setState({nodeinfo: data});
                }
            );
            // hightlighting
            //let hnodes = [];
            //let hlinks = [];
            //hnodes.push(node);
            //node.neighbors.forEach(neighbor => hnodes.push(node));
            //node.links.forEach( link => hlinks.push(link) );
            //this.setState({highlightNodes: hnodes});
            //this.setState({highlightLinks: hlinks});
        }
    }

    handleNodeClick = node => {
        console.log("Node Clicked");
        console.log(node);
        if ( node ) {
            const uri = `/#/${node.target_type}/${node.target_id}`;
            window.open(uri);
        }
    }

    handleClearGraph = () => {
        this.setState({graph: {}});
    }

    handleToggleGraph = () => {
        if (this.state.graphtype === '2D') {
            this.setState({graphtype: '3D'});
        }
        else {
            this.setState({graphtype: '2D'});
        }
    }

    draw_to_canvas  = (node, ctx, globalScale) => {
        this.node_paint(node, node.color, ctx);
    }

    node_paint = (node, color, ctx) => {
        //const radius = (5 - ( 5 / node.degree )) + 4; 
        const radius = 5;
        ctx.fillStyle = color;
        ctx.beginPath();
        ctx.arc(node.x, node.y, radius, 0, 2 * Math.PI, false);
        ctx.fill();
        //if ( this.state.highlightNodes.includes(node) ) {
        //    this.paint_highlight(node,ctx);
        //}
    }

    paint_highlight = (node,ctx) => {
        ctx.beginPath();
        ctx.arc(node.x, node.y, 5*1.4, 0, 2*Math.PI, false);
        ctx.fillStyle = node === this.state.hoverNode ? 'red':'yellow';
        ctx.fill();
    }

    render() {
        return (
            <div>
                <div className="GraphControl" style={nodeinfostyle}>
                        <div style={sidebyside}>
                            <button onClick={this.handleToggleGraph}>Toggle Graph Mode</button>
                            <form onSubmit={this.handle_node_add}>
                                <label htmlFor="thingtype">Enter Type:</label>
                                <select id="thingtype" name="thingtype">
                                    <option>event</option>
                                    <option>intel</option>
                                    <option>incident</option>
                                    <option>dispatch</option>
                                    <option>entity</option>
                                </select>
                                <label htmlFor="thingid">Enter ID:</label>
                                <input id="thingid" name="thingid" type="text"/>
                                <label htmlFor="depth">Enter Depth:</label>
                                <input id="depth" name="depth" type="text"/>
                                <button>Go!</button>
                            </form>
                        </div>
                </div>
                <div className="NodeInfo" style={nodeinfostyle}>
                    <NodeInfo nodeInfo={this.state.nodeinfo}/>
                </div>
                <div className="GraphView">
                    { this.state.graphtype === '2D' ?
                    <ForceGraph2D
                     graphData={this.state.graph}
                     onNodeClick={this.handleNodeClick}
                     onNodeHover={this.handleNodeHover}
                     nodeAutoColorBy="target_type"
                     nodeCanvasObject={
                        (node, ctx, globalScale) => 
                            { this.draw_to_canvas(node,ctx,globalScale)}
                     }
                     nodePointerAreaPaint={
                        (node, color, ctx) => 
                            { this.node_paint(node, color, ctx) }
                     }
                    />
                    :
                    <ForceGraph3D
                     graphData={this.state.graph}
                     nodeAutoColorBy="target_type"
                     nodeThreeObject={
                        node => new THREE.Mesh(
                                    new THREE.SphereGeometry(2, 16, 16),
                                    new THREE.MeshBasicMaterial({ color: node.color })
                                )
                     }
                     onNodeClick={this.handleNodeClick}
                     onNodeHover={this.handleNodeHover}
                    />
                    }
                </div>
            </div>
        );
    }
}
export default withSnackbar(withStyles(styles)(SFG));


