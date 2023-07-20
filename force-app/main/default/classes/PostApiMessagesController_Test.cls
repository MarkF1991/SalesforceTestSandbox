@isTest
public class PostApiMessagesController_Test {
    
    static testMethod void test_PostApiForSuccessMessagesController(){
        
        Test.setMock(HttpCalloutMock.class, new CalloutMock());
        
        Test.startTest();
        List<PostApiForSuccessMessagesController.FlowInputs> flowInputs = new List<PostApiForSuccessMessagesController.FlowInputs>();
        PostApiForSuccessMessagesController.FlowInputs flowInput = new PostApiForSuccessMessagesController.FlowInputs();
        flowInput.action = 'Success';
        flowInput.eventType = 'AttachFile';
        flowInput.internalReferenceId = 'addd9805-7777-48bc-9de3-48157d247f17';
        flowInput.origin = 'Salesforce';
        flowInput.Ids = '[8025P000000P77JQAS,8025P000000P77KQAS]';
        flowInputs.add(flowInput);
        
        PostApiForSuccessMessagesController.postSuccessMessageToPS_Method(flowInputs);
        Test.stopTest();
    }   
    
    static testMethod void test_PostApiForErrorMessagesController(){
        
        Test.setMock(HttpCalloutMock.class, new CalloutMock());
        
        Test.startTest();
        List<PostApiForErrorMessagesController.FlowInputs> flowInputs = new List<PostApiForErrorMessagesController.FlowInputs>();
        PostApiForErrorMessagesController.FlowInputs flowInput = new PostApiForErrorMessagesController.FlowInputs();
        flowInput.action = 'Success';
        flowInput.eventType = 'AttachFile';
        flowInput.internalReferenceId = 'addd9805-7777-48bc-9de3-48157d247f17';
        flowInput.origin = 'Salesforce';
        flowInput.Ids = '[8025P000000P77JQAS,8025P000000P77KQAS]';
        flowInput.errorMessages = 'This is an error';
        flowInputs.add(flowInput);
        
        PostApiForErrorMessagesController.postErrorMessageToPS_Method(flowInputs);
        Test.stopTest();
    }   
}