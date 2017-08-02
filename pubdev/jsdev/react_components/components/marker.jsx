import React, { PureComponent, Component } from 'react';
import PropTypes from 'prop-types';
import { Modal } from 'react-bootstrap';
import ReactTable from 'react-table';

class Mark extends Component {
    constructor( props ) { 
        super( props );

        this.state = {
            data: {},
            allSelected: false,
        }
        
        this.handleTHeadCheckboxSelection = this.handleTHeadCheckboxSelection.bind(this);
        this.handleRowSelection = this.handleRowSelection.bind(this);
        this.handleCheckboxSelection = this.handleCheckboxSelection.bind(this);
    }

    componentWillMount() {
        this.mounted = true;
        
        const data = [
            {
                type: 'event',
                id: 123,
                subject: 'event subject 1',
                selected: false,
            },
            {
                type: 'event',
                id: 456,
                subject: 'event subject 2',
                selected: true,
            },
            {
                type: 'entry',
                id: 1000,
                subject: 'entry body 120 characters',
                selected: false,
            },
            {
                type: 'entry',
                id: 2000,
                subject: 'entry body 120 characters including this text to make it intentionally longer for test purposes 1234125312312312312112 12',
                selected: false,
            },
        ]

        this.setState({ data: data });
    }

    componentWillUnmount() {
        this.mounted = false;
    }
    
    render() {

        const columns = [
        {
                Header: cell => {
                    return (
                        <div>
                            <div className='mark-checkbox'><i className={`fa fa${this.state.allSelected ? '-check' : '' }-square-o`} aria-hidden="true"></i></div>
                             
                        </div>
                    )
                },
                id: 'selected',
                accessor: d => d.selected,
                Cell: row => {
                    return ( 
                        <div>
                            <div className='mark-checkbox'><i className={`fa fa${row.row.selected ? '-check' : '' }-square-o`} aria-hidden="true"></i></div>
                        </div>
                    )
                },
                maxWidth: 100,
            },
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
            <Modal dialogClassName='mark-modal' show={ this.props.modalActive } onHide={ this.props.markModalToggle }>
                <Modal.Header closeButton={ true } >
                    <Modal.Title>
                        Items Marked
                    </Modal.Title>
                </Modal.Header>
                <Modal.Body>
                    <ReactTable 
                        columns = { columns } 
                        data = { this.state.data } 
                        defaultPageSize = { 10 }
                        getTdProps = { this.handleCheckboxSelection }
                        getTheadThProps = { this.handleTHeadCheckboxSelection }
                        getTrProps = { this.handleRowSelection }
                        minRows = { 0 }
                    />
                </Modal.Body>
                <Modal.Footer>
                    Buttons go here
                </Modal.Footer>
            </Modal>
        )
    }
    
    handleRowSelection( state, rowInfo, column ) {
        return {
            onClick: event => {
                let data = this.state.data;
                
                for (let row of data ) { 
                    if ( rowInfo.row.id != row.id) {
                        row.selected =  false;
                    } else {
                        row.selected = true;
                    }
                }

                this.setState({data: data, allSelected: false});
                return;
            },
            style: {
                background: rowInfo != undefined ? rowInfo.row.selected ? 'rgb(174, 218, 255)' : null : null,
            }
        }
    }

    handleCheckboxSelection( state, rowInfo, column ) {
        if ( column.id == 'selected' ) {
            return {
                onClick: event => {
                    var data = this.state.data;
                    
                    for ( let row of data ) { 
                        if ( rowInfo.row.id == row.id ) {
                            row.selected = !row.selected
                            break;
                        }
                    }
                    
                    this.setState({data: data, allSelected: this.checkAllSelected(data) });
                    event.stopPropagation();
                    return;
                } 
            }
        } else {
            return {};
        }
    }

    handleTHeadCheckboxSelection( state, rowInfo, column, instance ) {
        if ( column.id === 'selected' ) {
            return {
                onClick: event => {
                    let data = this.state.data;
                    let allSelected = !this.state.allSelected;
                    
                    for ( let row of data ) {
                        row.selected = allSelected;
                    }

                    this.setState({data: data, allSelected: allSelected});
                    return; 
                }
            }
        } else {
            return {};
        }
    }

    checkAllSelected( data ) {
        for ( let row of data ) {
            if ( !row.selected ) {
                return false; 
            }   
        }
        return true;
    }
}

Mark.propTypes = {
    modalActive: PropTypes.bool
}

Mark.defaultProps = {
    modalActive: true
}

export default Mark;
