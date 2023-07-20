/** created by n4lsalesforce@gmail.com on 17/05/2020
 *  receive student household records from n4l internal platform.
 *  upsert record by id RSP_Customer_No__c.
**/
@RestResource(urlMapping='/n4l/platform/welcome-calls/*')
global without sharing class StudentHouseHoldApexRest {
   @Httppost
    global static String doPost() {
        RestRequest req = RestContext.request;
        return StudentHouseHoldApexRestHelper.UpsertStudentHouseHold(req.requestBody.toString());
    }
}