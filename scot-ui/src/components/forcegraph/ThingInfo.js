import React from 'react';
import {withStyles } from '@material-ui/core/styles';

class EntityInfo extends React.Component {
    
    constructor(props) {
        super(props);
    }

    render() {
        let ti  = this.props.nodeInfo;
        let tags = ti.tags;
        if ( typeof tags === 'undefined' ) {
            tags = [];
        }
        return (
            <div>
                <h3>{ti.sourcetype} Info</h3>
                <table>
                    <tr>
                        <th>{ti.subject}</th>
                    </tr>
                    <tr>
                        <td>{ti.status}</td>
                    </tr>
                    <tr>
                        <ol>
                            {tags.length > 0 && tags.map((tag) => (
                                <li key={tag}>{tag}</li>
                            ))}
                        </ol>
                    </tr>
                    <tr>
                        <td>Entries: {ti.entry_count}</td>
                    </tr>
                </table>
            </div>
        );
    }
}
export default EntityInfo;
