//
// Generated by JSON2Apex http://json2apex.herokuapp.com/
//
// The supplied json has fields with names that are not valid in apex
// and so can only be parsed with explicitly generated code, this option
// was auto selected for you.

public class NetworkDesign {

	public class Product {
		public String x_id {get;set;} // in json: _id
		public String salesforceId {get;set;} 
		public String description {get;set;} 
		public String deviceMake {get;set;} 
		public String deviceMakeId {get;set;} 
		public String deviceName {get;set;} 
		public String deviceType {get;set;} 
		public String family {get;set;} 
		public Boolean isActive {get;set;} 
		public String name {get;set;} 
		public String productCode {get;set;} 
		public String productType {get;set;} 
		public String quantityUnitOfMeasure {get;set;} 
		public String recordTypeId {get;set;} 
		public String stockKeepingUnit {get;set;} 

		public Product(JSONParser parser) {
			while (parser.nextToken() != System.JSONToken.END_OBJECT) {
				if (parser.getCurrentToken() == System.JSONToken.FIELD_NAME) {
					String text = parser.getText();
					if (parser.nextToken() != System.JSONToken.VALUE_NULL) {
						if (text == '_id') {
							x_id = parser.getText();
						} else if (text == 'salesforceId') {
							salesforceId = parser.getText();
						} else if (text == 'description') {
							description = parser.getText();
						} else if (text == 'deviceMake') {
							deviceMake = parser.getText();
						} else if (text == 'deviceMakeId') {
							deviceMakeId = parser.getText();
						} else if (text == 'deviceName') {
							deviceName = parser.getText();
						} else if (text == 'deviceType') {
							deviceType = parser.getText();
						} else if (text == 'family') {
							family = parser.getText();
						} else if (text == 'isActive') {
							isActive = parser.getBooleanValue();
						} else if (text == 'name') {
							name = parser.getText();
						} else if (text == 'productCode') {
							productCode = parser.getText();
						} else if (text == 'productType') {
							productType = parser.getText();
						} else if (text == 'quantityUnitOfMeasure') {
							quantityUnitOfMeasure = parser.getText();
						} else if (text == 'recordTypeId') {
							recordTypeId = parser.getText();
						} else if (text == 'stockKeepingUnit') {
							stockKeepingUnit = parser.getText();
						} else {
							// System.debug(LoggingLevel.WARN, 'Product consuming unrecognized property: '+text);
							consumeObject(parser);
						}
					}
				}
			}
		}
	}
	
	public class Data {
		public List<InstallPlan> installPlan {get;set;} 
		public String schoolId {get;set;} 
		public String x_id {get;set;} // in json: _id
		public String caseNumber {get;set;} 

		public Data(JSONParser parser) {
			while (parser.nextToken() != System.JSONToken.END_OBJECT) {
				if (parser.getCurrentToken() == System.JSONToken.FIELD_NAME) {
					String text = parser.getText();
					if (parser.nextToken() != System.JSONToken.VALUE_NULL) {
						if (text == 'installPlan') {
							installPlan = arrayOfInstallPlan(parser);
						} else if (text == 'schoolId') {
							schoolId = parser.getText();
						} else if (text == '_id') {
							x_id = parser.getText();
						} else if (text == 'caseNumber') {
							caseNumber = parser.getText();
						} else {
							// System.debug(LoggingLevel.WARN, 'Data consuming unrecognized property: '+text);
							consumeObject(parser);
						}
					}
				}
			}
		}
	}
	
	public class BomItem {
		public String x_id {get;set;} // in json: _id
		public Integer quantity {get;set;} 
		public Double cost {get;set;} 
		public Integer moeFunded {get;set;} 
		public Boolean isBundleEquipment {get;set;} 
		public String lineDescription {get;set;} 
		public String priceBookId {get;set;} 
		public String salesforcePriceBookId {get;set;} 
		public String priceBookEntryId {get;set;} 
		public String salesforcePriceBookEntryId {get;set;} 
		public Double lineTotal {get;set;} 
		public Boolean editCost {get;set;} 
		public Product product {get;set;} 

		public BomItem(JSONParser parser) {
			while (parser.nextToken() != System.JSONToken.END_OBJECT) {
				if (parser.getCurrentToken() == System.JSONToken.FIELD_NAME) {
					String text = parser.getText();
					if (parser.nextToken() != System.JSONToken.VALUE_NULL) {
						if (text == '_id') {
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
						} else if (text == 'priceBookId') {
							priceBookId = parser.getText();
						} else if (text == 'salesforcePriceBookId') {
							salesforcePriceBookId = parser.getText();
						} else if (text == 'priceBookEntryId') {
							priceBookEntryId = parser.getText();
						} else if (text == 'salesforcePriceBookEntryId') {
							salesforcePriceBookEntryId = parser.getText();
						} else if (text == 'lineTotal') {
							lineTotal = parser.getDoubleValue();
						} else if (text == 'editCost') {
							editCost = parser.getBooleanValue();
						} else if (text == 'product') {
							product = new Product(parser);
						} else {
							// System.debug(LoggingLevel.WARN, 'BomItem consuming unrecognized property: '+text);
							consumeObject(parser);
						}
					}
				}
			}
		}
	}
	
	public Data data {get;set;} 

	public NetworkDesign(JSONParser parser) {
		while (parser.nextToken() != System.JSONToken.END_OBJECT) {
			if (parser.getCurrentToken() == System.JSONToken.FIELD_NAME) {
				String text = parser.getText();
				if (parser.nextToken() != System.JSONToken.VALUE_NULL) {
					if (text == 'data') {
						data = new Data(parser);
					} else {
						// System.debug(LoggingLevel.WARN, 'NetworkDesign consuming unrecognized property: '+text);
						consumeObject(parser);
					}
				}
			}
		}
	}
	
	public class InstallPlan {
		public String x_id {get;set;} // in json: _id
		public BomItem bomItem {get;set;} 
		public String bridgeGroup {get;set;} 
		public String cabinetIdent {get;set;} 
		public String hostname {get;set;} 
		public List<String> location {get;set;} 
		public String operation {get;set;} 
		public Boolean overheight {get;set;} 
		public String serialNumber {get;set;} 
		public String stackGroup {get;set;} 
		public String switchRole {get;set;} 

		public InstallPlan(JSONParser parser) {
			while (parser.nextToken() != System.JSONToken.END_OBJECT) {
				if (parser.getCurrentToken() == System.JSONToken.FIELD_NAME) {
					String text = parser.getText();
					if (parser.nextToken() != System.JSONToken.VALUE_NULL) {
						if (text == '_id') {
							x_id = parser.getText();
						} else if (text == 'bomItem') {
							bomItem = new BomItem(parser);
						} else if (text == 'bridgeGroup') {
							bridgeGroup = parser.getText();
						} else if (text == 'cabinetIdent') {
							cabinetIdent = parser.getText();
						} else if (text == 'hostname') {
							hostname = parser.getText();
						} else if (text == 'location') {
							location = arrayOfString(parser);
						} else if (text == 'operation') {
							operation = parser.getText();
						} else if (text == 'overheight') {
							overheight = parser.getBooleanValue();
						} else if (text == 'serialNumber') {
							serialNumber = parser.getText();
						} else if (text == 'stackGroup') {
							stackGroup = parser.getText();
						} else if (text == 'switchRole') {
							switchRole = parser.getText();
						} else {
							// System.debug(LoggingLevel.WARN, 'InstallPlan consuming unrecognized property: '+text);
							consumeObject(parser);
						}
					}
				}
			}
		}
	}
	
	
	public static NetworkDesign parse(String json) {
		System.JSONParser parser = System.JSON.createParser(json);
		return new NetworkDesign(parser);
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

    private static List<InstallPlan> arrayOfInstallPlan(System.JSONParser p) {
        List<InstallPlan> res = new List<InstallPlan>();
        if (p.getCurrentToken() == null) p.nextToken();
        while (p.nextToken() != System.JSONToken.END_ARRAY) {
            res.add(new InstallPlan(p));
        }
        return res;
    }

    private static List<String> arrayOfString(System.JSONParser p) {
        List<String> res = new List<String>();
        if (p.getCurrentToken() == null) p.nextToken();
        while (p.nextToken() != System.JSONToken.END_ARRAY) {
            res.add(p.getText());
        }
        return res;
    }
}