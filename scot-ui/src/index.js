import React from "react";
import ReactDOM from "react-dom";
import "./styles/css/index.css";
import AMQ from "./main/index";
import registerServiceWorker from "./registerServiceWorker";
import { BrowserRouter } from "react-router-dom";
import Switch from "react-router-dom/es/Switch";
import { Route } from "react-router-dom/";
import { HashRouter } from "react-router-dom/";

// let customHistory = require("history").createBrowserHistory;

// ReactDOM.render(
//   <HashRouter history={customHistory()}>
//     <Switch>
//       <Route exact path="/" component={AMQ} />
//       <Route exact path="/:value" component={AMQ} />
//       <Route exact path="/:value/:id" component={AMQ} />
//       <Route exact path="/:value/:id/:id2" component={AMQ} />
//       <Route path="/:value/:type/:id/:id2" component={AMQ} />
//     </Switch>
//   </HashRouter>,
//   document.getElementById("root")
// );
registerServiceWorker();

ReactDOM.render(
  <BrowserRouter>
    <Switch>
      <Route exact path="/" component={AMQ} />
      <Route exact path="/:value" component={AMQ} />
      <Route exact path="/:value/:id" component={AMQ} />
      <Route exact path="/:value/:id/:id2" component={AMQ} />
      <Route path="/:value/:type/:id/:id2" component={AMQ} />
    </Switch>
  </BrowserRouter>,
  document.getElementById("root")
);
