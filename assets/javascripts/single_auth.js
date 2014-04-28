
  $(document).ready(function(){
    RMPlus.Utils.makeSelect2Combobox('input#settings_intranet_domains_');
    RMPlus.Utils.makeSelect2Combobox('input#settings_ip_whitelist_');

    $('form[action*=single_auth]').submit(RMPlus.Utils.modifyFormForComboboxes);
  });