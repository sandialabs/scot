import React from 'react';
import { withStyles } from '@material-ui/core/styles';
import Button from '@material-ui/core/Button';
import Card from '@material-ui/core/Card';
import CardContent from '@material-ui/core/CardContent';
import EntityInfo from './EntityInfo';
import ThingInfo from './ThingInfo';

const styles = theme => ({
    card: {
        minWidth: 200,
        marginBotton: 20
    },
});

class NodeInfo extends React.Component {

    constructor(props) {
        super(props);
    }

    render() {
        console.log("Render NodeInfo")
        console.log(this.props);
        let ni = this.props.nodeInfo;
        let type = ni.sourcetype;

        return (
            <div>
                { type === "entity" ? 
                <EntityInfo nodeInfo={ni} /> : 
                <ThingInfo nodeInfo={ni} />
                }
            </div>
        );
    }
}

export default NodeInfo;

