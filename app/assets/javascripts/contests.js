function countdown() {
    var m = $('.min');
    var s = $('.sec');  
    if(m.length == 0 && parseInt(s.html()) <= 0) {
        $('.clock').html('Contest is over');
        clearInterval(intervalID)
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
var intervalID = setInterval('countdown()',1000);



// Confirm participant
$('.confirm').on('switch-change', function (e, data) {
    var $el = $(data.el)
      , value = data.value
      , participant = $(this).attr("id")
      , contest = $(this).attr("contest");

    //console.log(contest, participant, value);

    $.post("/contests/"+contest.toString()+"/confirm_participant/"+participant.toString(), 
        {
            "value": value
        }
    )
});