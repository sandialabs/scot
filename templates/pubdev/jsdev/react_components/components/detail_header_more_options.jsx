import React, { PureComponent, Component } from 'react';
import PropTypes from 'prop-types';
import { Dropdown, Button, MenuItem } from 'react-bootstrap';

import PromotedData from '../modal/promoted_data.jsx';

class DetailHeaderMoreOptions extends Component {
    constructor( props ) { 
        super( props );

        this.state = {
            optionsActive: false,    
        }
    
        this.ToggleOptions = this.ToggleOptions.bind(this);
    }

    componentWillMount() {
        
    }
    
    componentWillUnmount() {
        
    }
    
    componentWillReceiveProps() {

    }

    render() {
           
            return (
                <div className='detail-header-more-options'>
                    {this.props.showData ? 
                        <Dropdown id="detail-header-more-options" pullRight noCaret bsSize='small' >
                            <Dropdown.Toggle>
                                More
                            </Dropdown.Toggle>
                            <Dropdown.Menu>
                                {( this.props.type == 'event' || this.props.type == 'incident') ? 
                                    <PromotedData data={this.props.data.promoted_from} type={this.props.type} id={this.props.id} />
                                : 
                                    null
                                }
                                <MenuItem>Links</MenuItem>
                                <MenuItem>Checkbox & Marked Objects</MenuItem>
                            </Dropdown.Menu>
                        </Dropdown>
                    :
                        null 
                    }
                </div>
            )
    }

    ToggleOptions() {
        let newState = !this.state.optionsActive;
        this.setState({ optionsActive: newState });
    }
   
}
export default DetailHeaderMoreOptions;
