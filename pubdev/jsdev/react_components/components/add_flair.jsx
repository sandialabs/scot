var AddFlair = {
    entityUpdate: function(entityData,flairToolbarToggle,type,linkWarningToggle) {
        setTimeout(function() {
            var entityResult = entityData;
            if (type != 'alertgroup') {
                $('iframe').each(function(index,ifr) {
                    //requestAnimationFrame waits for the frame to be rendered (allowing the iframe to fully render before excuting the next bit of code!!!
                    ifr.contentWindow.requestAnimationFrame( function() {
                        if(ifr.contentDocument != null) {
                            var ifrContents = $(ifr).contents();
                            if($(ifr.contentDocument.body).find('.extras')[0] == null) {
                                //This makes all href point to blank so they don't reload the iframe
                                $(ifr.contentDocument.body).find('a').attr('target','_blank');
                                //Copies href to a new attribute, url, before we make href an anchor (so it doesn't go anywhere when clicked)
                                ifrContents.find('a').each(function(index,a) {
                                    var url = $(a).attr('href');
                                    $(a).attr('url',url);
                                }.bind(this))
                                //Make href an anchor so it doesn't go anywhere when clicked and instead opens up the modal in linkWarningPopup
                                $(ifr.contentDocument.body).find('a').attr('href','#');
                                $(ifr.contentDocument.body).append('<iframe id="targ" style="display:none;" name="targ"></iframe>');
                                $(ifr.contentDocument.body).find('a').find('.entity').wrap("<a href='about:blank' target='targ'></a>");
                                ifrContents.find('.entity').each(function(index,entity){
                                    var currentEntityValue = $(entity).attr('data-entity-value');
                                    if (currentEntityValue !== undefined) {
                                        if (entityResult[currentEntityValue.toLowerCase()] !== undefined ) {
                                            var entityType = entityResult[currentEntityValue.toLowerCase()].type;
                                            var entityid = entityResult[currentEntityValue.toLowerCase()].id;
                                            var entityCount = entityResult[currentEntityValue.toLowerCase()].count;
                                            var entitydata = entityResult[currentEntityValue.toLowerCase()].data;
                                            var circle = $('<span class="noselect">');
                                            circle.addClass('circleNumber');
                                            circle.addClass('extras');
                                            circle.text(entityCount);
                                            $(entity).append(circle);
                                            $(entity).attr('data-entity-id',entityid)
                                            $(entity).unbind('click');
                                            if (entitydata !== undefined) {
                                                if (entitydata.geoip !== undefined) {
                                                    if (entitydata.geoip.isocode !== undefined) {
                                                        var country_code;
                                                        if (entitydata.geoip.isp == 'Sandia National Laboratories') {
                                                            country_code = 'sandia';    
                                                        } else {
                                                            country_code = entitydata.geoip.isocode;
                                                        }
                                                        var flag = $('<img class="noselect">').attr('src', '/images/flags/' + country_code.toLowerCase() + '.png');
                                                        flag.addClass('extras');
                                                        $(entity).append(flag);
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }.bind(this));
                            }
                        pentry(ifr,flairToolbarToggle,type,linkWarningToggle);
                        }
                    }.bind(this));
                }.bind(this));
            } else {
                if($(document.body).find('.extras')[0] == null) {
                    $(document.body).find('a').attr('target','_blank');
                    $(document.body).append('<iframe id="targ" style="display:none;" name="targ"></iframe>');
                    $(document.body).find('a').find('.entity').wrap("<a href='about:blank' target='targ'></a>");
                    $(document.body).find('.entity').each(function(index,entity){
                        var currentEntityValue = $(entity).attr('data-entity-value');
                        if (currentEntityValue !== undefined) {
                            if (entityResult[currentEntityValue.toLowerCase()] !== undefined ) {
                                var entityType = entityResult[currentEntityValue.toLowerCase()].type;
                                var entityid = entityResult[currentEntityValue.toLowerCase()].id;
                                var entityCount = entityResult[currentEntityValue.toLowerCase()].count;
                                var circle = $('<span class="noselect">');
                                circle.addClass('circleNumber');
                                circle.addClass('extras');
                                circle.text(entityCount);
                                $(entity).append(circle);
                                $(entity).attr('data-entity-id',entityid)
                                $(entity).unbind('click');
                                pentry(null,flairToolbarToggle,type);
                            }
                        }
                    }.bind(this));
                }
            }
        }.bind(this));
    },
}

function pentry(ifr,flairToolbarToggle,type,linkWarningToggle) {
            if(type != 'alertgroup') { 
                $(ifr).mouseenter(function() {
                    var intervalID = setInterval(checkFlairHover, 100, ifr, flairToolbarToggle,type,linkWarningToggle);
                    $(ifr).data('intervalID', intervalID);
                    console.log('Now watching iframe ' + intervalID);
                }.bind(this));
                $(ifr).mouseleave(function() {
                    var intervalID = $(this).data('intervalID');
                    window.clearInterval(intervalID);
                    console.log('No longer watching iframe ' + intervalID);
                }.bind(this));
            } else {
                setInterval(checkFlairHover, 100, null, flairToolbarToggle,type,linkWarningToggle);
            }
        }
function checkFlairHover(iframe,flairToolbarToggle,type,linkWarningToggle) {
    if(type != 'alertgroup') {
        if(iframe.contentDocument != null) {
            $(iframe).contents().find('.entity').each(function(index, entity) {
                if($(entity).css('background-color') == 'rgb(255, 0, 0)') {
                    $(entity).data('state', 'down');
                } else if ($(entity).data('state') == 'down') {
                    $(entity).data('state', 'up');
                    var entityid = $(entity).attr('data-entity-id');
                    infopop(iframe,entityid,flairToolbarToggle);
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
                    linkWarningPopup(iframe,url,linkWarningToggle);
                }
            }.bind(this));
        }
    } else {
        $(document.body).find('.entity').each(function(index, entity) {
                if($(entity).css('background-color') == 'rgb(255, 0, 0)') {
                    $(entity).data('state', 'down');
                } else if ($(entity).data('state') == 'down') {
                    $(entity).data('state', 'up');
                    var entityid = $(entity).attr('data-entity-id');
                    infopop(null,entityid,flairToolbarToggle);
                }
        }.bind(this));
        $(document.body).find('a').each(function(index,a) {
            if($(a).css('color') == 'rgb(255, 0, 0)') {
                $(a).data('state','down');
            } else if ($(a).data('state') == 'down') {
                $(a).data('state','up');
                var url = $(a).attr('url');
                linkWarningPopup(iframe,url,linkWarningToggle);
            }
        }.bind(this));
    }
}
        
function infopop(ifr,entityid,flairToolbarToggle) {
    flairToolbarToggle(entityid);
}
function linkWarningPopup(ifr,url,linkWarningToggle) {
    linkWarningToggle(url);
}

module.exports = AddFlair
