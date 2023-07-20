/** created by n4lsalesforce@gmail.com on 17/05/2020
 *  upsert record by id RSP_Customer_No__c.
**/
public class StudentHouseHoldApexRestHelper {
    
    public static String UpsertStudentHouseHold(String JsonBody){
        
        list<Student_House_Hold__c> shhList = new list<Student_House_Hold__c>();
        id accid;
        map<string,string> schoolIdMap = new map<string,string>();
        set<string> MoeSchoolIdset = new set<string>();
        try{
            shhList = (List<Student_House_Hold__c>)System.JSON.deserialize(JsonBody, List<Student_House_Hold__c>.class);
        }catch(Exception e){
            return 'Error on Json '+e.getMessage();
        }
        if(shhList.size()>0){
            // fecth the only farmside account by UUID.
           //accid =  new List<Account> ( [SELECT id FROM Account WHERE uuid__c =: shhList[0].RSP__c])[0].id; 
           accid = AccountController.getAccount_uuid(shhList[0].RSP__c).id;
        }
        for(Student_House_Hold__c shh : shhList){
            if(shh.Student_School__c !=null){
               MoeSchoolIdset.add(shh.Student_School__c); 
            } 
        }
        id schoolRTid = Schema.SObjectType.Account.getRecordTypeInfosByName().get('School').getRecordTypeId();
        for(account acc :[SELECT id,MoE_School_ID__c FROM Account WHERE RecordTypeId =:schoolRTid and MoE_School_ID__c in: MoeSchoolIdset]){
            schoolIdMap.put(acc.MoE_School_ID__c,acc.id);
        }
        for(Student_House_Hold__c shh : shhList){
            string addressString = shh.Street_Address__c+' '+shh.Suburb__c+' '+ shh.City__c;
            if(addressString.length()>80){
                addressString = addressString.substring(0, 79);// name length limt is 80
            }
            shh.Name = addressString;
            shh.RSP__c = accid;
            // if there is an exist school recordtype account has the same value in MoE_School_ID__c.
            if(shh.Student_School__c !=null && schoolIdMap.containskey(shh.Student_School__c)){
                shh.Student_School__c = schoolIdMap.get(shh.Student_School__c);
            }
        }
        try{
            upsert shhList RSP_Customer_No__c; // changed Id from MoE_Address_Identifier__c to RSP_Customer_No__c.
            return 'Upserted Sucessfully'; 
         }catch(Exception e){
            return 'DML Error: ' + e.getMessage(); 
        }
    }
      
}