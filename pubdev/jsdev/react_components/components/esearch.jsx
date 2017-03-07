var React               = require('react')
var Draggable           = require('react-draggable');
var type = ''
var id = 0
var sourceid = ''
var body = ''
var owner = ''
var typeid = ''

var Search = React.createClass({
    getInitialState: function() {
        return {
            showSearchToolbar: false,
            searchResults: null,
            entityHeight: '60vh',
            searching: false,
        }
    },	
    componentDidMount: function() {
        function searchEscHandler(event) {
            if ($('#main-search-results')[0] != undefined) {
                if (event.keyCode == 27) {
                    this.closeSearch();
                    event.preventDefault();
                }
            }
        }
        $(document).keyup(searchEscHandler.bind(this));
    },
    closeSearch: function() {
        this.setState({showSearchToolbar: false});
    },
    doSearch: function(string) {
        $.ajax({
            type: 'get',
            url: '/scot/api/v2/esearch',
            data: {qstring:string},
            success: function(response) {
                if (string == $('#main-search')[0].value) { 
                    this.setState({results:response.records, showSearchToolbar:true, searching:false})
                }
            }.bind(this),
            error: function(response) {
                this.props.errorToggle('search failed')
                this.setState({searching: false});    
            }.bind(this)
        });
        this.setState({searching: true});
    },
    handleEnterKey: function(e) {
        if (e.key == 'Enter') {
            this.doSearch(e.target.value);
        }
    },
    onChange: function(e) {
        this.doSearch(e.target.value);
    },
    render: function(){
        var tableRows = [] ;
        if (this.state.results != undefined) {
            if (this.state.results[0] != undefined) {
                for (var i=0; i < this.state.results.length; i++) {
                    tableRows.push(<SearchDataEachRows dataOne={this.state.results[i]} />);
                }
            } else {
                tableRows.push(<div style={{display:'inline-flex'}}><div style={{display:'flex'}}>No results returned</div></div>)
            }
        }
        return (
            <div style={{float:'right'}}>
                <div style={{display:'flex'}}>
                    <input id='main-search' className='esearch-query' style={{marginTop:'3px',padding:'10px 10px', backgroundColor: 'white', color:'black', float:'right', borderRadius:'50px',position:'relative'}} placeholder={'Search...'} onKeyPress={this.handleEnterKey} onChange={this.onChange}/>
                    {this.state.searching ? <i className="fa fa-spinner fa-spin fa-3x fa-fw" style={{color:'white'}}/> : null}
                </div>
                {this.state.showSearchToolbar ? 
                    <div id='main-search-results' style={{display:'flex', flexFlow:'row',position:'absolute', right:'10px', top:'53px', background: '#f3f3f3', border:'black', borderStyle:'solid'}}>
                        <div>
                            <SearchDataEachHeader closeSearch={this.closeSearch}/>
                            <div style={{overflowY: 'auto', maxHeight: '700px'}}>
                                {tableRows}
                            </div>
                        </div>
                    </div>
                :
                    null} 
            </div>
        )
	},
    componentWillUnmount: function() {
        $(document).off('keypress');
    },
})

var SearchDataEachHeader = React.createClass({
    render: function() {
        return (
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
        )
    }
});

var SearchDataEachRows = React.createClass({
    render: function() {
        var type = this.props.dataOne.type;
        var id = this.props.dataOne.id;
        var score = this.props.dataOne.score;
        var snippet = this.props.dataOne.snippet;
        var href = '/#/'+type+'/'+id;
        return (
            <div style={{display:'inline-flex'}}>
                <div style={{display:'flex'}}>
                    <a href={href} style={{width:'100px', textAlign:'left', overflow:'hidden', textOverflow:'ellipsis', whiteSpace:'nowrap'}}>{id}</a>
                </div>
                <div style={{display:'flex'}}>
                    <a href={href} style={{width:'100px', textAlign:'left', overflow:'hidden', textOverflow:'ellipsis', whiteSpace:'nowrap'}}>{type}</a>
                </div>
                <div style={{display:'flex'}}>
                    <a href={href} style={{width:'100px', textAlign:'left', overflow:'hidden', textOverflow:'ellipsis', whiteSpace:'nowrap'}}>{score}</a>
                </div>
                <div style={{display:'flex', overflowX:'hidden',wordWrap:'break-word'}}>
                    <a href={href} style={{textAlign:'left', overflow:'hidden', textOverflow:'ellipsis', width: '400px'}}>{snippet}</a>
                </div>
            </div>
        )
    }
})

module.exports = Search
