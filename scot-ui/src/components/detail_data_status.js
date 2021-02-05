import React from "react";
import $ from "jquery";
let ButtonToolbar = require("react-bootstrap/lib/ButtonToolbar");
let OverlayTrigger = require("react-bootstrap/lib/OverlayTrigger");
let MenuItem = require("react-bootstrap/lib/MenuItem");
let DropdownButton = require("react-bootstrap/lib/DropdownButton");
let Popover = require("react-bootstrap/lib/Popover");
let Link = require("react-router-dom").Link;

export default class DetailDataStatus extends React.Component {
  componentDidMount = () => {
    //Adds open/close hot keys for alertgroup
    if (this.props.type === "alertgroup") {
      $("#list-view").keydown(
        function(event) {
          //prevent from working when in input
          if ($("input").is(":focus")) {
            return;
          }
          //check for character "o" for 79 or "c" for 67
          if (this.props.status !== "promoted") {
            if (
              event.keyCode === 79 &&
              (event.ctrlKey !== true && event.metaKey !== true)
            ) {
              this.statusAjax("open");
            } else if (
              event.keyCode === 67 &&
              (event.ctrlKey !== true && event.metaKey !== true)
            ) {
              this.statusAjax("closed");
            }
          }
        }.bind(this)
      );
    }
  };

  componentWillUnmount = () => {
    $("#list-view").unbind("keydown");
  };

  /*eventStatusToggle: function () {
        if (this.props.status == 'open') {
            this.statusAjax('closed');
        } else if (this.props.status == 'closed') {
            this.statusAjax('open');
        }
    },*/
  trackAll = () => {
    this.statusAjax("tracked");
  };

  untrackAll = () => {
    this.statusAjax("untracked");
  };

  closeAll = () => {
    this.statusAjax("closed");
  };

  openAll = () => {
    this.statusAjax("open");
  };

  enableAll = () => {
    this.statusAjax("enabled");
  };

  disableAll = () => {
    this.statusAjax("disabled");
  };

  statusAjax = newStatus => {
    console.log(newStatus);
    let json = { status: newStatus };
    $.ajax({
      type: "put",
      url: "scot/api/v2/" + this.props.type + "/" + this.props.id,
      data: JSON.stringify(json),
      contentType: "application/json; charset=UTF-8",
      success: function(data) {
        console.log("success status change to: " + data);
      },
      error: function(data) {
        this.props.errorToggle("Failed to change status", data);
      }.bind(this)
    });
  };

  render = () => {
    let buttonStyle = "";
    let open = "";
    let closed = "";
    let promoted = "";
    let title = "";
    let classStatus = "";
    let href;
    if (
      this.props.status === "open" ||
      this.props.status === "disabled" ||
      this.props.status === "untracked"
    ) {
      buttonStyle = "danger";
      classStatus = "alertgroup_open";
    } else if (
      this.props.status === "closed" ||
      this.props.status === "enabled" ||
      this.props.status === "tracked"
    ) {
      buttonStyle = "success";
      classStatus = "alertgroup_closed";
    } else if (this.props.status === "promoted") {
      buttonStyle = "default";
      classStatus = "alertgroup_promoted";
    }

    if (this.props.type === "alertgroup") {
      open = this.props.data.open_count;
      closed = this.props.data.closed_count;
      promoted = this.props.data.promoted_count;
      title = open + " / " + closed + " / " + promoted;
    }

    if (this.props.type === "event") {
      href = "/incident/" + this.props.data.promotion_id;
    } else if (this.props.type === "intel") {
      href = "/product/" + this.props.data.promotion_id;
    } else if (this.props.type === "dispatch") {
      href = "/intel/" + this.props.data.promotion_id;
    } 

    if (this.props.type === "guide" ) { //|| this.props.type === "intel") {
      return <div />;
    } else if (this.props.type === "alertgroup") {
      return (
        <ButtonToolbar>
          <OverlayTrigger
            placement="top"
            overlay={
              <Popover id={this.props.id}>open/closed/promoted alerts</Popover>
            }
          >
            <DropdownButton
              bsSize="xsmall"
              bsStyle={buttonStyle}
              title={title}
              id="dropdown"
              className={classStatus}
            >
              <MenuItem eventKey="1" onClick={this.openAll} bsSize="xsmall">
                <b>Open</b> All Alerts
              </MenuItem>
              <MenuItem eventKey="2" onClick={this.closeAll}>
                <b>Close</b> All Alerts
              </MenuItem>
            </DropdownButton>
          </OverlayTrigger>
        </ButtonToolbar>
      );
    } else if (this.props.type === "incident") {
      return (
        <DropdownButton
          bsSize="xsmall"
          bsStyle={buttonStyle}
          id="event_status"
          className={classStatus}
          style={{ fontSize: "14px" }}
          title={this.props.status}
        >
          <MenuItem eventKey="1" onClick={this.openAll}>
            Open Incident
          </MenuItem>
          <MenuItem eventKey="2" onClick={this.closeAll}>
            Close Incident
          </MenuItem>
        </DropdownButton>
      );
    } else if (this.props.type === "signature") {
      return (
        <DropdownButton
          bsSize="xsmall"
          bsStyle={buttonStyle}
          id="event_status"
          className={classStatus}
          style={{ fontSize: "14px" }}
          title={this.props.status}
        >
          <MenuItem eventKey="1" onClick={this.enableAll}>
            Enable Signature
          </MenuItem>
          <MenuItem eventKey="2" onClick={this.disableAll}>
            Disable Signature
          </MenuItem>
        </DropdownButton>
      );
    } else if (this.props.type === "entity") {
      return (
        <DropdownButton
          bsSize="xsmall"
          bsStyle={buttonStyle}
          id="event_status"
          className={classStatus}
          style={{ fontSize: "14px" }}
          title={this.props.status}
        >
          <MenuItem eventKey="1" onClick={this.trackAll}>
            Track
          </MenuItem>
          <MenuItem eventKey="2" onClick={this.untrackAll}>
            Untracked
          </MenuItem>
        </DropdownButton>
      );
    } else {
      return (
        <div>
          {this.props.status === "promoted" ? (
            <Link to={href} role="button" className={"btn btn-warning"}>
              {this.props.status}
            </Link>
          ) : (
            <DropdownButton
              bsSize="xsmall"
              bsStyle={buttonStyle}
              id="event_status"
              className={classStatus}
              style={{ fontSize: "14px" }}
              title={this.props.status}
            >
              <MenuItem eventKey="1" onClick={this.openAll}>
                Open
              </MenuItem>
              <MenuItem eventKey="2" onClick={this.closeAll}>
                Close
              </MenuItem>
            </DropdownButton>
          )}
        </div>
      );
    }
  };
}
