import React, { PureComponent } from 'react';
import PropTypes from 'prop-types';
import Dazzle, { addWidget } from 'react-dazzle';

class Dashboard extends PureComponent {
	constructor( props ) {
		super( props );

		this.state = {
			editMode: props.isNew,
			layout: props.layout,
			title: props.title,
		};

		this.onAdd = this.onAdd.bind(this);
		this.updateLayout = this.updateLayout.bind(this);
	}

	static propTypes = {
		widgets: PropTypes.object.isRequired,
		title: PropTypes.string.isRequired,
		saveDashboard: PropTypes.func.isRequired,
		layout: PropTypes.object,
		newDashboard: PropTypes.bool,
	}

	static defaultProps = {
		title: '',
		layout: {
			rows: [{
				columns: [
					{
						className: 'col-sm-4',
						widgets: [],
					},
					{
						className: 'col-sm-4',
						widgets: [],
					},
					{
						className: 'col-sm-4',
						widgets: [],
					},
				],
			}],
		},
		isNew: false,
	}

	onAdd( layout, rowIndex, columnIndex ) {
		this.updateLayout(
			addWidget( layout, rowIndex, columnIndex, 'Status' )
		);
	}

	updateLayout( layout ) {
		this.setState( {
			layout: layout,
		} );
	}

	render() {
		return (
			<Dazzle
				onRemove={this.updateLayout}
				onMove={this.updateLayout}
				onAdd={this.onAdd}
				editable={this.state.editMode}
				layout={this.state.layout}
				widgets={this.props.widgets}
			/>
		)
	}
}

export default Dashboard;
