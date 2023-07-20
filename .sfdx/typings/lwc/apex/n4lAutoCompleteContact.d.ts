declare module "@salesforce/apex/n4lAutoCompleteContact.getResults" {
  export default function getResults(param: {ObjectName: any, fieldName: any, value: any, accountId: any}): Promise<any>;
}
declare module "@salesforce/apex/n4lAutoCompleteContact.getResultFromExistingSchool" {
  export default function getResultFromExistingSchool(param: {value: any, accountId: any}): Promise<any>;
}
declare module "@salesforce/apex/n4lAutoCompleteContact.addNewContact" {
  export default function addNewContact(param: {newEmail: any, firstName: any, lastName: any, jobTitle: any, mobilePhone: any, accountId: any, recordId: any, isReplace: any, replaceValue: any, isInherit: any}): Promise<any>;
}
declare module "@salesforce/apex/n4lAutoCompleteContact.saveRelationship" {
  export default function saveRelationship(param: {recordId: any, accountId: any, contactId: any, isActive: any, canProvideSiteAccess: any, roles: any, authorities: any, createSupportHubUser: any, currentRecordId: any, isReplace: any, replaceValue: any, isChangeOldEmail: any, isInherit: any, systemAccessible: any}): Promise<any>;
}
declare module "@salesforce/apex/n4lAutoCompleteContact.checkShowAddNewContact" {
  export default function checkShowAddNewContact(param: {accountId: any}): Promise<any>;
}
declare module "@salesforce/apex/n4lAutoCompleteContact.validateContactFieldEdits" {
  export default function validateContactFieldEdits(param: {recordId: any, accountId: any}): Promise<any>;
}
declare module "@salesforce/apex/n4lAutoCompleteContact.checkEmailDuplicates" {
  export default function checkEmailDuplicates(param: {email: any, recordId: any, emailEditable: any}): Promise<any>;
}
