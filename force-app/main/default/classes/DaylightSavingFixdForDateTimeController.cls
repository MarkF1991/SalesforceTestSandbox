public class DaylightSavingFixdForDateTimeController {
    @InvocableMethod (label='DaylightSavingFixdForDateTime' description='Use this formula can avoid the affect from Daylight Saving')
    
    public static void formatNZdatetime(List<FlowInputs> request) {

        string result = JSON.serialize(request).substring(1,JSON.serialize(request).length()-1);
        String dt1;
        String dt2;
        Datetime dtFromPS1;
        Datetime dtFromPS2;
 
        Map<String, String> jsonValues = (Map<String, String>)JSON.deserialize(result, Map<String, String>.class);        
        
        Id commonId = jsonValues.get('id');
        
        if(jsonValues.get('dt1') != null && String.isNotEmpty(jsonValues.get('dt1'))){
            dtFromPS1 = Datetime.valueOf(jsonValues.get('dt1'));
        }
        
        if(jsonValues.get('dt2') != null && String.isNotEmpty(jsonValues.get('dt2'))){
            dtFromPS2 = Datetime.valueOf(jsonValues.get('dt2'));
        }
        
        
        Case complianceCase = [SELECT id, Approx_Outage_Start_Date_Time__c, Approx_Outage_Restore_Date_Time__c FROM Case WHERE id =: commonId];
        complianceCase.Approx_Outage_Start_Date_Time__c = dtFromPS1;
        complianceCase.Approx_Outage_Restore_Date_Time__c = dtFromPS2;
        update complianceCase;
        
    }
    
    //input details that comes to apex from flow
    public class FlowInputs{
        
                
        @InvocableVariable
        public Id id;
        
        @InvocableVariable
        public string dt1;
        
        @InvocableVariable
        public string dt2;
    
    }
}