import React from 'react';
import { withStyles } from '@material-ui/core/styles';
import Button from '@material-ui/core/Button';
import Card from '@material-ui/core/Card';
import CardContent from '@material-ui/core/CardContent';

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
        return (
            <div>
                <h3>Node Info</h3>
                <h4>{ni.sourcetype}</h4>
                <table>
                    <tr>
                        <td>Value</td><td>{ni.value}</td>
                    </tr><tr>
                        <td>sourcetype</td><td>{ni.sourcetype}</td>
                    </tr>
                </table>
            </div>
        );
    }
}

export default NodeInfo;

