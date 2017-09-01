/*global d3, CodeMirror, d3sparql */
/*jshint multistr: true */



const
	ENDPOINT = 'http://dev.togogenome.org/sparql-test',
	DEFAULT = {
		aspect: 'pathway',
		species: [ 9606, 10090, 10116 ]
	},
	DURATION = {
		scroll: 250,
		css: 200
	},
	TREE = {
		svgHeight: 320,
		lineHeight: 32,
		width: 200,
		nodeSize: 8,
		nodeStrokeWidth: 2
	},
	SPARQLS = {
		step1: '\
			DEFINE sql:select-option "order"\n\
			\n\
			PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>\n\
			PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>\n\
			PREFIX up: <http://purl.uniprot.org/core/>\n\
			PREFIX tax: <http://purl.uniprot.org/taxonomy/>\n\
			PREFIX db: <http://purl.uniprot.org/database/>\n\
			\n\
			SELECT ?orgs (COUNT(?orgs) AS ?count)\n\
			WHERE {\n\
				SELECT ?label (GROUP_CONCAT(REPLACE(STR(?tax), tax:, "") ;	separator=", ") AS ?orgs)\n\
				WHERE {\n\
					SELECT DISTINCT ?label ?tax\n\
					FROM <http://togogenome.org/graph/uniprot>\n\
					WHERE {\n\
						VALUES ?tax { @@taxvalues@@ }\n\
						?up up:organism ?tax .\n\
						@@aspect@@\n\
					}\n\
					ORDER BY ?tax\n\
				}\n\
			}\n\
			ORDER BY DESC(?count)',

		step2: '\
			DEFINE sql:select-option "order"\n\
			\n\
			PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>\n\
			PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>\n\
			PREFIX up: <http://purl.uniprot.org/core/>\n\
			PREFIX tax: <http://purl.uniprot.org/taxonomy/>\n\
			PREFIX db: <http://purl.uniprot.org/database/>\n\
			\n\
			SELECT DISTINCT ?label ?sum ?orgs\n\
			WHERE {\n\
				{\n\
					SELECT ?label (SUM(?count) AS ?sum) (GROUP_CONCAT(REPLACE(STR(?tax), tax:, "") ;	separator=", ") AS ?orgs)\n\
					WHERE {\n\
						SELECT ?label ?tax (COUNT(?up) AS ?count)\n\
						WHERE {\n\
							SELECT DISTINCT ?label ?tax ?up\n\
							FROM <http://togogenome.org/graph/uniprot>\n\
							WHERE {\n\
								VALUES ?tax { @@taxvalues@@ }\n\
								?up up:organism ?tax .\n\
								@@aspect@@\n\
							}\n\
						}\n\
						ORDER BY ?tax\n\
					}\n\
				}\n\
				FILTER (?orgs = "@@taxfilter@@")\n\
			}\n\
			ORDER BY DESC(?sum)',

		step3: '\
			DEFINE sql:select-option "order"\n\
			\n\
			PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>\n\
			PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>\n\
			PREFIX up: <http://purl.uniprot.org/core/>\n\
			PREFIX tax: <http://purl.uniprot.org/taxonomy/>\n\
			PREFIX db: <http://purl.uniprot.org/database/>\n\
			\n\
			#SELECT DISTINCT ?tg_id ?up_id ?tax_id ?up ?tax\n\
			SELECT DISTINCT ?tg_id ?up_id ?tax_id\n\
			WHERE {\n\
				GRAPH <http://togogenome.org/graph/uniprot> {\n\
					VALUES ?label { @@category@@ }\n\
					VALUES ?tax { @@taxvalues@@ }\n\
					?up up:organism ?tax .\n\
					@@aspect@@\n\
				}\n\
				GRAPH <http://togogenome.org/graph/tgup> {\n\
					?up_id rdfs:seeAlso ?up .\n\
					?tg_id rdfs:seeAlso ?up_id .\n\
					?tg_id rdfs:seeAlso ?tax_id .\n\
					?tax_id a <http://identifiers.org/taxonomy> .\n\
				}\n\
			}\n\
			ORDER BY (?tax_id)'
	},
	LINKS_TO_HEADER_LABEL_MAPPING = {
		tg_id: 'TogoGenome ID',
		up_id: 'UniProt ID',
		tax_id: 'Taxonomy ID'
	};
var application;

function wrapInner(html){
	return '<div class="inner">' + html + '</div>';
}


/**
 * ノードリストから指定された名を持つノードを検索して返す
 * ノードリストに該当する名が存在しない場合は新規にノードを生成
 * @param	nodes:Array
 * @param	name:String
 */
function getNodeWithName(nodes, name, isSelected){
	var hasNode = false, index, param = {};
	for (index = 0; index < nodes.length; index++) {
		if (nodes[index].name === name) {
			hasNode = true;
			break;
		}
	}
	if (!hasNode) {
		//*
		param.name = name;
		param.isLeaf = false;
		if (isSelected) {
			param.children = [];
		} else {
			param._children = [];
		}
		nodes.push(param);
	}
	return nodes[index]._children ? nodes[index]._children : nodes[index].children;
}


function intersect(rect1, rect2){
	var sx, sy, ex, ey, w, h;
	sx = Math.max(rect1.x, rect2.x);
	sy = Math.max(rect1.y, rect2.y);
	ex = Math.min(rect1.x + rect1.width, rect2.x + rect2.width);
	ey = Math.min(rect1.y + rect1.height, rect2.y + rect2.height);
	w = ex - sx;
	h = ey - sy;
	if (w > 0 && h > 0) {
		return { x: sx, y: sy, width: w, height: h };
	} else {
		return { x: 0, y: 0, width: 0, height: 0 };
	}
}


/**
 * Tree class
 * D3.js の treeを管理するクラス
 * @param	data:Object	taxonomy の json データ
 */
function Tree(data){
	//window.console.log(data);
	var deepest = 0, species, clades, node, isSelected, isOpened = true;

	// taxonomyの生成
	// 界の生成
	for (var i = 0; i < data.length; i++) {
		// 界の取得
		species = data[i];
		isSelected = DEFAULT.species.indexOf( parseInt(species.taxid) ) !== -1;
		clades = species.clade;
		node = getNodeWithName(this.taxonomy.children, species.domain, isSelected);
		deepest = deepest > clades.length ? deepest : clades.length;
		// 系統樹の生成
		for (var j = 0; j < clades.length; j++) {
			node = getNodeWithName(node, clades[j], isSelected);
		}
		// 種の生成
		species.name = species.common_name;
		species.isLeaf = true;
		node.push(species);
	}
	deepest += 3;


	// 系統樹の生成
	//var svgWidth = data.length * TREE.lineHeight,
	//		svgHeight = deepest * TREE.width,
	var svgWidth = TREE.svgHeight,
			svgHeight = 320,
	//		translate = [0, (-svgHeight + TREE.svgHeight) * 0.5],
			translate = [100, 0],
			zoom;

	// zoom
	zoom = d3.behavior.zoom()
		//.size([100, 100])
		.translate(translate)
		.scaleExtent([0.25, 8])
		.on('zoom', function(){
			this.treeGroup.attr('transform', 'translate(' + d3.event.translate + ')scale(' + d3.event.scale + ')');
		}.bind(this));

	// svg
	this.svg = d3.select('#species-selector').append('svg');
	this.svg.append('rect')
		.attr('class', 'event-capture')
		.call(zoom);
	this.treeGroup = this.svg.append('g')
		.attr('transform', 'translate(' + translate + ')');

	// tree
	this.tree = d3.layout.tree()
		.nodeSize([TREE.width, TREE.lineHeight])
		.separation(function(a, b) { return (a.parent === b.parent ? 1 : 1.5); })
		.size([svgWidth, svgHeight]);

	// diagonal
	this.diagonal = d3.svg.diagonal()
		.projection(function(d){ return [d.y, d.x]; });

	// make tree
	this.taxonomy.x0 = svgHeight / 2;
	this.taxonomy.y0 = 0;
	this.update(this.taxonomy);

	// 表示切替ボタン
	this.$speciesSelector = $('#species-selector');
	this.speciesSelectorWidthMargin = window.innerWidth - this.$speciesSelector.width();
	this.$speciesSelector.find('.toggle-button').on('click', function(){
			if (isOpened) {
				this.$speciesSelector
					.css('width', '')
					.addClass('closed');
				$(window).off('resize.species-selector');
			} else {
				this.$speciesSelector.removeClass('closed');
				$(window).on('resize.species-selector', this.resize.bind(this)).triggerHandler('resize.species-selector');
			}
			isOpened = !isOpened;
			window.setTimeout(function(){
				$(window).triggerHandler('scroll.headingNavigation');
			}, DURATION.css + 100);
	}.bind(this));
	$(window).on('resize.species-selector', this.resize.bind(this)).triggerHandler('resize.species-selector');
}
Tree.prototype = {
	DURATION: 750,
	taxonomy: { // taxonomy のルート
		name: 'Taxonomy',
		children: [],
		isLeaf: false
	},
	nodeIndex: 0,
	svg: undefined,
	treeGroup: undefined,
	tree: undefined,
	diagonal: undefined,

	update: function(source){
		var nodes, node, nodeEnter, nodeUpdate, nodeExit, leafNode, links, link, self = this;

		nodes = this.tree.nodes(this.taxonomy).reverse();
		links = this.tree.links(nodes);

		// Normalize for fixed-depth.
		nodes.forEach(function(d) { d.y = d.depth * 180; });

		// Update the nodes…
		node = this.treeGroup.selectAll('g.node')
			.data(nodes, function(d) { return d.id || (d.id = ++this.nodeIndex); }.bind(this));

		// Enter any new nodes at the parent's previous position.
		nodeEnter = node.enter().append('g')
			.attr({
				class: function(d) {
					return 'node' +
						(d.isLeaf ? ' leaf' : '') +
						(d._children ? ' collapsed' : '') +
						(d.children ? ' expanded' : '');
				},
				transform: function() { return 'translate(' + [source.y0, source.x0] + ')'; }
			})
			.on('click', function(d){
				console.log(arguments);
				if (d.isLeaf) {
					if (d.isSelected) {
						// 選択を解除
						d.isSelected = false;
						d3.select(this).classed({ selected: false });
						application.deleteSpecies(d, this);
					} else {
						// 種を選択
						if (application.setSpecies(d, this)) {
							// 選択に成功したら、選択状態に
							d.isSelected = true;
							d3.select(this).classed({ selected: true });
						}
					}
				} else {
					if (d._children) {
						// 閉じてる
						d3.select(this).classed({ collapsed: false, expanded: true });
						d.children = d._children;
						d._children = null;
					} else {
						// 開いてる
						d3.select(this).classed({ collapsed: true, expanded: false });
						d._children = d.children;
						d.children = null;
					}
					self.update(d);
				}

			});
			//.on('click', this.click.bind(this));
		nodeEnter.append('circle')
			.attr( 'r', 1e-6 );
		nodeEnter.append('text')
			.attr( 'text-anchor', function(d) { return d.isLeaf ? 'start' : 'end'; } )
			.text(function(d) { return d.name; })
			.style('fill-opacity', 1e-6);

		// Transition nodes to their new position.
		nodeUpdate = node.transition()
			.duration(this.DURATION)
			.attr('transform', function(d) {　return 'translate(' + [d.y, d.x] + ')';　});
		nodeUpdate.select('circle')
			.attr('r', TREE.nodeSize - TREE.nodeStrokeWidth);
		nodeUpdate.select('text')
			.style('fill-opacity', 1);

		// Transition exiting nodes to the parent's new position.
		nodeExit = node.exit().transition()
			.duration(this.DURATION)
			.attr('transform', function() { return 'translate(' + [source.y, source.x] + ')'; })
			.remove();
		nodeExit.select('circle')
			.attr('r', 1e-6);
		nodeExit.select('text')
			.style('fill-opacity', 1e-6);

		// leaf
		leafNode = this.treeGroup.selectAll('.node.leaf');
		leafNode
			.attr('data-tax-id', function(d) { return d.taxid; });
		leafNode.selectAll('circle')
			.attr('r', TREE.nodeSize);
		leafNode
			.append('rect')
				.attr({ class: 'plus1', width: 2, height: 8 });
		leafNode
			.append('rect')
				.attr({ class: 'plus2', width: 8, height: 2 });

		// link
		// Update the links…
		link = this.treeGroup.selectAll('path.link')
			.data(links, function(d) {
				//window.console.log(d.target.id);
				return d.target.id;
			});

		// Enter any new links at the parent's previous position.
		link.enter().insert('path', 'g')
			.attr({
				class: 'link',
				d: function() {
					var o = { x: source.x0, y: source.y0 };
					return this.diagonal({ source: o, target: o });
				}.bind(this)
			});

		// Transition links to their new position.
		link.transition()
			.duration(this.DURATION)
			.attr('d', this.diagonal);

		// Transition exiting nodes to the parent's new position.
		link.exit().transition()
			.duration(this.DURATION)
			.attr('d', function() {
				var o = { x: source.x, y: source.y };
				return this.diagonal({ source: o, target: o });
			}.bind(this))
			.remove();
			
		// Stash the old positions for transition.
		nodes.forEach(function(d) {
			d.x0 = d.x;
			d.y0 = d.y;
		});
	},

	resize: function(){
		console.log(window.innerWidth);
		console.log(this.speciesSelectorWidthMargin);
		this.$speciesSelector.width( 'calc(100% - 24px)' );
	}
};


/**
 * Species class
 * 
 * @param	data:Object	taxonomy の json データ
 */
function Species(data, index, targetNode) {
	var html;
	this.index = index;
	this.data = data;
	//this.commonName = data.common_name;
	//this.scientificName = data.scientific_name;
	this.taxId = data.taxid;
	this.wikipedia = data.wikipedia;
	this.targetNode = targetNode;

	// htmlの生成
	if (!this.$container) {
		this.$container = $('#section-species').children('.species-container');
	}
	html = '<div class="species" data-index="@@index@@">\
			<div class="color-ball"></div>\
			<h3>@@common_name@@</h3>\
			<p class="scientific-name">@@scientific_name@@</p>\
			<div class="close-button"></div>\
		</div>'
		.replace(/@@index@@/, this.index + '')
		.replace(/@@common_name@@/, data.common_name + '')
		.replace(/@@scientific_name@@/, data.scientific_name);

	this.$container.append(html);
	this.$ = this.$container.children('.species').last();
	this.$.find('.close-button').on('click', this.clickCloseButton.bind(this));
}
Species.prototype = {
	$container: undefined,

	clickCloseButton: function() {
		var event = new MouseEvent("click");
		this.targetNode.dispatchEvent(event);
	},

	updateByDeleteTaxId: function(taxId, index) {
		if (taxId === this.data.taxid) {
			window.console.log('消す');
			this.$.remove();
			return true;
		} else {
			this.index = index;
			this.$.attr('data-index', index);
			return false;
		}
	}
};


/**
 * VennDiagram class
 * 
 * @param	elm:HTMLElement
 * @param	parentElm:HTMLElement
 */
function VennDiagram(elm, parentElm) {
	this.vennDiagram = elm;
	this.$vennDiagram = $(elm);
	this.$parent = $(parentElm);
	this.vennDiagramHeight = this.$vennDiagram.height();

	//$(window).on('scroll.venn-diagram', this.scroll.bind(this));
}
VennDiagram.prototype = {
	MARGIN_TOP: 80,
	MARGIN_BOTTOM: 80,
	FIXED_TOP: 110,

	scroll: function(){
		if ( (window.scrollY + this.MARGIN_TOP) > this.$parent.offset().top ) {
			this.$vennDiagram.css({
				position: 'fixed',
				top: this.FIXED_TOP
			})
		} else {
			this.$vennDiagram.css({
				position: '',
				top: ''
			})
		}
	}
};


/**
 * Heading Navigation class
 * 見出しによるナビゲーション
 * 画面上下に吸着し、ナビゲーションとして機能
 * @param	data:Object	taxonomy の json データ
 */
function HeadingNavigation() {
	var self = this,
			headingHeight = $('.section > header').height(),
			$section = $('.section');

	this.sections = [];
	this.$window = $(window);
	this.$scroll = $('body, html');

	$section.each(function(index){
		var $this = $(this),
				$heading = $this.children('header');
		self.sections.push({
			$section: $this,
			$heading: $heading,
			top: headingHeight * index,
			bottom: headingHeight * ($section.length - 1 - index),
			position: undefined
		});
		$heading
			.data('index', index)
			.on('click', function(){
				if ($this.hasClass('disabled')) {
					return;
				}
				self.scrollTo( $(this).data('index') );
			});
	});

	this.$window
		.on('scroll.headingNavigation', this.scroll.bind(this))
		.triggerHandler('scroll.headingNavigation');
}
HeadingNavigation.prototype = {
	scroll: function(){
		var scrollTop = this.$window.scrollTop(),
				windowHeight = this.$window.innerHeight(),
				PADDING_TOP = 46;

		this.sections.forEach(function(section){
			var top = section.$section.offset().top,
					height = section.$heading.height(),
					position = 0;
			if (scrollTop > (top - section.top - PADDING_TOP)) {
				position = -1;
			}
			if ((scrollTop + windowHeight) < (top + height + section.bottom)) {
				position = 1;
			}
			if (section.position !== position) {
				section.position = position;
				switch(position) {
					case -1: // 上に吸着
						section.$section.addClass('sticked').removeClass('bottom');
						section.$heading.css({ top: section.top + PADDING_TOP, bottom: '' });
						break;
					case 0: // スクロール
						section.$section.removeClass('sticked').addClass('bottom');
						section.$heading.css({ top: '', bottom: '' });
						break;
					case 1: // 下に吸着
						section.$section.addClass('sticked bottom');
						section.$heading.css({ top: '', bottom: section.bottom });
						break;
				}
			}
		});
	},
	scrollTo: function(index){
		this.$scroll.animate({
			scrollTop: this.sections[index].$section.offset().top - this.sections[index].top + 2
		}, {
			duration: DURATION.scroll
		});
	}
};

/**
 * Application class
 * アプリ全体を管理するクラス
 */
function Application() {
}
Application.prototype = {
	MAX_OF_TAXON: 5,

	initialize: function(data){
		//window.console.log(data);
		var self = this, treeLeafNode;

		//this.species = []; // TODO: デフォルトを定義

		// reference
		this.$aspectH2 = $('#section-aspect h2 strong');
		this.$speciesH2 = $('#section-species h2 strong');
		this.$combinationH2 = $('#section-combination h2 strong');
		this.$categoryH2 = $('#section-category h2 strong');
		this.$sectionSpecies = $('#section-species');
		this.$sectionSpecies.attr('data-number-of-species', 0);
		this.$sectionCombination = $('#section-combination');
		this.$combinationResultsGraph = $('#combination-results-graph');
		this.d3VennDiagrams = d3.selectAll('.venn-diagram');
		this.d3VennDiagramTexts = this.d3VennDiagrams.selectAll('text');
		this.$sectionCategory = $('#section-category');
		this.$categoryContainer = $('#category-container');
		this.$sectionLinkTo = $('#section-link-to');
		this.$linkToContainer = $('#link-to-container');

		this.$sectionCombination.addClass('disabled');
		this.$sectionCategory.addClass('disabled');
		this.$sectionLinkTo.addClass('disabled');

		// cache
		this.data = data;
		this.cache = {
			aspect: undefined,
			species: [],
			taxIds: undefined
		};

		// タクソンツリーの生成
		this.tree = new Tree(data);

		// ベン図
		this.vennDiagram = new VennDiagram(
			document.getElementById('venn-diagrams'),
			document.getElementById('section-combination')
			);

		// ナビゲーション	
		this.HeadingNavigation = new HeadingNavigation();

		// インタラクション：Aspect の選択
		$('#aspects-selector input[type="radio"]').click(function(){
			var $parent = $(this).parent(),
					labelText = $parent.text(),
					smallText = $parent.find('small').text();
			labelText = labelText.replace(smallText, '');
			self.setAspect(labelText, this.value);
		});

		treeLeafNode = this.$sectionSpecies.find('g.node.leaf');
		// デフォルトの選択
		$('#aspects-selector').find('input[value="' + DEFAULT.aspect + '"]').trigger('click');
		DEFAULT.species.forEach(function(d){
			var $g = treeLeafNode.filter('[data-tax-id="' + d + '"]');
			var event = new MouseEvent("click");
			$g.get(0).dispatchEvent(event);
		});
	},

	getValueWithKeyValue: function(key1, key2, value) {
		value = value + '';
		for (var i = 0; i < this.data.length; i++) {
			if (this.data[i][key2] === value) {
				return this.data[i][key1];
			}
		}
	},

	setAspect: function(label, value){
		this.$aspectH2.text(label);
		this.cache.aspect = value;
		this.step1();
	},
	setSpecies: function(data, targetNode){
		var species;
		if (this.cache.species.length >= (this.MAX_OF_TAXON)) {
			window.alert('Species は5種までしか選択できません');
			return false;
		} else {
			species = new Species(data, this.cache.species.length, targetNode);
			this.cache.species.push(species);
			this.updateSpecies();
			return true;
		}
	},
	deleteSpecies: function(data, targetNode){
		var newSpecies = [], isLDead;
		this.cache.species.forEach(function(species, index){
			isLDead = species.updateByDeleteTaxId(data.taxid, newSpecies.length);
			if (!isLDead) {
				newSpecies.push(species);
			}
		});
		this.cache.species = newSpecies;
		this.updateSpecies();
	},
	updateSpecies: function(){
		var html = this.cache.species.length === 0 ? '--' : '';
		// data
		this.$sectionSpecies.attr('data-number-of-species', this.cache.species.length);
		this.$sectionCombination.attr('data-number-of-species', this.cache.species.length);
		// heading
		this.cache.species.forEach(function(species, index, array){
			html += ('<span data-index="@@index@@">@@name@@</span>'
				.replace(/@@index@@/, species.index)
				.replace(/@@name@@/, species.data.common_name + (index < (array.length - 1) ? ',' : '')));
		});
		this.$speciesH2.html(html);
		this.step1();
	},

	aspectSparql: function(aspect) {
		var sparql = '',
				mapping = {
					interpro: 'InterPro',
					pfam: 'Pfam',
					supfam: 'SUPFAM',
					prosite: 'PROSITE',
					reactome: 'Reactome',
					ctd: 'CTD',
					cazy: 'CAZy',
					brenda: 'BRENDA',
					eggnog: 'eggNOG',
					genetree: 'GeneTree',
					hogenom: 'HOGENOM',
					hovergen: 'HOVERGEN',
					inparanoid: 'InParanoid',
					ko: 'KO',
					oma: 'OMA',
					orthodb: 'OrthoDB',
					phylomedb: 'PhylomeDB',
					treefam: 'TreeFam',
					nextbio: 'NextBio',
					paxdb: 'PaxDb',
					pride: 'PRIDE'
				};
		switch(aspect) {
			case 'pathway': sparql = '?up up:annotation ?annotation .\n\t?annotation rdf:type up:Pathway_Annotation .\n\t?annotation rdfs:comment ?label .'; break;
			case 'location': sparql = '?up up:annotation ?annotation .\n\t?annotation a up:Subcellular_Location_Annotation .\n\t?annotation up:locatedIn/up:cellularComponent ?location .\n\t?location up:alias ?label .'; break;
			case 'geneontology': sparql = '?up up:classifiedWith ?go .\n\t?go up:database db:go .\n\t?go rdfs:label ?label .'; break;
			case 'interpro':
			case 'pfam':
			case 'supfam':
			case 'prosite':
			case 'reactome':
			case 'cazy':
				sparql = this.dbsparql(mapping[aspect]);
				break;
			case 'ctd':
			case 'brenda':
			case 'eggnog':
			case 'genetree':
			case 'hogenom':
			case 'hovergen':
			case 'inparanoid':
			case 'ko':
			case 'oma':
			case 'orthodb':
			case 'phylomedb':
			case 'treefam':
			case 'nextbio':
			case 'paxdb':
			case 'pride':
				sparql = this.dbsparql_link(mapping[aspect]);
				break;
		}
		return sparql;
	},

	// generate a SPARQL query fragment for database selection with label
	dbsparql: function(db) {
		return '\
			?up rdfs:seeAlso ?link .\n\
			?link up:database db:@@database@@ .\n\
			?link rdfs:comment ?label .'.replace(/@@database@@/, db);
	},
	// generate a SPARQL query fragment for database selection without label (use link instead)
	dbsparql_link: function(db) {
		return '\
			?up rdfs:seeAlso ?label .\n\
			?label up:database db:@@database@@ .'.replace(/@@database@@/, db);
	},

	/* アスペクトと生物種から集合を作る
	 *
	 */
	step1: function(){
		var self = this, taxIds, commonNames, sparql;

		// 既存の結果の削除
		this.$combinationH2.empty();
		this.$combinationResultsGraph.empty();
		this.$sectionCategory.addClass('disabled');
		this.$categoryContainer.empty();
		this.$categoryH2.empty();
		this.$sectionLinkTo.addClass('disabled');
		this.$linkToContainer.empty();

		if (!this.cache.aspect || this.cache.species.length === 0) {
			this.$sectionCombination.addClass('disabled');
			return;
		}

		this.$sectionCombination.addClass('loading');

		// クエリ
		taxIds = this.cache.species.map(function(taxon){
				return taxon.taxId;
			});
		commonNames = this.cache.species.map(function(taxon){
				return taxon.data.common_name;
			});
		sparql = SPARQLS.step1
			.replace(/@@taxvalues@@/, 'tax:' + taxIds.join(' tax:') )
			.replace(/@@aspect@@/, this.aspectSparql(this.cache.aspect));

		d3sparql.query(ENDPOINT, sparql, function(response){
			var html = '',
					results = response.results.bindings,
					setPrefix = 'set' + this.cache.species.length + '-',
					unsortedTaxIds, count = [], max, commonNames2, setValue, barWidth;
			// 有効化
			this.$sectionCombination.removeClass('disabled loading');
			this.d3VennDiagramTexts.text('');

			// 結果のソート
			results.forEach(function(d){
				unsortedTaxIds = d.orgs.value.split(', ');
				d.taxIds = [];
				d.taxIdIndices = [];
				taxIds.forEach(function(taxId, index){
					if (unsortedTaxIds.indexOf(taxId) !== -1) {
						d.taxIds.push(taxId);
						d.taxIdIndices.push(index);
					}
				});
				count.push(parseInt(d.count.value));
			});
			max = Math.max.apply(null, count);
			results.sort(function(a, b){
				if( a.taxIds.length > b.taxIds.length ) return -1;
				if( a.taxIds.length < b.taxIds.length ) return 1;
				return 0;				
			});

			// 結果の描画
			results.forEach(function(d){
				// 結果の描画：図表
				commonNames2 = d.taxIdIndices.map(function(taxIdIndex){
					return commonNames[taxIdIndex];
				});
				setValue = setPrefix + d.taxIdIndices.join('_');
				barWidth = (parseInt(d.count.value) / max) * 100;
				html += '\
					<div class="bar-chart set' + d.taxIds.length + '" data-set="' + setValue + '" data-value="' + d.orgs.value + '">\
						<p class="bar-name">' + commonNames2.join('<span class="sign">∩</span>') + '</p>\
						<div class="color-ball ' + setValue + '"></div>\
						<div class="bar' + (barWidth >= 50 ? ' over-half' : '') + '" style="width: ' + barWidth + '%;"><span>' + d.count.value + '</span></div>\
					</div>';
				// 結果の描画：ベン図
				d3.select('#venn-text-' + setPrefix + d.taxIdIndices.join('_')).text(d.count.value);
			});

			this.$combinationResultsGraph
				.empty()
				.append(wrapInner(html));
			// イベント
			this.$combinationResultsGraph.find('.bar-chart')
				.on({
					mouseenter: function(){
						self.$sectionCombination.addClass('hovering');
						if (!this.d3TargetShape) {
							this.d3TargetShape = d3.select('#venn-shape-' + this.dataset.set);
							this.d3TargetText = d3.select('#venn-text-' + this.dataset.set);
						}
						this.d3TargetShape.classed({ relative: true });
						this.d3TargetText.classed({ relative: true });
					},
					mouseleave: function(){
						self.$sectionCombination.removeClass('hovering');
						this.d3TargetShape.classed({ relative: false });
						this.d3TargetText.classed({ relative: false });
					},
					click: function(){
						$(this)
							.siblings().removeClass('selected')
							.end().addClass('selected');
						self.step2(this.dataset.value);
					}
				});
			this.d3VennDiagrams.selectAll('.part')
				.on('mouseenter', function(){
					self.$sectionCombination.addClass('hovering');
					var setName = this.id.replace('venn-shape-', '');
					this.$targetBar = self.$combinationResultsGraph.find('[data-set="' + setName + '"]');
					this.d3TargetText = d3.select('#venn-text-' + setName);
					this.$targetBar.addClass('relative');
					this.d3TargetText.classed({ relative: true });
				})
				.on('mouseleave', function(){
					self.$sectionCombination.removeClass('hovering');
					this.$targetBar.removeClass('relative');
					this.d3TargetText.classed({ relative: false });
				})
				.on('click', function(){
					$(this.$targetBar).trigger('click');
				});

		}.bind(this));

	},

	/* 生物種の taxon id の集合からアスペクトの内訳一覧を作る
	 */
	step2: function(taxIds) {
		var self = this, sparql, html = '', results, barWidth, sum, max;
		this.cache.taxIds = taxIds;

		// 有効化
		var taxIds2 = this.cache.taxIds.split(', ').map(function(taxId){
			return parseInt(taxId);
		});
		var commonNames = taxIds2.map(function(taxId){
			return self.getValueWithKeyValue('common_name', 'taxid', taxId);
		});
		this.$combinationH2.html(commonNames.join('<span class="sign">∩</span>'));
		//this.$sectionCategory.removeClass('disabled');

		// 既存の結果の削除
		this.$categoryContainer.empty();
		this.$categoryH2.empty();
		this.$sectionLinkTo.addClass('disabled');
		this.$linkToContainer.empty();
		this.$sectionCategory.addClass('loading');

		// クエリ
		sparql = SPARQLS.step2
			.replace(/@@taxvalues@@/, this.taxIdsWithString(this.cache.taxIds))
			.replace(/@@taxfilter@@/, this.cache.taxIds)
			.replace(/@@aspect@@/, this.aspectSparql(this.cache.aspect));

		d3sparql.query(ENDPOINT, sparql, function(response){
			results = response.results.bindings;

			// 有効化
			self.$sectionCategory.removeClass('disabled loading');

			// 最大値
			sum = results.map(function(result){
				return parseInt(result.sum.value);
			});
			max = Math.max.apply(null, sum);

			// グラフの描画
			results.forEach(function(d){
				barWidth = (parseInt(d.sum.value) / max) * 100;
				html += '\
					<div class="bar-chart" data-value="' + d.label.value + '">\
						<p class="bar-name">' + d.label.value + '</p>\
						<div class="bar' + (barWidth >= 50 ? ' over-half' : '') + '" style="width: ' + barWidth + '%;"><span>' + d.sum.value + '</span></div>\
					</div>';
			});
			self.$categoryContainer.html(wrapInner(html));
			// イベント
			self.$categoryContainer.find('.bar-chart')
				.on('click', function(){
					$(this)
						.siblings().removeClass('selected')
						.end().addClass('selected');
					self.step3(this.dataset.value);
				});
		});

	},

	/* 生物種の taxon id の集合からアスペクトの内訳一覧を作る
	 */
	step3: function(category) {
		var self = this, sparql, header, results, html;

		// 有効化
		this.$categoryH2.text(category);

		// 既存の結果の削除
		this.$linkToContainer.empty();
		this.$sectionLinkTo.addClass('loading');

		// クエリ
    if (category.indexOf('http://purl.uniprot.org') < 0) {
      this.category = '"' + category + '"';
    } else {
      this.category = '<' + category + '>';
    }
		sparql = SPARQLS.step3
			.replace(/@@taxvalues@@/, this.taxIdsWithString(this.cache.taxIds))
			.replace(/@@category@@/, this.category)
			.replace(/@@aspect@@/, this.aspectSparql(this.cache.aspect));

		d3sparql.query(ENDPOINT, sparql, function(response){
			// 有効化
			self.$sectionLinkTo.removeClass('disabled loading');

			header = response.head.vars;
			results = response.results.bindings;
			html = '<table><thead>@@thead@@</thead><tbody>@@tbody@@</tbody></table>'
				.replace(/@@thead@@/, header
					.map(function(value){ return '<th>' + LINKS_TO_HEADER_LABEL_MAPPING[value] + '</th>'; })
					.join('')
				)
				.replace(/@@tbody@@/, results
					.map(function(value){
						var tr = header
							.map(function(headerEml){
								return '<td><a href="@@uri@@" target="_blank">@@uri@@</a></td>'.replace(/@@uri@@/g, value[headerEml].value);
							})
							.join('');
						return '<tr>' + tr + '</tr>';
					})
					.join('')
				);

			self.$linkToContainer.html(wrapInner(html));
		});

	},

	// [ 123, 456 ] -> 'tax:123 tax:456'
	taxIdsWithArray: function(array) {
		return array.map(function(d) { return 'tax:' + d; }).join(' ');
	},

	// '123, 456' -> 'tax:123 tax:456'
	taxIdsWithString: function(string) {
		return string.split(', ').map(function(d) { return 'tax:' + d; }).join(' ');
	}
};



$(function() {

	application = new Application();

	// TogoGenome 埋め込みにあたっての処置
	$('#search-methods-selector').css({
		zIndex: 1000
	});

	// taxon の読み込み
	d3.json("taxonomy.json", function(data){
		application.initialize(data);
	});

});
