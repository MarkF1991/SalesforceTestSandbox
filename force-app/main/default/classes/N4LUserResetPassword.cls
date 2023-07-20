/**
 * @Date               : February 05, 2021
 * @Description        : class that's being called to reset password of the newly activated user
 * @Author             : Heidi Tang (heitang@deloitte.com)
**/
public with sharing class N4LUserResetPassword {
    @InvocableMethod(label='User Reset Password' description='reset password for newly activated user' category='User')
    public static void resetPassword(List<User> userList) {
        if(!userList.isEmpty()){
            System.resetPassword(userList[0].Id,true);
        }
    }
}