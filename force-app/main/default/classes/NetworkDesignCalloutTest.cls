@IsTest
public class NetworkDesignCalloutTest {
//test method to get test coverage on retired class
    static testMethod void testNothing() {
        NetworkDesignCallout.doNothing();
    }
    /**Retired MARCH-2022** replaced by flow - 'N4L PSI Asset Reconciliation'***
    static testMethod void test_executeGetNetworkDesign_success(){
        Test.setMock(HttpCalloutMock.class, TestClassUtility.setStaticMock(200, 'NetworkDesignMock'));
        
        system.Test.startTest();
        
        HttpRequest request = new HttpRequest();
        HttpResponse response =  NetworkDesignCallout.executeGetNetworkDesign(1000, 1, request);
        system.assertEquals(200, response.getStatusCode());

        system.Test.stopTest();
    }

    static testMethod void test_executeGetNetworkDesign_error(){
        Test.setMock(HttpCalloutMock.class, TestClassUtility.setStaticMock(408, 'NetworkDesignMock'));
        
        system.Test.startTest();
        
        HttpRequest request = new HttpRequest();
        HttpResponse response =  NetworkDesignCallout.executeGetNetworkDesign(10, 1, request);
        system.assertEquals(408, response.getStatusCode());

        system.Test.stopTest();
       
    }

    static testMethod void test_executeGetNetworkDesign_error2(){
        Test.setMock(HttpCalloutMock.class, TestClassUtility.setStaticMock(500, 'NetworkDesignMock'));
        
        system.Test.startTest();
        
        HttpRequest request = new HttpRequest();
        HttpResponse response =  NetworkDesignCallout.executeGetNetworkDesign(20, 1, request);
        system.assertEquals(500, response.getStatusCode());

        system.Test.stopTest();
       
    }
*/
}