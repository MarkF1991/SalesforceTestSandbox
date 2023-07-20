/** created by n4lsalesforce@gmail.com on 17/05/2020
 *  receive email notifications from n4l internal platform.
 *  store latest email content into "Last_Usage_Alert_Email_Content__c" under student household object.
 *  create a chatter post.
**/
@RestResource(urlMapping='/n4l/platform/usage-alerts/*')
global without sharing class FarmsideApexRest {
/** update record if json is valid.
 * otherwise save json as a file into library folder "FarmSide Errors".
**/    
    @HttpPOST
    global static String doPost() {
        RestRequest req = RestContext.request;
        if(FarmsideApexRestHelper.isJsonValid(req.requestBody.toString())){
        /** activate this email method when need.
        FarmsideApexRestHelper.sendEmail(req.requestBody.toString());
        **/
        FarmsideApexRestHelper.updateRecord(req.requestBody.toString());
        return 'Update Received';
        }else{
          FarmsideApexRestHelper.createErrorFile(req.requestBody.toString());  
          return 'Json Error';   
        }    
    }
    
}