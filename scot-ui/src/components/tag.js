import React from "react";
import $ from "jquery";
import Button from "react-bootstrap/lib/Button";
import ReactTags from "react-tag-input";

export default class Tag extends React.Component {
  constructor(props) {
    super(props);
    this.state = { tagEntry: false };
  }

  toggleTagEntry = () => {
    if (this.state.tagEntry === false) {
      this.setState({ tagEntry: true });
    } else if (this.state.tagEntry === true) {
      this.setState({ tagEntry: false });
    }
  };

  render = () => {
    let rows = [];
    let id = this.props.id;
    let type = this.props.type;
    let data = this.props.data;

    //Don't show if guide
    if (this.props.type === "guide") {
      return <th />;
    }

    if (data !== undefined) {
      for (let i = 0; i < data.length; i++) {
        rows.push(
          <TagDataIterator
            data={data}
            dataOne={data[i]}
            id={id}
            type={type}
            updated={this.props.updated}
            key={i}
            errorToggle={this.props.errorToggle}
          />
        );
      }
    }
    return (
      <th>
        <th>Tags:</th>
        <td>
          {rows}
          {this.state.tagEntry ? (
            <NewTag
              data={data}
              type={type}
              id={id}
              toggleTagEntry={this.toggleTagEntry}
              updated={this.props.updated}
              errorToggle={this.props.errorToggle}
            />
          ) : null}
          {this.state.tagEntry ? (
            <span className="add-tag-button">
              <Button
                bsSize={"xsmall"}
                bsStyle={"danger"}
                onClick={this.toggleTagEntry}
              >
                <span
                  className="glyphicon glyphicon-minus"
                  aria-hidden="true"
                />
              </Button>
            </span>
          ) : (
            <span className="remove-tag-button">
              <Button
                bsSize={"xsmall"}
                bsStyle={"success"}
                onClick={this.toggleTagEntry}
              >
                <span className="glyphicon glyphicon-plus" aria-hidden="true" />
              </Button>
            </span>
          )}
        </td>
      </th>
    );
  };
}

class TagDataIterator extends React.Component {
  tagDelete = () => {
    let data = this.props.data;
    let newTagArr = [];
    for (let i = 0; i < data.length; i++) {
      if (data[i] !== undefined) {
        if (typeof data[i] === "string") {
          if (data[i] !== this.props.dataOne) {
            newTagArr.push(data[i]);
          }
        } else {
          if (data[i].value !== this.props.dataOne.value) {
            newTagArr.push(data[i].value);
          }
        }
      }
    }
    $.ajax({
      type: "put",
      url: "scot/api/v2/" + this.props.type + "/" + this.props.id,
      data: JSON.stringify({ tag: newTagArr }),
      contentType: "application/json; charset=UTF-8",
      success: function(data) {
        console.log("deleted tag success: " + data);
      },
      error: function(data) {
        this.props.errorToggle("Failed to delete tag", data);
      }.bind(this)
    });
  };

  render = () => {
    let dataOne = this.props.dataOne;
    let value;
    if (typeof dataOne === "string") {
      value = dataOne;
    } else if (typeof dataOne === "object") {
      if (dataOne !== undefined) {
        value = dataOne.value;
      }
    }
    return (
      <span id="event_tag" className="tagButton">
        {value}{" "}
        <span className="tagButtonClose">
          <i onClick={this.tagDelete} className="fa fa-times" />
        </span>
      </span>
    );
  };
}

class NewTag extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      suggestions: this.props.options
    };
  }

  handleAddition = tag => {
    let newTagArr = [];
    let data = this.props.data;
    for (let i = 0; i < data.length; i++) {
      if (data[i] !== undefined) {
        if (typeof data[i] === "string") {
          newTagArr.push(data[i]);
        } else {
          newTagArr.push(data[i].value);
        }
      }
    }
    newTagArr.push(tag);
    $.ajax({
      type: "put",
      url: "scot/api/v2/" + this.props.type + "/" + this.props.id,
      data: JSON.stringify({ tag: newTagArr }),
      contentType: "application/json; charset=UTF-8",
      success: function() {
        console.log("success: tag added");
        this.props.toggleTagEntry();
      }.bind(this),
      error: function(data) {
        this.props.errorToggle("Failed to add tag", data);
        this.props.toggleTagEntry();
      }.bind(this)
    });
  };

  handleInputChange = input => {
    let arr = [];
    $.ajax({
      type: "get",
      url: "/scot/api/v2/ac/tag/" + input,
      success: function(result) {
        for (let i = 0; i < result.records.length; i++) {
          arr.push(result.records[i]);
        }
        this.setState({ suggestions: arr });
      }.bind(this),
      error: function(data) {
        this.props.errorToggle("Failed to get autocomplete data for tag", data);
      }.bind(this)
    });
  };

  handleDelete = () => {
    //blank since buttons are handled outside of this
  };

  handleDrag = () => {
    //blank since buttons are handled outside of this
  };

  render = () => {
    let suggestions = this.state.suggestions;
    return (
      <span className="tag-new">
        <ReactTags
          suggestions={suggestions}
          handleAddition={this.handleAddition}
          handleDelete={this.handleDelete}
          handleDrag={this.handleDrag}
          handleInputChange={this.handleInputChange}
          minQueryLength={1}
          customCSS={1}
        />
      </span>
    );
  };
}
