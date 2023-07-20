@IsTest
public class FarmsideEmailWrapperTest {
   
	static testMethod void testParse() {
		String json = '{'+
		'    \"email_alerts\": ['+
		'        {'+
		'         \"RSP_Customer_No\":\"test001\",'+
		'         \"Email_Sent_to\":\"dummy1@n4l.com\",'+
		'         \"Last_Usage_Alert_Email_Content\":\"test email content 1\",'+
		'         \"Last_Usage_Alert_Email_Date_Time\":\"2020-05-14 16:15:00\",'+
        '         \"Alert_Email_Type\":\"over 80 alert"'+
		'        },'+
		'        {'+
		'         \"RSP_Customer_No\":\"test002\",'+
		'         \"Email_Sent_to\":\"dummy2@n4l.com\",'+
		'         \"Last_Usage_Alert_Email_Content\":\"test html content 2\",'+
		'         \"Last_Usage_Alert_Email_Date_Time\":\"2020-05-16 20:15:35\",'+
        '         \"Alert_Email_Type\":\"over 100 alert"'+
		'        }'+
		'    ]'+
		'}';
		FarmsideEmailWrapper r = FarmsideEmailWrapper.parse(json);
		System.assert(r != null);

		json = '{\"TestAMissingObject\": { \"TestAMissingArray\": [ { \"TestAMissingProperty\": \"Some Value\" } ] } }';
		FarmsideEmailWrapper objJSON2Apex = new FarmsideEmailWrapper(System.JSON.createParser(json));
		System.assert(objJSON2Apex != null);
		System.assert(objJSON2Apex.email_alerts == null);

		json = '{\"TestAMissingObject\": { \"TestAMissingArray\": [ { \"TestAMissingProperty\": \"Some Value\" } ] } }';
		FarmsideEmailWrapper.Email_alerts objEmail_alerts = new FarmsideEmailWrapper.Email_alerts(System.JSON.createParser(json));
		System.assert(objEmail_alerts != null);
		System.assert(objEmail_alerts.RSP_Customer_No == null);
		System.assert(objEmail_alerts.Email_Sent_to == null);
		System.assert(objEmail_alerts.Last_Usage_Alert_Email_Content == null);
		System.assert(objEmail_alerts.Last_Usage_Alert_Email_Date_Time == null);
        System.assert(objEmail_alerts.Alert_Email_Type == null);
        
	}

}