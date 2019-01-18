import React, { Component } from "react";
import PropTypes from "prop-types";
import { Modal, Button } from "react-bootstrap";
import $ from "jquery";
import ScotImage from "../images/scot_logo_473x473.png";

class Login extends Component {
  constructor(props) {
    super(props);

    this.state = {
      user: "",
      pass: ""
    };
    this.SSO = this.SSO.bind(this);
    this.NormalAuth = this.NormalAuth.bind(this);
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
    let url = "/sso?orig_url=/#" + origurl;
    return (
      <Modal dialogClassName="login-modal" show={this.props.modalActive}>
        <Modal.Header>
          <Modal.Title style={{ textAlign: "center" }}>SCOT Login</Modal.Title>
        </Modal.Header>
        <Modal.Body style={{ textAlign: "center" }}>
          <img src={ScotImage} alt="SCOT Logo" />
          <Button type="submit" href={url}>
            Sign in using SSO
          </Button>
          <br />
          <br />
          <div
            className="input-group"
            style={{
              marginBottom: "25px",
              marginRight: "100px",
              marginLeft: "100px"
            }}
          >
            <span className="input-group-addon">
              <i className="fa fa-user" />
            </span>
            <input
              id="user"
              type="user"
              ref="user"
              defaultValue=""
              className="form-control"
              placeholder="Username or Email"
            />
          </div>
          <div
            className="input-group"
            style={{
              marginBottom: "25px",
              marginRight: "100px",
              marginLeft: "100px"
            }}
          >
            <span className="input-group-addon">
              <i className="fa fa-lock" />
            </span>
            <input
              id="pass"
              type="password"
              ref="pass"
              defaultValue=""
              placeholder="Password"
              className="form-control"
              onKeyPress={this.isEnterPressed}
            />
          </div>
          <Button
            type="submit"
            className="btn btn-primary"
            onClick={this.NormalAuth}
            style={{ marginBottom: "25px", width: "140px" }}
          >
            Submit
          </Button>
          <br />
        </Modal.Body>
      </Modal>
    );
  }
  isEnterPressed(e) {
    if (e.key === "Enter") {
      this.NormalAuth();
    }
  }

  SSO() {
    let data = {};
    data["orig_url"] = "%2f";
    $.ajax({
      type: "get",
      url: "sso",
      crossDomain: true,
      data: data,
      success: function(data) {
        console.log("success logging in");
        //TODO: Run restart code
        // Actions.restartClient(); //restart the amq client after successful login
        this.props.WhoAmIQuery(); //get new whoami after successful login
        this.props.GetHandler(); //get new handler after succesful login
        this.props.loginToggle(null, true);
      }.bind(this),
      error: function(data) {
        this.props.errorToggle("Failed to log in using SSO");
      }.bind(this)
    });
  }

  NormalAuth() {
    let data = {};
    data["user"] = this.refs.user.value;
    data["pass"] = this.refs.pass.value;
    data["csrf_token"] = this.props.csrf;

    $.ajax({
      type: "post",
      url: "auth",
      data: data,
      success: function() {
        console.log("success logging in");
        //TODO: Implemtn restart script
        //Actions.restartClient(); //restart the amq client after successful login
        this.props.WhoAmIQuery(); //get new whoami after successful login
        this.props.GetHandler(); //get new handler after succesful login
        this.props.loginToggle(null, true);
      }.bind(this),
      error: function(data) {
        if (data.responseText === "Failed CSRF check") {
          this.props.errorToggle(
            "Failed to log in due to bad CSRF token. Please reload the page and then log in. Error: " +
              data.responseText
          );
        } else {
          this.props.errorToggle(
            "Failed to log in using normal auth: " + data.responseText
          );
        }
      }.bind(this)
    });
  }
}

Login.propTypes = {
  modalActive: PropTypes.bool
};

Login.defaultProps = {
  modalActive: true
};

export default Login;
