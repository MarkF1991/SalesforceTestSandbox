/**
* @author Ben Edwards (beedwards@deloitte.co.nz)
* @date 3rd June 2020
* @description Test class for OrderXeroCancelSyncInvocable
*
* CHANGE LOG
**/
@isTest 
public class OrderXeroCancelSyncInvocableTest {
    
    @TestSetup
    static void makeData(){
        
        Order testOrder = TestClassUtility.createOrderAndRelatedData();
        testOrder.Xero_Id__c = 'ABC123';
        update testOrder;
    }

    @isTest 
    static void testCancelPurchaseOrdersInXero() {

        Order testOrder = [SELECT Xero_Id__c FROM Order];

        // Set the Mock Class
        Test.setMock(HttpCalloutMock.class, TestClassUtility.setStaticMock(200, 'XeroPurchaseOrderMock'));

        Test.startTest();

        OrderXeroCancelSyncInvocable.cancelPurchaseOrdersInXero(new List<Order>{testOrder});

        Test.stopTest();

    }   
}