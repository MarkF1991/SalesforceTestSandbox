/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an organization are executed whenever Apex code is deployed
 * to a production organization to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production organization. In addition, all triggers must have some code coverage.
 * 
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the organization size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
@isTest
private class TriggerOnDeviceTest {

    static testMethod void myUnitTest() {
        Account a = TestObjectFactory.getAccount(true, 'Test Account', '4-Contract Signed');
        Device_Make_Model__c dmm = new Device_Make_Model__c(name='Cisco 2951',device_type__c='Router(CLNE)');
        insert dmm;
        //Select d.Status__c, d.Provision_Case__c, d.Name, d.Installed_N4L_Asset__c, d.Device_Make_Model__c, d.Customer__c From Device__c d
        Device__c d= new Device__c(name='test Device',Status__c='Proposed',Installed_N4L_Asset__c=null,Device_Make_Model__c=dmm.id,Customer__c=a.id);
        insert d;
        
        N4L_Asset_Register__c nar = new N4L_Asset_Register__c(Current_Location__c='test location',Make_Model__c=dmm.id,Status__c='Spare');
        insert nar;
        
        Test.startTest();
        d.Installed_N4L_Asset__c=nar.id;
        update d;
        Test.stopTest();
        
        System.assertEquals('In Transit',[select id,Status__c from N4L_Asset_Register__c where id=: nar.id].Status__c);
        System.assertEquals(a.name,[select id,Current_Location__c from N4L_Asset_Register__c where id=: nar.id].Current_Location__c);
        
        
    }
}