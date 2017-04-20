$(function() {
  $('form#receipt-form').submit(function( event ) {
    event.preventDefault();
    event.stopPropagation();

    // Create new form data object with the contents of this form
    var formData = new FormData(this);

    $.ajax({
      url: $(this).attr("action"),
      type: 'POST',
      data: formData,
      success: function(data) {
        alert(data);
      },
      cache: false,
      contentType: false,
      processData: false
    });

    // Stop propogation of event
    return false;
  });
});
