/**
* @author Ben Edwards (beedwards@deloitte.co.nz)
* @date 29th May 2020
* @description Wrapper class for serialising and de-serialising Xero Purchase ORders
*
* CHANGE LOG
* 8 July 2020 - Patrick Lorilla (plorilla@deloitte.co.nz) Added the account code and tracking mapping logic. 
* 9 July 2020 - Patrick Lorilla (plorilla@deloitte.co.nz) Added additional fields to be populated.
* 29 Oct 2020 - Ben Soh (ben.soh@n4l.co.nz) added Account Name on Reference field (NP-1372)
* 30 Oct 2020 - Ben Soh (ben.soh@n4l.co.nz) modified Xero Account Code mapping to use integer formatted string for 'discount' part
**/
public class XeroPurchaseOrder {
    
    public String PurchaseOrderID;  //44d3f8a4-7031-45e8-b252-e92914e43c7e
    public String PurchaseOrderNumber;  //PO-0001
    public String Date_x;
    public String DeliveryDateString;   //2017-02-22T00:00:00
    public String DeliveryDate; ///Date(1487721600000+0000)/
    public String DeliveryAddress;  //23 Main Street
    public String AttentionTo;  //FOH
    public String Telephone;    //0800 1234 5678
    public String DeliveryInstructions; //Deliver to reception. As agreed, table needs to be assembled prior to delivery.
    public Boolean IsDiscounted;
    public String Reference;    //710
    public String Type; //PURCHASEORDER
    public Decimal CurrencyRate;    //1
    public String CurrencyCode; //NZD
    public String BrandingThemeID;  //7889a0ac-262a-40e3-8a63-9a769b1a18af
    public String Status;   //BILLED
    public String LineAmountTypes;  //Exclusive
    public Boolean SentToContact;
    public Decimal SubTotal;    //1000
    public Decimal TotalTax;    //150
    public Decimal Total;   //1150
    public String UpdatedDateUTC;   ///Date(1385147725247+0000)/
    public String Url;  ///Date(1385147725247+0000)/
    public List<XeroValidationError> ValidationErrors;

    public XeroContact Contact;
    public List<LineItem> LineItems;
      
    public class LineItem {
        public String LineItemID;   //1aa3bf00-a5fe-420f-b4b3-d64349a13108
        public String Description;  //Coffee table for reception
        public Decimal UnitAmount;  //1000
        public String TaxType;  //INPUT2
        public Decimal TaxAmount;   //150
        public Decimal LineAmount;  //1000
        public Decimal Quantity;    //1
        public String AccountCode;
        public List<Tracking> Tracking;
        
        public LineItem(OrderItem poLine) {

            // Build the description
            this.Description = 
                (String.isNotBlank(poLine.Product_SKU__c) ? poLine.Product_SKU__c + ' - ' : '' ) + 
                (String.isNotBlank(poLine.Description) ? poLine.Description : poLine.Product2.Description);
            
            this.UnitAmount = poLine.Buy_Price__c;
            this.Quantity = poLine.Quantity;
            this.TaxType = 'INPUT2';

            // Retrieve the account code mapping
            Xero_Purchase_Order_Account_Mapping__mdt accountCodeMapping = this.getAccountCodeMappingForPoLine(poLine);

            // Add account code and tracking if we've found
            if (accountCodeMapping != null) {
                this.AccountCode = accountCodeMapping.Account_Code__c;
                this.Tracking = new List<Tracking>{
                    new Tracking('Cost Center', accountCodeMapping.Tracking_Cost_Centre__c), //Actual spelling in Xero production environment is "Cost Center" not "Cost Centre"
                    new Tracking('Project', accountCodeMapping.Tracking_Project__c)
                };
            }
        } 

        // Retrieve the Xero Account Code mapping for the line
        public Xero_Purchase_Order_Account_Mapping__mdt getAccountCodeMappingForPoLine (OrderItem poLine) {

            // Build the key
            String key = getAccountCodeKey(
                poLine.Order.Case__r.Programme__c,
                poLine.Order.Type,
                poLine.Discount__c == null ? '0' : String.valueOf(Integer.valueOf(poLine.Discount__c))
            );

            if (xeroAccountCodeMappings.containsKey(key)) {

                return xeroAccountCodeMappings.get(key);
            }

            return null;
        }
    }

    public class Tracking {

        public String Name;
        public String Option;

        public Tracking (String name, String option) {
           
            this.Name = name;
            this.Option = option;
        }
    }
    
    public XeroPurchaseOrder(Order order, Boolean isCancel) {

        // Set Purchase Order variables
        this.PurchaseOrderID = order.Xero_Id__c;
        this.Reference = order.OrderNumber + ' - ' + order.Account.Name;
        this.AttentionTo = order.CompanyAuthorizedBy.Name;
        this.DeliveryAddress = order.Shipping_Address__c;
        //this.Contact = new XeroContact(order.Provider__r.Xero_Id__c);
        this.Contact = new XeroContact(ChargeToXeroId(order));
        this.Status = isCancel ? 'DELETED' : Label.Xero_Purchase_Order_Status;
        this.LineAmountTypes = 'Exclusive';
        this.DeliveryInstructions = order.Account.Name  ;
        this.SentToContact = true;
        
        // Set the date
        this.DeliveryDate = 
            (order.Type == 'SOW - Installer' || order.Type == 'SOW - ICT') ?
                String.valueOf(order.Planned_Install_Date__c) :
                String.valueof(order.Latest_Delivery_Date__c);

        this.Date_x = String.valueOf(order.CreatedDate);
        this.Url = System.URL.getSalesforceBaseUrl().toExternalForm() + '/' + order.Id;
        
        // Generate line items
        this.LineItems = new List<LineItem>();
        for (OrderItem poLine :order.OrderItems) {
            this.LineItems.add(new LineItem(poLine));
        }
    }

    // Build a map of the Xero Account Code mappings
    public static Map<String, Xero_Purchase_Order_Account_Mapping__mdt> xeroAccountCodeMappings {
        get {
            if (xeroAccountCodeMappings == null) {
                
                xeroAccountCodeMappings = new Map<String, Xero_Purchase_Order_Account_Mapping__mdt>();

                // Query for the active mappings
                for (Xero_Purchase_Order_Account_Mapping__mdt mapping : [
                    SELECT 
                        Account_Code__c
                        , Order_Line_Discount__c
                        , Order_Type__c
                        , Programme__c
                        , Tracking_Cost_Centre__c
                        , Tracking_Project__c 
                    FROM  
                        Xero_Purchase_Order_Account_Mapping__mdt 
                    WHERE 
                        Active__c = true
                ]){

                    // Add to the map
                    xeroAccountCodeMappings.put(
                        getAccountCodeKey(
                            mapping.Programme__c,
                            mapping.Order_Type__c,
                            mapping.Order_Line_Discount__c != null ? String.valueOf(Integer.valueOf(mapping.Order_Line_Discount__c)) : ''
                        ),
                        mapping
                    );
                }
            }
            return xeroAccountCodeMappings;
        }
        set;
    }

    // Build a map of the Xero Charge To Account mappings
    public static Map<String, Xero_Charge_To_Account_Mapping__mdt> XeroChargeToAccountMapping {
        get {
            if (XeroChargeToAccountMapping == null) {
                
                XeroChargeToAccountMapping = new Map<String, Xero_Charge_To_Account_Mapping__mdt>();

                // Query for the active mappings
                for (Xero_Charge_To_Account_Mapping__mdt mapping : [
                    SELECT 
                    Charge_To__c
                    , Provider__c
                    , Type__c
                    , Xero_Contact_Id__c
                    FROM  
                    Xero_Charge_To_Account_Mapping__mdt 
                ]){

                    // Add to the map
                    XeroChargeToAccountMapping.put(
                        Helper.concatenateKey(new List<String>{
                            mapping.Charge_To__c,
                            mapping.Provider__c,
                            mapping.Type__c
                        }),
                        mapping
                    );
                }
            }
            return XeroChargeToAccountMapping;
        }
        set;
    }
    
    //Build a method to determine what XeroId should be using
    public static String ChargeToXeroId(Order order){
        String result;
        order = [Select id, Provider__r.name, Charge_To__c, Type, Provider__r.Xero_Id__c From Order Where id =: order.Id];

            String key = Helper.concatenateKey(new List<String>{
                order.Charge_To__c,
                order.Provider__r.name,
                order.Type
            });

            if(XeroChargeToAccountMapping.containsKey(key)){
                result = XeroChargeToAccountMapping.get(key).Xero_Contact_Id__c;
            }
            else{
                result = order.Provider__r.Xero_Id__c;
            }
            return result;
    }

    // Build the key used to map the Account Codes to the PO Lines
    public static String getAccountCodeKey(String programme, String orderType, String discount) {
        return String.join(
            new List<String>{
                getStringValue(programme),
                getStringValue(orderType),
                getStringValue(discount)
            },
            '-'
        );
    }

    // Will return an empty string if a value is null
    public static String getStringValue (String value) {
        return String.isBlank(value) ? '' : value;
    }
    
    public String serialize() {
        
        // Serialise the full XeroInvoice object into a string
        String serialized = JSON.serialize(this, true);
      
        // Replace the _x with the correct format
        serialized = serialized.replace('"Date_x"', '"Date"');
         
        return serialized;
    }

    // Custom deserialize method to remove the Contact info from
    // the Purchase Order response
    public static String deserialize(String jsonBody) {

        // Cast to array based on response
        List<Object> jsonObjectArray = (List<Object>) JSON.deserializeUntyped(jsonBody);

        // Cast to map/value pair
        Map<String, Object> jsonObject = (Map<String, Object>) jsonObjectArray[0];

        // Remove the Contact object - causing all sorts of problems
        jsonObject.remove('Contact');

        // Re-serialise the string
        return JSON.serialize(jsonObject);
    }

    
}