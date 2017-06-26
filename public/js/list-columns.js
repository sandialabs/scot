var listColumnsJSON = {};
listColumnsJSON = {
    columnsDisplay: {
        alertgroup: ['ID', 'Status', 'Subject', 'Created', 'Sources', 'Tags', 'Views'],
        alert: ['ID', 'Status', 'Subject', 'Created', 'Sources', 'Tags', 'Views'],
        event: ['ID', 'Status', 'Subject', 'Created', 'Updated', 'Sources', 'Tags', 'Owner', 'Entries', 'Views'],
        incident: ['ID', 'DOE', 'Status', 'Owner', 'Subject', 'Occurred', 'Type', 'Tags', 'Sources'],
        task: ['Type', 'ID', 'Status', 'Owner', 'Entry Id', 'Updated'],
        guide: ['ID', 'Subject', 'Applies To'],
        intel: ['ID', 'Subject', 'Created', 'Updated', 'Source', 'Tags', 'Owner', 'Entries', 'Views'],
        signature: ['ID', 'Name', 'Type', 'Status', 'Group', 'Description', 'Owner', 'Tag', 'Source', 'Updated'],
        entity: ['ID', 'Value', 'Type', 'Entries']
    },
    columns: {
        alertgroup: ['id', 'status', 'subject', 'created', 'source', 'tag', 'views'],
        alert: ['id', 'status', 'subject', 'created', 'source', 'tag', 'views'],
        event: ['id', 'status', 'subject', 'created', 'updated', 'source', 'tag', 'owner', 'entry_count', 'views'],
        incident: ['id', 'doe_report_id', 'status', 'owner', 'subject', 'occurred', 'type', 'tag', 'source'],
        task: ['target.type', 'target.id', 'metadata.status', 'owner', 'id', 'updated'],
        guide: ['id', 'subject', 'applies_to'],
        intel: ['id', 'subject', 'created', 'updated', 'source', 'tag', 'owner', 'entry_count', 'views'],
        signature: ['id', 'name', 'type', 'status', 'signature_group', 'description', 'owner', 'tag', 'source', 'updated'],
        entity: ['id', 'value', 'type', 'entry_count']
    },
    columnsClassName: {
        alertgroup: ['id', 'status', 'subject', 'created', 'source', 'tag', 'views'],
        alert: ['id', 'status', 'subject', 'created', 'source', 'tag', 'views'],
        event: ['id', 'status', 'subject', 'created', 'updated', 'source', 'tag', 'owner', 'entry_count', 'views'],
        incident: ['id', 'doe_report_id', 'status', 'owner', 'subject', 'occurred', 'type', 'tag', 'source'],
        task: ['target_type', 'target_id', 'task_status', 'owner', 'id', 'updated'],
        guide: ['id', 'subject', 'applies_to']   ,
        intel: ['id', 'subject', 'created', 'updated', 'source', 'tag', 'owner', 'entry_count', 'views'],
        signature: ['id', 'name', 'type', 'status', 'signature_group', 'description', 'owner', 'tag', 'source', 'updated'],
        entity: ['id', 'value', 'type', 'entry_count']
    }
};
