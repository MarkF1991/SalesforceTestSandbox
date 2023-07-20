/**
* @author Ben Soh (ben.soh@n4l.co.nz)
* @date 2020-09-08
* @description 	defined as a wrapper class for HTTP Request in ServiceEventRest.cls.
*				this class uses virtual and extends to create an abstract layer for "data" object
*
* CHANGE LOG
* renamed ServiceEventNetworkDesignWrapper to ServiceEventNDWrapper
**/
public class ServiceEventWrapper {

	public ServiceEventWrapper(){
		//constructor
		header = new Header();
	}

	public class Header {
		public String eventType {get;set;} 
		public String action {get;set;} 
		public Integer replayId {get;set;} 
		public Datetime eventDate {get;set;} 
		public String internalReferenceId {get;set;} 
		public String origin {get;set;} 

		public Header(){
			//constructor
		}

		public Header(JSONParser parser) {
			while (parser.nextToken() != System.JSONToken.END_OBJECT) {
				if (parser.getCurrentToken() == System.JSONToken.FIELD_NAME) {
					String text = parser.getText();
					if (parser.nextToken() != System.JSONToken.VALUE_NULL) {
						if (text == 'eventType') {
							eventType = parser.getText();
						} else if (text == 'action') {
							action = parser.getText();
						} else if (text == 'replayId') {
							replayId = parser.getIntegerValue();
						} else if (text == 'eventDate') {
							eventDate = parser.getDatetimeValue();
						} else if (text == 'internalReferenceId') {
							internalReferenceId = parser.getText();
						} else if (text == 'origin') {
							origin = parser.getText();
						} else {
							System.debug(LoggingLevel.WARN, 'Header consuming unrecognized property: '+text);
							consumeObject(parser);
						}
					}
				}
			}
		}
	}
	
	
    public virtual class Data {
        
    }
    
    public class Data_ServiceRequestWebFiltering extends Data {
        public String subject {get;set;} 
		public String description {get;set;} 
		public String accountId {get;set;} 
		public String contactId {get;set;} 
		//public String origin {get;set;} 

		public Data_ServiceRequestWebFiltering(){
			//constructor
		}
	}
	
	public class Data_NetworkDesign extends Data {
		public ServiceEventNDWrapper networkDesign {get;set;} 

		public Data_NetworkDesign(){
			//constructor
		}
		public Data_NetworkDesign(JSONParser parser) {
			
			while (parser.nextToken() != System.JSONToken.END_OBJECT) {
				if (parser.getCurrentToken() == System.JSONToken.FIELD_NAME) {
					String text = parser.getText();
					if (parser.nextToken() != System.JSONToken.VALUE_NULL) {
						if (text == 'networkDesign') {
							networkDesign = new ServiceEventNDWrapper(parser); 
						} else {
							System.debug(LoggingLevel.WARN, 'Data_NetworkDesign consuming unrecognized property: '+text);
							consumeObject(parser);
						}
					}
				}
			}
		}
    }
    
    public class Data_PDFid extends Data {
		public String pdfId {get;set;} 

		public Data_PDFid(){
			//constructor
		}
		
		public Data_PDFid(JSONParser parser) {
			while (parser.nextToken() != System.JSONToken.END_OBJECT) {
				if (parser.getCurrentToken() == System.JSONToken.FIELD_NAME) {
					String text = parser.getText();
					if (parser.nextToken() != System.JSONToken.VALUE_NULL) {
						if (text == '_id') {
							pdfId = parser.getText();
						} else {
							System.debug(LoggingLevel.WARN, 'Data consuming unrecognized property: '+text);
							consumeObject(parser);
						}
					}
				}
			}
		}

	}
	

    public class Data_PDFcreate extends Data {
		public String templateId {get;set;} 
        public Contract contract {get;set;} 

		public Data_PDFcreate(){
			//constructor
		}

		public Data_PDFcreate(JSONParser parser) {
			while (parser.nextToken() != System.JSONToken.END_OBJECT) {
				if (parser.getCurrentToken() == System.JSONToken.FIELD_NAME) {
					String text = parser.getText();
					if (parser.nextToken() != System.JSONToken.VALUE_NULL) {
						if (text == 'templateId') {
							templateId = parser.getText();
						} else if (text == 'contract') {
                            //contract = new Contract(parser);
                            contract = (Contract)parser.readValueAs(Contract.class);
						} else {
							System.debug(LoggingLevel.WARN, 'Data consuming unrecognized property: '+text);
							consumeObject(parser);
						}
					}
				}
			}
		}
    }


   
	
	public String eventId {get;set;} // in json: _id
	public Header header {get;set;} 
	public Data data {get;set;} 
    public Datetime whenCreated {get;set;} 
    public System.Exception error {get;set;} 

	public ServiceEventWrapper(JSONParser parser) {
		while (parser.nextToken() != System.JSONToken.END_OBJECT) {
			if (parser.getCurrentToken() == System.JSONToken.FIELD_NAME) {
				String text = parser.getText();
				if (parser.nextToken() != System.JSONToken.VALUE_NULL) {
					if (text == '_id' || text == 'eventId') {
						eventId = parser.getText();
					} else if (text == 'header') {
						header = new Header(parser);
					} else if (text == 'data') {


                        try{
                            //create instance of the inner class data                        
                            switch on header.eventType {
                                when 'ServiceRequestWebFiltering' {
                                    data = (Data_ServiceRequestWebFiltering)parser.readValueAs(Data_ServiceRequestWebFiltering.class);
								}
								when 'NetworkDesign' {
									data = new Data_NetworkDesign(parser);
                                }
                                when 'PDF' {
                                    switch on header.action {
                                        when 'create' { //was generate
                                            data = new Data_PDFcreate(parser);
                                            //data.contract = (Contract)parser.readValueAs(Contract.class);
                                            //data = (Data_PDFcreate)parser.readValueAsStrict(Data_PDFcreate.class); //do validation out side of thie wrapper
                                        }
                                        when 'created' {
											//data = (Data_PDFid)parser.readValueAs(Data_PDFid.class); //do validation out side of thie wrapper
											data = new Data_PDFid(parser);
                                        }
                                    }
                                }
                            }
                            error = null; //when parser.readValueAsStrict is successful leave error as null

                        } catch (System.Exception e){
                            data = null;
                            //error = new System.Exception();
                            error = e;
                        }
                        

					} else if (text == 'whenCreated') {
						whenCreated = parser.getDatetimeValue();
					} else {
						System.debug(LoggingLevel.WARN, 'ServiceEventWrapper consuming unrecognized property: '+text);
						consumeObject(parser);
					}
				}
			}
		}
	}
    
	
	public static ServiceEventWrapper parse(String json) {
		System.JSONParser parser = System.JSON.createParser(json);
		return new ServiceEventWrapper(parser);
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