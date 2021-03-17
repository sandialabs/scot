import React from 'react';
import {withStyles } from '@material-ui/core/styles';

class EntityInfo extends React.Component {
    
    constructor(props) {
        super(props);
    }

    render() {
        let ei  = this.props.nodeInfo;
        return (
            <div>
                <h3>Entity Info</h3>
                <table>
                    <tr>
                        <th>{ei.value}</th>
                    </tr>
                    <tr>
                        <td>{ei.type}</td>
                    </tr>
                    <tr>
                        <td>Entries: {ei.entry_count}</td>
                    </tr>
                </table>
            </div>
        );
    }
}
export default EntityInfo;
