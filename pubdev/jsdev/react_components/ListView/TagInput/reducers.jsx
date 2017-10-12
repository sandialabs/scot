import { buildFetchReducer } from '../../../redux/reducers/builder';

export const tagInputPrefix = 'TAGINPUT';
export const stateKey = 'tagSuggestions';
export const clearTagSuggestionsAction = 'CLEAR_TAG_INPUT';

export const handleTagInput = buildFetchReducer( { actionPrefix: tagInputPrefix, clearAction: clearTagSuggestionsAction, } );
