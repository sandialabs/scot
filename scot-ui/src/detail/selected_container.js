import React from "react";
import $ from "jquery";
let SelectedHeader = require("./selected_header");

export default class SelectedContainer extends React.Component {
  render = () => {
    let datarows = [];
    datarows.push(
      <SelectedHeader
        key={this.props.id}
        id={this.props.id}
        type={this.props.type}
        toggleEventDisplay={this.props.viewEvent}
        taskid={this.props.taskid}
        alertPreSelectedId={this.props.alertPreSelectedId}
        handleFilter={this.props.handleFilter}
        errorToggle={this.props.errorToggle}
        history={this.props.history}
        form={this.props.form}
        createCallbackObject={this.props.createCallbackObject}
        removeCallbackObject={this.props.removeCallbackObject}
      />
    );
    let width = "100%";
    if ($("#list-view")[0] !== undefined) {
      width = "calc(100% - " + $("#list-view").width() + "px)";
    }
    return (
      <div
        id="main-detail-container"
        className="entry-container"
        style={{ width: width, position: "relative" }}
        tabIndex="3"
      >
        {datarows}
      </div>
    );
  };
}
