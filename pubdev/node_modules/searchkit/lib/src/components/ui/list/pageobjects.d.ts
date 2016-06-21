import { Component, List } from "xenon";
export declare class ItemComponent extends Component {
    checkbox: Component;
    label: Component;
    count: Component;
}
export declare class ItemList extends Component {
    options: List<ItemComponent>;
}
