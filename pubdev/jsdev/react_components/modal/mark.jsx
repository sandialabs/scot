import React, { PureComponent, Component } from 'react';
import PropTypes from 'prop-types';
import { Modal, Button, ButtonGroup, Panel, FormControl, Form, Col } from 'react-bootstrap';
import ReactTable from 'react-table';
import { removeMarkedItems } from '../components/marker';

const ACTION_BUTTONS = {
	READY: {
		style: "default",
	},
	LOADING: {
		text: "Processing...",
		style: "default",
		disabled: true,
	},
	SUCCESS: {
		text: "Success!",
		style: "success",
	},
	ERROR: {
		text: "Error!",
		style: "danger",
	},
};

class Mark extends Component {
    constructor( props ) { 
        super( props );

        this.state = {
            data: [],
            allSelected: false,
        }
        
        this.handleTHeadCheckboxSelection = this.handleTHeadCheckboxSelection.bind(this);
        this.handleRowSelection = this.handleRowSelection.bind(this);
        this.handleCheckboxSelection = this.handleCheckboxSelection.bind(this);
        this.getMarkedItems = this.getMarkedItems.bind(this);
    }

    componentWillMount() {
        this.mounted = true;
        
        this.getMarkedItems();
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
                filterable: false,
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
                        Marked Objects
                    </Modal.Title>
                </Modal.Header>
                <Modal.Body>
                    { this.state.data.length > 0 ?
                        <ReactTable 
                            columns = { columns } 
                            data = { this.state.data } 
                            defaultPageSize = { 10 }
                            getTdProps = { this.handleCheckboxSelection }
                            getTheadThProps = { this.handleTHeadCheckboxSelection }
                            getTrProps = { this.handleRowSelection }
                            minRows = { 0 }
                            noDataText= 'No items marked.'
                            style={{
                                maxHeight: "60vh"
                            }}
                            filterable
                        />
                    :
                        <h3>No marked items detected.</h3>
                    }
                </Modal.Body>
                <Modal.Footer>
                    <Actions data={this.state.data} id={this.props.id} type={this.props.type} getMarkedItems={this.getMarkedItems} errorToggle={this.props.errorToggle} />
                </Modal.Footer>
            </Modal>
        )
    }
    
    handleRowSelection( state, rowInfo, column ) {
        return {
            onClick: event => {
                let data = this.state.data;
                
                for (let row of data ) { 
                    if ( rowInfo.row.id == row.id && rowInfo.row.type == row.type ) {
                        row.selected =  true;
                    } else {
                        row.selected = false;
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
                        if ( rowInfo.row.id == row.id && rowInfo.row.type == row.type ) {
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
                        for ( let pageRow of state.pageRows ) {
                            if ( row.id == pageRow.id && row.type == pageRow.type ) {                 //compare displayed rows to rows in dataset and only select those
                                row.selected = allSelected;
                                break;
                            }
                        }
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

    getMarkedItems () {
        let markedItems = getLocalStorage( 'marked' );
        let currentItem = { id: this.props.id, type: this.props.type, subject: this.props.string };

        if ( markedItems ) {
            markedItems = JSON.parse( markedItems );
            markedItems.unshift( currentItem );         //Add currently viewed item to the top of the list
            this.setState({ data: markedItems });
        } else {
            return; //return if no items are marked
        }
    
    }
}

class Actions extends Component {
    constructor( props ) {
        super( props );

        this.state = {
            entry: false,
            thing: false,
            actionSuccess: false,
            linkContextString: null,
            linkPanel: false,

			reparseButton: ACTION_BUTTONS.READY,
        }
        
        this.RemoveSelected = this.RemoveSelected.bind(this);
        this.MoveEntry = this.MoveEntry.bind(this);
        this.CopyEntry = this.CopyEntry.bind(this);
        this.EntryAjax = this.EntryAjax.bind(this);
        this.Link = this.Link.bind(this);
        this.LinkAjax = this.LinkAjax.bind(this);
		this.Reparse = this.Reparse.bind(this);
		this.ReparseAjax = this.ReparseAjax.bind(this);
        this.ToggleActionSuccess = this.ToggleActionSuccess.bind(this);
        this.ExpandLinkToggle = this.ExpandLinkToggle.bind(this);
        this.LinkContextChange = this.LinkContextChange.bind(this);
    }

    componentWillMount() {
        this.mounted = true;
    }

    componentWillUnmount() {
        this.mounted = false;
    }

    render() {
        let buttons = [];
        let entry = false;
        let thing = false;

        for ( let key of this.props.data ) {
            if ( key.type && key.selected ) {
                if ( key.type == 'entry' ) { 
                    entry = true;
                } else {
                    thing = true;
                }
            }
        }

		const reparseButton = this.state.reparseButton;
         
        return (
            <div>
                {this.state.actionSuccess ? 
                    <div>
                        <Button bsStyle='success' onClick={this.RemoveSelected}>Action Successful! Remove Mark?</Button>
                        <Button onClick={this.ToggleActionSuccess}>Keep Marked</Button>
                    </div>
                :
                    <div style={{ display: 'grid' }}>
                        <div>
                            { thing || entry ? <h4 style={{float: 'left'}}>Actions</h4> : <div> { this.props.data.length > 0 ? <h4 style={{float: 'left'}}>Select a Marked Object</h4> : null } </div> }
                            <ButtonGroup style={{float: 'right'}}>
                                {entry && !thing && this.props.type != 'alertgroup' ? <Button onClick={this.MoveEntry}>Move to {this.props.type} {this.props.id}</Button> : null }
                                {entry && !thing && this.props.type != 'alertgroup' ? <Button onClick={this.CopyEntry}>Copy to {this.props.type} {this.props.id}</Button> : null }
                                {thing || entry ? <Button onClick={this.ExpandLinkToggle} >Link to {this.props.type} {this.props.id}</Button> : null }
								{(thing || entry) && <Button bsStyle={reparseButton.style} onClick={this.Reparse} disabled={reparseButton.disabled} >{reparseButton.text ? reparseButton.text : "Reparse Flair"}</Button> }
                                {thing || entry ? <Button bsStyle='danger' onClick={this.RemoveSelected} >Unmark</Button> : null }
                            </ButtonGroup>
                        </div>
                        { this.state.linkPanel && ( thing || entry ) ? 
                            <Panel collapsible expanded={this.state.linkPanel}>
                                <Form horizontal>
                                    <Col sm={2}>
                                        Provide context to this link:
                                    </Col>
                                    <Col sm={9}>
                                        <FormControl
                                            type="text"
                                            value={this.state.linkContextString}
                                            placeholder="optional"
                                            onChange={this.LinkContextChange}
                                        />
                                    </Col>
                                    <Col sm={1}>
                                        <Button onClick={this.Link} bsStyle={'success'}>Submit</Button>
                                    </Col>
                                </Form>
                            </Panel>
                        :
                            null
                        }
                    </div>                
                }   
            </div>
        )
    }
    
    LinkContextChange(e) {
        this.setState({ linkContextString: e.target.value });
    }

    ExpandLinkToggle( newState ) {
        if ( newState == true || newState == false ) {
            this.setState({ linkPanel: newState, linkContextString: '' });
        } else {
            let linkPanel = !this.state.linkPanel;
            this.setState({ linkPanel: linkPanel, linkContextString: '' });
        }
    }

    RemoveSelected() {
        for ( let key of this.props.data ) {
            if ( key.selected ) {
                removeMarkedItems( key.type, key.id );
            }
        }
        
        //update marked items after removal
        this.props.getMarkedItems();
        
        //turn off the action success buttons after removal
        if ( this.state.actionSuccess ) {
            this.setState({ actionSuccess: false });
        }
    }
    
    MoveEntry() {
        for (let key of this.props.data ) {
            if ( key.selected && key.type =='entry' ) {
                this.EntryAjax( key.id, true ); 
            }
        }
    }
    
    CopyEntry() {
        for (let key of this.props.data ) {
            if ( key.selected && key.type =='entry' ) {
                this.EntryAjax( key.id, false );
            }
        } 
    }

    Link() {


        for ( let key of this.props.data ) {
            if ( key.selected ) {

                let arrayToLink = [];
                let obj = {};
                let currentobj = {};

                //assign new thing to link
                obj.id = parseInt( key.id );
                obj.type = key.type;
                
                //assign current thing to link to
                currentobj.id = parseInt( this.props.id );
                currentobj.type = this.props.type;

                arrayToLink.push( obj );
                arrayToLink.push ( currentobj );
            
                this.LinkAjax( arrayToLink );
            }
            
            /*
                if ( arrayToLink.length > 0 ) {
                //add current thing to be linked to
                let obj = {};
                obj.id = parseInt( this.props.id );
                obj.type = this.props.type;

                arrayToLink.push( obj );
                this.LinkAjax( arrayToLink );
            }*/
        }

        
    }

	Reparse() {
		this.setState({
			reparseButton: ACTION_BUTTONS.LOADING,
		});

		$.when( ...this.props.data.filter( ( thing ) => thing.selected )
			.map( ( thing ) => {
				return this.ReparseAjax( thing );
			} )
		).then( () => {
			this.setState({
				reparseButton: ACTION_BUTTONS.SUCCESS,
			});
		}, ( error ) => {
			console.err( error );
			this.setState({
				reparseButton: ACTION_BUTTONS.ERROR,
			});
			this.props.errorToggle( 'error reparsing', error );
		} ).always( () => {
			setTimeout( () => {
				this.setState({
					reparseButton: ACTION_BUTTONS.READY,
				});
			}, 2000 );
		} );
	}

	ReparseAjax( thing ) {
        return $.ajax({
            type: 'put',
            url: '/scot/api/v2/'+ thing.type +'/'+ thing.id,
            data: JSON.stringify({parsed:0}),
            contentType: 'application/json; charset=UTF-8',
        });
	}

    LinkAjax( arrayToLink ) {
        let data = {};
        data.weight = 1; //passed in object
        data.vertices = arrayToLink; //link to current thing
        
        if ( this.state.linkContextString ) {           //add context string if one was submitted
            data.context = this.state.linkContextString
        }

        $.ajax({
            type: 'post',
            url: '/scot/api/v2/link',
            data: JSON.stringify( data ),
            contentType: 'application/json; charset=UTF-8',
            dataType: 'json',
            success: function( response ) {
                console.log( 'successfully linked' );
                this.ExpandLinkToggle(false);                          //disable link panel
                this.ToggleActionSuccess(true);
            }.bind(this),
            error: function( data ) {
                this.props.errorToggle( 'failed to link', data );
            }.bind(this)
        })
    }

    EntryAjax(id, removeOriginal) {
        
        $.ajax({
            type: 'get',
            url: '/scot/api/v2/entry/' + id,
            success: function( response ) {
                let data ={};
                data= {parent: 0, body: response.body, target_id: parseInt(this.props.id), target_type: this.props.type}; 
                $.ajax({
                    type: 'post',
                    url: '/scot/api/v2/entry',
                    data: JSON.stringify(data),
                    contentType: 'application/json; charset=UTF-8',
                    dataType: 'json',
                    success: function( response ) {
                        
                        if ( removeOriginal ) {
                            this.RemoveEntryAfterMove ( id );   
                            this.RemoveSelected();
                        } else {
                            if ( !this.state.actionSuccess ) {
                                this.ToggleActionSuccess(true);
                            }
                        }

                    }.bind(this),
                    error: function ( data ) {
                        this.props.errorToggle('failed to create new entry', data);
                    }.bind(this)
                })
            }.bind(this),
            error: function( data ) {
                this.props.errorToggle('failed to get entry data', data);
            }.bind(this)
        })
        
    }
    
    RemoveEntryAfterMove( id ) {
        $.ajax({
            type: 'delete',
            url: '/scot/api/v2/entry/' + id,
            success: function( response ) {
                console.log('removed original entry');
            }.bind(this),
            error: function( data ) {
                this.props.errorToggle('Failed to remove original entry', data);
            }.bind(this),
        });
    }

    ToggleActionSuccess(status) {
        
        if ( status == true || status == false ) {
            this.setState({ actionSuccess: status });
        } else {
            let newActionSuccess = !this.state.actionSuccess;
            this.setState({ actionSuccess: newActionSuccess });    
        }
        
    }
}

Actions.propTypes = {
    data: PropTypes.object
}

Actions.defaultProps = {
    data: {}
}

Mark.propTypes = {
    modalActive: PropTypes.bool
}

Mark.defaultProps = {
    modalActive: true
}

export default Mark;
