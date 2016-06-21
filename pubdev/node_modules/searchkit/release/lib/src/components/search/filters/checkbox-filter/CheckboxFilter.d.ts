import * as React from "react";
import { SearchkitComponent, SearchkitComponentProps, CheckboxFilterAccessor, ReactComponentType } from "../../../../core";
import { Panel, CheckboxItemList } from "../../../ui";
export interface CheckboxFilterProps extends SearchkitComponentProps {
    id: string;
    filter: any;
    title: string;
    label: string;
    containerComponent?: ReactComponentType<any>;
    listComponent?: ReactComponentType<any>;
    showCount?: boolean;
}
export declare class CheckboxFilter extends SearchkitComponent<CheckboxFilterProps, any> {
    accessor: CheckboxFilterAccessor;
    static propTypes: any;
    static defaultProps: {
        listComponent: typeof CheckboxItemList;
        containerComponent: typeof Panel;
        collapsable: boolean;
        showCount: boolean;
    };
    constructor(props: any);
    defineAccessor(): CheckboxFilterAccessor;
    toggleFilter(key: any): void;
    setFilters(keys: any): void;
    getSelectedItems(): string[];
    render(): React.ReactElement<any>;
}
