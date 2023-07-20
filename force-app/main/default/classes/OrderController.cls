public with sharing class OrderController {
    
    public static List<Order> listOrders(ID orderId){
        List<Order> orders = [SELECT Id, uuid__c, Status, Case__c, Type, Case__r.caseNumber, Case__r.OwnerId, Case__r.ICT_Date_onsite__c, Case__r.Cutover_Appointment__c,  Case__r.ER_Lite__c, Case__r.Phase_1_Cutover_Appointment__c, Contract.status, AccountId, 
                              Contract.ContractNumber, PoNumber, Account.NZ_Region__c, Account.MoE_External_ID__c, Order.PoDate, case__r.Case_Thread_ID__c, Account.Name, Account.ShippingAddress, Account.uuid__c, Earliest_Delivery_Date__c, Latest_Delivery_Date__c,
                              OrderNumber, OrderReferenceNumber, Xero_Id__c, Charge_To__c, Xero_Error__c, Order.Shipping_Address__c, Order.ShippingStreet, Order.ShippingCity, Order.ShippingPostalCode,  TotalAmount,               
                              Provider__r.Billing_Contact__c, Provider__r.Billing_Contact__r.FirstName, Provider__r.Billing_Contact__r.Email, Provider__r.Name, Provider__r.BillingStreet, 
                              Provider__r.BillingCity, Provider__r.BillingPostalCode, Provider__r.BillingCountry, Description, Planned_Install_Date__c FROM Order WHERE Id =: orderId];
        return orders;
    }
    
    //-----------------------------------------------------------------OrderApprover1 Start-------------------------------------------------------------------------
    @AuraEnabled() //using cacheable=true will cause error LIMIT_USAGE_FOR_NS   Number of DML statements: 1 out of 0 ******* CLOSE TO LIMIT
    public static Map<String,String> approveOrder1(ID orderId ) {
        Map<String,String> result = New Map<String,String>();
        MethodResponse res = new MethodResponse();
        
        //get order
        List<Order> orders = listOrders(orderId);
        
        //   get order error
        if(orders.isEmpty()){
            if (String.isNotBlank(orderId)){
                res.setStatus(404);
                res.setResult('error', 'Could not find a Order record with id = ' + orderId);   
            } else {
                res.setStatus(400);
                res.setResult('error', 'Missing orderId');    
            }
            result.put('response', res.getJSONstring());
            return result;
        }
        //   get order success
        Order order = orders[0];
        
        //1. Xero Integration
        
        If (String.isNotBlank(order.PONumber)){
            res.setStatus(200);
            res.setResult('Xero Integration', 'Skipped Xero Integration as there is already a PONumber for this order');
        } else {
            Order XeroOrder = XeroAPI.sendPurchaseOrder(order.Id);
            if (String.isBlank(XeroOrder.Xero_Error__c)){
                res.setStatus(200);  
                res.setResult('Xero Integration', 'Xero Integration has been completed - Xero Id = ' + XeroOrder.Xero_Id__c + ' | PO Number=' + XeroOrder.PoNumber);
            } else {
                res.setStatus(400);    
                res.setResult('Xero Integration Error', XeroOrder.Xero_Error__c);
                result.put('response', res.getJSONstring());
                return result; 
            }
            
        }
        
        //temporary debug
        orders = listOrders(orderId);
        order = orders[0];
        system.System.debug('order in part1 immediately after xero integration , order.PoNumber:' + order.PoNumber);
        
        
        result.put('response', res.getJSONstring());
        return result; 
    }
    //-----------------------------------------------------------------OrderApprover1 End---------------------------------------------------------------------------
    
    //-----------------------------------------------------------------OrderApprover2 Start-------------------------------------------------------------------------
    @AuraEnabled() //using cacheable=true will cause error LIMIT_USAGE_FOR_NS   Number of DML statements: 1 out of 0 ******* CLOSE TO LIMIT
    public static Map<String,String> approveOrder2(ID orderId ) {
        Map<String,String> result = New Map<String,String>();
        MethodResponse res = new MethodResponse();
        
        //get order
        List<Order> orders = listOrders(orderId);
        //get order error
        if(orders.isEmpty()){
            if (String.isNotBlank(orderId)){
                res.setStatus(404);
                res.setResult('error', 'Could not find a Order record with id = ' + orderId);   
            } else {
                res.setStatus(400);
                res.setResult('error', 'Missing orderId');    
            }
            result.put('response', res.getJSONstring());
            return result;
        }
        //   get order success
        Order order = orders[0];
        system.System.debug('order in part2 beginning, order.PoNumber:' + order.PoNumber);
        
        /**Retired MARCH-2022** replaced by flow - 'N4L PSI Asset Reconciliation' */
        //2. Network Design 
        //If (order.Type == 'Equipment - New' && !string.Isblank(order.uuid__c)){
        //   MethodResponse res2 = NetworkDesignController.getNetworkDesign(order);
        //res2.setStatus(200);//for unit test at early stage
        //MethodResponse res2 = NetworkDesignController.getNetworkDesign(order.uuid__c);
        //within that NetworkDesignController.getNetworkDesign method, do a few things:
        //2.1 Make a API callout  NetworkDesignController.requestNetworkDesign(order.uuid__c)
        //2.2 with the body from 2.1, validate the network design: NetworkDesignController.validateNetworkDesign 
        //2.3 passing the validation  in 2.2, and the body from 2.1, upsert the locations and network design data in NetworkDesignController.processNetworkDesign
        
        // if (res2.statuscode == 200){
        //   res.setStatus(res2.statuscode);
        //   res.appendResult(res2.results);
        //} else if (res2.statuscode >= 400){
        //    res.setStatus(res2.statuscode);
        //   res.appendResult(res2.results);
        //   result.put('response', res.getJSONstring());
        //  return result; 
        // }
        //}
        
        //3. Send Purchase Order Email
        
        //3.1 get latest order records before sending email
        orders = listOrders(orderId);
        order = orders[0]; 
        
        List<OrderItem> orderItems = [select Id, OrderId from OrderItem where OrderId =: order.Id];
        
        if(orderItems.isEmpty()){
            res.setStatus(400);
            res.setResult('Sending Purchase Order', 'Order must have a product' );
            result.put('response', res.getJSONstring());
            return result;
        }
        
        if(order.PoNumber == null){
            res.setStatus(400);
            res.setResult('Sending Purchase Order', 'Order must have a valid PO Number' );
            result.put('response', res.getJSONstring());
            return result;
        }
        
        if(order.PoDate == null){
            res.setStatus(400);
            res.setResult('Sending Purchase Order', 'Order must have a valid PO Date' );
            result.put('response', res.getJSONstring());
            return result;
        }
        
        MethodResponse res3 = new MethodResponse();
        //added software on 2nd of Sep. 2020
        if (order.Type == 'Equipment - New' || order.Type == 'Equipment - RMA' || order.Type == 'Equipment - DOA' || order.Type.contains('Software') || order.Type == 'Equipment - Equipment Only' || order.Type == 'Complex Mac'){
            res3 = PurchaseOrderEquipment(order);
        }
        else if (order.Type.contains('SOW') || order.Type =='Variation'){
            res3 = PurchaseOrderInstaller(order);
        }
        
        
        res.setStatus(res3.statuscode);
        res.appendResult(res3.results);
        
        if(res.statuscode >= 400){
            result.put('response', res.getJSONstring());
            return result;
        }
        
        //3.2 update order status to 'Activated'
        try {
            order.Status = 'Activated';
            update order;
            res.setStatus(200);
            res.setResult('Order Activation', 'Successfully activated the order');
        } catch (System.Exception ex) {
            res.setStatus(400);
            res.setResult('Order Activation', 'OrderController.approveOrder Exception during activating this order' );
            res.setResult('Order Activation error(s)', ex.getMessage());
            
            result.put('response', res.getJSONstring());
            return result;
        }
        
        result.put('response', res.getJSONstring());
        return result; 
    }
    //-----------------------------------------------------------------OrderApprover2 End---------------------------------------------------------------------------
    
    
    //-----------------------------------------------------------------CancelOrder Start--------------------------------------------
    @AuraEnabled() 
    public static Map<String,String> cancelOrder(Id orderId){
        Map<String,String> result = New Map<String,String>();
        MethodResponse res = new MethodResponse();
        List<Order> orders = listOrders(orderId);
        Order order = orders[0]; 
        
        If (String.isNotBlank(order.PONumber)){
            Order XeroOrder = XeroAPI.sendPurchaseOrder(orderId, true);
            
            if (String.isBlank(XeroOrder.Xero_Error__c)){
                res.setStatus(200);    
                order.Status = 'Cancelled';
                update order;
                
                res.setResult('Xero Integration', 'Xero Integration PO cancellation has been completed - Xero Id = ' + XeroOrder.Xero_Id__c + ' | PO Number=' + XeroOrder.PoNumber);
            } else {
                res.setStatus(400);    
                res.setResult('Xero Integration PO cancellation Error', XeroOrder.Xero_Error__c);
                result.put('response', res.getJSONstring());
                return result; 
            }
        }
        result.put('response', res.getJSONstring());
        return result; 
    }
    //-----------------------------------------------------------------CancelOrder End----------------------------------------------      
    
    public static MethodResponse PurchaseOrderEquipment(Order order){
        MethodResponse res = new MethodResponse();
        List<OrderItem> orderItemList = new List<OrderItem>();
        
        // fetch Data using SOQL from Salesforce       
        orderItemList = [SELECT
                         Order.PoNumber,
                         Order.PoDate,
                         Order.Case__r.case_Thread_ID__c,
                         Order.Case__r.caseNumber,
                         Order.Contract.ContractNumber,
                         Order.OrderNumber,
                         Order.OrderReferenceNumber,
                         Order.Account.MoE_External_ID__c,
                         Order.Account.Name,
                         Order.ShippingStreet,
                         Order.ShippingCity,
                         Order.ShippingPostalCode,
                         Order.Case__r.Contact.FirstName,
                         Order.Case__r.Contact.LastName,
                         Order.Case__r.ContactMobile,
                         Order.Case__r.ContactEmail,
                         Order.Earliest_Delivery_Date__c,
                         Order.Latest_Delivery_Date__c,
                         Order.Allow_Part_Shipment__c,
                         Order.Urgent_Delivery_Required__c,
                         Order.Description,
                         Order.ReturnTo__r.Name,
                         Order.ReturnTo__r.ShippingStreet,
                         Order.ReturnTo__r.ShippingCity,
                         Order.ReturnTo__r.ShippingPostalCode,
                         Product2.StockKeepingUnit,
                         Description,
                         Quantity,
                         UnitPrice,
                         Discount__c
                         FROM OrderItem
                         WHERE OrderId =: order.Id];
        
        //Set Header values of the file
        
        string csvHeader = 'PO Number, PO Date, Case Thread ID, Case, Contract Number, Order Number, Account Id, Account Name, Order Shipping Street, Order Shipping City, Order Shipping ZIP/Postal Code, Order Contact First Name, Order Contact Last Name, Order Contact Phone, Order Contact Email, Earliest Delivery Date, Latest Delivery Date, Allow Part Shipment, Urgent Delivery Required, Order Description, Relinquished Equipment Return to, Returns Street Address, Returns Street City, Returns Address Zip/Postal Code, SKU, Line Reference, Quantity, Unit Price, Charge To \n';
        
        string mainContent = csvHeader;
        string recordString = '';
        
        String chargeToValue = GetChargeToCode(order.Charge_To__c); //get Exeed Charge To code based on Order's Charge To picklist value
        String poDate = helper.formatNZdate(order.PoDate);
        String earliestDeliveryDate = helper.formatNZdate(order.Earliest_Delivery_Date__c);
        String latestDeliveryDate = helper.formatNZdate(order.Latest_Delivery_Date__c);
        
        try {
            
            for (OrderItem orderItem: orderItemList){ 
                //Make False as 0 and True as 1
                String AllowPartShipment = string.valueOf(orderItem.Order.Allow_Part_Shipment__c==True?1:0);
                String UrgentDeliveryRequired = string.valueOf(orderItem.Order.Urgent_Delivery_Required__c==True?1:0);
                
                //Adding records in a string           
                recordString = '"' + orderItem.Order.PoNumber + '" , "' +
                    poDate + '" , "' +
                    orderItem.Order.Case__r.case_Thread_ID__c + '" , "' +
                    orderItem.Order.Case__r.caseNumber + '" , "' +
                    orderItem.Order.Contract.ContractNumber + '" , "' +
                    orderItem.Order.OrderNumber + '" , "' +
                    orderItem.Order.Account.MoE_External_ID__c + '" , "' +
                    orderItem.Order.Account.Name + '" , "' +
                    orderItem.Order.ShippingStreet + '" , "' +
                    orderItem.Order.ShippingCity + '" , "' +
                    orderItem.Order.ShippingPostalCode + '" , "' +
                    orderItem.Order.Case__r.Contact.FirstName + '" , "' +
                    orderItem.Order.Case__r.Contact.LastName + '" , "' +
                    orderItem.Order.Case__r.ContactMobile + '" , "' +
                    orderItem.Order.Case__r.ContactEmail + '" , "' +
                    earliestDeliveryDate + '" , "' +
                    latestDeliveryDate + '" , "' +
                    AllowPartShipment + '" , "' +
                    UrgentDeliveryRequired + '" , "' +
                    orderItem.Order.Description + '" , "' +
                    orderItem.Order.ReturnTo__r.Name + '" , "' +
                    orderItem.Order.ReturnTo__r.ShippingStreet + '" , "' +
                    orderItem.Order.ReturnTo__r.ShippingCity + '" , "' +
                    orderItem.Order.ReturnTo__r.ShippingPostalCode + '" , "' +
                    orderItem.Product2.StockKeepingUnit + '" , "' +
                    orderItem.Description + '" , "' +
                    orderItem.Quantity + '" , "' +
                    orderItem.UnitPrice + '" , "' +
                    chargeToValue  +'" \n';
                
                
                
                mainContent += recordString.replace('null',' ');
            }
            
            
            
            String whoId = order.Provider__r.Billing_Contact__c;
            String whatId = order.Case__c;
            //Equipment_Purchase_Order_0412_Springdale.csv 
            String accountName = order.Account.Name;
            accountName = accountName.replace(' ', '_');
            String subject = 'Equipment_Purchase_Order' + '_' + Helper.getStringValue(order.PoNumber) + '_' + accountName + '.csv'; 
            
            //get Email Template Name based on MetaData - Email Template Mapping
            String masterLabel = ('purchase order equipment').toLowerCase();
            MethodResponse res2 = EmailController.getEmailTemplateByMasterLabel(masterLabel);
            EmailTemplate emailTemplate = res2.emailTemplate; //dto in res
            OrgWideEmailAddress orgWideEmailAddress = res2.orgWideEmailAddress; //dto in res
            
            String htmlBody = emailTemplate.HtmlValue;
            htmlBody = htmlBody.replace('[Latest Delivery Date]', latestDeliveryDate);
            
            String plainBody = emailTemplate.Body;
            plainBody = plainBody.replace('[Latest Delivery Date]', latestDeliveryDate);
            
            
            //prepare CSV file
            String csvString = mainContent;
            // ---------------------- SFT-112 new approach using email.setEntityAttachments to include files as attachments in email) -----------------------
            List<Id> fileIdsToAttach = new List<Id>();
            Map<Id, ContentVersion> createdCSVFile = FileController.createNewFiles(new List<String>{subject},new List<String>{csvString},whatId,'InternalUsers','V',false,null);
            fileIdsToAttach.addAll(createdCSVFile.Keyset()); //get the Id of the CSV file created and add to fileIdsToAttach variable.
            // ---------------------- SFT-112 new approach using email.setEntityAttachments to include files as attachments in email) -----------------------
            
            /* //commented out for SFT-112 as email.setFileAttachments (approach using attachments) is replace email.setEntityAttachments (approach using files)
Messaging.EmailFileAttachment csvAttachment = prepareCSVAttachment(subject, csvString );

List<Messaging.EmailFileAttachment> attachments = new List<Messaging.EmailFileAttachment>();        
if (csvAttachment != null) {    
attachments.add(csvAttachment);
}
*/
            
            //toAddresses
            List<String> toAddresses = new List<String>();
            
            if(String.isNotBlank(order.Provider__r.Billing_Contact__r.Email)) toAddresses.add(order.Provider__r.Billing_Contact__r.Email); //add designated contact's email to address
            
            //ccAddresses - no cc required, but leave it as empty list
            List<String> ccAddresses = new List<String>();
            
            Messaging.Singleemailmessage email = EmailController.constructEmail2(whoId, whatId, emailTemplate, toAddresses, ccAddresses, htmlBody, plainBody, orgWideEmailAddress);
            
            //email.setFileAttachments(attachments);  
            email.setEntityAttachments(fileIdsToAttach); //attach all the file ids to be sent into email.
            email.setSubject(subject);
            
            Messaging.sendEmail(new Messaging.SingleEmailmessage[] {email});
            
            res.setStatus(200);
            res.setResult('Sending Purchase Order', 'Successfully sent Equipment Purchase Order to ' + string.join(toAddresses,','));
            
        }
        catch (System.Exception ex){
            res.setStatus(400);
            res.setResult('Sending Purchase Order', 'Failed to send Equipment Purchase Order');
            res.setResult('Sending Purchase Order', ex.getMessage() + ex.getStackTraceString());
            //system.debug('Try Catch error:' + ex.getMessage());
        }
        return res;
    }
    
    //------------------------------------------------------------------Second Method---------------------------------------------------------------------------------------//
    
    public static MethodResponse PurchaseOrderInstaller(Order order){
        MethodResponse res = new MethodResponse();
        
        List<OrderItem> orderItemList = new List<OrderItem>();
        // fetch Data using SOQL from Salesforce
        
        orderItemList = [SELECT
                         Order.PoNumber,
                         Order.PoDate,
                         Order.Case__r.case_Thread_ID__c,
                         Order.Case__r.caseNumber,
                         Order.Contract.ContractNumber,
                         Order.OrderNumber,
                         Order.Account.MoE_External_ID__c,
                         Order.Account.Name,
                         Order.ShippingStreet,
                         Order.ShippingCity,
                         Order.ShippingPostalCode,
                         Order.Planned_Install_Date__c,
                         Order.Case__r.Cutover_Appointment__c,
                         Order.Case__r.ICT_Date_onsite__c,
                         Product2.ProductCode,
                         Product2.Description,
                         OrderItem.Quantity,
                         OrderItem.Description,
                         Product2.QuantityUnitOfMeasure,
                         OrderItem.UnitPrice,
                         OrderItem.TotalPrice
                         FROM OrderItem
                         where OrderId =: order.id];
        
        //Set Header values of the file
        string csvHeader = 'PO Number, PO Date, Case Thread ID, Case, Contract Number, Order Number, School ID, School Name, Install Address Street, Install Address City, Install Address Postcode, Scheduled Installation, Product Code, Product Description, Quantity, UOM, Unit Price, Total Price \n';
        
        string mainContent = csvHeader;
        string recordString = '';
        
        String poDate = helper.formatNZdate(order.PoDate);
        String plannedInstallDate = helper.formatNZdate(order.Planned_Install_Date__c);
        
        for (OrderItem orderItem: orderItemList){
            //Adding records in a string          
            recordString = '"' + orderItem.Order.PoNumber + '" , "' +
                poDate + '" , "' +
                orderItem.Order.Case__r.case_Thread_ID__c + '" , "' +
                orderItem.Order.Case__r.caseNumber + '" , "' +
                orderItem.Order.Contract.ContractNumber + '" , "' +
                orderItem.Order.OrderNumber + '" , "' +
                orderItem.Order.Account.MoE_External_ID__c + '" , "' +
                orderItem.Order.Account.Name + '" , "' +
                orderItem.Order.ShippingStreet + '" , "' +
                orderItem.Order.ShippingCity + '" , "' +
                orderItem.Order.ShippingPostalCode + '" , "' +
                plannedInstallDate + '" , "' +
                orderItem.Product2.ProductCode + '" , "' +
                orderItem.Product2.Description + '" , "' +
                OrderItem.Quantity + '" , "' +
                orderItem.Product2.QuantityUnitOfMeasure + '" , "' +
                OrderItem.UnitPrice + '" , "' +
                OrderItem.TotalPrice +'" \n';
            
            mainContent += recordString.replace('null',' ');
        }
        
        
        try {                    
            String whoId = order.Provider__r.Billing_Contact__c;
            String whatId = order.Case__c;
            String accountName = order.Account.Name;
            String orderType = Helper.getStringValue(order.Type);
            accountName = accountName.replace(' ', '_');
            orderType = orderType.replace(' ','');
            String subject = orderType + '_' + order.PoNumber + '_' + accountName + '.csv';
            
            //get Email Template Name based on MetaData - Email Template Mapping
            String masterLabel = ('purchase order sow').toLowerCase();
            MethodResponse res2 = EmailController.getEmailTemplateByMasterLabel(masterLabel);
            EmailTemplate emailTemplate = res2.emailTemplate; //dto in res
            OrgWideEmailAddress orgWideEmailAddress = res2.orgWideEmailAddress; //dto in res
            
            String htmlBody = emailTemplate.HtmlValue;
            String htmltableScopeofWork = '';
            
            //----------------------------------------------------------------HTML Table Start-----------------------------------------------------------------------------------------------------------------
            //SFB-133
            For (OrderItem orderItem : orderItemList){
                htmltableScopeofWork += '<tr style="vertical-align:top">';
                htmltableScopeofWork += '<td style="width:40%; padding-bottom:10px"><span>' + (orderItem.Description == null ? Helper.getStringValue(orderItem.Product2.Description) : Helper.getStringValue(orderItem.Description)) + '</span></td>';
                htmltableScopeofWork += '<td style="width: 10%; text-align: right;"><span>' + orderItem.Quantity.format() + '</span></td>';
                htmltableScopeofWork += '<td style="width: 10%; text-align: right;"><span>' + (orderItem.Product2.QuantityUnitOfMeasure == null ? '' : orderItem.Product2.QuantityUnitOfMeasure) + '</span></td>';
                htmltableScopeofWork += '<td style="width: 15%; text-align: right;"><span>' + Helper.currency(orderItem.UnitPrice) + '</span></td>';
                htmltableScopeofWork += '<td style="width: 15%; text-align: right;"><span>' + Helper.currency(orderItem.TotalPrice) + '</span></td>';
                htmltableScopeofWork += '</tr>';
            }
            
            //---------------------------------------------------------------HTML Table End--------------------------------------------------------------------------------------------------------------------
            htmlBody = htmlBody.replace('[ProviderContactFirstName]', Helper.getStringValue(order.Provider__r.Billing_Contact__r.FirstName)); 
            htmlBody = htmlBody.replace('[ProviderName]', Helper.getStringValue(order.Provider__r.Name)); 
            htmlBody = htmlBody.replace('[ProviderAddressLine1]', Helper.getStringValue(order.Provider__r.BillingStreet));
            htmlBody = htmlBody.replace('[ProviderAddressLine2]', Helper.getStringValue(order.Provider__r.BillingCity) + ' ' + Helper.getStringValue(order.Provider__r.BillingPostalCode));
            htmlBody = htmlBody.replace('[ProviderAddressLine3]', Helper.getStringValue(order.Provider__r.BillingCountry));
            htmlBody = htmlBody.replace('[OrderPoNumber]', Helper.getStringValue(Order.PoNumber));
            htmlBody = htmlBody.replace('[OrderPoDate]', Helper.formatNZdate(Order.PoDate));
            htmlBody = htmlBody.replace('[SchoolId]', Helper.getStringValue(Order.Account.MoE_External_ID__c));
            htmlBody = htmlBody.replace('[SchoolName]', Helper.getStringValue(Order.Account.Name));
            htmlBody = htmlBody.replace('[InstallAddressStreet]', Helper.getStringValue(Order.ShippingStreet));
            htmlBody = htmlBody.replace('[InstallAddressCity]', Helper.getStringValue(Order.ShippingCity));
            htmlBody = htmlBody.replace('[InstallAddressPostCode]', Helper.getStringValue(Order.ShippingPostalCode));
            htmlBody = htmlBody.replace('[OrderNumber]', Helper.getStringValue(Order.OrderNumber));
            htmlBody = htmlBody.replace('[CaseNumber]', Helper.getStringValue(Order.Case__r.CaseNumber));
            htmlBody = htmlBody.replace('{!Case.Case_Thread_ID__c}', Helper.getStringValue(Order.Case__r.Case_Thread_ID__c));
            htmlBody = htmlBody.replace('[ContractNumber]', Helper.getStringValue(Order.Contract.ContractNumber));
            htmlBody = htmlBody.replace('[SubTotal]', Helper.currency(Order.TotalAmount)); //format decimal to 12,345.67
            htmlBody = htmlBody.replace('[Tax]', Helper.currency((Order.TotalAmount * 0.15))); //format decimal to 12,345.67
            htmlBody = htmlBody.replace('[Total]', Helper.currency((Order.TotalAmount * 1.15))); //format decimal to 12,345.67            
            htmlBody = htmlBody.replace('[htmltableScopeofWork]', htmltableScopeofWork); //relate to contract's school name
            htmlBody = htmlBody.replace('[SchoolRegion]', Helper.getStringValue(Order.Account.NZ_Region__c));
            htmlBody = htmlBody.replace('[SchoolAddress]', Helper.getStringValue(Order.Shipping_Address__c));
            //Job Date And Time
            if(order.Type == 'SOW - Installer') {
                //Edit by Carolyn Hayward (Micado) Aug-2022 Job date must be Phase 1 Cutover date for ER Lite
                //MNTC-1278 https://n4lconz.atlassian.net/browse/MNTC-1278
                if(order.Case__r.ER_Lite__c) {
                    htmlBody = htmlBody.replace('[JobDateTime]', helper.formatNZdatetime(Order.Case__r.Phase_1_Cutover_Appointment__c));
                } else {
                    htmlBody = htmlBody.replace('[JobDateTime]', helper.formatNZdatetime(Order.Case__r.Cutover_Appointment__c));
                }
            }
            Else if(order.Type == 'SOW - ICT' || order.Type == 'SOW 1 - ICT'|| order.Type == 'SOW 2 - ICT'|| order.Type == 'Variation' || order.Type == 'Complex MAC' || order.Type == 'Equipment - Equipment Only') {
                htmlBody = htmlBody.replace('[JobDateTime]', helper.formatNZdatetime(Order.Case__r.ICT_Date_onsite__c));
            }
            
            String plainBody = emailTemplate.Body;
            plainBody = plainBody.replace('[ProviderContactFirstName]', Helper.getStringValue(order.Provider__r.Billing_Contact__r.FirstName)); 
            plainBody = plainBody.replace('[ProviderName]', Helper.getStringValue(order.Provider__r.Name));
            plainBody = plainBody.replace('[SchoolName]', Helper.getStringValue(Order.Account.Name));
            
            List<Messaging.EmailFileAttachment> attachments = new List<Messaging.EmailFileAttachment>();    
            
            //prepare CSV           
            String csvString = mainContent;
            // ---------------------- SFT-112 new approach using email.setEntityAttachments to include files as attachments in email) -----------------------
            List<Id> fileIdsToAttach = new List<Id>();
            Map<Id, ContentVersion> createdCSVFile = FileController.createNewFiles(new List<String>{subject},new List<String>{csvString},whatId,'InternalUsers','V',false,null);
            fileIdsToAttach.addAll(createdCSVFile.Keyset()); //get the Id of the CSV file created and add to fileIdsToAttach variable.
            
            //retrieve PDF files from related Contract.
            Map<Id, sObject> existingFilesOnContract = new Map<Id, sObject>();
            if(order.Type == 'SOW - Installer') {
                existingFilesOnContract = FileController.getAttachmentOrFileIds(order.ContractId, new List<String>{'%Network Design%','%Install Run Sheet%'},'Both');
            }
            else if(order.Type == 'SOW - ICT'|| order.Type == 'SOW 1 - ICT'|| order.Type == 'SOW 2 - ICT'|| order.Type == 'Variation') {
                existingFilesOnContract = FileController.getAttachmentOrFileIds(order.ContractId, new List<String>{'%Network Design%','%Migration Run Sheet%'},'Both');
            }
            fileIdsToAttach.addAll(existingFilesOnContract.KeySet());
            system.debug('>>>> there should be 2 pdfAttachments.size: ' + fileIdsToAttach);  
            // ---------------------- SFT-112 new approach using email.setEntityAttachments to include files as attachments in email) -----------------------
            
            /* //commented out for SFT-112 as email.setFileAttachments (approach using attachments) is replace email.setEntityAttachments (approach using files)
Messaging.EmailFileAttachment csvAttachment = prepareCSVAttachment(subject, csvString);

//Insert ContentVersion
ContentVersion cVersion = new ContentVersion();
cVersion.ContentLocation = 'S'; //S-Document is in Salesforce. E-Document is outside of Salesforce. L-Document is on a Social Netork.
cVersion.PathOnClient = subject;//File name with extention
cVersion.Origin = 'C';//C-Content Origin. H-Chatter Origin.
cVersion.Title = subject;//Name of the file
cVersion.VersionData = Blob.valueOf(csvString);//File content
Insert cVersion;

//After saved the Content Verison, get the ContentDocumentId
Id conDocument = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =:cVersion.Id].ContentDocumentId;

//Insert ContentDocumentLink
ContentDocumentLink cDocLink = new ContentDocumentLink();
cDocLink.ContentDocumentId = conDocument;//Add ContentDocumentId
cDocLink.LinkedEntityId = order.ContractId;//Add attachment parentId
//cDocLink.ShareType = 'V';//V - Viewer permission. C - Collaborator permission. I - Inferred permission.
//cDocLink.Visibility = 'AllUsers';//AllUsers, InternalUsers, SharedUsers
Insert cDocLink;

if (csvAttachment != null) {                 
attachments.add(csvAttachment);

}
system.debug('>>>> 1 attachments.size: ' + attachments.size());

//Prepare PDF
List<Id> contentDocumentIds = new List<Id>();
List<ContentDocumentLink> contentDocumentLinks = [SELECT ContentDocumentID FROM ContentDocumentLink WHERE LinkedEntityId =: order.ContractId];
if(!contentDocumentLinks.isEmpty()){
For (ContentDocumentLink contentDocumentLink : contentDocumentLinks){
contentDocumentIds.add(contentDocumentLink.ContentDocumentID); //ContentDocumentID is not Id. They have different value.
}

if(order.Type == 'SOW - Installer') {
List<Messaging.EmailFileAttachment> pdfAttachments = prepareFileAttachmentsForInstaller(contentDocumentIds);
system.debug('>>>> there should be 2 pdfAttachments.size: ' + pdfAttachments.size()); 

for (Messaging.EmailFileAttachment pdfattachment : pdfAttachments ){
attachments.add(pdfAttachment);
}
}
else if(order.Type == 'SOW - ICT') {
List<Messaging.EmailFileAttachment> pdfAttachments = prepareFileAttachmentsForICT(contentDocumentIds);
system.debug('>>>> there should be 2 pdfAttachments.size: ' + pdfAttachments.size());   

for (Messaging.EmailFileAttachment pdfattachment : pdfAttachments ){
attachments.add(pdfAttachment);
}

}               

//attachments.addAll(pdfAttachments);
system.debug('>>>> 2 attachments.size: ' + attachments.size());    
}
*/
            
            
            //toAddresses
            List<String> toAddresses = new List<String>();
            
            if(String.isNotBlank(order.Provider__r.Billing_Contact__r.Email)) toAddresses.add(order.Provider__r.Billing_Contact__r.Email); //add designated contact's email to address
            
            //ccAddresses - no cc required, but leave it as empty list
            List<String> ccAddresses = new List<String>();
            Messaging.Singleemailmessage email = EmailController.constructEmail2(whoId, whatId, emailTemplate, toAddresses, ccAddresses, htmlBody, plainBody, orgWideEmailAddress);
            
            //email.setFileAttachments(attachments);
            email.setEntityAttachments(fileIdsToAttach); //attach all the file ids to be sent into email.   
            email.setSubject(subject);
            Messaging.sendEmail(new Messaging.SingleEmailmessage[] {email});
            
            res.setStatus(200);
            res.setResult('Sending Purchase Order', 'Successfully sent SOW Purchase Order to ' + string.join(toAddresses,','));
        }
        catch (System.Exception ex){
            res.setStatus(400);
            res.setResult('Sending Purchase Order', 'Failed to send SOW Purchase Order');
            res.setResult('Sending Purchase Order', ex.getStackTraceString());
            //system.debug('Try Catch error:' + ex.getMessage());
        }
        return res;
    }
    
    
    //Exeed Chage To
    public static String GetChargeToCode(String chargeTo){
        String result = '';
        if(String.isEmpty(chargeTo)) return result; //stop and return '' when chargeTo is empty
        
        String chargeToCodes = System.Label.Exeed_Charge_To_code;
        Map<string, string> chargeToMap = new Map<string, string>();
        
        if(!String.isBlank(chargeToCodes)){
            //prepare a map of chargeTo : Exeed Charge To Code
            for(String chargeToCode : chargeToCodes.split(';')){
                List<String> values = chargeToCode.trim().split('/');
                chargeToMap.put(values[0],values[1]);
            }
            
            if(chargeToMap.containsKey(chargeTo)){
                result = chargeToMap.get(chargeTo);
            }
        }
        return result;
    }
    
    @InvocableMethod(label='UpdateTravelTimeAndVehicleMileage')
    //SA-32 automatically calculate 'Travel Time' and 'Vehicle Mileage' in orderItem
    public static void UpdateTravelTimeAndVehicleMileage(List<ID> orderIds ) {
        //get order
        List<Order> orders = listOrders(orderIds[0]);
        Order order = orders[0];
        GetTravelTimeAndVehicleMileage(order.id);
    }
    
    @Future(callout=true)
    public static void GetTravelTimeAndVehicleMileage(ID orderId ) {
        //get order
        Order order = [SELECT Id, uuid__c, Status, Case__c, Type, Case__r.caseNumber, case__r.ICT_Implementation_Provider__r.ShippingLatitude, case__r.ICT_Implementation_Provider__r.ShippingLongitude, Case__r.ICT_Date_onsite__c, Case__r.Cutover_Appointment__c, Contract.status, Case__r.ownerId,
                       Contract.ContractNumber, PoNumber, Account.NZ_Region__c, Account.MoE_External_ID__c, Order.PoDate, case__r.Case_Thread_ID__c, Account.ShippingLatitude, Account.ShippingLongitude, Account.School_Location__c, Provider__r.School_Location__c, Provider__r.ShippingAddress, Account.Name, Account.ShippingAddress, Account.uuid__c, Earliest_Delivery_Date__c, Latest_Delivery_Date__c,
                       OrderNumber, OrderReferenceNumber, Xero_Id__c, Charge_To__c, Xero_Error__c, Order.Shipping_Address__c, Order.ShippingStreet, Order.ShippingCity, Order.ShippingPostalCode,  TotalAmount,               
                       Provider__r.Billing_Contact__c, Provider__r.Billing_Contact__r.FirstName, Provider__r.Billing_Contact__r.Email, Provider__r.Name, Provider__r.ShippingLatitude, Provider__r.ShippingLongitude, Provider__r.BillingStreet, 
                       Provider__r.BillingCity, Provider__r.BillingPostalCode, Provider__r.BillingCountry, Description, Planned_Install_Date__c FROM Order WHERE Id =: orderId];
        
        
        List<OrderItem> orderItems = [select Id, Product2Id, Quantity, OrderItem.Product2.Name, OrderId from OrderItem where OrderId =: order.Id];
        list<String> resList = new list<String>();
        String schoolAddress;
        String providerAddress;
        
        try{
            
            schoolAddress = String.valueOf(order.Account.ShippingLatitude + ',' + order.Account.ShippingLongitude);
            providerAddress = String.valueOf(order.case__r.ICT_Implementation_Provider__r.ShippingLatitude + ',' + order.case__r.ICT_Implementation_Provider__r.ShippingLongitude);
            System.debug('schoolAddress:--> ' + schoolAddress +'ProviderAddress:--> ' + providerAddress);
            
            String endpoint = 'https://maps.googleapis.com/maps/api/distancematrix/json?';
            String apiKey = 'AIzaSyCKn_oVUw58Q3JSjTbbZjryDkAUkNfM3Rc';
            HttpRequest req = new HttpRequest();
            Http http = new Http();
            
            req.setMethod('GET');
            String url = endpoint +'origins='+ schoolAddress +'&destinations='+ providerAddress +'&key='+ apikey;
            
            req.setEndPoint(url);
            HTTPResponse resp = http.send(req); 
            
            System.debug('response:--> ' + resp.getBody());
            JSONParser parser =  JSON.createParser(resp.getBody());
            System.debug('parser:--> ' + parser);
            
            while (parser.nextToken() != null) {
                if(parser.getText() == 'text') {
                    System.debug('distance'+ parser.getText());
                    system.debug('Main temp_min-->' + parser.nextValue());
                    resList.add(parser.getText());
                    system.debug('Main temp_min--> ' + parser.nextValue());
                }
            }
            system.debug(resList);
            
            //SFB-783: fix issue - System.ListException: List index out of bounds: 0
            String distance;
            String travelTime;   
            if(resList.size() > 0){
                distance  = resList[0];
                travelTime  = resList[1];
            }
            Decimal finalTravelTime;
            Decimal finalDistance;
            
            system.debug('>>>>>Size :'+travelTime.split(' ').size());
            if(travelTime.split(' ').size() >2){
                finalTravelTime = Decimal.valueOf(travelTime.split(' ')[0]) + (Decimal.valueOf(travelTime.split(' ')[2])/60).setScale(2); 
            }else{
                finalTravelTime = Decimal.valueOf(travelTime.split(' ')[0]) / 60;
            }
            
            if(distance.split(' ')[0].contains(',')){
                finalDistance = Decimal.valueOf(distance.split(' ')[0].remove(','));
            }else{
                finalDistance = Decimal.valueOf(distance.split(' ')[0]);
            }
            
            
            system.debug('>>>>>Distance :'+distance.split(' ')[0]);
            //system.debug('>>>>>Hour :'+travelTime.split(' ')[0] +'>>>>>minTOHour: '+(Decimal.valueOf(travelTime.split(' ')[2])/60).setScale(2));
            
            //Call return function
            List<Decimal> toReturnResult = GetBackTravelTimeAndVehicleMileage(order.id);
            system.debug('@@#$#!!#>>>Result: '+toReturnResult);
            
            //Calculate the quantity 
            for(OrderItem orderItem : orderItems){
                if(orderItem.Product2.Name == 'Travel time'){
                    orderItem.Quantity = finalTravelTime + toReturnResult[1];
                }
                else if(orderItem.Product2.Name == 'Vehicle mileage'){
                    orderItem.Quantity = finalDistance + toReturnResult[0];
                }
                update orderItem;
            }
            
            
        }catch(System.CalloutException e) {
            
            System.debug('Callout error: '+ e.getMessage());
        }
    }
    
    public static List<Decimal> GetBackTravelTimeAndVehicleMileage(ID orderId ) {
        //get order
        Order order = [SELECT Id, uuid__c, Status, Case__c, Type, Case__r.caseNumber, Case__r.ICT_Date_onsite__c, Case__r.Cutover_Appointment__c, Contract.status, Case__r.ownerId,
                       Contract.ContractNumber, PoNumber, Account.NZ_Region__c, Account.MoE_External_ID__c, Order.PoDate, case__r.Case_Thread_ID__c, Account.ShippingLatitude, Account.ShippingLongitude, Account.School_Location__c, Provider__r.School_Location__c, Provider__r.ShippingAddress, Account.Name, Account.ShippingAddress, Account.uuid__c, Earliest_Delivery_Date__c, Latest_Delivery_Date__c,
                       OrderNumber, OrderReferenceNumber, Xero_Id__c, Charge_To__c, Xero_Error__c, Order.Shipping_Address__c, Order.ShippingStreet, Order.ShippingCity, Order.ShippingPostalCode,  TotalAmount,               
                       Provider__r.Billing_Contact__c, Provider__r.Billing_Contact__r.FirstName, Provider__r.Billing_Contact__r.Email, Provider__r.Name, Provider__r.ShippingLatitude, Provider__r.ShippingLongitude, Provider__r.BillingStreet, 
                       Provider__r.BillingCity, Provider__r.BillingPostalCode, Provider__r.BillingCountry, Description, Planned_Install_Date__c, case__r.ICT_Implementation_Provider__r.ShippingLatitude, case__r.ICT_Implementation_Provider__r.ShippingLongitude FROM Order WHERE Id =: orderId];
        
        List<OrderItem> orderItems = [select Id, Product2Id, Quantity, OrderItem.Product2.Name, OrderId from OrderItem where OrderId =: order.Id];
        list<String> resList = new list<String>();
        List<Decimal> finalResult = new List<Decimal>();
        String schoolAddress;
        String providerAddress;
        
        try{
            
            schoolAddress = String.valueOf(order.Account.ShippingLatitude + ',' + order.Account.ShippingLongitude);
            providerAddress = String.valueOf(order.case__r.ICT_Implementation_Provider__r.ShippingLatitude + ',' + order.case__r.ICT_Implementation_Provider__r.ShippingLongitude);
            System.debug('schoolAddress:--> ' + schoolAddress +'ProviderAddress:--> ' + providerAddress);
            
            String endpoint = 'https://maps.googleapis.com/maps/api/distancematrix/json?';
            String apiKey = 'AIzaSyCKn_oVUw58Q3JSjTbbZjryDkAUkNfM3Rc';
            HttpRequest req = new HttpRequest();
            Http http = new Http();
            
            req.setMethod('GET');
            String url = endpoint +'origins='+ providerAddress +'&destinations='+ schoolAddress +'&key='+ apikey;
            
            req.setEndPoint(url);
            HTTPResponse resp = http.send(req); 
            
            System.debug('response:--> ' + resp.getBody());
            JSONParser parser =  JSON.createParser(resp.getBody());
            System.debug('parser:--> ' + parser);
            
            while (parser.nextToken() != null) {
                if(parser.getText() == 'text') {
                    System.debug('distance'+ parser.getText());
                    system.debug('Main temp_min-->' + parser.nextValue());
                    resList.add(parser.getText());
                    system.debug('Main temp_min--> ' + parser.nextValue());
                }
            }
            system.debug(resList);
            
            String distance = resList[0];
            String travelTime = resList[1];
            Decimal finalTravelTime;
            Decimal finalDistance;
            
            system.debug('>>>>>Size :'+travelTime.split(' ').size());
            if(travelTime.split(' ').size() >2){
                finalTravelTime = Decimal.valueOf(travelTime.split(' ')[0]) + (Decimal.valueOf(travelTime.split(' ')[2])/60).setScale(2); 
            }else{
                finalTravelTime = Decimal.valueOf(travelTime.split(' ')[0]) / 60;
            }
            
            if(distance.split(' ')[0].contains(',')){
                finalDistance = Decimal.valueOf(distance.split(' ')[0].remove(','));
            }else{
                finalDistance = Decimal.valueOf(distance.split(' ')[0]);
            }
            
            
            system.debug('>>>>>Distance :'+distance.split(' ')[0]);
            //system.debug('>>>>>Hour :'+travelTime.split(' ')[0] +'>>>>>minTOHour: '+(Decimal.valueOf(travelTime.split(' ')[2])/60).setScale(2));
            
            finalResult.add(finalDistance);
            finalResult.add(finalTravelTime);
            
            system.debug('>>>>>Distance: '+finalDistance+'!!!!!Time: '+finalTravelTime);
            
        }catch(System.CalloutException e) {
            
            System.debug('Callout error: '+ e.getMessage());
        }
        return finalResult;
    }
    
}