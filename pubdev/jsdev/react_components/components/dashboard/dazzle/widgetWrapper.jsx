import React from 'react';

import { Panel, Button } from 'react-bootstrap';

const PanelHeader = ( title, onRemove ) => (
	<div style={{ position: 'relative' }}>
		{title}
		<span className="panel-button right">
			<Button onClick={onRemove} bsSize="small"><i className="fa fa-close" /></Button>
		</span>
	</div>
)

const Wrapper = ( { children, onRemove, editable, title } ) => (
	<div className={`widget ${editable && "editable"}`}>
		{ !editable && children }
		{ editable &&
			<Panel header={PanelHeader( title, onRemove )}>
				{children}
			</Panel>
		}
	</div>
)

export default Wrapper;
