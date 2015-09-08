$ ->
  saveSequence = (sequence) ->
    if sequence?
      localStorage.setItem('sequence', sequence)
    true

  loadSequence = ->
    localStorage.getItem('sequence')

  input    = $("input#fragment")
  button   = $("#methods button")
  sequence = loadSequence()

  if sequence?
    input.val(sequence)

    unless window.location.search
      button.click()

  button.on "click", ->
    val = input.val()
    saveSequence(val)

  false
