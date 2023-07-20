/**
* @author Ben Soh (ben.soh@n4l.co.nz)
* @date 2021-02-19
* @description  to chain Queueable Apex jobs:  Update Task 
*               this class should be able to cover actions with similar minor processes:
                    Hold, 	
                    PeerReview,
                    PeerReject,
                    SchoolReject,
                    InstallerReject,
                    financialreview,
                    financialreject
* CHANGE LOG
**/

public inherited sharing class ServiceEventNDQMinorAction extends ServiceEventNDQ {
    public ServiceEventNDQController.Mode mode {get;set;} 

    public ServiceEventNDQMinorAction(ServiceEventWrapper event, ServiceEventNDQController.Mode mode ) {
        super(event);
        this.mode = mode;

        //get school record
        this.onboardingData.getAccount(this.data.networkDesign.schoolId, 'school');

        //validation
        if(!this.onboardingData.errorMessages.isEmpty()){
            this.trackServiceEvent(this.onboardingData.getErrorMessage(), 400, this.onboardingData.onboardingCase.id);
            return;
        }

        if(!Test.isRunningTest()){ //to prevent unit test failure: System.AsyncException: Maximum stack depth has been reached.  
            system.enqueueJob(new queue_UpdateTasks(this, PrepareInputTasks(mode, this.onboardingData.onboardingCase.id)));
        }
    }
    
    //use a task variable to pass parameters into the queuable job. This allows us to extend the code if we add new custom fields for task 
    public static List<Task> PrepareInputTasks(ServiceEventNDQController.Mode mode, Id whatId){ 
        List<Task> inputTasks = new List<Task>();
        switch on mode {
            //FINANCIALREJECT has 2 tasks to update
            when FINANCIALREJECT{
                inputTasks.add(new Task(
                    WhatId = whatId,
                    RecordTypeId = Helper.getRecordTypeId(Schema.SObjectType.Task, 'Onboarding'),
                    Type = 'Design',
                    Status = 'In Progress'
                ));
                inputTasks.add(new Task(
                    WhatId = whatId,
                    RecordTypeId = Helper.getRecordTypeId(Schema.SObjectType.Task, 'Onboarding'),
                    Type = 'Design Financial Approval',
                    Status = 'Deferred'
                ));
            }

            //every other action only has 1 task to update
            when else {
                Task inputTask = new Task(
                    WhatId = whatId,
                    RecordTypeId = Helper.getRecordTypeId(Schema.SObjectType.Task, 'Onboarding')
                );
                //map Task Type and Status based on mode (Action)
                inputTask =  MapTaskTypeAndStatus(inputTask, mode);
                inputTasks.add(inputTask);
            }
        }
        
        return inputTasks;
    }

    public static Task MapTaskTypeAndStatus(Task task, ServiceEventNDQController.Mode mode){
        switch on mode {
            when HOLD{
                task.Type = 'Design';
                task.Status = 'Deferred';
            }
            when PEERREVIEW{
                task.Type = 'Design';
                task.Status = 'In Peer Review';
            }
            when PEERREJECT{
                task.Type = 'Design';
                task.Status = 'In Progress';
            }
            when SCHOOLREJECT{
                task.Type = 'Design';
                task.Status = 'In Progress';
            }
            when INSTALLERREJECT{
                task.Type = 'Design';
                task.Status = 'In Progress';
            }
            when FINANCIALREVIEW{
                task.Type = 'Design';
                task.Status = 'Completed';
            }
            when ASSIGNINSTALLER{
                task.Type = 'Assign Installer';
                task.Status = 'In Progress';
            }
        }
        
        return task;
    } 

    //inner class - extends ServiceEventNDQ.queue_UpdateTask inner class for queuable job
    public class queue_UpdateTasks extends ServiceEventNDQ.queue_UpdateTasks {
        public queue_UpdateTasks (ServiceEventNDQMinorAction queueHandler, List<Task> input) {
            super(queueHandler, input);
        }
    }

}