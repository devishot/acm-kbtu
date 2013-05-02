function countdown() {
    var m = $('.min');
    var s = $('.sec');  
    if(m.length == 0 && parseInt(s.html()) <= 0) {
        $('.clock').html('Contest is over');
        location.reload();
    }
    if(parseInt(s.html()) <= 0) {
        m.html(parseInt(m.html()-1));   
        s.html(60);
    }
    if(parseInt(m.html()) <= 0) {
        $('.clock').html('<span class="sec">59</span> seconds'); 
    }
    s.html(parseInt(s.html()-1));
}
setInterval('countdown()',1000);