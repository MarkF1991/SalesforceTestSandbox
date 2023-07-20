/** 
  * Add Google Doc in Lightning
  * 
  * @author Jayson Faderanga (jfaderanga@deloitte.co.nz)
  * @date December 2019
  * @test AddGoogleDocControllerTest
  * @page AddGoogleDoc.cmp
 **/
public with sharing class AddGoogleDocController {

    @AuraEnabled
    public static String saveGoogleDoc(String parentId, String name, String url) {
        // TODO add attach as copy function
        return attachAsReference(parentId, name, url);
    }

    public static String attachAsReference(String parentId, String name, String url) {

        ExternalDataSource source = [SELECT Id, DeveloperName
                                       FROM ExternalDataSource
                                      WHERE DeveloperName = :Label.GoogleDriveDataSource
                                      LIMIT 1];

        String message;
        Savepoint sp = Database.setSavePoint();

        try {
            String gdocId = url.substringAfter( '/d/' ).substringBefore( '/' );
            
            /** S—Document is located within Salesforce.
              * E—Document is located external outside Salesforce
              * L—Document is located on a social network and accessed via Social Customer Service.
             **/
             ContentVersion contentVersion = new ContentVersion(
                ContentLocation = 'E',
                Origin = 'H',
                OwnerId = UserInfo.getUserId(),
                Title = Name,
                ContentUrl = url,
                ExternalDataSourceId = source.Id,
                ExternalDocumentInfo1 = url,    
                ExternalDocumentInfo2 = gdocId,
                FirstPublishLocationId = parentId
            );

            insert contentVersion;	

            message = 'success';

        } catch (Exception e) {

            Database.rollback(sp);
            message = e.getMessage().substringAfter(':');
        }

        return message;
    }
}