import React, { PureComponent } from 'react';
import PropTypes from 'prop-types';
import Dazzle, { addWidget } from 'react-dazzle';

import { Grid, Button } from 'react-bootstrap';

import WidgetWrapper from './widgetWrapper';
import WidgetPicker from './widgetPicker';

class Dashboard extends PureComponent {
	constructor( props ) {
		super( props );

		this.state = {
			editable: props.saveDashboard != null,
			editMode: props.isNew,
			layout: props.layout,
			title: props.title,
			widgetPicker: false,
			newWidgetOptions: {},
		};

		this.onAdd = this.onAdd.bind(this);
		this.updateLayout = this.updateLayout.bind(this);
		this.updateTitle = this.updateTitle.bind(this);
		this.reset = this.reset.bind(this);
		this.saveDashboard = this.saveDashboard.bind(this);
		this.toggleEdit = this.toggleEdit.bind(this);
		this.togglePicker = this.togglePicker.bind(this);
		this.selectWidget = this.selectWidget.bind(this);
	}

	static propTypes = {
		widgets: PropTypes.object.isRequired,
		title: PropTypes.string,
		saveDashboard: PropTypes.func,
		layout: PropTypes.object,
		isNew: PropTypes.bool,
		errorToggle: PropTypes.func,
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
		this.setState( {
			widgetPicker: true,
			newWidgetOptions: {
				row: rowIndex,
				col: columnIndex,
			},
		} );
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
		if ( !this.state.title ) {
			this.props.errorToggle( "Please enter a dashboard title" );
			return;
		}

		this.props.saveDashboard( this.state.title, this.state.layout );
		this.toggleEdit();
	}

	reset() {
		this.setState( {
			layout: this.props.layout,
			title: this.props.title,
			editMode: false,
			widgetPicker: false,
			newWidgetOptions: {},
		} );
	}

	togglePicker() {
		this.setState({
			widgetPicker: !this.state.widgetPicker,
		});
	}

	selectWidget( widget ) {
		let { row, col } = this.state.newWidgetOptions;
		this.updateLayout(
			addWidget( this.state.layout, row, col, widget )
		);
		this.togglePicker();
	}

	render() {
		return (
			<div className="dashboard">
				<WidgetPicker
					widgets={this.props.widgets}
					layout={this.state.layout}
					isOpen={this.state.widgetPicker}
					onClose={this.togglePicker}
					onSelect={this.selectWidget}
				/>
				<TitleBar
					title={this.state.title}
					editable={this.state.editable}
					editMode={this.state.editMode}
					onEdit={this.toggleEdit}
					onSave={this.saveDashboard}
					onCancel={this.reset}
					handleTitleChange={this.updateTitle}
					isNew={this.props.isNew}
				/>
				<Grid fluid>
					<Dazzle
						onRemove={this.updateLayout}
						onMove={this.updateLayout}
						onAdd={this.onAdd}
						editable={this.state.editMode}
						layout={this.state.layout}
						widgets={this.props.widgets}
						frameComponent={WidgetWrapper}
					/>
				</Grid>
			</div>
		)
	}
}

const TitleBar = ( {
	title,
	editMode,
	onEdit,
	onSave,
	onCancel,
	handleTitleChange,
	isNew,
	editable
} ) => {
	if ( !editable ) {
		return null;
	}
	return (
		<div className="titleBar clearfix">
			{ editMode &&
				<form onSubmit={onSave}>
					<input type="text" className="title" value={title} placeholder="Dashboard Title" onChange={handleTitleChange} />
				</form>
			}
			{ !editMode ? (
				<div className="edit">
					<Button bsSize="xsmall" onClick={onEdit}><i className="fa fa-edit" /></Button>
				</div>
			) : (
				<div className="edit">
					<Button bsStyle="primary" bsSize="small" onClick={onSave}>Save</Button>
					<Button bsStyle="warning" bsSize="small" disabled={isNew} onClick={onCancel}>Cancel</Button>
				</div>
			) }
		</div>
	);
}
TitleBar.propTypes = {
	title: PropTypes.string.isRequired,
	editMode: PropTypes.bool.isRequired,
	onEdit: PropTypes.func.isRequired,
	onSave: PropTypes.func.isRequired,
	onCancel: PropTypes.func.isRequired,
	handleTitleChange: PropTypes.func.isRequired,
	editable: PropTypes.bool.isRequired,
};

export default Dashboard;
