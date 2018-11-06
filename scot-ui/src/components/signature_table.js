import React from "react";
import AceEditor from "react-ace";
import Button from "react-bootstrap/lib/Button.js";
import DropdownButton from "react-bootstrap/lib/DropdownButton.js";
import MenuItem from "react-bootstrap/lib/MenuItem.js";
import "brace/mode/bro";
import "brace/mode/javascript";
import "brace/mode/java";
import "brace/mode/python";
import "brace/mode/xml";
import "brace/mode/ruby";
import "brace/mode/sass";
import "brace/mode/markdown";
import "brace/mode/mysql";
import "brace/mode/json";
import "brace/mode/html";
import "brace/mode/c_cpp";
import "brace/mode/csharp";
import "brace/mode/perl";
import "brace/mode/powershell";
import "brace/mode/yaml";
import "brace/theme/github";
import "brace/theme/monokai";
import "brace/theme/kuroir";
import "brace/theme/solarized_dark";
import "brace/theme/solarized_light";
import "brace/theme/terminal";
import "brace/theme/textmate";
import "brace/theme/tomorrow";
import "brace/theme/twilight";
import "brace/theme/xcode";
import "brace/keybinding/vim";
import "brace/keybinding/emacs";
import * as Cookies from "../utils/cookies";
import $ from "jquery";

export default class SignatureTable extends React.Component {
    constructor(props) {
        super(props);
        let key = new Date();
        key = key.getTime();
        let value = "";
        let currentKeyboardHandler = "none";
        let currentLanguageMode = "java";
        let currentEditorTheme = "github";
        let viewVersionid = this.props.headerData.prod_sigbody_id;
        let viewSigBodyid;
        if (Cookies.checkCookie("signatureKeyboardHandler") !== undefined) {
            currentKeyboardHandler = Cookies.checkCookie("signatureKeyboardHandler");
        }
        if (Cookies.checkCookie("signatureLanguageMode") !== undefined) {
            currentLanguageMode = Cookies.checkCookie("signatureLanguageMode");
        }
        if (Cookies.checkCookie("signatureEditorTheme") !== undefined) {
            currentEditorTheme = Cookies.checkCookie("signatureEditorTheme");
        }
        if (
            Object.keys(this.props.headerData.version).length !== 0 &&
            this.props.headerData.version.constructor !== Object
        ) {
            //if (!jQuery.isEmptyObject(this.props.headerData.version)) {
            if (
                this.props.headerData.version[this.props.headerData.data.prod_sigbody_id] !==
                undefined ||
                this.props.headerData.version[this.props.headerData.data.prod_sigbody_id] ===
                0
            ) {
                value = this.props.headerData.version[
                    this.props.headerData.data.prod_sigbody_id
                ].body;
                viewSigBodyid = this.props.headerData.version[
                    this.props.headerData.data.prod_sigbody_id
                ].id;
            } else {
                for (let key in this.props.headerData.version) {
                    if (key < viewVersionid) {
                        continue;
                    } else {
                        viewVersionid = key;
                        value = this.props.headerData.version[key].body;
                        viewSigBodyid = this.props.headerData.version[key].id;
                    }
                }
            }
        }
        this.state = {
            readOnly: true,
            value: value,
            signatureData: this.props.headerData,
            loaded: true,
            viewSigBodyid: viewSigBodyid,
            viewVersionid: viewVersionid,
            lastViewVersionid: null,
            key: key,
            cursorEnabledDisabled: "cursorDisabled",
            keyboardHandlers: ["none", "vim", "emacs"],
            currentKeyboardHandler: currentKeyboardHandler,
            languageModes: [
                "bro",
                "csharp",
                "c_cpp",
                "html",
                "javascript",
                "java",
                "json",
                "markdown",
                "mysql",
                "perl",
                "powershell",
                "python",
                "ruby",
                "sass",
                "xml",
                "yaml"
            ],
            currentLanguageMode: currentLanguageMode,
            editorThemes: [
                "github",
                "monokai",
                "kuroir",
                "solarized_dark",
                "solarized_light",
                "terminal",
                "textmate",
                "tomorrow",
                "twilight",
                "xcode"
            ],
            currentEditorTheme: currentEditorTheme,
            ajaxType: null
        };
    }

    onChange(value) {
        this.setState({ value: value });
    }

    submitSigBody = e => {
        let url = "scot/api/v2/sigbody/";
        let versionid = this.state.viewVersionid; //version revision if creating a new sigbody
        if (this.state.ajaxType === "put") {
            versionid = this.state.viewSigBodyid; //version id (not revision id) if editing an existing sigbody
            url = "scot/api/v2/sigbody/" + versionid;
        }
        $.ajax({
            type: this.state.ajaxType,
            url: url,
            data: JSON.stringify({
                signature_id: parseInt(this.props.id, 10),
                body: this.state.value
            }),
            contentType: "application/json; charset=UTF-8",
            success: function (data) {
                console.log("successfully changed signature data");
                let viewVersionid;
                if (data.revision === undefined) {
                    viewVersionid = this.state.viewVersionid;
                } else {
                    viewVersionid = data.revision;
                }
                this.setState({
                    readOnly: true,
                    cursorEnabledDisabled: "cursorDisabled",
                    ajaxType: null,
                    viewVersionid: viewVersionid,
                    viewSigBodyid: data.id
                });
            }.bind(this),
            error: function (data) {
                this.props.errorToggle("Failed to create/update sigbody", data);
            }.bind(this)
        });
    };

    componentWillReceiveProps = nextProps => {
        this.setState({ signatureData: nextProps.headerData });
    };

    editSigBody = e => {
        this.setState({
            readOnly: false,
            lastViewVersionid: this.state.viewVersionid,
            cursorEnabledDisabled: "cursorEnabled",
            ajaxType: "put"
        });
    };

    createNewSigBody = () => {
        this.setState({
            readOnly: false,
            viewVersionid: null,
            lastViewVersionid: this.state.viewVersionid,
            value: "",
            cursorEnabledDisabled: "cursorEnabled",
            ajaxType: "post"
        });
    };

    createNewSigBodyFromSig = () => {
        this.setState({
            readOnly: false,
            lastViewVersionid: this.state.viewVersionid,
            cursorEnabledDisabled: "cursorEnabled",
            ajaxType: "post",
            viewVersionid: null
        });
    };

    Cancel = () => {
        let value = "";
        if (
            Object.keys(this.state.signatureData.version).length !== 0 &&
            this.state.signatureData.version.constructor !== Object
        ) {
            // if (!jQuery.isEmptyObject(this.state.signatureData.version)) {
            if (
                this.state.signatureData.version[
                this.state.signatureData.data.prod_sigbody_id
                ] !== undefined
            ) {
                value = this.state.signatureData.version[this.state.lastViewVersionid]
                    .body;
            }
        }
        this.setState({
            readOnly: true,
            value: value,
            viewVersionid: this.state.lastViewVersionid,
            cursorEnabledDisabled: "cursorDisabled",
            ajaxType: null
        });
    };

    viewSigBody = e => {
        if (this.state.readOnly === true) {
            //only allow button click if you can't edit the signature
            this.setState({
                value: this.state.signatureData.version[e.target.id].body,
                viewVersionid: e.target.id,
                viewSigBodyid: e.target.viewSigBodyid
            });
        }
    };

    keyboardHandlerUpdate = e => {
        Cookies.setCookie("signatureKeyboardHandler", e.target.text, 1000);
        this.setState({ currentKeyboardHandler: e.target.text });
    };

    languageModeUpdate = e => {
        Cookies.setCookie("signatureLanguageMode", e.target.text, 1000);
        this.setState({ currentLanguageMode: e.target.text });
    };

    editorThemeUpdate = e => {
        Cookies.setCookie("signatureEditorTheme", e.target.text, 1000);
        this.setState({ currentEditorTheme: e.target.text });
    };

    render = () => {
        let versionsArray = [];
        let keyboardHandlersArray = [];
        let languageModesArray = [];
        let editorThemesArray = [];
        let not_saved_signature_entry_id =
            "not_saved_signature_entry_" + this.state.key;
        let currentKeyboardHandlerApplied = this.state.currentKeyboardHandler;
        let viewVersionid = [];
        let highestVersionid = 0;
        if (
            Object.keys(this.state.signatureData).length !== 0 &&
            this.state.signatureData.constructor !== Object
        ) {
            //if (!jQuery.isEmptyObject(this.state.signatureData)) {
            if (
                Object.keys(this.state.signatureData.version).length !== 0 &&
                this.state.signatureData.version.constructor !== Object
            ) {
                //if (!jQuery.isEmptyObject(this.state.signatureData.version)) {
                for (let key in this.state.signatureData.version) {
                    let versionidrevision = this.state.signatureData.version[key]
                        .revision;
                    let versionidrevisionprodqual = this.state.signatureData.version[key]
                        .revision;
                    let versionidSigBodyid = this.state.signatureData.version[key].id;
                    if (this.state.signatureData.data.prod_sigbody_id === versionidrevision) {
                        versionidrevisionprodqual = versionidrevision + " - Production";
                    } else if (
                        this.state.signatureData.data.qual_sigbody_id === versionidrevision
                    ) {
                        versionidrevisionprodqual = versionidrevision + " - Quality";
                    } //add production and quality text to identify current status on the menu
                    let disabled;
                    if (this.state.readOnly === true) {
                        disabled = false;
                    } else {
                        disabled = true;
                    }
                    versionsArray.push(
                        <MenuItem
                            id={versionidrevision}
                            key={versionidrevision}
                            onClick={this.viewSigBody}
                            eventKey={versionidrevision}
                            viewSigBodyid={versionidSigBodyid}
                            bsSize={"xsmall"}
                            disabled={disabled}
                        >
                            {versionidrevisionprodqual}
                        </MenuItem>
                    );
                    if (versionidrevision > highestVersionid) {
                        highestVersionid = versionidrevision;
                    }
                }
            }
        }

        if (this.state.keyboardHandlers !== undefined) {
            for (let i = 0; i < this.state.keyboardHandlers.length; i++) {
                keyboardHandlersArray.push(
                    <MenuItem
                        id={i}
                        key={i}
                        onClick={this.keyboardHandlerUpdate}
                        eventKey={i}
                        bsSize={"xsmall"}
                    >
                        {this.state.keyboardHandlers[i]}
                    </MenuItem>
                );
            }
        }

        if (this.state.currentKeyboardHandler === "none") {
            currentKeyboardHandlerApplied = null;
        }

        if (this.state.languageModes !== undefined) {
            for (let i = 0; i < this.state.languageModes.length; i++) {
                languageModesArray.push(
                    <MenuItem
                        id={i}
                        key={i}
                        onClick={this.languageModeUpdate}
                        eventKey={i}
                        bsSize={"xsmall"}
                    >
                        {this.state.languageModes[i]}
                    </MenuItem>
                );
            }
        }

        if (this.state.editorThemes !== undefined) {
            for (let i = 0; i < this.state.editorThemes.length; i++) {
                editorThemesArray.push(
                    <MenuItem
                        id={i}
                        key={i}
                        onClick={this.editorThemeUpdate}
                        eventKey={i}
                        bsSize={"xsmall"}
                    >
                        {this.state.editorThemes[i]}
                    </MenuItem>
                );
            }
        }
        if (this.state.signatureData.data.prod_sigbody_id === this.state.viewVersionid) {
            viewVersionid.push(
                <span className="signature_production_color">
                    {this.state.viewVersionid} - Production
        </span>
            );
        } else if (
            this.state.signatureData.data.qual_sigbody_id === this.state.viewVersionid
        ) {
            viewVersionid.push(
                <span className="signature_quality_color">
                    {this.state.viewVersionid} - Quality
        </span>
            );
        } else {
            viewVersionid.push(<span>{this.state.viewVersionid}</span>);
        }
        return (
            <div id={"signatureDetail"} className="signatureDetail">
                {this.state.loaded ? (
                    <div>
                        <SignatureMetaData
                            signatureData={this.state.signatureData}
                            type={this.props.type}
                            id={this.props.id}
                            currentLanguageMode={this.state.currentLanguageMode}
                            currentEditorTheme={this.state.currentEditorTheme}
                            currentKeyboardHandlerApplied={currentKeyboardHandlerApplied}
                            errorToggle={this.props.errorToggle}
                            showSignatureOptions={this.props.showSignatureOptions}
                        />
                        <div
                            id={not_saved_signature_entry_id}
                            className={"not_saved_signature_entry"}
                        >
                            <div
                                className={"row-fluid signature-entry-outer"}
                                style={{ marginLeft: "auto", marginRight: "auto" }}
                            >
                                <div className={"row-fluid signature-entry-header"}>
                                    <div className="signature-entry-header-inner">
                                        Signature Body: {viewVersionid}
                                        <span
                                            className="pull-right"
                                            style={{ display: "inline-flex", paddingRight: "3px" }}
                                        >
                                            Editor Theme:
                      <DropdownButton
                                                bsSize={"xsmall"}
                                                title={this.state.currentEditorTheme}
                                                id="bg-nested-dropdown"
                                                style={{ marginRight: "10px" }}
                                            >
                                                {editorThemesArray}
                                            </DropdownButton>
                                            Language Handler:
                      <DropdownButton
                                                bsSize={"xsmall"}
                                                title={this.state.currentLanguageMode}
                                                id="bg-nested-dropdown"
                                                style={{ marginRight: "10px" }}
                                            >
                                                {languageModesArray}
                                            </DropdownButton>
                                            Keyboard Handler:
                      <DropdownButton
                                                bsSize={"xsmall"}
                                                title={this.state.currentKeyboardHandler}
                                                id="bg-nested-dropdown"
                                                style={{ marginRight: "10px" }}
                                            >
                                                {keyboardHandlersArray}
                                            </DropdownButton>
                                            Signature Body Version:
                      <DropdownButton
                                                bsSize={"xsmall"}
                                                title={viewVersionid}
                                                id="bg-nested-dropdown"
                                                style={{ marginRight: "10px" }}
                                            >
                                                {versionsArray}
                                            </DropdownButton>
                                            {this.state.readOnly ? (
                                                <span>
                                                    <Button
                                                        bsSize={"xsmall"}
                                                        onClick={this.createNewSigBody}
                                                        bsStyle={"success"}
                                                    >
                                                        Create new version
                          </Button>
                                                    {this.state.viewVersionid !== 0 ? (
                                                        <span>
                                                            <Button
                                                                bsSize={"xsmall"}
                                                                onClick={this.createNewSigBodyFromSig}
                                                            >
                                                                Create new version using this base
                              </Button>
                                                            <Button
                                                                bsSize={"xsmall"}
                                                                onClick={this.editSigBody}
                                                            >
                                                                Update displayed version
                              </Button>
                                                        </span>
                                                    ) : null}
                                                </span>
                                            ) : (
                                                    <span>
                                                        <Button
                                                            bsSize={"xsmall"}
                                                            onClick={this.submitSigBody}
                                                        >
                                                            Submit
                          </Button>
                                                        <Button bsSize={"xsmall"} onClick={this.Cancel}>
                                                            Cancel
                          </Button>
                                                    </span>
                                                )}
                                        </span>
                                    </div>
                                </div>
                                <AceEditor
                                    mode={this.state.currentLanguageMode}
                                    theme={this.state.currentEditorTheme}
                                    onChange={this.onChange}
                                    name="signatureEditor"
                                    editorProps={{ $blockScrolling: true }}
                                    keyboardHandler={currentKeyboardHandlerApplied}
                                    value={this.state.value}
                                    width="100%"
                                    maxLines={50}
                                    minLines={10}
                                    readOnly={this.state.readOnly}
                                    className={this.state.cursorEnabledDisabled}
                                    showPrintMargin={false}
                                />
                            </div>
                        </div>
                    </div>
                ) : (
                        <div>Loading Signature Data...</div>
                    )}
            </div>
        );
    };
}

class SignatureMetaData extends React.Component {
    constructor(props) {
        super(props);
        this.state = {
            optionsValue: JSON.stringify(this.props.signatureData.options)
        };
    }

    submitMetaData = event => {
        let k = event.target.id;
        let v = event.target.value;
        if (k === "options" || k === "target") {
            try {
                v = JSON.parse(v);
            } catch (err) {
                this.props.errorToggle(
                    "Failed to convert string to object. Try adding quotation marks around the key and values"
                );
                return;
            }
            let optionsType = typeof v;
            if (optionsType !== "object") {
                this.props.errorToggle(
                    "options need to be an object but were detected as: " + optionsType
                );
                return;
            }
        } //Convery v to JSON for options as its type is JSON
        let json = {};
        json[k] = v;
        $.ajax({
            type: "put",
            url: "scot/api/v2/signature/" + this.props.id,
            data: JSON.stringify(json),
            contentType: "application/json; charset=UTF-8",
            success: function (data) {
                console.log("successfully changed signature data");
            },
            error: function (data) {
                this.props.errorToggle("Failed to update signature metadata", data);
            }.bind(this)
        });
    };

    onOptionsChange = optionsValue => {
        this.setState({ optionsValue: optionsValue });
    };

    render = () => {
        return (
            <div>
                {this.props.showSignatureOptions ? (
                    <div id="signatureTable2" className="signatureTableOptions">
                        <div
                            className={"row-fluid signature-entry-outer"}
                            style={{ marginLeft: "auto", marginRight: "auto" }}
                        >
                            <div className={"row-fluid signature-entry-header"}>
                                <div className="signature-entry-header-inner">
                                    Signature Options
                  <Button
                                        type="submit"
                                        bsSize="xsmall"
                                        bsStyle="success"
                                        onClick={this.submitMetaData}
                                        id={"options"}
                                        value={this.state.optionsValue}
                                    >
                                        Apply
                  </Button>
                                </div>
                            </div>
                            <AceEditor
                                mode="json"
                                theme={this.props.currentEditorTheme}
                                onChange={this.onOptionsChange}
                                name="signatureEditorOptions"
                                editorProps={{ $blockScrolling: true }}
                                keyboardHandler={this.props.currentKeyboardHandlerApplied}
                                value={this.state.optionsValue}
                                minLines={10}
                                maxLines={25}
                                width="100%"
                                readOnly={false}
                                showPrintMargin={false}
                            />
                        </div>
                    </div>
                ) : null}
            </div>
        );
    };
}

class SignatureGroup extends React.Component {
    constructor(props) {
        super(props);
        this.state = {
            signatureGroupValue: ""
        };
    }

    handleAddition = signature_group => {
        let newSignatureGroupArr = [];
        let data = this.props.data;
        for (let i = 0; i < data.length; i++) {
            if (data[i] != undefined) {
                if (typeof data[i] == "string") {
                    newSignatureGroupArr.push(data[i]);
                } else {
                    newSignatureGroupArr.push(data[i].value);
                }
            }
        }
        newSignatureGroupArr.push(signature_group.target.value);
        $.ajax({
            type: "put",
            url: "scot/api/v2/signature/" + this.props.id,
            data: JSON.stringify({ signature_group: newSignatureGroupArr }),
            contentType: "application/json; charset=UTF-8",
            success: function (data) {
                console.log("success: signature_group added");
                this.setState({ signatureGroupValue: "" });
            }.bind(this),
            error: function (data) {
                this.props.errorToggle("Failed to add signature_group", data);
            }.bind(this)
        });
    };

    InputChange = event => {
        this.setState({ signatureGroupValue: event.target.value });
    };

    handleDelete = event => {
        let data = this.props.data;
        let clickedThing = event.target.id;
        let newSignatureGroupArr = [];
        for (let i = 0; i < data.length; i++) {
            if (data[i] !== undefined) {
                if (typeof data[i] === "string") {
                    if (data[i] !== clickedThing) {
                        newSignatureGroupArr.push(data[i]);
                    }
                } else {
                    if (data[i].value !== clickedThing) {
                        newSignatureGroupArr.push(data[i].value);
                    }
                }
            }
        }
        $.ajax({
            type: "put",
            url: "scot/api/v2/signature/" + this.props.id,
            data: JSON.stringify({ signature_group: newSignatureGroupArr }),
            contentType: "application/json; charset=UTF-8",
            success: function (data) {
                console.log("deleted signature_group success: " + data);
            },
            error: function (data) {
                this.props.errorToggle("Failed to delete signature_group", data);
            }.bind(this)
        });
    };

    render = () => {
        let data = this.props.data;
        let signatureGroupArr = [];
        let value;
        for (let i = 0; i < data.length; i++) {
            if (typeof data[i] === "string") {
                value = data[i];
            } else if (typeof data[i] === "object") {
                if (data[i] !== undefined) {
                    value = data[i].value;
                }
            }
            signatureGroupArr.push(
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
        return (
            <div className="col-lg-2 col-md-4">
                <span className="signatureTableWidth">Signature Group:</span>
                <span className="signatureTableWidth">
                    <input
                        id={this.props.metaType}
                        onChange={this.InputChange}
                        value={this.state.signatureGroupValue}
                    />
                    {this.state.signatureGroupValue !== "" ? (
                        <Button
                            bsSize="xsmall"
                            bsStyle="success"
                            onClick={this.handleAddition}
                            value={this.state.signatureGroupValue}
                        >
                            Submit
            </Button>
                    ) : (
                            <Button bsSize="xsmall" bsType="submit" disabled>
                                Submit
            </Button>
                        )}
                </span>
                {signatureGroupArr}
            </div>
        );
    };
}
