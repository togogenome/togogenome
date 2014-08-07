var ___c = window.console;

$(function(){
  $w = $(window);

  // ナビゲーションのインジケータとスクロール位置の連動
  {
    var $ulNav = $("#navbar ul.nav");
    if ($ulNav.length >= 1) {
      var LIST_ADDITION_WIDTH = 4,
          ulWidth = 0;
      $("li", $ulNav).each(function(){
        ulWidth += $(this).width() + LIST_ADDITION_WIDTH;
      });
      $ulNav.width(ulWidth);
      $w.scroll(function(){
        if (ulWidth > window.innerWidth) {
          var wholeHeight = document.body.clientHeight - window.innerHeight,
              scrollRatio = document.body.scrollTop / wholeHeight,
              ulLeft = Math.round((ulWidth - window.innerWidth) * scrollRatio);
          $ulNav.css({ left: "-" + ulLeft + "px" });
        } else {
          $ulNav.css({ left: "0px" });
        }
      });
    }
  }

  // 検索ウインドウの開閉
  {
    var methodSelector = {}; // name space
    methodSelector.$ = $("#search-methods-selector");
    // shut button
    methodSelector.$shutButton = $(".search-methods-visibility-button", methodSelector.$);
    methodSelector.$methods = $("#methods");
    methodSelector.HIDE = "Hide";
    methodSelector.SHOW = "Show";
    methodSelector.isShut = false;
    methodSelector.$shutButton.click(function(){
      if (methodSelector.isShut) {
        methodSelector.$shutButton.removeClass(methodSelector.HIDE);
        methodSelector.$shutButton.text(methodSelector.HIDE);
        methodSelector.$methods.css({ display: "block" });
      } else {
        methodSelector.$shutButton.addClass(methodSelector.HIDE);
        methodSelector.$shutButton.text(methodSelector.SHOW);
        methodSelector.$methods.css({ display: "none" });
      }
      methodSelector.isShut = !methodSelector.isShut;
    });
  }

  // ID Mapping
  // TODO: ステップ数を選ぶGUI
  // TODO: 矢印にしっぽをつける
  // TODO: undo の GUI:
  // TODO: リセット の GUI
  {
    var $mappingsContainer = $("#mappings-container");
    if ($mappingsContainer) {
      var IDM = {}; // name space
      IDM.RESULTS_DEFAULT_HEIGHT = 120;
      IDM.ROUTE_HEIGHT = 21;
      IDM.DB_ICON_SIZE = 16;
      IDM.RESULT_AREA_MARGIN = 0;
      IDM.SMALL_DB_ICON_TOP = 3;
      IDM.SMALL_DB_ICON_HEIGHT = 13;
      IDM.LARGE_DB_ICON_HEIGHT = 26;
      IDM.Z_INDEX = 120;
      IDM.STEP_DURATION = 400;
      IDM.EXCLUDE_SAME_CATEGORY = true;
      IDM.DB_ICON_TOP = (IDM.ROUTE_HEIGHT - IDM.DB_ICON_SIZE) * .5;
      IDM.DB_ICON_DEFAULT_COLOR = "#aaa",
      IDM.CLASSES = {};
      IDM.CLASSES.HIGHLIGHTING = "highlighting";
      IDM.CLASSES.SELECTED = "selected-route";
      IDM.CLASSES.HOVERING = "hovering";
      IDM.CLASSES.SHOWING_RESULT = "showing-result";
      IDM.CLASSES.DECIDING_ROUTE = "deciding-route";
      IDM.CLASSES.DECIDED_ROUTE = "decided-route";
      IDM.DIRECT_ROUTE = "direct route";
      IDM.MODE_CONVERTER = "converter";
      IDM.CONVERTER_DEFAULT_STEP = 4;
      IDM.MODE_RESOLVER = "resolver";
      IDM.RESOLVER_DEFAULT_STEP = 5;
      IDM.selectedDb = { from: "", to: "" };
      IDM.THE_OHTER_DB_NAMES = { from: "to", to: "from" };
      IDM.LOCATIVE_CAPITALIZED = { from: "From", to: "To" };
      IDM.selectedDbListItem = { from: undefined, to: undefined };
      IDM.arrowLayers = [];
      IDM.routes = [];
      IDM.route = [];
      IDM.routesHistory = [];
      IDM.results = {};
      IDM.results.width = 0;
      IDM.results.height = 0;
      IDM.d3ArrowLine = d3.svg.line()
        .interpolate('basis')
        .x(function(d){ return d[0]; })
        .y(function(d){ return d[1]; }),
      IDM.d3ArrowheadLine = d3.svg.line()
        .x(function(d){ return d[0]; })
        .y(function(d){ return d[1]; });
      IDM.sampleMode = true;

      /* DBリストクラス
       */
      IDM.DBList = function($target) {
        var $ul = $("ul", $target),
            $arrow = $(".arrow", $target),
            $bg = $(".bg", $target).click(function(){
                close();
              }),
            $inner = $(".inner", $target),
            LEFT_ADJUST = 10,
            TOP_ADJUST = -3,
            TOP_OFFSET = 50,
            BOTTOM_OFFSET = 6,
            self = this;
        this.$ = $target;

        // 始点・終点のDBリストを開く
        this.openEndDBList = function() {
          var height = $w.innerHeight() - TOP_OFFSET - BOTTOM_OFFSET;
          $target.height(height);
          $inner.height(height - $inner.position().top - 15);
          open($target.prev());
        }

        // DBリストを開く
        var open = function($node) {
          // 左右いずれに出るか
          var nodeOffset = $node.offset();
          var isRight = false;
          if ($w.width() * .5 < nodeOffset.left) {
            isRight = true;
            $target.addClass("is-right");
          } else {
            $target.removeClass("is-right");
          }
          // 位置
          var middle = $target.outerHeight() * .5;
          var parentOffset = $target.parent().offset();
          var top = nodeOffset.top + $node.outerHeight() * .5 - middle + TOP_ADJUST;
          var topOffset = TOP_OFFSET + $w.scrollTop();
          top = top < topOffset ? topOffset : top;
          var left;
          if (isRight) {
            left = nodeOffset.left - LEFT_ADJUST - $target.width();
          } else {
            left = nodeOffset.left + $node.width() + LEFT_ADJUST;
          }
          $target.css({
            top: top - parentOffset.top,
            left: left - parentOffset.left
          });
          // 矢印の位置
          $arrow.css("top", nodeOffset.top + $node.outerHeight() * .5 - top - 3);
          // 背景
          $bg.css({
            width: $w.width() * 2,
            height: $w.height() * 2,
            top:  -top,
            left:  -left,
          });
          // 開く
          $target.addClass("open");
          $w.on("keyup.dblist", function(e){
            if (e.keyCode == 27) close();
          });
        }

        // DBリストを閉じる
        var close = function() {
          $target.removeClass("open");
          $w.off("keyup.dblist");
        }
        this.close = function() {
          close();
        }

      };


      // DB情報の読み込み
      // json読み込みをトリガーとしてアプリを駆動
      $.getJSON("/dbmapping.json", function(data){

        /* DBの選択
         * @param String locative: 始点（"from"）か終点（"to"）か
         * @param String id: 選択されたDB名
         * @param Array decidedRoute: 決定されたルート（オプション）
         * decidedRoute が渡されていた場合、ルートも決定されているため、ルート検索を飛ばす
         */
        IDM.selectDB = function(locative, id, decidedRoute) {
          // 選択されたDBのセット
          var $icon = IDM.dbLargeIcon[locative];
          $(".side, .lid", $icon).css("background-color", IDM.hslFromCategory(IDM.DBs[id].category));
          IDM.$dbList[locative].removeClass("open");
          IDM.dbLargeIconLabel[locative].text(IDM.DBs[id].label);
          IDM.dbLargeIconLabel[locative].addClass("selected");
          IDM.selectedDb[locative] = id;

          switch (true) {
            case (IDM.mode == IDM.MODE_CONVERTER):
            {
              // もう一方のセレクタ中の同じDBを選択不可能に
              var $theOtherDbList = IDM.$dbList[IDM.THE_OHTER_DB_NAMES[locative]];
              $("[data-dbid='" + IDM.selectedDb[locative] + "']", $theOtherDbList).removeClass("disable");
              $("[data-dbid='" + id + "']", $theOtherDbList).addClass("disable");
              // もしどちらのDBも選択されていれば、ルート検索を開始
              if (IDM.selectedDb["from"] != "" && IDM.selectedDb["to"] != "") {
                var availableRoutes = [];
                if (decidedRoute) { // すでにルートが確定している場合
                  availableRoutes.push(decidedRoute);
                } else {
                  IDM.searchRoute([IDM.selectedDb.from], IDM.selectedDb.to, availableRoutes);
                }
                // 前回のルートの消去
                IDM.deleteResults(false);
                // ルート描画
                IDM.routesHistory = [];
                IDM.routes = IDM.sortConverterRoutes(availableRoutes);
                IDM.routesHistory.push(IDM.routes);
                IDM.makeConverterRoutes();
              }
            }
              break;
            case (IDM.mode == IDM.MODE_RESOLVER):
            {
              if (decidedRoute) { // すでにルートが確定している場合
              }
              // ルート描画
              IDM.makeResolverRoutes(id, decidedRoute);
            }
              break;
          }
        }

        /* 初期化
         */
        IDM.reset = function() {
          for (var locative in IDM.dbLargeIcon) {
            var $icon = IDM.dbLargeIcon[locative];
            $(".side, .lid", $icon).css("background-color", IDM.DB_ICON_DEFAULT_COLOR);
            IDM.$dbList[locative].removeClass("open");
            IDM.dbLargeIconLabel[locative].text(IDM.LOCATIVE_CAPITALIZED[locative]);
            IDM.dbLargeIconLabel[locative].removeClass("selected");
            IDM.selectedDb[locative] = undefined;
            $("dd > p", IDM.$dbList[locative]).removeClass("disable");
            $(IDM.selectedDbListItem[locative]).removeClass("selected");
            IDM.selectedDbListItem[locative] = undefined;
          }
          IDM.deleteResults(false);
          IDM.$resultsContainer.removeClass(IDM.CLASSES.SHOWING_RESULT);
          switch (true) {
            case (IDM.mode == IDM.MODE_CONVERTER):
              IDM.routes = [];
              IDM.routesHistory.push(IDM.routes);
              break;
            case (IDM.mode == IDM.MODE_RESOLVER):
              d3.select("#mapping-arrows-container svg").remove();
              break;
          }
          // テーブルの初期化
          IDM.selectRoute([]);
        }

        /* リゾルバー（探索型）ルート描画
         */
        IDM.makeResolverRoutes = function(db, decidedRoute) {

          // 画面消去
          d3.select("#mapping-arrows-container svg").remove();
          IDM.$hoveringRoute.empty();
          IDM.$dbIconsContainer.empty();

          // 初期化
          if (decidedRoute) {
            db = decidedRoute.pop();
          }
          var route = decidedRoute ? decidedRoute : [],
              d3ArrowsSvg = d3.select("#mapping-arrows-container").append("svg").attr("id", "arrows-svg"),
              ARROW_HEAD_MARGIN = 12,
              ARROW_HEAD_LENGTH = 4,
              links = IDM.DBs[db].links,
              stepUnit = (100 - IDM.RESULT_AREA_MARGIN * 2) / (route.length + 1),
              stepUnit2 = stepUnit * .01;
          IDM.results.width = IDM.$resultsContainer.get(0).clientWidth;
          IDM.results.height = IDM.ROUTE_HEIGHT * links.length;
          var resultTop = IDM.results.height > IDM.RESULTS_DEFAULT_HEIGHT ? 0 : (IDM.RESULTS_DEFAULT_HEIGHT - IDM.results.height) * .5;


          // やじりのパスに添うアニメーション
          var arrowheadTween = function(path){
            var l = path.getTotalLength();
            return function(i) {
              return function(t) {
                var p = path.getPointAtLength(t * l);
                var prevT = t - .02;
                prevT = prevT < 0
                  ? 0
                  : prevT;
                var prevP = path.getPointAtLength(prevT * l);
                var radian = Math.atan2(p.x - prevP.x, p.y - prevP.y);
                var degree = 450 - radian * 180 / Math.PI;
                return "translate(" + p.x + "," + p.y + ") rotate(" + degree + ")";
              }
            }
          }

          /* 矢印の描画
           * @param Boolean animation: アニメーションを伴うか
           */
          var drawArrows = function(animatiing){
            // 確定済みルート
            for (var i = 0; i < route.length - 1; i++) {
              var selector = "#mapping-arrows-container .s" + (i + 1) + " g",
                  d3ArrowGroups = d3.selectAll(selector);
              //window.console.log(selector);
              //window.console.log(d3ArrowGroups);
              if (d3ArrowGroups.size() == 0) {
                var d3ArrowsGroup = d3ArrowsSvg.append("g").attr({ "class": "s" + (i + 1) }),
                    d3Group = d3ArrowsGroup.append("g")
                      .attr({
                        "class": IDM.CLASSES.SELECTED,
                        "data-db": route[i + 1]
                      });
                d3Group.append("path").attr({
                  "class": "arrow"
                });
                d3Group.append("path").attr({
                  "d": IDM.d3ArrowheadLine([[-ARROW_HEAD_LENGTH, -ARROW_HEAD_LENGTH], [0, 0], [-ARROW_HEAD_LENGTH, ARROW_HEAD_LENGTH]]),
                  "class": "arrowhead"
                });
                d3ArrowGroups = d3.selectAll(selector);
              }
              d3ArrowGroups.each(function(){
                var d3ArrowGroup = d3.select(this);
                if (this.getAttribute("data-db") == route[i + 1]) {
                  var x1 = (i * stepUnit2) * IDM.results.width + 1,
                      x2 = x1 + IDM.results.width * stepUnit2 - ARROW_HEAD_MARGIN,
                      y = IDM.results.height * .5,
                      pos1 = [x1, y],
                      pos2 = [x1 * .6667 + x2 * .3333, y],
                      pos3 = [x1 * .3333 + x2 * .6667, y],
                      pos4 = [x2, y],
                      transform = "translate(" + x2 + ", " + y + ")";
                  if (animatiing) { // アニメーションする
                    d3ArrowGroup.select("path.arrow")
                      .transition()
                        .duration(IDM.STEP_DURATION)
                        .ease("cubic-out")
                        .attr("d", IDM.d3ArrowLine([pos1, pos2, pos3, pos4]));
                    d3ArrowGroup.select("path.arrowhead")
                      .transition()
                        .duration(IDM.STEP_DURATION)
                        .ease("cubic-out")
                        .attr("transform", transform);
                  } else { // アニメーションしない
                    d3ArrowGroup.select("path.arrow")
                      .attr("d", IDM.d3ArrowLine([pos1, pos2, pos3, pos4]));
                    d3ArrowGroup.select("path.arrowhead")
                      .attr("transform", transform);
                  }
                } else { // 不要なルートであれば削除
                  d3ArrowGroup.remove();
                }
              });
            }
            // 右端の分岐ルート
            var x1 = ((route.length - 1) * stepUnit2) * IDM.results.width + 1,
                x2 = x1 + IDM.results.width * stepUnit2 - ARROW_HEAD_MARGIN,
                y1 = IDM.results.height * .5,
                d3ArrowGroup = d3.selectAll("#mapping-arrows-container .s" + route.length),
                isNew = d3ArrowGroup.size() == 0;
            if (isNew) d3ArrowsGroup = d3ArrowsSvg.append("g").attr({ "class": "s" + route.length });
            for (var i = 0; i < links.length; i++) {
              var d3Group;
              if (isNew) {
                d3Group = d3ArrowsGroup.append("g")
                  .attr({
                    "class": "r" + i,
                    "data-db": links[i]
                  });
              } else {
                d3Group = d3ArrowGroup.select(".r" + i);
              }
              //矢
              var y2 = resultTop + i * IDM.ROUTE_HEIGHT + IDM.ROUTE_HEIGHT * .5,
                  pos1 = [x1, y1],
                  pos2 = [x1 * .75 + x2 * .25, y1],
                  pos3 = [x1 * .25 + x2 * .75, y2],
                  pos4 = [x2, y2];
              var d3ArrowPath;
              if (isNew) {
                d3ArrowPath = d3Group.append("path")
                  .attr({
                    "d": IDM.d3ArrowLine([pos1, pos2, pos3, pos4]),
                    "class": "arrow"
                  });
                var totalLength = d3ArrowPath.node().getTotalLength();
                d3ArrowPath
                  .attr({
                    "stroke-dasharray": totalLength + " " + totalLength,
                    "stroke-dashoffset": totalLength
                  })
                  .transition()
                    .duration(IDM.STEP_DURATION)
                    .ease("in")
                    .attr("stroke-dashoffset", 0)
                  .each("end", function(){
                    d3.select(this)
                      .attr({
                        "stroke-dasharray": null,
                        "stroke-dashoffset": null
                      });
                  });
              } else {
                d3ArrowPath = d3Group.select(".arrow");
                d3ArrowPath.attr("d", IDM.d3ArrowLine([pos1, pos2, pos3, pos4]));
              }

              // やじり
              if (isNew) {
                d3Group.append("path")
                  .attr({
                    "d": IDM.d3ArrowheadLine([[-ARROW_HEAD_LENGTH, -ARROW_HEAD_LENGTH], [0, 0], [-ARROW_HEAD_LENGTH, ARROW_HEAD_LENGTH]]),
                    "class": "arrowhead"
                  })
                  .transition()
                    .duration(IDM.STEP_DURATION)
                    .ease("in")
                    .attrTween('transform', arrowheadTween(d3ArrowPath.node()));
              } else {
                d3Group.select(".arrowhead")
                  .attr("transform", "translate(" + x2 + "," + y2 + ")");
              }
            }
          }

          // 横幅
          $w.on("resize.adjustWidthResolverCase", function(){
            // 矢印の再描画
            d3ArrowsSvg.attr("width", IDM.results.width);
            drawArrows(false);
          });
          $w.trigger("resize");

          // ルート描画（再起的に呼ばれる）
          var makeResolverRoutes = function(db, index){
            var trimmedRoute = route.splice(index);
            route[index] = db;
            links = IDM.DBs[db].links;
            stepUnit = (100 - IDM.RESULT_AREA_MARGIN * 2) / (route.length + 1),
            stepUnit2 = stepUnit * .01;
            var html = "";

            // 重複するリンク先の削除
            links = [];
            for (var i = 0; i < IDM.DBs[db].links.length; i++) {
              var linkedDb = IDM.DBs[db].links[i];
              if ($.inArray(linkedDb, route) == -1) {
                links.push(linkedDb);
              }
            }

            // 不要な要素の削除
            for (var i = 0; i < (trimmedRoute.length + 1); i++) {
              var step = i + index;
              $("[data-step='" + step + "']", IDM.$dbIconsContainer).remove();
              d3.selectAll("#mapping-arrows-container .s" + step).remove();
            }

            // 次のDBの候補を描画

            // 領域全体の高さ定義
            IDM.results.height = IDM.ROUTE_HEIGHT * links.length;
            resultTop = IDM.results.height > IDM.RESULTS_DEFAULT_HEIGHT ? 0 : (IDM.RESULTS_DEFAULT_HEIGHT - IDM.results.height) * .5;
            IDM.results.height = IDM.results.height > IDM.RESULTS_DEFAULT_HEIGHT ? IDM.results.height : IDM.RESULTS_DEFAULT_HEIGHT;
            IDM.$resultsContainer
              .addClass(IDM.CLASSES.SHOWING_RESULT)
              .css("height", IDM.results.height);
            d3ArrowsSvg
              .attr({
                "width": IDM.results.width,
                "height": IDM.results.height
              });

            { // DBアイコンの生成
              // 確定済みルートのDBアイコンの移動と、それ以外の削除
              for (var i = 0; i < route.length - 1; i++) {
                var $icons = $("[data-step='" + (i + 1) + "']", IDM.$dbIconsContainer);
                if ($icons.length == 0) { // アイコンが存在しない場合、生成
                  html = IDM.makeSmallDBIconHTML({
                    category: IDM.DBs[route[i + 1]].category,
                    db: route[i + 1],
                    routeClass: IDM.CLASSES.SELECTED,
                    colIndex: i + 1,
                    colUnit: stepUnit,
                    height: IDM.DB_ICON_SIZE,
                    rowIndex: 0,
                    topOffset: resultTop,
                    label: IDM.DBs[route[i + 1]].label,
                    isOnlyIcon: false
                  });
                  IDM.$dbIconsContainer.append(html);
                  $icons = IDM.$dbIconsContainer.children().last();
                }
                $icons.each(function(){
                  $this = $(this);
                  if ($this.data("db") == route[i + 1]) {
                    $this
                      .addClass(IDM.CLASSES.SELECTED)
                      .css({
                        left: (IDM.RESULT_AREA_MARGIN + stepUnit * (i + 1)) + "%",
                        top: (IDM.results.height * .5 - IDM.DB_ICON_SIZE * .5) + "px"
                      });
                  } else {
                    $this.remove();
                  }
                });
              }
              IDM.selectRoute(route);
              // 選択肢のDBアイコンの生成
              //var left = (IDM.RESULT_AREA_MARGIN + stepUnit * route.length) + "%";
              html = "";
              for (var i = 0; i < links.length; i++) {
                var nextDb = links[i];
                html += IDM.makeSmallDBIconHTML({
                  category: IDM.DBs[nextDb].category,
                  db: nextDb,
                  routeClass: "r" + i,
                  colIndex: route.length,
                  colUnit: stepUnit,
                  height: IDM.DB_ICON_SIZE,
                  rowIndex: i,
                  topOffset: resultTop,
                  label: IDM.DBs[nextDb].label,
                  isOnlyIcon: false
                });
              }
              IDM.$dbIconsContainer.append(html);
              // DBアイコンのインタラクション
              $(".node", IDM.$dbIconsContainer)
                .each(function(){
                  if (this.initialized) return;
                  this.initialized = true;
                  var $this = $(this),
                      classes = $this.attr("class").split(" "),
                      aRoute;
                  for (var j = 0; j < classes.length; j++) {
                    var className = classes[j];
                    if (className.indexOf("r") == 0) aRoute = parseInt(className.substring(1));
                  }
                  $this
                    .data("route", aRoute)
                    .on({
                      "mouseenter.selecteingRoute": function(){
                        if ($this.hasClass(IDM.CLASSES.SELECTED)) return;
                        // ルートのハイライト
                        IDM.$resultsContainer.addClass(IDM.CLASSES.HIGHLIGHTING);
                        $(".r" + aRoute, IDM.$resultsContainer).attr("class", function(index, classNames){
                          return classNames + " " + IDM.CLASSES.HOVERING;
                        });
                      },
                      "mouseleave.selecteingRoute": function(){
                        if ($this.hasClass(IDM.CLASSES.SELECTED)) return;
                        IDM.$resultsContainer.removeClass(IDM.CLASSES.HIGHLIGHTING);
                        $(".r" + aRoute, IDM.$resultsContainer).attr("class", function(index, classNames){
                          return classNames.replace(" " + IDM.CLASSES.HOVERING, "");
                        });
                      },
                      "click.selecteingRoute": function(){
                        if (!$this.hasClass(IDM.CLASSES.SELECTED)) {
                          // 未選択のDBの場合
                          // 同ルートを選択状態にする
                          $(".r" + aRoute, IDM.$resultsContainer).attr("class", function(index, classNames){
                            return classNames + " " + IDM.CLASSES.SELECTED;
                          });
                          IDM.$resultsContainer.removeClass(IDM.CLASSES.HIGHLIGHTING);
                        }
                        // 新しいルートの生成
                        makeResolverRoutes($this.data("db"), parseInt($this.data("step")));
                      }
                    })
                })
            }

            // 矢印の生成・変形
            drawArrows(true);

            { // ルートの確定（resolver では都度ルートが確定される）
            }
          }
          makeResolverRoutes(db, route.length);

          // 大本のDBアイコンをクリックすると、そこからの選択肢が現れる
          IDM.dbLargeIcon.from
            .off("click.selecteingRoute")
            .on("click.selecteingRoute", function(){
              makeResolverRoutes(route[0], 0);
            });
        }

        /* コンバーター（一覧型）ルートのソート
         */
        IDM.sortConverterRoutes = function(routes1) {
          var routes2 = [];
          // ステップ数の少ない順にソート
          for (var i = 2; i <= IDM.step; i++) {
            for (var j = 0; j <= routes1.length; j++) {
              if (routes1[j] && routes1[j].length == i) {
                routes2.push(routes1[j]);
                delete routes1[j];
              }
            }
          }
          if (IDM.EXCLUDE_SAME_CATEGORY) {
            // 同カテゴリのDBが続く場合排除
            var excludedRoutes = [];
            for (var i = 0; i < routes2.length; i++) {
              var route = routes2[i];
              if (route.length == 2) {
                // 中間のDBがない場合は有効
                excludedRoutes.push(route);
              } else {
                var differ = true;
                for (var j = 0; j < (route.length - 1); j++) {
                  //if (IDM.DBs[route[j]].category == IDM.DBs[route[j + 1]].category) differ = false;
                }
                if (differ) excludedRoutes.push(route);
              }
            }
            return excludedRoutes;
          } else {
            return routes2;
          }
        }

        /* コンバーター（一覧型）ルート描画
         */
        IDM.makeConverterRoutes = function() {

          // ひとつもルートがない場合
          if (IDM.routes.length == 0) {
            html = "<p class='result-message'>Found no route.</p>";
            IDM.$resultsContainer
              .append(html)
              .removeClass(IDM.CLASSES.SHOWING_RESULT);
            return;
          }

          // 領域全体の高さ定義
          IDM.results.height = IDM.ROUTE_HEIGHT * IDM.routes.length;
          var resultTop = (IDM.results.height > IDM.RESULTS_DEFAULT_HEIGHT) ? 0 : (IDM.RESULTS_DEFAULT_HEIGHT - IDM.results.height) * .5;
          IDM.$resultsContainer
            .addClass(IDM.CLASSES.SHOWING_RESULT)
            .css("height", IDM.results.height);
          var html = "";

          // DBアイコンの生成
          for (var r = 0; r < IDM.routes.length; r++) {
            var route = IDM.routes[r];
            // 行の走査
            var colUnit = (100. - IDM.RESULT_AREA_MARGIN * 2.) / (route.length - 1.);
            for (var c = 1; c < (route.length - 1); c++) {
              //var category = route[c]; // カテゴリノードの場合
              var db = route[c];
              //var category = IDM.DBs[db].category;
              var routeClass = "r" + r;
              // 上のリザルトと同じDBであれば、スキップする
              if (r > 0) {
                var prevRoute = IDM.routes[r - 1];
                if (prevRoute.length == route.length && prevRoute[c] == db) continue;
                //if (prevRoute.length == route.length && prevRoute[c] == category) continue; // カテゴリノードの場合
              }
              // 後続のリザルトが同じDBか調べる
              var height = IDM.DB_ICON_SIZE;
              if (r < (IDM.routes.length - 1)) {
                for (r2 = r + 1; r2 < IDM.routes.length; r2++) {
                  var nextRoute = IDM.routes[r2];
                  if (route.length != nextRoute.length || db != nextRoute[c]) break;
                  //if (route.length != nextRoute.length || category != nextRoute[c]) break; // カテゴリノードの場合
                  height += IDM.ROUTE_HEIGHT;
                  routeClass += " r" + r2;
                }
              }
              // HTMLの生成
              var hsl = "style='background-color:" + IDM.hslFromCategory(category) + "'";
              html += IDM.makeSmallDBIconHTML({
                category: IDM.DBs[db].category,
                db: db,
                routeClass: routeClass,
                colIndex: c,
                colUnit: colUnit,
                height: height,
                rowIndex: r,
                topOffset: resultTop,
                label: IDM.DBs[db].label,
                isOnlyIcon: false
              });
            }
          }
          IDM.$dbIconsContainer.append(html);
          // DBアイコンのインタラクション
          $(".node", IDM.$dbIconsContainer)
            .on({
              "mouseenter.selecteingRoute": function(){ // ルートのハイライト
                IDM.$hoveringRoute.empty();
                if (!IDM.$resultsContainer.hasClass(IDM.CLASSES.HIGHLIGHTING)) {
                  IDM.$resultsContainer.addClass(IDM.CLASSES.HIGHLIGHTING);
                }
                var selecter = "";
                var routeClasses = [];
                var $sameDBs = $("[data-db='" + $(this).data("db") + "'][data-step='" + $(this).data("step") + "']", IDM.$resultsContainer)
                  .each(function(){
                    // 選択されたDBを通るルートの抽出
                    var classes = this.className.split(" ");
                    for (var i = 0; i < classes.length; i++) {
                      var className = classes[i];
                      if (className.charAt(0) == "r" && $.inArray(className, routeClasses) == -1) {
                        routeClasses.push(className);
                      }
                    }
                  })
                  .clone().appendTo(IDM.$hoveringRoute);
                var $routes = $("." + routeClasses.join(", ."), IDM.$resultsContainer)
                  .clone().appendTo(IDM.$hoveringRoute);
              },
              "mouseleave.selecteingRoute": function(){
                if (IDM.$resultsContainer.hasClass(IDM.CLASSES.HIGHLIGHTING)) {
                  IDM.$resultsContainer.removeClass(IDM.CLASSES.HIGHLIGHTING);
                }
                IDM.$hoveringRoute.empty();
              },
              "click.selecteingRoute": function(e){
                IDM.$resultsContainer.removeClass(IDM.CLASSES.HIGHLIGHTING);
                IDM.$hoveringRoute.empty();
                // ルートをフィルタリング
                var filteredRoutes = IDM.filterRoutes(parseInt($(this).data("step")), $(this).data("db"));
                IDM.routesHistory.push(filteredRoutes);
                IDM.routes = filteredRoutes;
                // マップを再描画
                IDM.deleteResults(false);
                IDM.makeConverterRoutes();
              }
            });

          // 矢印の生成
          html = "";
          var rowMiddle = (IDM.routes.length - 1) * .5;
          for (var r = 0; r < IDM.routes.length; r++) {
            var route = IDM.routes[r];
            // 行の走査
            for (var c = 0; c < (route.length - 1); c++) {
              var fromDB = route[c];
              var toDB = route[c + 1];
              // 上のリザルトと同じDBであれば、スキップする
              if (r > 0) {
                var prevRoute = IDM.routes[r - 1];
                if (prevRoute.length == route.length && fromDB == prevRoute[c] && toDB == prevRoute[c + 1]) {
                  continue;
                }
              }
              // 共通する後続ルートの探査
              var routeClass = "r" + r;
              for (var r2 = r + 1; r2 < IDM.routes.length; r2++) {
                var nextRoute = IDM.routes[r2];
                if (!(route.length == nextRoute.length && fromDB == nextRoute[c] && toDB == nextRoute[c + 1])) {
                  break;
                } else {
                  routeClass += " r" + r2;
                }
              }
              // 矢印の生成
              html += IDM.makeArrowHTML({
                routeClass : routeClass,
                colIndex   : c,
                colNode    : 0,
                colOffset  : 1,
                colUnit    : (100. - IDM.RESULT_AREA_MARGIN * 2.) / (route.length - 1.),
                colLength  : route.length,
                rowIndex   : r,
                rowOffset  : r2 - r,
                rowLength  : IDM.routes.length,
                topOffset  : resultTop,
                dotted     : false
              });
            }
          }
          IDM.$arrowsContainer.append(html);

          // ルート（非表示）の生成
          html = "";
          for (var r = 0; r < IDM.routes.length; r++) {
            html += "<div class='route' data-route='r" + r + "' style='top:" + resultTop + "px;'></div>";
          }
          IDM.$routesContainer.append(html);
          // ルートのインタラクション
          $(".route", IDM.$routesContainer)
            .hover( // ルートのハイライト
              function(){
                IDM.$hoveringRoute.empty();
                if (!IDM.$resultsContainer.hasClass(IDM.CLASSES.HIGHLIGHTING)) {
                  IDM.$resultsContainer.addClass(IDM.CLASSES.HIGHLIGHTING);
                }
                //$("." + $(this).data("route"), IDM.$resultsContainer).addClass(IDM.CLASSES.HIGHLIGHTING);
                $("." + $(this).data("route"), IDM.$resultsContainer).clone().appendTo(IDM.$hoveringRoute);
              },
              function(){
                if (IDM.$resultsContainer.hasClass(IDM.CLASSES.HIGHLIGHTING)) {
                  IDM.$resultsContainer.removeClass(IDM.CLASSES.HIGHLIGHTING);
                }
                //$("." + $(this).data("route"), IDM.$resultsContainer).removeClass(IDM.CLASSES.HIGHLIGHTING);
                IDM.$hoveringRoute.empty();
              })
            .click(function(){ // ルートの選択
              IDM.$resultsContainer.removeClass(IDM.CLASSES.HIGHLIGHTING);
              IDM.$hoveringRoute.empty();
              $("." + $(this).data("route"), IDM.$resultsContainer).addClass(IDM.CLASSES.SELECTED);
              var routeIndex = parseInt($(this).data("route").replace("r", ""));
              IDM.deleteResults(true);
              IDM.selectRoute(IDM.routes[routeIndex]);
            });

          // 結果の情報
          html = "<p class='result-message'>Found " + IDM.routes.length + " route" + (IDM.routes.length > 1 ? "s" : "") + ".</p>";
          IDM.$resultsContainer.append(html);

          // ルートがひとつだけの場合、ルートの確定
          if (IDM.routes.length == 1) {
            $(".r0", IDM.$resultsContainer).addClass(IDM.CLASSES.SELECTED);
            $(".node", IDM.$dbIconsContainer).off(".selecteingRoute");
            IDM.deleteResults(true);
            IDM.selectRoute(IDM.routes[0]);
          }

        }

        /* ルートの決定
         * @param Array route
         */
        IDM.selectRoute = function(route) {
          IDM.route = route;

          idConvert(IDM.route, IDM.sampleMode);

          // URLパラメータ
          window.location.hash = route.length > 0 ? route.join(":") : "";

          // テーブルの更新
          var html = "<tr>",
              width = " style='width:" + Math.floor(100 / route.length) + "%;'",
              HOP = 100;
          for (var i = 0; i < route.length; i++) {
            html +="<th" + width + "><div class='circle' style='border-color: " + IDM.hslFromCategory(IDM.DBs[route[i]].category) + "'></div>" + IDM.DBs[route[i]].label + "</th>";
          }
          html += "</tr>";
          IDM.$mappedIDsHead.html(html);

          // アニメーション
          IDM.$resultsContainer.addClass(IDM.CLASSES.DECIDING_ROUTE);
          var thIndex = 1,
              icons,
              sortedIcons = [],
              $ths = $("th", IDM.$mappedIDsHead),
              $icons,
              condition = IDM.mode == IDM.MODE_RESOLVER ? "[data-step='" + (route.length - 1) + "']" : "";
          $icons = $(".node." + IDM.CLASSES.SELECTED + condition, IDM.$resultsContainer).clone().appendTo(IDM.$hoveringRoute);
          $icons = $(".node." + IDM.CLASSES.SELECTED, IDM.$hoveringRoute);
          for (var i = 0; i < $icons.length; i++) {
            var step = parseInt($($icons[i]).data("step"));
            sortedIcons[step - 1] = $icons[i];
          }
          for (var i = 0; i < sortedIcons.length; i++) {
            var $icon = $(sortedIcons[i]),
                iconOffset = $icon.offset(),
                iconPosition = $icon.position(),
                $th = $($ths.get(thIndex++)),
                thOffset = $th.offset();
            if (IDM.mode == IDM.MODE_RESOLVER && i != (sortedIcons.length - 1)) continue;
            $("p", $icon).remove();
            $icon
              .css({ zIndex: 100 })
              .animate({
                left: thOffset.left - iconOffset.left + iconPosition.left + 6
              }, {
                duration: IDM.STEP_DURATION,
                step: function(now, tween){
                  if (tween.prop == "left") {
                    var $this = $(this),
                        ratio = (tween.now - tween.start) / (tween.end - tween.start),
                        radian = ratio * Math.PI,
                        thOffsetTop = $th.offset().top,
                        top = thOffsetTop - iconOffset.top + iconPosition.top + 7;
                    $this.css("top", (iconPosition.top * (1 - ratio) + top * ratio - HOP * Math.sin(radian)) + "px");
                  }
                },
                complete: function(){
                  IDM.$resultsContainer.removeClass(IDM.CLASSES.DECIDING_ROUTE);
                  IDM.$resultsContainer.addClass(IDM.CLASSES.DECIDED_ROUTE);
                  IDM.$hoveringRoute.empty();
                }
              });
          }
        }

        /* 小さなDBアイコン用HTMLの作成
         * @param  String param.category カテゴリ
         * @param  String param.db DB
         * @param  String param.routeClass ルート弁別用クラス
         * @param  Number param.colIndex 列の開始位置
         * @param  Number param.colUnit 列の幅の単位
         * @param  Number param.height 高さ
         * @param  Number param.rowIndex 行の開始位置
         * @param  Number param.topOffset 縦のオフセット値
         * @param  String param.label DB名
         * @param  Boolean param.isOnlyIcon 中央のアイコンのグラフィックのみか
         * @return String
         */
         IDM.makeSmallDBIconHTML = function(param) {
          //window.console.log(param);
          var hsl = "style='background-color:" + IDM.hslFromCategory(param.category) + "'";
          var html1 = param.isOnlyIcon
            ? ""
            : "<div class='node " + param.routeClass + "' style='height:" + param.height + "px; top:" + (IDM.ROUTE_HEIGHT * param.rowIndex + IDM.DB_ICON_TOP + param.topOffset - 2) + "px; left:" + (IDM.RESULT_AREA_MARGIN + param.colUnit * param.colIndex) + "%' data-db='" + param.db + "' data-step='" + param.colIndex + "'>";
          var html2 = "<div class='small-db-icon' style='top:" + (IDM.SMALL_DB_ICON_TOP + (param.height - IDM.DB_ICON_SIZE) * .5) + "px'><div " + hsl + " class='bottom side'></div><div " + hsl + " class='bottom lid'></div><div " + hsl + " class='middle side'></div><div " + hsl + " class='middle lid'></div><div " + hsl + " class='top side'></div><div " + hsl + " class='top lid'></div></div><p class='db-name'>" + param.label + "</p>";
          var html3 = param.isOnlyIcon
            ? ""
            : "</div>";
          return html1 + html2 + html3;
        }

        /* 矢印用HTMLの作成
         * @param  String param.routeClass ルート弁別用クラス
         * @param  Number param.colIndex 列の開始位置
         * @param  Number param.colNode 分岐点の位置
         * @param  Number param.colOffset 列の長さ
         * @param  Number param.colUnit 列の幅の単位
         * @param  Number param.colLength 列の全体長
         * @param  Number param.rowIndex 行の開始位置
         * @param  Number param.rowOffset 行の長さ
         * @param  Number param.rowLength 行の全体長
         * @param  Number param.topOffset 縦のオフセット値
         * @param  Number param.dotted リーダー罫か
         * @return String
         */
         IDM.makeArrowHTML = function(param) {
          var borderClass = "";
          var arrowStyle = "";
          if (param.dotted) {
            borderClass += "dotted ";
          }
          // 行（横）
          var left = param.colUnit * param.colIndex;
          var width = param.colUnit * param.colOffset;
          borderClass += (param.colIndex == param.colNode ? "left " : "") + ((param.colIndex + param.colOffset + 1) == param.colLength ? "right " : "");
          // 列（縦）
          var top = IDM.ROUTE_HEIGHT * param.rowIndex + param.topOffset;
          var height = IDM.ROUTE_HEIGHT * param.rowOffset;
          var rowMiddle = param.rowLength * .5;
          var arrowTop = param.rowIndex + param.rowOffset * .5;
          if (arrowTop < (rowMiddle - .5)) {
            borderClass += "top ";
            arrowStyle = " style='height:" + ((rowMiddle - arrowTop) * IDM.ROUTE_HEIGHT - IDM.LARGE_DB_ICON_HEIGHT * .5 - 2) + "px'";
          } else if (arrowTop > (rowMiddle + .5)) {
            borderClass += "bottom ";
            arrowStyle = " style='height:" + ((arrowTop - rowMiddle) * IDM.ROUTE_HEIGHT - IDM.LARGE_DB_ICON_HEIGHT * .5 - 2) + "px'";
          }
          // HTMLの生成
          var html = "<div class='arrow-container " + borderClass + param.routeClass + "' style='top:" + top + "px; height:" + height + "px; width:" + width + "%; left:" + left + "%;'><div class='inner'><div class='mapping-arrow right-arrowhead' " + arrowStyle + "></div></div></div>";
          return html;
         }

        /* ルート検索
         * @param  Array currentRoute
         * @param  String toDB
         * @param  Array(reference) availableRoutes
         */
        IDM.searchRoute = function(currentRoute, toDB, availableRoutes) {
          //var currentCategory = currentRoute[currentRoute.length - 1]; // カテゴリノードの場合
          var currentDB = currentRoute[currentRoute.length - 1];
          //if (currentCategory == IDM.DBs[toDB].category) { // カテゴリノードの場合
          //if (currentCategory == toDB) { // カテゴリノードの場合
          if (currentDB == toDB) { // 確立したルート
            availableRoutes.push(currentRoute);
          } else {
            //var links = IDM.CATEGORY[currentCategory].links; // カテゴリノードの場合
            var links = IDM.DBs[currentDB].links;
            for (var i = 0; i < links.length; i++) {
              //var nextCategory = links[i]; // カテゴリノードの場合
              var nextDB = links[i];
              // 同カテゴリであればパス
              if (currentRoute.length > 0 && IDM.DBs[currentDB].category == IDM.DBs[nextDB].category) {
                continue;
              }
              // すでに通過したDBでなければ、再帰的に検索
              var repeated = false;
              var sameCategory = false;
              for (var j = 0; j < currentRoute.length; j++) {
                //if (currentRoute[j] == nextCategory) repeated = true; // カテゴリノードの場合
                if (currentRoute[j] == nextDB) repeated = true;
              }
              if (!repeated) {
                if (currentRoute.length < IDM.step) {
                  //IDM.searchRoute(currentRoute.concat(nextCategory), toDB, availableRoutes);
                  IDM.searchRoute(currentRoute.concat(nextDB), toDB, availableRoutes); // カテゴリノードの場合
                }
              }
            }
          }
        }

        /* ルートをフィルタリング
         * @param  Number step
         * @param  String db
         * @return  Array
         */
        IDM.filterRoutes = function(step, db) {
          var filteredRoutes = [];
          for (var i = 0; i < IDM.routes.length; i++) {
            var route = IDM.routes[i];
            if ((route.length - 1) > step) {
              if (route[step] == db) {
                filteredRoutes.push(route);
              }
            }
          }
          return filteredRoutes;
        }

        /* カテゴリー名からHSLを返す
         * @param  String category: カテゴリー名
         * @return String
         */
        IDM.hslFromCategory = function(category) {
          return "hsl(" + IDM.CATEGORY[category].color.hue + "," + IDM.CATEGORY[category].color.saturation + "%," + IDM.CATEGORY[category].color.lightness + "%)";
        }

        /* ルート候補の削除
         * @param  Boolean isKeepSelecting: 選択された要素を保持するか
         */
        IDM.deleteResults = function(isKeepSelecting) {
          $(".result-message", IDM.$resultsContainer).remove();
          // 結果領域の高さ戻す
          IDM.$resultsContainer
            .css("height", "auto");
          // ルートの削除
          IDM.$routesContainer.empty();
          // DBアイコンの削除（選択されている物は保持）
          $(".node", IDM.$dbIconsContainer).each(function(){
            var $this = $(this);
            //window.console.log(this);
            if (isKeepSelecting && $this.hasClass(IDM.CLASSES.SELECTED)) {
              $this.css({
                height: IDM.DB_ICON_SIZE,
                top: 50
              });
              $(".small-db-icon", this).css("top", IDM.SMALL_DB_ICON_TOP);
            } else {
              $this.remove();
            }
          });
          // 矢印の削除（選択されている物は保持）
          $(".arrow-container", IDM.$arrowsContainer).each(function(){
            var $this = $(this);
            if (isKeepSelecting && $this.hasClass(IDM.CLASSES.SELECTED)) {
              $this
                .removeClass("top")
                .removeClass("bottom")
                .css({
                  height: IDM.RESULTS_DEFAULT_HEIGHT,
                  top: 0
                });
              $(".mapping-arrow", this)
                .css({
                  height: 0
                });
            } else {
              $this.remove();
            }
          });
        }

        { // GUI の生成
          var LOCATIVE = ["from", "to"];

          // json のデータを格納
          // var data = $.parseJSON(json);
          IDM.CATEGORY = data.category;
          IDM.DBs = data.DBs;

          // mode: converter or resolver
          IDM.mode = $mappingsContainer.data("mappingMode");
          IDM.step = 4;
          switch (true) {
            case (IDM.mode == IDM.MODE_CONVERTER):
              IDM.step = IDM.CONVERTER_DEFAULT_STEP;
              break;
            case (IDM.mode == IDM.MODE_RESOLVER):
              IDM.step = IDM.RESOLVER_DEFAULT_STEP;
              break;
          }

          // GUI の生成: DBセレクタ
          var html = "";
          for (var l = 0; l < LOCATIVE.length; l++) {
            if (IDM.mode == IDM.MODE_RESOLVER && l == 1) break;
            html += "\
            <div id='mapping-" + LOCATIVE[l] + "-db' class='db-selector'>\
            <div class='icon' data-locative='" + LOCATIVE[l] + "'>\
            <div class='bottom side'></div>\
            <div class='bottom lid'></div>\
            <div class='middle side'></div>\
            <div class='middle lid'></div>\
            <div class='top side'></div>\
            <div class='top lid'></div>\
            </div>\
            <div class='db-name-container'><p class='db-name'>" + IDM.LOCATIVE_CAPITALIZED[LOCATIVE[l]] + "</p></div>\
            </div>\
            <div class='db-list-container'><div class='bg'></div><div class='arrow'></div><div class='inner'></div></div>\
            ";
          };
          // GUI の生成: 枠
          html += "\
          <div id='mapping-results-container'>\
          <div class='arrow-container undefined'>\
          <div class='inner'>\
          <div class='mapping-arrow undefined right-arrowhead'></div>\
          </div>\
          </div>\
          <div id='mapping-hovering-route'></div>\
          <div id='mapping-arrows-container'></div>\
          <div id='mapping-dbicons-container'></div>\
          <div id='mapping-routes-container'></div>\
          <div id='mapping-reset-button' class='tg-button clear'>Reset</div>\
          </div>";
          $("#mappings-selector-container").append(html);

          // GUI の参照
          IDM.dbLargeIcon = {
            from: $("#mapping-from-db .icon"),
            to: $("#mapping-to-db .icon")
          };
          IDM.dbLargeIconLabel = {
            from: $("#mapping-from-db > .db-name-container > p.db-name"),
            to: $("#mapping-to-db > .db-name-container > p.db-name")
          };
          IDM.$dbList = {
            from: $("#mapping-from-db + .db-list-container"),
            to: $("#mapping-to-db + .db-list-container")
          };
          IDM.dbList = {};
          IDM.$resultsContainer = $("#mapping-results-container");
          IDM.$resultsContainerSublayer = $("#mapping-results-container > div");
          IDM.$hoveringRoute = $("#mapping-hovering-route");
          IDM.$arrowsContainer = $("#mapping-arrows-container");
          IDM.$dbIconsContainer = $("#mapping-dbicons-container");
          IDM.$routesContainer = $("#mapping-routes-container");
          IDM.$resetButton = $("#mapping-reset-button");
          IDM.$mappedIDsHead = $("#mapped-ids thead");
          IDM.$mappedIDsBody = $("#mapped-ids tbody");

          // DBセレクタの中身を生成
          for (var l = 0; l < LOCATIVE.length; l++) {
            html = "<dl>",
                category = "";
            for (var i in IDM.DBs) {
              if (category != IDM.DBs[i].category) {
                category = IDM.DBs[i].category;
                html += "<dt>" + IDM.CATEGORY[category].label + "</dt>";
              }
              html += "<dd style='color:" + IDM.hslFromCategory(category) + "'><p data-locative='" + LOCATIVE[l] + "' data-dbid='" + i + "'>" + IDM.DBs[i].label + "</p></dd>";
            }
            html += "</dl>";
            $(".inner", IDM.$dbList[LOCATIVE[l]]).append(html);
            IDM.dbList[LOCATIVE[l]] = new IDM.DBList(IDM.$dbList[LOCATIVE[l]]);
          }


          // 生成した GUI にイベントのはりつけ

          // DBアイコンをクリックすると、DBリストが開く
          $(".db-selector > .db-name-container > .db-name").click(function(e) {
            e.stopPropagation();
            var $icon = $(this).parent().siblings(".icon");
            IDM.dbList[$icon.data("locative")].openEndDBList();
          });

          // DBリストの項目をクリックすると、そのDBが選ばれる
          $(".db-list-container p").click(function() {
            if ($(this).hasClass("disable")) return;
            var locative = $(this).data("locative");
            var lastItem = IDM.selectedDbListItem[locative];
            if (!lastItem || lastItem != this) {
              if (IDM.selectedDbListItem[locative]) IDM.selectedDbListItem[locative].className = "";
              IDM.selectedDbListItem[locative] = this;
              this.className = "selected";
              IDM.selectDB(locative, $(this).data("dbid"));
            }
          });

          // 横幅
          $w.on("resize.adjustWidth", function(){
            // 矢印の再描画
            IDM.results.width = IDM.$resultsContainer.get(0).clientWidth;
            IDM.$resultsContainerSublayer.css("width", IDM.results.width);
          });

          // Reset ボタンを押下すると初期化
          IDM.$resetButton.click(function(){
            IDM.reset();
          });
        }

        { // ハッシュからルートを生成
          var hash = window.location.hash;
          if (hash.length > 0) {
            hash = hash.substring(1);
            var route = hash.split(":");
            // 値のチェック
            var valid = true;
            for (var i = 0; i < route.length; i++) {
              if (!IDM.DBs[route[i]]) invalid = false;
            }
            if (valid) {
            switch (true) {
              case (IDM.mode == IDM.MODE_CONVERTER):
                IDM.selectDB("from", route[0], route);
                IDM.selectDB("to", route[route.length - 1], route);
              break;
              case (IDM.mode == IDM.MODE_RESOLVER):
              {
                IDM.selectDB("from", route[0], route);
              }
              break;
            }
            }
          }
        }
      }); // DB情報の読み込みをトリガーとする処理、ここまで

      $('textarea#identifiers').on('change', function(){
        if ($(this).val() == '') {
          IDM.sampleMode = true;
        } else {
          IDM.sampleMode = false;
          $(this).removeClass('sample');
          $('#add-new-id p#add-new-id-description').text(' + Add new ID');
        }
      });

      $('#execute').on('click', function(){
        idConvert(IDM.route, IDM.sampleMode);
      });

      function idConvert(route, sampleMode) {
        $('#loading').html("<div class='dataTables_processing'>Processing...</div>");
        $.get("/identifiers/convert",
          { identifiers: $('textarea#identifiers').val(), databases: route, sample_mode: sampleMode }
        );
      }
    }
  }
});
