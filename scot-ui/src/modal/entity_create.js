import React, { Component } from "react";
import { Modal, Button } from "react-bootstrap";
import $ from "jquery";
//import TagInput from '../components/TagInput';
import AutoCompleteInput from "../components/autocomplete_input.js";

class EntityCreateModal extends Component {
  constructor(props) {
    super(props);

    this.state = {
      value: "",
      match: "",
      userdef: true,
      status: "tracked",
      multiword: "yes",
      confirmation: false,
      countLoading: false
    };

    this.Submit = this.Submit.bind(this);
    this.HasSpacesCheck = this.HasSpacesCheck.bind(this);
    this.Confirmation = this.Confirmation.bind(this);
    this.OnChangeValue = this.OnChangeValue.bind(this);
    this.OnChangeMatch = this.OnChangeMatch.bind(this);
  }

  componentWillMount() {
    if (this.props.match) {
      this.setState({ match: this.props.match });
    }

    this.mounted = true;
  }

  componentDidMount() {
    $(document)
      .keypress(
        function(event) {
          if ($("input").is(":focus")) {
            return;
          }

          if (
            event.keyCode === 13 &&
            this.state.match.length >= 1 &&
            this.state.value >= 1
          ) {
            if (this.state.confirmation === false) {
              this.Confirmation();
            } else {
              this.Submit();
            }
          }
          return;
        }.bind(this)
      )
      .bind(this);

    this.HasSpacesCheck(this.props.match);
  }

  componentWillUnmount() {
    $(document).unbind("keypress");
    this.mounted = false;
  }

  HasSpacesCheck(match) {
    if (/\s/g.test(match) === true) {
      this.setState({ multiword: "yes" });
    } else {
      this.setState({ multiword: "no" });
    }
  }

  GetCount() {
    this.setState({ countLoading: true });
    let match = encodeURIComponent(this.state.match);
    $.ajax({
      type: "get",
      url: "/scot/api/v2/hitsearch?match=" + match,
      success: function(data) {
        this.setState({ count: data.count, countLoading: false });
      }.bind(this),
      error: function(data) {
        this.setState({ count: "unable to get count", countLoading: false });
      }.bind(this)
    });
  }

  Confirmation() {
    if (this.state.confirmation === false) {
      this.GetCount();
      this.setState({ confirmation: true });
    } else {
      this.setState({ confirmation: false, value: "" });
    }
  }

  Submit() {
    let json = {
      value: this.state.value,
      match: this.state.match,
      status: "active",
      options: { multiword: this.state.multiword }
    };
    $.ajax({
      type: "POST",
      url: "/scot/api/v2/entitytype",
      data: JSON.stringify(json),
      contentType: "application/json; charset=UTF-8",
      success: function(data) {
        console.log("success: " + data);
        this.props.ToggleCreateEntity();
      }.bind(this),
      error: function(data) {
        if (data.responseJSON.error_msg) {
          this.props.errorToggle(
            "failed to create user defined entity: error_message: " +
              data.responseJSON.error_msg,
            data
          );
        } else {
          this.props.errorToggle("failed to create user defined entity", data);
        }
      }.bind(this)
    });
  }

  OnChangeMatch(e) {
    this.setState({ match: e.target.value });
    this.HasSpacesCheck(e.target.value);
  }

  OnChangeValue(e) {
    this.setState({ value: e });
  }

  render() {
    return (
      <Modal
        dialogClassName="entity-create-modal"
        show={this.props.modalActive}
        onHide={this.props.ToggleCreateEntity}
      >
        <Modal.Header closeButton={true}>
          <Modal.Title>
            {!this.state.confirmation ? (
              <span>Create a user defined entity</span>
            ) : (
              <span>Confirm and submit user defined entity</span>
            )}
          </Modal.Title>
        </Modal.Header>
        <Modal.Body>
          {!this.state.confirmation ? (
            <span>
              <span style={{ display: "flex" }}>
                <span style={{ width: "150px" }}>
                  <b>New Entity Name:</b>
                </span>
                <span style={{ width: "300px" }}>
                  <input
                    type={"tag"}
                    onChange={this.OnChangeMatch}
                    value={this.state.match}
                    style={{ width: "100%" }}
                  />
                </span>
              </span>
              <span style={{ display: "flex" }}>
                <span style={{ width: "150px" }}>
                  <b>Entity Type:</b>
                </span>
                <span>
                  <AutoCompleteInput
                    type={"entitytype"}
                    OnChange={this.OnChangeValue}
                    value={this.state.value}
                  />
                </span>
              </span>
            </span>
          ) : (
            <span>
              <div>
                Entity Name: <b>{this.state.match}</b>
              </div>
              <div>
                Entity Type: <b>{this.state.value}</b>
              </div>
              <div>
                Multiword: <b>{this.state.multiword}</b>
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

export default EntityCreateModal;
