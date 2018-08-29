import React from "react";
import $ from "jquery";
let ReactTime = require("react-time").default;
let Modal = require("react-modal");
let Button = require("react-bootstrap/lib/Button");
let type;
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

export default class ViewedByHistory extends React.Component {
  constructor(props) {
    super(props);
    return {
      historyBody: false,
      data: ""
    };
  }
  componentDidMount = () => {
    $.ajax({
      type: "get",
      url: "/scot/api/v2/" + this.props.type + "/" + this.props.id,
      success: function(result) {
        this.setState({ historyBody: true, data: result });
      }.bind(this),
      error: function(data) {
        this.props.errorToggle("failed to get user change history", data);
      }.bind(this)
    });
  };

  render = () => {
    return (
      <div>
        <Modal
          isOpen={true}
          onRequestClose={this.props.viewedByHistoryToggle}
          style={customStyles}
        >
          <div className="modal-header">
            <img
              alt=""
              src="/images/close_toolbar.png"
              className="close_toolbar"
              onClick={this.props.viewedByHistoryToggle}
            />
            <h3 id="myModalLabel">{this.props.subjectType} Viewed By</h3>
          </div>
          <div
            className="modal-body"
            style={{ maxHeight: "30vh", overflowY: "auto" }}
          >
            {this.state.historyBody ? (
              <ViewedByHistoryData data={this.state.data} />
            ) : null}
          </div>
          <div className="modal-footer">
            <Button onClick={this.props.viewedByHistoryToggle}>Done</Button>
          </div>
        </Modal>
      </div>
    );
  };
}

class ViewedByHistoryData extends React.Component {
  render = () => {
    let rows = [];
    let data = this.props.data;
    for (let prop in data.view_history) {
      rows.push(
        <ViewedByHistoryDataIterator
          data={data.view_history[prop]}
          prop={prop}
        />
      );
    }
    return <div>{rows}</div>;
  };
}

class ViewedByHistoryDataIterator extends React.Component {
  render = () => {
    let data = this.props.data;
    let prop = this.props.prop;
    return (
      <div>
        <b>{prop}</b> at{" "}
        <ReactTime value={data.when * 1000} format="MM/DD/YYYY hh:mm:ss a" />{" "}
        from IP: {data.where}
      </div>
    );
  };
}
