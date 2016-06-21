import { SearchkitComponent, HierarchicalFacetAccessor, SearchkitComponentProps } from "../../../../../core";
export interface HierarchicalMenuFilterProps extends SearchkitComponentProps {
    id: string;
    fields: Array<string>;
    title: string;
    size?: number;
    orderKey?: string;
    orderDirection?: string;
    countFormatter?: (count: number) => string | number;
}
export declare class HierarchicalMenuFilter extends SearchkitComponent<HierarchicalMenuFilterProps, any> {
    accessor: HierarchicalFacetAccessor;
    static defaultProps: {
        countFormatter: any;
    };
    static propTypes: any;
    defineBEMBlocks(): {
        container: string;
        option: string;
    };
    defineAccessor(): HierarchicalFacetAccessor;
    addFilter(option: any, level: any): void;
    renderOption(level: any, option: any): JSX.Element;
    renderOptions(level: any): JSX.Element;
    render(): JSX.Element;
}
