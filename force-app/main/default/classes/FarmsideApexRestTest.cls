/** created by n4lsalesforce@gmail.com on 1/7/2020
 *  test calss for both FarmsideApexRestHelper and FarmsideApexRest.
**/
@isTest
private class FarmsideApexRestTest {
    static testMethod void happypathtest(){
        account testacc = new account();
        testacc.name = 'testaccname';
        insert testacc;
        Student_House_Hold__c testshh = new Student_House_Hold__c();
        testshh.name = 'testshhname';
        testshh.RSP__c = testacc.id; 
        testshh.Street_Address__c ='testaddress';
        testshh.City__c ='testcity';
        testshh.RSP_Customer_No__c ='test001';
        insert testshh;
        String json = 
             '{'+
             '       \"email_alerts\": [ '+
             '  {'+
        	 '       \"RSP_Customer_No\":\"test001\",'+
        	 '       \"Email_Sent_to\":\"0001@n4l.com\",'+
             '       \"Last_Usage_Alert_Email_Content\": \"test email body 1\",'+
             '       \"Last_Usage_Alert_Email_Date_Time\":\"2020-05-28 15:30:30\",'+
			 '       \"Alert_Email_Type\":\"over 80 alert\"'+
             '},'+
             '{'+
        	 '       \"RSP_Customer_No\":\"test002\",'+
        	 '       \"Email_Sent_to\":\"0002@n4l.com\",'+
             '       \"Last_Usage_Alert_Email_Content\":\"test email body 2\",'+
             '       \"Last_Usage_Alert_Email_Date_Time\":\"2020-05-29 15:30:30\",'+
			 '       \"Alert_Email_Type\":\"over 100 alert\" '+
             '}'+
             ']'+
             '}';
        RestRequest request = new RestRequest();
        request.requestUri ='/services/apexrest/n4l/platform/usage-alerts';
        request.httpMethod = 'POST';
		request.requestBody = blob.valueOf(json);
        RestContext.request = request;
		system.Test.startTest();
        FarmsideApexRest.doPost();
        system.Test.stopTest();
    }
    static testMethod void errortest(){
        String json = 
             '{'+
             '       \"email_alerts\": [ '+
             '  {'+
        	 '       \"RSP_Customer_No\":\"test001\",'+
        	 '       \"Email_Sent_to\":\"0001@n4l.com\",'+
             '       \"Last_Usage_Alert_Email_Content\": \"test email body 1\",'+
             '       \"Last_Usage_Alert_Email_Date_Time\":\"2020-05-28 15:30:30\",'+
			 '       \"Alert_Email_Type\":\"over 80 alert\"'+
             '},'+
             '{'+
        	 '       \"RSP_Customer_No\":\"test002\",'+
        	 '       \"Email_Sent_to\":\"0002@n4l.com\",'+
             '       \"Last_Usage_Alert_Email_Content\":\"test email body 2\",'+
             '       \"Last_Usage_Alert_Email_Date_Time\":\"2020-05-29 15:30:30\",'+
			 '       \"Alert_Email_Type\":\"over 100 alert\" '+
             '}'+
             ']'+
             ',}'; //make it invaild json by adding an additional "," 
        RestRequest request = new RestRequest();
        request.requestUri ='/services/apexrest/n4l/platform/usage-alerts';
        request.httpMethod = 'POST';
		request.requestBody = blob.valueOf(json);
        RestContext.request = request;
		system.Test.startTest();
        FarmsideApexRest.doPost();
        system.Test.stopTest();
    }
}