import { Component } from "xenon";
export declare class SearchLoader extends Component {
    static states: {
        HIDDEN: string;
    };
}
export declare class Searchbox extends Component {
    query: Component;
    submit: Component;
    loader: SearchLoader;
    search(query: string): void;
}
