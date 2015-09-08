$ ->
  seq = localStorage.getItem('sequence')

  if seq
    $("#fragment").val(seq)

  $('button').on "click", ->
    fragment = $("#fragment").val()
    if fragment
      localStorage.setItem('sequence', fragment)
