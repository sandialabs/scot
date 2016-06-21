import * as React from "react";
import { FacetFilterProps } from "./FacetFilterProps";
import { FacetAccessor, SearchkitComponent, ISizeOption, FieldOptions } from "../../../../core";
import { CheckboxItemList, Panel } from "../../../ui";
export declare class FacetFilter<T extends FacetFilterProps> extends SearchkitComponent<T, any> {
    accessor: FacetAccessor;
    static propTypes: any;
    static defaultProps: {
        listComponent: typeof CheckboxItemList;
        containerComponent: typeof Panel;
        size: number;
        collapsable: boolean;
        showCount: boolean;
        showMore: boolean;
        bucketsTransform: any;
    };
    constructor(props: any);
    getAccessorOptions(): {
        id: string;
        operator: string;
        title: string;
        size: number;
        include: string[] | string;
        exclude: string[] | string;
        field: string;
        translations: Object;
        orderKey: string;
        orderDirection: string;
        fieldOptions: FieldOptions;
    };
    defineAccessor(): FacetAccessor;
    defineBEMBlocks(): {
        container: string;
        option: string;
    };
    componentDidUpdate(prevProps: any): void;
    toggleFilter(key: any): void;
    setFilters(keys: any): void;
    toggleViewMoreOption(option: ISizeOption): void;
    hasOptions(): boolean;
    getSelectedItems(): (string | number)[];
    getItems(): any;
    render(): React.ReactElement<any>;
    renderShowMore(): JSX.Element;
}
