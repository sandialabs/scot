import React, { PureComponent, Component } from 'react';
import PropTypes from 'prop-types';
import { Modal } from 'react-bootstrap';

class Login extends Component {
    constructor( props ) { 
        super( props );

        this.state = {
            user: '',
            pass: '',
        }
        this.SSO = this.SSO.bind(this);
        this.NormalAuth = this.NormalAuth.bind(this);
        this.HandleInput = this.HandleInput.bind(this); 
        this.Reset = this.Reset.bind(this);
    }

    componentWillMount() {
        this.mounted = true;
    }

    componentWillUnmount() {
        this.mounted = false;
    }
    
    render() {

        return (
            <Modal dialogClassName='login-modal' show={ this.props.modalActive }> 
                <Modal.Header >
                    <Modal.Title style={{textAlign: 'center'}}>
                        <h1> SCOT Login </h1>
                    </Modal.Title>
                </Modal.Header>
                <Modal.Body style={{textAlign: 'center'}}>
                    <img src='/images/scot_logo_473x473.png' alt='SCOT Logo' />
                    <input type='submit' value='Sign in using SSO' onClick={this.SSO} />
                    <br />
                    <br />
                    <div>
                        <label>Username </label>
                        <input id='user' type='user' ref='user' onBlur={this.HandleInput} />
                    </div>
                    <div>
                        <label>Password </label>
                        <input id='pass' type='password' ref='pass' onBlur={this.HandleInput} />
                    </div>
                    <input type='submit' onClick={this.NormalAuth} />
                    <input type='reset' onClick={this.Reset} />
                    <br />
                </Modal.Body>
            </Modal>
        )
    }
     
    Reset() {
        this.refs.user.value = '';
        this.refs.pass.value = '';
    }

    HandleInput(e) {
        let key = e.target.id;
        let val = e.target.value;
        let obj = {};
        obj[key] = val;
        this.setState(obj);
    }

    SSO() {
        let data = {};
        data['orig_url'] = '%2f';
        $.ajax({
            type: 'get',
            url: 'sso',
            data: data,
            success: function(data) {
                console.log('success logging in');
                this.props.loginToggle( null, true );
            }.bind(this),
            error: function(data) {
                this.props.errorToggle('Failed to log in using SSO');
            },
        });
    }

    NormalAuth () {
        let data = {}
        data['user'] = this.state.user;
        data['pass'] = this.state.pass;
        data['csrf_token'] = this.props.csrf;

        $.ajax({
            type: 'post',
            url: 'auth',
            data: data,
            success: function() {
                console.log('success logging in');
                this.props.loginToggle( null, true );
            }.bind(this),
            error: function(data) {
                this.props.errorToggle('Failed to log in using normal auth');
            }
        });
    }
}

Login.propTypes = {
    modalActive: PropTypes.bool
}

Login.defaultProps = {
    modalActive: true
}

export default Login;
