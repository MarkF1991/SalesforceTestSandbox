public without sharing class flowTriggerHelper {


  public static void runICTProviderlows(list<Related_School_ICTProvider__c> ICTPRoviders, map<Id,sObject> oldICTProviders){
      //List<Related_School_ICTProvider__c> toUpdate = new List<Related_School_ICTProvider__c>{};
      List<Id> IdstoUpdate = new List<Id>{};
      Map<Id, Map<String, Id>> mapFlowVarsPerRecord = new Map<Id, Map<String, Id>>();
      for(Related_School_ICTProvider__c aICTProvider : ICTPRoviders){
        
        if(oldICTProviders != null){
        Related_School_ICTProvider__c oldProvider = oldICTProviders.containsKey(aICTProvider.Id)?(Related_School_ICTProvider__c)oldICTProviders.get(aICTProvider.Id):null;
        //1. Invoke Delete Group Flow and Set Fields to Null
            if(oldProvider!=null){
              if(((aICTProvider.School_Data_Sharing_on_Portal_Authorised__c == false ) && (oldProvider.School_Data_Sharing_on_Portal_Authorised__c == true)) 
                  && aICTProvider.Public_Group_ID__c!=null){
                Map<String, Id> tempMap = new Map<String, Id>();
              tempMap.put('var_PublicGroupID',aICTProvider.Public_Group_ID__c);
              tempMap.put('var_JunctionRecordID',aICTProvider.Id);
              mapFlowVarsPerRecord.put(aICTProvider.id,tempMap); 
              
              //add to update after flow
              IdstoUpdate.add(aICTProvider.id);
              
              }
            }
        }
            //2. When a new Public Group is created invoke Flow
            if(aICTProvider.Public_Group_ID__c != NULL && (aICTProvider.Account_Share_ID__c != NULL && aICTProvider.Account_Share_ID__c != 'failed') && aICTProvider.School_Data_Sharing_on_Portal_Authorised__c == TRUE){
                Map<String, Id> tempMap = new Map<String, Id>();
                tempMap.put('VarT_PublicGroupID',aICTProvider.Public_Group_ID__c);
                tempMap.put('Var_ICTAccountNumber',aICTProvider.ICT_Provider__c);
                mapFlowVarsPerRecord.put(aICTProvider.id,tempMap);
                
            }
      }
      if(IdstoUpdate.size()>0){
        callFlowToDelete(JSON.serialize(mapFlowVarsPerRecord));
        updateRecordsWithBlankIds(IdstoUpdate);
      }
      else{
        callFlowToAddICTUser(JSON.serialize(mapFlowVarsPerRecord));
      }  
  }

  public static void runAddNewlyCreatedICTUserstoExistingGroups(List<User> newUsers){
    //3. When a new Community user is added Invoke Flow
    for(User u : newUsers){
      if(u.ProfileId == Label.UserICTProfileId){
        Map<String, Object> mapFlowVars = new Map<String, Object>();
        mapFlowVars.put('var_NewICTCommunityUsersAccountID',u.AccountId);
        mapFlowVars.put('var_NewUserID',u.Id);
        Flow.Interview.Add_Newly_Created_ICT_Users_to_Existing_Groups theFlow = new Flow.Interview.Add_Newly_Created_ICT_Users_to_Existing_Groups(mapFlowVars);
        theFlow.start();
      }
    }
  }
  
    //Method to update the account after the flow has completed.
    public static void updateRecordsWithBlankIds(List<Id> allRecordIds) {
        
        List<Related_School_ICTProvider__c> recsToUpdate = new List<Related_School_ICTProvider__c>();
        //update the records for all the provided record Ids.
        for(Id recId : allRecordIds){
            Related_School_ICTProvider__c schoolRec = new Related_School_ICTProvider__c(Id=recId, Account_Share_ID__c = NULL, Public_Group_ID__c = NULL);
            recsToUpdate.add(schoolRec);
        }
         
        update recsToUpdate;
        
    }
    
    //Method to start the flow to Delete the public group. 
    @future
    public static void callFlowToDelete(String mapFlowVarsPerRecordJSON) {
        //Flow to be started in future method.
        Map<Id, Map<String, Id>> mapFlowVarsPerRecord = (Map<Id, Map<String, Id>>)JSON.deserialize(mapFlowVarsPerRecordJSON, Map<Id, Map<String, Id>>.class);
        
        for(Id  recId : mapFlowVarsPerRecord.keySet()){
            Map<String, Object> mapFlowVarsAsIds = mapFlowVarsPerRecord.get(recId);
            Map<String, Object> mapFlowVarsToPass = new Map<String, Object>();
            for(String mapKey : mapFlowVarsAsIds.keySet()){
                mapFlowVarsToPass.put(mapKey, (Object)mapFlowVarsAsIds.get(mapKey));
            }   
            
            Flow.Interview.Delete_Public_Group theFlow = new Flow.Interview.Delete_Public_Group(mapFlowVarsToPass);
            theFlow.start();
        }               
            
    }
    
    //Method to start the flow to add ICT User to public group. 
    @future
    public static void callFlowToAddICTUser(String mapFlowVarsPerRecordJSON) {
        
        //Flow to be started in future method.
        Map<Id, Map<String, Id>> mapFlowVarsPerRecord = (Map<Id, Map<String, Id>>)JSON.deserialize(mapFlowVarsPerRecordJSON, Map<Id, Map<String, Id>>.class);
        
        for(Id  recId : mapFlowVarsPerRecord.keySet()){
            Map<String, Object> mapFlowVarsAsIds = mapFlowVarsPerRecord.get(recId);
            Map<String, Object> mapFlowVarsToPass = new Map<String, Object>();
            for(String mapKey : mapFlowVarsAsIds.keySet()){
                mapFlowVarsToPass.put(mapKey, (Object)mapFlowVarsAsIds.get(mapKey));
            }   
            
            Flow.Interview.Add_ICT_User_to_Public_Group_Flow theFlow = new Flow.Interview.Add_ICT_User_to_Public_Group_Flow(mapFlowVarsToPass);
            theFlow.start();
        }
                
    }
}