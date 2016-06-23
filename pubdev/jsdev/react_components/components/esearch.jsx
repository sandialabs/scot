var React = require('react')
//var SearchkitProvider       = require('../../../node_modules/searchkit').SearchkitProvider;
//var SearchkitManager       = require('../../../node_modules/searchkit').SearchkitManager;
//var SearchBox       = require('../../../node_modules/searchkit').SearchBox;
//const searchkit = new SearchkitManager("/scot/api/v2")
var Search = React.createClass({
	render: function(){
	return (
  /*
        React.createElement('div', {className: 'searchkit'}, 
                    React.createElement(SearchkitProvider, {searchkit: searchkit},
                    React.createElement(SearchBox, {autofocus: true, searchOnChange: true, prefixQueryFields: ["My Lord"]}
                    )
                    )
                    ) 

*/

	    React.createElement('input', {type:'text', className: 'search', id: 'searchid', placeholder: 'Search', style: {position: 'relative', 'margin-top': '7.5px', 'border-radius': '50px', width: '30%', float: 'right', padding: '10px 20px',color: 'black', 'background-color': 'white'}})
	
    
    )
	}
})


module.exports = Search
