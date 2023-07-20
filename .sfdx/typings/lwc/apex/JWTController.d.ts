declare module "@salesforce/apex/JWTController.decodeJWTintoMap" {
  export default function decodeJWTintoMap(param: {type: any, input: any, isEncrypted: any}): Promise<any>;
}
declare module "@salesforce/apex/JWTController.authenticate" {
  export default function authenticate(param: {userid: any}): Promise<any>;
}
declare module "@salesforce/apex/JWTController.request_authorisation" {
  export default function request_authorisation(param: {productName: any, token: any}): Promise<any>;
}
declare module "@salesforce/apex/JWTController.request_authorisation_with_credential" {
  export default function request_authorisation_with_credential(param: {productName: any, token: any, userId: any}): Promise<any>;
}
