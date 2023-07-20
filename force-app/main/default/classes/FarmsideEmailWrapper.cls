/** created by n4lsalesforce@gmail.com on 17/05/2020
 *  a wrapper class for notifications data from n4l internal platform.
 *  
**/
public class FarmsideEmailWrapper {

    public List<Email_alerts> email_alerts {get;set;} 
    public FarmsideEmailWrapper(){}
	public FarmsideEmailWrapper(JSONParser parser) {
		while (parser.nextToken() != System.JSONToken.END_OBJECT) {
			if (parser.getCurrentToken() == System.JSONToken.FIELD_NAME) {
				String text = parser.getText();
				if (parser.nextToken() != System.JSONToken.VALUE_NULL) {
					if (text == 'email_alerts') {
						email_alerts = arrayOfEmail_alerts(parser);
					} else {
						System.debug(LoggingLevel.WARN, 'FarmsideEmailWrapper consuming unrecognized property: '+text);
						consumeObject(parser);
					}
				}
			}
		}
	}
	
	public class Email_alerts {
		public String RSP_Customer_No {get;set;} 
		public String Email_Sent_to {get;set;} 
		public String Last_Usage_Alert_Email_Content {get;set;} 
		public String Last_Usage_Alert_Email_Date_Time {get;set;} 
        public String Alert_Email_Type {get;set;} 
   
		public Email_alerts(JSONParser parser) {
			while (parser.nextToken() != System.JSONToken.END_OBJECT) {
				if (parser.getCurrentToken() == System.JSONToken.FIELD_NAME) {
					String text = parser.getText();
					if (parser.nextToken() != System.JSONToken.VALUE_NULL) {
						if (text == 'RSP_Customer_No') {
							RSP_Customer_No = parser.getText();
						} else if (text == 'Email_Sent_to') {
							Email_Sent_to = parser.getText();
						} else if (text == 'Last_Usage_Alert_Email_Content') {
							Last_Usage_Alert_Email_Content = parser.getText();
						} else if (text == 'Last_Usage_Alert_Email_Date_Time') {
							Last_Usage_Alert_Email_Date_Time = parser.getText();
						} else if (text == 'Alert_Email_Type') {
							Alert_Email_Type = parser.getText();
                        } else {
							System.debug(LoggingLevel.WARN, 'Email_alerts consuming unrecognized property: '+text);
							consumeObject(parser);
						}
					}
				}
			}
		}
	}
	
	
	public static FarmsideEmailWrapper parse(String json) {
		System.JSONParser parser = System.JSON.createParser(json);
		return new FarmsideEmailWrapper(parser);
	}
	
	public static void consumeObject(System.JSONParser parser) {
		Integer depth = 0;
		do {
			System.JSONToken curr = parser.getCurrentToken();
			if (curr == System.JSONToken.START_OBJECT || 
				curr == System.JSONToken.START_ARRAY) {
				depth++;
			} else if (curr == System.JSONToken.END_OBJECT ||
				curr == System.JSONToken.END_ARRAY) {
				depth--;
			}
		} while (depth > 0 && parser.nextToken() != null);
	}
	


    private static List<Email_alerts> arrayOfEmail_alerts(System.JSONParser p) {
        List<Email_alerts> res = new List<Email_alerts>();
        if (p.getCurrentToken() == null) p.nextToken();
        while (p.nextToken() != System.JSONToken.END_ARRAY) {
            res.add(new Email_alerts(p));
        }
        return res;
    }


}