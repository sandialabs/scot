import * as React from "react";
import { SearchkitComponent, SearchkitComponentProps, NoFiltersHitCountAccessor, SuggestionsAccessor, ReactComponentType } from "../../../../core";
import { NoHitsErrorDisplay, NoHitsErrorDisplayProps } from "./NoHitsErrorDisplay";
import { NoHitsDisplay, NoHitsDisplayProps } from "./NoHitsDisplay";
export interface NoHitsProps extends SearchkitComponentProps {
    suggestionsField?: string;
    errorComponent?: ReactComponentType<NoHitsErrorDisplayProps>;
    component?: ReactComponentType<NoHitsDisplayProps>;
}
export declare class NoHits extends SearchkitComponent<NoHitsProps, any> {
    noFiltersAccessor: NoFiltersHitCountAccessor;
    suggestionsAccessor: SuggestionsAccessor;
    static translations: {
        "NoHits.NoResultsFound": string;
        "NoHits.NoResultsFoundDidYouMean": string;
        "NoHits.DidYouMean": string;
        "NoHits.SearchWithoutFilters": string;
        "NoHits.Error": string;
        "NoHits.ResetSearch": string;
    };
    translations: {
        "NoHits.NoResultsFound": string;
        "NoHits.NoResultsFoundDidYouMean": string;
        "NoHits.DidYouMean": string;
        "NoHits.SearchWithoutFilters": string;
        "NoHits.Error": string;
        "NoHits.ResetSearch": string;
    };
    static propTypes: any;
    static defaultProps: {
        errorComponent: typeof NoHitsErrorDisplay;
        component: typeof NoHitsDisplay;
    };
    componentWillMount(): void;
    defineBEMBlocks(): {
        container: string;
    };
    getSuggestion(): any;
    setQueryString(query: any): void;
    resetFilters(): void;
    resetSearch(): void;
    getFilterCount(): any;
    render(): React.ReactElement<any>;
}
