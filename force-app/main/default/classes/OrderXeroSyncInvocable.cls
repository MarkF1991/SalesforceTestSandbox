/**
* @author Ben Edwards (beedwards@deloitte.co.nz)
* @date 29th May 2020
* @description Invocable action to trigger integration with Xero 
*
* CHANGE LOG
**/
public with sharing class OrderXeroSyncInvocable {
    
    /**
    *   @author Ben Edwards (aaquino@deloitte.com)
    *   @description For a given set of Purchase Order IDs, send them to Xero
    **/
    @InvocableMethod(label='Sync Order to Xero' description='Takes a given order ID and syncs to Xero')
    public static List<Output> sendPurchaseOrdersToXero(List<Id> orderIds) { 

        List<Output> outputs = new List<Output>();

        for (Id orderId :orderIds) {

            // Send to Xero
            Order order = XeroAPI.sendPurchaseOrder(orderId);
            
            // Return output
            outputs.add(new Output(
                order.Xero_Id__c, 
                order.PONumber,  
                String.isBlank(order.Xero_Error__c),
                order.Xero_Error__c
            )); 
        }

        return outputs;
    }

    public class Output {

		@InvocableVariable(label='Xero Id')
        public String xeroId;
        
        @InvocableVariable(label='PO Number')
        public String poNumber;

        @InvocableVariable(label='Is Success')
        public Boolean isSuccess;

        @InvocableVariable(label='Error Message')
        public String error;

        public Output() {}
        
        public Output(String xeroId, String poNumber, Boolean isSuccess, String error) {
            this.xeroid = xeroid;
            this.poNumber = poNumber;
            this.isSuccess = isSuccess;
            this.error = error;
        }
    }

}