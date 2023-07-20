/**
* @author Mark Fu
* @date 2023-01-20
* @description  to handle HTTP Requests.
*
* CHANGE LOG
* 
**/

@RestResource(urlMapping='/n4l/platform/ss-user-registration/*')
global without sharing class SelfServiceRest {
    @Httppost
    global static User doPost() {
        RestRequest req = RestContext.request;
        return SelfServiceRestHelper.CreateSSuserAccount(req.requestBody.toString());
    }
}