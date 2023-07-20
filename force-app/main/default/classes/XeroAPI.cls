/**
* @author Ben Edwards (beedwards@deloitte.co.nz)
* @date 29th May 2020
* @description Handle calls to the Xero API
*
* CHANGE LOG
* 8 July 2020 - Patrick Lorilla (plorilla@deloitte.co.nz) Added the account code and tracking mapping logic. 
* 9 July 2020 - Patrick Lorilla (plorilla@deloitte.co.nz) Added additional fields to be populated.
**/
public with sharing class XeroAPI {
    
    /**
*   @author Ben Edwards (beedwards@deloitte.co.nz)
*   @description Send a Salesforce Account to Xero
**/
    public static Account sendAccount (Id accountId) {
        
        return sendAccount(accountId, true);
    }
    
    /**
*   @author Ben Edwards (beedwards@deloitte.co.nz)
*   @description Send a Salesforce Account to Xero
**/
    public static Account sendAccount (Id accountId, Boolean doDml) {
        
        return sendAccount([
            SELECT 
            Id  
            , Name 
            , Xero_Id__c
            , BillingStreet
            , BillingCity
            , BillingState
            , BillingPostalCode
            , BillingCountry
            , ShippingStreet
            , ShippingCity
            , ShippingState
            , ShippingPostalCode
            , ShippingCountry
            , Phone 
            , Fax 
            , (SELECT FirstName, LastName, Email FROM Contacts LIMIT 1)
            FROM  
            Account  
            WHERE 
            Id = :accountId
        ], 
                           doDml
                          );
    }
    
    /**
*   @author Ben Edwards (beedwards@deloitte.co.nz)
*   @description Send a Salesforce Account to Xero
**/
    public static Account sendAccount (Account account, Boolean doDml) {
        
        // Generate a new account for updating
        // As updating existing account with all fields queried was causing issues
        Account accountForUpdate = new Account(Id = account.Id);
        
        try {
            
            // Send the Contact to Xero
            HttpResponse response = XeroCalloutService.executeCallout('POST', 'Contacts', new XeroContact(account).serialize());
            
            // Determine if message was successfully sent
            Boolean isSuccess = response.getStatusCode() < 300;
            
            // 401 errors are in a different format
            // So need to process in a different way
            if (response.getStatusCode() == 401) {
                
                accountForUpdate.Xero_Error__c = XeroUtils.process401Error(response.getBody());
            }
            else { 
                
                // Cast back to a Xero Contact
                String jsonSerialized = XeroUtils.generateJsonStringForParsing(response.getBody(), isSuccess ? 'Contacts' : 'Elements');
                
                // Now serialise the response
                List<XeroContact> xeroContacts = (List<XeroContact>) JSON.deserialize(jsonSerialized, List<XeroContact>.class);
                
                // If success
                if (isSuccess) {
                    
                    // Save values back to the account
                    accountForUpdate.Xero_Id__c = xeroContacts[0].ContactID;
                    accountForUpdate.Xero_Error__c = null;
                }
                // else, process the error
                else {
                    
                    // Store the error
                    accountForUpdate.Xero_Error__c = response.getStatusCode() + ': ' + response.getStatus() + '\n';
                    
                    if (xeroContacts[0].ValidationErrors != null && !xeroContacts[0].ValidationErrors.isEmpty()) {
                        accountForUpdate.Xero_Error__c += XeroValidationError.processValidationErrors(xeroContacts[0].ValidationErrors);
                    }
                }
            }
        }
        catch (Exception ex) {
            
            system.debug('### Error from Xero: ' + ex.getMessage() + '\n\n' + ex.getStackTraceString());
            
            accountForUpdate.Xero_Error__c = ex.getMessage() + '\n\n' + ex.getStackTraceString();
        }
        
        if (doDml) {
            
            update accountForUpdate;
        }
        
        return accountForUpdate;
    }
    
    /**
*   @author Ben Edwards (beedwards@deloitte.co.nz)
*   @description Send a Salesforce Purchase ORder to Xero as an Purchase Order
**/
    public static Order sendPurchaseOrder (Id orderId) {
        //if(Helper.isSandbox() && !Test.isRunningTest()){ //Only run this hijack when in sandbox and not during unit test
        //   return XeroZZZZXeroAPI.sendPurchaseOrder(orderId, false); //added by Ben Soh to hijack the API, but show httpRequest instead
        //}
        
        return sendPurchaseOrder(orderId, false);
        }
        
        /**
*   @author Ben Edwards (beedwards@deloitte.co.nz)
*   @description Send a Salesforce Purchase ORder to Xero as an Purchase Order
**/
        public static Order sendPurchaseOrder (Id orderId, Boolean isCancelled) {
            
            return sendPurchaseOrder([
                SELECT 
                AccountId
                , Account.Name
                , CompanyAuthorizedById
                , CompanyAuthorizedBy.Name
                , Case__r.Programme__c
                , CreatedDate
                , Latest_Delivery_Date__c
                , OrderNumber
                , Planned_Install_Date__c
                , PoNumber
                , Provider__r.Xero_Id__c
                , Shipping_Address__c
                , Type
                , Xero_Id__c
                , Charge_To__c
                , Provider__r.Name
                , (
                    SELECT 
                    Description
                    , Discount__c 
                    , Order.Type
                    , Order.Case__r.Programme__c
                    , Product_SKU__c
                    , Product2.Description
                    , Quantity
                    , Buy_Price__c
                    FROM 
                    OrderItems
                )
                FROM  
                Order 
                WHERE 
                Id = :orderId
            ], isCancelled);
        }
        
        /**
*   @author Ben Edwards (beedwards@deloitte.co.nz)
*   @description Send a Salesforce Purchase ORder to Xero as an Purchase Order
**/
        public static Order sendPurchaseOrder (Order order, Boolean isCancelled) {
            
            // If cancelled but we have no Xero ID, reutrn the order as we can't do anything
            if (isCancelled && String.isBlank(order.Xero_Id__c)) {
                return order;
            }
            
            // Instantiate the parent account with parent Xero ID
            Account parentAccount = new Account(Id = order.Provider__c, Xero_Id__c = order.Provider__r.Xero_Id__c);
            
            // Control whether or not we need ot update the parent account
            // If the account doesn't exist in Xero, we'll need to update it
            Boolean updateAccount = false;
            
            try {
                
                // If the Order's Account hasn't been synced to Xero yet, we need to sync that first
                if (String.isBlank(order.Provider__r.Xero_Id__c)) {
                    
                    // Attempt sending of the Account to 
                    parentAccount = sendAccount(order.Provider__c, false);
                    
                    // If we couldn't create the Account for some reason
                    if (String.isBlank(parentAccount.Xero_Id__c)) {
                        
                        order.Xero_Error__c = 'Could not create Purchase Order as Account could not be created:\n\n' + parentAccount.Xero_Error__c;
                        update order;
                        return order;
                    }
                    else {
                        
                        updateAccount = true;
                    }
                }
                
                // Send the Purchase Order to Xero as an Purchase Order
                HttpResponse response = XeroCalloutService.executeCallout(
                    'POST', 
                    'PurchaseOrders',
                    new XeroPurchaseOrder(order, isCancelled).serialize()
                );
                
                // Determine if message was successfully sent
                Boolean isSuccess = response.getStatusCode() < 300;
                
                // 401 errors are in a different format
                // So need to process in a different way
                if (response.getStatusCode() == 401) {
                    
                    order.Xero_Error__c = XeroUtils.process401Error(response.getBody());
                }
                else {
                    
                    try {
                        
                        // Cast back to a Xero Contact
                        String jsonSerialized = XeroUtils.generateJsonStringForParsing(response.getBody(), isSuccess ? 'PurchaseOrders' : 'Elements');
                        
                        // Process the JSON
                        jsonSerialized = XeroPurchaseOrder.deserialize(jsonSerialized);
                        
                        // Now serialise the response
                        XeroPurchaseOrder theXeroPurchaseOrder = (XeroPurchaseOrder) JSON.deserialize(jsonSerialized, XeroPurchaseOrder.class);
                        
                        // If success
                        if (isSuccess) {
                            
                            // Save values back to the Invoice
                            order.Xero_Id__c = theXeroPurchaseOrder.PurchaseOrderID;
                            order.PONumber = theXeroPurchaseOrder.PurchaseOrderNumber;
                            order.PoDate = System.today();
                            order.Xero_Error__c = null;
                        }
                        // else, process the error
                        else {
                            
                            // Store the error
                            order.Xero_Error__c = response.getStatusCode() + ': ' + response.getStatus() + '\n';
                            
                            if (theXeroPurchaseOrder.ValidationErrors != null && !theXeroPurchaseOrder.ValidationErrors.isEmpty()) {
                                order.Xero_Error__c += XeroValidationError.processValidationErrors(theXeroPurchaseOrder.ValidationErrors);
                            }
                        }
                    }
                    catch (Exception ex) {
                        
                        // If we fail parsing the error above, dump the full error into the error field
                        order.Xero_Error__c = response.getStatusCode() + ': ' + response.getStatus() + '\n';
                        order.Xero_Error__c += response.getBody(); 
                    }
                }
            }
            catch (Exception ex) {
                
                order.Xero_Error__c = ex.getMessage() + '\n\n' + ex.getStackTraceString();
            }
            
            update order;
            
            if (updateAccount) {
                
                update parentAccount;
            }
            
            return order;
        }
        
        
        /**
*   @author Ben Edwards (ben@edwards.nz)
*   @description Retrieve the latest Xero ID to use for the Xero Tenant ID
**/
        public static String getXeroTenantId () {
            
            // Callout to Xero to retrieve contacts
            HttpResponse response = XeroCalloutService.executeCallout('GET', 'connections'); 
            
            if (response.getStatusCode() < 300) {
                
                // Retrieve the Xero Connection
                List<XeroConnection> xeroConnections = (List<XeroConnection>) JSON.deserialize(response.getBody(), List<XeroConnection>.class);
                
                system.debug('### Latest Xero Tenant ID is:' + xeroConnections[0].tenantId);
                
                // Now serialise the response and reutrn
                return xeroConnections[0].tenantId;
            }
            else {
                
                // Throw exception
                throw new XeroApiException(
                    'Error retrieving connections: ' + response.getStatusCode() + ' - ' + response.getStatus() + '\n\n' + 
                    response.getBody()
                );
            }
        }
        
        public class XeroApiException extends Exception {}
    }