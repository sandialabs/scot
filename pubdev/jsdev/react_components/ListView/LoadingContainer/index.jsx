import React, { PureComponent } from 'react';
import PropTypes from 'prop-types';
import { CSSTransitionGroup } from 'react-transition-group';

import Icon from '../Icon';
import './styles.scss';

class LoadingContainer extends PureComponent {
	static propTypes = {
		loading: PropTypes.bool,
	}

	render() {
		return (
			<div styleName='LoadingContainer'>
				{ this.props.loading &&
					<CSSTransitionGroup
						transitionName='fade'
						transitionAppear={true}
						transitionLeave={true}
						transitionAppearTimeout={0}
						transitionEnterTimeout={0}
						transitionLeaveTimeout={0}
					>
						<div key={0} styleName='loading'>
							<span styleName='helper'></span>
							<Icon icon='refresh' />
						</div>
					</CSSTransitionGroup>
				}
			</div>
		)
	}
}

export default LoadingContainer;
