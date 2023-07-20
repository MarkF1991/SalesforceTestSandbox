public class NetworkDesignController {
    //empty method to get test coverage on retired class
    public static void doNothing() {
        
    }
    /**Retired MARCH-2022** replaced by flow - 'N4L PSI Asset Reconciliation'***
    public static Map<String, Device__c> getMapNetworkElement(List<Device__c> Devices){
        Map<String, Device__c> result = new Map<String, Device__c>();
        For(Device__c device : Devices){
            result.put(Device.Source_Data_UUID__c, device);
        }
        return result;
    }
    
    public static Map<String, Product2> getMapProduct(List<Product2> Products){
        Map<String, Product2> result = new Map<String, Product2>();
        For(Product2 product : Products){
            result.put(product.ProductCode, product);
        }
        return result;
    }

    
    public static MethodResponse getNetworkDesign(Order order){ 
        MethodResponse res = new MethodResponse();
        string body;
        
        //2.1 Make a API callout  NetworkDesignController.requestNetworkDesign(order.uuid__c)
        
        //HttpResponse response = requestNetworkDesign(order.uuid__c, order.Id); //old way
        HttpResponse response = NetworkDesignCallout.GetNetworkDesign(order.uuid__c, order.Id);
        
        if (response.getStatusCode() != 200) {
            res.setStatus(400);
            res.setResult('GetNetworkDesign', 'HttpRequest to Get Network Design failed');  
            return res;
        }
        //system.debug('Response'+response.getBody());
        body = string.valueOf(response.getBody());

 
        //to make sure the body use Case Number of this Order in TestMode.
        if(Test.isRunningTest()){
            //body = body.replace('"schoolId": "24ac35ec-e14d-401f-a50c-50552ee80cd9"', '"schoolId": "'+ order.Account.uuid__c +'"'); 
            body = body.replace('"caseNumber": "00162022"', '"caseNumber": "'+ order.Case__r.caseNumber +'"'); 
        }
        // example body = '{"data":{"_id":"b4ef0ba0-8278-4525-92b3-46bd793f00a1","schoolId":"24ac35ec-e14d-401f-a50c-50552ee80cd9","caseNumber":"00162022","buildings":[{"_id":"6b5fbd38-3c2b-4dd6-aa42-5045017d3e49","ministryId":"44","ministryNumber":"A","ministryName":"Administration","name":"","code":"","whenCreated":"2020-05-01T10:12:31.414Z","whenUpdated":"2020-05-25T09:31:59.246Z","__v":0,"floors":[{"_id":"9a46e8d9-e83d-4370-9727-f2cbfaa0a514","ministryId":"1681023","ministryName":"Ground Floor","name":"","code":"","whenCreated":"2020-05-01T10:12:31.415Z","whenUpdated":"2020-05-25T09:31:59.381Z","__v":0,"rooms":[{"_id":"b306d8c0-2398-4b95-a251-24523e80135d","ministryId":"7250608","ministryNumber":"588013","ministryName":"Staff bathroom (Male)","name":"","code":"","locationId":"","whenCreated":"2020-05-01T10:12:31.502Z","whenUpdated":"2020-05-25T09:31:55.874Z","__v":0,"ownership":{"moe":100,"bot":0,"community":0},"networkElements":[{"_id":"218f8ae4-677d-409b-a325-f3dce345d7fe","status":"Proposed","hostname":"","productCode":"ICX7150-48-4X1G","moeFunded":100},{"_id":"9bc7f5eb-09e4-4ba8-9be4-2a16c28098bf","status":"Proposed","hostname":"","productCode":"901-R650-WW00","moeFunded":100},{"_id":"5cdac524-b25c-439f-8b77-0fbf1b31e306","status":"Proposed","hostname":"","productCode":"ICX7150-24P-4X1G","moeFunded":100},{"_id":"65b13b75-ee11-44a1-a0b7-7ad00b985214","status":"Proposed","hostname":"","productCode":"ICX7150-C10ZP-2X10GR","moeFunded":100},{"_id":"d6ea3174-17a6-4218-abae-55291ec3e0f5","status":"Proposed","hostname":"","productCode":"ICX7150-48ZP-E2X10G","moeFunded":100},{"_id":"f300a041-6f7b-4183-8a10-6002e44e40c0","status":"Proposed","hostname":"","productCode":"ICX7450-24","moeFunded":100}]}]}]},{"_id":"711ca8bb-630f-4897-b050-c3d191a7bd5e","ministryId":"48","ministryNumber":"E","ministryName":"E Block","name":"","code":"","whenCreated":"2020-05-01T10:12:31.440Z","whenUpdated":"2020-05-25T09:32:06.023Z","__v":0,"floors":[{"_id":"3023326a-1c12-4dff-a7b2-45cf7250664e","ministryId":"1692592","ministryName":"Ground Floor","name":"","code":"","whenCreated":"2020-05-01T10:12:31.441Z","whenUpdated":"2020-05-25T09:32:06.169Z","__v":0,"rooms":[{"_id":"aaefe273-a1c5-4cde-9376-f0ad2af98aba","ministryId":"7315146","ministryNumber":"136742","ministryName":"Design Room","name":"","code":"","locationId":"","whenCreated":"2020-05-01T10:12:32.335Z","whenUpdated":"2020-05-25T09:32:04.849Z","__v":0,"ownership":{"moe":100,"bot":0,"community":0},"networkElements":[{"_id":"f565d167-8585-4f8d-8bd2-0d25261c8260","status":"Proposed","hostname":"","productCode":"ICX7150-48P-4X1G","moeFunded":100}]}]}]}]}}';

        NetworkDesign networkDesign = NetworkDesign.parse(body); 
        
        //2.2 with the body from 2.1, validate the network design: NetworkDesignController.validateNetworkDesign 
        MethodResponse res2 = validateNetworkDesign(order, networkDesign);
        if (res2.statuscode == 200){
            res.setStatus(res2.statuscode);
            res.appendResult(res2.results);
        } else if (res2.statuscode >= 400){ 
            res.setStatus(res2.statuscode);
            res.appendResult(res2.results);
            return res; 
        } 
        
        //2.3 passing the validation  in 2.2, and the body from 2.1, upsert the locations and network design data in NetworkDesignController.processNetworkDesign
        MethodResponse res3 = processNetworkDesign(networkDesign);
        if (res3.statuscode == 200){
            res.setStatus(res3.statuscode);
            res.appendResult(res3.results);
        } else if (res3.statuscode >= 400){
            res.setStatus(res3.statuscode);
            res.appendResult(res3.results);
            return res; 
        }
        return res;
    }
    
    
    public static MethodResponse validateNetworkDesign(Order order, NetworkDesign networkDesign){
        MethodResponse res = new MethodResponse();
        
        //validate product code must be active product --------------------------------------------------
        Set<String> productCodes = new Set<String>();
        //loop through network elements in networkdesign
        For(NetworkDesign.InstallPlan item : networkDesign.data.installPlan){
            productCodes.add(item.bomItem.product.productCode);
        }
        
        //check if networkDesign provided productCodes
        if(productCodes.isEmpty()){
            res.setStatus(400);
            res.results.put('Network Design - Devices', 'missing productCodes in networkElements[] of Network Design - Devices payload');
            return res;
        }
        
        
        List<Product2> existingProducts = [SELECT Id, IsActive, ProductCode FROM Product2 WHERE ProductCode IN: productCodes];
        Map<String, Product2> mapExistingProducts = getMapProduct(existingProducts);
        
         
        //check if there is any product in networkDesign does not exist in Salesforce
        for (String productCode : productCodes){
            if(mapExistingProducts.containsKey(productCode) == false){
                res.setStatus(400);
                res.results.put(productCode, productCode + ' does not exist in Salesforce');
            }
        }
        if (res.statuscode == 400){
            return res;
        } 
        
        
        //check for inactive product
        for (Product2 product : existingProducts){
            if (product.IsActive = false){
                res.setStatus(400);
                res.results.put(product.productCode, product.productCode + ' is inactive');
            }
        }
        
        if (res.statuscode == 400){
            return res;
        } 
        
        res.setStatus(200);
        res.setResult('validateNetworkDesign_Product', 'Successfully validated product codes in Network Design');
        //validate product code must be active product --------------------------------------------------
        
        //validate Case must be Order.Case.Number --------------------------------------------------
        if (order.Case__r.caseNumber.contains(networkDesign.Data.caseNumber)){
            //system.debug('CaseNumber In SF '+order.Case__r.caseNumber+' vs CaseNumber In Json '+ networkDesign.Data.caseNumber);
            res.setStatus(200);
            res.setResult('validateNetworkDesign_Case', 'Successfully validated case number in Network Design');
        } else {
            res.setStatus(400);
            res.setResult('validateNetworkDesign_Case', 'Failed to validate case number ' + networkDesign.Data.caseNumber + ' in Network Design');
            return res;
        }
        //validate Case must be Order.Case.Number --------------------------------------------------
        
        
        //validate SchoolId must be equal to order.Account.uuid__c --------------------------------------------------
        if (networkDesign.Data.SchoolId == order.Account.uuid__c){
            res.setStatus(200);
            res.setResult('validateNetworkDesign_SchoolId', 'Successfully validated SchoolId in Network Design');
        } else {
            res.setStatus(400);
            res.setResult('validateNetworkDesign_SchoolId', 'Failed to validate SchoolId ' + networkDesign.Data.SchoolId + 'in Network Design'); 
        }
        //validate SchoolId must be Order.Account.uuid__c --------------------------------------------------
        return res;
    }

    
    public static MethodResponse processNetworkDesign(NetworkDesign networkDesign){
        MethodResponse res = new MethodResponse();
        try{
        
            //get account record based on uuid
            Account account = AccountController.getAccount_uuid(networkDesign.Data.schoolId);
            
            //-----------------------------------------  Network Element -------------------------------------
            //get existing device id 
            Map<String, Device__c> mapNetworkElements = new Map<String, Device__c>();
            
            List<Product2> existingProducts = [SELECT Id, ProductCode, Device_Make_Model__c FROM Product2];
            Map<String, Product2> mapExistingProducts = getMapProduct(existingProducts);
            
            For(NetworkDesign.InstallPlan install : networkDesign.Data.installPlan){
                System.debug('productCode ' + install.bomItem.product.productCode);
                Product2 p = mapExistingProducts.get(install.bomItem.product.productCode);
                //System.debug('Customer__c account.Id ' + account.Id);
                //System.debug('HostName__c install.hostname ' + install.hostname);
                //System.debug('Source_Data_UUID__c ' + install.bomItem.x_id);
                //System.debug('MoE_Funded__c install.bomItem.moeFunded ' + install.bomItem.moeFunded);
                //System.debug('Product__c install.bomItem.product.x_id ' + install.bomItem.product.salesforceId);
                //System.debug('Device_Make_Model__c install.bomItem.product.deviceMakeId ' + install.bomItem.product.deviceMakeId);
                //System.debug('Installation_Location__c ' + String.join(install.location, ','));
                Device__c device = new Device__c(
                    Customer__c = account.Id,
                    // Status__c = networkElement.status, 
                    HostName__c = install.hostname, 
                    Source_Data_UUID__c = install.x_id,
                    Name = install.hostname,
                    MoE_Funded__c = install.bomItem.moeFunded,
                    Product__c = p.Id,
                    // Device_Make_Model__c  = install.bomItem.product.deviceMakeId,
                    Device_Make_Model__c  = p.Device_Make_Model__c,
                    RecordTypeId = Helper.getRecordTypeId(Schema.SObjectType.Device__c, 'LAN Element'),
                    Installation_Location__c = String.join(install.location, ',')
                );
                mapNetworkElements.put(device.Source_Data_UUID__c, device);
            }

            //collect devices for upsert
            upsert mapNetworkElements.values() Source_Data_UUID__c;
        //-----------------------------------------  Network Element -------------------------------------
        
        
        res.setStatus(200);
        res.setResult('processNetworkDesign', 'Succesfully insert or update existing Location and Network Elements' );
        
        }//end of try
        catch (System.Exception ex){
            res.setStatus(400);
            res.setResult('processNetworkDesign', 'Failed to insert or update existing Location and Network Elements' );
            res.setResult('processNetworkDesign error', ex.getMessage() + '\n\n' + ex.getStackTraceString() );
            
            system.debug('catch error - ex.getMessage = ' + ex.getMessage() + '\n\n' + ex.getStackTraceString());
        }
        
        return res; 
    }//end of processNetworkDesign */
}