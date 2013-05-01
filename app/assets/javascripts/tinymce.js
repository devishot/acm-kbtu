$(function(){
  tinymce.init({
    selector: "textarea.tinymce",
    plugins: [
      "autoresize advlist autolink link image lists charmap preview hr anchor pagebreak spellchecker",
      "searchreplace wordcount visualblocks visualchars code fullscreen insertdatetime media nonbreaking",
      "save table contextmenu directionality emoticons template paste textcolor"
    ],
    width: 697 //like a span9
  });
});