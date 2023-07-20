/**
* @author Ben Soh (ben.soh@n4l.co.nz)
* @date 2021-02-19
* @description  to chain Queueable Apex jobs:  Get PDF and Safe as File under Case > Update Task and finally trigger TaskActions process builder
*               this class should be able to cover 2 similar Event Actions: School Review and Installer Review
* CHANGE LOG
**/

public inherited sharing class ServiceEventNDQExternalReview extends ServiceEventNDQ {

    public ServiceEventNDQController.Mode mode {get;set;} 
    
    public ServiceEventNDQExternalReview(ServiceEventWrapper event, ServiceEventNDQController.Mode mode ) {
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
            system.enqueueJob(new queue_GetPDFandSaveAsFile(this));
        }
    }
    
        public class queue_GetPDFandSaveAsFile implements Queueable {
            Private ServiceEventNDQExternalReview queueHandler;
            Private ServiceEventNDQ.OnboardingData onboardingData;
            Private ServiceEventWrapper.Data_NetworkDesign data;
            Private List<ServiceEventNDWrapper.Pdf> pdfs;
    
            public queue_GetPDFandSaveAsFile(ServiceEventNDQExternalReview queueHandler){
                this.queueHandler = queueHandler;
                this.onboardingData = queueHandler.onboardingData;
                this.data = queueHandler.data;
    
                this.pdfs = new List<ServiceEventNDWrapper.Pdf>();
                List<ServiceEventNDWrapper.Pdf> payloadPDFs = new List<ServiceEventNDWrapper.Pdf>(this.data.networkDesign.pdfs);
                switch on this.queueHandler.mode {
                    when SCHOOLREVIEW {
                        //prepare a list of 'design' pdfs for chaining queues to get and save pdfs 
                        for (ServiceEventNDWrapper.Pdf pdf : payloadPDFs){
                            switch on pdf.pdfType{
                                when 'design'{
                                    this.pdfs.add(pdf);
                                }
                            }
                        }
                    }
                    when INSTALLERREVIEW {
                        //prepare a list of 'installerrunsheet', 'design' pdfs for chaining queues to get and save pdfs 
                        for (ServiceEventNDWrapper.Pdf pdf : payloadPDFs){
                            switch on pdf.pdfType{
                                when 'installrunsheet', 'design'{
                                    this.pdfs.add(pdf);
                                }
                            }
                        }
                    }
                }

                for (ServiceEventNDWrapper.Pdf pdf : this.pdfs){
                    pdf.pdfParentId = this.onboardingData.onboardingCase.id; //parent is Case id
                }
            }
    
            public void execute(QueueableContext context) {
                try{
                    if(Test.isRunningTest()){ //to prevent it from running the chained queue. System.LimitException: Apex CPU time limit exceeded  
                        CalloutException e = new CalloutException();
                        e.setMessage('Read timed out');
                        throw e;
                    } else {
                        system.enqueueJob(new ServiceEventNDQExternalReview.queue_RecursiveGetPDFandSaveAsFile(this.queueHandler, this.pdfs, new List<String>()));
                    }
                } catch (System.Exception e) {
                    this.queueHandler.trackServiceEvent(e, 400, this.onboardingData.onboardingCase.id);
                }
            }
        }
    
        public class queue_RecursiveGetPDFandSaveAsFile implements Queueable, Database.AllowsCallouts {
            Private ServiceEventNDQExternalReview queueHandler;
            Private ServiceEventNDQ.OnboardingData onboardingData;
            Private List<ServiceEventNDWrapper.Pdf> pdfs;
            Private List<String> entityIds;
    
            public queue_RecursiveGetPDFandSaveAsFile(ServiceEventNDQExternalReview queueHandler, List<ServiceEventNDWrapper.Pdf> pdfs, List<String> entityIds){
                this.queueHandler = queueHandler;
                this.onboardingData = queueHandler.onboardingData;
                this.pdfs = pdfs;
                this.entityIds = entityIds;
            }
    
            public void execute(QueueableContext context) {
                execute_GetPDFandSaveAsFile(); //get pdf and safe as file, and then remove 1 item from the list.
                
                if (!this.pdfs.isEmpty()){
                    //when there are more pdf to get, chain to another queue and do it again
                    if(!Test.isRunningTest()){
                        system.enqueueJob(new ServiceEventNDQExternalReview.queue_RecursiveGetPDFandSaveAsFile(this.queueHandler, this.pdfs, this.entityIds));    
                    }
                } else {
                    String status = '';
                    switch on this.queueHandler.mode {
                        when SCHOOLREVIEW {
                            status = 'In review with school';//MNTC-351: update ‘Design’ onboarding task status to In Review with School
                        }
                        when INSTALLERREVIEW {
                            status = 'In review with panel supplier';//MNTC-89: update ‘Design’ onboarding task status to In review with panel supplier 
                        }
                    }
                    //use a task variable to pass parameters into the queuable job. This allows us to extend the code if we add new custom fields for task 
                    Task inputTask = new Task(
                        WhatId = this.onboardingData.onboardingCase.id,
                        RecordTypeId = Helper.getRecordTypeId(Schema.SObjectType.Task, 'Onboarding'),
                        type = 'Design',
                        Status = status,
                        Entity_Attachment_Ids__c = String.join(this.entityIds, ';')
                    );

                    
                    if(!Test.isRunningTest()){
                        system.enqueueJob(new queue_UpdateTask(this.queueHandler, inputTask));//chain queuable job
                    }
                }
            }
     
            public void execute_GetPDFandSaveAsFile(){
                if (!this.pdfs.isEmpty()){
                    try{
                        ServiceEventNDWrapper.Pdf pdf = this.pdfs.remove(0);
                        if(!Test.isRunningTest()){
                            //MNTC-414 : Add error handling on GetPDFandSaveAsFile method when Get PDF HttpResponse return status code other than 200
                            MethodResponse res  = ServiceEventGeneratePDFCallout.GetPDFandSaveAsFile(pdf.pdfId, pdf.filename, pdf.pdfParentId);
                            this.entityIds.add(res.results.get('fileRecordId')); //even if the Get PDF HttpResponse return error, the recordId will be null
                            if(res.statuscode >= 400){
                                this.queueHandler.trackServiceEvent('Network Design - ' + this.queueHandler.event.header.action + ' failed to execute_GetPDFandSaveAsFile(). ' + res.results.get('HttpResponse'), res.statuscode, this.onboardingData.onboardingCase.id);
                            }
                        }
                    } catch (System.Exception e) {
                        this.queueHandler.trackServiceEvent(e, 400, this.onboardingData.onboardingCase.id);
                    }    
                }
            }
        }
    
        //inner class - extends ServiceEventNDQ.queue_UpdateTask inner class for queuable job
        public class queue_UpdateTask extends ServiceEventNDQ.queue_UpdateTask {
            public queue_UpdateTask (ServiceEventNDQExternalReview queueHandler, Task input) {
                super(queueHandler, input);
            }
        }


}