import React from "react";
import $ from "jquery";
import "jquery/src/jquery";
import Highlighter from "react-highlight-words";
let Link = require("react-router-dom").Link;

export default class Search extends React.Component {
    constructor(props) {
        super(props);
        this.state = {
            showSearchToolbar: false,
            searchResults: null,
            entityHeight: "60vh",
            searching: false,
            searchString: ""
        };
    }

    componentDidMount = () => {
        function searchEscHandler(event) {
            if ($("#main-search-results")[0] !== undefined) {
                if (event.keyCode === 27) {
                    this.closeSearch();
                    event.preventDefault();
                }
            }
        }
        $(document).keyup(searchEscHandler.bind(this));
    };

    closeSearch = () => {
        this.setState({ showSearchToolbar: false });
    };

    doSearch = string => {
        $.ajax({
            type: "get",
            url: "/scot/api/v2/esearch",
            data: { qstring: string },
            success: function (response) {
                if (string === $("#main-search")[0].value) {
                    this.setState({
                        results: response.records,
                        showSearchToolbar: true,
                        searching: false,
                        searchString: string
                    });
                }
            }.bind(this),
            error: function () {
                //this.props.errorToggle('search failed')
                this.setState({ searching: false });
            }.bind(this)
        });
        this.setState({ searching: true });
    };

    handleEnterKey = e => {
        if (e.key === "Enter") {
            this.doSearch(e.target.value);
        }
    };

    onChange = e => {
        //only do auto search if there are at least 3 characters
        //if (e.target.value.length > 2) {
        this.doSearch(e.target.value);
        //}
    };

    componentDidUpdate = () => {
        if (this.state.searchString !== undefined) {
            //var re = new RegExp(this.state.searchString,"gi");
            //$(".search-snippet").html(function(_, html) {
            //    return html.replace(re, '<span class="search_highlight">$&</span>');
            //});
            // $(".search-snippet").mark(this.state.searchString, {
            //   element: "span",
            //   className: "search_highlight"
            // });
        }
    };

    render = () => {
        let tableRows = [];
        if (this.state.results !== undefined) {
            if (this.state.results[0] !== undefined) {
                for (let i = 0; i < this.state.results.length; i++) {
                    tableRows.push(
                        <SearchDataEachRows
                            dataOne={this.state.results[i]}
                            key={i}
                            index={i}
                        />
                    );
                }
            } else {
                tableRows.push(
                    <div style={{ display: "inline-flex" }}>
                        <div style={{ display: "flex" }}>No results returned</div>
                    </div>
                );
            }
        }
        return (
            <div className="esearch">
                <div style={{ display: "flex" }}>
                    <input
                        id="main-search"
                        className="esearch-query"
                        style={{
                            marginTop: "3px",
                            padding: "10px 10px",
                            float: "right",
                            position: "relative"
                        }}
                        placeholder="&#xF002; Search"
                        charSet="utf-8"
                        onKeyPress={this.handleEnterKey}
                        onChange={this.onChange}
                    />
                    {this.state.searching ? (
                        <i
                            className="fa fa-spinner fa-spin fa-3x fa-fw"
                            style={{ color: "white" }}
                        />
                    ) : null}
                </div>
                {this.state.showSearchToolbar ? (
                    <div
                        id="main-search-results"
                        style={{
                            display: "flex",
                            flexFlow: "row",
                            position: "absolute",
                            right: "10px",
                            top: "53px",
                            background: "#f3f3f3",
                            border: "black",
                            borderStyle: "solid"
                        }}
                    >
                        <div>
                            <SearchDataEachHeader closeSearch={this.closeSearch} />
                            <div
                                style={{
                                    overflowY: "auto",
                                    maxHeight: "600px",
                                    display: "table-caption"
                                }}
                            >
                                {tableRows}
                            </div>
                        </div>
                    </div>
                ) : null}
            </div>
        );
    };

    componentWillUnmount = () => {
        $(document).off("keypress");
    };
}

class SearchDataEachHeader extends React.Component {
    render = () => {
        /*return (
                <div className="table-row header" style={{color:'black', display:'flex'}}>
                    <div style={{flexGrow:1, display:'flex'}}>
                        <div style={{width:'100px', textAlign:'left', overflow:'hidden', textOverflow:'ellipsis', whiteSpace:'nowrap'}}>
                            ID
                        </div>
                        <div style={{width:'100px', textAlign:'left', overflow:'hidden', textOverflow:'ellipsis', whiteSpace:'nowrap'}}>
                            Type
                        </div>
                        <div style={{width:'100px', textAlign:'left', overflow:'hidden', textOverflow:'ellipsis', whiteSpace:'nowrap'}}>
                            Score
                        </div>
                        <div style={{width:'400px', textAlign:'left', overflow:'hidden', textOverflow:'ellipsis', whiteSpace:'nowrap'}}>
                            Snippet
                            <i className='fa fa-times pull-right' style={{color:'red', margin: '2px', cursor: 'pointer'}}onClick={this.props.closeSearch}/>
                        </div>
                    </div>
                </div>
            )*/
        return (
            <div
                className="table-row header"
                style={{ color: "black", display: "flex" }}
            >
                <div style={{ flexGrow: 1, display: "flex" }}>
                    <div
                        style={{
                            width: "100%",
                            textAlign: "left",
                            overflow: "hidden",
                            textOverflow: "ellipsis",
                            whiteSpace: "nowrap"
                        }}
                    >
                        Search Results - Score Displayed
            <i
                            className="fa fa-times pull-right"
                            style={{ color: "red", margin: "2px", cursor: "pointer" }}
                            onClick={this.props.closeSearch}
                        />
                    </div>
                </div>
            </div>
        );
    };
}

class SearchDataEachRows extends React.Component {
    render = () => {
        let type = this.props.dataOne.type;
        let id = this.props.dataOne.id;
        let entryid = this.props.dataOne.entryid;
        let score = this.props.dataOne.score;
        let highlight = [];

        let rowEvenOdd = "even";
        if (!isEven(this.props.index)) {
            rowEvenOdd = "odd";
        }

        let rowClassName = "search_result_row list-view-row" + rowEvenOdd;

        let href = "/" + type + "/" + id;
        if (entryid !== undefined) {
            href = "/" + type + "/" + id + "/" + entryid;
        }

        if (this.props.dataOne.highlight !== undefined) {
            if (typeof this.props.dataOne.highlight === "string") {
                highlight.push(
                    <span className="search_snippet_container panel col">
                        <span className="search_snippet_header">Snippet:</span>
                        <span className="search_snippet_result">
                            {this.props.dataOne.highlight}
                        </span>
                    </span>
                );
            } else if ($.isArray(this.props.dataOne.highlight)) {
                highlight.push(
                    <span className="search_snippet_container panel col">
                        <span className="search_snippet_header">Snippet:</span>
                        <span className="search_snippet_result">
                            {this.props.dataOne.highlight[0]}
                        </span>
                    </span>
                );
            } else {
                for (let key in this.props.dataOne.highlight) {
                    highlight.push(
                        <span className="search_snippet_container panel col">
                            <span className="search_snippet_header">{key}</span>
                            <span className="search_snippet_result">
                                {this.props.dataOne.highlight[key]}
                            </span>
                        </span>
                    );
                }
            }
        }
        return (
            <div key={Date.now()} className={rowClassName}>
                <Link to={href} style={{ display: "flex" }}>
                    <span
                        className="panel panel-default"
                        style={{
                            display: "flex",
                            flexFlow: "column",
                            borderColor: "black",
                            borderWidth: "thin",
                            margin: "0px"
                        }}
                    >
                        <div className="panel-heading h4 search-heading">
                            {type} {id} - {score}
                        </div>
                        <div
                            className="search-snippet"
                            style={{
                                display: "flex",
                                overflowX: "hidden",
                                wordWrap: "break-word"
                            }}
                        >
                            <span
                                className="container-fluid"
                                style={{
                                    textAlign: "left",
                                    overflow: "hidden",
                                    textOverflow: "ellipsis",
                                    width: "600px"
                                }}
                            >
                                {highlight}
                            </span>
                        </div>
                    </span>
                </Link>
            </div>
        );
        /*
            return (
                <div key={Date.now()} className={rowClassName}>
                    <a href={href} style={{display:'flex'}}>
                        <div style={{display:'flex'}}>
                            <span style={{width:'100px', textAlign:'left', overflow:'hidden', textOverflow:'ellipsis', whiteSpace:'nowrap'}}>{id}</span>
                        </div>
                        <div style={{display:'flex'}}>
                            <span style={{width:'100px', textAlign:'left', overflow:'hidden', textOverflow:'ellipsis', whiteSpace:'nowrap'}}>{type}</span>
                        </div>
                        <div style={{display:'flex'}}>
                            <span style={{width:'100px', textAlign:'left', overflow:'hidden', textOverflow:'ellipsis', whiteSpace:'nowrap'}}>{score}</span>
                        </div>
                        <div className='search-snippet' style={{display:'flex', overflowX:'hidden',wordWrap:'break-word'}}>
                            <span className='row' style={{textAlign:'left', overflow:'hidden', textOverflow:'ellipsis', width: '400px'}}>{highlight}</span>
                        </div>
                    </a>
                </div>
            )*/
    };
}

function isEven(n) {
    return n % 2 === 0;
}
