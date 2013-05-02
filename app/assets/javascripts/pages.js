var fixHelper = function(e, ui) {
  ui.children().each(function() {
    $(this).width($(this).width());
  });
  return ui;
};

$(function() {
    $( ".sortable").sortable({
      axis: 'y',
      items: '> .child',
      helper: fixHelper
    }).disableSelection();
    $( ".sortable").disableSelection();
    $( ".sortable_button  ").click(function(){
      var order = $(".sortable").sortable("toArray");
      alert("Hello"+$( ".sortable").attr('id'))
      $.post("/upd_pages_order", {
          "json": {
            "node": "<%= @node.path %>",
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