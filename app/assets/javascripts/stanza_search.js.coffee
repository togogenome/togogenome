$ ->
  saveTextSearchCondition = ->
    cond =
      selectedValue: $('select#category').find(':selected').val()
      query: $('input#q').val()

    localStorage.setItem('textSearch', JSON.stringify(cond))

  loadTextSearchCondition = ->
    JSON.parse(localStorage.getItem('textSearch'))

  deleteTextSearchCondition = ->
    localStorage.removeItem('textSearch')

  $('form').on "submit", (e) ->
    e.preventDefault()

    selectTag    = $('select#category')
    searchTarget = selectTag.find(':selected').data('searchTarget')

    do saveTextSearchCondition

    switch searchTarget
      when 'category'
        @action = Routes.text_index_path()
        selectTag.attr('name', 'category')
      when 'stanza'
        @action = Routes.text_search_path()
        selectTag.attr('name', 'stanza_id')

    @submit()

  $("button#reset_button").on "click", ->
    do deleteTextSearchCondition
    window.location.href = Routes.text_index_path()
    false

  $(window).on "load", (e) ->
    search = window.location.search

    if search
      do saveTextSearchCondition
    else
      cond = do loadTextSearchCondition

      if cond
        form = $('form')
        form.find('#q').val(cond.query)
        form.find('select#category').val(cond.selectedValue)
        form.submit()
