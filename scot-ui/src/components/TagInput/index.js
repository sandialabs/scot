import React, { Component } from "react";
import PropTypes from "prop-types";
import ReactTags from "react-tag-autocomplete";
import $ from "jquery";

class TagInput extends Component {
  constructor(props) {
    super(props);

    let tags = [];
    if (this.props.value) {
      tags = this.props.value;
    }

    let maxTags = undefined;
    if (this.props.maxTags) {
      maxTags = this.props.maxTags;
    }
    this.state = {
      suggestions: [],
      tags: tags,
      maxTags: maxTags,
      placeholder: ""
    };
  }

  handleDelete = i => {
    const tags = this.state.tags;

    tags.splice(i, 1);
    if (tags.length === 0) {
      this.props.onChange("");
      this.setState({ tags: tags, placeholder: "" });
      return;
    }

    this.props.onChange(tags);
    this.setState({ tags: tags, placeholder: "" });
  };

  handleAdd = tag => {
    const tags = this.state.tags;

    if (this.state.maxTags && tags.length >= this.state.maxTags) {
      this.setState({
        placeholder:
          "Only " +
          this.state.maxTags +
          " allowed. Please delete a tag to add another one"
      });
      return;
    } else {
      tags.push(tag);
      this.props.onChange(tags);
      this.setState({ tags: tags, placeholder: "" });
    }
  };

  componentDidUpdate() {
    this.showHideInput();
  }

  handleInputChange = input => {
    if (input && input.length >= 2) {
      let arr = [];
      $.ajax({
        type: "get",
        url: "/scot/api/v2/ac/" + this.props.type + "/" + input,
        success: function(result) {
          result = result.records;
          for (let i = 0; i < result.length; i++) {
            let obj = {};
            obj.id = i + 1;
            obj.name = result[i];
            arr.push(obj);
          }
          this.setState({ suggestions: arr });
        }.bind(this),
        error: function(data) {
          console.log("failed to get autocomplete data");
        }
      });
    }
  };

  showHideInput = () => {
    if (
      this.props.type === "userdef" &&
      this.props.maxTags &&
      this.state.tags.length >= this.props.maxTags
    ) {
      $(".react-tags__search").hide();
    } else {
      $(".react-tags__search").show();
    }
  };

  render() {
    return (
      <div className="TagInput">
        <ReactTags
          tags={this.state.tags}
          suggestions={this.state.suggestions}
          handleAddition={this.handleAdd}
          handleDelete={this.handleDelete}
          handleInputChange={this.handleInputChange}
          autoresize={false}
          autofocus={false}
          allowBackspace={false}
          allowNew={true}
          placeholder={this.state.placeholder}
          tagComponent={Tag}
        />
      </div>
    );
  }
}

const Tag = ({ classNames, onDelete, tag }) => (
  <div className={classNames.selectedTag}>
    <span className={classNames.selectedTagName}>{tag.name}</span>
    <i className={"fa fa-remove"} aria-hidden="true" onClick={onDelete} />
  </div>
);

export default TagInput;
