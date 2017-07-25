$(function() {
  $('form#receipt-form').submit(function( event ) {
    event.preventDefault();
    event.stopPropagation();

    // Create new form data object with the contents of this form
    var formData = new FormData();
    formData.append('file', $('#tran-file')[0].files[0]);
    formData.append('json', JSON.stringify({
      transaction_type: $('#tran-type').val(),
      organisation_name: $('#org-name').val(),
      street_name: $('#org-street').val(),
      town: $('#org-town').val(),
      postcode: $('#org-postcode').val(),
      transaction_value: $('#tran-value').val()
    }));

    $.ajax({
      url: $(this).attr("action"),
      type: 'POST',
      data: formData,
      success: function(data) {
        console.log(data);
        alert(data.message);
        $('form#receipt-form')[0].reset();
      },
      error: function(data) {
        console.log(data);
        alert(data.responseJSON.message);
      },
      cache: false,
      contentType: false,
      processData: false
    });

    // Stop propogation of event
    return false;
  });
});
