import React, { PureComponent, Component } from 'react';
import PropTypes from 'prop-types';
import { Modal } from 'react-bootstrap';
import ReactTable from 'react-table';

class Mark extends Component {
    constructor( props ) { 
        super( props );

        this.state = {
            selected: {},
            displayed: {},
            data: {},
        }
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
                Header: 'Selected',
                id: 'selected',
                accessor: d => d.selected,
                Cell: row => {
                    return ( 
                        <div>
                            { row.row.selected ?
                                <div className='mark-checkbox'><i className="fa fa-check-square-o" aria-hidden="true"></i></div>
                            :
                                <div className='mark-checkbox'><i className="fa fa-square-o" aria-hidden="true"></i></div>
                            }
                        </div>
                    )
                },
                maxWidth: 100,
            },
            {
                Header: 'Type',
                accessor: 'type',
                maxWidth: 150,
            },
            {   Header: 'ID',
                accessor: 'id',
                maxWidth: 100,
            },
            {   Header: 'Subject',
                accessor: 'subject',
                maxWidth: '100%',
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
                        columns={ columns } 
                        data={ this.state.data } 
                        defaultPageSize = { 10 }
                        getTdProps= { this.handleCheckboxSelection() }
                    />
                </Modal.Body>
                <Modal.Footer>
                    Buttons go here
                </Modal.Footer>
            </Modal>
        )
    }
    
    handleRowSelection( ) {
        return ( state, rowInfo, column ) => {
            return {
                onClick: event => {
                    var data = this.state.data;
                    for (let i=0; i < this.state.data.length; i++) { 
                        if ( rowInfo.row.id != data[i].id) {
                            data[i].selected =  false;
                        } else {
                            data[i].selected = true;
                        }
                    }
                    this.setState({data: data});
                    return;
                },
                style: {
                    background: rowInfo != undefined ? rowInfo.row.selected ? 'rgb(174, 218, 255)' : null : null,
                }
            }
        }
    }

    handleCheckboxSelection( ) {
        return ( state, rowInfo, column ) => {
            return {
                onClick: event => {
                    var data = this.state.data;
                    if ( column.id == 'selected' ) {  //selects the row without removing other row selections
                        for ( let i=0; i < this.state.data.length; i++ ) { 
                            if ( rowInfo.row.id == data[i].id ) {
                                if ( rowInfo.row.selected == true ) {
                                    data[i].selected = false;
                                } else {
                                    data[i].selected = true;
                                }
                            }
                        }
                    } else {   //selects the row and removes other row selections
                        for ( let i=0; i < this.state.data.length; i++ ) {
                            if ( rowInfo.row.id != data[i].id) {
                                data[i].selected =  false;
                            } else {
                                data[i].selected = true;
                            }
                        }
                    }
                    this.setState({data: data});
                    return;
                },
                style: {
                    background: rowInfo != undefined ? rowInfo.row.selected ? 'rgb(174, 218, 255)' : null : null,
                }
            }
        }
    }
    
}

Mark.propTypes = {
    modalActive: PropTypes.bool
}

Mark.defaultProps = {
    modalActive: true
}

export default Mark;
