import React from "react";
import ReactTable from "react-table";
import { buildTypeColumns } from "./tableConfig";
import $ from "jquery";
import * as Cookies from "../utils/cookies";
import listColumnsJSON from "../utils/list-columns";
import SelectedContainer from "../detail/selected_container";
import Button from "react-bootstrap/lib/Button";
import LoadingContainer from "./LoadingContainer/index";
import EntityCreateModal from "../modal/entity_create";
let datasource;
let listStartY;
let listStartHeight;
let listQuery;

export default class ListView extends React.Component {
  constructor(props) {
    super(props);
    let type = this.props.type;
    let id = this.props.id;
    let queryType = this.props.type;
    let alertPreSelectedId = null;
    let scrollHeight = $(window).height() - 170 + "px";
    let scrollWidth = "650px";
    let showSelectedContainer = false;
    let sort = [{ id: "id", desc: true }];
    let activepage = { page: 0, limit: 50 };
    let filter = [];

    let columnsDisplay = listColumnsJSON.columnsDisplay[this.props.type];
    let columns = listColumnsJSON.columns[this.props.type];
    let columnsClassName = listColumnsJSON.columnsClassName[this.props.type];

    if (this.props.listViewSort != null) {
      sort = JSON.parse(this.props.listViewSort);
    }

    if (this.props.listViewPage != null) {
      activepage = JSON.parse(this.props.listViewPage);
    }

    if (this.props.listViewFilter != null) {
      filter = JSON.parse(this.props.listViewFilter);
    }

    if (this.props.type === "alert") {
      showSelectedContainer = false;
      typeCapitalized = "Alertgroup";
      type = "alertgroup";
      queryType = "alertgroup";
      alertPreSelectedId = id;
    }

    if (this.props.type === "task") {
      type = "task";
      queryType = this.props.queryType;
    }

    let typeCapitalized = this.titleCase(this.props.type);
    this.state = {
      togglePreventClick: false,
      splitter: true,
      selectedColor: "#AEDAFF",
      sourcetags: [],
      tags: [],
      startepoch: "",
      endepoch: "",
      idtext: "",
      totalCount: 0,
      activepage: activepage,
      statustext: "",
      subjecttext: "",
      idsarray: [],
      classname: [" ", " ", " ", " "],
      alldetail: true,
      viewsarrow: [0, 0],
      idarrow: [-1, -1],
      subjectarrow: [0, 0],
      statusarrow: [0, 0],
      resize: "horizontal",
      createdarrow: [0, 0],
      sourcearrow: [0, 0],
      tagsarrow: [0, 0],
      viewstext: "",
      entriestext: "",
      scrollheight: scrollHeight,
      display: "flex",
      differentviews: "",
      maxwidth: "915px",
      maxheight: scrollHeight,
      minwidth: "650px",
      suggestiontags: [],
      suggestionssource: [],
      sourcetext: "",
      tagstext: "",
      scrollwidth: scrollWidth,
      reload: false,
      viewfilter: false,
      viewevent: false,
      showevent: true,
      objectarray: [],
      csv: true,
      fsearch: "",
      listViewOrientation: "landscape-list-view",
      columns: listColumnsJSON.columns[this.props.type],
      columnsDisplay: listColumnsJSON.columnsDisplay[this.props.type],
      columnsClassName: listColumnsJSON.columnsClassName[this.props.type],
      typeCapitalized: typeCapitalized,
      type: type,
      queryType: queryType,
      id: id,
      showSelectedContainer: showSelectedContainer,
      listViewContainerDisplay: null,
      viewMode: this.props.viewMode,
      offset: 0,
      sort: sort,
      filter: filter,
      match: null,
      alertPreSelectedId: alertPreSelectedId,
      entryid: this.props.id2,
      listViewKey: 1,
      loading: true,
      initialAutoScrollToId: false,
      manualScrollHeight: null,
      showEntityCreateModal: false,
      form: []
    };
    this.handleRowSelection = this.handleRowSelection.bind(this);
  }

  componentWillMount = () => {
    if (
      this.props.viewMode === undefined ||
      this.props.viewMode === "default"
    ) {
      this.Landscape();
    } else if (this.props.viewMode === "landscape") {
      this.Landscape();
    } else if (this.props.viewMode === "portrait") {
      this.Portrait();
    }
    //If alert id is passed, convert the id to its alertgroup id.
    if (this.props.id) {
      this.ConvertAlertIdToAlertgroupId(this.props.id);
    }

    //if the type is entry, convert the id and type to the actual type and id
    this.ConvertEntryIdToType(this.props.id);

    $.ajax({
      type: "get",
      url: "/scot/api/v2/form",
      success: function(data) {
        this.setState({ form: data });
      }.bind(this),
      error: function(data) {
        this.props.errorToggle("Failed to get form structure", data);
      }.bind(this)
    });
  };

  componentDidMount = () => {
    let height = this.state.scrollheight;
    let sortBy = this.state.sort;
    let filterBy = this.state.filter;
    let pageLimit = this.state.activepage.limit;
    let pageNumber = this.state.activepage.page;
    let idsarray = [];
    let newPage;
    if (this.props.id !== undefined) {
      if (this.props.id.length > 0) {
        array = this.props.id;
        //scrolled = $('.container-fluid2').scrollTop()
        if (this.state.viewMode === "landscape") {
          height = "30vh";
        }
      }
    }

    let array = [];
    let finalarray = [];
    //register for creation
    let storeKey = this.props.type + ":listview";
    this.props.createCallback(storeKey, this.reloadactive);
    // Store.storeKey(storeKey);
    // Store.addChangeListener(this.reloadactive);
    //List View code
    let url = "/scot/api/v2/" + this.state.type;
    if (this.props.type === "alert") {
      url = "/scot/api/v2/alertgroup";
    }

    //get page number
    newPage = pageNumber * pageLimit;
    let data = { limit: pageLimit, offset: newPage };

    //add sort to the data object
    if (sortBy !== undefined || sortBy === null) {
      let sortObj = {};
      $.each(sortBy, function(key, value) {
        let sortInt = -1;
        if (!value.desc) {
          sortInt = 1;
        }
        sortObj[value.id] = sortInt;
      });
      data["sort"] = JSON.stringify(sortObj);
    }

    //add filter to the data object
    if (sortBy !== undefined || sortBy === null) {
      $.each(filterBy, function(key, value) {
        if (value.id === "source" || value.id === "tag") {
          let stringArr = [];
          for (let each of value.value) {
            stringArr.push(each.name);
          }
          data[value.id] = JSON.stringify(stringArr);
        } else if (value.id === "created" || value.id === "updated") {
          let arr = [];
          arr.push(value.value.start);
          arr.push(value.value.end);
          data[value.id] = JSON.stringify(arr);
        } else {
          data[value.id] = JSON.stringify(value.value);
        }
      });
    }

    listQuery = $.ajax({
      type: "GET",
      url: url,
      data: data,
      traditional: true,
      success: function(response) {
        datasource = response;
        $.each(
          datasource.records,
          function(key, value) {
            finalarray[key] = {};
            $.each(
              value,
              function(num, item) {
                if (num === "sources" || num === "source") {
                  if (item !== undefined) {
                    let sourcearr = item.join(", ");
                    finalarray[key]["source"] = sourcearr;
                  }
                } else if (num === "tags" || num === "tag") {
                  if (item !== undefined) {
                    let tagarr = item.join(", ");
                    finalarray[key]["tag"] = tagarr;
                  }
                } else {
                  finalarray[key][num] = item;
                }
                if (num === "id") {
                  this.props.createCallback(item, this.reloadactive);
                  idsarray.push(item);
                }
              }.bind(this)
            );
            if (key % 2 === 0) {
              finalarray[key]["classname"] = "table-row roweven";
            } else {
              finalarray[key]["classname"] = "table-row rowodd";
            }
          }.bind(this)
        );

        let totalPages = this.getPages(response.totalRecordCount); //get pages for list view

        this.setState({
          scrollheight: height,
          objectarray: finalarray,
          totalCount: response.totalRecordCount,
          loading: false,
          idsarray: idsarray,
          totalPages: totalPages
        });
        if (
          this.props.type === "alert" &&
          this.state.showSelectedContainer === false
        ) {
          this.setState({ showSelectedContainer: false });
        } else if (this.state.id === undefined || this.state.id === null) {
          this.setState({ showSelectedContainer: false });
        } else {
          this.setState({ showSelectedContainer: true });
        }
      }.bind(this),
      error: function(data) {
        if (!data.statusText === "abort") {
          this.props.errorToggle("failed to get list data", data);
        }
      }.bind(this)
    });

    $("#list-view-container").keydown(this.keyNavigate);

    $(document.body).keydown(
      function(e) {
        if ($("input").is(":focus")) {
          return;
        }
        if ($("textarea").is(":focus")) {
          return;
        }
        if (e.keyCode === 70 && (e.ctrlKey !== true && e.metaKey !== true)) {
          this.toggleView();
        }
      }.bind(this)
    );
  };

  componentWillUnmount = () => {
    document.removeEventListener("keydown", this.keyNavigate);
  };

  togglePreventClick = () => {
    this.setState({ preventClick: !this.state.preventClick });
  };

  keyNavigate = event => {
    if (event.type !== "click") {
      if (!["j", "k", "ArrowUp", "ArrowDown"].includes(event.key)) {
        return;
      }

      let target = event.target || event.srcElement;
      let targetType = target.tagName.toLowerCase();
      if (targetType === "input" || targetType === "textarea") {
        return;
      }
    }

    let curRow = document.querySelector(
      ".ReactTable .rt-tbody .rt-tr.selected"
    );
    if (!curRow) {
      return;
    }
    let nextRow = null;

    switch (event.key) {
      case "j":
      case "ArrowDown":
      default:
        nextRow = curRow.parentElement.nextElementSibling;
        break;
      case "k":
      case "ArrowUp":
        nextRow = curRow.parentElement.previousElementSibling;
        break;
    }

    if (!nextRow) {
      return;
    }
    let nextId = nextRow.children[0].children[0].innerHTML;

    this.props.history.push(`/${this.state.type}/${nextId}`);

    event.preventDefault();
    event.stopPropagation();
  };

  //Callback for AMQ updates
  reloadactive = () => {
    this.getNewData();
  };

  ToggleCreateEntity = () => {
    this.setState({ showEntityCreateModal: !this.state.showEntityCreateModal });
  };

  render = () => {
    let listViewContainerHeight;
    let showClearFilter = false;
    let scrollheight = this.state.scrollheight;

    if (this.state.listViewContainerDisplay == null) {
      listViewContainerHeight = null;
    } else {
      listViewContainerHeight = "0px";
    }

    if (this.state.id != null && this.state.typeCapitalized != null) {
      document.title =
        this.state.typeCapitalized.charAt(0) + "-" + this.state.id;
    }

    if (
      Cookies.checkCookie("listViewFilter" + this.props.type) != null ||
      Cookies.checkCookie("listViewSort" + this.props.type) != null ||
      Cookies.checkCookie("listViewPage" + this.props.type) != null
    ) {
      showClearFilter = true;
    }

    let columns = buildTypeColumns(this.props.type, {}, {}, false);

    return (
      <div>
        {this.state.type !== "entry" ? (
          <div key={this.state.listViewKey} className="allComponents">
            <div className="black-border-line">
              <div className="mainview">
                <div>
                  <div className="list-buttons">
                    {this.props.notificationSetting === "on" ? (
                      <Button
                        eventkey="1"
                        onClick={this.props.notificationToggle}
                        bsSize="xsmall"
                      >
                        Mute Notifications
                      </Button>
                    ) : (
                      <Button
                        eventkey="2"
                        onClick={this.props.notificationToggle}
                        bsSize="xsmall"
                      >
                        Turn On Notifications
                      </Button>
                    )}
                    {this.props.type === "event" ||
                    this.props.type === "intel" ||
                    this.props.type === "incident" ||
                    this.props.type === "signature" ||
                    this.props.type === "guide" ||
                    this.props.type === "entity" ? (
                      <Button
                        onClick={this.createNewThing}
                        eventkey="6"
                        bsSize="xsmall"
                      >
                        Create {this.state.typeCapitalized}
                      </Button>
                    ) : null}
                    <Button
                      eventkey="5"
                      bsSize="xsmall"
                      onClick={this.exportCSV}
                    >
                      Export to CSV
                    </Button>
                    <Button bsSize="xsmall" onClick={this.toggleView}>
                      Full Screen Toggle (f)
                    </Button>
                    {showClearFilter ? (
                      <Button
                        onClick={this.clearAll}
                        eventkey="3"
                        bsSize="xsmall"
                        bsStyle={"info"}
                      >
                        Clear All Filters
                      </Button>
                    ) : null}
                  </div>
                  <div id="list-view-container" tabIndex="1">
                    <div id="list-view" tabIndex="2">
                      <ReactTable
                        columns={columns}
                        data={this.state.objectarray}
                        style={{
                          maxHeight: scrollheight
                        }}
                        page={this.state.activepage.page}
                        pages={this.state.totalPages}
                        defaultPageSize={50}
                        onPageChange={this.handlePageChange}
                        onPageSizeChange={this.handlePageSizeChange}
                        pageSize={this.state.activepage.limit}
                        onFilteredChange={this.handleFilter}
                        filtered={this.state.filter}
                        onSortedChange={this.handleSort}
                        sorted={this.state.sort}
                        manual={true}
                        sortable={true}
                        filterable={true}
                        resizable={true}
                        styleName="styles.ReactTable"
                        className="-striped -highlight"
                        minRows={0}
                        LoadingComponent={this.CustomTableLoader}
                        loading={this.state.loading}
                        getTrProps={this.handleRowSelection}
                      />
                    </div>
                  </div>
                  <div
                    onMouseDown={this.dragdiv}
                    className="splitter"
                    style={{
                      display: "block",
                      height: "10px",
                      backgroundColor: "black",
                      borderTop: "1px solid #AAA",
                      borderBottom: "1px solid #AAA",
                      cursor: "row-resize",
                      overflow: "hidden"
                    }}
                  />
                  {this.state.showSelectedContainer ? (
                    <SelectedContainer
                      key={this.state.id}
                      id={this.state.id}
                      type={this.state.queryType}
                      alertPreSelectedId={this.state.alertPreSelectedId}
                      taskid={this.state.entryid}
                      handleFilter={this.handleFilter}
                      errorToggle={this.props.errorToggle}
                      history={this.props.history}
                      togglePreventClick={this.togglePreventClick}
                      form={this.state.form}
                      createCallback={this.props.createCallback}
                      removeCallback={this.props.removeCallback}
                      togglePreventClick={this.togglePreventClick}
                    />
                  ) : null}
                  {this.state.showEntityCreateModal ? (
                    <EntityCreateModal
                      match={""}
                      modalActive={this.state.showEntityCreateModal}
                      ToggleCreateEntity={this.ToggleCreateEntity}
                      errorToggle={this.props.errorToggle}
                    />
                  ) : null}
                </div>
              </div>
            </div>
          </div>
        ) : null}
      </div>
    );
  };

  CustomTableLoader = () => {
    return (
      <div className={"-loading" + (this.state.loading ? " -active" : "")}>
        <LoadingContainer loading={this.state.loading} />
      </div>
    );
  };

  AutoScrollToId = () => {
    //auto scrolls to selected id
    let row = document.querySelector(".ReactTable .rt-tbody .rt-tr.selected");
    let tbody = document.querySelector(".ReactTable .rt-tbody");

    if (!row) {
      tbody.scrollTop = 0;
      return;
    }

    if (
      tbody.scrollTop + tbody.offsetHeight - row.offsetHeight < row.offsetTop ||
      row.offsetTop < tbody.scrollTop
    ) {
      tbody.scrollTop =
        row.offsetTop - tbody.offsetHeight / 2 + row.offsetHeight / 2;
    }

    this.setState({ initialAutoScrollToId: true });
  };

  componentDidUpdate = (prevProps, prevState) => {
    //auto scrolls to selected id
    for (let i = 0; i < this.state.objectarray.length; i++) {
      //Iterate through all of the items in the list to verify that the current id still matches the rows in the list. If not, don't scroll
      let idReference = this.state.objectarray[i].id;
      if (
        (this.state.id != null &&
          this.state.id === idReference &&
          this.state.id !== prevState.id) ||
        (this.state.id != null &&
          this.state.id === idReference &&
          prevState.initialAutoScrollToId === false)
      ) {
        //Checks that the id is present, is on the screen, and will not be kicked off again if its already been scrolled to before. The || statement handles the initial load since the id hasn't been scrolled to before.
        setTimeout(this.AutoScrollToId, 300);
      }
    }
  };

  componentWillReceiveProps = nextProps => {
    if (nextProps.id === undefined) {
      this.setState({
        type: nextProps.type,
        id: null,
        showSelectedContainer: false,
        scrollheight: $(window).height() - 170 + "px"
      });
    } else if (nextProps.id !== this.props.id) {
      if (this.props.type === "alert") {
        this.ConvertAlertIdToAlertgroupId(nextProps.id);
        this.ConvertEntryIdToType(nextProps.id);
        this.setState({
          type: nextProps.type,
          alertPreSelectedId: nextProps.id
        });
      } else if (this.props.type === "task") {
        this.setState({
          type: nextProps.type,
          queryType: nextProps.queryType,
          id: nextProps.id,
          entryid: nextProps.id2
        });
      } else {
        this.setState({ type: nextProps.type, id: nextProps.id });
      }
    }
  };

  ConvertAlertIdToAlertgroupId = id => {
    //if the type is alert, convert the id to the alertgroup id
    if (this.props.type === "alert") {
      $.ajax({
        type: "get",
        url: "scot/api/v2/alert/" + id,
        success: function(response1) {
          let newresponse = response1;
          this.setState({
            id: newresponse.alertgroup,
            showSelectedContainer: true
          });
        }.bind(this),
        error: function(data) {
          this.props.errorToggle(
            "failed to convert alert id to alertgroup id",
            data
          );
        }.bind(this)
      });
    }
  };

  ConvertEntryIdToType = id => {
    //if the type is alert, convert the id to the alertgroup id
    if (this.props.type === "entry") {
      $.ajax({
        type: "get",
        url: "scot/api/v2/entry/" + id,
        async: false,
        success: function(response) {
          this.selected(
            response.target.type,
            response.target.id,
            this.props.id
          );
          //this.setState({id: response.target.id, type: response.target.type, showSelectedContainer:true});
        }.bind(this),
        error: function(data) {
          this.props.errorToggle(
            "failed to convert alert id to alertgroup id",
            data
          );
        }.bind(this)
      });
    }
  };

  //This is used for the dragging portrait and landscape views
  startdrag = e => {
    $("iframe").each(function(index, ifr) {
      $(ifr).addClass("pointerEventsOff");
    });

    this.setState({
      manualScrollHeight: listStartHeight + e.clientY - listStartY + "px",
      scrollheight: listStartHeight + e.clientY - listStartY + "px"
    });
  };

  stopdrag = e => {
    $("iframe").each(function(index, ifr) {
      $(ifr).removeClass("pointerEventsOff");
    });
    document.onmousemove = null;
  };

  dragdiv = e => {
    if (e.preventDefault) {
      e.preventDefault();
    }
    if (e.stopPropagation) {
      e.stopPropagation();
    }
    let elem = document.getElementsByClassName("ReactTable");
    listStartY = e.clientY;
    listStartHeight = parseInt(
      document.defaultView.getComputedStyle(elem[0]).height,
      10
    );
    document.onmousemove = this.startdrag;
    document.onmouseup = this.stopdrag;
  };

  toggleView = () => {
    if (
      this.state.id.length !== 0 &&
      this.state.showSelectedContainer === true &&
      this.state.listViewContainerDisplay !== "none"
    ) {
      this.setState({ listViewContainerDisplay: "none", scrollheight: "0px" });
    } else {
      this.setState({ listViewContainerDisplay: null, scrollheight: "30vh" });
    }
  };

  Landscape = () => {
    document.onmousemove = null;
    document.onmousedown = null;
    document.onmouseup = null;
    $(".splitter").css("width", "100%");
    $(".mainview").show();
    this.setState({
      classname: [" ", " ", " ", " "],
      splitter: false,
      display: "block",
      maxheight: "",
      alldetail: true,
      differentviews: "100%",
      scrollheight:
        this.state.id != null ? "300px" : $(window).height() - 170 + "px",
      maxwidth: "",
      minwidth: "",
      scrollwidth: "100%",
      resize: "vertical"
    });
    this.setState({ listViewOrientation: "landscape-list-view" });
    Cookies.setCookie("viewMode", "landscape", 1000);
  };

  clearAll = () => {
    let newListViewKey = this.state.listViewKey + 1;
    this.setState({
      listViewKey: newListViewKey,
      activepage: { page: 0, limit: this.state.activepage.limit },
      sort: [{ id: "id", desc: true }],
      filter: []
    });
    this.getNewData({ page: 0 }, [{ id: "id", desc: true }], {});
    Cookies.deleteCookie("listViewFilter" + this.props.type); //clear filter cookie
    Cookies.deleteCookie("listViewSort" + this.props.type); //clear sort cookie
    Cookies.deleteCookie("listViewPage" + this.props.type); //clear page cookie
  };

  selected = (type, rowid, subid, taskid) => {
    let scrollheight;
    if (taskid == null && subid == null) {
      //window.history.pushState('Page', 'SCOT', '/#/' + type +'/'+rowid)
      this.props.history.push("/" + type + "/" + rowid);
    } else if (taskid == null && subid != null) {
      this.props.history.push("/" + type + "/" + rowid + "/" + subid);
    } else {
      //If a task, swap the rowid and the taskid
      //window.history.pushState('Page', 'SCOT', '/#/' + type + '/' + taskid + '/' + rowid)
      this.props.history.push("/" + type + "/" + taskid + "/" + rowid + "/");
    }

    if (this.state.display === "block") {
      scrollheight = "30vh";
    }

    this.setState({
      alertPreSelectedId: 0,
      scrollheight: scrollheight,
      showSelectedContainer: true
    });
  };

  getNewData = (page, sort, filter) => {
    this.setState({ loading: true }); //display loading opacity
    let sortBy = sort;
    let filterBy = filter;
    let pageLimit;
    let pageNumber;
    let idsarray = this.state.idsarray;
    let newidsarray = [];

    //if the type is alert, convert the id to the alertgroup id
    this.ConvertAlertIdToAlertgroupId(this.props.id);

    //if the type is entry, convert the id and type to the actual type and id
    this.ConvertEntryIdToType(this.props.id);

    //defaultpage = page.page
    if (page == undefined) {
      pageNumber = this.state.activepage.page;
      pageLimit = this.state.activepage.limit;
    } else {
      if (page.page == undefined) {
        pageNumber = this.state.activepage.page;
      } else {
        pageNumber = page.page;
      }
      if (page.limit == undefined) {
        pageLimit = this.state.activepage.limit;
      } else {
        pageLimit = page.limit;
      }
    }
    let newPage;
    newPage = pageNumber * pageLimit;
    //sort check
    if (sortBy == undefined) {
      sortBy = this.state.sort;
    }
    //filter check
    if (filterBy == undefined) {
      filterBy = this.state.filter;
    }
    let data = { limit: pageLimit, offset: newPage };

    //add sort to the data object
    if (sortBy != undefined) {
      let sortObj = {};
      $.each(sortBy, function(key, value) {
        let sortInt = -1;
        if (!value.desc) {
          sortInt = 1;
        }
        sortObj[value.id] = sortInt;
      });
      data["sort"] = JSON.stringify(sortObj);
    }

    //add filter to the data object
    if (filterBy != undefined) {
      $.each(filterBy, function(key, value) {
        if (value.id == "source" || value.id == "tag") {
          let stringArr = [];
          for (let each of value.value) {
            stringArr.push(each.name);
          }
          data[value.id] = JSON.stringify(stringArr);
        } else if (
          value.id == "created" ||
          value.id == "updated" ||
          value.id == "occurred"
        ) {
          let arr = [];
          arr.push(value.value.start);
          arr.push(value.value.end);
          data[value.id] = JSON.stringify(arr);
        } else {
          data[value.id] = JSON.stringify(value.value);
        }
      });
    }

    let newarray = [];

    //Update 5/17/18 - removed below check as it was breaking clicking on an alert in alert group, closing alert and then immediately switching to a new alert group would cancel ajax call and majorly lag network traffic
    if (this.state.loading == true) {
      listQuery.abort();
    }
    listQuery = $.ajax({
      type: "GET",
      url: "/scot/api/v2/" + this.state.type,
      data: data,
      traditional: true,
      success: function(response) {
        datasource = response;
        $.each(
          datasource.records,
          function(key, value) {
            newarray[key] = {};
            $.each(
              value,
              function(num, item) {
                if (num == "sources" || num == "source") {
                  if (item != undefined) {
                    let sourcearr = item.join(", ");
                    newarray[key]["source"] = sourcearr;
                  }
                } else if (num == "tags" || num == "tag") {
                  if (item != undefined) {
                    let tagarr = item.join(", ");
                    newarray[key]["tag"] = tagarr;
                  }
                } else {
                  newarray[key][num] = item;
                }
                if (num == "id") {
                  this.props.createCallback(item, this.reloadactive);
                  newidsarray.push(item);
                }
              }.bind(this)
            );
            if (key % 2 == 0) {
              newarray[key]["classname"] = "table-row roweven";
            } else {
              newarray[key]["classname"] = "table-row rowodd";
            }
          }.bind(this)
        );

        let totalPages = this.getPages(response.totalRecordCount); //get pages for list view

        this.setState({
          totalCount: response.totalRecordCount,
          activepage: { page: pageNumber, limit: pageLimit },
          objectarray: newarray,
          loading: false,
          idsarray: newidsarray,
          totalPages: totalPages
        });
      }.bind(this),
      error: function(data) {
        if (!data.statusText == "abort") {
          this.props.errorToggle("failed to get list data", data);
        }
      }.bind(this)
    });
  };

  exportCSV = () => {
    let keys = [];
    let columns = this.state.columns;
    $.each(columns, function(key, value) {
      keys.push(value);
    });
    let csv = "";
    $(".rt-tbody")
      .find(".rt-tr")
      .each(function(key, value) {
        let storearray = [];
        $(value)
          .find(".rt-td")
          .each(function(x, y) {
            let obj = $(y).text();
            obj = obj.replace(/,/g, "|");
            storearray.push(obj);
          });
        csv += storearray.join() + "\n";
      });
    let result = keys.join() + "\n";
    csv = result + csv;
    let data_uri = "data:text/csv;charset=utf-8," + encodeURIComponent(csv);
    window.open(data_uri);
  };

  handleSort = (sortArr, clearall) => {
    let newSortArr = [];

    if (clearall === true) {
      this.setState({ sort: [{ id: "id", desc: true }] });
    } else {
      for (let sortEach of sortArr) {
        if (sortEach.id) {
          newSortArr.push(sortEach);
        }
      }
    }

    this.setState({ sort: newSortArr });
    this.getNewData(null, newSortArr, null);
    let cookieName = "listViewSort" + this.props.type;
    Cookies.setCookie(cookieName, JSON.stringify(newSortArr), 1000);
  };

  handleFilter = (filterObj, string, clearall, type) => {
    let newFilterArr = [];
    let _type = this.props.type;

    if (type !== undefined) {
      _type = type;
    }

    if (clearall === true) {
      this.setState({ filter: newFilterArr });
      return;
    } else {
      for (let filterEach of filterObj) {
        if (filterEach.id) {
          newFilterArr.push(filterEach);
        }
      }

      this.setState({ filter: newFilterArr });

      if (type === this.props.type || type === undefined) {
        //Check if the type passed in matches the type displayed. If not, it's updating the filter for a future query in a different type. Undefined implies its the same type, so update
        this.getNewData({ page: 0 }, null, newFilterArr);
      }

      let cookieName = "listViewFilter" + _type;
      Cookies.setCookie(cookieName, JSON.stringify(newFilterArr), 1000);
    }
  };

  titleCase = string => {
    let newstring = string.charAt(0).toUpperCase() + string.slice(1);
    return newstring;
  };

  createNewThing = () => {
    let data;

    if (this.props.type === "signature") {
      data = JSON.stringify({
        name: "Name your Signature",
        status: "disabled"
      });
    } else if (this.props.type === "guide") {
      data = JSON.stringify({
        subject: "ENTER A GUIDE NAME",
        applies_to: ["documentation"]
      });
    } else if (this.props.type === "entity") {
      this.ToggleCreateEntity();
      return;
    } else {
      data = JSON.stringify({ subject: "No Subject" });
    }

    $.ajax({
      type: "POST",
      url: "/scot/api/v2/" + this.props.type,
      data: data,
      success: function(response) {
        this.selected(this.props.type, response.id);
      }.bind(this),
      error: function(data) {
        this.props.errorToggle("failed to create new thing", data);
      }.bind(this)
    });
  };

  handlePageChange = pageIndex => {
    this.getNewData({ page: pageIndex });
    let cookieName = "listViewPage" + this.props.type;
    Cookies.setCookie(
      cookieName,
      JSON.stringify({ page: pageIndex, limit: this.state.activepage.limit })
    );
  };

  handlePageSizeChange = (pageSize, pageIndex) => {
    this.getNewData({ limit: pageSize, page: pageIndex });
    let cookieName = "listViewPage" + this.props.type;
    Cookies.setCookie(
      cookieName,
      JSON.stringify({ page: pageIndex, limit: pageSize })
    );
  };

  getPages = count => {
    let totalPages = Math.ceil((count || 1) / this.state.activepage.limit);
    return totalPages;
  };

  handleRowSelection(state, rowInfo, column, instance) {
    return {
      onClick: event => {
        if (this.state.preventClick !== true) {
          if (this.state.id === rowInfo.row.id) {
            return;
          }
          let scrollheight = this.state.scrollheight;
          if (this.state.display == "block") {
            scrollheight = "30vh";
          }
          if (this.state.type === "task") {
            this.props.history.push(
              "/task/" +
                rowInfo.row.target_type +
                "/" +
                rowInfo.row.target_id +
                "/" +
                rowInfo.row.id
            );
          } else {
            this.props.history.push(
              "/" + this.state.type + "/" + rowInfo.row.id
            );
          }
          this.setState({
            alertPreSelectedId: 0,
            scrollheight: scrollheight,
            showSelectedContainer: true
          });
          return;
        } else {
          this.props.errorToggle(
            "Currently processing action(s). Please wait."
          );
        }
      },
      className: rowInfo.row.id === parseInt(this.props.id) ? "selected" : null
    };
  }
}
