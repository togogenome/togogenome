<% if @db_links.empty? %>
$("#message").html("<div class='alert'><i class='icon-warning-sign'> Not found.</i></div>");
<% end %>

$("table#mapped-ids tbody").html("#{j(render 'results')}");
