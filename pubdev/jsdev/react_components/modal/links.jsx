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
            {   Header: 'Subject',
                accessor: 'subject',
                maxWidth: '100%',
                sortable: true,
            },   
        
        ]
        
        return (
            <Modal dialogClassName='links-modal' show={ this.props.modalActive } onHide={ this.props.linksModalToggle }>
                <Modal.Header closeButton={ true } >
                    <Modal.Title>
                        Links
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
                this.setState({ data: data.records, loading: false });
            }.bind(this),
            error: function( data ) {
                this.setState({ loading: false });
                this.props.errorToggle( 'failed to get links', data );
            }.bind(this),
        });
    }
}


export default Links;
