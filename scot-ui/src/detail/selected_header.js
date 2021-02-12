import React from "react";
import $ from "jquery";
import DetailDataStatus from "../components/detail_data_status";
import ReactTime from "react-time";
import SelectedHeaderOptions from "./selected_header_options.js";
import { DeleteThingComponent } from "../modal/delete.js";
import Owner from "../modal/owner.js";
import Entities from "../modal/entities.js";
import ChangeHistory from "../modal/change_history.js";
import ViewedByHistory from "../modal/viewed_by_history.js";
import SelectedPermission from "../components/permission.js";
import SelectedEntry from "./selected_entry.js";
import Badge from "../components/badge.js";
import Notification from "react-notification-system";
import AddFlair from "../components/add_flair.js";
import EntityDetail from "../modal/entity_detail.js";
import LinkWarning from "../modal/link_warning.js";
import Links from "../modal/links.js";
import Mark from "../modal/mark.js";
import ExportModal from "../modal/export_event.js";
import PromotedData from "../modal/promoted_data.js";
let InitialAjaxLoad;

export default class SelectedHeader extends React.Component {
  constructor(props) {
    super(props);
    let entityDetailKey = Math.floor(Math.random() * 1000);
    this.state = {
      showEventData: false,
      headerData: {},
      sourceData: "",
      tagData: "",
      permissionsToolbar: false,
      entitiesToolbar: false,
      changeHistoryToolbar: false,
      viewedByHistoryToolbar: false,
      entryToolbar: false,
      deleteToolbar: false,
      deleteType: null,
      promoteToolbar: false,
      notificationType: null,
      notificationMessage: null,
      key: this.props.id,
      showEntryData: false,
      entryData: "",
      showEntityData: false,
      entityData: [],
      entryEntityData: null,
      entityid: null,
      entitytype: null,
      entityoffset: null,
      entityobj: null,
      flairToolbar: false,
      linkWarningToolbar: false,
      exportModal: false,
      refreshing: false,
      loading: false,
      eventLoaded: false,
      entryLoaded: false,
      entityLoaded: false,
      guideID: null,
      fileUploadToolbar: false,
      isNotFound: false,
      runWatcher: false,
      entityDetailKey: entityDetailKey,
      processing: false,
      showSignatureOptions: false,
      showMarkModal: false,
      showLinksModal: false,
      flairOff: false,
      highlightedText: "",
      flairing: false,
      isMounted: false,
      alertsSelected: [],
      isDeleted: false
    };
  }

  componentWillMount() {
    this.setState({ loading: true });
  }

  componentDidMount() {
    this.setState({ isMounted: true });
    let delayFunction = {
      delay: function() {
        let entryType = "entry";
        if (this.props.type === "alertgroup") {
          entryType = "alert";
        }
        //Main Type Load
        $.ajax({
          type: "get",
          url: "scot/api/v2/" + this.props.type + "/" + this.props.id,
          success: function(result) {
            if (this.state.isMounted) {
              let eventResult = result;
              this.setState({
                headerData: eventResult,
                showEventData: true,
                isNotFound: false,
                tagData: eventResult.tag,
                sourceData: eventResult.source
              });
              if (
                this.state.showEventData === true &&
                this.state.showEntryData === true &&
                this.state.showEntityData === true
              ) {
                this.setState({ loading: false });
              }
              if (
                this.props.type === "alertgroup" &&
                eventResult.parsed === -1
              ) {
                this.setState({ flairing: true });
              } else {
                this.setState({ flairing: false });
              }
            }
          }.bind(this),
          error: function(result) {
            this.setState({ showEventData: true, isNotFound: true });
            if (
              this.state.showEventData === true &&
              this.state.showEntryData === true &&
              this.state.showEntityData === true
            ) {
              this.setState({ loading: false });
            }
            this.props.errorToggle(
              "Error: Failed to load detail data. Error message: " +
                result.responseText,
              result
            );
          }.bind(this)
        });
        //entry load
        $.ajax({
          type: "get",
          url:
            "scot/api/v2/" +
            this.props.type +
            "/" +
            this.props.id +
            "/" +
            entryType,
          success: function(result) {
            if (this.state.isMounted) {
              let entryResult = result.records;
              // entryResult.forEach(
              //   function(item) {
              //     this.props.createCallback(item.id, this.updated);
              //   }.bind(this)
              // );
              this.setState({
                showEntryData: true,
                entryData: entryResult,
                runWatcher: true
              });
              this.Watcher();
              if (
                this.state.showEventData === true &&
                this.state.showEntryData === true &&
                this.state.showEntityData === true
              ) {
                this.setState({ loading: false });
              }
            }
          }.bind(this),
          error: function(result) {
            this.setState({ showEntryData: true });
            if (
              this.state.showEventData == true &&
              this.state.showEntryData == true &&
              this.state.showEntityData == true
            ) {
              this.setState({ loading: false });
            }
            this.props.errorToggle(
              "Error: Failed to load entry data. Error message: " +
                result.responseText,
              result
            );
          }
        });
        //entity load
        $.ajax({
          type: "get",
          url:
            "scot/api/v2/" + this.props.type + "/" + this.props.id + "/entity",
          success: function(result) {
            if (this.state.isMounted) {
              let entityResult = result.records;
              this.setState({ showEntityData: true, entityData: entityResult });
              var waitForEntry = {
                waitEntry: function() {
                  if (this.state.showEntryData == false) {
                    setTimeout(waitForEntry.waitEntry, 50);
                  } else {
                    setTimeout(
                      function() {
                        AddFlair.entityUpdate(
                          entityResult,
                          this.flairToolbarToggle,
                          this.props.type,
                          this.linkWarningToggle,
                          this.props.id,
                          this.scrollTo
                        );
                      }.bind(this)
                    );
                    if (
                      this.state.showEventData == true &&
                      this.state.showEntryData == true &&
                      this.state.showEntityData == true
                    ) {
                      this.setState({ loading: false });
                    }
                  }
                }.bind(this)
              };
              waitForEntry.waitEntry();
            }
          }.bind(this),
          error: function(result) {
            this.setState({ showEntityData: true });
            if (
              this.state.showEventData == true &&
              this.state.showEntryData == true &&
              this.state.showEntityData == true
            ) {
              this.setState({ loading: false });
            }
            this.props.errorToggle(
              "Error: Failed to load entity data.",
              result
            );
          }.bind(this)
        });
        //guide load
        if (this.props.type == "alertgroup") {
          $.ajax({
            type: "get",
            url:
              "scot/api/v2/" + this.props.type + "/" + this.props.id + "/guide",
            success: function(result) {
              if (this.state.isMounted) {
                let arr = [];
                for (let i = 0; i < result.records.length; i++) {
                  arr.push(result.records[i].id);
                }
                if (arr.length === 0) {
                  arr = null;
                }
                this.setState({ guideID: arr });
              }
            }.bind(this),
            error: function(result) {
              this.setState({ guideID: null });
              this.props.errorToggle(
                "Error: Failed to load guide data. Error message:" +
                  result.responseText,
                result
              );
            }.bind(this)
          });
        }
        this.props.createCallback(this.props.id, this.updated);
      }.bind(this)
    };
    InitialAjaxLoad = setTimeout(delayFunction.delay, 400);
  }

  componentWillUnmount() {
    this.setState({ isMounted: false });
    clearTimeout(InitialAjaxLoad);
    if (this.state.entryData.forEach === "function") {
      this.state.entryData.forEach(
        function(entry) {
          this.props.removeCallback(entry.id);
        }.bind(this)
      );
    }
  }

  componentDidUpdate() {
    //This runs the watcher which handles the entity popup and link warning.
    if (this.state.runWatcher === true) {
      this.Watcher();
    }
  }

  updated = (_type, _message) => {
    this.setState({
      refreshing: true,
      eventLoaded: false,
      entryLoaded: false,
      entityLoaded: false
    });
    let entryType = "entry";
    if (this.props.type == "alertgroup") {
      entryType = "alert";
    }
    //main type load
    $.ajax({
      type: "get",
      url: "scot/api/v2/" + this.props.type + "/" + this.props.id,
      success: function(result) {
        if (this.state.isMounted) {
          let eventResult = result;
          this.setState({
            headerData: eventResult,
            showEventData: true,
            eventLoaded: true,
            isNotFound: false,
            tagData: eventResult.tag,
            sourceData: eventResult.source
          });
          if (
            this.state.eventLoaded == true &&
            this.state.entryLoaded == true &&
            this.state.entityLoaded == true
          ) {
            this.setState({ refreshing: false });
          }
          if (this.props.type == "alertgroup" && eventResult.parsed === -1) {
            this.setState({ flairing: true });
          } else {
            this.setState({ flairing: false });
          }
        }
      }.bind(this),
      error: function(result) {
        this.setState({
          showEventData: true,
          eventLoaded: true,
          isNotFound: true
        });
        if (
          this.state.eventLoaded == true &&
          this.state.entryLoaded == true &&
          this.state.entityLoaded == true
        ) {
          this.setState({ refreshing: false });
        }
        this.props.errorToggle(
          "Error: Failed to reload detail data. Error message: " +
            result.responseText,
          result
        );
      }.bind(this)
    });
    //entry load
    $.ajax({
      type: "get",
      url:
        "scot/api/v2/" +
        this.props.type +
        "/" +
        this.props.id +
        "/" +
        entryType,
      success: function(result) {
        if (this.state.isMounted) {
          let entryResult = result.records;
          this.setState({
            showEntryData: true,
            entryLoaded: true,
            entryData: entryResult,
            runWatcher: true
          });
          this.Watcher();
          if (
            this.state.eventLoaded == true &&
            this.state.entryLoaded == true &&
            this.state.entityLoaded == true
          ) {
            this.setState({ refreshing: false });
          }
        }
      }.bind(this),
      error: function(result) {
        this.setState({ showEntryData: true, entryLoaded: true });
        if (
          this.state.eventLoaded == true &&
          this.state.entryLoaded == true &&
          this.state.entityLoaded == true
        ) {
          this.setState({ refreshing: false });
        }
        this.props.errorToggle(
          "Error: Failed to reload entry data. Error message: " +
            result.responseText,
          result
        );
      }
    });
    //entity load
    $.ajax({
      type: "get",
      url: "scot/api/v2/" + this.props.type + "/" + this.props.id + "/entity",
      success: function(result) {
        if (this.state.isMounted) {
          let entityResult = result.records;
          this.setState({
            showEntityData: true,
            entityLoaded: true,
            entityData: entityResult
          });
          var waitForEntry = {
            waitEntry: function() {
              if (this.state.entryLoaded == false) {
                setTimeout(waitForEntry.waitEntry, 50);
              } else {
                setTimeout(
                  function() {
                    AddFlair.entityUpdate(
                      entityResult,
                      this.flairToolbarToggle,
                      this.props.type,
                      this.linkWarningToggle,
                      this.props.id
                    );
                  }.bind(this)
                );
                if (
                  this.state.eventLoaded == true &&
                  this.state.entryLoaded == true &&
                  this.state.entityLoaded == true
                ) {
                  this.setState({ refreshing: false });
                }
              }
            }.bind(this)
          };
          waitForEntry.waitEntry();
        }
      }.bind(this),
      error: function(result) {
        this.setState({ showEntityData: true });
        if (
          this.state.eventLoaded == true &&
          this.state.entryLoaded == true &&
          this.state.entityLoaded == true
        ) {
          this.setState({ refreshing: false });
        }
        this.props.errorToggle("Error: Failed to reload entity data.", result);
      }.bind(this)
    });
    //error popup if an error occurs
    if (_type != undefined && _message != undefined) {
      this.props.errorToggle(_message);
    }
  };

  flairToolbarToggle = (id, value, type, entityoffset, entityobj) => {
    this.setState({
      flairToolbar: true,
      entityid: id,
      entityvalue: value,
      entitytype: type,
      entityoffset: entityoffset,
      entityobj: entityobj
    });
  };

  flairToolbarOff = () => {
    if (this.state.isMounted) {
      let newEntityDetailKey = this.state.entityDetailKey + 1;
      this.setState({
        flairToolbar: false,
        entityDetailKey: newEntityDetailKey
      });
    }
  };

  linkWarningToggle = (href, nopop=false) => {
    if (this.state.linkWarningToolbar === false) {
      this.setState({ linkWarningToolbar: true, link: href, nopop: nopop });
    } else {
      this.setState({ linkWarningToolbar: false, nopop: nopop });
    }
  };

  exportToggle = () => {
    if (this.state.exportModal === false) {
      this.setState({ exportModal: true });
    } else {
      this.setState({ exportModal: false });
    }
  };

  viewedbyfunc = headerData => {
    let viewedbyarr = [];
    if (headerData !== null) {
      for (let prop in headerData.view_history) {
        viewedbyarr.push(prop);
      }
    }
    return viewedbyarr;
  };

  entryToggle = () => {
    if (this.state.entryToolbar === false) {
      this.setState({ entryToolbar: true });
    } else {
      this.setState({ entryToolbar: false });
    }
  };

  deleteToggle = (type, isDeleted) => {
    if (this.state.deleteToolbar === false) {
      this.setState({ deleteToolbar: true, deleteType: type });
    } else {
      this.setState({ deleteToolbar: false, deleteType: type });
    }
    if (isDeleted) {
      this.setState({ isDeleted: true });
    }
  };

  changeHistoryToggle = () => {
    if (this.state.changeHistoryToolbar === false) {
      this.setState({ changeHistoryToolbar: true });
    } else {
      this.setState({ changeHistoryToolbar: false });
    }
  };

  viewedByHistoryToggle = () => {
    if (this.state.viewedByHistoryToolbar === false) {
      this.setState({ viewedByHistoryToolbar: true });
    } else {
      this.setState({ viewedByHistoryToolbar: false });
    }
  };

  permissionsToggle = () => {
    if (this.state.permissionsToolbar === false) {
      this.setState({ permissionsToolbar: true });
    } else {
      this.setState({ permissionsToolbar: false });
    }
  };

  entitiesToggle = () => {
    if (this.state.entitiesToolbar === false) {
      this.setState({ entitiesToolbar: true });
    } else {
      this.setState({ entitiesToolbar: false, entryEntityData: null });
    }
  };

  promoteToggle = () => {
    if (this.state.promoteToolbar === false) {
      this.setState({ promoteToolbar: true });
    } else {
      this.setState({ promoteToolbar: false });
    }
  };

  fileUploadToggle = () => {
    if (this.state.fileUploadToolbar === false) {
      this.setState({ fileUploadToolbar: true });
    } else {
      this.setState({ fileUploadToolbar: false });
    }
  };

  titleCase = string => {
    let newstring = string.charAt(0).toUpperCase() + string.slice(1);
    return newstring;
  };

  Watcher = () => {
    $("iframe").each(
      function(index, ifr) {
        //requestAnimationFrame waits for the frame to be rendered (allowing the iframe to fully render before excuting the next bit of code!!!
        ifr.contentWindow.requestAnimationFrame(
          function() {
            if (ifr.contentDocument !== null) {
              let arr = [];
              //arr.push(this.props.type);
              arr.push(this.checkFlairHover);
              arr.push(this.checkHighlight);
              $(ifr).off("mouseenter");
              $(ifr).off("mouseleave");
              $(ifr).on(
                "mouseenter",
                function(v, type) {
                  let intervalID = setInterval(this[0], 50, ifr); // this.flairToolbarToggle, type, this.props.linkWarningToggle, this.props.id);
                  let intervalID1 = setInterval(this[1], 50, ifr); // this.flairToolbarToggle, type, this.props.linkWarningToggle, this.props.id);
                  $(ifr).data("intervalID", intervalID);
                  $(ifr).data("intervalID1", intervalID1);
                  console.log("Now watching iframe " + intervalID);
                }.bind(arr)
              );
              $(ifr).on("mouseleave", function() {
                let intervalID = $(ifr).data("intervalID");
                let intervalID1 = $(ifr).data("intervalID1");
                window.clearInterval(intervalID);
                window.clearInterval(intervalID1);
                console.log("No longer watching iframe " + intervalID);
              });
            }
          }.bind(this)
        );
      }.bind(this)
    );
    if (this.props.type == "alertgroup") {
      $("#detail-container")
        .find("a, .entity")
        .not(".not_selectable")
        .each(
          function(index, tr) {
            $(tr).off("mousedown");
            $(tr).on(
              "mousedown",
              function(index) {
                let thing = index.target;
                if ($(thing)[0].className == "extras") {
                  thing = $(thing)[0].parentNode;
                } //if an extra is clicked reference the parent element
                if ($(thing).attr("url")) {
                  //link clicked
                  let url = $(thing).attr("url");
                  this.linkWarningToggle(url);
                } else {
                  //entity clicked
                  let entityid = $(thing).attr("data-entity-id");
                  let entityvalue = $(thing).attr("data-entity-value");
                  let entityoffset = $(thing).offset();
                  let entityobj = $(thing);
                  this.flairToolbarToggle(
                    entityid,
                    entityvalue,
                    "entity",
                    entityoffset,
                    entityobj
                  );
                }
              }.bind(this)
            );
          }.bind(this)
        );
    }
  };

  checkHighlight = ifr => {
    let content;
    if (ifr.contentWindow !== null) {
      content = ifr.contentWindow.getSelection().toString();
      if (this.state.highlightedText != content) {
        //this only tells the lower components to run their componentWIllReceiveProps methods to check for highlighted text.
        this.setState({ highlightedText: content });
      } else {
        return;
      }
    } else {
    }
  };

  checkFlairHover = (ifr, nicktype) => {
    function returnifr() {
      return ifr;
    }
    if (ifr.contentDocument != null) {
      $(ifr)
        .contents()
        .find(".entity")
        .each(
          function(index, entity) {
            if ($(entity).css("background-color") == "rgb(255, 0, 0)") {
              $(entity).data("state", "down");
            } else if ($(entity).data("state") == "down") {
              $(entity).data("state", "up");
              let entityid = $(entity).attr("data-entity-id");
              let entityvalue = $(entity).attr("data-entity-value");
              let entityobj = $(entity);
              let ifr = returnifr();
              let entityoffset = {
                top: $(entity).offset().top + $(ifr).offset().top,
                left: $(entity).offset().left + $(ifr).offset().left
              };
              this.flairToolbarToggle(
                entityid,
                entityvalue,
                "entity",
                entityoffset,
                entityobj
              );
            }
          }.bind(this)
        );
      $(ifr)
        .contents()
        .find("a")
        .each(
          function(index, a) {
            if ($(a).css("color") == "rgb(255, 0, 0)") {
              $(a).data("state", "down");
            } else if ($(a).data("state") == "down") {
              $(a).data("state", "up");
              let url = $(a).attr("url");
              this.linkWarningToggle(url);
            }
          }.bind(this)
        );
    }
  };

  summaryUpdate = () => {
    this.forceUpdate();
  };

  scrollTo = () => {
    if (this.props.taskid !== undefined) {
      $(".entry-wrapper").scrollTop(
        $(".entry-wrapper").scrollTop() +
          $("#iframe_" + this.props.taskid).position().top -
          30
      );
    }
  };

  guideRedirectToAlertListWithFilter = () => {
    RegExp.escape = function(text) {
      return text.replace(/[-[\]{}()*+?.,\\^$|#\s]/g, "\\$&");
    };
    //column, string, clearall (bool), type
    this.props.handleFilter(null, null, true, "alertgroup");
    this.props.handleFilter(
      [
        {
          id: "subject",
          value: RegExp.escape(this.state.headerData.data.applies_to[0])
        }
      ],
      null,
      false,
      "alertgroup"
    );
    window.open("#/alertgroup/");
  };

  setEntryEntities = data => {
    this.entitiesToggle();
    this.setState({ entryEntityData: data });
  };

  showSignatureOptionsToggle = () => {
    if (this.state.showSignatureOptions === false) {
      this.setState({ showSignatureOptions: true });
    } else {
      this.setState({ showSignatureOptions: false });
    }
  };
  markModalToggle = () => {
    if (this.state.showMarkModal === false) {
      this.setState({ showMarkModal: true });
    } else {
      this.setState({ showMarkModal: false });
    }
  };

  ToggleProcessingMessage = status => {
    this.setState({ processing: status });
    this.props.togglePreventClick();
  };

  linksModalToggle = () => {
    let showLinksModal = !this.state.showLinksModal;
    this.setState({ showLinksModal: showLinksModal });
  };

  toggleFlair = () => {
    if (this.state.flairOff) {
      this.setState({ flairOff: false, runWatcher: true });
      setTimeout(
        function() {
          AddFlair.entityUpdate(
            this.state.entityData,
            this.flairToolbarToggle,
            this.props.type,
            this.linkWarningToggle,
            this.props.id
          );
        }.bind(this)
      );
    } else {
      this.setState({ flairOff: true });
    }
  };

  //2019 new alert table stuff
  checkSelection(rowid) {
    if (this.state.alertsSelected.some(item => rowid === item.id)) {
      return true;
    } else {
      return false;
    }
  }

  handleSelection = row => {
    console.log("Got selection click!");
    this.setState({
      alertsSelected: [row]
    });
  };

  handleMultiSelection = row => {
    if (!this.checkSelection(row.id)) {
      let temparray = [...this.state.alertsSelected, row];
      this.setState({
        alertsSelected: temparray
      });
    } else {
      /** item already selected, lets filter out item (uncheck and reset state
      with new array returned from filter**/
      this.setState({
        alertsSelected: this.state.alertsSelected.filter(function(alert) {
          return alert["id"] !== row.id;
        })
      });
    }
  };

  handleSelectAll = data => {
    const selection = data.map(object => object.id);
    this.setState({
      alertsSelected: selection
    });
  };

  handleShiftSelect = (startIndex, endIndex, data) => {
    if (startIndex > endIndex) {
      startIndex = [endIndex, (endIndex = startIndex)][0];
    }
    let temparray = [];
    data.forEach(
      function(row) {
        if (row.id <= endIndex && row.id >= startIndex) {
          if (!this.checkSelection(row)) {
            temparray.push(row);
          }
        }
      }.bind(this)
    );
    this.setState({
      alertsSelected: [...this.state.alertsSelected, ...temparray]
    });
  };

  render() {
    let headerData = this.state.headerData;
    let viewedby = this.viewedbyfunc(headerData);
    let type = this.props.type;
    let subjectType = this.titleCase(this.props.type); //in signatures  and feeds we're using the key "name"
    let id = this.props.id;
    let string = "";

    if (this.state.headerData.subject) {
      string = this.state.headerData.subject;
    } else if (this.state.headerData.value) {
      string = this.state.headerData.value;
    } else if (this.state.headerData.name) {
      string = this.state.headerData.name;
    } else if (this.state.headerData.body) {
      string = this.state.headerData.body;
    }

    return (
      <div>
        {" "}
        {this.state.isNotFound ? (
          <h1>No record found.</h1>
        ) : (
          <div>
            <div id="header">
              <div id="NewEventInfo" className="entry-header-info-null">
                <div
                  className="details-subject"
                  style={{ display: "inline-flex", paddingLeft: "5px" }}
                >
                  {this.state.showEventData ? (
                    <EntryDataSubject
                      data={this.state.headerData}
                      subjectType={subjectType}
                      type={type}
                      id={this.props.id}
                      errorToggle={this.props.errorToggle}
                    />
                  ) : null}
                  {this.state.refreshing ? (
                    <span style={{ color: "lightblue" }}>
                      Refreshing Data...
                    </span>
                  ) : null}
                  {this.state.loading ? (
                    <span style={{ color: "lightblue" }}>Loading...</span>
                  ) : null}
                  {this.state.processing ? (
                    <span style={{ color: "lightblue" }}>
                      Processing Actions...
                    </span>
                  ) : null}
                  {this.state.flairing ? (
                    <span style={{ color: "lightblue" }}>Flairing...</span>
                  ) : null}
                </div>
                {type !== "entity" ? (
                  <div
                    className="details-table toolbar"
                    style={{ display: "flex" }}
                  >
                    <table>
                      <tbody>
                        <tr>
                          <th />
                          <td>
                            <div style={{ marginLeft: "5px" }}>
                              {this.state.showEventData ? (
                                <DetailDataStatus
                                  data={this.state.headerData}
                                  status={this.state.headerData.status}
                                  id={id}
                                  type={type}
                                  errorToggle={this.props.errorToggle}
                                />
                              ) : null}
                            </div>
                          </td>
                          {type !== "entity" ? <th>Owner: </th> : null}
                          {type !== "entity" ? (
                            <td>
                              <span>
                                {this.state.showEventData ? (
                                  <Owner
                                    key={id}
                                    data={this.state.headerData.owner}
                                    type={type}
                                    id={id}
                                    updated={this.updated}
                                    errorToggle={this.props.errorToggle}
                                  />
                                ) : null}
                              </span>
                            </td>
                          ) : null}
                          {type !== "entity" ? <th>Updated: </th> : null}
                          {type !== "entity" ? (
                            <td>
                              <span id="event_updated">
                                {this.state.showEventData ? (
                                  <EntryDataUpdated
                                    data={this.state.headerData.updated}
                                  />
                                ) : null}
                              </span>
                            </td>
                          ) : null}
                          {(type === "event" || type === "incident" || type === "intel" || type === "product") &&
                          this.state.showEventData &&
                          this.state.headerData.promoted_from.length > 0 ? (
                            <th>Promoted From:</th>
                          ) : null}
                          {(type === "event" || type === "incident" || type === "intel" || type === "product") &&
                          this.state.showEventData &&
                          this.state.headerData.promoted_from.length > 0 ? (
                            <PromotedData
                              data={this.state.headerData.promoted_from}
                              type={type}
                              id={id}
                            />
                          ) : null}
                          {type !== "entity" && this.state.showEventData ? (
                            <Badge
                              data={this.state.tagData}
                              id={id}
                              type={type}
                              updated={this.updated}
                              errorToggle={this.props.errorToggle}
                              badgeType="tag"
                            />
                          ) : null}
                          {type !== "entity" && this.state.showEventData ? (
                            <Badge
                              data={this.state.sourceData}
                              id={id}
                              type={type}
                              updated={this.updated}
                              errorToggle={this.props.errorToggle}
                              badgeType="source"
                            />
                          ) : null}
                        </tr>
                      </tbody>
                    </table>
                    {/*<DetailHeaderMoreOptions type={type} id={id} data={this.state.headerData} errorToggle={this.props.errorToggle} showData={this.state.showEventData} />*/}
                  </div>
                ) : null}
              </div>
              <Notification ref="notificationSystem" />
              {this.state.exportModal ? (
                <ExportModal
                  type={type}
                  errorToggle={this.props.errorToggle}
                  exportToggle={this.exportToggle}
                  id={id}
                />
              ) : null}
              {this.state.linkWarningToolbar ? (
                <LinkWarning
                  linkWarningToggle={this.linkWarningToggle}
                  link={this.state.link}
                  nopop={this.state.nopop}
                />
              ) : null}
              {this.state.viewedByHistoryToolbar ? (
                <ViewedByHistory
                  viewedByHistoryToggle={this.viewedByHistoryToggle}
                  id={id}
                  type={type}
                  subjectType={subjectType}
                  viewedby={viewedby}
                  errorToggle={this.props.errorToggle}
                />
              ) : null}
              {this.state.changeHistoryToolbar ? (
                <ChangeHistory
                  changeHistoryToggle={this.changeHistoryToggle}
                  id={id}
                  type={type}
                  subjectType={subjectType}
                  errorToggle={this.props.errorToggle}
                />
              ) : null}
              {this.state.entitiesToolbar ? (
                <span>
                  {this.state.entryEntityData !== null ? (
                    <Entities
                      entitiesToggle={this.entitiesToggle}
                      entityData={this.state.entryEntityData}
                      flairToolbarToggle={this.flairToolbarToggle}
                      flairToolbarOff={this.flairToolbarOff}
                    />
                  ) : (
                    <Entities
                      entitiesToggle={this.entitiesToggle}
                      entityData={this.state.entityData}
                      flairToolbarToggle={this.flairToolbarToggle}
                      flairToolbarOff={this.flairToolbarOff}
                    />
                  )}
                </span>
              ) : null}

              {this.state.deleteToolbar ? (
                <div>
                  {this.state.deleteType !== "alert" ? (
                    <DeleteThingComponent
                      deleteType={this.state.deleteType}
                      subjectType={subjectType}
                      id={id}
                      deleteToggle={this.deleteToggle}
                      updated={this.updated}
                      errorToggle={this.props.errorToggle}
                      history={this.props.history}
                      removeCallback={this.props.removeCallback}
                    />
                  ) : (
                    <DeleteThingComponent
                      deleteType={this.state.deleteType}
                      type={type}
                      deleteToggle={this.deleteToggle}
                      updated={this.updated}
                      errorToggle={this.props.errorToggle}
                      history={this.props.history}
                      alertsSelected={this.state.alertsSelected}
                      removeCallback={this.props.removeCallback}
                    />
                  )}
                </div>
              ) : null}
              {this.state.showMarkModal ? (
                <Mark
                  modalActive={true}
                  type={type}
                  id={id}
                  string={string}
                  errorToggle={this.props.errorToggle}
                  markModalToggle={this.markModalToggle}
                />
              ) : null}
              {this.state.showLinksModal ? (
                <Links
                  modalActive={true}
                  type={type}
                  id={id}
                  errorToggle={this.props.errorToggle}
                  linksModalToggle={this.linksModalToggle}
                />
              ) : null}
              {this.state.showEventData ? (
                <SelectedHeaderOptions
                  type={type}
                  subjectType={subjectType}
                  id={id}
                  entryData={this.state.entryData}
                  headerData={this.state.headerData}
                  status={this.state.headerData.status}
                  promoteToggle={this.promoteToggle}
                  permissionsToggle={this.permissionsToggle}
                  entryToggle={this.entryToggle}
                  entitiesToggle={this.entitiesToggle}
                  changeHistoryToggle={this.changeHistoryToggle}
                  viewedByHistoryToggle={this.viewedByHistoryToggle}
                  exportToggle={this.exportToggle}
                  deleteToggle={this.deleteToggle}
                  updated={this.updated}
                  flairToolbarToggle={this.flairToolbarToggle}
                  flairToolbarOff={this.flairToolbarOff}
                  sourceToggle={this.sourceToggle}
                  subjectName={this.state.headerData.subject}
                  fileUploadToggle={this.fileUploadToggle}
                  fileUploadToolbar={this.state.fileUploadToolbar}
                  guideRedirectToAlertListWithFilter={
                    this.guideRedirectToAlertListWithFilter
                  }
                  showSignatureOptionsToggle={this.showSignatureOptionsToggle}
                  markModalToggle={this.markModalToggle}
                  linksModalToggle={this.linksModalToggle}
                  ToggleProcessingMessage={this.ToggleProcessingMessage}
                  errorToggle={this.props.errorToggle}
                  toggleFlair={this.toggleFlair}
                  alertsSelected={this.state.alertsSelected}
                  guideID={this.state.guideID}
                />
              ) : null}
              {this.state.permissionsToolbar ? (
                <SelectedPermission
                  updateid={id}
                  id={id}
                  type={type}
                  permissionData={this.state.headerData}
                  permissionsToggle={this.permissionsToggle}
                  updated={this.updated}
                  errorToggle={this.props.errorToggle}
                />
              ) : null}
            </div>
            {this.state.showEventData && type !== "entity" ? (
              <SelectedEntry
                id={id}
                type={type}
                entryToggle={this.entryToggle}
                updated={this.updated}
                entryData={this.state.entryData}
                headerData={this.state.headerData}
                showEntryData={this.state.showEntryData}
                showEntityData={this.state.showEntityData}
                summaryUpdate={this.summaryUpdate}
                flairToolbarToggle={this.flairToolbarToggle}
                flairToolbarOff={this.flairToolbarOff}
                linkWarningToggle={this.linkWarningToggle}
                entryToolbar={this.state.entryToolbar}
                alertPreSelectedId={this.props.alertPreSelectedId}
                errorToggle={this.props.errorToggle}
                fileUploadToggle={this.fileUploadToggle}
                fileUploadToolbar={this.state.fileUploadToolbar}
                showSignatureOptions={this.state.showSignatureOptions}
                flairOff={this.state.flairOff}
                highlightedText={this.state.highlightedText}
                form={this.props.form}
                createCallback={this.props.createCallback}
                removeCallback={this.props.removeCallback}
                addFlair={AddFlair.entityUpdate}
                handleSelection={this.handleSelection}
                handleShiftSelect={this.handleShiftSelect}
                handleMultiSelection={this.handleMultiSelection}
                handleSelectAll={this.handleSelectAll}
                alertsSelected={this.state.alertsSelected}
                setEntryEntities={this.setEntryEntities}
              />
            ) : null}
            {this.state.showEventData && type === "entity" ? (
              <EntityDetail
                entityid={id}
                form={this.props.form}
                entitytype={"entity"}
                id={id}
                type={"entity"}
                fullScreen={true}
                errorToggle={this.props.errorToggle}
                linkWarningToggle={this.linkWarningToggle}
                createCallback={this.props.createCallback}
                removeCallback={this.props.removeCallback}
                addFlair={AddFlair.entityUpdate}
              />
            ) : null}
            {this.state.flairToolbar ? (
              <EntityDetail
                key={this.state.entityDetailKey}
                form={this.props.form}
                flairToolbarToggle={this.flairToolbarToggle}
                flairToolbarOff={this.flairToolbarOff}
                linkWarningToggle={this.linkWarningToggle}
                entityid={parseInt(this.state.entityid, 10)}
                data={this.state.headerData}
                entityvalue={this.state.entityvalue}
                entitytype={this.state.entitytype}
                type={this.props.type}
                id={this.props.id}
                errorToggle={this.props.errorToggle}
                entityoffset={this.state.entityoffset}
                watcher={this.Watcher}
                entityobj={this.state.entityobj}
                createCallback={this.props.createCallback}
                removeCallback={this.props.removeCallback}
                addFlair={AddFlair.entityUpdate}
              />
            ) : null}
          </div>
        )}
      </div>
    );
  }
}

class EntryDataUpdated extends React.Component {
  render() {
    let data = this.props.data;
    return (
      <div>
        <ReactTime value={data * 1000} format="MM/DD/YY hh:mm:ss a" />
      </div>
    );
  }
}

class EntryDataSubject extends React.Component {
  constructor(props) {
    super(props);
    let keyName = "subject";
    let value = this.props.data.subject;
    if (this.props.type === "signature" || this.props.type === "feed") {
      keyName = "name";
      value = this.props.data.name;
    } else if (this.props.type === "entity") {
      keyName = "value";
      value = this.props.data.value;
    }
    this.state = {
      value: value,
      width: "",
      keyName: keyName
    };
  }

  handleChange = event => {
    if (event !== null) {
      let keyName = this.state.keyName;
      let json = { [keyName]: event.target.value };
      let newValue = event.target.value;
      $.ajax({
        type: "put",
        url: "scot/api/v2/" + this.props.type + "/" + this.props.id,
        data: JSON.stringify(json),
        contentType: "application/json; charset=UTF-8",
        success: function(data) {
          console.log("success: " + data);
          this.setState({ value: newValue });
          this.calculateWidth(newValue);
        }.bind(this),
        error: function(result) {
          this.props.errorToggle(
            "error: Failed to update the subject/name",
            result
          );
        }.bind(this)
      });
    }
  };

  componentDidMount() {
    this.calculateWidth(this.state.value);
  }

  onChange = e => {
    this.setState({ value: e.target.value });
  };

  handleEnterKey = e => {
    if (e.key === "Enter") {
      this.handleChange(e);
    }
  };

  calculateWidth = input => {
    let newWidth;
    $("#invisible").html($("<span></span>").text(input));
    newWidth = $("#invisible").width() + 25 + "px";
    this.setState({ width: newWidth });
  };

  componentWillReceiveProps = nextProps => {
    let value = nextProps.data.subject;
    if (nextProps.type === "signature" || nextProps.type === "feed") {
      value = nextProps.data.name;
    } else if (nextProps.type === "entity") {
      value = nextProps.data.value;
    }
    this.setState({ value: value });
    this.calculateWidth(value);
  };

  render() {
    //only disable the subject editor on an entity with a non-blank subject as editing it could damage flair.
    let isDisabled = false;
    if (this.props.type === "entity" && this.state.value !== "") {
      isDisabled = true;
    }
    return (
      <div>
        {this.props.subjectType} {this.props.id}:{" "}
        <input
          type="text"
          value={this.state.value}
          onKeyPress={this.handleEnterKey}
          onChange={this.onChange}
          onBlur={this.handleChange}
          style={{ width: this.state.width, lineHeight: "normal" }}
          className="detail-header-input"
          disabled={isDisabled}
        />
      </div>
    );
  }
}
