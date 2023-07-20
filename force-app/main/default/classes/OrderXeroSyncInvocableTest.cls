/**
* @author Ben Edwards (beedwards@deloitte.co.nz)
* @date 29th May 2020
* @description Test class for OrderXeroSyncInvocable
*
* CHANGE LOG
**/
@isTest 
public class OrderXeroSyncInvocableTest {

    @TestSetup
    static void makeData(){
        
        TestClassUtility.createOrderAndRelatedData();
    }

    @isTest 
    static void testSendPurchaseOrdersToXero() {

        Order testOrder = [SELECT Id FROM Order];

        String xeroEndpoint = 'callout:Xero/api.xro/2.0';

        // Set the Mock Classes for the multiple callouts
        // Love this feature!
        Test.setMock(HttpCalloutMock.class, TestClassUtility.setMultiStaticMock(new Map<String, String>{
            xeroEndpoint + '/Contacts'  => 'XeroContactMock',
            xeroEndpoint + '/PurchaseOrders' => 'XeroPurchaseOrderMock'
        }));

        Test.startTest();

        OrderXeroSyncInvocable.sendPurchaseOrdersToXero(new List<Id>{testOrder.Id});

        Test.stopTest();

        // Assert Xero Id loaded against order.
        system.assertNotEquals(
            null, 
            [SELECT Xero_Id__c FROM Order].Xero_Id__c,
            'Xero ID should be loaded against the Order.'  
        );
    }   
    
}