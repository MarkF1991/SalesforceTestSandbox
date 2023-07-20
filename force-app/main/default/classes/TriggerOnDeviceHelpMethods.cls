public class TriggerOnDeviceHelpMethods {

@future
      public static void updateN4LAsset (map<id,id> deviceWithAsset,map<id,string> deviceWithCustomerName)
    {
      list<N4L_Asset_Register__c> updateAssetList = new list<N4L_Asset_Register__c>();
      set<id> assetIds = new set<id>(deviceWithAsset.values());
      for (N4L_Asset_Register__c n4la:[Select n.Status__c, n.Id, n.Current_Location__c From N4L_Asset_Register__c n where n.id in:assetIds]){
           
         if (n4la.status__c=='Spare'){
         
            n4la.status__c='In Transit';
            n4la.Current_Location__c = deviceWithCustomerName.get(n4la.id);
            updateAssetList.add(n4la);
         }
      
      }
         if(updateAssetList.size()>0){
         
           try{
             update updateAssetList;}
             catch(DmlException e){
             System.debug('The following exception has occurred: ' + e.getMessage());
             }
         }
      
      
    }
}