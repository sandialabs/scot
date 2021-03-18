import React from 'react';
import {withStyles } from '@material-ui/core/styles';

const tablestyle = {
    padding: "5px",
    width: "100%"
};


class EntityInfo extends React.Component {
    
    constructor(props) {
        super(props);
    }

    render() {
        let ei  = this.props.nodeInfo;
        return (
            <div>
                <table style={tablestyle}>
                    <tr>
                        <th>Entity Info</th>
                        <td>id: {ei.id}</td>
                        <td>Entity: {ei.value}</td>
                        <td>Type: {ei.type}</td>
                        <td>Entries: {ei.entry_count}</td>
                    </tr>
                </table>
            </div>
        );
    }
}
export default EntityInfo;
