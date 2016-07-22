var React               = require('react')
var SearchkitProvider   = require('../../../node_modules/searchkit').SearchkitProvider;
var SearchkitManager    = require('../../../node_modules/searchkit').SearchkitManager;
var SearchBox           = require('../../../node_modules/searchkit').SearchBox;
var Hits                = require('../../../node_modules/searchkit').Hits;
var FilteredQuery       = require('../../../node_modules/searchkit').FilteredQuery;
var TermQuery           = require('../../../node_modules/searchkit').TermQuery;
var BoolShould          = require('../../../node_modules/searchkit').BoolShould;
var LayoutBody          = require('../../../node_modules/searchkit').LayoutBody;
var LayoutResults       = require('../../../node_modules/searchkit').LayoutResults;
var Pagination          = require('../../../node_modules/searchkit').Pagination;
const searchkit         = new SearchkitManager("/scot/api/v2/search/")
var type = ''
var id = 0
var sourceid = ''
var body = ''
var owner = ''
var typeid = ''
class Results extends React.Component{
    render() {
        if(this.props.result._type == 'entry'){
            type = this.props.result._source.target.type
            id   = this.props.result._source.target.id
            if(type == 'alert'){
                type  = 'alert'
                id    = this.props.result._source.target.id
            }
        }
        else if(this.props.result._type == 'alert'){
            type    = 'alert'
            id      = this.props.result._source.id 
        }
        else {
            id      = this.props.result._id
            type    = this.props.result._type
        }
        if(this.props.result._source.id != undefined){
            sourceid = this.props.result._source.id
        }
        if(this.props.result._source.body_plain != undefined){
            body = this.props.result._source.body_plain
        }
        if(this.props.result._source.owner != undefined){
            owner = this.props.result._source.owner
        }
        if(this.props.result._source.type != undefined){
            typeid = this.props.result._source.type
        }
        return (
            searchboxtext ? 
            React.createElement('div', null,
                React.createElement('div', {style: {display: 'inline-flex'}},
                        React.createElement("div", {className: "wrapper attributes "},
                        React.createElement('div', {className: 'wrapper status-owner-severity'},
                        React.createElement('div', {className: 'wrapper status-owner status-owner-wide'},
                        React.createElement('a',   {href: '/#/'+type+'/' + id, className: 'column owner'}, id))),
                        React.createElement('div', {className: 'wrapper status-owner-severity'},
                        React.createElement('div', {className: 'wrapper status-owner status-owner-wide'},
                        React.createElement('a',   {href: '/#/'+type+'/' + id, className: 'column owner'}, type))),
                        React.createElement('div', {className: 'wrapper title-comment-module-reporter'},
                        React.createElement('div', {className: 'wrapper title-comment'},
                        React.createElement('a',   {style: {width: '1200px'},href: '/#/'+type+'/' + id, className: 'column title'}, sourceid + ' ' + body + ' ' + owner + ' ' + typeid)))))) : null
    )
    }
}

var Search = React.createClass({
	render: function(){
        return (
                React.createElement(SearchkitProvider, {searchkit: searchkit},
                    React.createElement('div', {className: 'search'},
                    React.createElement('div', {className: 'search_query'},
                        React.createElement(SearchBox, {autofocus: true, searchOnChange: true})
                            ),
                            React.createElement('div', {style: {color: 'black', 'background-color': 'white',display: 'none', width: '600%', height: '200px', position: 'absolute', 'overflow-y': 'auto', resize: 'vertical', top: '55px', border: '1px solid #DDD', left: ''},className: 'search_results'},
               React.createElement("div", {className: "container-fluid2", id: 'fluid2', style: {/*'max-width': '915px',*//*'min-width': '650px',*/ width: '100%', 'max-height': '100%', 'margin-left': '0px',height: '100%', 'overflow-y': 'auto', 'overflow-x' : 'hidden','padding-left':'5px'}},
                    React.createElement("div", {className: "table-row header "},
                        React.createElement("div", {className: "wrapper attributes "},                        
                        React.createElement('div', {className: 'wrapper status-owner-severity'},
                        React.createElement('div', {className: 'wrapper status-owner status-owner-wide'},
                        React.createElement('div', {className: 'column owner'}, 'ID'))),

                        React.createElement('div', {className: 'wrapper status-owner-severity'},
                        React.createElement('div', {className: 'wrapper status-owner status-owner-wide'},
                        React.createElement('div', {className: 'column owner'}, 'Type'))),

                        React.createElement('div', {className: 'wrapper title-comment-module-reporter'},
                        React.createElement('div', {className: 'wrapper title-comment'},
                        React.createElement('div', {className: 'column title'}, 'Snippet(s)'))),

                        React.createElement('div', {className: 'wrapper status-owner-severity'},
                        React.createElement('div', {className: 'wrapper status-owner status-owner-wide'},
                        React.createElement('div', {className: 'column owner'}, 'Snippet(s)')))
                            )), 
                            React.createElement(Hits, {hitsPerPage: 10, itemComponent: Results, mod: 'sk-hits-list', highlightFields:['id']})),
                            React.createElement(Pagination, {showNumbers: true}))
                            
        )))
	}
})


module.exports = Search
