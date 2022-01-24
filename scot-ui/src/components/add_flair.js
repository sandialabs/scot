import $ from "jquery";
// import ResizeAlertTable from '../detail/resize.js';
//import { getTextWidth, getCssStyle, getMaxColumnWidths, resizeColumns } from '../detail/resize3';

export const AddFlair = {
  entityUpdate: function (
    entityData,
    flairToolbarToggle,
    type,
    linkWarningToggle,
    id,
    scrollTo
  ) {
    setTimeout(
      function () {
        let entityResult = {};
        console.log("Received Entity Data!");
        console.log(entityData);
        for (let key in entityData) {
          entityResult[$("<span />", { html: key }).html()] = entityData[key];
        }

        if (type !== "alertgroup") {
          $("iframe").each(
            function (index, ifr) {
              //requestAnimationFrame waits for the frame to be rendered (allowing the iframe to fully render before excuting the next bit of code!!!
              ifr.contentWindow.requestAnimationFrame(function () {
                if (ifr.contentDocument != null) {
                  let ifrContents = $(ifr).contents();
                  //This makes all href point to blank so they don't reload the iframe
                  $(ifr.contentDocument.body)
                    .find("a")
                    .attr("target", "_blank");
                  //Copies href to a new attribute, url, before we make href an anchor (so it doesn't go anywhere when clicked)
                  ifrContents.find("a").each(function (index, a) {
                    let url = $(a).attr("href");
                    $(a).attr("url", url);
                  });
                  //Make href an anchor so it doesn't go anywhere when clicked and instead opens up the modal in linkWarningPopup
                  //$(ifr.contentDocument.body).find('a').find('.entity').wrap("<a href='about:blank' target='targ'></a>");
                  ifrContents.find(".entity").each(function (index, entity) {
                    if ($(entity).find(".extras")[0] == null) {
                      //var currentEntityValue = $(entity).attr('data-entity-value');
                      let currentEntityValue = $("<span />", {
                        html: $(entity).attr("data-entity-value"),
                      }).html();
                      if (
                        currentEntityValue !== undefined &&
                        entityResult !== undefined
                      ) {
                        let entityMatched = entityResult;
                        if (
                          entityMatched[currentEntityValue.toLowerCase()] !==
                          undefined
                        ) {
                          entityMatched =
                            entityMatched[currentEntityValue.toLowerCase()];
                        } else {
                          entityMatched = entityMatched[currentEntityValue];
                        }

                        if (entityMatched !== undefined) {
                          console.log("entity matched!");
                          let entityid = entityMatched.id;
                          let entityCount = abbreviateNumber(
                            parseInt(entityMatched.count, 10),
                            0
                          );
                          let entitydata = entityMatched.data;
                          console.log("entitydata for "+ entityMatched.id);
                          console.log(entitydata);
                          let entityEntryCount = entityMatched.entry;
                          let circle = $('<span class="noselect">');
                          circle.addClass("circleNumber");
                          circle.addClass("extras");
                          circle.text(entityCount);
                          $(entity).append(circle);
                          $(entity).attr("data-entity-id", entityid);
                          $(entity).unbind("click");
                          if (entitydata !== undefined) {
                            if (entitydata.scanner !== undefined) {
                              if (entitydata.scanner.active === "true") {
                                $(entity).append(
                                  $(
                                    '<img class="extras" title="scanner">'
                                  ).attr("src", "/images/flair/scanner.png")
                                );
                              }
                            }

                            if (entitydata.geoip !== undefined) {
                              if (entitydata.geoip.data !== undefined) {
                                if (entitydata.geoip.data.isocode) {
                                    let country_code;
                                    if (
                                    entitydata.geoip.data.isp ===
                                    "Sandia National Laboratories"
                                    ) {
                                    country_code = "sandia";
                                    } else {
                                    country_code = entitydata.geoip.data.isocode;
                                    }
                                    if (country_code !== null) {
                                    let flag = $(
                                        '<img title="' +
                                        country_code.toLowerCase() +
                                        '">'
                                    ).attr(
                                        "src",
                                        "/images/flags/" +
                                        country_code.toLowerCase() +
                                        ".png"
                                    );
                                    flag.addClass("extras");
                                    $(entity).append(flag);
                                    }
                                }
                                if (entitydata.geoip.data.is_anonymous) {
                                    let anonicon = $(
                                        '<img title="is_anonymous">'
                                    ).attr(
                                        'src',
                                        '/images/flair/anon.png'
                                    );
                                    anonicon.addClass("extras");
                                    $(entity).append(anonicon);
                                }
                                if (entitydata.geoip.data.is_anonymous_vpn) {
                                    let icon = $(
                                        '<img title="is_anonymous_vpn">'
                                    ).attr(
                                        'src',
                                        '/images/flair/anonvpn.png'
                                    );
                                    icon.addClass("extras");
                                    $(entity).append(icon);
                                }
                                if (entitydata.geoip.data.is_hosting_provider) {
                                    let icon = $(
                                        '<img title="is_hosting_provider">'
                                    ).attr(
                                        'src',
                                        '/images/flair/hosting.png'
                                    );
                                    icon.addClass("extras");
                                    $(entity).append(icon);
                                }
                                if (entitydata.geoip.data.is_public_proxy) {
                                    let icon = $(
                                        '<img title="is_public_proxy">'
                                    ).attr(
                                        'src',
                                        '/images/flair/proxy.png'
                                    );
                                    icon.addClass("extras");
                                    $(entity).append(icon);
                                }
                                if (entitydata.geoip.data.is_tor_exit_node) {
                                    let icon = $(
                                        '<img title="is_tor_exit_node">'
                                    ).attr(
                                        'src',
                                        '/images/flair/tor.png'
                                    );
                                    icon.addClass("extras");
                                    $(entity).append(icon);
                                }
                                if (entitydata.geoip.data.is_residential_proxy) {
                                    let icon = $(
                                        '<img title="is_residential_proxy">'
                                    ).attr(
                                        'src',
                                        '/images/flair/residence.png'
                                    );
                                    icon.addClass("extras");
                                    $(entity).append(icon);
                                }


                              }
                            }

                            if (entitydata.sidd !== undefined) {
                              if (
                                Object.keys(entitydata.sidd.data).length !==
                                  0 &&
                                entitydata.sidd.data.constructor === Object
                              ) {
                                $(entity).append(
                                  $('<img class="extras" title="sidd">').attr(
                                    "src",
                                    "/images/flair/sidd.png"
                                  )
                                );
                              }
                            }

                            // display flair icons based on blocklist
                            if ( entitydata.blocklist3 !== undefined) {
                                if ( entitydata.blocklist3.data.firewall !== 0 ) {
                                $(entity).append(
                                    $(
                                    '<img class="extras" title="firewall block">'
                                    ).attr(
                                    "src",
                                    "/images/flair/firewalled.png"
                                    )
                                );
                                }
                                if ( entitydata.blocklist3.data.watch !==0 ) {
                                $(entity).append(
                                    $(
                                    '<img class="extras" title="watch list">'
                                    ).attr("src", "/images/flair/watch.png")
                                );
                                }
                                if ( entitydata.blocklist3.data.whitelist !== 0 ) {
                                $(entity).append(
                                    $(
                                    '<img class="extras" title="white list">'
                                    ).attr(
                                    "src",
                                    "/images/flair/white_list.jpg"
                                    )
                                );
                                }
                                if ( entitydata.blocklist3.data.blackhole !== 0 ) {
                                $(entity).append(
                                    $(
                                    '<img class="extras" title="dns black hole">'
                                    ).attr(
                                    "src",
                                    "/images/flair/blackholed.png"
                                    )
                                );
                                }
                                if ( entitydata.blocklist3.data.proxy_block !== 0 ) {
                                console.log("proxy block detected!");
                                $(entity).append(
                                    $(
                                    '<img class="extras" title="proxy block">'
                                    ).attr("src", "/images/flair/blocked.png")
                                );
                                }
                                else {
                                console.log("proxy where art thou"+ entitydata.blocklist3.data);
                                }
                            }
                          }

                          if (entityEntryCount !== undefined) {
                            if (entityEntryCount !== 0) {
                              let entityEntry =
                                entityMatched.entries[0].body_plain;
                              $(entity).append(
                                $(
                                  '<img class="extras" title="' +
                                    entityEntry +
                                    '">'
                                ).attr("src", "/images/flair/note.png")
                              );
                            }
                          }
                        }
                      }
                    }
                  });
                  //}
                  //pentry(ifr,flairToolbarToggle,type,linkWarningToggle,id);
                }
              });
            }.bind(this)
          );
        } else if (type === "alertgroup") {
          //console.log("FOOBAR!!!!!");
          $(document.body)
            .find(".alertTableHorizontal")
            .find(".entity")
            .each(function (index, entity) {
              if ($(entity).find(".extras")[0] == null) {
                let subtable = $(document.body).find(".alertTableHorizontal");
                subtable.find("a").attr("target", "_blank");
                subtable
                  .find("a")
                  .find(".entity")
                  .wrap("<a href='about:blank' target='targ'></a>");
                //Copies href to a new attribute, url, before we make href an anchor (so it doesn't go anywhere when clicked)
                subtable.find("a").each(function (index, a) {
                  let url = $(a).attr("href");
                  $(a).attr("url", url);
                });
                //var currentEntityValue = $(entity).attr('data-entity-value');
                let currentEntityValue = $("<span />", {
                  html: $(entity).attr("data-entity-value"),
                }).html();
                if (
                  currentEntityValue !== undefined &&
                  entityResult !== undefined
                ) {
                  let entityMatched = entityResult;
                  if (
                    entityMatched[currentEntityValue.toLowerCase()] !==
                    undefined
                  ) {
                    entityMatched =
                      entityMatched[currentEntityValue.toLowerCase()];
                  } else {
                    entityMatched = entityMatched[currentEntityValue];
                  }

                  if (entityMatched !== undefined) {
                    let entityid = entityMatched.id;
                    let entityCount = abbreviateNumber(entityMatched.count);
                    let entitydata = entityMatched.data;
                    console.log("entitydata for "+ entityMatched.id);
                    console.log(entitydata);
                    let entityEntryCount = entityMatched.entry;
                    let circle = $('<span class="noselect">');
                    circle.addClass("circleNumber");
                    circle.addClass("extras");
                    circle.text(entityCount);
                    $(entity).append(circle);
                    $(entity).attr("data-entity-id", entityid);
                    $(entity).unbind("click");
                    if (entitydata !== undefined) {
                      if (entitydata.scanner !== undefined) {
                        if (entitydata.scanner.active === "true") {
                           $(entity).append(
                             $(
                               '<img class="extras" title="scanner">'
                             ).attr("src", "/images/flair/scanner.png")
                           );
                        }
                      }

                      if (entitydata.sidd !== undefined) {
                         if (
                            Object.keys(entitydata.sidd.data).length !==
                              0 &&
                            entitydata.sidd.data.constructor === Object
                          ) {
                            $(entity).append(
                              $('<img class="extras" title="sidd">').attr(
                                "src",
                                "/images/flair/sidd.png"
                              )
                            );
                         }
                      }
                      if (entitydata.geoip !== undefined) {
                        if (entitydata.geoip.data.isocode) {
                          let country_code;
                          if (
                            entitydata.geoip.data.isp ===
                            "Sandia National Laboratories"
                          ) {
                            country_code = "sandia";
                          } else {
                            country_code = entitydata.geoip.data.isocode;
                          }
                          let flag = $(
                            '<img title="' + country_code.toLowerCase() + '">'
                          ).attr(
                            "src",
                            "/images/flags/" +
                              country_code.toLowerCase() +
                              ".png"
                          );
                          flag.addClass("extras");
                          $(entity).append(flag);
                        }
                        if (entitydata.geoip.data.is_anonymous) {
                            let anonicon = $(
                                '<img title="is_anonymous">'
                            ).attr(
                                'src',
                                '/images/flair/anon.png'
                            );
                            anonicon.addClass("extras");
                            $(entity).append(anonicon);
                        }
                        if (entitydata.geoip.data.is_anonymous_vpn) {
                            let icon = $(
                                '<img title="is_anonymous_vpn">'
                            ).attr(
                                'src',
                                '/images/flair/anonvpn.png'
                            );
                            icon.addClass("extras");
                            $(entity).append(icon);
                        }
                        if (entitydata.geoip.data.is_hosting_provider) {
                            let icon = $(
                                '<img title="is_hosting_provider">'
                            ).attr(
                                'src',
                                '/images/flair/hosting.png'
                            );
                            icon.addClass("extras");
                            $(entity).append(icon);
                        }
                        if (entitydata.geoip.data.is_public_proxy) {
                            let icon = $(
                                '<img title="is_public_proxy">'
                            ).attr(
                                'src',
                                '/images/flair/proxy.png'
                            );
                            icon.addClass("extras");
                            $(entity).append(icon);
                        }
                        if (entitydata.geoip.data.is_tor_exit_node) {
                            let icon = $(
                                '<img title="is_tor_exit_node">'
                            ).attr(
                                'src',
                                '/images/flair/tor.png'
                            );
                            icon.addClass("extras");
                            $(entity).append(icon);
                        }
                        if (entitydata.geoip.data.is_residential_proxy) {
                            let icon = $(
                                '<img title="is_residential_proxy">'
                            ).attr(
                                'src',
                                '/images/flair/residence.png'
                            );
                            icon.addClass("extras");
                            $(entity).append(icon);
                        }
                      }
                      // now in blocklist3 
                      if ( entitydata.blocklist3 !== undefined) {
                        if ( entitydata.blocklist3.data.firewall !== 0) {
                            $(entity).append(
                            $(
                                '<img class="extras" title="firewall block">'
                            ).attr("src", "/images/flair/firewalled.png")
                            );
                        }
                        if ( entitydata.blocklist3.data.watch !== 0) {
                            $(entity).append(
                            $(
                                '<img class="extras" title="watch list">'
                            ).attr("src", "/images/flair/watch.png")
                            );
                        }
                        if ( entitydata.blocklist3.data.whitelist !== 0) {
                            $(entity).append(
                            $(
                                '<img class="extras" title="white list">'
                            ).attr("src", "/images/flair/white_list.jpg")
                            );
                        }
                        if ( entitydata.blocklist3.data.blackhole !== 0) {
                            $(entity).append(
                            $(
                                '<img class="extras" title="dns black hole">'
                            ).attr("src", "/images/flair/blackholed.png")
                            );
                        }
                        if ( entitydata.blocklist3.data.proxy_block !== 0) {
                            console.log("proxy_block detected!");
                            $(entity).append(
                            $(
                                '<img class="extras" title="proxy block">'
                            ).attr("src", "/images/flair/blocked.png")
                            );
                        }
                        else {
                            console.log("Why no pblock? "+entitydata.blocklist3.data);
                        }
                    // XXX
                      }
                    }

                    if (entityEntryCount !== undefined) {
                      if (entityEntryCount !== 0) {
                        let entityEntry = entityMatched.entries[0].body_plain;
                        $(entity).append(
                          $(
                            '<img class="extras" title="' + entityEntry + '">'
                          ).attr("src", "/images/flair/note.png")
                        );
                      }
                    }
                  }
                }
              }
            });
        }
        if (scrollTo !== undefined && scrollTo !== null) {
          scrollTo();
        }
        console.log("BOOMBAZ");
        // resizeColumns();
      }.bind(this),
      1000
    );
  },
};

function abbreviateNumber(num, fixed) {
  if (num === null) {
    return null;
  } // terminate early
  if (num === 0) {
    return "0";
  } // terminate early
  fixed = !fixed || fixed < 0 ? 0 : fixed; // number of decimal places to show
  let b = num.toPrecision(2).split("e"), // get power
    k = b.length === 1 ? 0 : Math.floor(Math.min(b[1].slice(1), 14) / 3), // floor at decimals, ceiling at trillions
    c =
      k < 1
        ? num.toFixed(0 + fixed)
        : (num / Math.pow(10, k * 3)).toFixed(1 + fixed), // divide by power
    d = c < 0 ? c : Math.abs(c), // enforce -0 is 0
    e = d + ["", "K", "M", "B", "T"][k]; // append power
  return e;
}
export default AddFlair;
//module.exports = {AddFlair, Watcher}
