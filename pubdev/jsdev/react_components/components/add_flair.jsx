        function infopop(ifr,entityid,flairToolbarToggle) {
            flairToolbarToggle(entityid);
        }
        function checkFlairHover(iframe,flairToolbarToggle) {
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
        }
        function pentry(ifr,flairToolbarToggle) {
            $(ifr).mouseenter(function() {
                var intervalID = setInterval(checkFlairHover, 100, ifr, flairToolbarToggle);
                $(ifr).data('intervalID', intervalID);
                console.log('Now watching iframe ' + intervalID);
            }.bind(this));
            $(ifr).mouseleave(function() {
                var intervalID = $(this).data('intervalID');
                window.clearInterval(intervalID);
                console.log('No longer watching iframe ' + intervalID);
            }.bind(this));
        }
    var AddFlair = {
        entityUpdate: function(entityData,flairToolbarToggle) {
            setTimeout(function() {
                var entityResult = entityData;
                $('iframe').each(function(index,ifr) {
                    //requestAnimationFrame waits for the frame to be rendered (allowing the iframe to fully render before excuting the next bit of code!!!
                    ifr.contentWindow.requestAnimationFrame( function() {
                        if(ifr.contentDocument != null) {
                            var ifrContents = $(ifr).contents();
                            if($(ifr.contentDocument.body).find('.extras')[0] == null) {
                                $(ifr.contentDocument.body).find('a').attr('target','_blank');
                                $(ifr.contentDocument.body).append('<iframe id="targ" style="display:none;" name="targ"></iframe>');
                                $(ifr.contentDocument.body).find('a').find('.entity').wrap("<a href='about:blank' target='targ'></a>");
                                ifrContents.find('.entity').each(function(index,entity){
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
                                            pentry(ifr,flairToolbarToggle);
                                        }
                                    }
                                }.bind(this));
                            }
                        }
                    }.bind(this));
                }.bind(this));
            }.bind(this));
        },
    }


module.exports = AddFlair
