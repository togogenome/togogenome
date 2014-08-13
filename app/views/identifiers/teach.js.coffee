sampleIds = <%= @sample_ids.to_json.html_safe %>

$("textarea#identifiers").val(sampleIds.join("\n")).addClass('sample')
$('#add-new-id p#add-new-id-description').text('Replace with your identifiers')

<% if @db_links.empty? %>
$("#message").html("<div class='alert'><i class='icon-warning-sign'> Not found.</i></div>")
<% end %>

$("table#mapped-ids tbody").html("<%= j(render 'results') %>")
