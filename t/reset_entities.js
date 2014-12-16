db.entities.remove();
db.alerts.update({}, {$set : {lastextract: 0}}, {multi: true});
db.entries.update({}, {$set :{lastextract: 0}}, {multi: true});
