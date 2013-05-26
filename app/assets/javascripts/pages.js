var fixHelper = function(e, ui) {
  ui.children().each(function() {
    $(this).width($(this).width());
  });
  return ui;
};

$(function() {
    $(".sortable").sortable({
      axis: 'y',
      items: '> .child',
      helper: fixHelper
    }).disableSelection();
    $(".sortable").disableSelection();
    $(".sortable_button").click(function(){
      var node = this.id
      var order = $("#"+node+".sortable").sortable("toArray")      
      $.post("/upd_pages_order", {
          "json": {
            "node": node,
            "order": order
          }
        }, 
        function(response) {
          //location.reload();
          alert('Order saved')
        }
      )
    });
});