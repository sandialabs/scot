import React from "react";
import ReactDateTime from "react-datetime";
import {Button, Tooltip, OverlayTrigger, FormControl } from "react-bootstrap";
import $ from "jquery";

export default class FeedTable extends React.Component {

    onChange = event => {
        let attribute_name = event.target.id;
        let value = event.target.value;

        let data = {};
        data[attribute_name] = value;

        $.ajax({
            type: "put",
            url: "scot/api/v2/" + this.props.tyype + "/" + this.props.id,
            data: JSON.stringify(data),
            contentType: "application/json; charset=UTF-8",
            success: function() {
                console.log("successfully changed feed data");
                this.forceUpdate();
            }.bind(this),
            error: function(data) {
                this.props.errorToggle("Failed to update Feed data", data);
            }.bind(this)
        });
    };

    shouldComponentUpdate(nextProps, nextState) {
        if (this.props.headerData === nextProps.headerData) {
            return false;
        }
        else {
            return true;
        }
    }

    render() {
        let rowComponents =[];
        let statusDropdown = {
            "key": "status",
            "value": [
                { "value": "active", "selected": 1 },
                { "value": "paused", "selected": 0 }
            ],
            "label": "Status",
            "help": "Activate or Pause Feed",
        };
        // status, name, type, uri 
        rowComponents.push(
            <DropdownComponent
             onChange={this.onChange}
             label={statusDropdown["label"]}
             id={statusDropdown["key"]}
             referenceKey={statusDropdown["key"]}
             value={statusDropdown["value"]}
             dropdownValues={statusDropdown["value"]}
             help={statusDropdown["help"]}
            />
        );

        let nameField = {
            "key": "name",
            "value": "",
            "label": "Feed Name",
            "help": "Easy Name to reference Feed by"
        };
        rowComponents.push(
            <InputComponent
             onBlur={this.onChange}
             value={nameField["value"]}
             id={nameField["key"]}
             label={nameField["label"]}
             help={nameField["help"]}
            />
        );

        let uriField = {
            "key": "uri",
            "value": "",
            "label": "URI of Feed",
            "help": "Enter the URI to access feed"
        };
        rowComponents.push(
            <InputComponent
             onBlur={this.onChange}
             value={uriField["value"]}
             id={uriField["key"]}
             label={uriField["label"]}
             help={uriField["help"]}
            />
        );

        let typeDropdown = {
            "key": "status",
            "value": [
                { "value": "rss", "selected": 1 },
                { "value": "twitter", "selected": 0 },
                { "value": "email", "selected": 0 }
            ],
            "label": "Feed Type",
            "help": "Select type of Feed",
        };
        rowComponents.push(
            <DropdownComponent
             onChange={this.onChange}
             label={typeDropdown["label"]}
             id={typeDropdown["key"]}
             referenceKey={typeDropdown["key"]}
             value={typeDropdown["value"]}
             dropdownValues={typeDropdown["value"]}
             help={typeDropdown["help"]}
            />
        );

        return (
            <div>
                <div className="custom-metadata-table container">
                    <div className="row">
                        {rowComponents}
                    </div>
                </div>
            </div>
        );
    }
}

class DropdownComponent extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      selected: null,
      options: []
    };
  }

  componentWillMount() {
    if (this.props.dynamic) {
      this.getDynamic();
    } else {
      let arr = [];
      let selected = "";

      for (let j = 0; j < this.props.dropdownValues.length; j++) {
        if (this.props.value == this.props.dropdownValues[j]["value"]) {
          selected = this.props.value;
        }

        arr.push(<option>{this.props.dropdownValues[j]["value"]}</option>);
      }

      this.setState({ selected: selected, options: arr });
    }
  }

  getDynamic = () => {
    $.ajax({
      type: "get",
      url: this.props.fetchURL,
      success: function(result) {
        let arr = [];
        let selected = "";
        let referenceKey = this.props.referenceKey;
        if (
          referenceKey == "qual_sigbody_id" ||
          referenceKey == "prod_sigbody_id"
        ) {
          arr.push(<option>0</option>);
          for (let key in result["version"]) {
            if (
              result["version"][key]["revision"] == result.data[referenceKey]
            ) {
              selected = result.data[referenceKey];
            }
            arr.push(<option>{result["version"][key]["revision"]}</option>);
          }
        } else {
          for (let j = 0; j < result[this.props.referenceKey].length; j++) {
            if (result[this.props.referenceKey][j].selected == 1) {
              selected = result[this.props.referenceKey][j].value;
            }

            arr.push(
              <option>{result[this.props.referenceKey][j].value}</option>
            );
          }
        }

        this.setState({ selected: selected, options: arr });
      }.bind(this)
    });
  };

  componentWillReceiveProps(nextProps) {
    if (nextProps.dynamic) {
      this.getDynamic();
    } else {
      this.setState({ selected: nextProps.value });
    }
  }

  onChange = event => {
    this.props.onChange(event);
    this.setState({ selected: event.target.value });
  };

  render() {
    return (
      <div className="custom-metadata-table-component-div">
        <span className="custom-metadata-tableWidth">{this.props.label}</span>
        <span>
          <select
            id={this.props.id}
            value={this.state.selected}
            onChange={this.onChange}
          >
            {this.state.options}
          </select>
        </span>
        <span>
          <OverlayTrigger
            placement="top"
            overlay={
              <Tooltip id={this.props.id}>
                <div
                  dangerouslySetInnerHTML={{ __html: this.props.help }}
                  bsClass="popover helpPopup"
                />
              </Tooltip>
            }
          >
            <i
              className="fa fa-question-circle-o"
              aria-hidden="true"
              style={{ paddingLeft: "5px" }}
            ></i>
          </OverlayTrigger>
        </span>
      </div>
    );
  }
}

class InputComponent extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      value: ""
    };
  }

  componentWillMount() {
    if (this.props.dynamic) {
      this.getDynamic();
    } else {
      this.setState({ value: this.props.value });
    }
  }

  getDynamic = () => {
    $.ajax({
      type: "get",
      url: this.props.fetchURL,
      success: function(result) {
        let value = "";
        value = result[this.props.referenceKey];
        this.setState({ value: value });
      }.bind(this)
    });
  };

  inputOnChange = event => {
    this.setState({ value: event.target.value });
  };

  componentWillReceiveProps(nextProps) {
    if (nextProps.dynamic) {
      this.getDynamic();
    } else {
      this.setState({ value: nextProps.value });
    }
  }

  render() {
    return (
      <div className="custom-metadata-table-component-div">
        <span className="custom-metadata-tableWidth">{this.props.label}</span>
        <span>
          <input
            className="custom-metadata-input-width"
            id={this.props.id}
            onBlur={this.props.onBlur}
            onChange={this.inputOnChange}
            value={this.state.value}
          />
        </span>
        <span>
          <OverlayTrigger
            placement="top"
            overlay={
              <Tooltip id={this.props.id}>
                <div
                  dangerouslySetInnerHTML={{ __html: this.props.help }}
                  bsClass="popover helpPopup"
                />
              </Tooltip>
            }
          >
            <i
              className="fa fa-question-circle-o"
              aria-hidden="true"
              style={{ paddingLeft: "5px" }}
            ></i>
          </OverlayTrigger>
        </span>
      </div>
    );
  }
}


