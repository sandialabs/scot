import React, { PureComponent, Component } from 'react';
import PropTypes from 'prop-types';
import { Modal, Button } from 'react-bootstrap';
import Actions from '../activemq/actions';

class Login extends Component {
    constructor( props ) { 
        super( props );

        this.state = {
            user: '',
            pass: '',
        }
        this.SSO = this.SSO.bind(this);
        this.NormalAuth = this.NormalAuth.bind(this);
        this.Reset = this.Reset.bind(this);
        this.isEnterPressed = this.isEnterPressed.bind(this);
    }

    componentWillMount() {
        this.mounted = true;
    }

    componentWillUnmount() {
        this.mounted = false;
    }
    
    render() {
        let origurl = this.props.origurl;
        let url = '/sso?orig_url=/#' + origurl;
        return (
            <Modal dialogClassName='login-modal' show={ this.props.modalActive }>
                <Modal.Header >
                    <Modal.Title style={{textAlign: 'center'}}>
                        <h1> SCOT Login </h1>
                    </Modal.Title>
                </Modal.Header>
                <Modal.Body style={{textAlign: 'center'}}>
                    {/*<img src='/images/scot_logo_473x473.png' alt='SCOT Logo' />*/}
                    <img class="profile-img" src="/images/scot_logo_473x473.pn" alt='SCOT Logo' />
                    <Button type='submit' href={url}>Sign in using SSO</Button>
                    <br />
                    <br />
                    <div>
                        {/*<input id='user' type='user' ref='user' defaultValue=''  />*/}
                        <input type="user" id='user' class="form-control" placeholder="Login" required autofocus/>
                    </div>
                    <div>
                        <input id='pass' type='password' ref='pass' defaultValue='' onKeyPress={this.isEnterPressed}  />
                        <input type="password" class="form-control" id='pass' ref='pass' placeholder="Password" onKeyPress={this.isEnterPressed} />
                    </div>
                    {/*<input type='submit' onClick={this.NormalAuth} />*/}
                    <button class="btn btn-lg btn-primary btn-block" type="submit" onClick={this.NormalAuth}>
                        Sign in
                    </button>
                    <input type='reset' onClick={this.Reset} />
                    <br />
                </Modal.Body>
            </Modal>
        )
    }
    
    isEnterPressed(e) {
        if ( e.key == 'Enter' ) {
            this.NormalAuth();
        }
    }

    Reset() {
       this.refs.user.value == '';
       this.refs.pass.value == '';
    }

    SSO() {
        let data = {};
        data['orig_url'] = '%2f';
        $.ajax({
            type: 'get',
            url: 'sso',
            crossDomain: true,
            data: data,
            success: function(data) {
                console.log('success logging in');
                Actions.restartClient();                //restart the amq client after successful login
                this.props.WhoAmIQuery();              //get new whoami after successful login
                this.props.GetHandler();                //get new handler after succesful login
                this.props.loginToggle( null, true );
            }.bind(this),
            error: function(data) {
                this.props.errorToggle('Failed to log in using SSO');
            }.bind(this),
        });
    }

    NormalAuth () {
        let data = {}
        data['user'] = this.refs.user.value;
        data['pass'] = this.refs.pass.value;
        data['csrf_token'] = this.props.csrf;

        $.ajax({
            type: 'post',
            url: 'auth',
            data: data,
            success: function() {
                console.log('success logging in');
                Actions.restartClient();                //restart the amq client after successful login
                this.props.WhoAmIQuery();              //get new whoami after successful login
                this.props.GetHandler();                //get new handler after succesful login
                this.props.loginToggle( null, true );
            }.bind(this),
            error: function(data) {
                if (data.responseText == 'Failed CSRF check') {
                    this.props.errorToggle('Failed to log in due to bad CSRF token. Please reload the page and then log in. Error: ' + data.responseText);
                } else {
                    this.props.errorToggle('Failed to log in using normal auth: ' + data.responseText);
                }
            }.bind(this),
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
