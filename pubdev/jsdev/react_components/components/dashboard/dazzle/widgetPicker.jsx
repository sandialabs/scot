import React from 'react';
import PropTypes from 'prop-types';
import { Modal, Button } from 'react-bootstrap';

const WidgetPicker = ( { widgets, layout, isOpen, onClose, onSelect } ) => {
	let activeWidgets = new Set();
	layout.rows.forEach( row => {
		row.columns.forEach( col => {
			col.widgets.forEach( widget => {
				activeWidgets.add( widget.key );
			} );
		} );
	} );

	let widgetItems = Object.keys(widgets)
		.filter( widget => !activeWidgets.has( widget ) )
		.map( ( widget, key ) => {
			const widgetObj = widgets[widget];
			return (
				<div key={key} className="picker-item" onClick={() => {onSelect(widget);}}>
					<h3>{widgetObj.title}</h3>
					<p>{widgetObj.description}</p>
				</div>
			)
		} );

	if ( !widgetItems.length ) {
		widgetItems = <h2>No available widgets</h2>;
	}

	return (
		<Modal show={isOpen} onHide={onClose} className="WidgetPicker">
			<Modal.Header closeButton>
				<Modal.Title>Pick a Widget</Modal.Title>
			</Modal.Header>

			<Modal.Body className="picker-grid">{widgetItems}</Modal.Body>

			<Modal.Footer>
				<Button onClick={onClose}>Cancel</Button>
			</Modal.Footer>
		</Modal>
	)
}
WidgetPicker.propTypes = {
	widgets: PropTypes.object.isRequired,
	layout: PropTypes.object.isRequired,
	isOpen: PropTypes.bool.isRequired,
	onClose: PropTypes.func.isRequired,
	onSelect: PropTypes.func.isRequired,
};

export default WidgetPicker;
