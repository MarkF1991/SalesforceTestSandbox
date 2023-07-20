/**
* @author Kamal Lamgade (kamal.lamgade@n4l.co.nz)
* @date 2021-07-12
* @installer selected for a Design to be reflected on the linked Salesforce Onboarding Case(#MNTC-520)
* CHANGE LOG
**/
public with sharing class ServiceEventNDQInstallerAssigned {
    public enum Status { INPROGRESS, COMPLETED }
    public ServiceEventWrapper event; 

    public ServiceEventNDQInstallerAssigned(ServiceEventWrapper event) {
        InstallerAssignedQueueable job = new InstallerAssignedQueueable(event);
        this.event = event;
        System.enqueueJob(job); 
    }

    public class InstallerAssignedQueueable implements Queueable {
        public Case onBoardingCase;
        public ServiceEventNDWrapper networkDesign;
        public ServiceEventWrapper event;
        public ServiceEventNDQController.Mode mode { get;set; }
        public Task task;  
        
        public InstallerAssignedQueueable(ServiceEventWrapper event) {
            ServiceEventWrapper.Data_NetworkDesign data = (ServiceEventWrapper.Data_NetworkDesign) event.data;
            this.networkDesign = data.networkDesign;
            this.event = event;
        }

        public void execute(QueueableContext context) {
            onBoardingCase = getCaseById(this.networkDesign.salesforceCaseId);
            if(onBoardingCase != null) {
                Account provider = getProvider(this.networkDesign.implementation.salesforceProviderId);
                onBoardingCase.Install_Provider__c = provider.Id;
                update onBoardingCase;
                onBoardingCase = getCaseById(this.networkDesign.salesforceCaseId);
                task = getTaskByType('Assign Installer', onBoardingCase.Id);
                task.Status = ServiceEventNDQInstallerAssigned.Status.COMPLETED.name();
                update task;
            }
        }  
    }

        public static Case getCaseById(String caseId) {
            List<Case> cases = [ SELECT Id, Status, Install_Provider__c  FROM Case WHERE Id = :caseId];
            if(cases.size() == 0){
                return null;
            } else {
                return cases[0];
            }
        }

        public static Account getProvider(String providerUuid) {
            List<Account> providers = [ SELECT Id, Name  FROM Account WHERE uuid__c = :providerUuid];
            if(providers.size() == 0){
                return null;
            }
            return providers[0];
        }

        public static Task getTaskByType(String taskType, String caseId) {
            List<Task> tasks = [ SELECT Id, Status, WhatId FROM Task WHERE Type = :taskType AND WhatId = :caseId];
            if(tasks.size() == 0){
                return null;
            } else {
                return tasks[0];
            }
        }
}