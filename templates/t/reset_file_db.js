db.files.drop();
db.files.ensureIndex({"file_id": 1});
db.idgenerators.update({"collection": "files"},{'$set': {"lastid": 0}});
