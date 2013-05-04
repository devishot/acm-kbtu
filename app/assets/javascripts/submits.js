sh_highlightDocument();

$(document).ready(function(){

    $('a.copy').zclip({
        path:'/assets/zclip/ZeroClipboard.swf',
        copy:$('pre#sourcecode').text()
    });

    // The link with ID "copy-description" will copy
    // the text of the paragraph with ID "description"
});