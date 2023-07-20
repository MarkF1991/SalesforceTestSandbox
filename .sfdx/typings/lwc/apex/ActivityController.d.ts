declare module "@salesforce/apex/ActivityController.getTaskList" {
  export default function getTaskList(param: {whatId: any, isOpenOnly: any}): Promise<any>;
}
declare module "@salesforce/apex/ActivityController.createTaskRecord" {
  export default function createTaskRecord(param: {fieldsMap: any}): Promise<any>;
}
declare module "@salesforce/apex/ActivityController.getEventList" {
  export default function getEventList(param: {whatId: any, isOpenOnly: any}): Promise<any>;
}
declare module "@salesforce/apex/ActivityController.upsertEventRecord" {
  export default function upsertEventRecord(param: {fieldsMap: any}): Promise<any>;
}
