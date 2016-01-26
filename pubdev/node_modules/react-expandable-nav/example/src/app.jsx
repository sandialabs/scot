'use strict';

var React = require('react');

var ExpandableNav = require('../../src/index');
var {ExpandableNavContainer, ExpandableNavbar, ExpandableNavHeader,
    ExpandableNavMenu, ExpandableNavMenuItem, ExpandableNavPage,
    ExpandableNavToggleButton} = ExpandableNav;

{
  /*jslint browser: true */
  window.React = React;
  var $ = window.$;
}

var App = React.createClass({
  componentDidMount() {
    $('[data-toggle="menuitem-tooltip"]').tooltip();
  },
  render() {
    var headerSmall = <span className="logo">&lt;B&gt;</span>;
    var headerFull = <span>&lt;Bootstrap&gt;</span>;

    var menuItemsSmall = [
      <span className="glyphicon glyphicon-home"></span>,
      <span className="glyphicon glyphicon-user"></span>,
      <span className="glyphicon glyphicon-comment"></span>
    ];
    var menuItemsFull = [
      <span>Home</span>,
      <span>About us</span>,
      <span>Contact us</span>
    ];
    var headerStyle = {
      paddingLeft: 5
    };
    var fullStyle = {
      paddingLeft: 50
    };
    return (
      <ExpandableNavContainer expanded={true} >
        <ExpandableNavbar fullClass="full" smallClass="small">
          <ExpandableNavHeader small={headerSmall} full={headerFull} headerStyle={headerStyle} fullStyle={fullStyle}/>
          <ExpandableNavMenu>
            <ExpandableNavMenuItem small={menuItemsSmall[0]} full={menuItemsFull[0]} tooltip={"Home"} jquery={window.$}/>
            <ExpandableNavMenuItem small={menuItemsSmall[1]} full={menuItemsFull[1]} tooltip={"About us"} jquery={window.$} />
            <ExpandableNavMenuItem small={menuItemsSmall[2]} full={menuItemsFull[2]} tooltip={"Contact us"} jquery={window.$}/>
          </ExpandableNavMenu>
        </ExpandableNavbar>
        <ExpandableNavToggleButton smallClass="s" className="shared"/>
        <ExpandableNavPage>
          <div className="row">
            <h2>React component for twitch-like navbar layout </h2>
            <p>The style is inspired by <a href="http://bootsnipp.com/snippets/featured/twitch-like-navbar">http://bootsnipp.com/snippets/featured/twitch-like-navbar</a></p>
          </div>
          <div className="row">
              <h2>Navbar Styles</h2>
              <p>Lorem ipsum dolor sit amet, consectetur adipiscing elit. Praesent vitae rutrum neque, non pretium odio. Cras mi ipsum, convallis in rutrum vitae, consectetur et diam. Phasellus varius sagittis condimentum. Aliquam erat volutpat. Nam tincidunt maximus sodales. Curabitur eleifend neque vitae elit ultrices accumsan. Maecenas eleifend arcu non tellus gravida lacinia eget quis sem. Aliquam maximus porta fringilla. Ut id egestas ante. Ut dapibus rhoncus ex a sodales. Sed mollis rutrum massa a commodo. Pellentesque habitant morbi tristique senectus et netus et malesuada fames ac turpis egestas. Morbi cursus tellus purus. Donec eu tellus volutpat, dapibus odio vitae, luctus leo.
                Morbi semper quam ac imperdiet tempor. Etiam varius non risus ut cursus. Donec sagittis tristique nunc at elementum. Maecenas lobortis ligula vel dui malesuada, non semper neque fringilla. Suspendisse auctor vulputate diam porta ornare. Nulla arcu odio, pellentesque non odio non, suscipit interdum mi. Nam venenatis urna lorem, in volutpat purus euismod mollis. Vestibulum condimentum convallis ligula, a euismod libero condimentum a. Proin euismod libero laoreet luctus euismod. Duis est neque, pulvinar vitae congue quis, tempor in tortor. In lacus odio, tempor sed molestie eget, scelerisque a lacus. In hendrerit velit et augue gravida congue.
                </p>
          </div>
          <div className="row">
            <div className="col-md-3">
              <p>Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nullam euismod justo in eleifend egestas. Nam tellus nulla, rutrum quis efficitur vel, interdum in dolor. Donec nec enim in tortor faucibus efficitur a ut diam. Sed eleifend felis sem, a iaculis ex semper id. Mauris ligula turpis, scelerisque et sem eget, consequat blandit ex. Sed ultricies turpis nec metus egestas, sed egestas libero aliquam. Aliquam laoreet ipsum eget viverra maximus. Ut mollis odio quis leo molestie efficitur. Fusce egestas sapien a elementum gravida. Vestibulum in facilisis justo, id condimentum mauris.
              Donec lacinia lacus</p>
            </div>
            <div className="col-md-3">
              <p>dolor non, vehicula blandit odio. In non dolor ullamcorper mauris finibus dapibus. In quis massa nec tortor fermentum sollicitudin nec id ligula. Sed sagittis volutpat euismod. Nullam nec nulla eu augue lobortis tempus. Ut commodo enim elit, fermentum pharetra augue venenatis quis. Aliquam erat volutpat. Mauris eu urna facilisis, blandit lorem vel, aliquet mauris. Aenean ipsum lectus, pretium non diam ut, egestas elementum lectus. Nam sit amet sem facilisis, blandit dolor id, euismod lorem. Nam vitae consequat purus.
              </p>
            </div>
            <div className="col-md-3">
              <p>Pellentesque habitant morbi tristique senectus et netus et malesuada fames ac turpis egestas. Aliquam porttitor laoreet lorem non vulputate. In suscipit felis et nulla sollicitudin, a ullamcorper enim venenatis. Maecenas sed quam nec turpis gravida egestas et vitae elit. Aenean nisi ex, dapibus et dictum sed, feugiat vel nisi. Mauris a eleifend massa. Nulla facilisi. Duis a erat at arcu pellentesque elementum. Praesent eu metus diam. Sed cursus ipsum ante, quis consequat felis posuere eu. Ut ullamcorper sapien non odio feugiat commodo. Praesent sed pretium purus, in laoreet dui. Suspendisse potenti. Duis volutpat augue et massa mollis commodo. Aliquam vehicula ultrices mattis.
              </p>
            </div>
            <div className="col-md-3">
              <p>Donec faucibus tellus non massa tempor, euismod euismod massa congue. Ut dictum tincidunt erat, vulputate mollis sapien euismod quis. Duis ut risus lacus. Proin sit amet elit a enim sodales posuere vitae sit amet nibh. Suspendisse vitae consectetur nisi. Quisque fringilla diam eros, in ultrices arcu convallis venenatis. Sed tristique sed tellus at sollicitudin. Vestibulum faucibus neque diam. Maecenas sagittis ante in pharetra dictum. Proin pellentesque ultrices magna ac consequat. Lorem ipsum dolor sit amet, consectetur adipiscing elit. Suspendisse sagittis rutrum nibh, a aliquet sapien consequat ut. Sed vel pharetra neque. Mauris porta bibendum aliquam.
              </p>
            </div>
          </div>
        </ExpandableNavPage>
      </ExpandableNavContainer>
    );
  }
});

module.exports = App;
