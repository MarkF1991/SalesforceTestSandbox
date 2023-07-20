declare module "@salesforce/apex/N4LFormScreen.getUserLicense" {
  export default function getUserLicense(): Promise<any>;
}
declare module "@salesforce/apex/N4LFormScreen.getRecordDetails" {
  export default function getRecordDetails(param: {recordId: any, contactId: any, objectName: any, isReplace: any, accountId: any, replaceValue: any}): Promise<any>;
}
declare module "@salesforce/apex/N4LFormScreen.checkEmailDuplicates" {
  export default function checkEmailDuplicates(param: {email: any, recordId: any, emailEditable: any}): Promise<any>;
}
declare module "@salesforce/apex/N4LFormScreen.checkEmailDomain" {
  export default function checkEmailDomain(param: {email: any, accountId: any}): Promise<any>;
}
declare module "@salesforce/apex/N4LFormScreen.checkSupportHubUser" {
  export default function checkSupportHubUser(param: {recordId: any, contactId: any, objectName: any, isReplace: any}): Promise<any>;
}
declare module "@salesforce/apex/N4LFormScreen.retrieveMultipicklistValues" {
  export default function retrieveMultipicklistValues(param: {objectName: any, fieldName: any, accountId: any}): Promise<any>;
}
declare module "@salesforce/apex/N4LFormScreen.retrieveScreenSettings" {
  export default function retrieveScreenSettings(): Promise<any>;
}
declare module "@salesforce/apex/N4LFormScreen.getResults" {
  export default function getResults(param: {ObjectName: any, fieldName: any, value: any, accountId: any}): Promise<any>;
}
declare module "@salesforce/apex/N4LFormScreen.getResultFromExistingSchool" {
  export default function getResultFromExistingSchool(param: {value: any, accountId: any}): Promise<any>;
}
declare module "@salesforce/apex/N4LFormScreen.getAccountDetails" {
  export default function getAccountDetails(param: {recordId: any, accountId: any}): Promise<any>;
}
declare module "@salesforce/apex/N4LFormScreen.addNewContact" {
  export default function addNewContact(param: {newEmail: any, firstName: any, lastName: any, jobTitle: any, mobilePhone: any, outageNotif: any, periodicEmail: any, operational: any, createSupportHubUser: any, accountId: any, recordId: any, isReplace: any, replaceValue: any, isInherit: any, secondaryEmail: any, systemAccessible: any, isActive: any}): Promise<any>;
}
declare module "@salesforce/apex/N4LFormScreen.saveRelationship" {
  export default function saveRelationship(param: {recordId: any, accountId: any, contactId: any, isActive: any, canProvideSiteAccess: any, roles: any, authorities: any, createSupportHubUser: any, currentRecordId: any, isReplace: any, replaceValue: any, isChangeOldEmail: any, isInherit: any, systemAccessible: any}): Promise<any>;
}
declare module "@salesforce/apex/N4LFormScreen.captureContactPrimaryAccountName" {
  export default function captureContactPrimaryAccountName(param: {accConRelId: any}): Promise<any>;
}
declare module "@salesforce/apex/N4LFormScreen.validateContactFieldEdits" {
  export default function validateContactFieldEdits(param: {recordId: any, accountId: any}): Promise<any>;
}
declare module "@salesforce/apex/N4LFormScreen.getContactEmail" {
  export default function getContactEmail(param: {recordId: any}): Promise<any>;
}
declare module "@salesforce/apex/N4LFormScreen.matchRolesAndAuthorities" {
  export default function matchRolesAndAuthorities(): Promise<any>;
}
