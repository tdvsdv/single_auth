$(document).ready(function(){
  RMPlus.SingleAuth = (function(my){
    var my = my || {};

    my.$sleeper = $('<canvas class="screensaver"></canvas>').appendTo(document.body);
    my.$sleeper.css({position: 'absolute'});
    my.sleeper = my.$sleeper.get(0);

    my.ctx = my.sleeper.getContext("2d");

    my.characters = "1234567890ABCDEFx"
    my.screensaver_fontsize = 10;

    my.sleeper.height = window.innerHeight;
    my.sleeper.width = window.innerWidth;
    my.screensaver_columns = my.sleeper.width / my.screensaver_fontsize;
    my.drops = [];
    for(var x = 0; x < my.screensaver_columns; x++){
      my.drops[x] = 1;
    }

    my.draw = function(){
      //Black BG for the canvas
      //translucent BG to show trail
      my.ctx.fillStyle = "rgba(0, 0, 0, 0.05)";
      my.ctx.fillRect(0, 0, my.sleeper.width, my.sleeper.height);

      my.ctx.fillStyle = "#0F0"; //green text
      my.ctx.font = my.screensaver_fontsize + "px arial";
      //looping over drops
      for(var i = 0; i < my.drops.length; i++)
      {
        var text = my.characters[Math.floor(Math.random() * my.characters.length)];
        //x = i*font_size, y = value of drops[i]*font_size
        my.ctx.fillText(text, i * my.screensaver_fontsize, my.drops[i] * my.screensaver_fontsize);

        //sending the drop back to the top randomly after it has crossed the screen
        //adding a randomness to the reset to make the drops scattered on the Y axis
        if(my.drops[i] * my.screensaver_fontsize > my.sleeper.height && Math.random() > 0.975){
          my.drops[i] = 0;
        }
        my.drops[i]++;
      }
    }

    my.runScreensaver = function(){
      if(typeof my.screensaver != "undefined") clearInterval(my.screensaver);
      my.screensaver = setInterval(my.draw, 100);
    }
    my.stopScreensaver = function(){
      clearInterval(my.screensaver);
    }

    my.loggedOut = false;

    my.prepareToSleep = function(){
      my.timer = setTimeout(function(){
        if (TabIsVisible()){
          my.$sleeper.stop(true, true).show('slow');
          my.runScreensaver();
        }
      }, my.settings.screensaver_timeout * 1000);
    };

    my.prepareToLogout = function(){
      my.timerLogout = setTimeout(function(){
        if (TabIsVisible()){
          if (my.loggedOut === false && my.tfa_login === true){
            $.ajax({url: my.logout_url,
                type: 'post',
                data: {},
                success: function(data){
                  my.loggedOut = true;
                  document.location.href = '';
                }
            });
          }
        }
      }, my.settings.logout_timeout * 1000);
    };

    my.screensaverHandler = function(){
      clearTimeout(my.timer);
      clearTimeout(my.timerLogout);
      my.stopScreensaver();
      my.prepareToSleep();
      my.prepareToLogout();
      if (my.$sleeper.css('display') !== 'none'){
        my.$sleeper.stop(true, true).hide('slow');
        my.stopScreensaver();
        $('html, body').css({width: '', height: '', margin: '', padding: ''});
      }
    };

    // my.prepareToLogout = function(){
    //   my.timerLogout = setTimeout(function(){
    //     if (TabIsVisible()){

    //     }
    //   }, my.settings.logout_timeout);
    // };

    // my.logoutHandler = function(){
    //   console.log('log him out!');
    //   my.timerLogout = setTimeout(function(){
    //     if (TabIsVisible() === true){

    //     }
    //   }, my.settings.logout_timeout);
    // }

    return my;
  })(RMPlus.SingleAuth || {});

  var events = 'mousemove.screensaver click.screensaver mouseup.screensaver mousedown.screensaver keydown.screensaver keypress.screensaver keyup.screensaver submit.screensaver change.screensaver mouseenter.screensaver scroll.screensaver resize.screensaver dblclick.screensaver';
  if (RMPlus.Utils.exists('SingleAuth.settings.enable_screensaver') && RMPlus.Utils.exists('SingleAuth.settings.screensaver_timeout')){
    if (RMPlus.SingleAuth.settings.enable_screensaver === 'true'){
      $(document).on(events, RMPlus.SingleAuth.screensaverHandler);
    }
  }
  if (RMPlus.Utils.exists('SingleAuth.settings.logout_timeout') && RMPlus.Utils.exists('SingleAuth.tfa_login')){
    RMPlus.SingleAuth.settings.logout_timeout = parseInt(RMPlus.SingleAuth.settings.logout_timeout);
    if (RMPlus.SingleAuth.tfa_login === true){
      $(document).on(events, RMPlus.SingleAuth.logoutHandler);
    }
  }

});