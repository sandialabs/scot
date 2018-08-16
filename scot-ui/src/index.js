import React from 'react';
import ReactDOM from 'react-dom';
import './index.css';
import { AMQ } from './activemq/amq';
import registerServiceWorker from './registerServiceWorker';
import Switch from "react-router-dom/es/Switch";
import Route from "react-router-dom/es/Route";
import HashRouter from "react-router-dom/es/HashRouter";
let customHistory   = require( 'history' ).createBrowserHistory;

ReactDOM.render(<HashRouter history={customHistory()}>
    <Switch>
        <Route exact path = '/' component = {AMQ} />
        <Route exact path = '/:value' component = {AMQ} />
        <Route exact path = '/:value/:id' component = {AMQ} />
        <Route exact path = '/:value/:id/:id2' component = {AMQ} />
        <Route path = '/:value/:type/:id/:id2' component = {AMQ} />
    </Switch>
</HashRouter>, document.getElementById('root'));
registerServiceWorker();