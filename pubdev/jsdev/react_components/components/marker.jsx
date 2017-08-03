import React, { PureComponent, Component } from 'react';
import PropTypes from 'prop-types';
import { Modal } from 'react-bootstrap';
import ReactTable from 'react-table';

class Marker extends Component {
    constructor( props ) { 
        super( props );

        this.state = {
            marked: [],
            isMarked: false,
        }
        
    }

    componentWillMount() {
        this.mounted = true;
        
        for (let key of this.getMarkedItems() ) {
            if ( key.id === this.props.id && key.type === this.props.type ) {
                this.setState({ isMarked: true });
            }
        }
        this.setState( { marked: JSON.parse( marked ) } );
    }
    
    componentWillUnmount() {
        this.mounted = false;
    }
    
    render() {
        return (
            <div onClick={ `${ this.state.isMarked ? this.removeMarkedItems : this.setMarkedItems }` }>
                <i style={color: `${ this.state.isMarked ? 'green' : '' } `} className={`fa fa${this.state.isMarked ? '-check' : '' }-square-o`} aria-hidden="true"></i>
                { this.state.isMarked ? <div>Marked</div> : <div>Mark</div> }
            </div>
        )
    }
    
    getMarkedItems() {
        let markedItems = JSON.parse( getLocalStorage( 'marked' ) );
        this.setState({ marked : markedItems });
        return { markedItems };
    }

    removeMarkedItems( type, id ) {
        
    }

    setMarkedItems ( type, id, subject ) {
        //let setMarked = new Set();
        //setMarked.add( JSON.stringify( getMarkedItems() ) );
        //setMarked.add( JSON.stringify( { 'type': type, 'id' : id, 'subject' : subject } ) );
        if ( !this.state.isMarked ) {
            for ( let key of this.getMarkedItems ) {
                let currentMarked = getMarkedItems();
            }
            let nextMarked = {};
            setLocalStorage( 'marked' , JSON.stringify( [ nextMarked, currentMarked ] );
        }
    }
    
}

Mark.propTypes = {
    isMarked: PropTypes.bool
}

Mark.defaultProps = {
    isMarked: false
}

export default Mark;
