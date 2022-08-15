print("Dropping collections...");
db.alert.drop();
db.alertgroup.drop();
db.audit.drop();
db.checklist.drop();
db.deleted.drop();
db.dispatch.drop();
db.entity.drop();
db.entry.drop();
db.event.drop();
db.feed.drop();
db.file.drop();
db.history.drop();
db.incident.drop();
db.intel.drop();
db.nextid.drop();
db.product.drop();
db.source.drop();
db.tag.drop();
db.user.drop();
db.user.drop();
db.link.drop();
db.guide.drop();
db.appearance.drop();
db.signature.drop();
db.sigbody.drop();
db.apikey.drop();
db.handler.drop();
db.stat.drop();
db.entitytype.drop();
db.getCollection('group').drop()
db.remoteflair.drop();
db.msv.drop();

print ("Creating indexes...");
load("./indexes.js");
print ("Zero-ing the nexid collection...");
load("./zero_nextid.js");

