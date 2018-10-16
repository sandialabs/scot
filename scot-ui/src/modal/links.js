import React, { Component } from "react";
import { Modal, Button, ButtonGroup } from "react-bootstrap";
import ReactTable from "react-table";
import $ from "jquery";

export default class Links extends Component {
    constructor(props) {
        super(props);

        this.state = {
            data: [],
            allSelected: false,
            loading: false
        };

        this.getLinks = this.getLinks.bind(this);
        this.handleTHeadCheckboxSelection = this.handleTHeadCheckboxSelection.bind(
            this
        );
        this.handleRowSelection = this.handleRowSelection.bind(this);
        this.handleCheckboxSelection = this.handleCheckboxSelection.bind(this);
    }

    componentWillMount() {
        this.getLinks();
        this.mounted = true;
    }

    componentWillUnmount() {
        this.mounted = false;
    }

    render() {
        const columns = [
            {
                Header: cell => {
                    return (
                        <div>
                            <div className="links-checkbox">
                                <i
                                    className={`fa fa${
                                        this.state.allSelected ? "-check" : ""
                                        }-square-o`}
                                    aria-hidden="true"
                                />
                            </div>
                        </div>
                    );
                },
                id: "selected",
                accessor: d => d.selected,
                Cell: row => {
                    return (
                        <div>
                            <div className="links-checkbox">
                                <i
                                    className={`fa fa${
                                        row.row.selected ? "-check" : ""
                                        }-square-o`}
                                    aria-hidden="true"
                                />
                            </div>
                        </div>
                    );
                },
                maxWidth: 100,
                filterable: false
            },
            {
                Header: "Type",
                accessor: "type",
                maxWidth: 150,
                sortable: true
            },
            {
                Header: "ID",
                accessor: "id",
                maxWidth: 100,
                sortable: true
            },
            {
                Header: "Context",
                accessor: "context",
                minWidth: 100,
                maxWidth: 800,
                sortable: true
            },
            {
                Header: "Memo",
                accessor: "memo",
                minWidth: 100,
                maxWidth: 800,
                sortable: true
            },
            {
                Header: "Link ID",
                accessor: "linkid",
                maxWidth: 100,
                sortable: true
            }
        ];

        return (
            <Modal
                dialogClassName="links-modal"
                show={this.props.modalActive}
                onHide={this.props.linksModalToggle}
            >
                <Modal.Header closeButton={true}>
                    <Modal.Title>
                        {this.state.data.length} items linked to {this.props.type}{" "}
                        {this.props.id}
                    </Modal.Title>
                </Modal.Header>
                <Modal.Body>
                    <ReactTable
                        columns={columns}
                        data={this.state.data}
                        defaultPageSize={10}
                        getTdProps={this.handleCheckboxSelection}
                        getTheadThProps={this.handleTHeadCheckboxSelection}
                        getTrProps={this.handleRowSelection}
                        minRows={0}
                        noDataText="No items Linked."
                        loading={this.state.loading}
                        style={{
                            maxHeight: "60vh"
                        }}
                        filterable
                    />
                </Modal.Body>
                <Modal.Footer>
                    <Actions
                        data={this.state.data}
                        id={this.props.id}
                        type={this.props.type}
                        getLinks={this.getLinks}
                        errorToggle={this.props.errorToggle}
                    />
                </Modal.Footer>
            </Modal>
        );
    }

    getLinks() {
        this.setState({ loading: true });

        $.ajax({
            type: "get",
            url: "/scot/api/v2/" + this.props.type + "/" + this.props.id + "/link",
            success: function (data) {
                let arr = [];

                for (let i = 0; i < data.records.length; i++) {
                    let verticeObject = {};
                    verticeObject.linkid = data.records[i].id;
                    verticeObject.context = data.records[i].context;
                    for (let j = 0; j < data.records[i].vertices.length; j++) {
                        //if ids are equal, check if the type is equal. If so, it's what is displayed so don't show it.
                        if (data.records[i].vertices[j].id === this.props.id) {
                            if (data.records[i].vertices[j].type !== this.props.type) {
                                verticeObject.id = data.records[i].vertices[j].id;
                                verticeObject.type = data.records[i].vertices[j].type;
                                verticeObject.memo = data.records[i].memo[j];
                                arr.push(verticeObject);
                            } else {
                                continue;
                            }
                        } else {
                            verticeObject.id = data.records[i].vertices[j].id;
                            verticeObject.type = data.records[i].vertices[j].type;
                            verticeObject.memo = data.records[i].memo[j];
                            arr.push(verticeObject);
                        }
                    }
                }

                this.setState({ data: arr, loading: false });
            }.bind(this),
            error: function (data) {
                this.setState({ loading: false });
                this.props.errorToggle("failed to get links", data);
            }.bind(this)
        });
    }

    handleRowSelection(state, rowInfo, column) {
        return {
            onClick: event => {
                let data = this.state.data;

                for (let row of data) {
                    if (rowInfo.row.id === row.id && rowInfo.row.type === row.type) {
                        row.selected = true;
                    } else {
                        row.selected = false;
                    }
                }

                this.setState({ data: data, allSelected: false });
                return;
            },
            style: {
                background:
                    rowInfo !== undefined
                        ? rowInfo.row.selected
                            ? "rgb(174, 218, 255)"
                            : null
                        : null
            }
        };
    }

    handleCheckboxSelection(state, rowInfo, column) {
        if (column.id === "selected") {
            return {
                onClick: event => {
                    let data = this.state.data;

                    for (let row of data) {
                        if (rowInfo.row.id === row.id && rowInfo.row.type === row.type) {
                            row.selected = !row.selected;
                            break;
                        }
                    }

                    this.setState({
                        data: data,
                        allSelected: this.checkAllSelected(data)
                    });
                    event.stopPropagation();
                    return;
                }
            };
        } else {
            return {};
        }
    }

    handleTHeadCheckboxSelection(state, rowInfo, column, instance) {
        if (column.id === "selected") {
            return {
                onClick: event => {
                    let data = this.state.data;
                    let allSelected = !this.state.allSelected;

                    for (let row of data) {
                        for (let pageRow of state.pageRows) {
                            if (row.id === pageRow.id && row.type === pageRow.type) {
                                //compare displayed rows to rows in dataset and only select those
                                row.selected = allSelected;
                                break;
                            }
                        }
                    }

                    this.setState({ data: data, allSelected: allSelected });
                    return;
                }
            };
        } else {
            return {};
        }
    }

    checkAllSelected(data) {
        for (let row of data) {
            if (!row.selected) {
                return false;
            }
        }
        return true;
    }
}

class Actions extends Component {
    constructor(props) {
        super(props);

        this.state = {
            entry: false,
            thing: false,
            actionSuccess: false
        };

        this.RemoveLink = this.RemoveLink.bind(this);
        this.RemoveLinkAjax = this.RemoveLinkAjax.bind(this);
        this.ToggleActionSuccess = this.ToggleActionSuccess.bind(this);
    }

    componentWillMount() {
        this.mounted = true;
    }

    componentWillUnmount() {
        this.mounted = false;
    }

    render() {
        let entry = false;
        let thing = false;

        for (let key of this.props.data) {
            if (key.type && key.selected) {
                if (key.type === "entry") {
                    entry = true;
                } else {
                    thing = true;
                }
            }
        }

        return (
            <div>
                {this.state.actionSuccess ? (
                    <div>
                        <span bsStyle={{ color: "green" }}>Action Successful!</span>
                    </div>
                ) : null}
                <div>
                    {thing || entry ? (
                        <h4 style={{ float: "left" }}>Actions</h4>
                    ) : (
                            <div>
                                {" "}
                                {this.props.data.length > 0 ? (
                                    <h4 style={{ float: "left" }}>Select a link for options</h4>
                                ) : null}{" "}
                            </div>
                        )}
                    <ButtonGroup style={{ float: "right" }}>
                        {thing || entry ? (
                            <Button onClick={this.RemoveLink}>Remove Link</Button>
                        ) : null}
                    </ButtonGroup>
                </div>
            </div>
        );
    }

    RemoveLink() {
        for (let key of this.props.data) {
            if (key.selected) {
                // eslint-disable-next-line
                this.RemoveLinkAjax(parseInt(key.linkid));
            }
        }
    }

    RemoveLinkAjax(id) {
        $.ajax({
            type: "delete",
            url: "/scot/api/v2/link/" + id,
            success: function (response) {
                console.log("successfully removed link");
                this.ToggleActionSuccess();
            }.bind(this),
            error: function (data) {
                this.props.errorToggle("failed to remove link", data);
            }.bind(this)
        });
    }

    ToggleActionSuccess() {
        let newActionSuccess = !this.state.actionSuccess;
        this.props.getLinks();
        this.setState({ actionSuccess: newActionSuccess });
    }
}

