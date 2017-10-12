import actionTypes from '../../../redux/actions';
import { tagInputPrefix } from './reducers';

export const doTagInput = ( type = 'tag', value ) => {
	return {
		type: actionTypes.fetchApiAction,
		url: '/ac/'+ type +'/'+ value,
		method: 'GET',
		actionPrefix: tagInputPrefix,
	}
}

