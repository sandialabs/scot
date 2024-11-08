import React from "react";
import $ from "jquery";
let Button = require("react-bootstrap/lib/Button");

export default class Wall extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      wallMessage: "",
      buttonStatus: "primary",
      buttonText: "Send",
      buttonLoading: false
    };
  }
  sendWallMessage = () => {
    if (this.state.wallMessage === "") {
      alert("Please enter text");
      this.setState({ buttonStatus: "warning" });
    } else {
      this.setState({ buttonText: "Loading", buttonLoading: true });
      let data = { msg: this.state.wallMessage };
      $.ajax({
        type: "post",
        url: "scot/api/v2/wall",
        data: data,
        traditional: true,
        success: function() {
          this.setState({
            buttonStatus: "success",
            buttonText: "Sent",
            buttonLoading: false
          });
        }.bind(this),
        error: function(data) {
          this.setState({
            buttonStatus: "danger",
            buttonText: "Failed - Try Again?",
            buttonLoading: false
          });
          this.props.errorToggle("Failed to send message", data);
        }.bind(this)
      });
    }
  };

  inputChange = input => {
    this.setState({ wallMessage: input.target.value });
  };

  render = () => {
    return (
      <div className="allComponents" style={{ "margin-left": "17px" }}>
        <div>
          <div>
            <div className="main-header-info-child">
              <h2 htmlFor="message">Message to all SCOT users:</h2>
              <input
                id="message"
                style={{ width: "700px" }}
                placeholder="Enter message to be displayed to everyone using SCOT"
                value={this.state.wallMessage}
                onChange={this.inputChange}
              />
              <Button
                onClick={this.sendWallMessage}
                bsStyle={this.state.buttonStatus}
                disabled={this.state.buttonLoading}
              >
                {this.state.buttonText}
              </Button>
            </div>
          </div>
        </div>
      </div>
    );
  };
}
