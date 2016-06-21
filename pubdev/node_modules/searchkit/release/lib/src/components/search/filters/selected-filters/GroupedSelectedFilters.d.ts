import { SearchkitComponent, SearchkitComponentProps, ReactComponentType } from "../../../../core";
import { FilterGroup } from "../../../ui";
export interface GroupedSelectedFiltersProps extends SearchkitComponentProps {
    groupComponent?: ReactComponentType<any>;
}
export declare class GroupedSelectedFilters extends SearchkitComponent<GroupedSelectedFiltersProps, any> {
    static propTypes: any;
    static defaultProps: {
        groupComponent: typeof FilterGroup;
    };
    constructor(props: any);
    defineBEMBlocks(): {
        container: string;
    };
    getFilters(): Array<any>;
    getGroupedFilters(): Array<any>;
    hasFilters(): boolean;
    removeFilter(filter: any): void;
    removeFilters(filters: any): void;
    render(): JSX.Element;
}
