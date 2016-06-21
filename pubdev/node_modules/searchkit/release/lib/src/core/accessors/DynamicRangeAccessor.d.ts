import { FilterBasedAccessor } from "./FilterBasedAccessor";
import { ObjectState } from "../state";
import { FieldOptions, FieldContext } from "../query";
export interface DynamicRangeAccessorOptions {
    title: string;
    id: string;
    field: string;
    fieldOptions?: FieldOptions;
}
export declare class DynamicRangeAccessor extends FilterBasedAccessor<ObjectState> {
    options: any;
    fieldContext: FieldContext;
    state: ObjectState;
    constructor(key: any, options: DynamicRangeAccessorOptions);
    buildSharedQuery(query: any): any;
    getStat(stat: any): any;
    isDisabled(): boolean;
    buildOwnQuery(query: any): any;
}
