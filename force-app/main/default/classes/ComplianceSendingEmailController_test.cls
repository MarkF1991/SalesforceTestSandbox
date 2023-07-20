@istest
public class ComplianceSendingEmailController_test {
    
    @TestSetup
    
    private static void setup(){
        TestObjectFactoryForOnboarding.setupOnboardingRecordsWithOrders();
        
    }
    
    static testMethod void test_send_Compliance_Email_Method(){ 
        MethodResponse res = New MethodResponse();
        
        Test.startTest();
        string dynamicContents = 'This is test';
        string ccAddress = 'mark.fu+01@n4l.co.nz, mark.fu+01@n4l.co.nz';
        string complianceCaseStatus = 'Non-Compliant Accepted';
        Account account = [SELECT Id, Name FROM Account WHERE uuid__c = 'schoola'];
        Case testCase = [SELECT Id, accountId, contactId FROM Case WHERE accountId =: account.id limit 1];
        
        //case contact
        Contact caseContact = [SELECT id, email FROM Contact WHERE id =: testCase.contactId];
        
        res = ComplianceSendingEmailController.send_Compliance_Email_Method(testCase.Id, dynamicContents, ccAddress, complianceCaseStatus);
        
        system.assertEquals(200, res.statuscode);
        Test.stopTest();
        
    }
    
    static testMethod void Test_sendingEmail(){
        Test.startTest();
        List<ComplianceSendingEmailController.FlowInputs> flowInputs = new List<ComplianceSendingEmailController.FlowInputs>();
        ComplianceSendingEmailController.FlowInputs flowInput = new ComplianceSendingEmailController.FlowInputs();
        
        Account account = [SELECT Id, Name FROM Account WHERE uuid__c = 'schoola'];
        Case testCase = [SELECT Id, accountId, contactId FROM Case WHERE accountId =: account.id limit 1];
        
        flowInput.Ids = testCase.Id;
        flowInput.DynamicContents = 'This is test';
        flowInput.ccAddress = 'mark.fu+01@n4l.co.nz, mark.fu+01@n4l.co.nz';
        flowInput.complianceCaseStatus = 'Non-Compliant Accepted';
        flowInputs.add(flowInput);
        
        ComplianceSendingEmailController.sendingEmail(flowInputs);
        
        
        Test.stopTest();
    }
}