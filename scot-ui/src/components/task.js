import React from "react";
import * as SessionStorage from "../utils/session_storage";
import $ from "jquery";

export default class Task extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      whoami: undefined
    };
  }

  componentDidMount = () => {
    let whoami = SessionStorage.getSessionStorage("whoami");
    this.setState({ whoami: whoami });
  };

  makeTask = () => {
    let json = { make_task: 1 };
    $.ajax({
      type: "put",
      url: "scot/api/v2/entry/" + this.props.entryid,
      data: JSON.stringify(json),
      contentType: "application/json; charset=UTF-8",
      success: function(data) {
        console.log("success: " + data);
      },
      error: function(data) {
        this.props.errorToggle("Failed to close task", data);
      }.bind(this)
    });
  };

  closeTask = () => {
    let json = { close_task: 1 };
    $.ajax({
      type: "put",
      url: "scot/api/v2/entry/" + this.props.entryid,
      data: JSON.stringify(json),
      contentType: "application/json; charset=UTF-8",
      success: function(data) {
        console.log("success: " + data);
      },
      error: function(data) {
        this.props.errorToggle("Failed to close task", data);
      }.bind(this)
    });
  };

  takeTask = () => {
    let json = { take_task: 1 };
    $.ajax({
      type: "put",
      url: "scot/api/v2/entry/" + this.props.entryid,
      data: JSON.stringify(json),
      contentType: "application/json; charset=UTF-8",
      success: function(data) {
        console.log("success: " + data);
      },
      error: function(data) {
        this.props.errorToggle("Failed to make Task owner", data);
      }.bind(this)
    });
  };

  render = () => {
    let taskDisplay = "Task Loading...";
    let onClick;
    if (this.props.taskData.class === "task") {
      if (
        this.props.taskData.metadata.task.status === undefined ||
        this.props.taskData.metadata.task.status === null ||
        this.props.taskData.class !== "task"
      ) {
        taskDisplay = "Make Task";
        onClick = this.makeTask;
      } else if (
        this.state.whoami !== this.props.taskData.metadata.task.who &&
        this.props.taskData.metadata.task.status === "open"
      ) {
        taskDisplay = "Assign task to me";
        onClick = this.takeTask;
      } else if (
        this.state.whoami === this.props.taskData.metadata.task.who &&
        this.props.taskData.metadata.task.status === "open"
      ) {
        taskDisplay = "Close Task";
        onClick = this.closeTask;
      } else if (
        this.props.taskData.metadata.task.status === "closed" ||
        this.props.taskData.metadata.task.status === "completed"
      ) {
        taskDisplay = "Reopen Task";
        onClick = this.makeTask;
      } else if (
        this.state.whoami === this.props.taskData.metadata.task.who &&
        this.props.taskData.metadata.task.status === "assigned"
      ) {
        taskDisplay = "Close Task";
        onClick = this.closeTask;
      } else if (
        this.state.whoami !== this.props.taskData.metadata.task.who &&
        this.props.taskData.metadata.task.status === "assigned"
      ) {
        taskDisplay = "Assign task to me";
        onClick = this.takeTask;
      }
    } else {
      taskDisplay = "Make Task";
      onClick = this.makeTask;
    }
    return (
      <span style={{ display: "block" }} onClick={onClick}>
        {taskDisplay}
      </span>
    );
  };
}
