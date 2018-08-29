import React, { PureComponent } from "react";
import Modal from "react-modal";
import { Button } from "react-bootstrap";
import PropTypes from "prop-types";
import $ from "jquery";

const customStyles = {
  content: {
    top: "50%",
    left: "50%",
    right: "auto",
    bottom: "auto",
    marginRight: "-50%",
    transform: "translate(-50%, -50%)"
  },
  overlay: {
    zIndex: "1101"
  }
};

const ACTION_BUTTONS = {
  READY: {
    style: "danger"
  },
  LOADING: {
    text: "Processing...",
    style: "default",
    disabled: true
  },
  SUCCESS: {
    text: "Success!",
    style: "success"
  },
  ERROR: {
    text: "Error!",
    style: "warning"
  }
};

export class DeleteEvent extends PureComponent {
  constructor(props) {
    super(props);

    this.state = {
      key: props.id
    };

    this.toggle = this.toggle.bind(this);
  }

  toggle() {
    $.ajax({
      type: "delete",
      url: "scot/api/v2/" + this.props.type + "/" + this.props.id,
      success: function(data) {
        console.log("success: " + data);
        this.props.deleteToggle(true);
      }.bind(this),
      error: function(data) {
        this.props.errorToggle("Failed to delete", data);
        this.props.deleteToggle();
      }.bind(this)
    });
    this.props.history.push("/" + this.props.type);
  }

  render() {
    return (
      <Modal
        isOpen={true}
        onRequestClose={this.props.deleteToggle}
        style={customStyles}
      >
        <div className="modal-header">
          <img
            alt=""
            src="images/close_toolbar.png"
            className="close_toolbar"
            onClick={this.props.deleteToggle}
          />
          <h3 id="myModalLabel">
            Are you sure you want to delete {this.props.subjectType}:{" "}
            {this.props.id}?
          </h3>
        </div>
        <div className="modal-footer">
          <Button id="cancel-delete" onClick={this.props.deleteToggle}>
            Cancel
          </Button>
          <Button bsStyle="danger" id="delete" onClick={this.toggle}>
            Delete
          </Button>
        </div>
      </Modal>
    );
  }
}

export class DeleteEntry extends PureComponent {
  constructor(props) {
    super(props);

    this.state = {
      key: props.id
    };

    this.toggle = this.toggle.bind(this);
  }

  toggle() {
    $.ajax({
      type: "delete",
      url: "scot/api/v2/entry/" + this.props.entryid,
      success: function(data) {
        console.log("success: " + data);
        let key = this.state.key;
      }.bind(this),
      error: function(data) {
        this.props.errorToggle("Failed to delete entry", data);
      }.bind(this)
    });
    this.props.deleteToggle();
  }

  render() {
    return (
      <Modal
        isOpen={true}
        onRequestClose={this.props.deleteToggle}
        style={customStyles}
      >
        <div className="modal-header">
          <img
            alt=""
            src="images/close_toolbar.png"
            className="close_toolbar"
            onClick={this.props.deleteToggle}
          />
          <h3 id="myModalLabel">
            Are you sure you want to delete Entry: {this.props.entryid}?
          </h3>
        </div>
        <div className="modal-footer">
          <Button id="cancel-delete" onClick={this.props.deleteToggle}>
            Cancel
          </Button>
          <Button bsStyle="danger" id="delete" onClick={this.toggle}>
            Delete
          </Button>
        </div>
      </Modal>
    );
  }
}

// The type signature for things to be deleted
const thingType = PropTypes.shape({
  type: PropTypes.string.isRequired,
  id: PropTypes.oneOfType([PropTypes.number, PropTypes.string]).isRequired
});

export class DeleteModal extends PureComponent {
  constructor(props) {
    super(props);

    this.state = {
      deleteButton: ACTION_BUTTONS.READY
    };

    this.deleteAll = this.deleteAll.bind(this);
  }

  static propTypes = {
    things: PropTypes.oneOfType([thingType, PropTypes.arrayOf(thingType)])
      .isRequired,
    errorToggle: PropTypes.func.isRequired,
    callback: PropTypes.func.isRequired
  };

  deleteAll() {
    this.setState({
      deleteButton: ACTION_BUTTONS.LOADING
    });

    let success = true;

    let { things } = this.props;
    if (!Array.isArray(things)) {
      things = [things];
    }

    $.when(...things.map(thing => this.deleteAjax(thing)))
      .then(
        // Success
        () => {
          this.setState({
            deleteButton: ACTION_BUTTONS.SUCCESS
          });
        },
        // Failure
        error => {
          console.error(error);
          this.setState({
            deleteButton: ACTION_BUTTONS.ERROR
          });
          this.props.errorToggle("error deleting", error);
          success = false;
        }
      )
      .always(() => {
        setTimeout(() => {
          this.setState({
            deleteButton: ACTION_BUTTONS.READY
          });

          this.props.callback(success);
        }, 2000);
      });
  }

  deleteAjax(thing) {
    return $.ajax({
      type: "delete",
      url: "/scot/api/v2/" + thing.type + "/" + thing.id,
      contentType: "application/json; charset=UTF-8"
    });
  }

  render() {
    let { things } = this.props;
    let confirmText = "";

    if (Array.isArray(things)) {
      confirmText = things
        .map(thing => `${thing.type}: ${thing.id}`)
        .join(", ");
    } else {
      confirmText = `${things.type}: ${things.id}`;
    }

    const { deleteButton } = this.state;

    return (
      <Modal
        isOpen={true}
        onRequestClose={this.props.callback}
        style={customStyles}
      >
        <div className="modal-header">
          <img
            alt=""
            src="images/close_toolbar.png"
            className="close_toolbar"
            onClick={this.props.callback}
          />
          <h3 id="myModalLabel">
            Are you sure you want to delete {confirmText}?
          </h3>
        </div>
        <div className="modal-footer">
          <Button id="cancel-delete" onClick={this.props.callback}>
            Cancel
          </Button>
          <Button
            bsStyle={deleteButton.style}
            id="delete"
            onClick={this.deleteAll}
            disabled={deleteButton.disabled}
          >
            {deleteButton.text ? deleteButton.text : "Delete"}
          </Button>
        </div>
      </Modal>
    );
  }
}
