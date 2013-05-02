var fixHelper = function(e, ui) {
  ui.children().each(function() {
    $(this).width($(this).width());
  });
  return ui;
};

$(function() {
    $( "#sortable").sortable({
      items: '> .child',
      axis: 'y',      
      helper: fixHelper
    }).disableSelection();
    $( "#sortable").disableSelection();
    $( "#sortable_button").click(function(){
      var order = $("#sortable").sortable("toArray");
      $.post("/upd_nodes_order", {
          "order": order
        }, 
        function(response) {
          //location.reload();
          alert('Order saved')
        }
      )
    });
});