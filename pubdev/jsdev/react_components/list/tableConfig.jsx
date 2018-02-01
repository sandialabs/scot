import React from 'react';
import { OverlayTrigger, ButtonGroup, Button, Popover } from 'react-bootstrap';
import DateRangePicker from 'react-daterange-picker';
import DebounceInput from 'react-debounce-input';

import { epochRangeToString, epochRangeToMoment, momentRangeToEpoch } from '../utils/time';

import * as constants from '../utils/constants';

import LoadingContainer from './LoadingContainer';
import TagInput from '../components/TagInput';

const customFilters = {
	numberFilter: ( {filter, onChange} ) => (
		<DebounceInput
			debounceTimeout={200}
			type='number'
			minLength={1}
            min = {0}
			value={filter ? filter.value : ''}
			onChange={ e => onChange( e.target.value ) }
			style={{width: '100%'}}
		/>
	),
	stringFilter: ( {filter, onChange} ) => (   
        <DebounceInput
            debounceTimeout={200}
            minLength={1} 
            value={filter ? filter.value : '' }
            onChange={ e => onChange( e.target.value ) }
            style={{width: '100%'}}
        />
    ),
	dropdownFilter: ( options = [ 'open', 'closed', 'promoted' ], align ) => ( {filter, onChange} ) => (
		<OverlayTrigger trigger='focus' placement='bottom' overlay={
			<Popover id='status_popover' style={{maxWidth: '400px'}}>
				<ButtonGroup vertical style={{maxHeight: '50vh', overflowY: 'auto', position: 'relative'}}>
					{ options.map( option => (
						<Button
							key={option}
							onClick={ () => onChange( option ) }
							active={filter && filter.value === option}
							style={{textTransform: 'capitalize', textAlign: align ? align : null}}
						>{option}</Button>
					) ) }
				</ButtonGroup>
				{ filter && 
					<Button
						block
						onClick={ () => onChange( '' ) }
						bsStyle='primary'
						style={{marginTop: '3px'}}
					>Clear</Button>
				}
			</Popover>
		}>
			<input type='text' value={filter ? filter.value : ''} readOnly style={{width: '100%', cursor: 'pointer'}} />
		</OverlayTrigger>
	),
	dateRange: ( {filter, onChange} ) => (
		<OverlayTrigger trigger='click' rootClose placement='bottom' overlay={
			<Popover id='daterange_popover' style={{maxWidth: '350px'}}>
				<DateRangePicker numberOfCalendars={2} selectionType='range' showLegend={false} singleDateRange={true} onSelect={
					( range, states ) => { onChange( momentRangeToEpoch( range ) ) }
				} value={filter ? epochRangeToMoment( filter.value ) : null} />
				{ filter &&
						<Button block onClick={ () => { 
							onChange( '' );
							document.dispatchEvent( new MouseEvent( 'click' ) );
						} } bsStyle='primary'>Clear</Button>
				}
			</Popover>
		}>
			<input type='text' value={filter ? epochRangeToString( filter.value ) : ''} readOnly style={{width: '100%', cursor: 'pointer'}} />
		</OverlayTrigger>
	),
	tagFilter: ( type = 'tag' ) => ( {filter, onChange} ) => (
		<TagInput type={type} onChange={onChange} value={filter ? filter.value : []} />
	),
}

const customCellRenderers = {
	dateFormater: row => {
		let date = new Date( row.value * 1000 );
		return ( 
			<span>{date.toLocaleString()}</span>
		);
	},
	alertStatus: row => {
		let [ open, closed, promoted ] = row.value.split( '/' ).map( value => parseInt( value.trim(), 10 ) );
		let className = 'open btn-danger';
		if ( promoted ) {
			className = 'promoted btn-warning';
		} else if ( closed ) {
			if ( !open ) {
                className = 'closed btn-success';
		    }
        }

		return (
			<div className={`alertStatusCell ${className}`}>{row.value}</div>
		)
	},
	textStatus: row => {
		let color = 'green';
		if ( row.value === 'open' || row.value === 'disabled' || row.value === 'assigned' ) {
			color = 'red';
		} else if ( row.value === 'promoted' ) {
			color = 'orange';
		}

		return (
			<span style={{color: color}}>{row.value}</span>
		)
	},
}

const customTableComponents = {
	loading: ( {loading} ) => (
		<div className={'-loading'+ ( loading ? ' -active' : '' )}>
			<LoadingContainer loading={loading} />
		</div>
	),
}

const columnDefinitions = {
	Id: {
		Header: 'ID',
		accessor: 'id',
		maxWidth: 100,
		Filter: customFilters.numberFilter,
	},

	AlertStatus: {
		Header: 'Status',
		accessor: d => d.open_count +' / '+ d.closed_count +' / '+ d.promoted_count,
		column: [ 'open_count', 'closed_count', 'promoted_count' ],
		id: 'status',
		maxWidth: 150,
		Filter: customFilters.dropdownFilter(),
		Cell: customCellRenderers.alertStatus,
		style: {
			padding: 0,
		},
	},

	EventStatus: {
		Header: 'Status',
		accessor: 'status',
		maxWidth: 100,
		Cell: customCellRenderers.textStatus,
		Filter: customFilters.dropdownFilter(),
	},

	IncidentStatus: {
		Header: 'Status',
		accessor: 'status',
		maxWidth: 100,
		Cell: customCellRenderers.textStatus,
		Filter: customFilters.dropdownFilter( [ 'open', 'closed' ] ),
	},
	
	SigStatus: {
		Header: 'Status',
		accessor: 'status',
		maxWidth: 100,
		Cell: customCellRenderers.textStatus,
		Filter: customFilters.dropdownFilter( [ 'enabled', 'disabled' ] ),
	},

	TaskStatus: {
		Header: 'Task Status',
		accessor: d => d.metadata.task.status,
		id: 'metadata.task.status',
		column: 'metadata',
		Cell: customCellRenderers.textStatus,
		Filter: customFilters.dropdownFilter( [ 'open', 'assigned', 'closed' ] ),
	},

	TaskSummary: {
		Header: 'Task Summary',
		accessor: d => d.body_plain.length > 200 ? d.body_plain.substr(0, 200) +'...' : d.body_plain,
		id: 'summary',
		minWidth: 400,
		maxWidth: 5000,
		Filter: customFilters.stringFilter,
	},

	Subject: {
		Header: 'Subject',
		accessor: 'subject',
		minWidth: 400,
		maxWidth: 5000,
		Filter: customFilters.stringFilter,
	},

	Created: {
		Header: 'Created',
		accessor: 'created',
		minWidth: 100,
		maxWidth: 180,
		Filter: customFilters.dateRange,
		Cell: customCellRenderers.dateFormater,
	},

	Updated: {
		Header: 'Updated',
		accessor: 'updated',
		minWidth: 100,
		maxWidth: 180,
		Filter: customFilters.dateRange,
		Cell: customCellRenderers.dateFormater,
	},

	Occurred: {
		Header: 'Occurred',
		accessor: 'occurred',
		minWidth: 100,
		maxWidth: 180,
		Filter: customFilters.dateRange,
		Cell: customCellRenderers.dateFormater,
	},

	Sources: {
		Header: 'Sources',
		accessor: 'source', //d => d.source ? d.source.join( ', ' ) : '',
		column: 'source',
		id: 'source',
		minWidth: 120,
		//maxWidth: 150,
		Filter: customFilters.tagFilter( 'source' ),
	},

	Tags: {
		Header: 'Tags',
		accessor: 'tag', //d => d.tag ? d.tag.join( ', ' ) : '',
		column: 'tag',
		id: 'tag',
		minWidth: 120,
		//maxWidth: 150,
		Filter: customFilters.tagFilter( 'tag' ),
	},

    TaskOwner: {
		Header: 'Task Owner',
		accessor: 'owner',
		maxWidth: 80,
		Filter: customFilters.stringFilter,
	},
    
	Owner: {
		Header: 'Owner',
		accessor: 'owner',
		maxWidth: 80,
		Filter: customFilters.stringFilter,
	},

	Entries: {
		Header: 'Entries',
		accessor: 'entry_count',
		maxWidth: 70,
		Filter: customFilters.numberFilter,
	},

	Views: {
		Header: 'Views',
		accessor: 'views',
		maxWidth: 70,
		Filter: customFilters.numberFilter,
	},

	DOE: {
		Header: 'DOE',
		accessor: 'doe_report_id',
		maxWidth: 100,
		Filter: customFilters.stringFilter,
	},

	IncidentType: {
		Header: 'Type',
		accessor: 'type',
		minWidth: 200,
		maxWidth: 250,
		Filter: customFilters.dropdownFilter( constants.INCIDENT_TYPES, 'left' ),
	},

	AppliesTo: {
		Header: 'Applies To',
		accessor: 'applies_to',
		Filter: customFilters.stringFilter,
		minWidth: 400,
		maxWidth: 5000,
	},

	Value: {
		Header: 'Value',
		accessor: 'value',
		Filter: customFilters.stringFilter,
		minWidth: 400,
		maxWidth: 5000,
	},

	Name: {
		Header: 'Name',
		accessor: 'name',
		Filter: customFilters.stringFilter,
		minWidth: 200,
		maxWidth: 300,
	},

	Group: {
		Header: 'Group',
		accessor: d => d.signature_group ? d.signature_group.join( ', ' ) : '',
		column: 'signature_group',
		id: 'group',
		Filter: customFilters.stringFilter,
	},

	Type: {
		Header: 'Type',
		accessor: 'type',
		Filter: customFilters.stringFilter,
		minWidth: 100,
		maxWidth: 150,
	},

	Description: {
		Header: 'Description',
		accessor: 'description',
		Filter: customFilters.stringFilter,
		minWidth: 400,
		maxWidth: 5000,
	},

	TargetType: {
		Header: 'Type',
		accessor: d => d.target.type,
		column: 'target',
		id: 'target_type',
		Filter: customFilters.stringFilter,
	},
	
    TargetId: {
		Header: 'Target Id',
		accessor: d => d.target.id,
		column: 'target',
		id: 'target_id',
		Filter: customFilters.numberFilter,
	},

	OpenTasks: {
		Header: 'Open Tasks',
		accessor: 'has_tasks',
		Filter: customFilters.numberFilter,
	    maxWidth: 90,
        filterable: false,
    },
}

const defaultTableSettings = {
	manual: true,
	sortable: true,
	filterable: true,
	resizable: true,
	styleName: 'styles.ReactTable',
	className: '-striped -highlight',
	minRows: 0,

	LoadingComponent: customTableComponents.loading,

}

export const defaultTypeTableSettings = {
	page: 0,
	pageSize: 50,
	sorted: [ {
		id: 'id',
		desc: true,
	} ],
	filtered: [],
}

const defaultColumnSettings = {
	style: {
		padding: '5px 5px',
	},
}

const typeColumns = {
	alertgroup: [ 'Id', 'AlertStatus', 'Subject', 'Created', 'Sources', 'Tags', 'Views', 'OpenTasks' ],
	event: [ 'Id', 'EventStatus', 'Subject', 'Created', 'Updated', 'Sources', 'Tags', 'Owner', 'Entries', 'Views', 'OpenTasks' ],
	incident: [ 'Id', 'DOE', 'IncidentStatus', 'Owner', 'Subject', 'Occurred', 'IncidentType',
		{
			title: 'Tags',
			options: { minWidth: 100, maxWidth: 150 },
		},
		{
			title: 'Sources',
			options: { minWidth: 100, maxWidth: 150 },
		},
	],
	intel: [ 'Id', 'Subject', 'Created', 'Updated', 'Sources', 
		{
			title: 'Tags',
			options: { minWidth: 200, maxWidth: 250 },
		}, 'Owner', 'Entries', 'Views', ],
	task: [ 'Id', 'TargetType', 'TargetId', 
        {
			title: 'TaskOwner',
			options: { minWidth: 150, maxWidth: 500 },
		},
        'TaskStatus', 'TaskSummary',
		{
			title: 'Updated',
			options: { minWidth: 150, maxWidth: 500 },
		},
	],
	signature: [ 'Id', 'Name', 'Type', 'SigStatus', 'Group', 'Description', 'Owner', 'Tags', 'Sources', 'Updated', ],
	guide: [ 'Id', 'Subject', 'AppliesTo' ],
	entity: [ 'Id', 'Value', 'Type', 'Entries', ],
	default: [ 'Id', 'AlertStatus', 'Subject', 'Created', 'Sources', 'Tags', 'Views', ],
}

export const buildTypeColumns = ( type ) => {
	if ( !typeColumns.hasOwnProperty( type ) ) {
		// throw new Error( 'No columns defined for type: '+ type );
		type = 'default';
	}
	
    let columns = [];
	for ( let col of typeColumns[ type ] ) {
        let colOptions = {};
		
        if ( typeof col === 'object' ) {
			colOptions = {
				...columnDefinitions[ col.title ],
				...col.options,
			}
		} else if ( typeof col === 'string' ) {
			colOptions = columnDefinitions[ col ];
		}

		columns.push( {
			...defaultColumnSettings,
			...colOptions,
		} );
	}

	return columns;
}

export default defaultTableSettings;
