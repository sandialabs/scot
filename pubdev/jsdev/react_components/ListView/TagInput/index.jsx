import React, { Component } from 'react';
import PropTypes from 'prop-types';
import ReactTags from 'react-tag-autocomplete';
import { connect } from 'react-redux';

import { stateKey } from './reducers';
import { doTagInput } from './actions';

import Icon from '../Icon';

import './styles.scss';

class TagInput extends Component {
	constructor( props ) {
		super( props );

		this.handleDelete = this.handleDelete.bind( this );
		this.handleAdd = this.handleAdd.bind( this );
		this.handleInputChange = this.handleInputChange.bind( this );
	}

	static propTypes = {
		onChange: PropTypes.func.isRequired,
		type: PropTypes.oneOf( [ 'source', 'tag' ] ).isRequired,
		value: PropTypes.array.isRequired,
		suggestions: PropTypes.array.isRequired,
	}

	handleDelete( i ) {
		const tags = [...this.props.value];
		tags.splice( i, 1 );
		if ( tags.length === 0 ) {
			this.props.onChange( '' );
			return;
		}
		this.props.onChange( tags );
	}

	handleAdd( tag ) {
		const tags = [...this.props.value];
		tags.push( tag );
		this.props.onChange( tags );
	}

	handleInputChange( input ) {
		if ( input && input.length >= 2 ) {
			this.props.getTagInput( this.props.type, input );
		}
	}

	render() {
		return (
			<div styleName='TagInput'>
				<ReactTags
					tags={this.props.value}
					suggestions={this.props.suggestions}
					handleAddition={this.handleAdd}
					handleDelete={this.handleDelete}
					handleInputChange={this.handleInputChange}
					autoresize={false}
					autofocus={false}
					allowBackspace={false}
					placeholder=''
					tagComponent={Tag}
				/>
			</div>
		)
	}
}

const Tag = ( { classNames, onDelete, tag } ) => (
	<div className={classNames.selectedTag}>
		<span className={classNames.selectedTagName}>{tag.name}</span>
		<Icon icon='remove' onClick={onDelete} />
	</div>
)

const mapStateToProps = ( state, ownProps ) => {
	let data = state[ stateKey ];
	let suggestions = data.data ? data.data : [];
	return {
		suggestions: suggestions.map( entry => {
			return {
				id: entry.id,
				name: entry.value,
			}
		} ),
		...ownProps,
	}
}

const mapDispatchToProps = ( dispatch ) => {
	return {
		getTagInput: ( type, value ) => dispatch( doTagInput( type, value ) ),
	}
}

export default connect( mapStateToProps, mapDispatchToProps ) ( TagInput );
export * from './reducers';
