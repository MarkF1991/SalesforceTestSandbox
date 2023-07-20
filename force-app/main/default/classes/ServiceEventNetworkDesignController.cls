/**
* @author Ben Soh (ben.soh@n4l.co.nz)
* @date 2020-09-11
* @description to handle subsequent processes from Service Event POST Request (ServiceEventRest.cls) in order to create case.
*
* CHANGE LOG
**/
public with sharing class ServiceEventNetworkDesignController {
    public static ApiResponse NetworkDesignRouting (ServiceEventWrapper event) {
        ApiResponse result = new ApiResponse();
        result.internalReferenceId = event.header.internalReferenceId;
        switch on event.header.action {
            when 'link' { 
                result = ServiceEventNetworkDesignController.NetworkDesignLink(event);
            }
            when 'approve' { 
                result = ServiceEventNetworkDesignController.NetworkDesignApprove(event);
            }
            when else {
                result.setStatus(200);
                result.messages = new List<String>{'event Action: "' + event.header.action + '" is not ready in Salesforce Eventing Network Design yet.'};
                result.record = null;
            }
        }
        return result;
    }

    //inner class to handle common onboarding records
    public class OnboardingData {
        public String errorMessage = '';
        public String designId = '';
        public User designApprover;
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
    }

    //----------------------------------------------------------- Network Design - Link -----------------------------------------------------------

    @future() //had to use future method to update Case owner in order to avoid triggering Case Assignment Rule. This Case Assignment Rule will fail and it caused the case owner default to Mark Fielding
    public static void UpdateCaseOwner (String caseId, String ownerId) {
        Case thisCase = [SELECT Id, OwnerId FROM Case WHERE id =: caseId LIMIT 1];
        thisCase.ownerId = ownerId;
        update  thisCase;
    }

    public static ApiResponse NetworkDesignLink (ServiceEventWrapper event) {
        ApiResponse result = new ApiResponse();
        result.internalReferenceId = event.header.internalReferenceId;

        //casting event.data class to a data class for Data_NetworkDesign
        ServiceEventWrapper.Data_NetworkDesign data = (ServiceEventWrapper.Data_NetworkDesign) event.data;
        
        List<Case> cases = [SELECT Id, AccountId, Account.uuid__c, OwnerId, uuid__c, Design_Id__c, RecordTypeId FROM Case WHERE id =: data.networkDesign.salesforceCaseId];
        if(cases.isEmpty()){
            result.setErrorMessage('Could not find a case with Id = ' + data.networkDesign.salesforceCaseId ,400);//display as error message
            result.record = null;
            return result;
        }
        Case onboardingCase = cases[0];
        
        
        Account account = AccountController.getAccount_uuid(data.networkDesign.schoolId);
        if(onboardingCase.accountId != account.Id){
            result.setErrorMessage('Invalid schoolId : ' + data.networkDesign.schoolId + ' which is different to an expected case.account.uuid : ' + onboardingCase.account.uuid__c, 400);//display as error message
            result.record = null;
            return result;
        }

        List<User> users = [SELECT id FROM User WHERE id =: data.networkDesign.assignedTo];
        if(users.isEmpty()){
            result.setErrorMessage('Could not find a user with Id = ' + data.networkDesign.assignedTo + ' to assign Case owner and Design Task owner.',400);//display as error message
            result.record = null;
            return result;
        }
        User user = users[0];

        try {
            
            //onboardingCase.ownerId = user.Id; //when running this way, it triggers Case Assignment Rule. It keeps failing, and caused default case owner to be Mark Fielding
            onboardingCase.uuid__c = data.networkDesign.caseId;
            onboardingCase.Design_Id__c = data.networkDesign.x_id;
            onboardingCase.Status = 'Under Action';
            update  onboardingCase;
            result.setRecord(onboardingCase.Id);

            MethodResponse res = update_statusOf_DesignTask(onboardingCase.Id, user.Id, 'Design', 'In Progress');

            if(res.statuscode >= 400){
                result.setErrorMessage(JSON.serialize(res.results), 500);
            } else {
                result.setStatus(res.statuscode);

                UpdateCaseOwner(onboardingCase.Id, user.Id); //update owner using future method, to overwrite the default owner of Mark Fielding here.
            }
            
        } catch (Exception e) {
            result.setErrorMessage(e,500);//display as internal error
            result.record = null;
        }

        return result;
    }

    public static MethodResponse update_statusOf_DesignTask (String caseId, String ownerId, String type, String status){
        MethodResponse res = new MethodResponse();
        try{
            List<Task> tasks = [SELECT id, type, task_template__c, Status, OwnerId
                                FROM Task
                                WHERE RecordType.name = 'Onboarding' 
                                    AND Task_Template__r.Type__c =: type
                                    //AND Status !=: status
                                    AND WhatId =: caseId
                                ];
            if(!tasks.isEmpty()){
                Task task = tasks[0]; //get the first task.
                task.Status = status;
                task.OwnerId = ownerId;
                update task;
            }
            res.setStatus(200);
        } catch (System.Exception ex) {
			res.setStatus(500);
            res.setResult('update_statusOf_DesignTask error', ex.getMessage());
		}
        return res;
    }
    //----------------------------------------------------------- Network Design - Link -----------------------------------------------------------


    //----------------------------------------------------------- Network Design - Approve -----------------------------------------------------------
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

    public static ApiResponse NetworkDesignApprove (ServiceEventWrapper event) {
        ApiResponse result = new ApiResponse();
        result.internalReferenceId = event.header.internalReferenceId;
        
        //casting event.data class to a data class for Data_NetworkDesign
        ServiceEventWrapper.Data_NetworkDesign data = (ServiceEventWrapper.Data_NetworkDesign) event.data;

        OnboardingData onboardingData = new OnboardingData();

        //set design id
        onboardingData.designId = data.networkDesign.x_id;
        
        //get User for Design Approver
        MethodResponse res1= UserController.getCustomerUser(data.networkDesign.approvedBy);
        if (res1.statusCode >= 400) {
            result.setErrorMessage('Could not find a user with assignedTo = ' + data.networkDesign.approvedBy, res1.statusCode);//display as error message
            result.record = null;
            return result;
        }
        onboardingData.designApprover = res1.user;


        //get school record
        Account school = AccountController.getAccount_uuid(data.networkDesign.schoolId);
        if(school.id == null){
            result.setErrorMessage('Could not find a account with schoolId = ' + data.networkDesign.schoolId,400);//display as error message
            result.record = null;
            return result;
        }
        onboardingData.school = school;

        //get Relinquished Equipment Return to (to populate Order.ReturnTo__c - Lookup(Organisation));
        //Id returnToId = null; //default to null
        List<ServiceEventNDWrapper.EquipmentForRemoval> removals = data.networkDesign.equipmentForRemoval;
        if(removals.size() > 0){
            Account accountReturnTo = AccountController.getAccount_uuid(removals[0].organisationId);
            if(accountReturnTo.id == null){
                result.setErrorMessage('Could not find an organisation with organisationId = ' + removals[0].organisationId + ' for equipmentForRemoval (Relinquished Equipment Return to)',400);//display as error message
                result.record = null;
                return result;
            }   
            //returnToId = accountReturnTo.Id;
            onboardingData.returnTo = accountReturnTo;
        }


        //get onboarding case
        List<Case> cases = [SELECT Id, Subject, OwnerId, Contract__c, Opportunity__c, ContactId, Secondary_Contact__c, Programme__c, Product__c FROM Case WHERE Id =: data.networkDesign.salesforceCaseId];
        //Case onboardingCase = null;
        if(cases.isEmpty()){
            result.setErrorMessage('Could not find a case with salesforceCaseId = ' + data.networkDesign.salesforceCaseId, 400);//display as error message
            result.record = null;
            return result;
        } else {
            //onboardingCase = cases[0];
            onboardingData.onboardingCase = cases[0];
        }
        
        //prepare a Map collection of pricebook and pricebook entries in inner class
        onboardingData.preparePricebookMap();
        
        
        //NP-1403: Create Order and Order Items for Order Type: Equipment - New
        List<ServiceEventNDWrapper.NewEquipment> equipments = data.networkDesign.newEquipment;
        if(equipments.size() > 0){
            //newEquipment list is not null, therefore, need to create Order with Order Type = 'Equipment - New'
            MethodResponse res2 = NetworkDesignApprove_Equipment_New(onboardingData, equipments);
            if (res2.statuscode >= 400){
                result.setErrorMessage(res2.results.get('error') , res2.statuscode);//display as error message
                result.record = null;
                return result; 
            }
        }

        result.setStatus(200);
        result.setRecord(onboardingData.onboardingCase.Id);
        return result;
    }

    //NP-1403: Create Order and Order Items for Order Type: Equipment - New
    public static MethodResponse NetworkDesignApprove_Equipment_New(OnboardingData onboardingData, List<ServiceEventNDWrapper.NewEquipment> equipments){
        MethodResponse res = new MethodResponse();
        Map<String, Order> ordersMap = new Map<String, Order>();
        List<Order> orders  = new List<Order>();
        List<OrderItem> orderItems = new List<OrderItem>();
        

        //validate pricebookIds given in payload
        Set<String> validPricebookIds = new Set<String>();
        Set<String> invalidPricebookIds = new Set<String>();
        For(ServiceEventNDWrapper.NewEquipment equipment : equipments){
            if (onboardingData.pricebooksMap.containsKey(equipment.salesforcePriceBookId)) {
                validPricebookIds.add(equipment.salesforcePriceBookId);
            } else {
                invalidPricebookIds.add(equipment.salesforcePriceBookId);
            }
        }
        if (!invalidPricebookIds.isEmpty()){
            res.setStatus(400);
            res.setResult('error', 'Invalid salesforcePriceBookId from the payload : ' + invalidPricebookIds.toString());
            return res;
        }

        //prepare a mapping for Pricebook and Product so that we can get valid PricebookEntry
        OnboardingData.preparePricebookProductMap(validPricebookIds);

        For(ServiceEventNDWrapper.NewEquipment equipment : equipments){
            Pricebook2 pricebook = onboardingData.pricebooksMap.get(equipment.salesforcePriceBookId);

            String key = ServiceEventNetworkDesignController.getPricebookChargeToKey(pricebook.Id, equipment.moeFunded);

            //add map item when the key does not exist
            if (!ordersMap.containsKey(key)) {
                ordersMap.put(key, new Order(
                                            AccountId = onboardingData.school.Id,
                                            Case__c = onboardingData.onboardingCase.Id,
                                            ContractId = onboardingData.onboardingCase.Contract__c,
                                            OpportunityId = onboardingData.onboardingCase.Opportunity__c,
                                            uuid__c = onboardingData.designId,
                                            CompanyAuthorizedById = onboardingData.designApprover.Id,
                                            CompanyAuthorizedDate = date.today(),

                                            EffectiveDate = date.today(),
                                            Status = 'Draft',
                                            Type = 'Equipment - New',
                                            OwnerId = onboardingData.school.ownerId,
                                            
                                            Charge_To__c = ServiceEventNetworkDesignController.getChargeTo(equipment.moeFunded),
                                            ReturnTo__c = (onboardingData.returnTo != null ? onboardingData.returnTo.Id : null ),
                                            Equipment_Returns_not_required__c = (onboardingData.returnTo == null),
                                            Pricebook2Id = pricebook.Id,
                                            Provider__c = pricebook.Provider__c,
                                            Allow_Part_Shipment__c = FALSE,
                                            Urgent_Delivery_Required__c = FALSE,
                                            IsReductionOrder = FALSE,
                                            
                                            BillingCity= onboardingData.school.BillingCity,
                                            BillingCountry= onboardingData.school.BillingCountry,
                                            BillingCountryCode= onboardingData.school.BillingCountryCode,
                                            BillingGeocodeAccuracy= onboardingData.school.BillingGeocodeAccuracy,
                                            BillingLatitude= onboardingData.school.BillingLatitude,
                                            BillingLongitude= onboardingData.school.BillingLongitude,
                                            BillingPostalCode= onboardingData.school.BillingPostalCode,
                                            BillingState= onboardingData.school.BillingState,
                                            BillingStateCode= onboardingData.school.BillingStateCode,
                                            BillingStreet= onboardingData.school.BillingStreet,
                                            
                                            ShippingCity= onboardingData.school.ShippingCity,
                                            ShippingCountry= onboardingData.school.ShippingCountry,
                                            ShippingCountryCode= onboardingData.school.ShippingCountryCode,
                                            ShippingGeocodeAccuracy= onboardingData.school.ShippingGeocodeAccuracy,
                                            ShippingLatitude= onboardingData.school.ShippingLatitude,
                                            ShippingLongitude= onboardingData.school.ShippingLongitude,
                                            ShippingPostalCode= onboardingData.school.ShippingPostalCode,
                                            ShippingState= onboardingData.school.ShippingState,
                                            ShippingStateCode= onboardingData.school.ShippingStateCode,
                                            ShippingStreet= onboardingData.school.ShippingStreet
                                            ));
            }                  
        }

        try {
            //add the unique orders from map to a list for bulk insert
            for(String key : ordersMap.keyset()){
                orders.add(ordersMap.get(key));  
            }
            insert orders;
        } catch (Exception e) {
            res.setStatus(500);
            res.setResult('error', e.getStackTraceString());//display as internal error
            return res;
        }


        //validate productIds given in payload
        String pricebookId = '';
        String productId = '';
        Set<String> validProductIds = new Set<String>();
        Set<String> invalidProductIds = new Set<String>();
        For(ServiceEventNDWrapper.NewEquipment equipment : equipments){
            pricebookId = equipment.salesforcePriceBookId;
            productId = equipment.product.salesforceId;
            String pricebookProductKey = Helper.concatenateKey(new List<String>{pricebookId, productId});
            if (onboardingData.pricebookProductMap.containsKey(pricebookProductKey)) {
                validProductIds.add(productId);
            } else {
                invalidProductIds.add(productId);
            }
        }
        if (!invalidProductIds.isEmpty()){
            res.setStatus(400);
            res.setResult('error', 'Invalid product Id from the payload : ' + invalidProductIds.toString());
            return res;
        }
        
        //add Order Line items to Orders
        For(ServiceEventNDWrapper.NewEquipment equipment : equipments){
                pricebookId = equipment.salesforcePriceBookId;
                productId = equipment.product.salesforceId;
                String key = ServiceEventNetworkDesignController.getPricebookChargeToKey(pricebookId, equipment.moeFunded);

                //add map item when the key does not exist
                if (ordersMap.containsKey(key)) {
                    
                    PricebookEntry pricebookEntry = onboardingData.pricebookProductMap.get( Helper.concatenateKey(new List<String>{pricebookId, productId}));

                    orderItems.add(new OrderItem(
                                                OrderId = ordersMap.get(key).Id,
                                                Quantity = equipment.quantity,
                                                Description = equipment.lineDescription,
                                                ListPrice = pricebookEntry.UnitPrice,
                                                UnitPrice = pricebookEntry.UnitPrice,
                                                Discount__c = equipment.moeFunded,
                                                Product2Id = equipment.product.salesforceId,
                                                PricebookEntryid = pricebookEntry.Id
                    ));
                }                  
        }

        try{
            insert orderItems;
        } catch (Exception e) {
            res.setStatus(500);
            res.setResult('error', e.getStackTraceString());//display as internal error
            return res;
        }

        res.setStatus(200);
        
        return res;
    }

    

    
    //----------------------------------------------------------- Network Design - Approve -----------------------------------------------------------


}