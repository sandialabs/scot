import React, { PureComponent, Component } from 'react';
import PropTypes from 'prop-types';
import { MenuItem, Button } from 'react-bootstrap';
import Modal from 'react-modal';
import { Link } from 'react-router-dom';

const customStyles = {
    content : {
        top     : '50%',
        left    : '50%',
        right   : 'auto',
        bottom  : 'auto',
        marginRight: '-50%',
        transform:  'translate(-50%, -50%)'
    }
}

class PromotedData extends Component {
    constructor( props ) { 
        super( props );

        this.state = {
            showAllPromotedDataToolbar: false 
        }
        
        this.showAllPromotedDataToggle = this.showAllPromotedDataToggle.bind(this);
    }

    showAllPromotedDataToggle() {
        if (this.state.showAllPromotedDataToolbar == false) {
            this.setState({showAllPromotedDataToolbar: true});
        } else {
            this.setState({showAllPromotedDataToolbar: false});
        }
    }

    render() {
        let promotedFromType = null;
        let fullarr = [];
        let shortarr = [];
        let shortforlength = 3;
        if (this.props.type == 'event') {
            promotedFromType = 'alert'
        } else if (this.props.type == 'incident') {
            promotedFromType = 'event'
        }
        //makes large array for modal
        for (let i=0; i < this.props.data.length; i++) {
            if (i > 0) {fullarr.push(<span> , </span>)}
            let link = '/' + promotedFromType + '/' + this.props.data[i];
            fullarr.push(<span key={this.props.data[i]}><Link to={link}>{this.props.data[i]}</Link></span>)
        }
        //makes small array for quick display in header
        if (this.props.data.length < 3 ) {
            shortforlength = this.props.data.length;
        }
        for (let i=0; i < shortforlength; i++) {
            if (i > 0) {shortarr.push(<div> , </div>)}
            let link = '/' + promotedFromType + '/' + this.props.data[i];
            shortarr.push(<div key={this.props.data[i]}><Link to={link}>{this.props.data[i]}</Link></div>)
        }
        if (this.props.data.length > 3) {shortarr.push(<div onClick={this.showAllPromotedDataToggle}>,<a href='javascript:;'>...more</a></div>)}
        return (
            <td>
            <span id='promoted_from' style={{display:'flex'}}>{shortarr}</span>
                {this.state.showAllPromotedDataToolbar ? <Modal isOpen={true} onRequestClose={this.showAllPromotedDataToggle} style={customStyles}>
                    <div className='modal-header'>
                        <img src='images/close_toolbar.png' className='close_toolbar' onClick={this.showAllPromotedDataToggle} />
                        <h3 id='myModalLabel'>Promoted From</h3>
                    </div>
                    <div className='modal-body promoted-from-full'>
                        {fullarr}
                    </div>
                    <div className='modal-footer'>
                        <Button id='cancel-modal' onClick={this.showAllPromotedDataToggle}>Close</Button>
                    </div>
                </Modal> : null }
            </td>
        )
    }
};

export default PromotedData;
