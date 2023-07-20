public class ServiceEventNDWrapper {

	public class EquipmentForRemoval {
		public String organisationId {get;set;} 

		public EquipmentForRemoval(JSONParser parser) {
			while (parser.nextToken() != System.JSONToken.END_OBJECT) {
				if (parser.getCurrentToken() == System.JSONToken.FIELD_NAME) {
					String text = parser.getText();
					if (parser.nextToken() != System.JSONToken.VALUE_NULL) {
						if (text == 'organisationId') {
							organisationId = parser.getText();
						} else {
							System.debug(LoggingLevel.WARN, 'EquipmentForRemoval consuming unrecognized property: '+text);
							consumeObject(parser);
						}
					}
				}
			}
		}
	}
	

	
    public class Product {
        public String salesforceId {get;set;}
		public String name {get;set;} 

        public Product() {

		}
		public Product(JSONParser parser) {
			while (parser.nextToken() != System.JSONToken.END_OBJECT) {
				if (parser.getCurrentToken() == System.JSONToken.FIELD_NAME) {
					String text = parser.getText();
					if (parser.nextToken() != System.JSONToken.VALUE_NULL) {
                        if (text == 'salesforceId') {
							salesforceId = parser.getText();
						} else if (text == 'name') {
							name = parser.getText();
						} else {
							System.debug(LoggingLevel.WARN, 'Product consuming unrecognized property: '+text);
							consumeObject(parser);
						}
					}
				}
			}
		}
	}
    public class Pdf {
		public String x_id {get;set;} // in json: _id
		public String filename {get;set;} 
		public String pdfId {get;set;} 
		public String pdfType {get;set;} 
		public String whenCreated {get;set;} 
        public String whenUpdated {get;set;} 
        public String pdfParentId {get;set;}  //for internal use salesforce apex to get PDF and save as file

        public Pdf() {

		}
		public Pdf(JSONParser parser) {
			while (parser.nextToken() != System.JSONToken.END_OBJECT) {
				if (parser.getCurrentToken() == System.JSONToken.FIELD_NAME) {
					String text = parser.getText();
					if (parser.nextToken() != System.JSONToken.VALUE_NULL) {
						if (text == '_id') {
							x_id = parser.getText();
						} else if (text == 'filename') {
							filename = parser.getText();
						} else if (text == 'pdfId') {
							pdfId = parser.getText();
						} else if (text == 'pdfType') {
							pdfType = parser.getText();
						} else if (text == 'whenCreated') {
							whenCreated = parser.getText();
						} else if (text == 'whenUpdated') {
							whenUpdated = parser.getText();
						} else {
							System.debug(LoggingLevel.WARN, 'Pdf consuming unrecognized property: '+text);
							consumeObject(parser);
						}
					}
				}
			}
		}
    }
    
    public class Header {
		public String estimatedOutageTime {get;set;} 

		public Header(JSONParser parser) {
			while (parser.nextToken() != System.JSONToken.END_OBJECT) {
				if (parser.getCurrentToken() == System.JSONToken.FIELD_NAME) {
					String text = parser.getText();
					if (parser.nextToken() != System.JSONToken.VALUE_NULL) {
						if (text == 'estimatedOutageTime') {
							estimatedOutageTime = parser.getText();
						} else {
							System.debug(LoggingLevel.WARN, 'Header consuming unrecognized property: '+text);
							consumeObject(parser);
						}
					}
				}
			}
		}
    }

	public class NewEquipment {
		public String x_id {get;set;} // in json: _id
		public Integer quantity {get;set;} 
		public Double cost {get;set;} 
		public Integer moeFunded {get;set;} 
		public Boolean isBundleEquipment {get;set;} 
		public String lineDescription {get;set;} 
		public String salesforcePriceBookId {get;set;} 
        public String salesforcePriceBookEntryId {get;set;}
        public Double lineTotal {get;set;}
		public Product product {get;set;} 

        public NewEquipment() {

        }
        
		public NewEquipment(JSONParser parser) {
			while (parser.nextToken() != System.JSONToken.END_OBJECT) {
				if (parser.getCurrentToken() == System.JSONToken.FIELD_NAME) {
					String text = parser.getText();
					if (parser.nextToken() != System.JSONToken.VALUE_NULL) {
						if (text == '_id' || text == 'x_id') {
							x_id = parser.getText();
						} else if (text == 'quantity') {
							quantity = parser.getIntegerValue();
						} else if (text == 'cost') {
							cost = parser.getDoubleValue();
						} else if (text == 'moeFunded') {
							moeFunded = parser.getIntegerValue();
						} else if (text == 'isBundleEquipment') {
							isBundleEquipment = parser.getBooleanValue();
						} else if (text == 'lineDescription') {
							lineDescription = parser.getText();
						} else if (text == 'salesforcePriceBookId') {
							salesforcePriceBookId = parser.getText();
						} else if (text == 'salesforcePriceBookEntryId') {
							salesforcePriceBookEntryId = parser.getText();
						} else if (text == 'lineTotal') {
							lineTotal = parser.getDoubleValue();
						} else if (text == 'product') {
							product = new Product(parser);
						} else {
							System.debug(LoggingLevel.WARN, 'NewEquipment consuming unrecognized property: '+text);
							consumeObject(parser);
						}
					}
				}
			}
		}
    }

	
	public class InstallerSOW {
		public String x_id {get;set;} // in json: _id
		public Double quantity {get;set;} 
		public Double cost {get;set;} 
		public Integer moeFunded {get;set;} 
		public Boolean isBundleEquipment {get;set;} 
		public String lineDescription {get;set;} 
		public String salesforcePriceBookId {get;set;} 
		public String salesforcePriceBookEntryId {get;set;} 
		public Double lineTotal {get;set;} 
		public Product product {get;set;} 
		
		public InstallerSOW() {

        }

		public InstallerSOW(JSONParser parser) {
			while (parser.nextToken() != System.JSONToken.END_OBJECT) {
				if (parser.getCurrentToken() == System.JSONToken.FIELD_NAME) {
					String text = parser.getText();
					if (parser.nextToken() != System.JSONToken.VALUE_NULL) {
						if (text == '_id' || text == 'x_id') {
							x_id = parser.getText();
						} else if (text == 'quantity') {
							quantity = parser.getDoubleValue();
						} else if (text == 'cost') {
							cost = parser.getDoubleValue();
						} else if (text == 'moeFunded') {
							moeFunded = parser.getIntegerValue();
						} else if (text == 'isBundleEquipment') {
							isBundleEquipment = parser.getBooleanValue();
						} else if (text == 'lineDescription') {
                            lineDescription = parser.getText();
						} else if (text == 'salesforcePriceBookId') {
							salesforcePriceBookId = parser.getText();
						} else if (text == 'salesforcePriceBookEntryId') {
							salesforcePriceBookEntryId = parser.getText();
						} else if (text == 'lineTotal') {
							lineTotal = parser.getDoubleValue();
						} else if (text == 'product') {
							product = new Product(parser);
						} else {
							System.debug(LoggingLevel.WARN, 'InstallerSOW consuming unrecognized property: '+text);
							consumeObject(parser);
						}
					}
				}
			}
		}
	}
	
    public class Implementation {
		public String recommendation {get;set;} 
		public String provider {get;set;}
		public String salesforceProviderId {get; set;} 
		public String selector {get;set;} 
		public String selection {get;set;} 

		public Implementation() {
			
		}

		public Implementation(JSONParser parser) {
			while (parser.nextToken() != System.JSONToken.END_OBJECT) {
				if (parser.getCurrentToken() == System.JSONToken.FIELD_NAME) {
					String text = parser.getText();
					if (parser.nextToken() != System.JSONToken.VALUE_NULL) {
						if (text == 'recommendation') {
							recommendation = parser.getText();
						} else if (text == 'provider') {
							provider = parser.getText();
						} else if (text == 'salesforceProviderId') {
							salesforceProviderId = parser.getText();
						} else if (text == 'selector') {
							selector = parser.getText();
						} else if (text == 'selection') {
							selection = parser.getText();
						} else {
							System.debug(LoggingLevel.WARN, 'Implementation consuming unrecognized property: '+text);
							consumeObject(parser);
						}
					}
				}
			}
		}
	}

    public Header header {get;set;} 
    public String installationNotes {get;set;}
    public List<NewEquipment> newEquipment {get;set;}
    public List<EquipmentForRemoval> equipmentForRemoval {get;set;}
    public Implementation implementation {get;set;} 
    public List<InstallerSOW> installerSOW {get;set;} 
    public List<Pdf> pdfs {get;set;}
    public String x_id {get;set;} // in json: _id
    public String caseId {get;set;} 
    public String salesforceCaseId {get;set;} 
    public Integer caseNumber {get;set;} 
    public String schoolId {get;set;} 
    public String schoolName {get;set;} 
    public String createdBy {get;set;} 
    public String assignedTo {get;set;}
    public String approvedBy {get;set;} 
    public String owner {get;set;} 
    public Boolean schoolApproved {get;set;} 
	public Boolean installerApproved {get;set;} 
	public String installerPriceBookId {get;set;}
	public String salesforceInstallerPricebookId {get;set;}

	public ServiceEventNDWrapper(JSONParser parser) {
		while (parser.nextToken() != System.JSONToken.END_OBJECT) {
			if (parser.getCurrentToken() == System.JSONToken.FIELD_NAME) {
				String text = parser.getText();
                if (parser.nextToken() != System.JSONToken.VALUE_NULL) {
                    if (text == '_id' || text == 'x_id') {
                        x_id = parser.getText();
                    } else if (text == 'header') {
                        header = new Header(parser);
                    } else if (text == 'caseId') {
                        caseId = parser.getText();
                    } else if (text == 'salesforceCaseId') {
                        salesforceCaseId = parser.getText();
                    } else if (text == 'caseNumber') {
                        caseNumber = parser.getIntegerValue();
                    } else if (text == 'schoolId') {
                        schoolId = parser.getText();
                    } else if (text == 'schoolName') {
                        schoolName = parser.getText();
                    } else if (text == 'createdBy') {
                        createdBy = parser.getText();
                    } else if (text == 'assignedTo') {
                        assignedTo = parser.getText();
                    } else if (text == 'approvedBy') {
                        approvedBy = parser.getText();
                    } else if (text == 'owner') {
                        owner = parser.getText();
                    } else if (text == 'installationNotes') {
                        installationNotes = parser.getText();
                    } else if (text == 'schoolApproved') {
                        schoolApproved = parser.getBooleanValue();
                    } else if (text == 'installerApproved') {
						installerApproved = parser.getBooleanValue();
					} else if (text == 'installerPriceBookId') {
						installerPriceBookId = parser.getText();
					} else if (text == 'salesforceInstallerPricebookId') {
						salesforceInstallerPricebookId = parser.getText();
                    } else if (text == 'newEquipment') {
                        newEquipment = arrayOfNewEquipment(parser);
                    } else if (text == 'equipmentForRemoval') {
                        equipmentForRemoval = arrayOfEquipmentForRemoval(parser);
                    } else if (text == 'implementation') {
                        implementation = new Implementation(parser);
                    } else if (text == 'installerSOW') {
                        installerSOW = arrayOfInstallerSOW(parser);
                    } else if (text == 'pdfs') {
                        pdfs = arrayOfPdf(parser);
                    } else {
						System.debug(LoggingLevel.WARN, 'ServiceEventNDWrapper consuming unrecognized property: '+text);
						consumeObject(parser);
					}
				}
			}
		}
	}


	public static ServiceEventNDWrapper parse(String json) {
		System.JSONParser parser = System.JSON.createParser(json);
		return new ServiceEventNDWrapper(parser);
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


    private static List<InstallerSOW> arrayOfInstallerSOW(System.JSONParser p) {
        List<InstallerSOW> res = new List<InstallerSOW>();
        if (p.getCurrentToken() == null) p.nextToken();
        while (p.nextToken() != System.JSONToken.END_ARRAY) {
            res.add(new InstallerSOW(p));
        }
        return res;
    }

    private static List<Pdf> arrayOfPdf(System.JSONParser p) {
        List<Pdf> res = new List<Pdf>();
        if (p.getCurrentToken() == null) p.nextToken();
        while (p.nextToken() != System.JSONToken.END_ARRAY) {
            res.add(new Pdf(p));
        }
        return res;
    }


    private static List<NewEquipment> arrayOfNewEquipment(System.JSONParser p) {
        List<NewEquipment> res = new List<NewEquipment>();
        if (p.getCurrentToken() == null) p.nextToken();
        while (p.nextToken() != System.JSONToken.END_ARRAY) {
            res.add(new NewEquipment(p));
        }
        return res;
    }


    private static List<EquipmentForRemoval> arrayOfEquipmentForRemoval(System.JSONParser p) {
        List<EquipmentForRemoval> res = new List<EquipmentForRemoval>();
        if (p.getCurrentToken() == null) p.nextToken();
        while (p.nextToken() != System.JSONToken.END_ARRAY) {
            res.add(new EquipmentForRemoval(p));
        }
        return res;
    }
}