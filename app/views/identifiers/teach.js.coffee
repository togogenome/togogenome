sampleIds = <%=raw @sample_ids.to_json %>

$("textarea#identifiers").val(sampleIds.join("\n")).addClass('sample')
$('#add-new-id p#add-new-id-description').text('Replace with your identifiers')

<% if @db_links.empty? %>
$("#message").html """
  <div class='alert'>
    <i class='icon-warning-sign'></i> Not found.
  </div>
"""
<% end %>

$("table#mapped-ids tbody").html("<%= j(render 'results') %>")
