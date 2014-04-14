
  $(document).ready(function(){
    $('input#intranet_domains').val(RMPlus.SingleAuth.intranet_domains_values);
    $('input#intranet_domains').select2({
      createSearchChoice:function(term, data){
        if ($(data).filter(function() { return this.text.localeCompare(term)===0; }).length===0){
          return {id:term, text:term};
        }
      },
      multiple: true,
      data: RMPlus.SingleAuth.intranet_domains
    });

     $('form[action*=single_auth]').submit(RMPlus.Utils.modifyFormForComboboxes(event, ["settings[intranet_domains][]"]))

     });

  });