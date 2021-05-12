
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

// print ("Creating indexes...");
// db.alertgroup.ensureIndex(  { "id":          1}, {unique: true, dropDups:true} );
// db.alertgroup.ensureIndex(  { "message_id":  1} );
// db.alertgroup.ensureIndex(  { "updated":     1} );
// db.alertgroup.ensureIndex(  { "created":     1} );
// db.alertgroup.ensureIndex(  { "subject":     1} );
// 
// db.alert.ensureIndex(       { "id":         1}, {unique: true, dropDups:true}  );
// db.alert.ensureIndex(       { "alertgroup": 1}  );
// db.alert.ensureIndex(       { "updated":    1}  );
// db.alert.ensureIndex(       { "created":    1}  );
// db.alert.ensureIndex(       { "when":       1}  );
// db.alert.ensureIndex(       { "status":     1}  );
// 
// db.audit.ensureIndex(       { "id":         1}, {unique: true, dropDups:true}  );
// db.audit.ensureIndex(       { "when":       1}  );
// 
// db.checklist.ensureIndex(   { "id":         1}, {unique: true, dropDups:true}  );
// 
// db.dispatch.ensureIndex (   { "id":         1}, {unique: true, dropDups:true}  );
// db.dispatch.ensureIndex(    { "when":       1}  );
// db.dispatch.ensureIndex(    { "subject":    1}  );
// db.dispatch.ensureIndex(    { "source_uri": 1}  );
// 
// db.event.ensureIndex(       { "id":         1}, {unique: true, dropDups:true}  );
// db.event.ensureIndex(       { "when":       1}  );
// db.event.ensureIndex(       { "subject":    1}  );
// 
// db.entity.ensureIndex(      { "id":         1}, {unique: true, dropDups:true}  );
// db.entity.ensureIndex(      { "value":      1}  );
// 
// db.entry.ensureIndex(       { "id":         1}, { unique: true, dropDups:true});
// db.entry.ensureIndex(       { "parent":     1}  );
// db.entry.ensureIndex(       { "is_task":    1}  );
// db.entry.ensureIndex(       { "when":       1}  );
// db.entry.ensureIndex(       { "owner":      1}  );
// db.entry.ensureIndex(       { "target":     1}  );
// db.entry.ensureIndex(       { "target.id":     1, "target.type": 1}  );
// 
// db.file.ensureIndex(        { "id":         1}, {unique: true, dropDups:true}  );
// db.file.ensureIndex(        { "filename":   1}  );
// db.file.ensureIndex(        { "entry":      1}  );
// db.file.ensureIndex(        { "md5":        1}  );
// db.file.ensureIndex(        { "sha1":       1}  );
// db.file.ensureIndex(        { "sha256":     1}  );
// 
// db.history.ensureIndex(     { "id":         1}, {unique: true, dropDups:true}  );
// db.history.ensureIndex(     { "when":       1}  );
// db.history.ensureIndex(     { "who":        1}  );
// db.history.ensureIndex(     { "target.id":        1, "target.type": 1}  );
// db.history.ensureIndex(     { "what":       1, 'target.type':1, "when":1});
// 
// db.incident.ensureIndex(    {"id":          1}, {unique: true, dropDups:true}  );
// db.incident.ensureIndex(    {"when":        1}  );
// db.incident.ensureIndex(    {"subject":     1}  );
// 
// db.intel.ensureIndex(       { "id":         1}, {unique: true, dropDups:true}  );
// db.intel.ensureIndex(       { "when":       1}  );
// db.intel.ensureIndex(       { "subject":    1}  );
// 
// db.product.ensureIndex (   { "id":         1}, {unique: true, dropDups:true}  );
// db.product.ensureIndex(    { "when":       1}  );
// db.product.ensureIndex(    { "subject":    1}  );
// 
// db.source.ensureIndex(      { "id":         1}, {unique: true, dropDups:true}  );
// db.source.ensureIndex(      { "value":      1}  );
// 
// db.tag.ensureIndex(         { "id":         1}, {unique: true, dropDups:true}  );
// db.tag.ensureIndex(         { "value":      1}  );
// 
// db.link.ensureIndex(        { "id":         1}, {unique: true, dropDups:true}  );
// db.link.ensureIndex(        { "value":      1 } );
// db.link.ensureIndex(        { "entity_id":  1 } );
// db.link.ensureIndex(        { "vertices":  1 } );
// db.link.ensureIndex(        { "vertices.type": 1, "vertices.id": 1} );
// db.link.ensureIndex(        { "when":       1 } );
// 
// db.appearance.ensureIndex(  { "id":      1}, {unique: true, dropDups:true} );
// db.appearance.ensureIndex(  { "when":    1} );
// db.appearance.ensureIndex(  { "type":    1} );
// db.appearance.ensureIndex(  { "value":   1} );
// db.appearance.ensureIndex(  { "target":  1} );
// 
// db.guide.ensureIndex    (   { "id":         1}, {unique: true, dropDups:true});
// db.guide.ensureIndex    (   { "applies_to": 1} );
// 
// db.user.ensureIndex ( {"id": 1},{unique: true, dropDups:true} );
// db.user.ensureIndex ( {"username": 1} );
// 
// db.getCollection('group').ensureIndex({"name": 1},{unique: true, dropDups:true});
// 
// db.remoteflair.ensureIndex({"id": 1}, {unique: true, dropDups:true});
print ("Zero-ing the nexid collection...");
db.nextid.drop();
db.nextid.insert({"for_collection": "alertgroup","last_id": 0});
db.nextid.insert({"for_collection": "alert",    "last_id": 0});
db.nextid.insert({"for_collection": "checklist","last_id": 0});
db.nextid.insert({"for_collection": "config",   "last_id": 0});
db.nextid.insert({"for_collection": "dispatch",   "last_id": 0});
db.nextid.insert({"for_collection": "entity",   "last_id": 0});
db.nextid.insert({"for_collection": "entry",    "last_id": 0});
db.nextid.insert({"for_collection": "event",    "last_id": 0});
db.nextid.insert({"for_collection": "feed",     "last_id": 0});
db.nextid.insert({"for_collection": "file",     "last_id": 0});
db.nextid.insert({"for_collection": "guide",    "last_id": 0});
db.nextid.insert({"for_collection": "history",  "last_id": 0});
db.nextid.insert({"for_collection": "incident", "last_id": 0});
db.nextid.insert({"for_collection": "intel",    "last_id": 0});
db.nextid.insert({"for_collection": "intel",    "last_id": 0});
db.nextid.insert({"for_collection": "product",   "last_id": 0});
db.nextid.insert({"for_collection": "source",   "last_id": 0});
db.nextid.insert({"for_collection": "tag",      "last_id": 0});
db.nextid.insert({"for_collection": "user",     "last_id": 2});
db.nextid.insert({"for_collection": "link",     "last_id": 0});
db.nextid.insert({"for_collection": "appearance", "last_id": 0});
db.nextid.insert({"for_collection": "entitytype", "last_id": 0});
db.nextid.insert({"for_collection": "remoteflair", "last_id": 0});

