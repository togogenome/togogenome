$ ->
  saveTextSearchCondition = (selectTag) ->
    cond = {
      selectedValue: selectTag.find(':selected').val()
      query: $('input#q').val()
    }

    localStorage.setItem('textSearch', JSON.stringify(cond))

  $('form').on "submit", (e) ->
    e.preventDefault()

    selectTag    = $('select#category')
    searchTarget = selectTag.find(':selected').data('searchTarget')

    saveTextSearchCondition(selectTag)

    switch searchTarget
      when 'category'
        @.action = "/text"
        selectTag.attr('name', 'category')
      when 'stanza'
        @.action = "/text/search"
        selectTag.attr('name', 'stanza_id')

    @.submit()
