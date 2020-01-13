import React from "react";
import * as SessionStorage from "../utils/session_storage";
import $ from "jquery";
import Dropzone from "react-dropzone";
let Button = require("react-bootstrap/lib/Button.js");
let Link = require("react-router-dom").Link;
let finalfiles = [];

export default class FileUpload extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      files: [],
      edit: false,
      stagecolor: "#000",
      enable: true,
      addentry: true,
      saved: true,
      enablesave: true,
      whoami: undefined
    };
  }

  componentDidMount() {
    let whoami = SessionStorage.getSessionStorage("whoami");
    if (whoami) {
      this.setState({ whoami: whoami });
    }

    $(".entry-wrapper").scrollTop(
      $(".entry-wrapper").scrollTop() +
        $("#not_saved_entry_" + this.props.id).position().top
    );
  }

  render() {
    let not_saved_entry_id = "not_saved_entry_" + this.props.id;
    return (
      <div id={not_saved_entry_id}>
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
                <Button bsSize={"xsmall"} onClick={this.submit}>
                  Submit
                </Button>
                <Button bsSize={"xsmall"} onClick={this.onCancel}>
                  Cancel
                </Button>
              </span>
            </div>
          </div>
          <Dropzone onDrop={this.onDrop}>
            {({ getRootProps, getInputProps }) => (
              <section>
                <div
                  style={{
                    "border-width": "2px",
                    "border-color": "#000",
                    "border-radius": "4px",
                    "border-style": "dashed",
                    "text-align": "center",
                    "background-color": "azure"
                  }}
                  {...getRootProps()}
                >
                  <input {...getInputProps()} />
                  <p>Drag 'n' drop some files here, or click to select files</p>
                </div>
              </section>
            )}
          </Dropzone>
          {this.state.files ? (
            <div>
              {" "}
              {this.state.files.map(
                function(file) {
                  return (
                    <ul
                      style={{
                        "list-style-type": "none",
                        margin: "0",
                        padding: "0"
                      }}
                    >
                      <li>
                        <p style={{ display: "inline" }}>{file.name}</p>
                        <button
                          style={{ "line-height": "1px" }}
                          className="btn btn-info"
                          id={file.name}
                          onClick={this.Close}
                        >
                          x
                        </button>
                      </li>
                    </ul>
                  );
                }.bind(this)
              )}
            </div>
          ) : null}
        </div>
      </div>
    );
  }

  onCancel = () => {
    finalfiles = [];
    this.props.fileUploadToggle();
  };

  Close = i => {
    for (let x = 0; x < finalfiles.length; x++) {
      if (i.target.id === finalfiles[x].name) {
        finalfiles.splice(x, 1);
      }
    }
    this.setState({ files: finalfiles });
  };

  onDrop = files => {
    for (let i = 0; i < files.length; i++) {
      finalfiles.push(files[i]);
    }
    console.log(files);
    this.setState({ files: finalfiles });
  };

  submit = () => {
    if (finalfiles.length > 0) {
      for (let i = 0; i < finalfiles.length; i++) {
        let data = new FormData();
        data.append("upload", finalfiles[i]);
        data.append("target_type", this.props.type);
        data.append("target_id", Number(this.props.targetid));
        if (this.props.entryid != null) {
          data.append("entry_id", this.props.entryid);
        }
        let xhr = new XMLHttpRequest();
        xhr.addEventListener("progress", this.uploadProgress);
        xhr.addEventListener("load", this.uploadComplete);
        xhr.addEventListener("error", this.uploadFailed);
        xhr.addEventListener("abord", this.uploadCancelled);
        xhr.open("POST", "/scot/api/v2/file");
        console.log(data);
        xhr.send(data);
      }
    } else {
      alert("Select a file to upload before submitting.");
    }
  };

  uploadComplete = () => {
    this.onCancel();
  };

  uploadFailed = () => {
    this.props.errorToggle("An error occured. Upload failed.");
  };
}
