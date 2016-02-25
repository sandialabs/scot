// db.alertgroup.drop();
db.alertgroup.ensureIndex({"id": 1});
db.alertgroup.ensureIndex({"message_id":1});
db.alertgroup.ensureIndex({"updated": 1});

db.alert.drop();
db.alert.ensureIndex({"id":1});
db.alert.ensureIndex({"alertgroup":1});
db.alert.ensureIndex({"updated": 1});
db.alert.ensureIndex({"when":1});

db.audit.drop();
db.audit.ensureIndex({"id":1});
db.audit.ensureIndex({"when":1});

db.checklist.drop();
db.checklist.ensureIndex({"id": 1});

db.scotmod.drop();
db.scotmod.insert({
    "id":   1,
    "module":    "Scot::Util::Activemq",
    "attribute": "amq",
});

//db.scotmod.insert({
//    "id":   2,
//    "module":    "Scot::Util::Imap",
//    "attribute":    "imap",
//});

db.config.drop();
db.config.insert({
    "id":     1,
    "module":   "Scot::Util::Activemq",
    "item":     {
        "host": "127.0.0.1",
        "port": 61513
    }
});
db.config.insert({
    "id":   2,
    "module":   "Scot::Util::Ldap",
    "item": {
		"hostname": "sec-ldap-nm.sandia.gov",
		"dn": "cn=snlldapproxy,ou=local config,dc=gov",
		"password": "snlldapproxy",
		"scheme": "ldap",
		"group_search": {
			"base":	"ou=groups,ou=snl,dc=nnsa,dc=doe,dc=gov",
			"filter": '(| (cn=wg-vast*))',
			"attrs": ['cn']
		},
		"user_groups": {
			"base": "ou=accounts,ou=snl,dc=nnsa,dc=doe,dc=gov",
			"filter": "uid=%s",
			"attrs": ['memberOf']
		}
	}
});

db.config.insert({
    id: 3,
    module: "default_groups",
    item:   {
        read:   [ "ir", "testing" ],
        modify: [ "ir", "testing" ],
    },
});
db.config.insert({
    id: 4,
    module: "default_owner",
    item:   {
        owner: "scot-adm"
    }
});

db.deleted.drop();

db.entity.drop();
db.entity.ensureIndex({id:1});
db.entity.ensureIndex({target_id: 1, target_type: 1});

db.entry.drop();
db.entry.ensureIndex({"id": 1});
db.entry.ensureIndex({"updated" :1});
db.entry.ensureIndex({"target_id": 1, "target_type": 1});

db.event.drop();
db.event.ensureIndex({"id":1});
db.event.ensureIndex({"updated":1});

db.file.drop();
db.file.ensureIndex({"id": 1});

db.guide.drop();

db.handler.drop();

db.incident.drop();
db.incident.ensureIndex({"id":1});
db.incident.ensureIndex({"updated":1});

db.intel.drop();
db.intel.ensureIndex({"id": 1});

// db.source.drop();
db.source.ensureIndex({id: 1});

// db.tag.drop();
db.tag.ensureIndex({id: 1});
db.tag.ensureIndex({text: 1});
db.tag.ensureIndex({"target_id": 1, "target_type": 1});

db.user.drop();

// db.idgenerators.drop();
// db.idgenerators.insert({"collection": "alert", "lastid": 0});
// db.idgenerators.insert({"collection": "entry", "lastid": 0});
// db.idgenerators.insert({"collection": "event", "lastid": 0});
// db.idgenerators.insert({"collection": "incident", "lastid": 0});
// db.idgenerators.insert({"collection": "checklist", "lastid": 0});
// db.idgenerators.insert({"collection": "file", "lastid": 0});
// db.idgenerators.insert({"collection": "alertgroup", "lastid": 0});
