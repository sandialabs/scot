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

class GraphControl extends React.Component {

    constructor(props) {
        super(props);
    }

    render() {
        return (
            <div>
                <h3>Graph Controls</h3>
                <p>controls go here</p>
            </div>
        );
    }
}

export default GraphControl;

