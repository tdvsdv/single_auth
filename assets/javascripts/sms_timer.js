
$(document).ready(function(){
  RMPlus.SingleAuth = (function(my){
    var my = my || {};

    my.count = Math.round(parseInt(document.getElementById("sms-counter").innerHTML));

    my.timer = function(){

      my.count = my.count - 1;
      document.getElementById("sms-counter").innerHTML = my.count;
      if (my.count <= 0){
        clearInterval(my.counter);
        $('#new-sms-code').show();
        return;
      }
    };

    my.counter = setInterval(my.timer, 1000);

    return my;
  })(RMPlus.SingleAuth || {});

});