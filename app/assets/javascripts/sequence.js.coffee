$ ->
  saveSequenceSearchCondition = ->
    sequence = $("input#fragment").val()
    if sequence?
      localStorage.setItem('sequence', sequence)

  loadSequenceSearchCondition = ->
    localStorage.getItem('sequence')

  deleteSequenceSearchCondition = ->
    $("input#fragment").val('')
    localStorage.removeItem('sequence')

  $(window).on "load", (e) ->
    input = $("input#fragment")
    search = window.location.search

    if search
      do saveSequenceSearchCondition
    else
      sequence = do loadSequenceSearchCondition

      if sequence?
        window.location.href = Routes.sequence_search_path({fragment: sequence})

  $("button#search_button").on "click", ->
    do saveSequenceSearchCondition
    true

  $("button#reset_button").on "click", ->
    do deleteSequenceSearchCondition
    window.location.href = Routes.sequence_index_path()
    false

  false
