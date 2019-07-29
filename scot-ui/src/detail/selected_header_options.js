import React from "react";
import $ from "jquery";
import ButtonGroup from "react-bootstrap/lib/ButtonGroup.js";
import Button from "react-bootstrap/lib/Button.js";
import Promote from "../components/promote.js";
import Marker from "../components/marker.js";
import TrafficLightProtocol from "../components/traffic_light_protocol.js";
import { CSVLink } from "react-csv";
import { put_data } from "../utils/XHR";

export default class SelectedHeaderOptions extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      globalFlairState: true,
      promoteRemaining: null,
      dataToDownload: []
    };
  }

  toggleFlair = () => {
    let newGlobalFlairState = !this.state.globalFlairState;
    this.props.toggleFlair();
    $("iframe").each(
      function(index, ifr) {
        if (ifr.contentDocument != null) {
          let ifrContents = $(ifr).contents();
          let off = ifrContents.find(".entity-off");
          let on = ifrContents.find(".entity");
          if (this.state.globalFlairState === false) {
            ifrContents.find(".extras").show();
            ifrContents.find(".flair-off").hide();
            off.each(function(index, entity) {
              $(entity).addClass("entity");
              $(entity).removeClass("entity-off");
            });
          } else {
            ifrContents.find(".extras").hide();
            ifrContents.find(".flair-off").show();
            on.each(function(index, entity) {
              $(entity).addClass("entity-off");
              $(entity).removeClass("entity");
            });
          }
        }
      }.bind(this)
    );
    this.setState({ globalFlairState: newGlobalFlairState });
  };

  //All methods containing alert are only used by selected_entry when viewing an alertgroupand interacting with an alert.
  alertOpenSelected = () => {
    let array = this.props.alertsSelected.map(function(alert) {
      return { id: alert.id, status: "open" };
    });
    let data = { alerts: array };

    this.props.ToggleProcessingMessage(true);
    let endpoint = `/scot/api/v2/${this.props.type}/${this.props.id}`;
    let response = put_data(endpoint, data);
    response
      .then(
        function() {
          console.log("success");
          this.props.ToggleProcessingMessage(false);
        }.bind(this)
      )
      .catch(
        function(data) {
          this.props.errorToggle("failed to open selected alerts", data);
          this.props.ToggleProcessingMessage(false);
        }.bind(this)
      );
  };

  alertCloseSelected = () => {
    let time = Math.round(new Date().getTime() / 1000);
    let array = this.props.alertsSelected.map(function(alert) {
      return { id: alert.id, status: "closed", closed: time };
    });
    let data = { alerts: array };

    this.props.ToggleProcessingMessage(true);

    let endpoint = `/scot/api/v2/${this.props.type}/${this.props.id}`;
    let response = put_data(endpoint, data);
    response
      .then(
        function() {
          console.log("success");
          this.props.ToggleProcessingMessage(false);
        }.bind(this)
      )
      .catch(
        function(data) {
          this.props.errorToggle("failed to open selected alerts", data);
          this.props.ToggleProcessingMessage(false);
        }.bind(this)
      );
  };

  alertPromoteSelected = () => {
    let data = JSON.stringify({ promote: "new" });
    let array = this.props.alertsSelected.map(alert => alert.id);

    this.props.ToggleProcessingMessage(true);

    //Start by promoting the first one in the array
    let endpoint = `/scot/api/v2/alert/${array[0]}`;
    let response = put_data(endpoint, data);
    response.then(
      function(response) {
        let promoteTo = {
          promote: response.data.pid
        };
        if (array.length == 1) {
          this.props.ToggleProcessingMessage(false);
        }
        array.forEach(
          function(alert_id, index) {
            if (index === 0) {
              console.log("promoting rest of alerts");
            } else {
              let endpoint = `/scot/api/v2/alert/${alert_id}`;
              let response2 = put_data(endpoint, promoteTo);
              response2
                .then(
                  function() {
                    if (index + 1 === array.length) {
                      this.props.ToggleProcessingMessage(false);
                    }
                  }.bind(this)
                )
                .catch(
                  function(data) {
                    this.props.errorToggle(
                      "failed to promoted selected alerts",
                      data
                    );
                  }.bind(this)
                );
            }
          }.bind(this)
        );
      }.bind(this)
    );
  };

  alertSelectExisting = () => {
    let text = prompt("Please Enter Event ID to promote into");
    if (text !== "" && text !== null) {
      this.props.alertsSelected.forEach(
        function(alert) {
          let data = { promote: parseInt(text, 10) };
          let endpoint = `/scot/api/v2/alert/${alert.id}`;
          let response = put_data(endpoint, data);
          response
            .then(
              function() {
                window.open("#/event/" + text);
              }.bind(this)
            )
            .catch(
              function() {
                prompt("Please use numbers only");
                this.selectExisting();
              }.bind(this)
            );
        }.bind(this)
      );
    }
  };

  alertExportCSV = () => {
    const currentRecords = this.props.alertsSelected;
    var data_to_download = [];
    currentRecords.forEach(
      function(row) {
        Object.keys(row).forEach(
          function(key) {
            //here lets strip html tags
            if (typeof row[key] === "string") {
              let regex = /(<([^>]+)>)/gi;
              let body = row[key];
              row[key] = body.replace(regex, "");
            }
          }.bind(this)
        );
        data_to_download.push(row);
      }.bind(this)
    );

    this.setState({ dataToDownload: data_to_download }, () => {
      // click the CSVLink component to trigger the CSV download
      this.csvLink.link.click();
    });
  };

  PrintPrepare = () => {
    $("iframe")
      .contents()
      .each(function(x, y) {
        $(y)
          .find("blockquote")
          .each(function(index, block) {
            $(block).css({ "max-height": "5000px" });
          });
        $(y)
          .find("pre")
          .each(function(index, pre) {
            $(pre).css({ "max-height": "5000px", "word-wrap": "break-word" });
          });
      });
    setTimeout(
      function() {
        this.forceUpdate();
      }.bind(this),
      500
    );
    setTimeout(function() {
      $("#print-button").click();
    }, 1000);
  };

  Print = () => {
    window.print();
  };

  componentDidMount = () => {
    //open, close SELECTED alerts
    if (this.props.type === "alertgroup" || this.props.type === "alert") {
      $("#main-detail-container").keydown(
        function(event) {
          if ($("input").is(":focus")) {
            return;
          }
          if (
            event.keyCode === 79 &&
            (event.ctrlKey !== true && event.metaKey !== true)
          ) {
            this.alertOpenSelected();
          }
          if (
            event.keyCode === 67 &&
            (event.ctrlKey !== true && event.metaKey !== true)
          ) {
            this.alertCloseSelected();
          }
        }.bind(this)
      );
    }
    $("#main-detail-container").keydown(
      function(event) {
        if ($("input").is(":focus")) {
          return;
        }
        if (
          event.keyCode === 84 &&
          (event.ctrlKey !== true && event.metaKey !== true)
        ) {
          this.toggleFlair();
        }
      }.bind(this)
    );
  };

  componentWillUnmount = () => {
    $("#main-detail-container").unbind("keydown");
  };

  guideToggle = () => {
    let entityoffset = { top: 0, left: 0 }; //set to 0 so it appears in a default location.
    this.props.flairToolbarToggle(
      this.props.guideID,
      null,
      "guide",
      entityoffset,
      null
    );
  };

  sourceToggle = () => {
    let entityoffset = { top: 0, left: 0 }; //set to 0 so it appears in a default location.
    this.props.flairToolbarToggle(
      this.props.id,
      null,
      "source",
      entityoffset,
      null
    );
  };

  createGuide = () => {
    let data = JSON.stringify({
      subject: "ENTER A GUIDE NAME",
      applies_to: [this.props.subjectName]
    });
    $.ajax({
      type: "POST",
      url: "/scot/api/v2/guide",
      data: data,
      contentType: "application/json; charset=UTF-8",
      success: function(response) {
        window.open("/#/guide/" + response.id);
      },
      error: function(data) {
        this.props.errorToggle("failed to create a new guide", data);
      }.bind(this)
    });
  };
  reparseFlair = () => {
    $.ajax({
      type: "put",
      url: "/scot/api/v2/" + this.props.type + "/" + this.props.id,
      data: JSON.stringify({ parsed: 0 }),
      contentType: "application/json; charset=UTF-8",
      success: function() {
        console.log("reparsing started");
      },
      error: function(data) {
        this.props.errorToggle("failed to reparse flair", data);
      }.bind(this)
    });
  };

  createLinkSignature = () => {
    $.ajax({
      type: "POST",
      url: "/scot/api/v2/signature",
      data: JSON.stringify({
        target: { id: this.props.id, type: this.props.type },
        name: "Name your Signature",
        status: "disabled"
      }),
      contentType: "application/json; charset=UTF-8",
      success: function(response) {
        const url = "/#/signature/" + response.id;
        window.open(url, "_blank");
      },
      error: function(data) {
        this.props.errorToggle("failed to create a signature", data);
      }.bind(this)
    });
  };

  manualUpdate = () => {
    this.props.updated(null, null);
  };

  render = () => {
    const { ...other } = this.props;
    let subjectType = this.props.subjectType;
    let type = this.props.type;
    let id = this.props.id;
    let status = this.props.status;

    let string = "";

    if (this.props.headerData.subject) {
      string = this.props.headerData.subject;
    } else if (this.props.headerData.value) {
      string = this.props.headerData.value;
    } else if (this.props.headerData.name) {
      string = this.props.headerData.name;
    } else if (this.props.headerData.body) {
      string = this.props.headerData.body;
    }

    if (type !== "alertgroup") {
      let newType;
      let showPromote = true;
      if (status !== "promoted") {
        if (type === "alert") {
          newType = "Event";
        } else if (type === "event") {
          newType = "Incident";
        } else if (
          type === "incident" ||
          type === "guide" ||
          type === "intel" ||
          type === "signature" ||
          type === "entity"
        ) {
          showPromote = false;
        }
      } else {
        showPromote = false;
      }
      return (
        <div className="entry-header detail-buttons">
          {type !== "entity" ? (
            <Button
              eventkey="1"
              bsStyle="success"
              onClick={this.props.entryToggle}
              bsSize="xsmall"
            >
              <i className="fa fa-plus-circle" aria-hidden="true" /> Add Entry
            </Button>
          ) : null}
          {type !== "entity" ? (
            <Button
              eventkey="2"
              onClick={this.props.fileUploadToggle}
              bsSize="xsmall"
            >
              <i className="fa fa-upload" aria-hidden="true" /> Upload File
            </Button>
          ) : null}
          <Button eventkey="3" onClick={this.toggleFlair} bsSize="xsmall">
            <i className="fa fa-eye-slash" aria-hidden="true" /> Toggle Flair
          </Button>
          {type === "alertgroup" || type === "event" || type === "intel" ? (
            <Button
              eventkey="4"
              onClick={this.props.viewedByHistoryToggle}
              bsSize="xsmall"
            >
              <img src="/images/clock.png" alt="" /> Viewed By History
            </Button>
          ) : null}
          <Button
            eventkey="5"
            onClick={this.props.changeHistoryToggle}
            bsSize="xsmall"
          >
            <img src="/images/clock.png" alt="" /> {subjectType} History
          </Button>
          {type !== "entity" ? (
            <Button
              eventkey="6"
              onClick={this.props.permissionsToggle}
              bsSize="xsmall"
            >
              <i className="fa fa-users" aria-hidden="true" /> Permissions
            </Button>
          ) : null}
          <TrafficLightProtocol
            type={type}
            id={id}
            tlp={this.props.headerData.tlp}
          />
          <Button
            eventkey="7"
            onClick={this.props.entitiesToggle}
            bsSize="xsmall"
          >
            <span className="entity">__</span> View Entities
          </Button>
          {type === "guide" ? (
            <Button
              eventkey="8"
              onClick={this.props.guideRedirectToAlertListWithFilter}
              bsSize="xsmall"
            >
              <i className="fa fa-table" aria-hidden="true" /> View Related
              Alerts
            </Button>
          ) : null}
          <Button onClick={this.props.linksModalToggle} bsSize="xsmall">
            <i className="fa fa-link" aria-hidden="true" /> Links
          </Button>
          {showPromote ? (
            <Promote
              type={type}
              id={id}
              updated={this.props.updated}
              errorToggle={this.props.errorToggle}
            />
          ) : null}
          {type !== "signature" ? (
            <Button bsSize="xsmall" onClick={this.createLinkSignature}>
              <i className="fa fa-pencil" aria-hidden="true" /> Create & Link
              Signature
            </Button>
          ) : null}
          {type === "signature" ? (
            <Button
              eventkey="11"
              onClick={this.props.showSignatureOptionsToggle}
              bsSize="xsmall"
              bsStyle="warning"
            >
              View Custom Options
            </Button>
          ) : null}
          <Button onClick={this.PrintPrepare} bsSize="xsmall" bsStyle="info">
            <i className="fa fa-print" aria-hidden="true" /> Print
          </Button>
          <Button
            onClick={this.Print}
            style={{ display: "none" }}
            id="print-button"
          />
          <Button
            onClick={this.props.exportToggle}
            bsSize="xsmall"
            id="export-button"
          >
            <i className="fa fa-share" aria-hidden="true" /> Export{" "}
            {subjectType}{" "}
          </Button>
          <Button
            bsStyle="danger"
            eventkey="9"
            onClick={() => this.props.deleteToggle(type)}
            bsSize="xsmall"
          >
            <i className="fa fa-trash" aria-hidden="true" /> Delete{" "}
            {subjectType}
          </Button>
          <ButtonGroup style={{ float: "right" }}>
            <Marker type={type} id={id} string={string} />
            <Button onClick={this.props.markModalToggle} bsSize="xsmall">
              Marked Objects
            </Button>
            <Button
              id="refresh-detail"
              bsStyle="info"
              eventkey="10"
              onClick={this.manualUpdate}
              bsSize="xsmall"
              style={{ float: "right" }}
            >
              <i className="fa fa-refresh" aria-hidden="true" />
            </Button>
          </ButtonGroup>
        </div>
      );
    } else {
      if (this.props.alertsSelected.length > 0) {
        return (
          <div className="entry-header second-menu detail-buttons">
            <Button eventkey="1" onClick={this.toggleFlair} bsSize="xsmall">
              <i className="fa fa-eye-slash" aria-hidden="true" /> Toggle Flair
            </Button>
            <Button eventkey="2" onClick={this.reparseFlair} bsSize="xsmall">
              <i className="fa fa-refresh" aria-hidden="true" /> Reparse Flair
            </Button>
            {this.props.guideID == null ? null : this.props.guideID.length !==
              0 ? (
              <Button eventkey="3" onClick={this.guideToggle} bsSize="xsmall">
                <img src="/images/guide.png" alt="" /> Guide
              </Button>
            ) : (
              <Button eventkey="3" onClick={this.createGuide} bsSize="xsmall">
                <img src="/images/guide.png" alt="" /> Create Guide
              </Button>
            )}
            {this.props.headerData == null ? null : (
              <Button eventkey="4" onClick={this.sourceToggle} bsSize="xsmall">
                <img src="/images/code.png" alt="" /> View Source
              </Button>
            )}
            <Button
              eventkey="5"
              onClick={this.props.entitiesToggle}
              bsSize="xsmall"
            >
              <span className="entity">__</span> View Entities
            </Button>
            {type === "alertgroup" || type === "event" || type === "intel" ? (
              <Button
                eventkey="6"
                onClick={this.props.viewedByHistoryToggle}
                bsSize="xsmall"
              >
                <img src="/images/clock.png" alt="" /> Viewed By History
              </Button>
            ) : null}

            <Button
              eventkey="7"
              onClick={this.props.changeHistoryToggle}
              bsSize="xsmall"
            >
              <img src="/images/clock.png" alt="" /> {subjectType} History
            </Button>
            <TrafficLightProtocol
              type={type}
              id={id}
              tlp={this.props.headerData.tlp}
            />
            <Button
              eventkey="8"
              onClick={this.alertOpenSelected}
              bsSize="xsmall"
              bsStyle="danger"
            >
              <img src="/images/open.png" alt="" /> Open Selected
            </Button>
            <Button
              eventkey="9"
              onClick={this.alertCloseSelected}
              bsSize="xsmall"
              bsStyle="success"
            >
              <i className="fa fa-flag-checkered" aria-hidden="true" /> Close
              Selected
            </Button>
            <Button
              eventkey="10"
              onClick={this.alertPromoteSelected}
              bsSize="xsmall"
              bsStyle="warning"
            >
              <img src="/images/megaphone.png" alt="" /> Promote Selected
            </Button>
            <Button
              eventkey="11"
              onClick={this.alertSelectExisting}
              bsSize="xsmall"
            >
              <img src="/images/megaphone_plus.png" alt="" /> Add Selected to{" "}
              <b>Existing Event</b>
            </Button>
            <CSVLink
              data={this.state.dataToDownload}
              filename="data.csv"
              className="hidden"
              ref={r => (this.csvLink = r)}
              target="_blank"
            />
            <Button eventkey="14" onClick={this.alertExportCSV} bsSize="xsmall">
              <img src="/images/csv_text.png" alt="" /> Export to CSV
            </Button>
            <Button onClick={this.props.linksModalToggle} bsSize="xsmall">
              <i className="fa fa-link" aria-hidden="true" /> Links
            </Button>
            <Marker
              type={type}
              id={id}
              string={string}
              isAlert={true}
              getSelectedAlerts={this.getSelectedAlerts}
              alertsSelected={this.props.alertsSelected}
            />
            <Button bsSize="xsmall" onClick={this.createLinkSignature}>
              <i className="fa fa-pencil" aria-hidden="true" /> Create & Link
              Signature
            </Button>
            <Button onClick={this.PrintPrepare} bsSize="xsmall" bsStyle="info">
              <i className="fa fa-print" aria-hidden="true" /> Print
            </Button>
            <Button
              onClick={this.Print}
              style={{ display: "none" }}
              id="print-button"
            />
            <Button
              eventkey="15"
              onClick={() => this.props.deleteToggle("alert")}
              bsSize="xsmall"
              bsStyle="danger"
            >
              <i className="fa fa-trash" aria-hidden="true" /> Delete Selected
            </Button>
            <Button
              bsStyle="danger"
              eventkey="17"
              onClick={() => this.props.deleteToggle(type)}
              bsSize="xsmall"
            >
              <i className="fa fa-trash" aria-hidden="true" /> Delete{" "}
              {subjectType}
            </Button>
            <ButtonGroup style={{ float: "right" }}>
              <Marker type={type} id={id} string={string} />
              <Button onClick={this.props.markModalToggle} bsSize="xsmall">
                Marked Actions
              </Button>
              <Button
                bsStyle="info"
                eventkey="16"
                onClick={this.manualUpdate}
                bsSize="xsmall"
                style={{ float: "right" }}
              >
                <i className="fa fa-refresh" aria-hidden="true" />
              </Button>
            </ButtonGroup>
          </div>
        );
      } else {
        return (
          <div className="entry-header detail-buttons">
            <Button eventkey="1" onClick={this.toggleFlair} bsSize="xsmall">
              <i className="fa fa-eye-slash" aria-hidden="true" /> Toggle Flair
            </Button>
            <Button eventkey="2" onClick={this.reparseFlair} bsSize="xsmall">
              <i className="fa fa-refresh" aria-hidden="true" /> Reparse Flair
            </Button>
            {this.props.guideID == null ? null : (
              <span>
                {this.props.guideID !== 0 ? (
                  <Button
                    eventkey="3"
                    onClick={this.guideToggle}
                    bsSize="xsmall"
                  >
                    <img src="/images/guide.png" alt="" /> Guide
                  </Button>
                ) : (
                  <Button
                    eventkey="3"
                    onClick={this.createGuide}
                    bsSize="xsmall"
                  >
                    <img src="/images/guide.png" alt="" /> Create Guide
                  </Button>
                )}
              </span>
            )}
            {this.props.headerData == null ? null : (
              <Button eventkey="4" onClick={this.sourceToggle} bsSize="xsmall">
                <img src="/images/code.png" alt="" /> View Source
              </Button>
            )}
            <Button
              eventkey="5"
              onClick={this.props.entitiesToggle}
              bsSize="xsmall"
            >
              <span className="entity">__</span> View Entities
            </Button>
            {type === "alertgroup" || type === "event" || type === "intel" ? (
              <Button
                eventkey="6"
                onClick={this.props.viewedByHistoryToggle}
                bsSize="xsmall"
              >
                <img src="/images/clock.png" alt="" /> Viewed By History
              </Button>
            ) : null}
            <Button
              eventkey="7"
              onClick={this.props.changeHistoryToggle}
              bsSize="xsmall"
            >
              <img src="/images/clock.png" alt="" /> {subjectType} History
            </Button>
            <TrafficLightProtocol
              type={type}
              id={id}
              tlp={this.props.headerData.tlp}
            />
            <Button onClick={this.props.linksModalToggle} bsSize="xsmall">
              <i className="fa fa-link" aria-hidden="true" /> Links
            </Button>
            <Button bsSize="xsmall" onClick={this.createLinkSignature}>
              <i className="fa fa-pencil" aria-hidden="true" /> Create & Link
              Signature
            </Button>
            <Button onClick={this.PrintPrepare} bsSize="xsmall" bsStyle="info">
              <i className="fa fa-print" aria-hidden="true" /> Print
            </Button>
            <Button
              onClick={this.Print}
              style={{ display: "none" }}
              id="print-button"
            />
            <Button
              bsStyle="danger"
              eventkey="8"
              onClick={() => this.props.deleteToggle(type)}
              bsSize="xsmall"
            >
              <i className="fa fa-trash" aria-hidden="true" /> Delete{" "}
              {subjectType}
            </Button>
            <ButtonGroup style={{ float: "right" }}>
              <Marker type={type} id={id} string={string} />
              <Button onClick={this.props.markModalToggle} bsSize="xsmall">
                Marked Actions
              </Button>
              <Button
                bsStyle="info"
                eventkey="9"
                onClick={this.manualUpdate}
                bsSize="xsmall"
                style={{ float: "right" }}
              >
                <i className="fa fa-refresh" aria-hidden="true" />
              </Button>
            </ButtonGroup>
          </div>
        );
      }
    }
  };
}
