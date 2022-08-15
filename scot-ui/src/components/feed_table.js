import React from "react";
import ReactDateTime from "react-datetime";
import { Button, Tooltip, OverlayTrigger, FormControl } from "react-bootstrap";
import $ from "jquery";

//Add data into this metadata field by entering in the form layout in scot.cfg.pl.

export default class FeedDataTable extends React.Component {
  onChange = event => {
    let attribute_name = event.target.id;
    let value = event.target.value;

    let data = {};
    data[attribute_name] = value;

    $.ajax({
      type: "put",
      url: "scot/api/v2/" + this.props.type + "/" + this.props.id,
      data: JSON.stringify(data),
      contentType: "application/json; charset=UTF-8",
      success: function() {
        console.log("successfully changed feed table data");
        this.forceUpdate();
      }.bind(this),
      error: function(data) {
        this.props.errorToggle("Failed to updated feed table data", data);
      }.bind(this)
    });
  };

  shouldComponentUpdate(nextProps, nextState) {
    //Only update the metadata if the headerData is different
    if (this.props.headerData === nextProps.headerData) {
      return false;
    } else {
      return true;
    }
  }

  render() {
    let formType = [
        { 
            "label": "Status", 
            "key": "status",
            "type": "dropdown",
            "value": [
                { "value": "active", "selected": 1 },
                { "value": "paused", "selected": 0 },
            ],
            "help": "Activate or Pause fetches from Feed"
        },
        {
            "label": "Feed Name",
            "key": "name",
            "type": "input",
            "value": "enter feed name",
            "help": "Name to reference feed by"
        },
        {
            "label": "URI of Feed",
            "key": "uri",
            "type": "input",
            "value": "https://uri.goes.here",
            "help": "Enter the URI to access the Feed"
        },
        {
            "label": "Feed type",
            "key": "type",
            "type": "dropdown",
            "value": [
                { "value": "RSS", "selected": 1 },
                { "value": "Twitter", "selected": 0 },
                { "value": "Email", "selected": 0 }
            ],
            "help": "Select type of feed"
        }
    ];
    let rowElements = [];
    for (let i = 0; i < formType.length; i++) {

        //console.log("header Data = ",this.props.headerData);
        let value = formType[i]["value"];
        let thiskey = formType[i]["key"];


        if ( this.props.headerData[thiskey] ) {
            value = this.props.headerData[thiskey];
        }
        // console.log("value is ",value);

        switch (formType[i]["type"]) {
            case "dropdown":
                rowElements.push(
                    <DropdownComponent
                        onChange={this.onChange}
                        label={formType[i].label}
                        id={formType[i].key}
                        referenceKey={formType[i]["key"]}
                        value={value}
                        dropdownValues={formType[i]["value"]}
                        help={formType[i].help}
                    />
                );
            break;

            case "input":
                rowElements.push(
                <InputComponent
                    onBlur={this.onChange}
                    value={value}
                    id={formType[i].key}
                    label={formType[i].label}
                    help={formType[i].help}
                />
                );
            break;

            case "calendar":
                let calendarValue = value * 1000;
                rowElements.push(
                <Calendar
                    typeTitle={formType[i].label}
                    value={calendarValue}
                    typeLower={formType[i].key}
                    type={this.props.type}
                    id={this.props.id}
                    help={formType[i].help}
                />
                );
            break;

            case "textarea":
                rowElements.push(
                <TextAreaComponent
                    id={formType[i].key}
                    value={value}
                    onBlur={this.onChange}
                    label={formType[i].label}
                    help={formType[i].help}
                />
                );
            break;

            case "input_multi":
                rowElements.push(
                <InputMultiComponent
                    id={formType[i].key}
                    value={value}
                    errorToggle={this.props.errorToggle}
                    mainType={this.props.type}
                    mainId={this.props.id}
                    label={formType[i].label}
                    help={formType[i].help}
                />
                );
            break;

            case "boolean":
                rowElements.push(
                <BooleanComponent
                    id={formType[i].key}
                    value={value}
                    onChange={this.onChange}
                    label={formType[i].label}
                    help={formType[i].help}
                />
                );
            break;

            case "multi_select":
                rowElements.push(
                <MultiSelectComponent
                    onChange={this.onChange}
                    label={formType[i].label}
                    id={formType[i].key}
                    referenceKey={formType[i]["key"]}
                    value={value}
                    dropdownValues={formType[i]["value"]}
                    help={formType[i].help}
                    mainType={this.props.type}
                    mainId={this.props.id}
                />
                );
            break;
        }
    }

    return (
      <div>
        {formType ? (
          <div className="custom-metadata-table container">
            <div className="row">
              {rowElements}
            </div>
          </div>
        ) : null}
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
        //console.log("props value = ",this.props.value);
        //console.log("props dropdownvalue = ",this.props.dropdownValues[j]["value"]);
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

class Calendar extends React.Component {
  constructor(props) {
    super(props);
    let loading = false;
    if (this.props.dynamic) {
      loading = true;
    }
    this.state = {
      showCalendar: false,
      loading: loading,
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
        let value = result[this.props.referenceKey] * 1000;
        this.setState({ value: value, loading: false });
      }.bind(this)
    });
  };

  componentWillReceiveProps(nextProps) {
    if (nextProps.dynamic) {
      this.getDynamic();
    } else {
      this.setState({ value: nextProps.value });
    }
  }

  onChange = event => {
    let data_string = this.props.typeLower;
    let v = event._d.getTime() / 1000;
    let json = {};
    json[data_string] = v;
    $.ajax({
      type: "put",
      url: "scot/api/v2/" + this.props.type + "/" + this.props.id,
      data: JSON.stringify(json),
      contentType: "application/json; charset=UTF-8",
      success: function() {
        console.log("successfully changed custom table data");
      }.bind(this),
      error: function(data) {
        this.props.errorToggle("Failed to updated custom table data", data);
      }.bind(this)
    });
  };

  showCalendar = () => {
    if (this.state.showCalendar == false) {
      this.setState({ showCalendar: true });
    } else {
      this.setState({ showCalendar: false });
    }
  };

  render() {
    return (
      <div
        className="custom-metadata-table-component-div"
        style={{ display: "flex", flexFlow: "row" }}
      >
        <span className="custom-metadata-tableWidth">
          {this.props.typeTitle}
        </span>
        {!this.state.loading ? (
          <ReactDateTime
            className="custom-metadata-input-width"
            value={this.state.value}
            onChange={this.onChange}
          />
        ) : (
          <span>Loading...</span>
        )}
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

class TextAreaComponent extends React.Component {
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
        let value = result[this.props.referenceKey];
        this.setState({ value: value });
      }.bind(this)
    });
  };

  componentWillReceiveProps(nextProps) {
    if (nextProps.dynamic) {
      this.getDynamic();
    } else {
      this.setState({ value: nextProps.value });
    }
  }

  inputOnChange = event => {
    this.setState({ value: event.target.value });
  };

  render() {
    return (
      <div className="custom-metadata-table-component-div">
        <span className="custom-metadata-tableWidth">
          {this.props.label}
          <OverlayTrigger
            placement="top"
            overlay={<Tooltip id={this.props.id}> {this.props.help}</Tooltip>}
          >
            <i
              className="fa fa-question-circle-o"
              aria-hidden="true"
              style={{ paddingLeft: "5px" }}
            ></i>
          </OverlayTrigger>
        </span>
        <span>
          <textarea
            id={this.props.id}
            onBlur={this.props.onBlur}
            onChange={this.inputOnChange}
            value={this.state.value}
            className="custom-metadata-textarea-width"
          />
        </span>
      </div>
    );
  }
}

class InputMultiComponent extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      inputValue: "",
      value: []
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
        let value = result[this.props.referenceKey];
        this.setState({ value: value });
      }.bind(this)
    });
  };

  componentWillReceiveProps(nextProps) {
    if (nextProps.dynamic) {
      this.getDynamic();
    } else {
      this.setState({ value: nextProps.value });
    }
  }

  handleAddition = group => {
    if (this.state.value !== undefined) {
      let groupArr = [];
      let data = this.state.value;
      console.log("handleAddition data is ",data);
      for (let i = 0; i < data.length; i++) {
        if (data[i] != undefined) {
          if (typeof data[i] == "string") {
            groupArr.push(data[i]);
          } else {
            groupArr.push(data[i].value);
          }
        }
      }
      groupArr.push(group.target.value);

      let newData = {};
      let data_string = this.props.id;
      newData[data_string] = groupArr;

      // newData[this.props.id] = groupArr;

      $.ajax({
        type: "put",
        url: "scot/api/v2/" + this.props.mainType + "/" + this.props.mainId,
        data: JSON.stringify(newData),
        contentType: "application/json; charset=UTF-8",
        success: function() {
          console.log("success: group added");
          this.setState({ inputValue: "", value: newData[this.props.id] });
        }.bind(this),
        error: function(data) {
          this.props.errorToggle("Failed to add group", data);
        }.bind(this)
      });
    }
  };

  InputChange = event => {
    this.setState({ inputValue: event.target.value });
  };

  handleDelete = event => {
    let data = this.state.value;
    let clickedThing = event.target.id;
    let groupArr = [];
    for (let i = 0; i < data.length; i++) {
      if (data[i] != undefined) {
        if (typeof data[i] == "string") {
          if (data[i] != clickedThing) {
            groupArr.push(data[i]);
          }
        } else {
          if (data[i].value != clickedThing) {
            groupArr.push(data[i].value);
          }
        }
      }
    }

    let newData = {
      data: {
        [this.props.id]: groupArr
      }
    };

    $.ajax({
      type: "put",
      url: "scot/api/v2/" + this.props.mainType + "/" + this.props.mainId,
      data: JSON.stringify(newData),
      contentType: "application/json; charset=UTF-8",
      success: function(data) {
        this.setState({ value: newData[this.props.id] });
        console.log("deleted group success: " + data);
      }.bind(this),
      error: function(data) {
        this.props.errorToggle("Failed to delete group", data);
      }.bind(this)
    });
  };

  render() {
    let data = this.state.value;
    let groupArr = [];
    let value;
    if (data !== undefined) {
      for (let i = 0; i < data.length; i++) {
        if (typeof data[i] == "string") {
          value = data[i];
        } else if (typeof data[i] == "object") {
          if (data[i] != undefined) {
            value = data[i].value;
          }
        }
        groupArr.push(
          <span id="event_signature" className="tagButton">
            {value}{" "}
            <i
              id={value}
              onClick={this.handleDelete}
              className="fa fa-times tagButtonClose"
            />
          </span>
        );
      }
    }

    return (
      <div className="custom-metadata-table-component-div">
        <span className="custom-metadata-tableWidth">{this.props.label}</span>
        <span>
          <input
            className="custom-metadata-input-width"
            id={this.props.id}
            onChange={this.InputChange}
            value={this.state.inputValue}
          />
          {this.state.inputValue != "" ? (
            <Button
              bsSize="xsmall"
              bsStyle="success"
              onClick={this.handleAddition}
              value={this.state.inputValue}
            >
              Submit
            </Button>
          ) : (
            <Button bsSize="xsmall" bsType="submit" disabled>
              Submit
            </Button>
          )}
        </span>
        <span className="custom-metadata-multi-input-tags">{groupArr}</span>
        <span>
          <OverlayTrigger
            placement="top"
            overlay={<Tooltip id={this.props.id}> {this.props.help}</Tooltip>}
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

class BooleanComponent extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      value: false
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
        let value = result[this.props.referenceKey];
        this.setState({ value: value });
      }.bind(this)
    });
  };

  componentWillReceiveProps = nextProps => {
    if (nextProps.dynamic) {
      this.getDynamic();
    } else {
      this.setState({ value: nextProps.value });
    }
  };

  onChange = e => {
    let value;
    if (e.target.value == "true") {
      value = 1;
    } else {
      value = 0;
    }

    let obj = {};
    obj["target"] = {};
    obj["target"]["id"] = this.props.id;
    obj["target"]["value"] = value;

    this.props.onChange(obj);
  };

  render() {
    return (
      <div className="custom-metadata-table-component-div">
        <span className="custom-metadata-tableWidth">{this.props.label}</span>
        <span>
          <input
            type="checkbox"
            className="custom-metadata-input-width"
            id={this.props.id}
            name={this.props.id}
            value={this.state.value}
            onClick={this.onChange}
          />
        </span>
        <span>
          <OverlayTrigger
            placement="top"
            overlay={<Tooltip id={this.props.id}> {this.props.help}</Tooltip>}
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

class MultiSelectComponent extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      options: []
    };
  }

  componentWillMount() {
    if (this.props.dynamic) {
      this.getDynamic();
    } else {
      this.makeForm();
    }
  }

  makeForm = nextProps => {
    let props = this.props;
    if (nextProps) {
      props = nextProps;
    }

    let arr = [];
    for (let j = 0; j < props.dropdownValues.length; j++) {
      if (props.value.includes(props.dropdownValues[j]["value"])) {
        arr.push(<option selected>{props.dropdownValues[j]["value"]}</option>);
      } else {
        arr.push(<option>{props.dropdownValues[j]["value"]}</option>);
      }
    }

    this.setState({ options: arr });
  };

  getDynamic = () => {
    $.ajax({
      type: "get",
      url: this.props.fetchURL,
      success: function(result) {
        let arr = [];
        for (let j = 0; j < result[this.props.referenceKey].length; j++) {
          if (result[this.props.referenceKey][j].selected == 1) {
            arr.push(
              <option selected>
                {result[this.props.referenceKey][j].value}
              </option>
            );
          } else {
            arr.push(
              <option>{result[this.props.referenceKey][j].value}</option>
            );
          }
        }

        this.setState({ options: arr });
      }.bind(this)
    });
  };

  componentWillReceiveProps = nextProps => {
    if (nextProps.dynamic) {
      this.getDynamic();
    } else {
      this.makeForm(nextProps);
    }
  };

  onChange = event => {
    let multiSelectArr = [];
    for (let i = 0; i < event.target.options.length; i++) {
      if (event.target.options[i] != undefined) {
        if (event.target.options[i].selected == true) {
          multiSelectArr.push(event.target.options[i].value);
        } else {
          continue;
        }
      }
    }

    let newData = {};
    let data_string = this.props.id;
    newData[data_string] = multiSelectArr;

    $.ajax({
      type: "put",
      url: "scot/api/v2/" + this.props.mainType + "/" + this.props.mainId,
      data: JSON.stringify(newData),
      contentType: "application/json; charset=UTF-8",
      success: function() {
        console.log("success: multi select added");
      }.bind(this),
      error: function(data) {
        this.props.errorToggle("Failed to add multi select", data);
      }.bind(this)
    });
    this.setState({ selected: event.target.value });
  };

  render() {
    return (
      <div className="custom-metadata-table-component-div">
        <span className="custom-metadata-tableWidth">{this.props.label}</span>
        <span>
          <FormControl
            id={this.props.id}
            componentClass="select"
            placeholder="select"
            bsClass="custom-metadata-multi-select-width"
            multiple
            onChange={this.onChange}
            size={this.state.options.length}
          >
            {this.state.options}
          </FormControl>
        </span>
        <span>
          <OverlayTrigger
            placement="top"
            overlay={<Tooltip id={this.props.id}> {this.props.help}</Tooltip>}
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
