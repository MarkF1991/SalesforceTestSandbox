/**
 * Created by Nitish Singhal (nsinghal@deloitte.co.nz ) on 5th July 2020
 * Controller for creating/retreiving files or attachments.
 */
public with sharing class FileController {
    
    /*
        method to prepare and return newly created files with Ids.
        return: Map<Id, ContentVersion>
    */
    public static Map<Id, ContentVersion> createNewFiles(List<String> attachNames, List<String> attachContent, String parentId, String visibilityValue, String shareTypeValue, Boolean base64Type, String folderName){
        List<ContentVersion> listContentVersion = new List<ContentVersion>();
        ContentWorkspace reportFolder;
        if(String.isNotBlank(folderName) && String.isBlank(parentId)){
            //get the folder id in case we need not to attach the file to any record.
            reportFolder = [SELECT Id FROM ContentWorkspace WHERE Name =: folderName];
        }
        
        //create the file content here. for PDFs, pass the base64Encoded strings.
        for(Integer i =0; i < attachNames.size() ; i ++){
           ContentVersion contentVersion = new ContentVersion(
                   Title = attachNames[i], 
                   PathOnClient = attachNames[i],
                   VersionData = base64Type ? EncodingUtil.base64Decode(attachContent[i]) : Blob.valueOf(attachContent[i]),
                   FirstPublishLocationId = reportFolder != null ? reportFolder.Id : null
            );
           listContentVersion.add(contentVersion);
        }

        if(!listContentVersion.isEmpty()) {
           insert listContentVersion;
           //if parent entity id passed, then use it and create content document link. 
           if(String.isNotBlank(parentId) && String.isBlank(folderName)){
                List<ContentVersion> latestList = [select contentDocumentId  from ContentVersion where Id in: listContentVersion];
                List<ContentDocumentLink> cdlList = new List<ContentDocumentLink>();
                for(ContentVersion cv : latestList) {
                    ContentDocumentLink cdl = new ContentDocumentLink(
                            ContentDocumentId = cv.ContentDocumentId,
                            LinkedEntityId =  parentId,
                            ShareType = shareTypeValue,
                            Visibility = visibilityValue
                    );
                    cdlList.add(cdl);
                }
                insert cdlList;
            }
           return new Map<Id, ContentVersion>(listContentVersion);
        }
        return null;
     }
    
     
     /*
        method to return files or attachments from database.
        return: Map<Id, sObject>
    */
     public static Map<Id, sObject> getAttachmentOrFileIds(Id parentId, List<String> filterKeywords, String attachOrFile){
        Map<Id, sObject> documentsToReturn = new Map<Id, sObject>();
        Set<Id> contentDocumentIds = new Set<Id>();
        
        List<ContentDocumentLink> CDLinks = [Select ContentDocumentId,LinkedEntityId from ContentDocumentLink where LinkedEntityId =: parentId AND ContentDocument.Title like :filterKeywords];
        for(ContentDocumentLink eachLink : CDLinks){
           contentDocumentIds.add(eachLink.ContentDocumentId);
        }
  
        String soql = 'Select Title, VersionData, PathOnClient,ContentDocumentId from ContentVersion where ContentDocumentId IN: contentDocumentIds';
        soql = soql + ' AND Title Like :filterKeywords ';
        soql = soql + ' ORDER BY LastModifiedDate DESC';
  
        //query all the files from parentIds
        List<Contentversion> contentVersions = Database.query(soql);
        for(ContentVersion cv : contentVersions){
            documentsToReturn.put(cv.Id, cv); //put the file ids in the list to return
        }

        //if user looking for both files and attachments, or only attachments, then search for attachment as well.
        if((attachOrFile.equalsIgnoreCase('Both')) || attachOrFile.equalsIgnoreCase('Attachment')){
           soql = 'select Name, Body, BodyLength from Attachment WHERE ParentId =: parentId';
           soql = soql + ' AND Name Like :filterKeywords ';
           soql = soql + ' ORDER BY LastModifiedDate DESC';
           for(Attachment att : Database.query(soql)){
              documentsToReturn.put(att.Id, att);
           }
        }

        return documentsToReturn;
     }

     public static Map<Id, sObject> getAttachmentOrFileFromCVIds(Id parentId, List<String> cvIds){
      Map<Id, sObject> documentsToReturn = new Map<Id, sObject>();

      String soql = 'Select Title, VersionData, PathOnClient,ContentDocumentId from ContentVersion';
      soql = soql + ' WHERE id IN :cvIds';
      soql = soql + ' ORDER BY LastModifiedDate DESC';

      //query all the files from parentIds
      List<Contentversion> contentVersions = Database.query(soql);
      for(ContentVersion cv : contentVersions){
          documentsToReturn.put(cv.Id, cv); //put the file ids in the list to return
      }

      return documentsToReturn;
   }
}