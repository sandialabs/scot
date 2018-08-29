import $ from "react";
import React, { Component } from "react";
import { Modal } from "react-bootstrap";
import AddEntry from "../components/add_entry.js";

export default class ExportModal extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      showEditor: false,
      data: null,
      responseSuccess: false,
      emailField: []
    };
  }

  componentWillMount = () => {
    this.getData();
  };

  onBlur = event => {
    let v = event.target.value;
    if (v === "") {
      return;
    }
    let emailArray = v.split(/[ ,]+/);
    this.setState({ emailField: emailArray });
  };

  getData = () => {
    $.ajax({
      type: "get",
      url: "/scot/api/v2/prepexport/" + this.props.type + "/" + this.props.id,
      success: function(response) {
        this.setState({ data: response });
        this.setState({ leaveCatch: false, showEditor: true });
      }.bind(this),
      error: function(response) {
        this.props.errorToggle(
          "Failed to get export data from server!",
          response
        );
      }.bind(this)
    });
  };

  exportResponse = response => {
    if (response === "success") {
      this.setState({ showEditor: false, responseSuccess: true });
    }
  };

  render() {
    let disabled = false;
    if (this.state.responseSuccess) {
      disabled = true;
    }
    return (
      <div>
        <Modal
          dialogClassName="links-modal"
          show={true}
          onHide={this.props.exportToggle}
        >
          <Modal.Header closeButton={true}>
            <Modal.Title>
              Export {this.props.type} {this.props.id}
            </Modal.Title>
          </Modal.Header>
          <Modal.Body>
            <div>
              <label htmlFor="exampleInputEmail1">Email addresses</label>
              <input
                type="email"
                className="form-control"
                id="email"
                aria-describedby="emailHelp"
                onBlur={this.onBlur}
                placeholder="Enter emails (comma-separated)"
                disabled={disabled}
              />
            </div>
            <br />
            {this.state.showEditor ? (
              <AddEntry
                entryAction={"Export"}
                exportResponse={this.exportResponse}
                type={this.props.type}
                targetid={this.props.id}
                id={"add_entry"}
                recipients={this.state.emailField}
                addedentry={this.entryToggle}
                content={this.state.data}
                errorToggle={this.props.errorToggle}
              />
            ) : null}
            {!this.state.showEditor && this.state.responseSuccess ? (
              <PostResponse />
            ) : null}
            {!this.state.showEditor && !this.state.responseSuccess ? (
              <i className="fa fa-spinner fa-spin fa-2x" aria-hidden="true" />
            ) : null}
          </Modal.Body>
        </Modal>
      </div>
    );
  }
}

class PostResponse extends Component {
  render() {
    return (
      <div>
        <i
          className="fa fa-check"
          aria-hidden="true"
          style={{ color: "green" }}
        />{" "}
        Export Successful!
      </div>
    );
  }
}
