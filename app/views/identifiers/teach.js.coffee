sampleIds = <%=raw @sample_ids.to_json %>

$('textarea#identifiers').val(sampleIds.join("\n")).addClass 'sample'
$('#add-new-id p#add-new-id-description').text 'Replace with your identifiers'

`<%=raw render(template: 'identifiers/convert') %>`
