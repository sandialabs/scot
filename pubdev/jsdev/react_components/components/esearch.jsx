var React = require('react')

var Search = React.createClass({

	render: function(){
	return (
	React.createElement('input', {type:'text', className: 'search', id: 'searchid', placeholder: 'Search', style: {position: 'relative', 'margin-top': '7.5px', 'border-radius': '50px', width: '30%', float: 'right', padding: '10px 20px',color: 'black', 'background-color': 'white'}})
	)
	}
})


module.exports = Search
