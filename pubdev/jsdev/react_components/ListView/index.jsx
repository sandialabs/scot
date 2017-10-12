import React, { PureComponent } from 'react';
//import PropTypes from 'prop-types';
//import { connect } from 'react-redux';
import ReactTable from 'react-table';
//import { push } from 'react-router-redux';
//import { isEqual } from 'lodash-es';

//import tableSettings, { buildTypeColumns, defaultTypeTableSettings } from './tableConfig';
//import { doListData, doListDataTableSettings} from '../../redux/actions/mainData';
//import { doCancelFetch } from '../../redux/actions';
//import { listDataKey, tableSettingsKey } from '../../redux/reducers';

//import 'react-table/react-table.css';
//import 'react-daterange-picker/src/css/react-calendar.scss';
// complains about not using 'styles'
// eslint-disable-next-line
//import styles from './styles.scss'; // Have to be named because of the vendor import

class ListView extends PureComponent {
	constructor( props ) {
		super( props );

		this.handleFilters = this.handleFilters.bind( this );
		this.handleSorts = this.handleSorts.bind( this );
		this.clearFilters = this.clearFilters.bind( this );
		this.handlePageChange = this.handlePageChange.bind( this );
		this.handlePageSizeChange = this.handlePageSizeChange.bind( this );
		this.handleDataChange = this.handleDataChange.bind( this );
		this.handleSelection = this.handleSelection.bind( this );
		this.keyNavigate = this.keyNavigate.bind( this );
	}

	//static propTypes = {
	//	type: PropTypes.string.isRequired,
	//}

	handleFilters( filtered ) {
		if ( this.props.loading ) {
			this.props.cancelLoad( this.props.requestId );
		}

		let { type, tablePageSize, tableSorted } = this.props;
		this.props.setTableSettings( type, 0, tablePageSize, tableSorted, filtered );
	}

	clearFilters() {
		if ( this.props.loading ) {
			this.props.cancelLoad( this.props.requestId );
		}

		let { type, tablePageSize } = this.props;
		this.props.setTableSettings( type, 0, tablePageSize, defaultTypeTableSettings.sorted, [] );
	}

	addClearFilterButton() {
		if ( this.props.buttonToolbar ) {
			this.props.buttonToolbar.registerButton( 'clearfilters-button', {
				text: 'Clear All Filters',
				priority: 10,
				onClick: this.clearFilters,
				bsStyle: 'info',
			} );
		}
	}

	removeClearFilterButton() {
		if ( this.props.buttonToolbar ) {
			this.props.buttonToolbar.removeButton( 'clearfilters-button' );
		}
	}

	showHideFilterButton() {
		let show = false;
		if ( this.props.tableFiltered.length > 0 ) {
			show = true;
		}

		if ( !isEqual( this.props.tableSorted, defaultTypeTableSettings.sorted ) ) {
			show = true;
		}

		if ( show ) {
			this.addClearFilterButton();
		} else {
			this.removeClearFilterButton();
		}
	}

	handleSorts( sorted ) {
		if ( this.props.loading ) {
			this.props.cancelLoad( this.props.requestId );
		}

		let { type, tablePageSize, tableFiltered } = this.props;
		this.props.setTableSettings( type, 0, tablePageSize, sorted, tableFiltered );
	}

	handlePageChange( pageIndex ) {
		if ( this.props.loading ) {
			this.props.cancelLoad( this.props.requestId );
		}

		let { type, tablePageSize, tableSorted, tableFiltered } = this.props;
		this.props.setTableSettings( type, pageIndex, tablePageSize, tableSorted, tableFiltered );
	}

	handlePageSizeChange( pageSize, pageIndex ) {
		if ( this.props.loading ) {
			this.props.cancelLoad( this.props.requestId );
		}

		let { type, tableSorted, tableFiltered } = this.props;
		this.props.setTableSettings( type, pageIndex, pageSize, tableSorted, tableFiltered );
	}

	handleDataChange( props = this.props ) {
		if ( this.props.loading ) {
			this.props.cancelLoad( this.props.requestId );
			this.handleDataChange();
			return;
		}

		let { tablePage, tablePageSize, tableSorted, tableFiltered } = props;

		// Build parameters
		let queryParams = {
			limit: tablePageSize,
			offset: tablePage * tablePageSize,
		}
		tableFiltered.forEach( filter => {
			switch( filter.id ) {
				case 'created':
				case 'modified':
					queryParams[ filter.id ] = [
						filter.value.start,
						filter.value.end,
					]
					break;
				case 'tag':
				case 'source':
					if ( !queryParams[ filter.id ] ) {
						queryParams[ filter.id ] = [];
					}
					filter.value.forEach( value => {
						queryParams[ filter.id ].push( value.name );
					} );
					break;
				default:
					queryParams[ filter.id ] = filter.value;
			}
		} );
		let sort = {};
		tableSorted.forEach( column => {
			sort[ column.id ] = column.desc ? -1 : 1;
		} );
		queryParams.sort = JSON.stringify( sort );

		// Only grab relevent columns
		let columnList = buildTypeColumns( this.props.type );
		let fetchColumns = new Set();
		columnList.forEach( column => {
			if ( typeof column.accessor === 'string' ) {
				fetchColumns.add( column.accessor );
				return;
			}

			if ( !column.column ) {
				throw new Error( 'If your accessor is not a string, you must define a \'column\' attribute with the field that you need' );
			}

			if ( typeof column.column === 'object' && Array.isArray( column.column ) ) {
				for ( let curCol of column.column ) {
					fetchColumns.add( curCol );
				}
			} else {
				fetchColumns.add( column.column );
			}
		} );
		queryParams.columns = Array.from( fetchColumns );

		// Fire query
		this.props.getListData( this.props.type, queryParams );
	}

	handleSelection( itemId ) {
		itemId = parseInt( itemId, 10 );
		return ( state, rowInfo, column, instance ) => {
			return {
				onClick: event => {
					if ( itemId === rowInfo.row.id ) {
						return;
					}

					this.props.navigate( `/${this.props.type}/${rowInfo.row.id}` );
				},
				className: rowInfo.row.id === itemId ? 'selected' : null,
			}
		}
	}

	keyNavigate( event ) {
		if ( event.type !== 'click' ) {
			if ( ![ 'j', 'k', 'ArrowUp', 'ArrowDown' ].includes( event.key ) ) {
				return;
			}
			
			let target = event.target || event.srcElement;
			let targetType = target.tagName.toLowerCase();
			if ( targetType === 'input' || targetType === 'textarea' ) {
				return;
			}
		}

		let curRow = document.querySelector( '.ReactTable .rt-tbody .rt-tr.selected' );
		if ( !curRow ) {
			return;
		}
		let nextRow = null;

		switch( event.key ) {
			case 'j':
			case 'ArrowDown':
			default:
				nextRow = curRow.parentElement.nextElementSibling;
				break;
			case 'k':
			case 'ArrowUp':
				nextRow = curRow.parentElement.previousElementSibling;
				break;
		}

		if ( !nextRow ) {
			return;
		}
		let nextId = nextRow.children[0].children[0].innerHTML;

		this.props.navigate( `/${this.props.type}/${nextId}` );

		event.preventDefault();
		event.stopPropagation();
	}

	componentWillReceiveProps( nextProps ) {
		// If we have new amq messages, see if anything is applicable and reload data
		if ( nextProps.amq.messages.length > 0 && nextProps.amq.messages !== this.props.amq.messages ) {
			let refreshNeeded = false;
			for ( let message of nextProps.amq.messages ) {
				// Ignore if type doesn't match
				if ( message.data.type !== this.props.type ) {
					continue;
				}

				// Check if id matches currently selected item
				if ( this.props.itemId && this.props.itemId === message.data.id ) {
					refreshNeeded = true;
					break;
				}
				// Check if id is in loaded data
				let id = parseInt( message.data.id, 10 );
				for ( let row of this.props.tableData ) {
					if ( row.id === id ) {
						refreshNeeded = true;
						break;
					}
				}

				if ( refreshNeeded ) {
					break;
				}
			}

			if ( refreshNeeded ) {
				this.handleDataChange();
			}

			this.props.amq.messagesProcessed();
		}

		// Fetch new data
		let refreshNeeded = this.props.tablePage !== nextProps.tablePage ||
							this.props.tablePageSize !== nextProps.tablePageSize ||
							this.props.tableSorted !== nextProps.tableSorted ||
							this.props.tableFiltered !== nextProps.tableFiltered;

		if ( refreshNeeded ) {
			this.handleDataChange( nextProps );
		}
	}

	componentDidUpdate( prevProps ) {
		if ( this.props.buttonToolbar ) {
			this.showHideFilterButton();
		}

		let row = document.querySelector( '.ReactTable .rt-tbody .rt-tr.selected' );
		let tbody = document.querySelector( '.ReactTable .rt-tbody' );

		if ( !row ) {
			tbody.scrollTop = 0;
			return;
		}

		if ( tbody.scrollTop + tbody.offsetHeight - row.offsetHeight < row.offsetTop || row.offsetTop < tbody.scrollTop ) {
			tbody.scrollTop = row.offsetTop - tbody.offsetHeight / 2 + row.offsetHeight / 2;
		}
	}

	componentWillMount() {
		document.addEventListener( 'keydown', this.keyNavigate );
	}

	componentDidMount() {
		this.handleDataChange();
	}

	componentWillUnmount() {
		this.removeClearFilterButton();

		document.removeEventListener( 'keydown', this.keyNavigate );
	}

	render() {
		let columns = buildTypeColumns( this.props.type );
		let numPages = Math.floor( this.props.dataCount / this.props.tablePageSize ) + 1;

		return (
			<ReactTable 
				data={!this.props.error ? this.props.tableData : []}
				noDataText={this.props.error ? this.props.error : undefined}
				loading={this.props.loading}
				columns={columns}
				pages={!this.props.error ? numPages : 0}

				page={this.props.tablePage}
				onPageChange={this.handlePageChange}
				pageSize={this.props.tablePageSize}
				onPageSizeChange={this.handlePageSizeChange}
				filtered={this.props.tableFiltered}
				onFilteredChange={this.handleFilters}
				sorted={this.props.tableSorted}
				onSortedChange={this.handleSorts}

				getTrProps={this.handleSelection( this.props.itemId )}

				{...tableSettings} />
		)
	}
}

/*const mapStateToProps = ( state = {}, ownProps ) => {
	const listData = state[ listDataKey ];
	const sortFilter = state[ tableSettingsKey ];

	let settingsDataType = ownProps.type !== listData.dataType ? ownProps.type : listData.dataType;
	let { sorted, filtered, page, pageSize } = sortFilter[ settingsDataType ] ? sortFilter[ settingsDataType ] : defaultTypeTableSettings;

	return { 
		tableData: listData.data,
		dataCount: listData.dataCount,
		dataType: listData.dataType,
		loading: listData.loading,
		requestId: listData.requestId,
		error: listData.error,
		tableSorted: sorted,
		tableFiltered: filtered,
		tablePage: page,
		tablePageSize: pageSize,
		...ownProps,
	}
}
*/
/*
const mapDispatchToProps = ( dispatch ) => {
	return {
		getListData: ( type, urlParams ) => dispatch( doListData( type, urlParams ) ),
		setTableSettings: ( type, page, pageSize, sorted, filtered ) => {
			dispatch( doListDataTableSettings( type, page, pageSize, sorted, filtered ) );
		},
		cancelLoad: ( requestId ) => dispatch( doCancelFetch( requestId ) ),
		navigate: ( path ) => dispatch( push( path ) ),
	}
}
*/
export default ListView;
