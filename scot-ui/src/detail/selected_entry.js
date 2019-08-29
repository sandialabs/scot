import React from "react";
import $ from "jquery";
import EntityDetail from "../modal/entity_detail";
import ReactTime from "react-time";
import SplitButton from "react-bootstrap/lib/SplitButton.js";
import MenuItem from "react-bootstrap/lib/MenuItem.js";
import Button from "react-bootstrap/lib/Button.js";
import AddEntry from "../components/add_entry.js";
import FileUpload from "../components/file_upload.js";
import { DeleteEntry } from "../modal/delete";
import Summary from "../components/summary";
import Task from "../components/task";
import SelectedPermission from "../components/permission.js";
import Frame from "react-frame-component";
import LinkWarning from "../modal/link_warning";
import { Link } from "react-router-dom";
import SignatureTable from "../components/signature_table";
import TrafficLightProtocol from "../components/traffic_light_protocol";
import Marker from "../components/marker";
import EntityCreateModal from "../modal/entity_create";
import CustomMetaDataTable from "../components/custom_metadata_table";
import ReactTable from "react-table";
import { get_data, put_data, post_data } from "../utils/XHR";
import AlertSubComponent from "./alert_subcomponent";
import {
  buildTypeColumns,
  customCellRenderers,
  getColumnWidth
} from "../list/tableConfig";
import Button2 from "@material-ui/core/Button";

export default class SelectedEntry extends React.Component {
  constructor(props) {
    super(props);
    let entityDetailKey = Math.floor(Math.random() * 1000);
    this.state = {
      showEntryData: this.props.showEntryData,
      showEntityData: this.props.showEntityData,
      entryData: this.props.entryData,
      entityData: this.props.entityData,
      entityid: null,
      entitytype: null,
      entityoffset: null,
      entityobj: null,
      key: this.props.id,
      flairToolbar: false,
      notificationType: null,
      notificationMessage: "",
      height: null,
      entityDetailKey: entityDetailKey,
      isMounted: false
    };
  }

  componentDidMount() {
    this.getEntryData();
    this.getEntityData();
    this.props.createCallback(this.props.id, this.updatedCB);
    this.containerHeightAdjust();

    window.addEventListener("resize", this.containerHeightAdjust);
    let table = document.querySelector(".ReactTable");
    table.onresize = function() {
      this.containerHeightAdjust();
    }.bind(this);
  }

  componentWillReceiveProps() {
    this.containerHeightAdjust();
  }

  componentDidUpdate() {
    if (this.state.runWatcher == true) {
      this.Watcher();
    }
  }

  componentWillUnmount() {
    this.setState({ isMounted: false });
  }

  getEntryData = () => {
    const { type, id } = this.props;
    this.setState({ isMounted: true });
    if (type === "alert" || type === "entity" || this.props.isPopUp === 1) {
      let entry_url = `scot/api/v2/${type}/${id}/entry`;
      let entry_response = get_data(entry_url, null);
      entry_response
        .then(
          function(response) {
            if (this.state.isMounted) {
              this.setState({
                showEntryData: true,
                entryData: response.data.records
              });
              response.data.records.forEach(
                function(element, i) {
                  this.props.createCallback(
                    response.data.records[i].id,
                    this.updatedCB
                  );
                }.bind(this)
              );
              this.Watcher();
            }
          }.bind(this)
        )
        .catch(
          function(error) {
            if (this.state.isMounted) {
              this.setState({ showEntryData: true });
              this.props.errorToggle("Failed to load entry data.", error);
            }
          }.bind(this)
        );
    }
  };

  getEntityData = () => {
    const { addFlair, type, id } = this.props;
    if (
      type === "alert" ||
      type === "entity" ||
      type === "incident" ||
      this.props.isPopUp === 1
    ) {
      const entity_url = `scot/api/v2/${type}/${id}/entity`;
      let entity_response = get_data(entity_url, null);
      entity_response
        .then(
          function(response) {
            let entityResult = response.data.records;
            if (this.state.isMounted) {
              this.setState({ showEntityData: true, entityData: entityResult });
              let waitForEntry = {
                waitEntry: function() {
                  if (this.state.showEntryData === false) {
                    setTimeout(waitForEntry.waitEntry, 50);
                  } else {
                    setTimeout(
                      function() {
                        addFlair(entityResult, null, type, null, id);
                      }.bind(this)
                    );
                  }
                }.bind(this)
              };
              waitForEntry.waitEntry();
            }
          }.bind(this)
        )
        .catch(
          function(data) {
            if (this.state.isMounted) {
              this.setState({ showEntityData: true });
              this.props.errorToggle("Failed to load entity data.", data);
            }
          }.bind(this)
        );
    }
  };

  updatedCB = () => {
    this.getEntityData();
    this.getEntryData();
  };

  flairToolbarToggle = (id, value, type, entityoffset, entityobj) => {
    if (this.state.isMounted) {
      this.setState({
        flairToolbar: true,
        entityid: id,
        entityvalue: value,
        entitytype: type,
        entityoffset: entityoffset,
        entityobj: entityobj
      });
    }
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

  linkWarningToggle = href => {
    if (this.state.isMounted) {
      if (this.state.linkWarningToolbar === false) {
        this.setState({ linkWarningToolbar: true, link: href });
      } else {
        this.setState({ linkWarningToolbar: false });
      }
    }
  };

  Watcher = () => {
    let containerid = this.props.type + "-detail-container";
    if (this.props.type != "alertgroup") {
      let selector = `iframe`;
      let iframes = document.querySelectorAll(selector);
      iframes.forEach(
        function(ifr, index) {
          ifr.contentWindow.requestAnimationFrame(
            function() {
              if (ifr.contentDocument != null) {
                let arr = [];
                arr.push(this.checkFlairHover);
                ifr.addEventListener("mouseenter", function(v, type) {
                  let intervalID = setInterval(this[0], 50, ifr); // this.flairToolbarToggle, type, this.props.linkWarningToggle, this.props.id);
                  console.log("Now watching iframe " + intervalID);
                });

                ifr.addEventListener("mouseleave", function() {
                  let intervalID = $(ifr).data("intervalID");
                  window.clearInterval(intervalID);
                  console.log("No longer watching iframe " + intervalID);
                });
              }
            }.bind(this)
          );
        }.bind(this)
      );
    } else {
      $(containerid)
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

  checkFlairHover = ifr => {
    function returnifr() {
      return ifr;
    }
    if (this.props.type != "alertgroup") {
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
      }
      if (ifr.contentDocument != null) {
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
    }
  };

  containerHeightAdjust = () => {
    //Using setTimeout so full screen toggle animation has time to finish before resizing detail section
    setTimeout(
      function() {
        let scrollHeight;
        let ListViewTableHeight = document.getElementsByClassName(
          "ReactTable"
        )[0].clientHeight;
        if (ListViewTableHeight !== undefined) {
          if (ListViewTableHeight !== 0) {
            scrollHeight =
              $(window).height() -
              ListViewTableHeight -
              $("#header").height() -
              78;
            scrollHeight = scrollHeight + "px";
          } else {
            scrollHeight = $(window).height() - $("#header").height() - 78;
            scrollHeight = scrollHeight + "px";
          }
          //$('#detail-container').css('height',scrollHeight);
          if (this.state.isMounted) {
            this.setState({ height: scrollHeight });
          }
        }
      }.bind(this),
      500
    );
  };

  render = () => {
    let divid = "detail-container";
    let height = this.state.height;
    let data = this.props.entryData;
    let type = this.props.type;
    let id = this.props.id;
    let showEntryData = this.props.showEntryData;
    let divClass = "row-fluid entry-wrapper entry-wrapper-main";
    if (type === "alert") {
      //divClass = 'row-fluid entry-wrapper entry-wrapper-main-300'
      divClass = "row-fluid entry-wrapper entry-wrapper-main-nh";
      data = this.state.entryData;
      showEntryData = this.state.showEntryData;
    } else if (type === "alertgroup") {
      divClass = "row-fluid alert-wrapper entry-wrapper-main";
    } else if (type === "entity" || this.props.isPopUp === 1) {
      divClass = "row-fluid entry-wrapper-entity";
      data = this.state.entryData;
      showEntryData = this.state.showEntryData;
    }
    //lazy loading flair - this needs to be done here because it is not initialized when this function is called by itself (alerts and entities)
    if (type === "alert" || this.props.isPopUp === 1) {
      divid = this.props.type + "-detail-container";
      height = null;
    }
    return (
      <div id={divid} key={id} className={divClass} style={{ height: height }}>
        {type !== "entity" && type !== "alert" ? (
          <CustomMetaDataTable
            type={type}
            id={id}
            errorToggle={this.props.errorToggle}
            form={this.props.form}
            headerData={this.props.headerData}
          />
        ) : null}
        {/*{(type == 'incident' && this.props.headerData != null) ? <IncidentTable type={type} id={id} headerData={this.props.headerData} errorToggle={this.props.errorToggle}/> : null}*/}
        {type === "signature" && this.props.headerData !== null ? (
          <SignatureTable
            type={type}
            id={id}
            headerData={this.props.headerData}
            errorToggle={this.props.errorToggle}
            showSignatureOptions={this.props.showSignatureOptions}
          />
        ) : null}
        {showEntryData ? (
          <EntryIterator
            updated={this.updatedCB}
            removeCallback={this.props.removeCallback}
            createCallback={this.props.createCallback}
            data={data}
            type={type}
            id={id}
            entityData={this.state.entityData}
            entryToggle={this.props.entryToggle}
            subcomponent={this.props.subcomponent}
            setAlertColumns={this.props.setAlertColumns}
            {...this.props}
          />
        ) : (
          <span>Loading...</span>
        )}
        {this.props.entryToolbar ? (
          <div>
            <AddEntry
              entryAction={"Add"}
              type={this.props.type}
              targetid={this.props.id}
              id={null}
              addedentry={this.props.entryToggle}
              updated={this.updatedCB}
              errorToggle={this.props.errorToggle}
            />
          </div>
        ) : null}
        {this.props.fileUploadToolbar ? (
          <div>
            <FileUpload
              type={this.props.type}
              targetid={this.props.id}
              id={"file_upload"}
              fileUploadToggle={this.props.fileUploadToggle}
              updated={this.updatedCB}
              errorToggle={this.props.errorToggle}
            />
          </div>
        ) : null}
        {this.state.flairToolbar ? (
          <EntityDetail
            key={this.state.entityDetailKey}
            flairToolbarToggle={this.flairToolbarToggle}
            flairToolbarOff={this.flairToolbarOff}
            entityid={this.state.entityid}
            entityvalue={this.state.entityvalue}
            entitytype={this.state.entitytype}
            type={this.props.type}
            id={this.props.id}
            entityoffset={this.state.entityoffset}
            entityobj={this.state.entityobj}
            linkWarningToggle={this.linkWarningToggle}
            errorToggle={this.props.errorToggle}
            createCallback={this.props.createCallback}
            removeCallback={this.props.removeCallback}
            addFlair={this.props.addFlair}
          />
        ) : null}
        {this.state.linkWarningToolbar ? (
          <LinkWarning
            linkWarningToggle={this.linkWarningToggle}
            link={this.state.link}
          />
        ) : null}
      </div>
    );
  };
}

class EntryIterator extends React.Component {
  render = () => {
    let rows = [];
    let data = this.props.data;
    let type = this.props.type;
    let items = this.props.items;
    let linkToSearch = [];
    let id = this.props.id;
    let entityData = this.props.entityData;
    let search = null;
    if (this.props.items !== undefined) {
      if (
        this.props.items[0].data_with_flair !== undefined &&
        !this.props.flairOff
      ) {
        search = items[0].data_with_flair.search;
      } else {
        search = items[0].data.search;
      }
      for (let y = 0; y < this.props.headerData.ahrefs.length; y++) {
        linkToSearch.push(
          <a href={this.props.headerData.ahrefs[y].link}>
            {this.props.headerData.ahrefs[y].subject}
          </a>
        );
        linkToSearch.push(<br />);
      }
    }

    if (data === undefined || data[0] === undefined) {
      if (type !== "alertgroup") {
        return (
          <div>
            <div style={{ color: "blue" }}>
              No entries found. Click the green Add Entry button if you would
              like to create one
            </div>
          </div>
        );
      } else {
        return (
          <div>
            <div style={{ color: "blue" }}>
              No alerts found or they are unable to be rendered. Please check
              the source and correct the formatting of the alert if necessary
            </div>
          </div>
        );
      }
    } else {
      if (type !== "alertgroup") {
        let key = 0;
        data.forEach(
          function(data) {
            rows.push(
              <EntryParent
                subcomponent={this.props.subcomponent}
                key={key}
                items={data}
                type={type}
                id={id}
                isPopUp={this.props.isPopUp}
                errorToggle={this.props.errorToggle}
                createCallback={this.props.createCallback}
                removeCallback={this.props.removeCallback}
                entityData={entityData}
                entryToggle={this.props.entryToggle}
              />
            );
            key = key + 1;
          }.bind(this)
        );
        return <div>{rows}</div>;
      } else {
        return (
          <div>
            <NewAlertTable
              subcomponent={this.props.subcomponent}
              {...this.props}
              key={id}
              type={type}
              id={id}
              items={data}
              entityData={entityData}
              entryToggle={this.props.entryToggle}
              createCallback={this.props.createCallback}
              removeCallback={this.props.removeCallback}
              addFlair={this.props.addFlair}
              setAlertColumns={this.props.setAlertColumns}
              updated={this.props.updated}
            />
          </div>
        );
      }
    }
  };
}

class NewAlertTable extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      columns: [],
      data: [],
      entityData: [],
      type: "",
      addFlair: null,
      promotionId: null,
      selected: [],
      flairOff: false,
      expanded: {}
    };
  }

  componentDidMount() {
    if (this.props.items.length > 0) {
      const data = this.createData();
      const columns = buildTypeColumns("alert", data, this.props.items, true);
      this.setState({ data, columns });
    }
    if (this.props.type) {
      this.setState({
        type: this.props.type,
        entityData: this.props.entityData
      });
    }
    if (this.props.addFlair) {
      this.setState({ addFlair: this.props.addFlair });
    }

    //handle alertselection from SelectedHeader
    if (this.props.alertsSelected) {
      this.setState({ selected: this.props.alertsSelected });
    }

    $("#main-detail-container").keydown(
      function(event) {
        //prevent from working when in input
        if ($("input").is(":focus")) {
          return;
        }
        //check for ctrl + a with keyCode
        if (
          event.keyCode === 65 &&
          (event.ctrlKey === true || event.metaKey === true)
        ) {
          this.handleSelectAll();
          event.preventDefault();
        }
      }.bind(this)
    );
  }

  componentDidUpdate(prevProps, prevState) {
    if (prevProps.entityData !== this.props.entityData) {
      this.setState({ entityData: this.props.entityData });
    }
    if (prevState.flairOff !== this.state.flairOff) {
      let data = this.createData();
      this.setState({ data });
    }
    if (prevProps.items !== this.props.items) {
      let data = this.createData();
      this.setState({ data });
    }

    if (
      this.props.alertsSelected !== prevState.selected &&
      this.props.alertsSelected !== undefined
    ) {
      this.setState({ selected: this.props.alertsSelected });
    }
  }

  static getDerivedStateFromProps(nextProps, prevState) {
    if (nextProps.flairOff !== prevState.flairOff) {
      return { flairOff: nextProps.flairOff };
    }
    if (nextProps.alertsSelected !== prevState.selected) {
      return { selected: nextProps.alertsSelected };
    } else return null;
  }

  createData = () => {
    const dataarray = [];
    this.props.items.forEach(
      function(element) {
        let dataitem = {};
        if (!this.state.flairOff) {
          dataitem = element.data_with_flair;
        } else {
          dataitem = element.data;
        }
        dataitem["id"] = element.id;
        dataitem["status"] = element.status;
        dataitem["entry_count"] = element.entry_count;
        dataarray.push(dataitem);
      }.bind(this)
    );
    return dataarray;
  };

  render() {
    const { data, columns } = this.state;
    const { addFlair, type, headerData, entityData, updated } = this.props;

    return (
      <div>
        <ReactTable
          styleName="styles.ReactTable"
          ref={r => (this.reactTable = r)}
          key={2}
          data={data}
          columns={columns}
          filterable={true}
          expanded={this.state.expanded}
          onExpandedChange={(expanded, index, event) => {
            this.setState({ expanded });
            addFlair(entityData, null, "entry", null, null);
          }}
          defaultFilterMethod={(filter, row) => {
            if (row[filter.id].includes(filter.value)) {
              return row;
            }
          }}
          SubComponent={({ row }) => {
            return (
              <AlertSubComponent
                flag={this.props.subcomponent}
                row={row}
                entryToggle={this.props.entryToggle}
                errorToggle={this.props.errorToggle}
                entryData={this.props.entryData}
                showEntryData={this.props.showEntryData}
                errorToggle={this.props.errorToggle}
                createCallback={this.props.createCallback}
                removeCallback={this.props.removeCallback}
                entityData={this.props.entityData}
                addFlair={this.props.addFlair}
                updated={this.props.updated}
              />
            );
          }}
          onFilteredChange={(filter, column) => {
            addFlair(entityData, null, type, null, null);
          }}
          onSortedChange={(newSorted, column, shiftKey) => {
            addFlair(entityData, null, type, null, null);
          }}
          showPagination={false}
          pageSize={data.length}
          getTrProps={(state, rowInfo) => {
            if (
              rowInfo &&
              rowInfo.row &&
              this.props.alertsSelected !== undefined
            ) {
              return {
                onClick: e => {
                  if (e.ctrlKey || (e.metaKey && e.keyCode === 83)) {
                    this.props.handleSelectAll(state.sortedData);
                  }
                  if (e.ctrlKey || e.metaKey) {
                    e.preventDefault();
                    this.props.handleMultiSelection(rowInfo.original);
                  } else if (e.shiftKey) {
                    document.getSelection().removeAllRanges();
                    this.props.handleShiftSelect(
                      this.state.selected[0].id,
                      rowInfo.original.id,
                      state.sortedData
                    );
                  } else {
                    this.props.handleSelection(rowInfo.original);
                  }
                },
                style: {
                  background: this.state.selected.some(
                    item => rowInfo.original.id === item.id
                  )
                    ? "#a7c6a5"
                    : "",
                  borderBottom: "1px solid black",
                  maxHeight: 200,
                  overflowY: "auto"
                }
              };
            } else {
              return { style: { maxHeight: 200, overflowY: "auto" } };
            }
          }}
        />
        <AlertTableSearchDiv
          items={this.props.items}
          flairOff={this.props.flairOff}
          headerData={this.props.headerData}
        />
      </div>
    );
  }
}

//div underneath alert table
class AlertTableSearchDiv extends React.Component {
  constructor(props) {
    super(props);
  }

  render() {
    let search = null;
    const { items } = this.props;
    if (items[0].data_with_flair !== undefined && !this.props.flairOff) {
      search = items[0].data_with_flair.search;
    } else {
      search = items[0].data.search;
    }

    let linkToSearch = this.props.headerData.ahrefs.map((item, index) => (
      <div key={index}>
        <a href={this.props.headerData.ahrefs[index].link}>
          {this.props.headerData.ahrefs[index].subject}
        </a>
        <br />
      </div>
    ));

    return (
      <div>
        {search !== undefined ? (
          <div
            className="alertTableHorizontal"
            style={{
              outline: "1px solid black",
              borderRadius: 5,
              padding: 3,
              margin: "10px 0 15px"
            }}
          >
            {linkToSearch}
            <div dangerouslySetInnerHTML={{ __html: search }} />
          </div>
        ) : null}
      </div>
    );
  }
}

class EntryParent extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      editEntryToolbar: false,
      replyEntryToolbar: false,
      deleteToolbar: false,
      permissionsToolbar: false,
      fileUploadToolbar: false,
      showEntityCreateModal: false,
      highlightedText: null,
      items: {}
    };
  }

  // componentWillUnmount() {
  //   this.props.removeCallback(this.props.items.id);
  // }

  componentDidMount = () => {
    this.props.createCallback(this.props.items.id, this.refreshButton);
  };

  //TODO modify manual entry refresh to be done on automatically based on STOMP single entry update. This works for now.
  refreshButton = () => {
    if ($("#refresh-detail")) {
      $("#refresh-detail").click();
    }
  };

  editEntryToggle = () => {
    if (this.state.editEntryToolbar === false) {
      this.setState({ editEntryToolbar: true });
    } else {
      this.setState({ editEntryToolbar: false });
    }
  };

  replyEntryToggle = () => {
    if (this.state.replyEntryToolbar === false) {
      this.setState({ replyEntryToolbar: true });
    } else {
      this.setState({ replyEntryToolbar: false });
    }
  };

  deleteToggle = () => {
    if (this.state.deleteToolbar === false) {
      this.setState({ deleteToolbar: true });
    } else {
      this.setState({ deleteToolbar: false });
    }
  };

  permissionsToggle = () => {
    if (this.state.permissionsToolbar === false) {
      this.setState({ permissionsToolbar: true });
    } else {
      this.setState({ permissionsToolbar: false });
    }
  };

  reparseFlair = () => {
    let reparse_flair_endpoint = `/scot/api/v2/entry/${this.props.items.id}`;
    let put_response = put_data(reparse_flair_endpoint);
    put_response
      .then(function(data) {
        console.log("reparsing started");
      })
      .catch(
        function(data) {
          this.props.errorToggle("failed to start reparsing of data", data);
        }.bind(this)
      );
  };

  fileUploadToggle = () => {
    if (this.state.fileUploadToolbar === false) {
      this.setState({ fileUploadToolbar: true });
    } else {
      this.setState({ fileUploadToolbar: false });
    }
  };

  render = () => {
    let itemarr = [];
    let subitemarr = [];
    let items = this.props.items;
    let type = this.props.type;
    let id = this.props.id;
    let isPopUp = this.props.isPopUp;
    let itemsClass = this.props.items.class;
    let summary = 0; //define Summary as false unless itemsClass is "summary"
    let editEntryToolbar = this.state.editEntryToolbar;
    let editEntryToggle = this.editEntryToggle;
    let errorToggle = this.props.errorToggle;
    let outerClassName = "row-fluid entry-outer";
    let innerClassName = "row-fluid entry-header";
    let taskOwner = "";
    if (itemsClass === "summary") {
      outerClassName += " summary_entry";
      summary = 1;
    }
    if (itemsClass === "task") {
      if (
        items.metadata.task.status === "open" ||
        items.metadata.task.status === "assigned"
      ) {
        taskOwner = "-- Task Owner " + items.metadata.task.who + " ";
        outerClassName += " todo_open_outer";
        innerClassName += " todo_open";
      } else if (
        (items.metadata.task.status === "closed" ||
          items.metadata.task.status === "completed") &&
        items.metadata.task.who != null
      ) {
        taskOwner = "-- Task Owner " + items.metadata.task.who + " ";
        outerClassName += " todo_completed_outer";
        innerClassName += " todo_completed";
      } else if (
        items.metadata.task.status === "closed" ||
        items.metadata.task.status === "completed"
      ) {
        outerClassName += " todo_undefined_outer";
        innerClassName += " todo_undefined";
      }
    }
    if (itemsClass === "alert") {
      outerClassName += " event_entry_container_alert";
    }
    itemarr.push(
      <EntryData
        id={items.id}
        key={items.id}
        subitem={items}
        type={type}
        targetid={id}
        editEntryToolbar={editEntryToolbar}
        editEntryToggle={editEntryToggle}
        isPopUp={isPopUp}
        errorToggle={this.props.errorToggle}
      />
    );
    for (let prop in items) {
      let childfunc = prop => {
        if (prop === "children") {
          let childobj = items[prop];
          items[prop].forEach(
            function(childobj) {
              subitemarr.push(
                new Array(
                  (
                    <EntryParent
                      items={childobj}
                      id={id}
                      type={type}
                      editEntryToolbar={editEntryToolbar}
                      editEntryToggle={editEntryToggle}
                      isPopUp={isPopUp}
                      errorToggle={errorToggle}
                      createCallback={this.props.createCallback}
                      removeCallback={this.props.removeCallback}
                    />
                  )
                )
              );
            }.bind(this)
          );
        }
      };
      childfunc(prop);
    }
    itemarr.push(subitemarr);

    let entryActions = [];
    if (this.props.items) {
      if (this.props.items.actions) {
        for (let i = 0; i < this.props.items.actions.length; i++) {
          if (
            this.props.items.actions[i].send_to_name &&
            this.props.items.actions[i].send_to_url
          ) {
            entryActions.push(
              <EntryAction
                id={this.props.items.actions[i].send_to_name}
                datahref={this.props.items.actions[i].send_to_url}
                errorToggle={this.props.errorToggle}
              />
            );
          }
        }
      }
    }

    let header1 = "[" + items.id + "] ";
    let header2 = " by " + items.owner + " " + taskOwner + "(updated on ";
    let header3 = ")";
    let createdTime = items.created;
    let updatedTime = items.updated;
    let entryHeaderInnerId =
      "entry-header-inner-" + this.props.id + " entry-header-inner";
    let tlpBorder;
    let tlpColorCSS;
    if (items.tlp !== "unset") {
      if (items.tlp !== "amber") {
        tlpColorCSS = items.tlp;
      } else {
        tlpColorCSS = "orange";
      }
      tlpBorder = "3px solid " + tlpColorCSS;
    }
    return (
      <div>
        {this.state.showEntityCreateModal ? (
          <EntityCreateModal
            match={this.state.highlightedText}
            modalActive={this.state.showEntityCreateModal}
            ToggleCreateEntity={this.ToggleCreateEntity}
            errorToggle={this.props.errorToggle}
            createCallback={this.props.createCallback}
            removeCallback={this.props.removeCallback}
          />
        ) : null}
        <div
          className={outerClassName}
          style={{
            marginLeft: "auto",
            marginRight: "auto",
            width: "99.3%",
            border: tlpBorder
          }}
        >
          <span
            className="anchor"
            id={"/" + type + "/" + id + "/" + items.id}
          />
          <div className={innerClassName}>
            <div id={entryHeaderInnerId} className={entryHeaderInnerId}>
              [
              <Link
                style={{ color: "black" }}
                to={"/" + type + "/" + id + "/" + items.id}
              >
                {items.id}
              </Link>
              ]{" "}
              <ReactTime
                value={items.created * 1000}
                format="MM/DD/YYYY hh:mm:ss a"
              />{" "}
              by {items.owner} {taskOwner}
              (updated on{" "}
              <ReactTime
                value={items.updated * 1000}
                format="MM/DD/YYYY hh:mm:ss a"
              />
              )
              {this.state.highlightedText !== "" &&
              this.state.highlightedText != null ? (
                <Button
                  bsSize="xsmall"
                  bsStyle="success"
                  onClick={this.ToggleCreateEntity}
                >
                  Create Entity
                </Button>
              ) : null}
              {this.props.items.body_flair !== "" &&
              this.props.items.parsed === 0 ? (
                <span style={{ color: "green", fontWeight: "bold" }}>
                  {" "}
                  Entry awaiting flair engine. Content may be inaccurate.
                </span>
              ) : null}
              <span
                className="pull-right"
                style={{ display: "inline-flex", paddingRight: "3px" }}
              >
                {this.state.permissionsToolbar ? (
                  <SelectedPermission
                    updateid={id}
                    id={items.id}
                    type={"entry"}
                    permissionData={items}
                    permissionsToggle={this.permissionsToggle}
                  />
                ) : null}
                {items.tlp !== "unset" && items.tlp !== undefined ? (
                  <span>
                    TLP:{" "}
                    <span style={{ color: tlpColorCSS }}>{items.tlp} </span>
                  </span>
                ) : null}
                <SplitButton
                  bsSize="xsmall"
                  title="Reply"
                  key={items.id}
                  id={"Reply " + items.id}
                  onClick={this.replyEntryToggle}
                  pullRight
                >
                  {type !== "entity" ? (
                    <MenuItem eventKey="1" onClick={this.fileUploadToggle}>
                      Upload File
                    </MenuItem>
                  ) : null}
                  {entryActions}
                  <MenuItem eventKey="3">
                    <Summary
                      type={type}
                      id={id}
                      entryid={items.id}
                      summary={summary}
                      errorToggle={this.props.errorToggle}
                    />
                  </MenuItem>
                  <MenuItem eventKey="4">
                    <Task
                      type={type}
                      id={id}
                      entryid={items.id}
                      taskData={items}
                      errorToggle={this.props.errorToggle}
                    />
                  </MenuItem>
                  <Marker
                    type={"entry"}
                    id={items.id}
                    string={items.body_plain}
                  />
                  <MenuItem onClick={this.permissionsToggle}>
                    Permissions
                  </MenuItem>
                  <MenuItem onClick={this.reparseFlair}>Reparse Flair</MenuItem>
                  <TrafficLightProtocol
                    type={"entry"}
                    id={items.id}
                    tlp={items.tlp}
                    errorToggle={this.props.errorToggle}
                  />
                  <MenuItem divider />
                  <MenuItem eventKey="2" onClick={this.deleteToggle}>
                    Delete
                  </MenuItem>
                </SplitButton>
                <Button bsSize="xsmall" onClick={this.editEntryToggle}>
                  Edit
                </Button>
              </span>
            </div>
          </div>
          {itemarr}
          {this.state.replyEntryToolbar ? (
            <AddEntry
              entryAction={"Reply"}
              type={type}
              header1={header1}
              header2={header2}
              header3={header3}
              createdTime={createdTime}
              updatedTime={updatedTime}
              targetid={id}
              id={items.id}
              addedentry={this.replyEntryToggle}
              errorToggle={this.props.errorToggle}
            />
          ) : null}
          {this.state.fileUploadToolbar ? (
            <FileUpload
              type={this.props.type}
              targetid={this.props.id}
              entryid={this.props.items.id}
              fileUploadToggle={this.fileUploadToggle}
              errorToggle={this.props.errorToggle}
            />
          ) : null}
        </div>
        {this.state.deleteToolbar ? (
          <DeleteEntry
            type={type}
            id={id}
            deleteToggle={this.deleteToggle}
            entryid={items.id}
            errorToggle={this.props.errorToggle}
          />
        ) : null}
      </div>
    );
  };

  componentWillReceiveProps = () => {
    this.checkHighlight();
  };

  checkHighlight = () => {
    let content;
    let iframe = document.getElementById("iframe_" + this.props.items.id);
    if (iframe) {
      if (iframe.contentWindow.getSelection() !== null) {
        content = iframe.contentWindow.getSelection().toString();
        if (this.state.highlightedText !== content) {
          console.log(iframe + " has highlighted text: " + content);
          this.setState({ highlightedText: content });
        } else {
          return;
        }
      } else {
        return;
      }
    }
  };

  ToggleCreateEntity = () => {
    this.setState({ showEntityCreateModal: !this.state.showEntityCreateModal });
  };
}

class EntryAction extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      [this.props.id]: false,
      disabled: false
    };
  }

  submit = () => {
    let url = this.props.datahref;
    let id = this.props.id;

    let post_response = post_data(url, null);
    post_response
      .then(
        function(data) {
          this.setState({ [id]: true, disabled: false });
        }.bind(this)
      )
      .catch(
        function(data) {
          this.props.errorToggle("failed to submit the entry action", data);
          this.setState({ disabled: false });
        }.bind(this)
      );
  };

  render = () => {
    return (
      <MenuItem disabled={this.state.disabled}>
        <span
          id={this.props.id}
          data-href={this.props.datahref}
          onClick={this.submit}
          style={{ display: "block" }}
        >
          {this.props.id}{" "}
          {this.state[this.props.id] ? (
            <span style={{ color: "green" }}>success</span>
          ) : null}
        </span>
      </MenuItem>
    );
  };
}

class EntryData extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      height: "1px"
    };
  }

  componentWillReceiveProps() {
    this.setHeight();
  }

  componentDidMount() {
    this.setHeight();
  }
  setHeight = () => {
    setTimeout(
      function() {
        if (document.getElementById("iframe_" + this.props.id) != undefined) {
          document
            .getElementById("iframe_" + this.props.id)
            .contentWindow.requestAnimationFrame(
              function() {
                let newheight;
                newheight = document.getElementById("iframe_" + this.props.id)
                  .contentWindow.document.body.scrollHeight;
                newheight = newheight + 35 + "px";
                if (this.state.height != newheight) {
                  this.setState({ height: newheight });
                }
              }.bind(this)
            );
        }
      }.bind(this),
      250
    );
  };

  render() {
    let rawMarkup = this.props.subitem.body_flair;
    if (this.props.subitem.body_flair == "") {
      rawMarkup = this.props.subitem.body;
    }
    let id = this.props.id;
    let entry_body_id = "entry-body-" + this.props.id;
    let entry_body_inner_id = "entry-body-inner-" + this.props.id;
    return (
      <div
        id={entry_body_id}
        key={this.props.id}
        className={"row-fluid entry-body"}
      >
        <div
          id={entry_body_inner_id}
          className={"row-fluid entry-body-inner"}
          style={{ marginLeft: "auto", marginRight: "auto", width: "99.3%" }}
        >
          {this.props.editEntryToolbar ? (
            <AddEntry
              entryAction={"Edit"}
              type={this.props.type}
              targetid={this.props.targetid}
              id={id}
              addedentry={this.props.editEntryToggle}
              parent={this.props.subitem.parent}
              errorToggle={this.props.errorToggle}
            />
          ) : (
            <Frame
              //Here is new stuff
              key={id}
              contentDidMount={this.setHeight}
              head={
                <link
                  rel="stylesheet"
                  type="text/css"
                  href="/css/sandbox.css"
                />
              }
              //end of new stuff
              frameBorder={"0"}
              id={"iframe_" + id}
              sandbox={"allow-same-origin"}
              style={{ width: "100%", height: this.state.height }}
            >
              <div dangerouslySetInnerHTML={{ __html: rawMarkup }} />
            </Frame>
          )}
        </div>
      </div>
    );
  }
}
