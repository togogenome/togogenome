$ ->
  saveSequence = (sequence) ->
    if sequence?
      localStorage.setItem('sequence', sequence)
    true

  loadSequence = ->
    localStorage.getItem('sequence')

  button = $("#methods button")
  input  = $("input#fragment")

  $(window).on "load", (e) ->
    search = window.location.search

    if search
      val = input.val()
      saveSequence(val)
    else
      sequence = loadSequence()

      if sequence?
        input.val(sequence)
        button.click()

  button.on "click", ->
    val = input.val()
    saveSequence(val)

  false
