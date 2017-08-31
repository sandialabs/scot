import React, { PureComponent, Component } from 'react';
import PropTypes from 'prop-types';
import { Modal, Button, ButtonGroup } from 'react-bootstrap';
import ReactTable from 'react-table';

class Links extends Component {
    constructor( props ) { 
        super( props );

        this.state = {
            data: [],
            allSelected: false,
            loading: false,
        }
        
        this.getLinks = this.getLinks.bind(this);
    }

    componentWillMount() {
        this.getLinks();
        this.mounted = true;
    }        

    componentWillUnmount() {
        this.mounted = false;
    }
    
    render() {

        const columns = [
    
            {
                Header: 'Type',
                accessor: 'type',
                maxWidth: 150,
                sortable: true,
            },
            {   Header: 'ID',
                accessor: 'id',
                maxWidth: 100,
                sortable: true,
            },
        
        ]
        
        return (
            <Modal dialogClassName='links-modal' show={ this.props.modalActive } onHide={ this.props.linksModalToggle }>
                <Modal.Header closeButton={ true } >
                    <Modal.Title>
                        {this.state.data.length} items linked to {this.props.type} {this.props.id}
                    </Modal.Title>
                </Modal.Header>
                <Modal.Body>
                    
                    <ReactTable 
                        columns = { columns } 
                        data = { this.state.data } 
                        defaultPageSize = { 10 }
                        minRows = { 0 }
                        noDataText= 'No items Linked.'
                        loading = { this.state.loading }
                    />
                    
                </Modal.Body>
                <Modal.Footer>
                    Links Footer
                </Modal.Footer>
            </Modal>
        )
    }

    getLinks () {
        this.setState({ loading: true });

        $.ajax({
            type: 'get',
            url: '/scot/api/v2/' + this.props.type + '/' + this.props.id + '/link',
            success: function( data ) {
                let arr = [];
                
                for ( let i = 0; i < data.records.length; i++ ) {
                    for ( let j = 0; j < data.records[i].vertices.length; j++ ) {
                        //if ids are equal, check if the type is equal. If so, it's what is displayed so don't show it.
                        if ( data.records[i].vertices[j].id == this.props.id  ) {
                            if ( data.records[i].vertices[j].type != this.props.type ) {
                                arr.push( data.records[i].vertices[j] );
                            } else {
                                continue;
                            }
                        } else {
                            arr.push( data.records[i].vertices[j] );
                        }
                    }
                }

                this.setState({ data: arr, loading: false });
            }.bind(this),
            error: function( data ) {
                this.setState({ loading: false });
                this.props.errorToggle( 'failed to get links', data );
            }.bind(this),
        });
    }
}


export default Links;
