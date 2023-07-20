var pass1 = "false"; 
var pass2 = "false";  
var pass3 = "false";

function navigate() {
    window.location = 'https://www.google.com';
}           
function validate2() {
    var password1 = $("#newPassword1 input").val();
    var password2 = $("#newPassword2 input").val();                
    if(password1 == password2 && password1) {
        $("#validate-status2").text("Match");  
        $("#validate-status2").css("color","#558b2f");
        $("#newPassword2 input").css("border", "1px solid #558b2f");
        pass2 = "true";
    }else if(password1 != password2 && password1 && password2) {
        $("#validate-status2").text("Passwords don't match");
        $("#validate-status2").css("color","#bf2727");
        $("#newPassword2 input").css("border", "1px solid #bf2727"); 
        pass2 = "false";
    }else if(!password1 || !password2){
        $("#validate-status2").text(" ");
        $("#newPassword2 input").css("border","1px solid lightgray");
    }
    
    if(pass1 == "true" && pass2 == "true" && pass3 == "true"){
        $(".slds-button_brand").attr('disabled',false);
        $(".slds-button_brand").css('border-color', 'rgb(247, 148, 30)');
        $(".slds-button_brand").css('background-color', 'rgb(247, 148, 30)');
    }else{
        $(".slds-button_brand").attr('disabled',true);
    }          
}

$(function() {
    $('#newPassword1 input').on('keypress', function(e) {
        if (e.which == 32){
            console.log('Space Detected');
            return false;
        }
    });
});

function validatePassword() {
    validate2()
    
    var rules = [{
        Pattern: "[A-Z]",
        Target: "UpperCase"
    },
                    {
                        Pattern: "[a-z]",
                        Target: "LowerCase"
                    },
                    {
                        Pattern: "[0-9]",
                        Target: "Numbers"
                    },
                    {
                        Pattern: "[^A-Za-z0-9_\\s]",
                        Target: "Symbols"
                    }
                ];
    
    var password = $(this).val();
    if(password.length > 7 && /[a-z]/.test(password) && /[A-Z]/.test(password) && /[0-9]/.test(password) && /[^A-Za-z0-9_\\s]/.test(password)){
        pass1 = "true";
    }else{
        pass1 = "false";
    }
    $("#Length").removeClass(password.length > 7 ? "glyphicon-default" : "glyphicon-ok");
    $("#Length").addClass(password.length > 7 ? "glyphicon-ok" : "glyphicon-default");
    
    for (var i = 0; i < rules.length; i++) {
        
        $("#" + rules[i].Target).removeClass(new RegExp(rules[i].Pattern).test(password) ? "glyphicon-default" : "glyphicon-ok"); 
        $("#" + rules[i].Target).addClass(new RegExp(rules[i].Pattern).test(password) ? "glyphicon-ok" : "glyphicon-default");
    }
    
    if(pass1 == "true") {
        $("#validate-status1").text("Good");  
        $("#validate-status1").css("color","#558b2f");
        $("#newPassword1 input").css("border", "1px solid #558b2f");
    }
    else if(pass1 != "true" && password) {
        $("#validate-status1").text("Too weak");
        $("#validate-status1").css("color","#bf2727");
        $("#newPassword1 input").css("border", "1px solid #bf2727");      
    }else if(!password){
        $("#validate-status1").text("Need password");
        $("#newPassword1 input").css("border", "1px solid #bf2727"); 
        $("#validate-status1").css("color","#bf2727");
    }
    
    if(pass1 == "true" && pass2 == "true" && pass3 == "true"){
        $(".slds-button_brand").attr('disabled',false);
    }else{
        $(".slds-button_brand").attr('disabled',true);
    }
}
$("#checkBox input" ).click(function() {
if($("#checkBox input" ).is(':checked')){
        pass3 = "true";
        if(pass1 == "true" && pass2 == "true" && pass3 == "true"){
            $(".slds-button_brand").attr('disabled',false);
        }else{                     
            $(".slds-button_brand").attr('disabled',true);
        }              
    }else{
        pass3 = "false";
        $(".slds-button_brand").attr('disabled',true);
    }       
});

$(document).ready(function() {
    $(".slds-button_brand").attr('disabled',true);
    $("#newPassword1 input").on('keyup', validatePassword)
    $("#newPassword2 input").keyup(validate2);        
});