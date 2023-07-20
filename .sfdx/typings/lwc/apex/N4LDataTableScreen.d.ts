declare module "@salesforce/apex/N4LDataTableScreen.getRelatedFieldName" {
  export default function getRelatedFieldName(param: {recordId: any, relatedObjectApiName: any}): Promise<any>;
}
declare module "@salesforce/apex/N4LDataTableScreen.retrieveColumns" {
  export default function retrieveColumns(param: {settingName: any, objectName: any}): Promise<any>;
}
declare module "@salesforce/apex/N4LDataTableScreen.retrieveRecords" {
  export default function retrieveRecords(param: {settingName: any, objectName: any, recordId: any, relationshipField: any, isBusinessContact: any, sortQuery: any}): Promise<any>;
}
declare module "@salesforce/apex/N4LDataTableScreen.retrieveBusinessRoles" {
  export default function retrieveBusinessRoles(param: {recordId: any}): Promise<any>;
}
declare module "@salesforce/apex/N4LDataTableScreen.updateRelationship" {
  export default function updateRelationship(param: {relationId: any}): Promise<any>;
}
declare module "@salesforce/apex/N4LDataTableScreen.retrieveOutageNotif" {
  export default function retrieveOutageNotif(param: {recordId: any}): Promise<any>;
}
