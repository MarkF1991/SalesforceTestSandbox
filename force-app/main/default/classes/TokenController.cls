/**
* @author Ben Soh (ben.soh@n4l.co.nz)
* @date 2019
* @description to handle store JWT values in token__c records. Allow Support Hub guest user profile to retrieve custom object record and verify JWT.
*
* CHANGE LOG
* Added closeTokenTree() method to close child records of a parent token
**/
public without sharing class TokenController {
    //due to sharing settings, token__c Org Wide Default is set to Controlled By Parent. external user cannot close token in ContractController (which has with sharing)
    //use without sharing Controller here, so that Guest user, and External User can update (close) the token record. 
    public static MethodResponse closeToken(id recordId, string status){
        MethodResponse res = new MethodResponse();
        Token__c token = New Token__c();
        token.id = recordId;
        token.Status__c = status;
        token.IsClosed__c = true;
        token.ClosedDate__c = datetime.now(); //token.ClosedDate__c is datetime. Similar to Case.CloseDate
                

        try {
            update token;     
            res.setStatus(200);
        
        } catch (System.Exception ex) {
			res.setStatus(400);
            res.setResult('error', ex.getMessage());
            res.setResult('log', 'TokenController.closeToken Exception' );
		}

        return res;
        
    }

    public static MethodResponse closeTokenTree(id recordId){
        MethodResponse res = new MethodResponse();
        List<Token__c> parentTokens = [SELECT Id, IsClosed__c, ClosedDate__c, Parent__c FROM Token__c WHERE Id =: recordId];
        List<Token__c> childTokens = [SELECT Id, IsClosed__c, ClosedDate__c, Parent__c FROM Token__c WHERE Parent__c =: recordId AND IsClosed__c = false];
        List<Token__c> updateTokens = new List<Token__c>();
        try {
            
            if(!parentTokens.isEmpty()){
                for(Token__c token : parentTokens){
                    token.IsClosed__c = true;
                    token.ClosedDate__c = datetime.now();
                    updateTokens.add(token);
                }
            }

            
            if(!childTokens.isEmpty()){
                for(Token__c token : childTokens){
                    token.IsClosed__c = true;
                    token.ClosedDate__c = datetime.now();
                    updateTokens.add(token);
                }
            }

            if(!updateTokens.isEmpty()){
                update updateTokens;
            }

            res.setStatus(200);
        } catch (System.Exception ex) {
			res.setStatus(400);
            res.setResult('error', ex.getMessage());
            res.setResult('log', 'TokenController.closeTokenTree Exception' );
		}

        return res;
    }

    public static MethodResponse getToken(id recordId){
        MethodResponse res = new MethodResponse();
        List<Token__c> tokens  = [SELECT id, RecordId__c, Account__c, Account__r.Name, Requester__c, Requester__r.FirstName, Requester__r.Name, Requester__r.Email, Approver__r.FirstName, Approver__r.Name, Approver__r.Email,  Type__c, Status__c, IsClosed__c, ClosedDate__c, JWT1__c, JWT2__c,JWT3__c, Parent__c, Parent__r.JWT1__c, parent__r.recordId__c, UserOrigin__c FROM Token__c WHERE id =: recordId LIMIT 1];
        //error handling
        if (tokens.isEmpty()){
            if (String.isNotBlank(recordId)){
                res.setStatus(404);
                res.setResult('error', 'Could not find a Token__c record with id = "' + recordId + '"');    
            } else {
                res.setStatus(400);
                res.setResult('error', 'Missing Token__c id in token claims');    
            }
            return res;
        } 
        //success
        res.setStatus(200);
        //use res.token to return as dto
        res.token = tokens[0]; //default to the first case in list - when a token has included a valid case, it should return only 1 record
        return res;
    }
    
}