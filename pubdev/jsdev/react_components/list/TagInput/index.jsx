import React, { Component } from 'react';
import PropTypes from 'prop-types';
import ReactTags from 'react-tag-autocomplete';

class TagInput extends Component {
	constructor( props ) {
		super( props );

        let tags = [];
        if ( this.props.value ) { tags = this.props.value };
        this.state = {
            suggestions: [],
            tags: tags,
        }
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
            this.setState({tags: tags });
			return;
		}
		this.props.onChange( tags );
        this.setState({tags: tags });
	}

	handleAdd( tag ) {
		const tags = [...this.props.value];
		tags.push( tag );
		this.props.onChange( tags );
        this.setState({tags : tags});
	}

	handleInputChange( input ) {
		if ( input && input.length >= 2 ) {
            var arr = [];
            $.ajax({
                type:'get',
                url:'/scot/api/v2/ac/' + this.props.type + '/' + input,
                success: function (result) {
                    var result = result.records;
                    for (var i=0; i < result.length; i++) {
                        let obj = {};
                        obj.id = i+1;
                        obj.name = result[i];
                        arr.push(obj)
                    }
                    this.setState({suggestions:arr})
                }.bind(this),
                error: function(data) {
                    console.log('failed to get autocomplete data');
                }.bind(this)
            })	
        }
	}

	render() {
		return (
			<div className='TagInput'>
				<ReactTags
					tags={this.state.tags}
					suggestions={this.state.suggestions}
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
	    <i className={'fa fa-remove'} aria-hidden='true' onClick={onDelete} />
    </div>
)

export default TagInput;
