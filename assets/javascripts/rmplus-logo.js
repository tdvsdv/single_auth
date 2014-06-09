$(document).ready(function(){
  var logo = $('#rmplus-logo').clone();
  $('#rmplus-logo').remove();
  $('div#settings').append(logo);
});