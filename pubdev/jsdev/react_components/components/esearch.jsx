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
const searchkit         = new SearchkitManager("https://as3007snllx.sandia.gov/scot/api/v2/search/")

class Results extends React.Component{
    render() {
        console.log(this.props)
        return (
            React.createElement('div', null,
                React.createElement('span', {style: {top: '0px', 'padding-top': '35px !important', width: '600%', left: '-500%', 'z-index': '-999', position: 'absolute', 'background-color': 'white', 'padding-left': '10px', overflow: 'auto', color: 'black', resize: 'vertical', display: 'inline', height: '508px'}}))
    )
    }
}

var Search = React.createClass({
	render: function(){
        console.log(searchboxtext)
        return (
                React.createElement(SearchkitProvider, {searchkit: searchkit},
                    React.createElement('div', {className: 'search'},
                    React.createElement('div', {className: 'search_query'},
                        React.createElement(SearchBox, {autofocus: true, searchOnChange: true})
                            ),
                            searchboxtext != '' ?
                            React.createElement('div', {className: 'search_results'},
                            React.createElement(Hits, {itemComponent: Results, mod: 'sk-hits-grid'})
                            ) : null
                       )
                )
        )
	}
})


module.exports = Search
