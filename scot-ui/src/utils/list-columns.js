var listColumnsJSON = {};
listColumnsJSON = {
    columnsDisplay: {
        alertgroup: ['ID', 'Status', 'Subject', 'Created', 'Sources', 'Tags', 'Views', 'Open Tasks'],
        alert: ['ID', 'Status', 'Subject', 'Created', 'Sources', 'Tags', 'Views'],
        event: ['ID', 'Status', 'Subject', 'Created', 'Updated', 'Sources', 'Tags', 'Owner', 'Entries', 'Views', 'Open Tasks'],
        incident: ['ID', 'DOE', 'Status', 'Owner', 'Subject', 'Occurred', 'Type', 'Tags', 'Sources'],
        task: [ 'Entry Id', 'Body', 'Type', 'ID', 'Status', 'Owner', 'Updated'],
        guide: ['ID', 'Subject', 'Applies To'],
        intel: ['ID', 'Subject', 'Created', 'Updated', 'Source', 'Tags', 'Owner', 'Entries', 'Views'],
        feed: ['ID', 'Status', 'Name', 'Uri', 'LastAttempt', 'LastArticle', 'Articles', 'Promotions'],
        signature: ['ID', 'Name', 'Type', 'Status', 'Group', 'Description', 'Owner', 'Tag', 'Source', 'Updated'],
        entity: ['ID', 'Value', 'Type', 'Entries']
    },
    columns: {
        alertgroup: ['id', 'status', 'subject', 'created', 'source', 'tag', 'views', 'has_tasks'],
        alert: ['id', 'status', 'subject', 'created', 'source', 'tag', 'views'],
        event: ['id', 'status', 'subject', 'created', 'updated', 'source', 'tag', 'owner', 'entry_count', 'views', 'has_tasks'],
        incident: ['id', 'doe_report_id', 'status', 'owner', 'subject', 'occurred', 'type', 'tag', 'source'],
        task: [ 'id', 'body_plain', 'target.type', 'target.id', 'metadata.status', 'owner', 'updated'],
        guide: ['id', 'subject', 'applies_to'],
        intel: ['id', 'subject', 'created', 'updated', 'source', 'tag', 'owner', 'entry_count', 'views'],
        feed: ['id', 'status', 'name', 'uri', 'last_attempt', 'last_article', 'article_count', 'promotions'],
        signature: ['id', 'name', 'type', 'status', 'signature_group', 'description', 'owner', 'tag', 'source', 'updated'],
        entity: ['id', 'value', 'type', 'entry_count']
    },
    columnsClassName: {
        alertgroup: ['id', 'status', 'subject', 'created', 'source', 'tag', 'views', 'has-tasks'],
        alert: ['id', 'status', 'subject', 'created', 'source', 'tag', 'views'],
        event: ['id', 'status', 'subject', 'created', 'updated', 'source', 'tag', 'owner', 'entry_count', 'views', 'has-tasks'],
        incident: ['id', 'doe_report_id', 'status', 'owner', 'subject', 'occurred', 'type', 'tag', 'source'],
        task: ['id', 'body_plain', 'target_type', 'target_id', 'task_status', 'owner', 'updated'],
        guide: ['id', 'subject', 'applies_to']   ,
        intel: ['id', 'subject', 'created', 'updated', 'source', 'tag', 'owner', 'entry_count', 'views'],
        feed: ['id', 'status', 'name', 'uri', 'last_attempt', 'last_article', 'article_count', 'promotions'],
        signature: ['id', 'name', 'type', 'status', 'signature_group', 'description', 'owner', 'tag', 'source', 'updated'],
        entity: ['id', 'value', 'type', 'entry_count']
    }
};
export default listColumnsJSON;
