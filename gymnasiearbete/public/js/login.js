$(document).ready(function(){

    $('.warning_flash').filter(function() {
        return $.trim($(this).text()) != ''
    }).show()
    $('.successfully_flash').filter(function() {
        return $.trim($(this).text()) != ''
    }).show()
    $('.successfully_flash').delay(2000).fadeOut('slow');

    $("#register_button").click(function() {
        alert( "Handler for .click() called." );
    });
})