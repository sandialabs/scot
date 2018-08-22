import React, { Component } from "react";
import PropTypes from "prop-types";
import AutoComplete from "react-autocomplete";
import $ from "jquery";

class AutoCompleteInput extends Component {
  constructor(props) {
    super(props);

    this.state = {
      suggestions: [],
      value: ""
    };

    this.HandleAdd = this.HandleAdd.bind(this);
    this.HandleInputChange = this.HandleInputChange.bind(this);
  }

  static propTypes = {
    onChange: PropTypes.func.isRequired,
    value: PropTypes.array.isRequired
  };

  componentWillMount() {
    if (this.props.value) {
      this.setState({ value: this.props.value });
    }
  }

  HandleAdd(value) {
    this.setState({ value: value });
    this.props.OnChange(value);
  }

  HandleInputChange(input) {
    this.props.OnChange(input.target.value);

    this.setState({ value: input.target.value });

    if (input.target && input.target.value.length >= 1) {
      let arr = [];
      $.ajax({
        type: "get",
        url: "/scot/api/v2/ac/" + this.props.type + "/" + input.target.value,
        success: function(result) {
          var result = result.records;
          for (let i = 0; i < result.length; i++) {
            if (typeof result[i] == "string") {
              let obj = {};
              obj.label = result[i];
              arr.push(obj);
            }
          }

          this.setState({ suggestions: arr });
        }.bind(this),
        error: function() {
          console.log("failed to get autocomplete data");
        }.bind(this)
      });
    }
  }

  render() {
    return (
      <div className="AutoCompleteInput">
        <AutoComplete
          getItemValue={item => item.label}
          items={this.state.suggestions}
          renderItem={(item, isHighlighted) => (
            <div style={{ background: isHighlighted ? "lightgray" : "white" }}>
              {item.label}
            </div>
          )}
          value={this.state.value}
          onChange={this.HandleInputChange}
          onSelect={this.HandleAdd}
          menuStyle={{
            borderRadius: "3px",
            boxShadow: "0 2px 12px rgba(0, 0, 0, 0.1)",
            background: "rgba(255, 255, 255, 0.9)",
            padding: "2px 0",
            fontSize: "90%",
            overflow: "auto",
            maxHeight: "200px", // TODO: don't cheat, let it flow to the bottom
            top: "unset",
            left: "unset",
            position: "absolute"
          }}
          inputProps={{ style: { width: "100%" } }}
          wrapperProps={{ style: { width: "300px" } }}
        />
      </div>
    );
  }
}

export default AutoCompleteInput;
