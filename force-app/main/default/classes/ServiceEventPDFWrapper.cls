/**
* @author Ben Soh (ben.soh@n4l.co.nz)
* @date 2020-09-25
* @description 	defined as a wrapper class for HTTP Response in ServiceEventPDFCallout.cls.
*
* CHANGE LOG
**/

public class ServiceEventPDFWrapper {
	// public class Content {
	// 	public Attributes attributes {get;set;} 
		
	// 	public Content(JSONParser parser) {
	// 		while (parser.nextToken() != System.JSONToken.END_OBJECT) {
	// 			if (parser.getCurrentToken() == System.JSONToken.FIELD_NAME) {
	// 				String text = parser.getText();
	// 				if (parser.nextToken() != System.JSONToken.VALUE_NULL) {
	// 					if (text == 'attributes') {
	// 						attributes = new Attributes(parser);
	// 					} else {
	// 						System.debug(LoggingLevel.WARN, 'Content consuming unrecognized property: '+text);
	// 						consumeObject(parser);
	// 					}
	// 				}
	// 			}
	// 		}
	// 	}
	// }
	
	// public class Attributes {
	// 	public String type {get;set;} // in json: type
	// 	public String url {get;set;} 

	// 	public Attributes(JSONParser parser) {
	// 		while (parser.nextToken() != System.JSONToken.END_OBJECT) {
	// 			if (parser.getCurrentToken() == System.JSONToken.FIELD_NAME) {
	// 				String text = parser.getText();
	// 				if (parser.nextToken() != System.JSONToken.VALUE_NULL) {
	// 					if (text == 'type') {
	// 						type = parser.getText();
	// 					} else if (text == 'url') {
	// 						url = parser.getText();
	// 					} else {
	// 						System.debug(LoggingLevel.WARN, 'Attributes consuming unrecognized property: '+text);
	// 						consumeObject(parser);
	// 					}
	// 				}
	// 			}
	// 		}
	// 	}
	// }

	// public class InputData {
	// 	public String templateId {get;set;} 
	// 	public Content content {get;set;} 

	// 	public InputData(JSONParser parser) {
	// 		while (parser.nextToken() != System.JSONToken.END_OBJECT) {
	// 			if (parser.getCurrentToken() == System.JSONToken.FIELD_NAME) {
	// 				String text = parser.getText();
	// 				if (parser.nextToken() != System.JSONToken.VALUE_NULL) {
	// 					if (text == 'templateId') {
	// 						templateId = parser.getText();
	// 					} else if (text == 'content') {
	// 						content = new Content(parser);
	// 					} else {
	// 						System.debug(LoggingLevel.WARN, 'InputData consuming unrecognized property: '+text);
	// 						consumeObject(parser);
	// 					}
	// 				}
	// 			}
	// 		}
	// 	}
	// }

	public class Data {
		public String eventId {get;set;} // in json: _id
		//public InputData inputData {get;set;} 
		public String pdfBlob {get;set;} 
		

		public Data(JSONParser parser) {
			while (parser.nextToken() != System.JSONToken.END_OBJECT) {
				if (parser.getCurrentToken() == System.JSONToken.FIELD_NAME) {
					String text = parser.getText();
					if (parser.nextToken() != System.JSONToken.VALUE_NULL) {
						if (text == '_id') {
							eventId = parser.getText();
						// } else if (text == 'inputData') {
						// 	inputData = new InputData(parser);
						} else if (text == 'pdfBlob') {
							pdfBlob = parser.getText();
						} else {
							System.debug(LoggingLevel.WARN, 'Data consuming unrecognized property: '+text);
							consumeObject(parser);
						}
					}
				}
			}
		}
	}
	
	public Data data {get;set;} 

	public ServiceEventPDFWrapper(JSONParser parser) {
		while (parser.nextToken() != System.JSONToken.END_OBJECT) {
			if (parser.getCurrentToken() == System.JSONToken.FIELD_NAME) {
				String text = parser.getText();
				if (parser.nextToken() != System.JSONToken.VALUE_NULL) {
					if (text == 'data') {
						data = new Data(parser);
					} else {
						System.debug(LoggingLevel.WARN, 'ServiceEventPDFWrapper consuming unrecognized property: '+text);
						consumeObject(parser);
					}
				}
			}
		}
	}
	

	public static ServiceEventPDFWrapper parse(String json) {
		System.JSONParser parser = System.JSON.createParser(json);
		return new ServiceEventPDFWrapper(parser);
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
	

}