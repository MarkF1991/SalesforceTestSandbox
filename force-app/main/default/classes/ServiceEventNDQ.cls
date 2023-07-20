/**
* @author Ben Soh (ben.soh@n4l.co.nz)
* @date 2021-01-15
* @description There is a limit to Apex class names, therefore use NDQ to abbreviate 'NetworkDesignQueue' to reserve space for various Eventing Actions like "Link", "Approve", etc
* CHANGE LOG
* 2021-02-03 MNTC-333 Added value assignment to this.onboardingData.designId
* 2021-02-20 Added queue_UpdateTasks() queueable method to update multiple tasks within a queue, especially for dfarejected action.
**/
public virtual class ServiceEventNDQ {
    Public ServiceEventWrapper event;
    Public ServiceEventWrapper.Data_NetworkDesign data;
    Public OnboardingData onboardingData;
    
    //constructor
    public ServiceEventNDQ(ServiceEventWrapper event) {
        this.event = event;
        this.data = (ServiceEventWrapper.Data_NetworkDesign) event.data;

        this.onboardingData = new OnboardingData();
        this.onboardingData.designId = this.data.networkDesign.x_id;
        this.onboardingData.getOnboardingCase(this.data.networkDesign.salesforceCaseId);
    }

    public ServiceEventNDQ() {} //for unit test purpose

    //common method to handle error during queue execution
    public virtual void trackServiceEvent(ApiResponse result){
        HttpResponse response = new HttpResponse();
        response.setStatusCode(result.statuscode);
        response.setStatus(result.status);
        response.setBody(System.JSON.serialize(result));

        String recordId = '';
        if(result.record != null){
            recordId = Helper.getStringValue(result.record.Id);
        }
        ServiceEventController.createServiceEvent(this.event, response, recordId);
    }

    

    public virtual void trackServiceEvent(String message, Integer statusCode, String recordId){
        //use ApiResponse class to collect data and produce a json structure for the response 
        ApiResponse result = new ApiResponse();
        if (statusCode >= 400){
            result.setErrorMessage(message, statusCode);//display as error message
        } else {
            result.setStatus(statusCode);
            result.messages.add(message);
        }
        if(!String.isBlank(recordId)){
            result.setRecord(recordId);
        }

        ServiceEventController.updateServiceEvent_Result(this.event, result);
    }

    public virtual void trackServiceEvent(Exception e, Integer statusCode, String recordId){
        //use ApiResponse class to collect data and produce a json structure for the response 
        ApiResponse result = new ApiResponse();
        result.setErrorMessage(e, statusCode);//display as error message
        if(!String.isBlank(recordId)){
            result.setRecord(recordId);
        }
        
        ServiceEventController.updateServiceEvent_Result(this.event, result);
    }
    
    //inner class to handle common onboarding records
    public class OnboardingData {
        
        // public enum UserType {ASSIGNEDTO, APPROVER, OWNER} //Inner types are not allowed to have inner types 

        public String errorMessage = '';
        public List<String> errorMessages;
        public String designId = '';
        public User designAssignedTo = null;
        public User designApprovedBy = null;
        public User designOwner = null;
        public Account school = null;
        public Account returnTo = null;
        public Case onboardingCase = null;
        public Map<Id, Pricebook2> pricebooksMap;
        public Map<String, Pricebook2> pricebooksMapByName;
        public Map<String, PricebookEntry> pricebookProductMap;
        
        public onboardingData() {
            this.pricebooksMap = new Map<Id, Pricebook2>();
            this.pricebooksMapByName = new Map<String, Pricebook2>();
            this.pricebookProductMap = new Map<String, PricebookEntry>();
            this.errorMessages = new List<String>();
        }
        
        public void getOnboardingCase(String caseId){
            List<Case> cases = [SELECT Id, AccountId, Account.uuid__c, OwnerId, uuid__c, Design_Id__c, RecordTypeId, Contract__c, Opportunity__c, ContactId, Secondary_Contact__c, Programme__c, Product__c FROM Case WHERE id =: caseId];
            //List<Case> cases = [SELECT Id, AccountId, Account.uuid__c, OwnerId, uuid__c, Design_Id__c, RecordTypeId FROM Case WHERE id =: caseId];
            if(cases.isEmpty()){
                this.errorMessages.add('Could not find a case with Id = ' + Helper.getStringValue(caseId));
            } else {
                this.onboardingCase = cases[0];
            }
        }

        public void getUser(String userId, String userType){
            
            List<User> users = [SELECT id FROM User WHERE id =: userId];
            if(users.isEmpty()){
                this.errorMessages.add('Could not find a user with Id = ' + Helper.getStringValue(userId) + ' to set as ' + userType);
            } else {
                switch on userType {
                    when 'assignedTo' {
                        this.designAssignedTo = users[0];   
                    }
                    when 'approvedBy' {
                        this.designApprovedBy = users[0];   
                    }
                    when 'owner' {
                        this.designOwner = users[0];   
                    }
                }
            }
        }

        public void getAccount(String accountUUId, String accountType){
            //get school record
            Account account = AccountController.getAccount_uuid(accountUUId);
            if(account.id == null){
                this.errorMessages.add('Could not find an account with uuid = ' + Helper.getStringValue(accountUUId) + ' to set as ' + accountType);
            } else {    
                switch on accountType {
                    when 'school' {
                        this.school = account;   
                    }
                    when 'returnTo' {
                        this.returnTo = account;   
                    }
                }
            }
        }

        public void preparePricebookMap(){
            List<Pricebook2> pricebooks = [SELECT id, Name, Provider__c, 
                                        (SELECT Id,Pricebook2Id,Product2Id, Product2.Family,Product2.Name, UnitPrice FROM PricebookEntries WHERE IsActive = true)
                                        FROM Pricebook2 WHERE IsActive = True];
            this.pricebooksMap = new Map<Id, Pricebook2>(pricebooks);

            for(Pricebook2 pricebook : pricebooks){
                this.pricebooksMapByName.put(pricebook.Name, pricebook);
            }
        }
        
        public void preparePricebookProductMap(Set<String> pricebookIds){
            this.pricebookProductMap.clear();
            for (String pricebookId : pricebookIds){
                Pricebook2 pricebook = this.pricebooksMap.get(id.valueof(pricebookId));
                for (PricebookEntry pricebookEntry : pricebook.PricebookEntries){
                    this.pricebookProductMap.put( Helper.concatenateKey(new List<String>{pricebookEntry.Pricebook2Id, pricebookEntry.Product2Id}), pricebookEntry);
                }
            }
        }

        public String getErrorMessage(){
            this.errorMessage = String.join(this.errorMessages,',');
            return this.errorMessage;
        }
    }

    //common queue for updating onboarding task of a case
    public virtual class queue_UpdateTask implements Queueable {
        Private Task input;
        Private ServiceEventNDQ queueHandler;

        public queue_UpdateTask (ServiceEventNDQ queueHandler, Task input) {
            this.queueHandler = queueHandler;
            this.input = input;
        }

        public void execute(QueueableContext context) {
            updateTask();
        }
 
        public void updateTask(){
            List<Task> tasks = [SELECT id, type, task_template__c, Status, OwnerId, Entity_Attachment_Ids__c
                                FROM Task
                                WHERE RecordTypeId =: input.RecordTypeId
                                    AND Task_Template__r.Type__c =: input.Type
                                    AND WhatId =: input.WhatId
                                ];
            if(!tasks.isEmpty()){
            
                Task task = tasks[0]; //get the first task.
                task.Status = input.Status;
                
                //only update task owner when input.OwnerId is given
                if(input.OwnerId != null){
                    task.OwnerId = input.OwnerId;
                }
                
                //only update task Entity_Attachment_Ids__c when input.Entity_Attachment_Ids__c is given. Entity_Attachment_Ids__c = '' will work too.
                if(input.Entity_Attachment_Ids__c != null){
                    task.Entity_Attachment_Ids__c = input.Entity_Attachment_Ids__c;
                }

                try{
                    update task;
                    //Finally completed the last step for Network Design queues. Therefore, mark the queue as success by in Service Event record. 
                    this.queueHandler.trackServiceEvent('Queue completed successfully', 200, this.queueHandler.onboardingData.onboardingCase.id); 
                } catch (System.Exception e) {
                    this.queueHandler.trackServiceEvent(e, 400, task.id); //to track error in Service Event and cause it to send error message to notify system admind
                }
                
            }
        }
    }

    public virtual class queue_UpdateTasks implements Queueable {
        Private List<Task> inputList;
        Private ServiceEventNDQ queueHandler;

        public queue_UpdateTasks (ServiceEventNDQ queueHandler, List<Task> inputList) {
            this.queueHandler = queueHandler;
            this.inputList = inputList;
        }

        public void execute(QueueableContext context) {
            if(!inputList.isEmpty()){
                updateTasks();
            }
        }
 
        public void updateTasks(){
            //prepare a map of task with Type as key
            Map<String, Task> taskMap = new Map<String, Task>();
            For(Task task : inputList){
                taskMap.put(task.Type, task);
            }

            List<Task> tasks = [SELECT Id, Type, Task_Template__c, Status, OwnerId, Entity_Attachment_Ids__c
                                FROM Task
                                WHERE RecordTypeId =: inputList[0].RecordTypeId
                                    AND Task_Template__r.Type__c IN: taskMap.keySet()
                                    AND WhatId =: inputList[0].WhatId
                                ];
            if(!tasks.isEmpty()){
            
                
                For(Task task : tasks){
                    Task input = taskMap.get(task.Type);
                    
                    //assign status value based on input
                    task.Status = input.Status;

                    //only update task owner when input.OwnerId is given
                    if(input.OwnerId != null){
                        task.OwnerId = input.OwnerId;
                    }
                    
                    //only update task Entity_Attachment_Ids__c when input.Entity_Attachment_Ids__c is given. Entity_Attachment_Ids__c = '' will work too.
                    if(input.Entity_Attachment_Ids__c != null){
                        task.Entity_Attachment_Ids__c = input.Entity_Attachment_Ids__c;
                    }
                }

                try{
                    update tasks;
                    //Finally completed the last step for Network Design queues. Therefore, mark the queue as success by in Service Event record. 
                    this.queueHandler.trackServiceEvent('Queue completed successfully', 200, this.queueHandler.onboardingData.onboardingCase.id); 
                } catch (System.Exception e) {
                    this.queueHandler.trackServiceEvent(e, 400, this.queueHandler.onboardingData.onboardingCase.id); //to track error in Service Event and cause it to send error message to notify system admind
                }
                
            }
        }
    }
}