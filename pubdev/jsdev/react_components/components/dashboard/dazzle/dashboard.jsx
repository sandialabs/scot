import React, { PureComponent } from 'react';
import PropTypes from 'prop-types';
import Dazzle, { addWidget } from 'react-dazzle';

class Dashboard extends PureComponent {
	constructor( props ) {
		super( props );

		this.state = {};

		this.onAdd = this.onAdd.bind(this);
	}

	static propTypes = {
		widgets: PropTypes.object.isRequired,
		layout: PropTypes.object.isRequired,
		editMode: PropTypes.bool.isRequired,
		updateLayout: PropTypes.func.isRequired,
	}

	onAdd( layout, rowIndex, columnIndex ) {
		this.props.updateLayout(
			addWidget( layout, rowIndex, columnIndex, 'Status' )
		);
	}

	render() {
		return (
			<Dazzle
				onRemove={this.props.updateLayout}
				onMove={this.props.updateLayout}
				onAdd={this.onAdd}
				editable={this.props.editMode}
				layout={this.props.layout}
				widgets={this.props.widgets}
			/>
		)
	}
}

export default Dashboard;
