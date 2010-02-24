$(function() {
    $('#edit_title').hide();
    $('#edit_description').hide();

    $('#show_title').click(function() {
        $('#show_title').hide();
        $('#edit_title').show();
    });

    $('#show_description').click(function() {
        $('#show_description').hide();
        $('#edit_description').show();
    });

    $('#cancel_edit_title').click(function() {
        $('#show_title').show();
        $('#edit_title').hide();
    });

    $('#cancel_edit_description').click(function() {
        $('#show_description').show();
        $('#edit_description').hide();
    })
});
