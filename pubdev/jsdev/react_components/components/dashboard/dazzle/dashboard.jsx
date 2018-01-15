import React, { PureComponent } from 'react';
import PropTypes from 'prop-types';
import Dazzle, { addWidget } from 'react-dazzle';

import { Button } from 'react-bootstrap';

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
		this.updateTitle = this.updateTitle.bind(this);
		this.reset = this.reset.bind(this);
		this.saveDashboard = this.saveDashboard.bind(this);
		this.toggleEdit = this.toggleEdit.bind(this);
	}

	static propTypes = {
		widgets: PropTypes.object.isRequired,
		title: PropTypes.string,
		saveDashboard: PropTypes.func.isRequired,
		layout: PropTypes.object,
		newDashboard: PropTypes.bool,
	}

	static defaultProps = {
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

	updateTitle( title ) {
		this.setState( {
			title: title.target.value,
		} );
	}

	toggleEdit() {
		this.setState( {
			editMode: !this.state.editMode,
		} );
	}

	saveDashboard() {
		// Handle upstream save
		this.toggleEdit();
	}

	reset() {
		this.setState( {
			layout: this.props.layout,
			title: this.props.title,
			editMode: false,
		} );
	}

	render() {
		return (
			<div className="dashboard">
				<TitleBar
					title={this.state.title}
					editMode={this.state.editMode}
					onEdit={this.toggleEdit}
					onSave={this.saveDashboard}
					onCancel={this.reset}
					handleTitleChange={this.updateTitle}
				/>
				<Dazzle
					onRemove={this.updateLayout}
					onMove={this.updateLayout}
					onAdd={this.onAdd}
					editable={this.state.editMode}
					layout={this.state.layout}
					widgets={this.props.widgets}
				/>
			</div>
		)
	}
}

const TitleBar = ( {
	title = '',
	editMode,
	onEdit,
	onSave,
	onCancel,
	handleTitleChange
} = {} ) => (
	<div className="titleBar clearfix">
		{ editMode &&
			<input type="text" className="title" value={title} placeholder="Dashboard Title" onChange={handleTitleChange} />
		}
		{ !editMode ? (
			<div className="edit">
				<Button bsSize="xsmall" onClick={onEdit}><i className="fa fa-edit" /></Button>
			</div>
		) : (
			<div className="edit">
				<Button bsStyle="primary" bsSize="small" onClick={onSave}>Save</Button>
				<Button bsStyle="warning" bsSize="small" onClick={onCancel}>Cancel</Button>
			</div>
		) }
	</div>
)
TitleBar.propTypes = {
	title: PropTypes.string,
	editMode: PropTypes.bool.isRequired,
	onEdit: PropTypes.func.isRequired,
	onSave: PropTypes.func.isRequired,
	onCancel: PropTypes.func.isRequired,
	handleTitleChange: PropTypes.func.isRequired,
};

export default Dashboard;
