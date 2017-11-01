var AddFlair = {
    entityUpdate: function(entityData,flairToolbarToggle,type,linkWarningToggle,id,scrollTo) {
        setTimeout(function() {
            let entityResult = {}; 
            for ( let key in entityData ) {
                entityResult[$('<span />', {html : key}).html()] = entityData[key];
            }

            if (type != 'alertgroup') {
                $('iframe').each(function(index,ifr) {
                    //requestAnimationFrame waits for the frame to be rendered (allowing the iframe to fully render before excuting the next bit of code!!!
                    ifr.contentWindow.requestAnimationFrame( function() {
                        if(ifr.contentDocument != null) {
                            var ifrContents = $(ifr).contents();
                            //This makes all href point to blank so they don't reload the iframe
                            $(ifr.contentDocument.body).find('a').attr('target','_blank');
                            //Copies href to a new attribute, url, before we make href an anchor (so it doesn't go anywhere when clicked)
                            ifrContents.find('a').each(function(index,a) {
                                var url = $(a).attr('href');
                                $(a).attr('url',url);
                            }.bind(this))
                            //Make href an anchor so it doesn't go anywhere when clicked and instead opens up the modal in linkWarningPopup
                            //$(ifr.contentDocument.body).find('a').find('.entity').wrap("<a href='about:blank' target='targ'></a>");
                            ifrContents.find('.entity').each(function(index,entity){
                                if ($(entity).find('.extras')[0] == null) {
                                    //var currentEntityValue = $(entity).attr('data-entity-value');
                                    var currentEntityValue = $('<span />', {html : $(entity).attr('data-entity-value')}).html();
                                    if (currentEntityValue != undefined && entityResult != undefined) {
                                        
                                        let entityMatched = entityResult;
                                        if ( entityMatched[currentEntityValue.toLowerCase()] != undefined ) {
                                            entityMatched = entityMatched[currentEntityValue.toLowerCase()];
                                        } else {
                                            entityMatched = entityMatched[currentEntityValue];
                                        }

                                        if (entityMatched != undefined ) {
                                            var entityType = entityMatched.type;
                                            var entityid = entityMatched.id;
                                            var entityCount = abbreviateNumber(parseInt(entityMatched.count),0);
                                            var entitydata = entityMatched.data;
                                            var entityEntryCount = entityMatched.entry;
                                            var entitystatus = entityMatched.status;
                                            var circle = $('<span class="noselect">');
                                            circle.addClass('circleNumber');
                                            circle.addClass('extras');
                                            circle.text(entityCount);
                                            $(entity).append(circle);
                                            $(entity).attr('data-entity-id',entityid)
                                            $(entity).unbind('click');
                                            if (entitydata != undefined) {
                                                if (entitydata.geoip != undefined) {
                                                    if (entitydata.geoip.data.isocode != undefined) {
                                                        var country_code;
                                                        if (entitydata.geoip.data.isp == 'Sandia National Laboratories') {
                                                            country_code = 'sandia';    
                                                        } else {
                                                            country_code = entitydata.geoip.data.isocode;
                                                        }
                                                        var flag = $('<img title="'+country_code.toLowerCase()+'">').attr('src', '/images/flags/' + country_code.toLowerCase() + '.png');
                                                        flag.addClass('extras');
                                                        $(entity).append(flag);
                                                    }
                                                }
                                                if (entitydata.sidd != undefined) {
                                                    if (entitydata.sidd.data.blocklist != undefined) {
                                                        if (entitydata.sidd.data.blocklist.action != undefined) {
                                                            if (entitydata.sidd.data.blocklist.action.firewall != false) {
                                                                $(entity).append($('<img class="extras" title="firewall block">').attr('src', '/images/flair/firewalled.png'));    
                                                            }
                                                            if (entitydata.sidd.data.blocklist.action.watch != false) {
                                                                $(entity).append($('<img class="extras" title="watch list">').attr('src', '/images/flair/watch.png'));
                                                            }
                                                            if (entitydata.sidd.data.blocklist.action.whitelist != false) {
                                                                $(entity).append($('<img class="extras" title="white list">').attr('src', '/images/flair/white_list.jpg'));
                                                            }
                                                            if (entitydata.sidd.data.blocklist.action.blackhole != false) {
                                                                $(entity).append($('<img class="extras" title="dns black hole">').attr('src', '/images/flair/blackholed.png'));;
                                                            }
                                                            if (entitydata.sidd.data.blocklist.action.proxy_block != false) {
                                                                $(entity).append($('<img class="extras" title="proxy block">').attr('src', '/images/flair/blocked.png'));
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                            /*if (entitystatus == 'untracked') {
                                                $(entity).append($('<img class="extras" title="untracked entity">').attr('src', '/images/flair/notrack64.jpeg'));
                                            }*/
                                            if (entityEntryCount != undefined) {
                                                if (entityEntryCount != 0) {
                                                    var entityEntry = entityMatched.entries[0].body_plain
                                                    $(entity).append($('<img class="extras" title="'+ entityEntry +'">').attr('src', '/images/flair/note.gif'));
                                                }
                                            }
                                        }
                                    }
                                }
                            }.bind(this));
                            //}
                        //pentry(ifr,flairToolbarToggle,type,linkWarningToggle,id);
                        }
                    }.bind(this));
                }.bind(this));
            } else if (type == 'alertgroup') {
                $(document.body).find('.alertTableHorizontal').find('.entity').each(function(index,entity){
                    if ($(entity).find('.extras')[0] == null) {
                        var subtable = $(document.body).find('.alertTableHorizontal');
                        subtable.find('a').attr('target','_blank');
                        subtable.find('a').find('.entity').wrap("<a href='about:blank' target='targ'></a>");
                        //Copies href to a new attribute, url, before we make href an anchor (so it doesn't go anywhere when clicked)
                        subtable.find('a').each(function(index,a) {
                            var url = $(a).attr('href');
                            $(a).attr('url',url);
                        }.bind(this)) 
                        //var currentEntityValue = $(entity).attr('data-entity-value');
                        var currentEntityValue = $('<span />', {html : $(entity).attr('data-entity-value')}).html();
                        if (currentEntityValue != undefined && entityResult != undefined) {
                            
                            let entityMatched = entityResult;
                            if ( entityMatched[currentEntityValue.toLowerCase()] != undefined ) {
                                entityMatched = entityMatched[currentEntityValue.toLowerCase()];
                            } else {
                                entityMatched = entityMatched[currentEntityValue];
                            }

                            if (entityMatched != undefined ) {
                                var entityType = entityMatched.type;
                                var entityid = entityMatched.id;
                                var entityCount = abbreviateNumber(entityMatched.count);
                                var entitydata = entityMatched.data;
                                var entityEntryCount = entityMatched.entry;
                                var entitystatus = entityMatched.status;
                                var circle = $('<span class="noselect">');
                                circle.addClass('circleNumber');
                                circle.addClass('extras');
                                circle.text(entityCount);
                                $(entity).append(circle);
                                $(entity).attr('data-entity-id',entityid)
                                $(entity).unbind('click');
                                if (entitydata != undefined) {
                                    if (entitydata.geoip != undefined) {
                                        if (entitydata.geoip.data.isocode != undefined) {
                                            var country_code;
                                            if (entitydata.geoip.data.isp == 'Sandia National Laboratories') {
                                                country_code = 'sandia';    
                                            } else {
                                                country_code = entitydata.geoip.data.isocode;
                                            }
                                            var flag = $('<img title="'+country_code.toLowerCase()+'">').attr('src', '/images/flags/' + country_code.toLowerCase() + '.png');
                                            flag.addClass('extras');
                                            $(entity).append(flag);
                                        }
                                    }
                                    if (entitydata.sidd != undefined) {
                                        if (entitydata.sidd.data.blocklist != undefined) {
                                            if (entitydata.sidd.data.blocklist.action != undefined) {
                                                if (entitydata.sidd.data.blocklist.action.firewall != false) {
                                                    $(entity).append($('<img class="extras" title="firewall block">').attr('src', '/images/flair/firewalled.png'));    
                                                }
                                                if (entitydata.sidd.data.blocklist.action.watch != false) {
                                                    $(entity).append($('<img class="extras" title="watch list">').attr('src', '/images/flair/watch.png'));
                                                }
                                                if (entitydata.sidd.data.blocklist.action.whitelist != false) {
                                                    $(entity).append($('<img class="extras" title="white list">').attr('src', '/images/flair/white_list.jpg'));
                                                }
                                                if (entitydata.sidd.data.blocklist.action.blackhole != false) {
                                                    $(entity).append($('<img class="extras" title="dns black hole">').attr('src', '/images/flair/blackholed.png'));
                                                }
                                                if (entitydata.sidd.data.blocklist.action.proxy_block != false) {
                                                    $(entity).append($('<img class="extras" title="proxy block">').attr('src', '/images/flair/blocked.png'));
                                                }
                                            }
                                        }
                                    }           
                                }
                                /*if (entitystatus == 'untracked') {
                                    $(entity).append($('<img class="extras" title="untracked entity">').attr('src', '/images/flair/notrack64.jpeg'));
                                }*/
                                if (entityEntryCount != undefined) {
                                    if (entityEntryCount != 0) {
                                        var entityEntry = entityMatched.entries[0].body_plain
                                        $(entity).append($('<img class="extras" title="'+ entityEntry +'">').attr('src', '/images/flair/note.gif'));
                                    }
                                }
                            }
                        }
                    }
                }.bind(this));
            }
            if (scrollTo != undefined) {
                scrollTo();
            }
        }.bind(this),1000);
    },
}

/* Placed in selectedHeader and selectedEntry accordingly
var Watcher = {  
    pentry: function(ifr,flairToolbarToggle,type,linkWarningToggle,id) {
        if(type != 'alertgroup') {  
            $('iframe').each(function(index,ifr) {
                //requestAnimationFrame waits for the frame to be rendered (allowing the iframe to fully render before excuting the next bit of code!!!
                ifr.contentWindow.requestAnimationFrame( function() {
                    if(ifr.contentDocument != null) {
                        $(ifr).hover( function() {
                            var intervalID = setInterval(checkFlairHover, 50, ifr, flairToolbarToggle,type,linkWarningToggle);
                            $(ifr).data('intervalID', intervalID);
                            console.log('Now watching iframe ' + intervalID);
                        }, function() {
                            var intervalID = $(ifr).data('intervalID');
                            window.clearInterval(intervalID);
                            console.log('No longer watching iframe ' + intervalID);
                        }).bind(this);
                    }
                }.bind(this))
            }.bind(this))
        } else {
            $('.alert-wrapper').find('a, .entity').not('.not_selectable').each(function(index,tr) {
                $(tr).hover( function() {
                    var intervalID = setInterval(checkFlairHover, 50, null, flairToolbarToggle,type,linkWarningToggle,id);
                    $(tr).data('intervalID', intervalID);
                    console.log('Now watching item ' + intervalID);
                }, function() {
                    var intervalID = $(tr).data('intervalID');
                    window.clearInterval(intervalID);
                    console.log('No longer watching item ' + intervalID);
                }).bind(this);
            }).bind(this)
        }
    }
}

function checkFlairHover(iframe,flairToolbarToggle,type,linkWarningToggle,id) {
    if(type != 'alertgroup') {
        if(iframe.contentDocument != null) {
            $(iframe).contents().find('.entity').each(function(index, entity) {
                if($(entity).css('background-color') == 'rgb(255, 0, 0)') {
                    $(entity).data('state', 'down');
                } else if ($(entity).data('state') == 'down') {
                    $(entity).data('state', 'up');
                    var entityid = $(entity).attr('data-entity-id');
                    var entityvalue = $(entity).attr('data-entity-value');
                    infopop(entityid, entityvalue, flairToolbarToggle);
                }
            }.bind(this));
        }
        if(iframe.contentDocument != null) {
            $(iframe).contents().find('a').each(function(index,a) {
                if($(a).css('color') == 'rgb(255, 0, 0)') {
                    $(a).data('state','down');
                } else if ($(a).data('state') == 'down') {
                    $(a).data('state','up');
                    var url = $(a).attr('url');
                    linkWarningPopup(url,linkWarningToggle);
                }
            }.bind(this));
        }
    } else if (type == 'alertgroup') {
        var subtable = $(document.body).find('.alertTableHorizontal');
        subtable.find('.entity').each(function(index, entity) {
            if($(entity).css('background-color') == 'rgb(255, 0, 0)') {
                $(entity).data('state', 'down');
            } else if ($(entity).data('state') == 'down') {
                $(entity).data('state', 'up');
                var entityid = $(entity).attr('data-entity-id');
                var entityvalue = $(entity).attr('data-entity-value');
                infopop(entityid, entityvalue, flairToolbarToggle);
            }
        }.bind(this));
        subtable.find('a').each(function(index,a) {
            if($(a).css('color') == 'rgb(255, 0, 0)') {
                $(a).data('state','down');
            } else if ($(a).data('state') == 'down') {
                $(a).data('state','up');
                var url = $(a).attr('url');
                linkWarningPopup(url,linkWarningToggle);
            }
        }.bind(this));
    }
}
        
function infopop(entityid, entityvalue, flairToolbarToggle) {
    flairToolbarToggle(entityid,entityvalue,'entity');
}
function linkWarningPopup(url,linkWarningToggle) {
    linkWarningToggle(url);
}*/
function abbreviateNumber(num, fixed) {
    if (num === null) { return null; } // terminate early
    if (num === 0) { return '0'; } // terminate early
    fixed = (!fixed || fixed < 0) ? 0 : fixed; // number of decimal places to show
    var b = (num).toPrecision(2).split("e"), // get power
        k = b.length === 1 ? 0 : Math.floor(Math.min(b[1].slice(1), 14) / 3), // floor at decimals, ceiling at trillions
        c = k < 1 ? num.toFixed(0 + fixed) : (num / Math.pow(10, k * 3) ).toFixed(1 + fixed), // divide by power
        d = c < 0 ? c : Math.abs(c), // enforce -0 is 0
        e = d + ['', 'K', 'M', 'B', 'T'][k]; // append power
    return e;
}

//module.exports = {AddFlair, Watcher}
module.exports = {AddFlair}
