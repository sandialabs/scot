import { FilterBasedAccessor } from "./FilterBasedAccessor";
import { ObjectState } from "../state";
import { FieldOptions, FieldContext } from "../query";
export interface RangeAccessorOptions {
    title: string;
    id: string;
    min: number;
    max: number;
    interval?: number;
    field: string;
    loadHistogram?: boolean;
    fieldOptions?: FieldOptions;
}
export declare class RangeAccessor extends FilterBasedAccessor<ObjectState> {
    options: any;
    state: ObjectState;
    fieldContext: FieldContext;
    constructor(key: any, options: RangeAccessorOptions);
    buildSharedQuery(query: any): any;
    getBuckets(): any;
    isDisabled(): boolean;
    getInterval(): any;
    buildOwnQuery(query: any): any;
}
