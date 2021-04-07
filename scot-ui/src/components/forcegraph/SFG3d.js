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

class SFG3d extends React.Component {

    constructor(props) {
        super(props);
        this.state = {
            graph: {
                nodes: [],
                links: []
            },
            nodeinfo: {}
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
        if ( node ) {
            const uri = `/scot/api/v2/${node.target_type}/${node.target_id}`;
            axios.get(uri).then(
                response => {
                    const data = response.data;
                    data["sourcetype"] = node.target_type;
                    this.setState({nodeinfo: data});
                }
            );
        }
    }

    handleNodeClick = node => {
        if ( node ) {
            const uri = `/#/${node.target_type}/${node.target_id}`;
            window.open(uri);
        }
    }

    handleClearGraph = () => {
        this.setState({graph: {}});
    }

    render() {
        return (
        <div>
            <div style={{"background-color": "black", color: "white"}}>
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
                <button onClick={this.handleClearGraph}>Clear Graph</button>
            </div>
            <div style={{width: "100%"}}>
                <NodeInfo
                 nodeInfo={this.state.nodeinfo}
                />
            </div>
            <ForceGraph3D 
             graphData={this.state.graph}
             nodeAutoColorBy="target_type"
             nodeThreeObject={ 
                node => new THREE.Mesh(
                        new THREE.SphereGeometry(10),
                        new THREE.MeshBasicMaterial({ color: node.color })
                    )
             }
             onNodeClick={this.handleNodeClick}
             onNodeHover={this.handleNodeHover}
            />
        </div>
        );
    }
}
export default withSnackbar(withStyles(styles)(SFG3d));


