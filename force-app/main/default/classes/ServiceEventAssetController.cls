public with sharing class ServiceEventAssetController {
    public ServiceEventAssetController() {}

    @TestVisible 
    class LinkAssetMessage {
        public ServiceEventMessageHeader header;
        public LinkAssetData data;
    }
    @TestVisible
    class LinkAssetData {
        //message data props go here
        public String serial;
        public String hostname;
        public String[] stackedSerialNumbers;
        public Integer numOfUnits;
    }

    public static N4L_Asset_Register__c[] getAssetsByIds(String[] assetIds) {
        N4L_Asset_Register__c[] assets = [SELECT Asset_Number__c,Id,MAC_Address__c,Name,Product__c,Serial_Number__c,Status__c,Network_Element__c
                                          FROM N4L_Asset_Register__c
                                          WHERE Id IN :assetIds];
        return assets;
    }

    public static N4L_Asset_Register__c[] getAssetsBySerialNumbers(String[] serials) {
        N4L_Asset_Register__c[] assets = [SELECT Asset_Number__c,Id,MAC_Address__c,Name,Product__c,Serial_Number__c,Status__c,Network_Element__c
                                          FROM N4L_Asset_Register__c
                                          WHERE Serial_Number__c IN :serials];
        return assets;
    }

    public static N4L_Asset_Register__c[] getAssetsByNetworkElementId(String networkElementId) {
        N4L_Asset_Register__c[] assets = [SELECT Asset_Number__c,Id,MAC_Address__c,Name,Product__c,Serial_Number__c,Status__c,Network_Element__c
                                          FROM N4L_Asset_Register__c
                                          WHERE Network_Element__c = :networkElementId];
        return assets;
    }

    public static N4L_Asset_Register__c getAssetById(String assetId) {
        N4L_Asset_Register__c[] assets = [SELECT Asset_Number__c,Id,MAC_Address__c,Name,Product__c,Serial_Number__c,Status__c,Network_Element__c
                                          FROM N4L_Asset_Register__c
                                          WHERE Id = :assetId];
        if(assets.size() > 0) {
            return assets[0];
        }
        return null;
    }

    public static N4L_Asset_Register__c getAssetBySerialNumber(String serial) {
        N4L_Asset_Register__c[] assets = [SELECT Asset_Number__c,Id,MAC_Address__c,Name,Product__c,Serial_Number__c,Status__c,Network_Element__c
                                          FROM N4L_Asset_Register__c
                                          WHERE Serial_Number__c = :serial];
        if(assets.size() > 0) {
            return assets[0];
        }
        return null;
    }

    public static Device__c getNetworkElementById(String deviceId) {
        Device__c[] devices = [SELECT HostName__c,Id,Product__c,Installation_Location__c,Installed_N4L_Asset_Status__c,Status__c
                               FROM Device__c
                               WHERE Id = :deviceId];
        if(devices.size() > 0) {
            return devices[0];
        }
        return null;
    }

    public static Device__c getNetworkElementByHostName(String hostname) {
        Device__c[] devices = [SELECT HostName__c,Id,Product__c,Installation_Location__c,Installed_N4L_Asset_Status__c,Status__c
                               FROM Device__c
                               WHERE HostName__c = :hostname];
        if(devices.size() > 0) {
            return devices[0];
        }
        return null;
    }

    public static String validate(LinkAssetMessage message) {
        String error = '';
        List<String> validActions = new List<String>{'create', 'delete'};

        if(message == null) {
            return 'message was null';
        }
        if(message.data == null) {
            return 'data was null';
        }
        if(!validActions.contains(message.header.action)) {
            return 'action '+message.header.action+' is not supported';
        }
        if(String.isBlank(message.data.hostname)) { //Malformed message
            error += 'hostname not provided;';
        }
        if(String.isBlank(message.data.serial)) {
            error += 'serial number not provided;';
        }
        return error;
    }

    /**
     * Remove the linked device for an asset. Updates the Device/Network Element, but not the asset
     */
    public static N4L_Asset_Register__c removeCurrentlyLinkedDevice(N4L_Asset_Register__c asset) {
        Device__c oldDevice = null;
        if(String.isNotBlank(asset.Network_Element__c)) { //Change status of old device if it has an empty Installed_N4L_Asset_Status__c
            oldDevice = getNetworkElementById(asset.Network_Element__c);
            if(oldDevice != null) {
                oldDevice.Status__c = 'Inactive';
                update oldDevice;
            }
            asset.Network_Element__c = null; //Discard the link
        }
        return asset;
    }

    public static N4L_Asset_Register__c setAssetToSpare(N4L_Asset_Register__c asset) {
        asset.Status__c = 'Spare';
        return asset;
    }

    public static N4L_Asset_Register__c linkDevice(N4L_Asset_Register__c asset, Device__c device) {
        asset.Status__c = 'In Service';
        asset.Network_Element__c = device.Id;
        device.Status__c = 'Active';
        update device;
        return asset;
    }

    private static String[] getSerialsFromMessageData(LinkAssetData data) {
        String[] serials = data.stackedSerialNumbers;
        if(serials == null || serials.size() == 0) {
            serials = new List<String>(1);
            serials[0] = data.serial; //Assign the (always provided) serial in case there is no stack (most common case)
        }
        return serials;
    }

    public class DeviceNotFoundException extends Exception{}

    public static ApiResponse linkAsset(String messageBody) {
        ApiResponse result = new ApiResponse();
        LinkAssetMessage message = (LinkAssetMessage)JSON.deserialize(messageBody, LinkAssetMessage.class); //Deserialize to message, always succeeds
        String error = validate(message);
        if(!String.isBlank(error)) {
            result.setErrorMessage(error, 400);
            result.record = null;
            return result;
        }
        String hostname = '';
        String[] serials;
        Device__c device;
        N4L_Asset_Register__c[] oldAssets;
        N4L_Asset_Register__c[] assets;
        try {
            LinkAssetData data = message.data;
            serials = getSerialsFromMessageData(data);
            hostname = data.hostname;
            device = getNetworkElementByHostName(hostname);
            if(device == null) {//No device found, create device here: TODO
                // device = new Device__c();
                throw new DeviceNotFoundException('Network Element not found for '+hostname);
            }
            oldAssets = getAssetsByNetworkElementId(device.Id);
            if(oldAssets.size() > 0) {
                for (N4L_Asset_Register__c asset : oldAssets) {
                    asset.Status__c = 'Spare';
                }
                update assets;
            }
            assets = getAssetsBySerialNumbers(serials); //Try to get stack member assets
            if(assets.size() > 0) {
                for (N4L_Asset_Register__c asset : assets) {
                    asset = removeCurrentlyLinkedDevice(asset);
                    asset = linkDevice(asset, device);
                }
                update assets;
            }
        }
        catch (NullPointerException e) {
            String serialsString = String.join(serials, ', ');
            String errorText = 'assets and network elements not found for serial numbers: '+serialsString+' and hostname: '+hostname+' '+e.getStackTraceString();
            result.setErrorMessage(errorText, 404);
            result.record = null;
            return result;
        } 
        catch (Exception e) {
            result.setErrorMessage(e+' '+e.getStackTraceString(), 500);
            result.record = null;
            return result;
        }
        //Will only run if no exceptions are encountered
        // Disabled for Mark 28092021 to allow long timeframe debugging of Techops account 
        // ServiceEventOutbound event = new ServiceEventOutbound('asset.link', 'created');
        // event.add('asset', asset);
        // event.add('networkElement', device);
        // event.add('assetId',asset.Id);
        // event.add('networkElementId',device.Id);
        // Id jobId = event.send();
        result.setStatus(200);
        // result.setRecord(jobId);
        result.setRecord(device.Id);
        return result;
    }

    public static ApiResponse linkAssetDelete(String messageBody) {
        ApiResponse result = new ApiResponse();
        LinkAssetMessage message = (LinkAssetMessage)JSON.deserialize(messageBody, LinkAssetMessage.class); //Deserialize to message, always succeeds
        String error = validate(message);

        if(!String.isBlank(error)) {
            result.setErrorMessage(error, 400);
            result.record = null;
            return result;
        }
        String hostname = '';
        String[] serials;
        Device__c device;
        N4L_Asset_Register__c[] oldAssets;
        N4L_Asset_Register__c[] assets;
        try {
            LinkAssetData data = message.data;
            serials = getSerialsFromMessageData(data);
            hostname = data.hostname;
            device = getNetworkElementByHostName(hostname);
            if(device == null) {//No device found, create device here: TODO
                // device = new Device__c();
                throw new DeviceNotFoundException('Network Element not found for '+hostname);
            }
            assets = getAssetsBySerialNumbers(serials); //Try to get stack member assets
            // if(assets.size() > 0) {
            //     for (N4L_Asset_Register__c asset : assets) {
            //         asset = removeCurrentlyLinkedDevice(asset);
            //     }
            //     update assets;
            // }
            oldAssets = getAssetsByNetworkElementId(device.Id);
            if(oldAssets.size() > 0) {
                for (N4L_Asset_Register__c asset : oldAssets) {
                    asset.Status__c = 'Faulty';
                }
                update assets;
            }
            device.Status__c = 'Inactive';
            update device;
        }
        catch (NullPointerException e) {
            String serialsString = String.join(serials, ', ');
            String errorText = 'assets and network elements not found for serial numbers: '+serialsString+' and hostname: '+hostname+' '+e.getStackTraceString();
            result.setErrorMessage(errorText, 404);
            result.record = null;
            return result;
        } 
        catch (Exception e) {
            result.setErrorMessage(e+' '+e.getStackTraceString(), 500);
            result.record = null;
            return result;
        }
        //Will only run if no exceptions are encountered
        // Disabled for Mark 28092021 to allow long timeframe debugging of Techops account 
        // ServiceEventOutbound event = new ServiceEventOutbound('asset.link', 'deleted');
        // event.add('asset', asset);
        // event.add('networkElement', device);
        // event.add('assetId',asset.Id);
        // event.add('networkElementId',device.Id);
        // Id jobId = event.send();
        result.setStatus(200);
        // result.setRecord(jobId);
        result.setRecord(device.Id);
        return result;
    }
}