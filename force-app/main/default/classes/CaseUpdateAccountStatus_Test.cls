/**
 * CaseUpdateAccountStatus_Test.cls
 * Tests for the CaseUpdateAccountStatus class.
 * @author Logan Moore (Trineo)
 */
@isTest
private class CaseUpdateAccountStatus_Test {

/*
Requirements:

1. When a new TSO Case with status "Under Action" is created or existing status is changed
to "Under Action, If Account.School Migration Status = "4-Contract Signed" then update Account.School
Migration Status = "5-In Transition". Note:We have the plan to add more status before "Under Action",
the solution need to continue work after new status added.

2. When TSO Case.TCNZ Work Stream Status is updated to "CLNE Installed with Service Configuration",
If Account.School Migration Status = "5-In Transition" then update Account.School Migration
Status = "6-Connected". Note: The TSO Case.TCNZ Work Stream Status is updated by a work floww when
TCNZ Service Order Completed Date is entered.

3.When TSO Case Status is changed to "Service Activated", if Account.School Migration Status = "6-Connected",
then update Account.School Migration Status = "7-In Use"
*/

  /**
   * Requirement: 1
   * @author Logan Moore (Trineo)

  @isTest static void newTSOCase_StatusUnderAction() {
    // setup test
    Account a = TestObjectFactoryTSO.getAccount(true, 'Test Account', '4-Contract Signed');
    a = [SELECT School_Migration_Status__c FROM Account WHERE Id = :a.Id];
    System.assertEquals('4-Contract Signed', a.School_Migration_Status__c);
    // perform test
    Test.startTest();
    Case c = TestObjectFactoryTSO.getCase(true, a.Id, 'TSO Case', 'Under Action', 'Basic Only', null);
    Test.stopTest();
    // perform assertions
    a = [SELECT School_Migration_Status__c FROM Account WHERE Id = :a.Id];
    System.assertEquals('5-In Transition', a.School_Migration_Status__c);
  }
   */
  /**
   * Requirement: 1
   * @author Logan Moore (Trineo)
   
  @isTest static void updateTSOCase_StatusUnderAction() {
    // setup test
    Account a = TestObjectFactoryTSO.getAccount(true, 'Test Account', '4-Contract Signed');
    Case c = TestObjectFactoryTSO.getCase(true, a.Id, 'TSO Case', 'Not Under Action', null);
    a = [SELECT School_Migration_Status__c FROM Account WHERE Id = :a.Id];
    System.assertEquals('4-Contract Signed', a.School_Migration_Status__c);
    // perform test
    Test.startTest();
    c.Status = 'Under Action';
    update c;
    Test.stopTest();
    // perform assertions
    a = [SELECT School_Migration_Status__c FROM Account WHERE Id = :a.Id];
    System.assertEquals('5-In Transition', a.School_Migration_Status__c);
  }
*/
  /**
   * Requirement: 2
   * @author Logan Moore (Trineo)
  @isTest static void newTSOCase_WorkStreamStatus() {
    // setup test
    Account a = TestObjectFactoryTSO.getAccount(true, 'Test Account', '5-In Transition');
    a = [SELECT School_Migration_Status__c FROM Account WHERE Id = :a.Id];
    System.assertEquals('5-In Transition', a.School_Migration_Status__c);
    // perform test
    Test.startTest();
    Case c = TestObjectFactoryTSO.getCase(true, a.Id, 'TSO Case', 'Not Tested', 'CLNE Installed with Service Configuration', 'Basic Only');
    Test.stopTest();
    // perform assertions
    a = [SELECT School_Migration_Status__c FROM Account WHERE Id = :a.Id];
    System.assertEquals('6-Connected', a.School_Migration_Status__c);
  }
*/
  /**
   * Requirement: 2
   * @author Logan Moore (Trineo)
  @isTest static void updateTSOCase_WorkStreamStatus() {
    // setup test
    Account a = TestObjectFactoryTSO.getAccount(true, 'Test Account', '5-In Transition');
    Case c = TestObjectFactoryTSO.getCase(true, a.Id, 'TSO Case', 'Not Tested', 'Not CLNE Installed with Service Configuration','Basic Only');
    a = [SELECT School_Migration_Status__c FROM Account WHERE Id = :a.Id];
    System.assertEquals('5-In Transition', a.School_Migration_Status__c);
    // perform test
    Test.startTest();
    c.TCNZ_Work_Stream_Status__c = 'CLNE Installed with Service Configuration';
    c.TCNZ_Service_Order_Completed_Date__c = Date.today();
    update c;
    Test.stopTest();
    // perform assertions
    a = [SELECT School_Migration_Status__c FROM Account WHERE Id = :a.Id];
    System.assertEquals('6-Connected', a.School_Migration_Status__c);
  }
*/
  /**
   * Requirement: 3
   * @author Logan Moore (Trineo)
  @isTest static void newTSOCase_StatusServiceActivated() {
    // setup test
    Account a = TestObjectFactoryTSO.getAccount(true, 'Test Account', '6-Connected');
    a = [SELECT School_Migration_Status__c FROM Account WHERE Id = :a.Id];
    System.assertEquals('6-Connected', a.School_Migration_Status__c);
    // perform test
    Test.startTest();
    Case c = TestObjectFactoryTSO.getCase(true, a.Id, 'TSO Case', 'Service Activated','Basic Only', null);
    Test.stopTest();
    // perform assertions
    a = [SELECT School_Migration_Status__c FROM Account WHERE Id = :a.Id];
    System.assertEquals('7-In Use', a.School_Migration_Status__c);
  }
   */
  /**
   * Requirement: 3
   * @author Logan Moore (Trineo)
  @isTest static void updateTSOCase_StatusServiceActivated() {
    // setup test
    Account a = TestObjectFactoryTSO.getAccount(true, 'Test Account', '6-Connected');
    Case c = TestObjectFactoryTSO.getCase(true, a.Id, 'TSO Case', 'Not Service Activated','Basic Only', null);
    a = [SELECT School_Migration_Status__c FROM Account WHERE Id = :a.Id];
    System.assertEquals('6-Connected', a.School_Migration_Status__c);
    // perform test
    Test.startTest();
    c.Status = 'Service Activated';
    //c.Cutover_Date_Actual__c = Date.today();
    c.Cutover_Date_Actual__c = datetime.now();
    update c;
    Test.stopTest();
    // perform assertions
    a = [SELECT School_Migration_Status__c FROM Account WHERE Id = :a.Id];
    System.assertEquals('7-In Use', a.School_Migration_Status__c);
  }
   */

  /**
   * Bug. Deleting a case threw exception. Assert that the exception is fixed.
   * @author Logan Moore (Trineo)
   */
  @isTest static void caseDeletion() {
    // setup test
    Account a = TestObjectFactoryTSO.getAccount(true, 'Test Account', '6-Connected');
    Case c = TestObjectFactoryTSO.getCase(true, a.Id, 'TSO Case', 'Not Service Activated','Basic Only', null);
    // perform test
    Test.startTest();
    delete c;
    Test.stopTest();
  }
}