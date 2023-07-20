/**
* @author n4lsalesforce@gmail.com
* @date 2020-09-08
* @description 	to generate UUID v4
*
* CHANGE LOG
**/
public class UUIDGenerator {
    public static String GenerateAccountUUID(String AccountId){
        return Version4UUIDGenerator(AccountId);
    }
    // base on UUID version 4 with variant version 1
    public static String Version4UUIDGenerator(string key){
        string keystring='';
        if(key==null || key==''){
            Blob blobKey = crypto.generateAesKey(128);
            keystring = EncodingUtil.convertToHex(blobKey);
        }else{
            keystring = key;
        }
        String mainkey = String.valueOf(datetime.now().gettime());
        Blob hexstring = crypto.generateMac('hmacMD5',
        Blob.valueOf(mainkey), Blob.valueOf(keystring));
        String UUIDstring = EncodingUtil.ConvertTohex(hexstring);
        String versionN = '4';
        integer variantindex = math.mod(math.round(math.random() *10),4);
        list<string> variantversion4 =  new list<String>{'8','9','a','b'};
        String variantstring = variantversion4.get(variantindex);
        return UUIDstring.SubString(0,8)+ '-' + UUIDstring.SubString(8,12) + '-' +versionN+ UUIDstring.SubString(13,16) + '-'+variantstring + UUIDstring.SubString(17,20) + '-' + UUIDstring.substring(20);
    }
}