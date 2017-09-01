(function(){
	jQuery(function(e){
		var t;
		return t=/^data-stanza-(.+)/,
			e("[data-stanza]")
				.each(
					function(n){
						var r,i,s,o;
						return r=e(this),
							i=r.data(),
							s={},
							e.each(
								this.attributes,
								function(e,n){
									var r;
									if(r=(t.exec(n.name)||[])[1])return s[r.replace("-","_")]=n.value
								}
							),
							o=""+i.stanza+"?"+e.param(s),
							e("<iframe></iframe>")
								.attr({
									src:o,
									frameborder:0
								})
								.attr({
									id:"stanza-frame-"+n
								})
								.attr({
									name:"stanza-frame-"+n
								})
								.width(i.stanzaWidth||"100%")
								.height(i.stanzaHeight)
								.appendTo(r)
					}
				),
			window.onmessage=function(t){
				var n,r;
				r=JSON.parse(t.data),n=e("#"+r.id);
				if (n.attr("style").search(/height/)===-1) return n.height(r.height)
			}
	})
}).call(this);