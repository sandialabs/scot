import React from "react";
import $ from "jquery";
import * as SessionStorage from "../utils/session_storage";
import { Editor } from "@tinymce/tinymce-react";
import Conflict from "./conflict";
import Dialog from "@material-ui/core/Dialog";

let Button = require("react-bootstrap/lib/Button.js");
let Prompt = require("react-router-dom").Prompt;
let Link = require("react-router-dom").Link;

export default class AddEntryModal extends React.Component {
  constructor(props) {
    super(props);
    let key = new Date();
    key = key.getTime();
    let tinyID = "tiny_" + key;
    let content;
    let asyncContentLoaded;
    switch (this.props.entryAction) {
      case "Add":
        content = "";
        asyncContentLoaded = true;
        break;
      case "Reply":
        content = "";
        asyncContentLoaded = true;
        break;
      case "Copy To Entry":
        content = this.props.content;
        asyncContentLoaded = true;
        break;
      case "Edit":
        content = "";
        asyncContentLoaded = false;
        break;
      case "Export":
        content = this.props.content;
        asyncContentLoaded = true;
        break;
      default:
        content = "";
        asyncContentLoaded = true;
        break;
    }

    this.state = {
      tinyID: tinyID,
      key: key,
      content: content,
      asyncContentLoaded: asyncContentLoaded,
      leaveCatch: true,
      whoami: undefined,
      recentlyUpdated: 0,
      showConflict: false,
      localcontent: ""
    };
  }

  componentDidMount = () => {
    let whoami = SessionStorage.getSessionStorage("whoami");
    if (whoami) {
      this.setState({ whoami: whoami });
    }

    if (this.props.entryAction === "Edit") {
      $.ajax({
        type: "GET",
        url: "/scot/api/v2/entry/" + this.props.id,
        success: function(response) {
          this.setState({
            content: response.body,
            asyncContentLoaded: true,
            recentlyUpdated: response.updated
          });
          this.forceUpdate();
        }.bind(this),
        error: function(data) {
          this.props.errorToggle(
            "Error getting original data from source. Copy/Paste original",
            data
          );
          this.setState({
            content:
              "Error getting original data from source. Copy/Paste original",
            asyncContentLoaded: true
          });
          this.forceUpdate();
        }.bind(this)
      });
    }
    if ($("#not_saved_entry_" + this.state.key).position()) {
      $(".entry-wrapper").scrollTop(
        $(".entry-wrapper").scrollTop() +
          $("#not_saved_entry_" + this.state.key).position().top
      );
    }
  };

  // shouldComponentUpdate = () => {
  //   return false; //prevent updating this component because it causes the page container to scroll upwards and lose focus due to a bug in paste_preprocess. If this is removed it will cause abnormal scrolling.
  // };

  onCancel = () => {
    this.setState({ leaveCatch: false });
    this.props.addedentry();
    this.setState({ change: false });
  };

  submit = () => {
    if (
      $("#tiny_" + this.state.key + "_ifr")
        .contents()
        .find("#tinymce")
        .text() === "" &&
      $("#" + this.state.key + "_ifr")
        .contents()
        .find("#tinymce")
        .find("img").length === 0
    ) {
      alert("Please Add Some Text");
    } else {
      if (this.props.entryAction === "Reply") {
        var data = {};
        $("#tiny_" + this.state.key + "_ifr")
          .contents()
          .find("#tinymce")
          .each(function(x, y) {
            $(y)
              .find("img")
              .each(function(key, value) {
                if ($(value)[0].src.startsWith("blob")) {
                  //Checking to see if it's a locally copied file
                  let canvas = document.createElement("canvas");
                  let set = new Image();
                  set = $(value);
                  canvas.width = set[0].width;
                  canvas.height = set[0].height;
                  let ctx = canvas.getContext("2d");
                  ctx.drawImage(set[0], 0, 0);
                  let dataURL = canvas.toDataURL("image/png");
                  $(value).attr("src", dataURL);
                }
              });
          });
        data = JSON.stringify({
          parent: Number(this.props.id),
          body: $("#tiny_" + this.state.key + "_ifr")
            .contents()
            .find("#tinymce")
            .html(),
          target_id: Number(this.props.targetid),
          target_type: this.props.type,
          tlp: "unset"
        });
        $.ajax({
          type: "post",
          url: "/scot/api/v2/entry",
          data: data,
          contentType: "application/json; charset=UTF-8",
          dataType: "json",
          success: function(response) {
            this.setState({ leaveCatch: false });
            this.props.addedentry();
          }.bind(this),
          error: function(response) {
            this.props.errorToggle("Failed to add entry.", response);
          }.bind(this)
        });
      } else if (this.props.entryAction === "Edit") {
        $.ajax({
          type: "GET",
          url: "/scot/api/v2/entry/" + this.props.id,
          success: function(response) {
            if (this.state.recentlyUpdated !== response.updated) {
              this.forEdit(false);
              this.setState({
                showConflict: true,
                remoteconflict: response.body
              });
            } else {
              this.forEdit(true);
            }
          }.bind(this),
          error: function(data) {
            this.props.errorToggle("failed to get data for edit", data);
          }.bind(this)
        });
      } else if (this.props.type === "alert") {
        $("#tiny_" + this.state.key + "_ifr")
          .contents()
          .find("#tinymce")
          .each(function(x, y) {
            $(y)
              .find("img")
              .each(function(key, value) {
                if ($(value)[0].src.startsWith("blob")) {
                  //Checking if it's a locally copied file
                  let canvas = document.createElement("canvas");
                  let set = new Image();
                  set = $(value);
                  canvas.width = set[0].width;
                  canvas.height = set[0].height;
                  let ctx = canvas.getContext("2d");
                  ctx.drawImage(set[0], 0, 0);
                  let dataURL = canvas.toDataURL("image/png");
                  $(value).attr("src", dataURL);
                }
              });
          });
        data = JSON.stringify({
          body: $("#tiny_" + this.state.key + "_ifr")
            .contents()
            .find("#tinymce")
            .html(),
          target_id: Number(this.props.targetid),
          target_type: "alert",
          tlp: "unset",
          parent: 0
        });
        $.ajax({
          type: "post",
          url: "/scot/api/v2/entry",
          data: data,
          contentType: "application/json; charset=UTF-8",
          dataType: "json",
          success: function(response) {
            this.setState({ leaveCatch: false });
            this.props.addedentry();
            this.props.toggleVisibility();
          }.bind(this),
          error: function(response) {
            this.props.errorToggle("Failed to add entry.", response);
          }.bind(this)
        });
      } else {
        $("#tiny_" + this.state.key + "_ifr")
          .contents()
          .find("#tinymce")
          .each(function(x, y) {
            $(y)
              .find("img")
              .each(function(key, value) {
                if ($(value)[0].src.startsWith("blob")) {
                  //Checking if its a locally copied file
                  let canvas = document.createElement("canvas");
                  let set = new Image();
                  set = $(value);
                  canvas.width = set[0].width;
                  canvas.height = set[0].height;
                  let ctx = canvas.getContext("2d");
                  ctx.drawImage(set[0], 0, 0);
                  let dataURL = canvas.toDataURL("image/png");
                  $(value).attr("src", dataURL);
                }
              });
          });
        data = {
          parent: 0,
          body: $("#tiny_" + this.state.key + "_ifr")
            .contents()
            .find("#tinymce")
            .html(),
          target_id: Number(this.props.targetid),
          target_type: this.props.type,
          tlp: "unset"
        };
        $.ajax({
          type: "post",
          url: "/scot/api/v2/entry",
          data: JSON.stringify(data),
          contentType: "application/json; charset=UTF-8",
          dataType: "json",
          success: function(response) {
            this.setState({ leaveCatch: false });
            this.props.addedentry();
          }.bind(this),
          error: function(response) {
            this.props.errorToggle("Failed to add entry.", response);
          }.bind(this)
        });
      }
    }
  };

  exportContent = () => {
    if (this.props.recipients.length > 0) {
      var data = {};
      $("#tiny_" + this.state.key + "_ifr")
        .contents()
        .find("#tinymce")
        .each(function(x, y) {
          $(y)
            .find("img")
            .each(function(key, value) {
              if ($(value)[0].src.startsWith("blob")) {
                //Checking to see if it's a locally copied file
                let canvas = document.createElement("canvas");
                let set = new Image();
                set = $(value);
                canvas.width = set[0].width;
                canvas.height = set[0].height;
                let ctx = canvas.getContext("2d");
                ctx.drawImage(set[0], 0, 0);
                let dataURL = canvas.toDataURL("image/png");
                $(value).attr("src", dataURL);
              }
            });
        });
      data = JSON.stringify({
        body: $("#tiny_" + this.state.key + "_ifr")
          .contents()
          .find("#tinymce")
          .html(),
        to: this.props.recipients,
        thing: this.props.type
      });
      $.ajax({
        type: "post",
        url: "/scot/api/v2/sendexport",
        data: data,
        contentType: "application/json; charset=UTF-8",
        dataType: "json",
        success: function() {
          this.setState({ leaveCatch: false });
          this.props.exportResponse("success");
        }.bind(this),
        error: function(response) {
          this.props.errorToggle(
            "Failed to export " + this.props.type,
            response
          );
          this.props.exportResponse("error");
        }.bind(this)
      });
    } else {
      this.props.errorToggle("Please enter a valid email address");
    }
  };

  handleClose = () => {
    this.setState({ showConflict: false });
  };

  forEdit = set => {
    if (set) {
      $("#tiny_" + this.state.key + "_ifr")
        .contents()
        .find("#tinymce")
        .each(function(x, y) {
          $(y)
            .find("img")
            .each(function(key, value) {
              if ($(value)[0].src.startsWith("blob")) {
                //Checking if its a lcoally copied file
                let canvas = document.createElement("canvas");
                let set = new Image();
                set = $(value);
                canvas.width = set[0].width;
                canvas.height = set[0].height;
                let ctx = canvas.getContext("2d");
                ctx.drawImage(set[0], 0, 0);
                let dataURL = canvas.toDataURL("image/png");
                $(value).attr("src", dataURL);
              }
            });
        });
      let data = {
        parent: Number(this.props.parent),
        body: $("#tiny_" + this.state.key + "_ifr")
          .contents()
          .find("#tinymce")
          .html(),
        target_id: Number(this.props.targetid),
        target_type: this.props.type,
        parsed: 0
      };
      $.ajax({
        type: "put",
        url: "/scot/api/v2/entry/" + this.props.id,
        data: JSON.stringify(data),
        contentType: "application/json; charset=UTF-8",
        dataType: "json",
        success: function(response) {
          this.setState({ leaveCatch: false });
          this.props.addedentry();
        }.bind(this),
        error: function(response) {
          this.props.errorToggle("Failed to edit entry.", response);
        }.bind(this)
      });
    }
  };

  handleEditorChange = e => {
    this.setState({ localcontent: e });
  };

  render = () => {
    let not_saved_entry_id = "not_saved_entry_" + this.state.key;
    return (
      <div id={not_saved_entry_id} className={"not_saved_entry"}>
        {this.state.showConflict ? (
          <Dialog
            fullWidth={true}
            maxWidth={"md"}
            open={this.state.showConflict}
            onClose={this.handleClose}
            aria-labelledby="simple-dialog-title"
          >
            <Conflict
              targetid={this.props.targetid}
              type={this.props.type}
              parent={this.props.parent}
              addedEntry={this.props.addedentry}
              id={this.props.id}
              localconflict={this.state.localcontent}
              handleClose={this.handleClose}
              remoteconflict={this.state.remoteconflict}
            />
          </Dialog>
        ) : null}
        <div
          className={"row-fluid entry-outer"}
          style={{
            border: "3px solid blue",
            marginLeft: "auto",
            marginRight: "auto",
            width: "99.3%"
          }}
        >
          <div className={"row-fluid entry-header"}>
            <div className="entry-header-inner">
              [
              <Link style={{ color: "black" }} to={"not_saved_0"}>
                Not_Saved_0
              </Link>
              ]by {this.state.whoami}
              <span
                className="pull-right"
                style={{ display: "inline-flex", paddingRight: "3px" }}
              >
                {this.props.entryAction === "Export" ? (
                  <Button
                    bsSize={"xsmall"}
                    onClick={this.exportContent}
                    bsStyle={"success"}
                  >
                    Export
                  </Button>
                ) : (
                  <Button
                    bsSize={"xsmall"}
                    onClick={this.submit}
                    bsStyle={"success"}
                  >
                    Submit
                  </Button>
                )}
                <Button bsSize={"xsmall"} onClick={this.onCancel}>
                  Cancel
                </Button>
              </span>
            </div>
          </div>
          {this.state.asyncContentLoaded ? (
            <Editor
              id={this.state.tinyID}
              className={"inputtext"}
              initialValue={this.state.content}
              plugins={
                "advlist lists link image charmap print preview hr anchor pagebreak searchreplace wordcount visualblocks visualchars code fullscreen insertdatetime media nonbreaking save table directionality emoticons template paste textpattern imagetools"
              }
              onEditorChange={this.handleEditorChange}
              init={{
                table_default_attributes: {
                  border: "5",
                  borderStyle: "solid",
                  borderColor: "blue"
                },
                auto_focus: this.state.tinyID,
                // selector: "textarea",
                browser_spellcheck: true,
                contextmenu: false,
                plugins:
                  "advlist lists link image charmap print preview hr anchor pagebreak searchreplace wordcount visualblocks visualchars code fullscreen insertdatetime media nonbreaking save table directionality emoticons template paste textpattern imagetools",
                table_clone_elements:
                  "strong em b i font h1 h2 h3 h4 h5 h6 p div",
                paste_retain_style_properties: "all",
                paste_data_images: true,
                paste_preprocess: function(plugin, args) {
                  function replaceA(string) {
                    return string.replace(/<(\/)?a([^>]*)>/g, "<$1span$2>");
                  }
                  args.content = replaceA(args.content) + " ";
                },
                paste_postprocess: (plugin, args) => {
                  args.node.querySelectorAll("table").forEach(tableNode => {
                    tableNode.setAttribute("border", "1");
                    tableNode.setAttribute("cellpadding", "1");
                    tableNode.setAttribute("cellspacing", "0");
                  });
                },
                relative_urls: false,
                remove_script_host: false,
                link_assume_external_targets: true,
                toolbar1:
                  "full screen  | undo redo | bold italic | alignleft aligncenter alignright | bullist numlist | forecolor backcolor fontsizeselect fontselect formatselect | blockquote code link image insertdatetime | customBlockquote",
                content_css: "/css/entryeditor.css",
                height: 250,
                verify_html: false,
                setup: function(editor) {
                  function blockquote() {
                    return "<blockquote><p><br></p></blockquote>";
                  }

                  function insertBlockquote() {
                    let html = blockquote();
                    editor.insertContent(html);
                  }

                  editor.ui.registry.addMenuButton("customBlockquote", {
                    text: "500px max-height blockquote",
                    //image: 'http://p.yusukekamiyamane.com/icons/search/fugue/icons/calendar-blue.png',
                    tooltip: "Insert a 500px max-height div (blockquote)",
                    fetch: insertBlockquote
                    // onclick: insertBlockquote
                  });
                }
              }}
            />
          ) : (
            <div>Loading Editor...</div>
          )}
        </div>
        <Prompt
          when={this.state.leaveCatch}
          message="Unsubmitted entry detected. You may want to submit or copy the contents of the entry before navigating elsewhere. Click CANCEL to prevent navigation elsewhere."
        />
      </div>
    );
  };
}
