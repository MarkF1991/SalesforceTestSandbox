/**
* @author Ben Soh (ben.soh@n4l.co.nz)
* @date 2021-01-15
* @description to handle subsequent processes from Service Event POST Request (ServiceEventRest.cls) in order to create case.
* There is a limit to Apex class names, therefore use NDQ to abbreviate 'NetworkDesignQueue'
* CHANGE LOG
* 2021-02-18 MNTC-351 added routing to event.header.action = 'schoolreview'
* 2021-02-20 MNTC-89, 90 added routing to event.header.action = 'installerreview', ‘hold', 'peerreview', 'peerreject', 'schoolreject', 'installerreject', 'financialreview', 'financialreject’
**/
public with sharing class ServiceEventNDQController {
    public enum Mode {SCHOOLREVIEW, INSTALLERREVIEW, HOLD, PEERREVIEW, PEERREJECT, SCHOOLREJECT, INSTALLERREJECT, FINANCIALREVIEW, FINANCIALREJECT, ASSIGNINSTALLER, INSTALLERASSIGNED}

    public static ApiResponse NetworkDesignValidation (ServiceEventWrapper event) {
        ApiResponse result = new ApiResponse();
        result.internalReferenceId = event.header.internalReferenceId;
        
        switch on event.header.action {
            when 'link', 'approve', 'schoolreview', 'installerreview', 'hold', 'peerreview', 'peerreject', 'schoolreject', 'installerreject', 'financialreview', 'financialreject', 'assigninstaller', 'installerassigned' { 
                //casting event.data class to a data class for Data_NetworkDesign
                ServiceEventWrapper.Data_NetworkDesign data = (ServiceEventWrapper.Data_NetworkDesign) event.data;
                
                //validate data.networkDesign.salesforceCaseId from payload
                List<Case> cases = [SELECT Id, AccountId, Account.uuid__c, OwnerId, uuid__c, Design_Id__c, RecordTypeId FROM Case WHERE id =: data.networkDesign.salesforceCaseId];
                if(cases.isEmpty()){
                    result.setErrorMessage('Could not find a case with Id = ' + data.networkDesign.salesforceCaseId ,400);//display as error message
                    result.record = null;
                    return result;
                }
                //prepare response
                result.setStatus(200);
                result.setRecord(cases[0].Id);
                
                //Asynchronously run subsequent workflows for every Event Actions of Network Design
                NetworkDesignRoutingAsync(JSON.serialize(event));
            }
            when else {
                result.setStatus(200);
                result.messages = new List<String>{'event Action: "' + event.header.action + '"is not ready in Salesforce Eventing Network Design yet.'};
                result.record = null;
            }
        }
        //once validation passed, return the http response early
        return result;
    }

    @future()
    public static void NetworkDesignRoutingAsync (String jsonEvent){
        ServiceEventWrapper event = ServiceEventWrapper.parse(jsonEvent);
        ApiResponse result = new ApiResponse();
        switch on event.header.action {
            when 'link' { 
                ServiceEventNDQLink queue_NetworkDesignLink = new ServiceEventNDQLink(event);
            }
            when 'approve' { 
                ServiceEventNDQApprove queue_NetworkDesignApprove = new ServiceEventNDQApprove(event);
            }
            when 'schoolreview'{
                ServiceEventNDQExternalReview queue_NetworkDesignExternalReview = new ServiceEventNDQExternalReview(event, ServiceEventNDQController.Mode.SCHOOLREVIEW);
            }
            when 'installerreview'{
                ServiceEventNDQExternalReview queue_NetworkDesignExternalReview = new ServiceEventNDQExternalReview(event, ServiceEventNDQController.Mode.INSTALLERREVIEW);
            }
            when 'hold'{
                ServiceEventNDQMinorAction queue_ServiceEventNDQMinorAction = new ServiceEventNDQMinorAction(event, ServiceEventNDQController.Mode.HOLD);
            }
            when 'peerreview'{
                ServiceEventNDQMinorAction queue_ServiceEventNDQMinorAction = new ServiceEventNDQMinorAction(event, ServiceEventNDQController.Mode.PEERREVIEW);
            }
            when 'peerreject'{
                ServiceEventNDQMinorAction queue_ServiceEventNDQMinorAction = new ServiceEventNDQMinorAction(event, ServiceEventNDQController.Mode.PEERREJECT);
            }
            when 'schoolreject'{
                ServiceEventNDQMinorAction queue_ServiceEventNDQMinorAction = new ServiceEventNDQMinorAction(event, ServiceEventNDQController.Mode.SCHOOLREJECT);
            }
            when 'installerreject'{
                ServiceEventNDQMinorAction queue_ServiceEventNDQMinorAction = new ServiceEventNDQMinorAction(event, ServiceEventNDQController.Mode.INSTALLERREJECT);
            }
            when 'financialreview'{
                ServiceEventNDQMinorAction queue_ServiceEventNDQMinorAction = new ServiceEventNDQMinorAction(event, ServiceEventNDQController.Mode.FINANCIALREVIEW);
            }
            when 'financialreject'{
                ServiceEventNDQMinorAction queue_ServiceEventNDQMinorAction = new ServiceEventNDQMinorAction(event, ServiceEventNDQController.Mode.FINANCIALREJECT);
            }
            when 'assigninstaller'{
                ServiceEventNDQMinorAction queue_ServiceEventNDQMinorAction = new ServiceEventNDQMinorAction(event, ServiceEventNDQController.Mode.ASSIGNINSTALLER);
            }
            when 'installerassigned'{
                System.debug('insttaller assigned when');
                ServiceEventNDQInstallerAssigned queue_NetworkDesignInstallerAssigned = new ServiceEventNDQInstallerAssigned(event);
                //ServiceEventNDQMinorAction queue_ServiceEventNDQMinorAction = new ServiceEventNDQMinorAction(event, ServiceEventNDQController.Mode.INSTALLERASSIGNED);
            }        
        }
    }

    // Build the key used to map the Pricebook Charge to the separate orders MOE funded
    public static String getPricebookChargeToKey(String pricebookId, Integer discount) {
        return String.join(
            new List<String>{
                Helper.getStringValue(pricebookId),
                getChargeTo(discount)
            },
            '-'
        );
    }
    
    public static String getChargeTo (Integer value) {
        //these values must match with the picklist values in Order.Charge_To__c
        return (value == 100) ? 'MOE' : 'N4L';
    }
   
}