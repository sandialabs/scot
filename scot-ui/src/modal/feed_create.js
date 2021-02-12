import React, { Component } from "react";
import { Modal, Button } from "react-bootstrap";
import $ from "jquery";
import AutoCompleteInput from "../components/autocomplete_input.js";

class FeedCreateModal extends Component {
  constructor(props) {
    super(props);

    this.state = {
      name: "",
      uri: "",
      status: "active",
      type: "rss",
    };
  }

  componentWillMount() {
    if (this.props.match) {
      this.setState({ match: this.props.match });
    }

    this.mounted = true;
  }

  componentDidMount() {
  }

  componentWillUnmount() {
    $(document).unbind("keypress");
    this.mounted = false;
  }

  Confirmation = () => {
    if (this.state.confirmation === false) {
      this.GetCount();
      this.setState({ confirmation: true });
    } else {
      this.setState({ confirmation: false, value: "" });
    }
  }

  Submit = () => {
    let json = {
      name: this.state.name,
      uri: this.state.uri,
      status: "active",
      type: this.state.type
    };
    $.ajax({
      type: "POST",
      url: "/scot/api/v2/feed",
      data: JSON.stringify(json),
      contentType: "application/json; charset=UTF-8",
      success: function (data) {
        console.log("success: " + data);
        this.props.ToggleCreateEntity();
      }.bind(this),
      error: function (data) {
        if (data.responseJSON.error_msg) {
          this.props.errorToggle(
            "failed to create user defined entity: error_message: " +
            data.responseJSON.error_msg,
            data
          );
        } else {
          this.props.errorToggle("failed to create user defined feed", data);
        }
      }.bind(this)
    });
  }

  OnChangeMatch = (e) => {
    this.setState({ match: e.target.value });
    this.HasSpacesCheck(e.target.value);
  }

  OnChangeValue = (e) => {
    this.setState({ value: e });
  }

  render() {
    return (
      <Modal
        dialogClassName="feed-create-modal"
        show={this.props.modalActive}
        onHide={this.props.ToggleCreateEntity}
      >
        <Modal.Header closeButton={true}>
          <Modal.Title>
            {!this.state.confirmation ? (
              <span>Create a user defined feed</span>
            ) : (
                <span>Confirm and submit user defined feed</span>
              )}
          </Modal.Title>
        </Modal.Header>
        <Modal.Body>
          {!this.state.confirmation ? (
            <span>
              <span style={{ display: "flex" }}>
                <span style={{ width: "150px" }}>
                  <b>New Feed Name:</b>
                </span>
                <span style={{ width: "300px" }}>
                  <input
                    type={"input"}
                    value={this.state.name}
                    style={{ width: "100%" }}
                  />
                </span>
              </span>
              <span style={{ display: "flex" }}>
                <span style={{ width: "150px" }}>
                  <b>Feed URI:</b>
                </span>
                <span>
                  <input 
                   type={"input"}
                   value={this.state.uri}
                   style={{width:"100%"}}
                  />
                </span>
              </span>
            </span>
          ) : (
              <span>
                <div>
                  Entity Name: <b>{this.state.name}</b>
                </div>
                <div>
                  Entity Type: <b>{this.state.uri}</b>
                </div>
              </span>
            )}
        </Modal.Body>
        <Modal.Footer>
          {!this.state.confirmation ? (
            <span>
              {this.state.value.length >= 1 && this.state.match.length >= 1 ? (
                <Button
                  onClick={this.Confirmation}
                  bsStyle={"primary"}
                  type={"submit"}
                  active={true}
                >
                  Continue
                </Button>
              ) : null}
              <Button onClick={this.props.ToggleCreateEntity}>Cancel</Button>
            </span>
          ) : (
              <span>
                <span style={{ color: "red", float: "left" }}>
                  {this.state.countLoading ? (
                    <span>Count: is loading...</span>
                  ) : (
                      <span>Count: {this.state.count}</span>
                    )}
                </span>
                <span>
                  <Button onClick={this.Submit} bsStyle={"success"}>
                    Submit
                </Button>
                  <Button onClick={this.Confirmation}>Go Back</Button>
                </span>
              </span>
            )}
        </Modal.Footer>
      </Modal>
    );
  }
}

export default FeedCreateModal;
