/**
* @author Ben Soh (ben.soh@n4l.co.nz)
* @date 2020-09-11
* @description to handle subsequent processes from Service Event POST Request (ServiceEventRest.cls) in order to create case.
*
* CHANGE LOG
**/
public with sharing class ServiceEventCaseController {
    public static ApiResponse ServiceRequestWebFiltering (ServiceEventWrapper event) {
        ApiResponse result = new ApiResponse();
        result.internalReferenceId = event.header.internalReferenceId;

        //casting event.data class to a data class for ServiceRequestWebFiltering
        ServiceEventWrapper.Data_ServiceRequestWebFiltering data = (ServiceEventWrapper.Data_ServiceRequestWebFiltering) event.data;

            List<Group> queues = [SELECT Id, Name FROM Group WHERE Name = 'Helpdesk Queue' LIMIT 1];
            If (queues.isEmpty()){
                result.setStatus(500);
                result.error.message = 'Could not find Id for "Helpdesk Queue" to be set as Owner of case.';
                return result;
            }

            try {
                Group queue = queues[0];
                Case newCase = new Case(
                    RecordTypeId = Helper.getRecordTypeId(Schema.SObjectType.Case, 'Service Request'),
                    Subject = data.subject,
                    Description = data.description,
                    AccountId = data.accountId,
                    ContactId = data.contactId,
                    Status = 'New',
                    Product__c = 'MNttS - Safe & Secure Internet',
                    Call_Driver__c = 'Firewall configuration',
                    Origin = 'School Reporting',
                    Priority = 'Unclassified',
                    //SuppliedEmail = null, //leave blank - so that it does not trigger sending a generic notification email
                    uuid__c = event.header.internalReferenceId,
                    OwnerId = queue.Id 
                );
                insert newCase;
                UpdateCaseOwner(newCase.Id, queue.Id); //update owner using future method, to overwrite the default owner of Mark Fielding here.
                result.setStatus(200);
                result.setRecord(newCase.Id);
                
            } catch (Exception e) {
                result.setErrorMessage(e,500);//display as internal error
                result.record = null;
            }

            return result;
    }

    @future() //had to use future method to update Case owner in order to avoid triggering Case Assignment Rule. This Case Assignment Rule will fail and it caused the case owner default to Mark Fielding
    public static void UpdateCaseOwner (String caseId, String ownerId) {
        Case thisCase = [SELECT Id, OwnerId FROM Case WHERE id =: caseId LIMIT 1];
        thisCase.ownerId = ownerId;
        update  thisCase;
    }
}