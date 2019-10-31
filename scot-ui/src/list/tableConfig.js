import React from "react";
import { OverlayTrigger, ButtonGroup, Button, Popover } from "react-bootstrap";
import DateRangePicker from "react-daterange-picker";
import DebounceInput from "react-debounce-input";
import {
  epochRangeToString,
  epochRangeToMoment,
  momentRangeToEpoch
} from "../utils/time";
import * as constants from "../utils/constants";
import LoadingContainer from "./LoadingContainer";
import TagInput from "../components/TagInput";
import Button2 from "@material-ui/core/Button";
import { get_data } from "../utils/XHR";
import Add from "@material-ui/icons/Add";
import stripHtml from "string-strip-html";
import { Link } from "react-router-dom";

const navigateTo = id => {
  window.open("#/event/" + id);
};

const customFilters = {
  numberFilter: ({ filter, onChange }) => (
    <DebounceInput
      debounceTimeout={200}
      type="number"
      minLength={1}
      min={0}
      value={filter ? filter.value : ""}
      onChange={e => onChange(e.target.value)}
      style={{ width: "100%" }}
    />
  ),
  stringFilter: ({ filter, onChange }) => (
    <DebounceInput
      debounceTimeout={200}
      minLength={1}
      value={filter ? filter.value : ""}
      onChange={e => onChange(e.target.value)}
      style={{ width: "100%" }}
    />
  ),
  dropdownFilter: (options = ["open", "closed", "promoted"], align) => ({
    filter,
    onChange
  }) => (
    <OverlayTrigger
      trigger="focus"
      placement="bottom"
      overlay={
        <Popover id="status_popover" style={{ maxWidth: "400px" }}>
          <ButtonGroup
            vertical
            style={{
              maxHeight: "50vh",
              overflowY: "auto",
              position: "relative"
            }}
          >
            {options.map(option => (
              <Button
                key={option}
                onClick={() => onChange(option)}
                active={filter && filter.value === option}
                style={{
                  textTransform: "capitalize",
                  textAlign: align ? align : null
                }}
              >
                {option}
              </Button>
            ))}
          </ButtonGroup>
          {filter && (
            <Button
              block
              onClick={() => onChange("")}
              bsStyle="primary"
              style={{ marginTop: "3px" }}
            >
              Clear
            </Button>
          )}
        </Popover>
      }
    >
      <input
        type="text"
        value={filter ? filter.value : ""}
        readOnly
        style={{ width: "100%", cursor: "pointer" }}
      />
    </OverlayTrigger>
  ),
  dateRange: ({ filter, onChange }) => (
    <OverlayTrigger
      trigger="click"
      rootClose
      placement="bottom"
      overlay={
        <Popover id="daterange_popover" style={{ maxWidth: "350px" }}>
          <DateRangePicker
            numberOfCalendars={2}
            selectionType="range"
            showLegend={false}
            singleDateRange={true}
            onSelect={(range, states) => {
              onChange(momentRangeToEpoch(range));
            }}
            value={filter ? epochRangeToMoment(filter.value) : null}
          />
          {filter && (
            <Button
              block
              onClick={() => {
                onChange("");
                document.dispatchEvent(new MouseEvent("click"));
              }}
              bsStyle="primary"
            >
              Clear
            </Button>
          )}
        </Popover>
      }
    >
      <input
        type="text"
        value={filter ? epochRangeToString(filter.value) : ""}
        readOnly
        style={{ width: "100%", cursor: "pointer" }}
      />
    </OverlayTrigger>
  ),
  tagFilter: (type = "tag") => ({ filter, onChange }) => (
    <TagInput
      type={type}
      onChange={onChange}
      value={filter ? filter.value : []}
    />
  )
};

export const customCellRenderers = {
  dateFormater: row => {
    let date = new Date(row.value * 1000);
    return <span>{date.toLocaleString()}</span>;
  },
  alertStatus: row => {
    let [open, closed, promoted] = row.value
      .split("/")
      .map(value => parseInt(value.trim(), 10));
    let className = "open btn-danger";
    if (promoted) {
      className = "promoted btn-warning";
    } else if (closed) {
      if (!open) {
        className = "closed btn-success";
      }
    }

    return <div className={`alertStatusCell ${className}`}>{row.value}</div>;
  },
  textStatus: row => {
    let color = "green";
    if (
      row.value === "open" ||
      row.value === "disabled" ||
      row.value === "assigned"
    ) {
      color = "red";
    } else if (row.value === "promoted") {
      color = "orange";
    }

    return <span style={{ color: color }}>{row.value}</span>;
  },

  alertStatusAlerts: row => {
    return (
      <div style={{ display: "flex", justifyContent: "center" }}>
        <PromotionButton row={row} />
      </div>
    );
  },
  flairCell: row => {
    if (row !== undefined) {
      return <FlairObject value={row.value} />;
    } else {
      return null;
    }
  }
};

const customTableComponents = {
  loading: ({ loading }) => (
    <div className={"-loading" + (loading ? " -active" : "")}>
      <LoadingContainer loading={loading} />
    </div>
  )
};

const columnDefinitions = {
  Id: {
    Header: "ID",
    accessor: "id",
    width: 80,
    Filter: customFilters.numberFilter
  },

  AlertStatus: {
    Header: "Status",
    accessor: d =>
      d.open_count + " / " + d.closed_count + " / " + d.promoted_count,
    column: ["open_count", "closed_count", "promoted_count"],
    id: "status",
    width: 150,
    Filter: customFilters.dropdownFilter(),
    Cell: customCellRenderers.alertStatus,
    style: {
      padding: 0
    }
  },

  EventStatus: {
    Header: "Status",
    accessor: "status",
    maxWidth: 100,
    Cell: customCellRenderers.textStatus,
    Filter: customFilters.dropdownFilter()
  },

  IncidentStatus: {
    Header: "Status",
    accessor: "status",
    maxWidth: 100,
    Cell: customCellRenderers.textStatus,
    Filter: customFilters.dropdownFilter(["open", "closed"])
  },

  SigStatus: {
    Header: "Status",
    accessor: "status",
    maxWidth: 100,
    Cell: customCellRenderers.textStatus,
    Filter: customFilters.dropdownFilter(["enabled", "disabled"])
  },

  TaskStatus: {
    Header: "Task Status",
    accessor: d => d.metadata.task.status,
    id: "metadata.task.status",
    column: "metadata",
    Cell: customCellRenderers.textStatus,
    Filter: customFilters.dropdownFilter(["open", "assigned", "closed"])
  },

  TaskSummary: {
    Header: "Task Summary",
    accessor: d =>
      d.body_plain.length > 200
        ? d.body_plain.substr(0, 200) + "..."
        : d.body_plain,
    id: "summary",
    minWidth: 400,
    maxWidth: 5000,
    Filter: customFilters.stringFilter
  },

  Subject: {
    Header: "Subject",
    accessor: "subject",
    minWidth: 400,
    maxWidth: 5000,
    Filter: customFilters.stringFilter
  },

  Location: {
    Header: "Location",
    accessor: "location",
    minWidth: 80,
    maxWidth: 180,
    Filter: customFilters.stringFilter
  },

  Created: {
    Header: "Created",
    accessor: "created",
    minWidth: 100,
    maxWidth: 180,
    Filter: customFilters.dateRange,
    Cell: customCellRenderers.dateFormater
  },

  Updated: {
    Header: "Updated",
    accessor: "updated",
    minWidth: 100,
    maxWidth: 180,
    Filter: customFilters.dateRange,
    Cell: customCellRenderers.dateFormater
  },

  Occurred: {
    Header: "When",
    accessor: "when",
    minWidth: 100,
    maxWidth: 180,
    Filter: customFilters.dateRange,
    Cell: customCellRenderers.dateFormater
  },

  Sources: {
    Header: "Sources",
    accessor: "source", //d => d.source ? d.source.join( ', ' ) : '',
    column: "source",
    id: "source",
    minWidth: 120,
    //maxWidth: 150,
    Filter: customFilters.tagFilter("source")
  },

  Tags: {
    Header: "Tags",
    accessor: "tag", //d => d.tag ? d.tag.join( ', ' ) : '',
    column: "tag",
    id: "tag",
    minWidth: 120,
    //maxWidth: 150,
    Filter: customFilters.tagFilter("tag")
  },

  TaskOwner: {
    Header: "Task Owner",
    accessor: "owner",
    maxWidth: 80,
    Filter: customFilters.stringFilter
  },

  Owner: {
    Header: "Owner",
    accessor: "owner",
    maxWidth: 80,
    Filter: customFilters.stringFilter
  },

  Entries: {
    Header: "Entries",
    accessor: "entry_count",
    maxWidth: 70,
    Filter: customFilters.numberFilter
  },

  Views: {
    Header: "Views",
    accessor: "views",
    maxWidth: 70,
    Filter: customFilters.numberFilter
  },

  DOE: {
    Header: "DOE",
    accessor: "doe_report_id",
    maxWidth: 100,
    Filter: customFilters.stringFilter
  },

  IncidentType: {
    Header: "Type",
    accessor: "type",
    minWidth: 200,
    maxWidth: 250,
    Filter: customFilters.dropdownFilter(constants.INCIDENT_TYPES, "left")
  },

  AppliesTo: {
    Header: "Applies To",
    id: "data.applies_to",
    accessor: d => d.data.applies_to,
    //Filter: customFilters.stringFilter,
    Filter: customFilters.tagFilter,
    minWidth: 400,
    maxWidth: 5000
  },

  Value: {
    Header: "Value",
    accessor: "value",
    Filter: customFilters.stringFilter,
    minWidth: 400,
    maxWidth: 5000
  },

  Name: {
    Header: "Name",
    accessor: "name",
    Filter: customFilters.stringFilter,
    minWidth: 200,
    maxWidth: 300
  },

  Group: {
    Header: "Group",
    accessor: d =>
      d.data.signature_group ? d.data.signature_group.join(", ") : "",
    column: "signature_group",
    id: "data.signature_group",
    Filter: customFilters.stringFilter
  },

  Type: {
    Header: "Type",
    accessor: d => d.data.type,
    id: "data.type",
    Filter: customFilters.stringFilter,
    minWidth: 100,
    maxWidth: 150
  },

  EntityType: {
    Header: "Type",
    accessor: "type",
    Filter: customFilters.stringFilter,
    minWidth: 100,
    maxWidth: 150
  },

  Description: {
    Header: "Description",
    // accessor: 'description',
    accessor: d => d.data.description,
    Filter: customFilters.stringFilter,
    minWidth: 400,
    id: "data.description",
    maxWidth: 5000
  },

  TargetType: {
    Header: "Type",
    accessor: d => d.target.type,
    column: "target",
    id: "target_type",
    Filter: customFilters.stringFilter
  },

  TargetId: {
    Header: "Target Id",
    accessor: d => d.target.id,
    column: "target",
    id: "target_id",
    Filter: customFilters.numberFilter
  },

  OpenTasks: {
    Header: "Open Tasks",
    accessor: "has_tasks",
    Filter: customFilters.numberFilter,
    maxWidth: 90,
    filterable: false
  },

  //alert stuff - 2019 - bemonta
  Status: {
    accessor: "status",
    Header: "Status",
    width: 100,
    Cell: customCellRenderers.alertStatusAlerts
  },

  EntryCountColumn: {
    width: 50,
    resizable: true,
    expander: true,
    filter: false,

    accessor: "entry_count",
    Header: "Entries",
    Expander: ({ isExpanded, ...rest }) => {
      return (
        <div style={{ display: "flex", justifyContent: "center" }}>
          {isExpanded ? (
            <Button2
              variant="contained"
              style={{ backgroundColor: "orange", color: "white" }}
            >
              Close entries
            </Button2>
          ) : (
            <div>
              {rest.original.entry_count == 0 ? (
                <Add />
              ) : (
                <Button2
                  variant="contained"
                  size="small"
                  style={{ backgroundColor: "#5bc0de", color: "white" }}
                >
                  {rest.original.entry_count} entries
                </Button2>
              )}
            </div>
          )}
        </div>
      );
    },
    getProps: (state, rowInfo, column) => {
      return {
        className: "show-pointer"
      };
    }
  }
};

const defaultTableSettings = {
  manual: true,
  sortable: true,
  filterable: true,
  resizable: true,
  styleName: "styles.ReactTable",
  className: "-striped -highlight",
  minRows: 0,

  LoadingComponent: customTableComponents.loading
};

export const defaultTypeTableSettings = {
  page: 0,
  pageSize: 50,
  sorted: [
    {
      id: "id",
      desc: true
    }
  ],
  filtered: []
};

const defaultColumnSettings = {
  style: {
    padding: "5px 5px"
  }
};

const typeColumns = {
  alert: ["Id", "Status", "EntryCountColumn"],

  alertgroup: [
    "Id",
    "Location",
    "AlertStatus",
    "Subject",
    "Created",
    "Sources",
    "Tags",
    "Views",
    "OpenTasks"
  ],
  event: [
    "Id",
    "Location",
    "EventStatus",
    "Subject",
    "Created",
    "Updated",
    "Sources",
    "Tags",
    "Owner",
    "Entries",
    "Views",
    "OpenTasks"
  ],
  incident: [
    "Id",
    "Location",
    "DOE",
    "IncidentStatus",
    "Owner",
    "Subject",
    "Occurred",
    "IncidentType",
    {
      title: "Tags",
      options: { minWidth: 100, maxWidth: 150 }
    },
    {
      title: "Sources",
      options: { minWidth: 100, maxWidth: 150 }
    }
  ],
  intel: [
    "Id",
    "Location",
    "Subject",
    "Created",
    "Updated",
    "Sources",
    {
      title: "Tags",
      options: { minWidth: 200, maxWidth: 250 }
    },
    "Owner",
    "Entries",
    "Views"
  ],
  task: [
    "Id",
    "Location",
    "Subject",
    "TargetType",
    "TargetId",
    {
      title: "TaskOwner",
      options: { minWidth: 150, maxWidth: 500 }
    },
    "TaskStatus",
    "TaskSummary",
    {
      title: "Updated",
      options: { minWidth: 150, maxWidth: 500 }
    }
  ],
  signature: [
    "Id",
    "Location",
    "Name",
    "Type",
    "SigStatus",
    "Group",
    "Description",
    "Owner",
    "Tags",
    "Sources",
    "Updated"
  ],
  guide: ["Id", "Location", "Subject", "AppliesTo"],
  entity: ["Id", "Location", "Value", "EntityType", "Entries"],
  default: [
    "Id",
    "Location",
    "AlertStatus",
    "Subject",
    "Created",
    "Sources",
    "Tags",
    "Views"
  ]
};

export const buildTypeColumns = (type, rowData, propData, flag) => {
  function get_current_combined_columnWidths(columns) {
    let column_total_width = columns.reduce(function(a, b) {
      if (a.width !== undefined) {
        return a.width + b.width;
      } else {
        return a + b.width;
      }
    });
    return column_total_width;
  }

  if (!typeColumns.hasOwnProperty(type)) {
    // throw new Error( 'No columns defined for type: '+ type );
    type = "default";
  }

  if (flag === false && type === "alert") {
    type = "alertgroup";
  }

  let columns = [];
  for (let col of typeColumns[type]) {
    let colOptions = {};

    if (typeof col === "object") {
      colOptions = {
        ...columnDefinitions[col.title],
        ...col.options
      };
    } else if (typeof col === "string") {
      colOptions = columnDefinitions[col];
    }

    columns.push({
      ...defaultColumnSettings,
      ...colOptions
    });
  }

  if (type === "alert") {
    if (propData.length > 0) {
      if (propData[0].data.columns) {
        propData[0].data.columns.forEach(
          function(element, index) {
            if (element !== "status") {
              let columnobj = {
                accessor: element,
                Header: element,
                filter: true,
                Cell: row => customCellRenderers.flairCell(row),
                width: getColumnWidth(rowData, element, element)
              };
              columns.push(columnobj);
            } else {
              // Had to add space to account for SCOT status column which is a duplicate column.
              //React table hates duplicate columns. See SelectedEntry - NewAlertTable for data manipulation
              let status_code_obj = {
                accessor: "status ",
                Header: element,
                filter: true,
                Cell: row => customCellRenderers.flairCell(row),
                width: 80
              };
              columns.push(status_code_obj);
            }
          }.bind(this)
        );
      }
      columns.forEach(function(column, index) {
        column["getProps"] = function(state, rowInfo) {
          return {
            style: {
              backgroundColor: index % 2 === 0 ? "#bababa45" : ""
            }
          };
        };
      });
    }

    // this function looks at columns and calculates how many columns were initially set to 90
    // if it detects a column with width of 90 or time in name, it add an exception, meaning that we should not
    // increase this column
    let num_of_exemptions = 3;
    columns.forEach(function(column) {
      if (column.width === 90) {
        num_of_exemptions++;
      }
      if (column.accessor.includes("time")) {
        num_of_exemptions++;
      }
    });

    let windowsize = window.innerWidth - 32;
    //calculate column widths
    let column_total_width = get_current_combined_columnWidths(columns);

    //if below conditional true, then we have empty white space in table and should increase column widths
    if (column_total_width < windowsize) {
      let residual = windowsize - column_total_width;
      let residual_per_column = residual / (columns.length - num_of_exemptions);
      columns.forEach(
        function(column) {
          //each iteration, we want to calculate the total width of columns
          column_total_width = get_current_combined_columnWidths(columns);
          if (column_total_width < windowsize) {
            if (
              column.accessor !== "id" &&
              column.accessor !== "entry_count" &&
              column.accessor !== "status" &&
              column.width !== 90 &&
              column.accessor.includes("time") !== true
            ) {
              if (column.width + residual_per_column < residual) {
                column.width = column.width + residual_per_column;
                column_total_width = get_current_combined_columnWidths(columns);
              } else {
                column.width = column.width + residual;
              }
            }
          }
        }.bind(this)
      );
    }
  }

  return columns;
};

class FlairObject extends React.Component {
  constructor(props) {
    super(props);
  }

  render() {
    const { value } = this.props;

    return (
      <div
        style={{
          wordBreak: "break-word"
        }}
        className="alertTableHorizontal"
        dangerouslySetInnerHTML={{ __html: value }}
      />
    );
  }
}

export const getColumnWidth = (data, accessor, headerText) => {
  //get calc width of html element, we use this to calculate as accurate as possible, widths of headertext, and data in cellss
  function calc_width(input) {
    try {
      let strip = stripHtml(input);
      return strip.length;
    } catch {
      return input.length;
    }
  }

  if (typeof accessor === "string" || accessor instanceof String) {
    accessor = d => d[accessor]; // eslint-disable-line no-param-reassign
  }
  const maxWidth = 400;
  const magicSpacing = 9;
  const cellLength = Math.max(
    ...data.map(function(row) {
      let newtext = row[headerText];
      if (newtext !== undefined) {
        return calc_width(newtext);
      } else {
        return 0;
      }
    }),
    headerText.length
  );

  if (cellLength < 13 && headerText !== "status") {
    return 90;
  } else {
    return Math.min(maxWidth, cellLength * magicSpacing);
  }
};

class PromotionButton extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      element: null,
      loading: true
    };
  }

  componentDidUpdate(prevProps) {
    if (prevProps.row.value !== this.props.row.value) {
      this.getPromotionInfo(this.props.row.original.id).then(element => {
        if (element) {
          this.setState({ element });
        }
      });
    }
  }

  componentDidMount() {
    this.getPromotionInfo(this.props.row.original.id).then(element => {
      if (element) {
        this.setState({ element });
      }
    });
  }

  getPromotionInfo = id => {
    let json = get_data(`/scot/api/v2/alert/${id}/event`, {});
    return json;
  };

  render() {
    if (this.props.row.value === "closed") {
      return <p style={{ color: "green" }}>{this.props.row.value}</p>;
    } else if (this.props.row.value === "open") {
      return <p style={{ color: "red" }}>{this.props.row.value}</p>;
    } else if (this.props.row.value === "promoted") {
      if (this.state.element) {
        return (
          <Button2
            variant="contained"
            onMouseDown={() =>
              navigateTo(this.state.element.data.records[0].id)
            }
            style={{ backgroundColor: "orange", color: "white" }}
          >
            {this.props.row.value}
          </Button2>
        );
      } else {
        return <span>Loading...</span>;
      }
    }
  }
}

export const getEntityPopupColumns = params => {
  const columns = [
    {
      Header: "Status",
      accessor: "status",
      width: 79,
      Cell: row => {
        let promotedHref = "";
        if (row.original.status !== undefined) {
          if (row.original.status === "closed") {
            return (
              <span style={{ color: "green" }}>{row.original.status}</span>
            );
          } else if (row.original.status === "open") {
            return <span style={{ color: "red" }}>{row.original.status}</span>;
          } else if (row.original.status === "promoted") {
            if (row.original.type === "alert") {
              promotedHref = `/#/event/${row.original.promotion_id}`;
            } else if (row.original.type === "event") {
              promotedHref = `/#/incident/${row.original.promotion_id}`;
            }
            return (
              <div style={{ display: "flex", alignItems: "center" }}>
                <Button
                  bsSize="xsmall"
                  bsStyle={"warning"}
                  // id={this.props.data.id}
                  href={promotedHref}
                  target="_blank"
                  style={{
                    lineHeight: "12pt",
                    fontSize: "10pt",
                    marginLeft: "auto"
                  }}
                >
                  {row.original.status}
                </Button>
              </div>
            );
          }
        } else {
          return <div>N/A</div>;
        }
      }
    },
    {
      Header: "ID",
      accessor: "id",
      width: 85,
      Cell: row => {
        if (row.original.id) {
          return (
            <Link
              to={`/${row.original.type}/${row.original.id}`}
              target="_blank"
            >
              {row.original.id}
            </Link>
          );
        }
      }
    },
    {
      Header: "type",
      accessor: "type",
      width: 50
    },
    {
      Header: "Entries",
      accessor: "entry_count",
      width: 66
    },
    {
      Header: "subject",
      accessor: "subject"
    },
    {
      Header: "updated",
      accessor: "updated",
      width: 121,
      Cell: row => {
        let daysSince = "Unknown";
        if (row.original.updated !== undefined) {
          daysSince = Math.floor(
            (Math.round(new Date().getTime() / 1000) - row.original.updated) /
              86400
          );
        }
        return <span>{daysSince} days ago</span>;
      }
    }
  ];
  return columns;
};

export default defaultTableSettings;
