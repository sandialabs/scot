import React from "react";
import $ from "jquery";

let Summary = React.createClass({
  getInitialState: function() {
    return {
      key: this.props.id
    };
  },
  toggle: function() {
    let newClass;
    if (this.props.summary === 1) {
      newClass = "entry";
    } else if (this.props.summary === 0) {
      newClass = "summary";
    }
    let json = { class: newClass };
    $.ajax({
      type: "put",
      url: "scot/api/v2/entry/" + this.props.entryid,
      data: JSON.stringify(json),
      contentType: "application/json; charset=UTF-8",
      success: function(data) {
        console.log("success: " + data);
      }.bind(this),
      error: function(data) {
        this.props.errorToggle("Failed to make summary", data);
      }.bind(this)
    });
  },
  render: function() {
    let summaryDisplay = "Summary Loading...";
    let onClick;
    if (this.props.summary == 0) {
      summaryDisplay = "Make Summary";
      onClick = this.toggle;
    } else if (this.props.summary == 1) {
      summaryDisplay = "Remove Summary";
      onClick = this.toggle;
    }
    return (
      <span style={{ display: "block" }} onClick={onClick}>
        {summaryDisplay}
      </span>
    );
  }
});

module.exports = Summary;
