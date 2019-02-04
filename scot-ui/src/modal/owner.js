import $ from "jquery";
import * as SessionStorage from "../utils/session_storage";
import React from "react";
import Modal from "react-modal";
import Button from "react-bootstrap/lib/Badge";
import DropdownButton from "react-bootstrap/lib/DropdownButton";
import MenuItem from "react-bootstrap/lib/MenuItem";

const customStyles = {
  content: {
    top: "50%",
    left: "50%",
    right: "auto",
    bottom: "auto",
    marginRight: "-50%",
    transform: "translate(-50%, -50%)"
  }
};

export default class Owner extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      currentOwner: this.props.data,
      whoami: undefined,
      ownerToolbar: false
    };
  }

  componentDidMount = () => {
    let whoami = SessionStorage.getSessionStorage("whoami");
    if (whoami) {
      this.setState({ whoami: whoami });
    }
  };

  componentWillReceiveProps = () => {
    this.setState({ currentOwner: this.props.data });
  };

  toggle = () => {
    if (this.state.whoami !== undefined) {
      let json = { owner: this.state.whoami };
      $.ajax({
        type: "put",
        url: "scot/api/v2/" + this.props.type + "/" + this.props.id,
        data: JSON.stringify(json),
        contentType: "application/json; charset=UTF-8",
        success: function(data) {},
        error: function(data) {
          this.props.errorToggle("Failed to change owner", data);
        }.bind(this)
      });
    } else {
      this.props.errorToggle("Failed to detect current user");
    }
    this.ownerToggle();
  };

  ownerToggle = () => {
    if (this.state.ownerToolbar === false) {
      this.setState({ ownerToolbar: true });
    } else {
      this.setState({ ownerToolbar: false });
    }
  };

  render = () => {
    return (
      <div>
        <DropdownButton
          bsSize="xsmall"
          id="event_owner"
          title={this.state.currentOwner}
        >
          <MenuItem eventKey="1" onClick={this.ownerToggle}>
            Take Ownership
          </MenuItem>
        </DropdownButton>
        {this.state.ownerToolbar ? (
          <Modal
            isOpen={true}
            onRequestClose={this.ownerToggle}
            style={customStyles}
          >
            <div className="modal-header">
              <img
                src="images/close_toolbar.png"
                alt=""
                className="close_toolbar"
                onClick={this.ownerToggle}
              />
              <h3 id="myModalLabel">Take Ownership</h3>
            </div>
            <div className="modal-body">
              Are you sure you want to take ownership of this event?
            </div>
            <div className="modal-footer">
              <Button id="cancel-ownership" onClick={this.ownerToggle}>
                Cancel
              </Button>
              <Button bsStyle="info" id="take-ownership" onClick={this.toggle}>
                Take Ownership
              </Button>
            </div>
          </Modal>
        ) : null}
      </div>
    );
  };
}
