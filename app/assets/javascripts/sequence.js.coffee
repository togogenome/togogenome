$ ->
  seq = localStorage.getItem('sequence')

  if seq
    $("#fragment").val(seq)

    unless window.location.search
      $('button').click()

  $('button').on "click", ->
    fragment = $("#fragment").val()
    if fragment
      localStorage.setItem('sequence', fragment)
