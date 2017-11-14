import React, { PureComponent, Component } from 'react';
import PropTypes from 'prop-types';
import { Modal, Button, ButtonGroup } from 'react-bootstrap';
import TagInput from '../components/TagInput';

class EntityCreateModal extends Component {
    constructor( props ) { 
        super( props );

        this.state = {
            value: '',
            match: '',
            userdef: true,
            status: 'tracked',
            multiword: 'yes', 
            confirmation: false,
        }
        
        this.Submit = this.Submit.bind(this);
        this.HasSpacesCheck = this.HasSpacesCheck.bind(this);
        this.Confirmation = this.Confirmation.bind(this);
        this.OnChange = this.OnChange.bind(this);
    }

    componentWillMount() {
        if (this.props.match) {
            this.setState({match: this.props.match});
        }
        
        this.mounted = true;
    }        
    
    componentDidMount() {
       $(document).keypress(function(event){
            if($('input').is(':focus')) {return}
            
            if (event.keyCode == 13) {
                if ( this.state.confirmation == false ) {
                    this.Confirmation();
                } else {
                    this.Submit();
                }
            }
            return
        }.bind(this)).bind(this) 
        
        this.HasSpacesCheck( this.props.match );
    }

    componentWillUnmount() {
        $(document).unbind('keypress')
        this.mounted = false;
    }
    
    HasSpacesCheck(match) {
        if ( /\s/g.test(match) == true ) {
            this.setState({multiword: 'yes'});   
        } else {
            this.setState({multiword: 'no'});
        }
    }

    Confirmation() {
        if ( this.state.confirmation == false ) {
            this.setState({confirmation: true});
        } else {
            this.setState({confirmation: false, value: '' }) 
        }
    }

    AddMatch() {
        this.setState({ match: 'match here'});
        this.HasSpacesCheck('match here');
    }

    Submit() {
        let json = {'value': this.state.value, 'match': this.state.match, 'status': 'active', 'options': { 'multiword': this.state.multiword }}
        $.ajax({
            type: 'POST',
            url: '/scot/api/v2/entitytype',
            data: JSON.stringify(json),
            contentType: 'application/json; charset=UTF-8',
            success: function(data) {
                console.log('success: ' + data);
                this.props.ToggleCreateEntity();            
            }.bind(this),
            error: function(data) {
                this.props.errorToggle('failed to create user defined entity', data);
            }.bind(this)
        })
    }
    
    OnChange(e) {
        if ( e[0] != undefined ) {
            this.setState({value: e[0].name});
        } else {
            this.setState({value: ''});
        }
    }
    
    render() {
        
        return (
            <Modal dialogClassName='entity-create-modal' show={ this.props.modalActive } onHide={ this.props.ToggleCreateEntity }>
                <Modal.Header closeButton={ true } >
                    <Modal.Title>
                        {!this.state.confirmation ? 
                            <span>Create a user defined entity</span> 
                        : 
                            <span>Confirm and submit user defined entity</span>
                        }
                    </Modal.Title>
                </Modal.Header>
                <Modal.Body>
                {!this.state.confirmation ?  
                    <span>
                        Entity Name: <b>{this.state.match}</b>
                        <br />
                        <span style={{display: 'flex'}}>
                            <span style={{minWidth: '75px'}}>   
                                Entity Type:
                            </span>
                            <TagInput type='userdef' onChange={this.OnChange} maxTags={1} errorToggle={this.props.errorToggle}/>
                        </span>    
                    </span>
                :
                    <span>
                        <div>Entity Name:  <b>{this.state.match}</b></div>
                        <div>Entity Type: <b>{this.state.value}</b></div>
                        <div>Multiword: <b>{this.state.multiword}</b></div>
                    </span>
                }
                </Modal.Body>
                <Modal.Footer>
                    {!this.state.confirmation ? 
                        <span>
                            {this.state.value.length >= 1 ? 
                                <Button onClick={this.Confirmation} bsStyle={'primary'} type={'submit'} active={true}>Continue</Button> 
                            :
                                null
                            }
                            <Button onClick={this.props.ToggleCreateEntity}>Cancel</Button>
                        </span>
                    : 
                        <span>
                            <div style={{color: 'red', textAlign: 'left'}}>
                                You are about to create a user defined entity which will flair all matches of this entity in SCOT. This WILL put a heavy load on the server. Verify your request above before submitting.
                            </div>
                            <div>
                                <Button onClick={this.Submit} bsStyle={'success'}>Submit</Button>
                                <Button onClick={this.Confirmation}>Go Back</Button>
                            </div>
                        </span>
                    }
                </Modal.Footer>
            </Modal>
        )
    }

}

export default EntityCreateModal;
