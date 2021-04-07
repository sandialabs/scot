import React from 'react';
import {withStyles } from '@material-ui/core/styles';

const style = {
    width: "100%",
    padding: "5px"
};

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
                <table style={style}>
                    <tr>
                        <th>{ti.sourcetype}</th> 
                        <td>id: {ti.id}</td>
                        <td>subject: {ti.subject}</td>
                        <td>status: {ti.status}</td>
                        <td>Tags:
                            {tags.length > 0 && tags.map((tag) => (
                                {tag}
                            ))}</td>
                        <td>Entries: {ti.entry_count}</td>
                    </tr>
                </table>
            </div>
        );
    }
}
export default EntityInfo;
