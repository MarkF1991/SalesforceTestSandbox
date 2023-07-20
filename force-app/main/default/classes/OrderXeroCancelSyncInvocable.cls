/**
* @author Alvin Aquino (aaquino@deloitte.com)
* @date 3rd June 2020
* @description Invocable action to trigger integration with Xero to cancel Purchase Order 
*
* CHANGE LOG
**/
public with sharing class OrderXeroCancelSyncInvocable {
    
    /**
    *   @author Alvin Aquino (aaquino@deloitte.com)
    *   @description For a given set of Purchase Order IDs, send them to Xero
    **/
    @InvocableMethod(label='Cancel Xero Purchase Order' description='Cancels the Purchase Order in Xero')
    public static void cancelPurchaseOrdersInXero(List<Order> orders) { 

        for (Order order :orders) {

            if (String.isNotBlank(order.Xero_Id__c)) {
                // Send to Xero
                cancelOrderInXeroAsync(order.Id);
            }
        }
    }

    @future(callout=true)
    public static void cancelOrderInXeroAsync(Id orderId) {

        XeroAPI.sendPurchaseOrder(orderId, true);
    }

}