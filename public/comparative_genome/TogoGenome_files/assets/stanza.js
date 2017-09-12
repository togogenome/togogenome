jQuery(function($) {
  var RE = /^data-stanza-(.+)/

  $('[data-stanza]').each(function(index) {
    var $this  = $(this),
        data   = $this.data(),
        params = {};

    $.each(this.attributes, function(i, attr) {
      var key = (RE.exec(attr.name) || [])[1]

      if (key) {
        params[key.replace('-', '_')] = attr.value;
      }
    });

    var src = data.stanza + '?' + $.param(params);

    $('<iframe></iframe>')
      .attr({src: src, frameborder: 0})
      .attr({id: 'stanza-frame-' + index})
      .attr({name: 'stanza-frame-' + index})
      .width(data.stanzaWidth || '100%')
      .height(data.stanzaHeight)
      .appendTo($this);
  });

  window.onmessage = function(e) {
    var message = JSON.parse(e.data),
        iframe  = $('#' + message.id);

    if (iframe.attr('style').search(/height/) === -1) {
      iframe.height(message.height);
    }
  };
});
