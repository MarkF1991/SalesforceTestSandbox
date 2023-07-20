/**
* @author Ben Soh (ben.soh@n4l.co.nz)
* @date 2021-01-15
* @description to chain Queueable Apex jobs: update Case and 'Design' Task
* CHANGE LOG
**/
public with sharing class ServiceEventNDQLink extends ServiceEventNDQ {
    public ServiceEventNDQLink(ServiceEventWrapper event) {
        super(event);
        //system.enqueueJob(new queue_UpdateCase(this, super.onboardingData, super.data));
        if(!Test.isRunningTest()){ //to prevent unit test failure: System.AsyncException: Maximum stack depth has been reached.  
            system.enqueueJob(new queue_UpdateCase(this));
        }
    }

    //inner class for queuable job
    public class queue_UpdateCase implements Queueable {
        Private ServiceEventNDQLink queueHandler;
        Private ServiceEventNDQ.OnboardingData onboardingData;
        Private ServiceEventWrapper.Data_NetworkDesign data;
        
        public queue_UpdateCase(ServiceEventNDQLink queueHandler){
        //public queue_UpdateCase(ServiceEventNDQLink queueHandler, ServiceEventNDQ.OnboardingData onboardingData, ServiceEventWrapper.Data_NetworkDesign data){
            this.queueHandler = queueHandler;
            this.onboardingData = queueHandler.onboardingData;
            this.data = queueHandler.data;
        }

        public void execute(QueueableContext context) {
            //Step 1 - update case
            execute_UpdateCase();
            
            //Step 2 - update task
            //use a task variable to pass parameters into the queuable job. This allows us to extend the code if we add new custom fields for task 
            Task inputTask = new Task(
                WhatId = this.onboardingData.onboardingCase.id,
                OwnerId = this.onboardingData.onboardingCase.OwnerId,
                RecordTypeId = Helper.getRecordTypeId(Schema.SObjectType.Task, 'Onboarding'),
                type = 'Design',
                Status = 'In Progress'
            );
            if(!Test.isRunningTest()){ //to prevent unit test failure: System.AsyncException: Maximum stack depth has been reached.  
                system.enqueueJob(new queue_UpdateTask(this.queueHandler, inputTask));//chain queuable job
            }
            
        }

        public void execute_UpdateCase(){
            this.onboardingData.getUser(this.data.networkDesign.assignedTo, 'assignedTo');

            if(this.onboardingData.errorMessages.isEmpty()){
                try{
                    this.onboardingData.onboardingCase.uuid__c = this.data.networkDesign.caseId;
                    this.onboardingData.onboardingCase.Design_Id__c = this.data.networkDesign.x_id;
                    this.onboardingData.onboardingCase.Status = 'Under Action';
                    this.onboardingData.onboardingCase.OwnerId = this.onboardingData.designAssignedTo.Id;
            
                
                    update this.onboardingData.onboardingCase;
                } catch (System.Exception e) {
                    this.queueHandler.trackServiceEvent(e, 400, this.onboardingData.onboardingCase.id);
                }
            
            } else {
                this.queueHandler.trackServiceEvent(this.onboardingData.getErrorMessage(), 400, this.onboardingData.onboardingCase.id);
            }
        }

    }

    //inner class - extends ServiceEventNDQ.queue_UpdateTask inner class for queuable job
    public class queue_UpdateTask extends ServiceEventNDQ.queue_UpdateTask {
        public queue_UpdateTask (ServiceEventNDQLink queueHandler, Task input) {
            super(queueHandler, input);
        }
    }

}