import React, { PureComponent } from 'react';
import PropTypes from 'prop-types';
import { getDisplayName } from 'recompose';
import { Broadcast, Subscriber } from 'react-broadcast';
import * as LocalStorage from '../../components/local_storage'; 

/**
 * This file defines everything needed to use user settings
 * in components.
 *
 * This uses React's context API so that we don't need to have
 * a giant prop chain
 *
 * The provider sets everything up and is included at the top
 * of the application.
 *
 * The HOC is included with every component that wants access
 * to the object
 *
 * userConfig data format:
 * {
 *		key1: { data },
 *		key2: [ data, data, data, ],
 *		key3: true,
 *		...
 * }
 * where keys and data structures are defined in the UserConfigKeys
 * object
 *
 * Currently components may only access one key of userConfig.
 * 
 * WARNING: The context API is likely to change in the future
 * and this will need to be updated. Hopefully though, only
 * this file will need to be updated as nothing else directly
 * accesses context
 */

// Channel name for react-broadcast
const UserConfigChannel = 'userConfig';

const UserConfigKeyShape = {
	key: PropTypes.string.isRequired,
	default: PropTypes.any.isRequired,
};

/**
 * Unique keys for the structure of userConfig
 *
 * Structure:
 *		KEY_ID: {
 *			key: KEY_VALUE,
 *			default: DEFAULT_VALUE(S),
 *		}
 *
 *	This is how to specify the top-level key into the userConfig object
 *	and define the shape of the data as well as the default values
 */
export const UserConfigKeys = {
	DASHBOARD: {
		key: 'dashboard',
		default: {
			curTab: 0,
			tabs: [],
		},
	},
}

const UserConfigContextTypes = {
	getUserConfig: PropTypes.func,
	setUserConfig: PropTypes.func,
};

/**
 * This sets up the context provider for the userConfig object
 *
 * Only needs to be included once, somewhere at the top of the chain
 * Currently in main/index.js
 */
export class UserConfigProvider extends PureComponent {
	constructor( props ) {
		super( props );

		this.state = {
			userConfig: {
				loading: true,
			},
		}

		this.update = this.update.bind(this);
		this.setUserConfig = this.setUserConfig.bind(this);
	}

	static childContextTypes = UserConfigContextTypes;

	getChildContext() {
		return {
			getUserConfig: this.getUserConfig,
			setUserConfig: this.setUserConfig,
		}
	}

	/**
	 * Load user config
	 *
	 * Return: Promise
	 */
	getUserConfig() {
		// Currently just uses localstorage
		// This should be easy to change to use a backend at some point
		return new Promise( ( resolve, reject ) => {
			let json = LocalStorage.getLocalStorage( UserConfigChannel )
			if ( json ) {
				resolve( JSON.parse( json ) );
				return;
			}

			resolve( {} );
		} );
	}

	/**
	 * Save user config
	 *
	 * Return: Promise
	 */
	setUserConfig( config ) {
		// Currently just uses localstorage
		// This should be easy to change to use a backend at some point
		return new Promise( ( resolve, reject ) => {
			LocalStorage.setLocalStorage( UserConfigChannel, JSON.stringify( config ) );

			resolve();
		} ).then( () => {
			this.update();
		} );
	}

	update() {
		this.getUserConfig().then( ( config ) => {
			this.setState( {
				userConfig: config,
			} );
		} );
	}

	componentDidMount() {
		this.update();
	}

	render() {
		return (
			<Broadcast value={this.state.userConfig} channel={UserConfigChannel}>
				<div>
					{this.props.children}
				</div>
			</Broadcast>
		)
	}
}

/*
 * Defining shape for UserConfig props.
 *
 * This should be imported by wrapped components:
 * static propTypes = {
 *		( all local propTypes ),
 *		...UserConfigPropTypes,
 * };
 *
 * Children:
 *		config: the actual data,
 *		setUserConfig( config ): save changes to config
 *		getUserConfig(): load the config from source again
 *		loading: whether the config is currently loading
 */
export const UserConfigPropTypes = {
	userConfig: PropTypes.shape( {
		config: PropTypes.any.isRequired,
		setUserConfig: PropTypes.func.isRequired,
		getUserConfig: PropTypes.func.isRequired,
		loading: PropTypes.bool,
	} ).isRequired,
}

/**
 * Higher-order Component (HOC) for providing a subkey of userConfig
 * to a component
 *
 * Usage: (In component file)
 *		export default withUserConfig( KEY ) (COMPONENT);
 * Where:
 *		KEY: is one of the values above in UserConfigKeys
 *		COMPONENT: is the component needing access to userConfig
 *
 * Example:
 *		export default withUserConfig( UserConfigKeys.DASHBOARD ) (HomeDashboard);
 *		
 *		This gives HomeDashboard access to the dashboard portion of userConfig
 */
export const withUserConfig = ( configKey ) => {
	PropTypes.checkPropTypes( UserConfigKeyShape, configKey, 'argument', 'withUserConfig' );

	return ( WrappedComponent ) => {
		class UserConfigSubscriber extends PureComponent {
			constructor( props ) {
				super( props );

				this.state = {}

				this.setUserSubConfig = this.setUserSubConfig.bind(this);
			}

			static contextTypes = UserConfigContextTypes;
			static displayName = `withUserConfig(${getDisplayName( WrappedComponent )})`;
			static propTypes = {
				userConfig: PropTypes.object.isRequired,
			};

			/**
			 * This allows the wrapped component to only have to worry about its own
			 * portion of userConfig. Its changes are automatically wrapped back into
			 * the whole object
			 */
			setUserSubConfig( subConfig ) {
				let newConfig = {
					...this.props.userConfig,
				}
				newConfig[configKey.key] = subConfig;

				this.context.setUserConfig( newConfig );
			}

			render() {
				let { userConfig, ...restProps } = this.props;

				let data = userConfig[ configKey.key ] || configKey.default;
				const loading = userConfig.loading;

				const userConfigProps = {
					userConfig: {
						loading: loading === true,
						config: data,
						setUserConfig: this.setUserSubConfig,
						getUserConfig: this.context.getUserConfig,
					}
				};
				
				return (
					<WrappedComponent {...restProps} {...userConfigProps} />
				)
			}
		}

		const UserConfigHelper = ( props ) => (
			<Subscriber channel={UserConfigChannel}>
				{ data => ( <UserConfigSubscriber userConfig={data} {...props} /> ) }
			</Subscriber>
		)
		return UserConfigHelper;
	}
}

