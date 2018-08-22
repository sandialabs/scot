import React from "react";
import $ from "jquery";
let Button = require("react-bootstrap/lib/Button.js");

let Promote = React.createClass({
  getInitialState: function() {
    return {
      newURL: null,
      newType: null
    };
  },
  componentDidMount: function() {
    if (this.props.type == "alert") {
      this.setState({ newType: "Event" });
      this.setState({ newURL: "event" });
    } else if (this.props.type == "event") {
      this.setState({ newType: "Incident" });
      this.setState({ newURL: "incident" });
    }
  },
  promote: function() {
    let data = JSON.stringify({ promote: "new" });
    $.ajax({
      type: "put",
      url: "scot/api/v2/" + this.props.type + "/" + this.props.id,
      data: data,
      contentType: "application/json; charset=UTF-8",
      success: function(data) {
        console.log("successfully promoted");
        window.location.assign("#/" + this.state.newURL + "/" + data.pid);
      }.bind(this),
      error: function(data) {
        this.props.errorToggle("error", "Failed to promote", data);
      }.bind(this)
    });
  },
  render: function() {
    return (
      <Button
        bsStyle="warning"
        eventKey="1"
        bsSize="xsmall"
        onClick={this.promote}
      >
        <img src="/images/megaphone.png" />
        <span>Promote to {this.state.newType}</span>
      </Button>
    );
  }
});

module.exports = Promote;
