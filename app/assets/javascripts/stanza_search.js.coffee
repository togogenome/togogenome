$ ->
  $('form').on "submit", (e) ->
    e.preventDefault()

    selectTag    = $('select#category')
    searchTarget = selectTag.find(':selected').data('searchTarget')

    switch searchTarget
      when 'category'
        @.action = "/text"
        selectTag.attr('name', 'category')
      when 'stanza'
        @.action = "/text/search"
        selectTag.attr('name', 'stanza_id')

    @.submit()
