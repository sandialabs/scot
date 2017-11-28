import React, { PureComponent } from 'react';
import PropTypes from 'prop-types';
import { CSSTransitionGroup } from 'react-transition-group';

class LoadingContainer extends PureComponent {
	static propTypes = {
		loading: PropTypes.bool,
	}

	render() {
		return (
			<div className='LoadingContainer'>
				{ this.props.loading ?
				    <i className='fa fa-spinner fa-spin fa-2x' aria-hidden='true' />	
				:
                    null
                }
			</div>
		)
	}
}

export default LoadingContainer;
