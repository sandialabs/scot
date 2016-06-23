import { FacetFilter } from "./FacetFilter";
import { FacetFilterProps } from "./FacetFilterProps";
export declare class MenuFilter extends FacetFilter<FacetFilterProps> {
    static propTypes: any;
    static defaultProps: any;
    toggleFilter(option: any): void;
    setFilters(options: any): void;
    getSelectedItems(): (string | number)[];
    getItems(): any;
}
