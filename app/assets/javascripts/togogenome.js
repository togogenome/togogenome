$(function(){

  // ナビゲーションのインジケータとスクロール位置の連動
  {
    var $ulNav = $("#navbar ul.nav");
    if ($ulNav.length >= 1) {
      var LIST_ADDITION_WIDTH = 4,
          ulWidth = 0,
          $w = $(window);
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
    methodSelector.HIDE = "hide";
    methodSelector.SHOW = "show";
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
  {
    var $mappingsContainer = $("#mappings-container");
    if ($mappingsContainer) {
      var IDM = {};
      IDM.MAX_STEP = 10;
      IDM.RESULTS_DEFAULT_HEIGHT = 120;
      IDM.ROUTE_HEIGHT = 42;
      IDM.DB_ICON_SIZE = 32;
      IDM.RESULT_AREA_MARGIN = 0;
      IDM.MAX_STEP = 4;
      IDM.SMALL_DB_ICON_TOP = 5;
      IDM.SMALL_DB_ICON_HEIGHT = 26;
      IDM.LARGE_DB_ICON_HEIGHT = 52;
      IDM.EXCLUDE_SAME_CATEGORY = true;
      IDM.DB_ICON_TOP = (IDM.ROUTE_HEIGHT - IDM.DB_ICON_SIZE) * .5;
      IDM.SELECTED_CLASS_NAME = "selected-route";
      IDM.dbLargeIcon = {
        from: $("#mapping-from-db .icon"),
        to: $("#mapping-to-db .icon")
      };
      IDM.dbLargeIconLabel = {
        from: $("#mapping-from-db .icon p.db-name"),
        to: $("#mapping-to-db .icon p.db-name")
      };
      IDM.dbList = {
        from: $("#mapping-from-db .db-list-container"),
        to: $("#mapping-to-db .db-list-container")
      };
      IDM.$resultsContainer = $("#mapping-results-container");
      IDM.$arrowsContainer = $("#mapping-arrows-container");
      IDM.$dbIconsContainer = $("#mapping-dbicons-container");
      IDM.$routesContainer = $("#mapping-routes-container");
      IDM.$mappedIDsHead = $("#mapped-ids thead");
      IDM.$mappedIDsBody = $("#mapped-ids tbody");
      IDM.selectedDb = { from: "", to: "" }
      IDM.selectedDbListItem = { from: undefined, to: undefined }
      IDM.arrowLayers = [];
      IDM.routes = [];
      IDM.route = [];

      // DB情報の読み込み
      $.getJSON("/dbmapping.json", function(data){ // 本来は getJSON
        //console.log('data');
        //console.log(data);
        IDM.CATEGORY = data.category;
        IDM.DBs = data.DBs;
        // セレクタに展開
        var LOCATIVE = ["from", "to"];
        for (var h = 0; h < LOCATIVE.length; h++) {
          var html = "<dl>",
              category = "";
          for (var i in IDM.DBs) {
            if (category != IDM.DBs[i].category) {
              category = IDM.DBs[i].category;
              html += "<dt>" + IDM.CATEGORY[category].label + "</dt>";
            }
            html += "<dd style='color:hsl(" + IDM.CATEGORY[category].color.hue + "," + IDM.CATEGORY[category].color.saturation + "%," + IDM.CATEGORY[category].color.lightness + "%)'><p data-locative='" + LOCATIVE[h] + "' data-dbid='" + i + "'>" + IDM.DBs[i].label + "</p></dd>";
          }
          html += "</dl>";
          $("#mapping-" + LOCATIVE[h] + "-db .inner").append(html);
        }

        // DBの選択
        IDM.selectDB = function(locative, id) {
          var category = IDM.DBs[id].category;
          var $icon = IDM.dbLargeIcon[locative];
          var hsl = "hsl(" + IDM.CATEGORY[category].color.hue + "," + IDM.CATEGORY[category].color.saturation + "%," + IDM.CATEGORY[category].color.lightness + "%)";
          $(".side, .lid", $icon).css("background-color", hsl);
          IDM.dbList[locative].removeClass("open");
          IDM.dbLargeIconLabel[locative].text(IDM.DBs[id].label);
          IDM.dbLargeIconLabel[locative].addClass("selected");
          IDM.selectedDb[locative] = id;
          // もしどちらのDBも選択されていれば、ルート検索を開始
          if (IDM.selectedDb["from"] != "" && IDM.selectedDb["to"] != "") {
            var availableRoutes = [];
            var currentRoute = [IDM.selectedDb.from];
            var node = IDM.DBs[IDM.selectedDb.from];
            var links = node.links;
            IDM.searchRoute(currentRoute, IDM.selectedDb.to, availableRoutes);
            // 結果のソート
            IDM.routes = (function(){
              var routes = [];
              for (var i = 2; i <= IDM.MAX_STEP; i++) {
                for (var j = 0; j <= availableRoutes.length; j++) {
                  if (availableRoutes[j] && availableRoutes[j].length == i) {
                    routes.push(availableRoutes[j]);
                    delete availableRoutes[j];
                  }
                }
              }
              if (IDM.EXCLUDE_SAME_CATEGORY) {
                // 同カテゴリのDBが続く場合排除
                var excludedRoutes = [];
                for (var i = 0; i < routes.length; i++) {
                  var route = routes[i];
                  if (route.length == 2) {
                    // 中間のDBがない場合は有効
                    excludedRoutes.push(route);
                  } else {
                    var differ = true;
                    for (var j = 0; j < (route.length - 1); j++) {
                      if (IDM.DBs[route[j]].category == IDM.DBs[route[j + 1]].category) differ = false;
                    }
                    if (differ) excludedRoutes.push(route);
                  }
                }
                return excludedRoutes;
              } else {
                return rotes;
              }
            })();

            // 前回の表示分の消去
            IDM.deleteResults(false);
            // 結果の表示
            if (IDM.routes.length == 0) {
              IDM.$resultsContainer.removeClass("showing-result");
              return;
            }
            var resultsHeight = IDM.ROUTE_HEIGHT * IDM.routes.length;
            var resultTop = (resultsHeight > IDM.RESULTS_DEFAULT_HEIGHT) ? 0 : (IDM.RESULTS_DEFAULT_HEIGHT - resultsHeight) * .5;
            IDM.$resultsContainer
              .addClass("showing-result")
              .css("height", resultsHeight);
            var html = "";
            // DBアイコンの生成
            for (var r = 0; r < IDM.routes.length; r++) {
              var route = IDM.routes[r];
              //if (IDM.routes.length > 0) {
              // 行の走査
              var colUnit = (100. - IDM.RESULT_AREA_MARGIN * 2.) / (route.length - 1.);
              for (var c = 1; c < (route.length - 1); c++) {
                var db = route[c];
                var category = IDM.DBs[db].category;
                var routeClass = "r" + r;
                // 上のリザルトと同じDBであれば、スキップする
                if (r > 0) {
                  var prevRoute = IDM.routes[r - 1];
                  if (prevRoute.length == route.length && prevRoute[c] == db) continue;
                }
                // 後続のリザルトが同じDBか調べる
                var height = IDM.DB_ICON_SIZE;
                if (r < (IDM.routes.length - 1)) {
                  for (r2 = r + 1; r2 < IDM.routes.length; r2++) {
                    var nextRoute = IDM.routes[r2];
                    if (route.length != nextRoute.length || db != nextRoute[c]) break;
                    height += IDM.ROUTE_HEIGHT;
                    routeClass += " r" + r2;
                  }
                }
                // HTMLの生成
                var hsl = "style='background-color:hsl(" + IDM.CATEGORY[category].color.hue + "," + IDM.CATEGORY[category].color.saturation + "%," + IDM.CATEGORY[category].color.lightness + "%)'";
                html += "<div class='node " + routeClass + "' style='height:" + height + "px; top:" + (IDM.ROUTE_HEIGHT * r + IDM.DB_ICON_TOP + resultTop) + "px; left:" + (IDM.RESULT_AREA_MARGIN + colUnit * c) + "%'><div class='small-db-icon' style='top:" + (IDM.SMALL_DB_ICON_TOP + (height - IDM.DB_ICON_SIZE) * .5) + "px'><div " + hsl + " class='bottom side'></div><div " + hsl + " class='bottom lid'></div><div " + hsl + " class='middle side'></div><div " + hsl + " class='middle lid'></div><div " + hsl + " class='top side'></div><div " + hsl + " class='top lid'></div></div><p class='db-name'>" + IDM.DBs[db].label + "</p></div>";
              }
              //}
            }
            IDM.$dbIconsContainer.append(html);
            // 矢印の生成
            var arrowSpaces = [];
            html = "";
            var rowMiddle = (IDM.routes.length - 1) * .5;
            for (var r = 0; r < IDM.routes.length; r++) {
              var route = IDM.routes[r];
              var width = (100. - IDM.RESULT_AREA_MARGIN * 2.) / (route.length - 1.);
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
                var top = IDM.ROUTE_HEIGHT * r + resultTop;
                var height = IDM.ROUTE_HEIGHT;
                //if (r < (IDM.routes.length - 1)) {
                for (var r2 = r + 1; r2 < IDM.routes.length; r2++) {
                  var nextRoute = IDM.routes[r2];
                  if (!(route.length == nextRoute.length && fromDB == nextRoute[c] && toDB == nextRoute[c + 1])) {
                    break;
                  } else {
                    height += IDM.ROUTE_HEIGHT;
                    routeClass += " r" + r2;
                  }
                }
                //}
                // 矢印コンテナの生成
                var borderClass = "";
                var isLeft = c == 0;
                var isRight = c == (route.length - 2);
                var isTop = isBottom = false;
                var arrowStyle = "";
                var r3 = r + (r2 - r - 1) * .5;
                //window.console.log("r: "+r+"/"+IDM.routes.length+",  r2: "+r2+",  r3: "+r3+",  c: "+c+"/"+route.length+",  rowMiddle: "+rowMiddle);
                if (isLeft) borderClass += "left ";
                if (isRight) borderClass += "right ";
                if (isLeft || isRight) {
                  if (r3 < (rowMiddle - .5)) {
                    borderClass += "top ";
                    isTop = true;
                    arrowStyle = " style='height:" + ((rowMiddle - r3) * IDM.ROUTE_HEIGHT - IDM.LARGE_DB_ICON_HEIGHT * .5 - 2) + "px'";
                  } else if (r3 > (rowMiddle + .5)) {
                    borderClass += "bottom ";
                    isBottom = true;
                    arrowStyle = " style='height:" + ((r3 - rowMiddle) * IDM.ROUTE_HEIGHT - IDM.LARGE_DB_ICON_HEIGHT * .5 - 2) + "px'";
                  }
                }
                html += "<div class='arrow-container " + borderClass + routeClass + "' style='top:" + top + "px; height:" + height + "px; width:" + width + "%; left:" + (IDM.RESULT_AREA_MARGIN + width * c) + "%;'><div class='inner'><div class='mapping-arrow right-arrowhead' " + arrowStyle + "></div></div></div>";
              }
            }
            IDM.$arrowsContainer.append(html);
            // ルート（非表示）の生成
            html = "";
            for (var r = 0; r < IDM.routes.length; r++) {
              html += "<div class='route' data-route='r" + r + "' style='top:" + resultTop + "px;'></div>";
            }
            IDM.$routesContainer.append(html);
            $(".route", IDM.$routesContainer)
              .hover( // ルートのハイライト
                function(){
                  IDM.$resultsContainer.addClass("highlighting");
                  $("." + $(this).data("route"), IDM.$resultsContainer).addClass("highlighting");
                },
                function(){
                  IDM.$resultsContainer.removeClass("highlighting");
                  $("." + $(this).data("route"), IDM.$resultsContainer).removeClass("highlighting");
                })
              .click(function(){ // ルートの選択
                $("." + $(this).data("route"), IDM.$resultsContainer).addClass(IDM.SELECTED_CLASS_NAME);
                var routeIndex = parseInt($(this).data("route").replace("r", ""));
                IDM.selectRoute(IDM.routes[routeIndex]);
              });
          }
        }

        // ルート検索
        IDM.searchRoute = function(currentRoute, toDB, availableRoutes) {
          var currentDB = currentRoute[currentRoute.length - 1];
          if (currentDB == toDB) {
            availableRoutes.push(currentRoute);
          } else {
            var links = IDM.DBs[currentDB].links;
            for (var i = 0; i < links.length; i++) {
              var nextDB = links[i];
              // すでに通過したDBでなければ、再帰的に検索
              var repeated = false;
              for (var j = 0; j < currentRoute.length; j++) {
                if (currentRoute[j] == nextDB) repeated = true;
              }
              if (!repeated) {
                if (currentRoute.length < IDM.MAX_STEP) {
                  IDM.searchRoute(currentRoute.concat(nextDB), toDB, availableRoutes);
                }
              }
            }
          }
        }

        // ルートの決定
        IDM.selectRoute = function(route) {
          // 選択されたルート意外の結果を削除
          IDM.deleteResults(true);
          // テーブルの更新
          var html = "<tr>";
          var width = " style='width:" + Math.floor(100 / route.length) + "%;'";
          for (var i = 0; i < route.length; i++) {
            html +="<th" + width + ">" + IDM.DBs[route[i]].label + "</th>"
          }
          html += "</tr>";
          IDM.$mappedIDsHead.html(html);
          IDM.route = route;
        }

        // ルート候補の削除
        IDM.deleteResults = function(isKeepSelecting) {
          // 結果領域の高さ戻す
          IDM.$resultsContainer
            .css("height", "auto");
          // ルートの削除
          IDM.$routesContainer.empty();
          //window.console.log(IDM.$resultsContainer.innerHeight());
          // DBアイコンの削除（選択されている物は保持）
          $(".node", IDM.$dbIconsContainer).each(function(){
            var $this = $(this);
            if (isKeepSelecting && $this.hasClass(IDM.SELECTED_CLASS_NAME)) {
              window.console.log(this);
              $this.css({
                height: IDM.DB_ICON_SIZE,
                top: 44
              });
              $(".small-db-icon", this).css("top", IDM.SMALL_DB_ICON_TOP);
            } else {
              $this.remove();
            }
          });
          // 矢印の削除（選択されている物は保持）
          $(".arrow-container", IDM.$arrowsContainer).each(function(){
            var $this = $(this);
            if (isKeepSelecting && $this.hasClass(IDM.SELECTED_CLASS_NAME)) {
              window.console.log(this);
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

        // DBアイコンをクリックすると、DBリストが開く
        $(".db-selector .icon").click(function() {
          IDM.dbList[$(this).data("locative")].toggleClass("open");
        });

        // DBリストの項目をクリックすると、そのDBが選ばれる
        $(".db-list-container p").click(function() {
          // body...
          var locative = $(this).data("locative");
          var lastItem = IDM.selectedDbListItem[locative];
          if (!lastItem || lastItem != this) {
            if (IDM.selectedDbListItem[locative]) IDM.selectedDbListItem[locative].className = "";
            IDM.selectedDbListItem[locative] = this;
            this.className = "selected";
            IDM.selectDB(locative, $(this).data("dbid"));
          }

        });
      });
      //window.console.log(IDM);

      {
        $('#execute').on('click', function(){
          $.get("/converter/convert", { identifiers: $('#identifiers').val(), databases: IDM.route } );
        });
      }
    }
  }
})
;
