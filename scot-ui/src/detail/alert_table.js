import React from "react";
import ReactTable from "react-table";
import AlertSubComponent from "./alert_subcomponent";
import { buildTypeColumns } from "../list/tableConfig";
import $ from "jquery";

export default class NewAlertTable extends React.Component {
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
      const columns = buildTypeColumns("alert", data, this.props.items);
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
                  borderBottom: "1px solid black"
                }
              };
            } else {
              return { style: {} };
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
