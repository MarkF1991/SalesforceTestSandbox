/**
 * @Date               : January 12, 2021
 * @Description        : controller class for n4l table screen lwc
 * @Author             : Heidi Tang (heitang@deloitte.com)
**/
public without sharing class N4LDataTableScreen {

    /** 
     * @Date: January 14, 2021
     * @Author: Heidi Tang (heitang@deloitte.com)
     * @Description: Method that retrieves related name of an object
     * @Params:
     * String recordId - the id of the record
     * String relatedObjectApiName - object api name used to get the name field
    **/
    @AuraEnabled (cacheable = false)
    public static String getRelatedFieldName(String recordId,String relatedObjectApiName){
        try{
            // set where clause condition
            String whereClause = 'Id = :recordId';
            // Build the Query
            String soql  = String.format('SELECT Name FROM {0} WHERE ({1}) LIMIT 1', new String[]{
                relatedObjectApiName,whereClause
            });

            List<SObject> records = Database.query(soql);
            
            return String.valueOf(records[0].get('Name'));
        }  catch (Exception ex) {
            handleException(ex);
            return null;
        }
    }

    /** 
     * @Date: January 12, 2021
     * @Author: Heidi Tang (heitang@deloitte.com)
     * @Description: Method that retrieve all columns based on the setting name
     * @Params:
     * String settingName - metadata setting for a table
     * String objectName - object api name used to show fields in the table
    **/
    @AuraEnabled (cacheable = false)
    public static List<N4L_DataTable_Fields_Setting__mdt> retrieveColumns(String settingName,String objectName){

        return [SELECT ID, Column_Title__c, Column_Type__c, Field_API_Name__c,
                    Column_Order__c,Column_Sortable__c, Is_Visible_in_Support_Hub__c
                    FROM N4L_DataTable_Fields_Setting__mdt 
                    WHERE Setting_Name__c = :settingName AND Object_API_Name__c = :objectName
                    ORDER BY Column_Order__c];
    }

    /** 
     * @Date: January 12, 2021
     * @Author: Heidi Tang (heitang@deloitte.com)
     * @Description: Method that retrieve all records based on the related id field
     * @Params:
     * String settingName - metadata setting for a table
     * String objectName - object api name used to show fields in the table
     * String recordId - metadata setting for a table
     * String relationshipField - object api name used to show fields in the table
     * Boolean isBusinessContact - boolean to determine if accountcontact relation must be filtered by business roles
    **/
    @AuraEnabled (cacheable = false)
    public static List<Map<String,Object>> retrieveRecords(String settingName,String objectName,String recordId,
                                                            String relationshipField, Boolean isBusinessContact,String sortQuery){
        try{
            // get login user type
            User objUser = [SELECT Id,ContactId,AccountId,Profile.Name FROM User WHERE Id = :UserInfo.getUserId()];
            List<N4L_ManageContactsProfile__mdt> allowedProfiles = [SELECT Id FROM N4L_ManageContactsProfile__mdt WHERE MasterLabel = :objUser.Profile.Name];

            // set where clause condition
            String whereClause = '';
            if (!String.isEmpty(relationshipField) && !String.isEmpty(recordId)) {
                whereClause = relationshipField+' = :recordId';

                if(allowedProfiles.isEmpty()) {
                    if(objUser.ContactId != null) {
                        Boolean isFilteredContactByOwner = true;
                        List<AccountContactRelation> relationOfLoginContact = [SELECT Id,Authority__c,Roles FROM AccountContactRelation 
                                                                                WHERE AccountId = :recordId AND ContactId = :objUser.ContactId];
                        
                        if(!relationOfLoginContact.isEmpty()) {
                            // do not filter if role is principal
                            if(relationOfLoginContact[0].Roles != null) {
                                isFilteredContactByOwner = relationOfLoginContact[0].Roles.toLowerCase().contains(N4LStringConstants.ROLE_PRINCIPAL) ? false : true;
                            }

                            // do not filter if authority is manage contacts
                            if(relationOfLoginContact[0].Authority__c != null) {
                                if(relationOfLoginContact[0].Authority__c.toLowerCase().contains(N4LStringConstants.AUTHORITY_MANAGECONTACT)
                                    || relationOfLoginContact[0].Authority__c.toLowerCase().contains(N4LStringConstants.AUTHORITY_NOMINATOR)) {
                                    isFilteredContactByOwner = false;
                                }
                            }
                        }

                        // filter account contact relation by login user only
                        if(isFilteredContactByOwner) {
                            String conId = objUser.ContactId;
                            whereClause += ' AND ContactId = :conId';
                        }
                    }
                }
    
            }
            
            // filter list by business roles
            if(isBusinessContact) {
                // Get list of business contact roles
                List<N4L_Business_Contact_Role__mdt> businessRoles = [SELECT ID, MasterLabel 
                FROM N4L_Business_Contact_Role__mdt ORDER BY Id];

                List<String> businessRolesList = new List<String>();
                for(N4L_Business_Contact_Role__mdt businessRole : businessRoles) {
                    businessRolesList.add(businessRole.MasterLabel);
                }

                String businessRolesStr = '(\'' + String.join(businessRolesList, '\',\'') + '\')';
                whereClause += ' AND  Roles INCLUDES ' + businessRolesStr;
            }

            // get all fields for the object
            List<String> fields = new List<String>();

            Boolean isActive = objectName == N4LStringConstants.OBJFIELD_ACRELATION ? false : true;

            for (N4L_DataTable_Fields_Setting__mdt header: retrieveColumns(settingName,objectName)) {
                fields.add(header.Field_API_Name__c);

                if(header.Field_API_Name__c == 'isActive') {
                    isActive = true;
                }
            }

            if(!isActive && objectName == N4LStringConstants.OBJFIELD_ACRELATION) {fields.add('isActive');}

            // Build the Query
            String soql  = String.format('SELECT Id{0} FROM {1} WHERE ({2}) {3}', new String[]{
                fields.size() != 0? ',' + String.join(fields, ',') : '',
                objectName,
                String.isNotBlank(whereClause) ? whereClause : 'Id != NULL',
                sortQuery
            });

            if(objectName == N4LStringConstants.OBJFIELD_ACRELATION) {
                soql  = String.format('SELECT Id,ContactId,Contact.AccountId{0} FROM {1} WHERE ({2}) {3}', new String[]{
                    ',' + String.join(fields, ','),
                    objectName,
                    String.isNotBlank(whereClause) ? whereClause : 'Id != NULL',
                    sortQuery
                });
            }

            // Set record list to be display on datatable
            List<SObject> records = Database.query(soql);

            List<Map<String,Object>> tableRecords = new List<Map<String,Object>>();

            String acctUrl = '/';
            String conUrl = '/';

            if(objUser.ContactId != null) {
                acctUrl = Label.Screen_CommunityUrl+'account/';
                conUrl = Label.Screen_CommunityUrl+'contact/';
            }

            for(SObject record : records) {

                Map<String,Object> tableRecord = new Map<String,Object>();
                tableRecord.put('Id',record.get('Id'));

                if(objectName == N4LStringConstants.OBJFIELD_ACRELATION) {
                    tableRecord.put('isActive',record.get('isActive'));
                }

                for (String field: fields) {
                    if(field == 'Contact.Account.Name') {
                        tableRecord.put(field+'.url',acctUrl+record.getSObject('Contact').get('AccountId'));
                    } else if(field == 'Contact.Name') {
                        tableRecord.put(field+'.url',conUrl+record.get('ContactId'));
                    } else if(field == 'Account.Name'){
                        tableRecord.put(field+'.url',Label.Screen_CommunityUrl+'account/'+record.get('AccountId'));
                    }

                    if(!field.contains('.')) {
                        tableRecord.put(field,record.get(field));
                    }else { 
                        if(field.split('\\.').size() == 2) {
                            tableRecord.put(field,record.getSObject(field.split('\\.')[0]).get(field.split('\\.')[1]));
                        } else if(field.split('\\.').size() == 3) {
                            tableRecord.put(field,record.getSObject(field.split('\\.')[0]).getSObject(field.split('\\.')[1]).get(field.split('\\.')[2]));
                        }
                    }
                }            
                
                tableRecords.add(tableRecord);
            }

            return tableRecords;
        }  catch (Exception ex) {
            handleException(ex);
            return null;
        }
    }

    /** 
     * @Date: January 13, 2021
     * @Author: Heidi Tang (heitang@deloitte.com)
     * @Description: Method that retrieves business roles
    **/
    @AuraEnabled (cacheable = false)
    public static List<String> retrieveBusinessRoles(String recordId){

        // Get list of business contact roles
        List<N4L_Business_Contact_Role__mdt> businessRoles = [SELECT ID, MasterLabel 
                                                                FROM N4L_Business_Contact_Role__mdt ORDER BY Id];
        
        List<String> businessRolesList = new List<String>();
        for(N4L_Business_Contact_Role__mdt businessRole : businessRoles) {
            businessRolesList.add(businessRole.MasterLabel);
        }

        // Get available roles
        List<String> missingRoles = new List<String>();

        String businessRolesStr = '(\'' + String.join(businessRolesList, '\',\'') + '\')';        
        
        String schoolAccRecType = N4LStringConstants.ACCOUNT_RECTYPE_SCHOOL;

        String queryString = 'SELECT Id, Roles FROM AccountContactRelation WHERE isActive = true AND AccountId = :recordId AND Account.RecordType.DeveloperName = :schoolAccRecType AND  Roles INCLUDES ' + businessRolesStr;
        List<AccountContactRelation> accConRelList = DataBase.query(queryString);

        // Separate missing roles
        for(N4L_Business_Contact_Role__mdt businessRole : businessRoles) {

            Boolean isFound = false;

            if(!accConRelList.isEmpty()) {
                for(AccountContactRelation accConRel : accConRelList){
                    if(accConRel.Roles.contains(businessRole.MasterLabel)){
                        isFound = true;
                    }
                }    
            } else {
                isFound = true;
            }

            if(!isFound) {
                missingRoles.add(businessRole.MasterLabel);
            }
        }

        return missingRoles;
    }

    /** 
     * @Date: March 18, 2021
     * @Author: Heidi Tang (heitang@deloitte.com)
     * @Description: Method that updates a relationship
    **/
    @AuraEnabled (cacheable = false)
    public static void updateRelationship(String relationId){
        try {
            AccountContactRelation accRelation = [SELECT Id,isActive,AccountId,ContactId,Contact.Email FROM AccountContactRelation WHERE Id = :relationId];
            accRelation.isActive = !accRelation.isActive;
            update accRelation;
        } catch(DmlException dmle) {
            handleException(dmle);
        }
    }
    
    /** 
     * @Date: January 13, 2021
     * @Author: Heidi Tang (heitang@deloitte.com)
     * @Description: Method that retrieves business roles
    **/
    @AuraEnabled (cacheable = false)
    public static String retrieveOutageNotif(String recordId){
        Boolean isOutageNotif = false;

        List<AccountContactRelation> accRelationList = [SELECT Id,Contact.Outage_notifications__c,Account.RecordType.DeveloperName
                                                        FROM AccountContactRelation WHERE AccountId = :recordId];
        
        if(!accRelationList.isEmpty()) {
            for(AccountContactRelation accRel : accRelationList){
                if(accRel.Account.RecordType.DeveloperName == N4LStringConstants.ACCOUNT_RECTYPE_SCHOOL) {
                    if(accRel.Contact.Outage_notifications__c) {
                        isOutageNotif = true;
                    }
                } else {
                    isOutageNotif = true;    
                }
            }
        } else {isOutageNotif = true;}

        return isOutageNotif ? null : Label.Screen_NoOutageNotif;
    }

    /** 
     * @Author: Heidi Tang (heitang@deloitte.com)
     * @Description: Handle an exception for Aura
     * @Params:
     * Exception - ex - the exception that was thrown and needs to be handled
    **/
    private static void handleException(Exception ex) {
        throw new AuraHandledException(ex.getMessage());
    }
}