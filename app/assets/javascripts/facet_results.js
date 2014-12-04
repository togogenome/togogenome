// 現在開いているタブ
var drawTable = "all";

$(function() {
  // DataTable のデフォルト値を設定
  $.extend( $.fn.dataTable.defaults, {
    "processing": true,
    "serverSide": true,
    "ordering" : false,
    "searching" : true,
    "pageLength": 25,
    "ajax" : {
      "url" : "/proteins/search.json",
      "data": function(d) {
        d.taxonomy =           $('#_taxonomy_id').val();
        d.environment =        $('#_environment_id').val();
        d.biological_process = $('#_biological_process_id').val();
        d.molecular_function = $('#_molecular_function_id').val();
        d.cellular_component = $('#_cellular_component_id').val();
        d.phenotype =          $('#_phenotype_id').val();
        d.draw_table =         drawTable;
      },
      "error": function() {
        alert('failing query...');
        return;
      }
    },
    "dom": "<'span5'i><'span5'l>r<p><<'.csv-export.span2'>>t<<'span5'i><'span5'><p>>",
    "pagingType": "custom-bootstrap",
    "drawCallback": function (setting) {
      var api = this.api()
      var pane = this.parent();

      // Donwload CSV のリンク生成
      var params = {};
      setting.ajax.data(params);
      url = "/proteins/search.csv?" + $.param(params);
      pane.find('.csv-export > a').attr("href", url);

      // テーブル毎に paginationSlider を持つ
      var paginationSlider = setting.oInit.paginationSlider;

      // スライダーの生成
      if (!paginationSlider) {
        var $ul = pane.find(".dataTables_paginate ul");
        $ul.before(
          "<div class='pagination-slider'>" +
          "<div class='pagination-slider-bar'></div>" +
          "<div class='pagination-slider-current-bar'></div>" +
          "<div class='pagination-slider-indicator'><div class='inner'>0</div></div>" +
          "<div class='pagination-slider-dotted-line-left'></div>" +
          "<div class='pagination-slider-dotted-line-right'></div>" +
          "</div>"
        );
        paginationSlider = {
          ul: $ul,
          container: pane.find(".pagination-slider"),
          bar: pane.find(".pagination-slider-bar"),
          currentBar: pane.find(".pagination-slider-current-bar"),
          indicator: pane.find(".pagination-slider-indicator"),
          indicatorInner: pane.find(".pagination-slider-indicator > .inner"),
          dottedLineLeft: pane.find(".pagination-slider-dotted-line-left"),
          dottedLineRight: pane.find(".pagination-slider-dotted-line-right"),
          pagination: pane.find(".pagination")
        }
        // スライダーイベント
        paginationSlider.indicator.mousedown(function(e){
          var startX = e.clientX,
              originX = paginationSlider.indicator.position().left,
              maxWidth = paginationSlider.bar.outerWidth(),
              unit = maxWidth / paginationSlider.totalPage,
              page;
          $(window)
            .on("mousemove.paginationSlider", function(e){
              // インジケータをマウスに追随して移動
              var x = originX + e.clientX - startX;
              x = x < 0 ? 0 : x;
              x = x > maxWidth ? maxWidth : x;
              paginationSlider.indicator.css("left", x + "px");
              // インジケータの数字
              x = x < unit * .5 ? unit * .5 : x;
              x = x > maxWidth - unit * .5 ? maxWidth - unit * .5 : x;
              page = Math.floor(x / unit);
              paginationSlider.currentPage = page;
              paginationSlider.indicatorInner.text(page + 1);
              paginationSlider.setPaginationRange();
              paginationSlider.render();
            })
            .on("mouseup.paginationSlider", function(e){
              // イベント削除
              $(window).off("mousemove.paginationSlider mouseup.paginationSlider");
              api.page(page).draw( false )
            });
        });
        // ページネーションの範囲定義
        paginationSlider.setPaginationRange = function(currentPage) {
          // ページネーションの開始ページ
          paginationSlider.startPage = paginationSlider.currentPage - PAGENATION_MARGIN;
          paginationSlider.startPage = paginationSlider.startPage < 0 ? 0 : paginationSlider.startPage;
          if ((paginationSlider.startPage + paginationSlider.displayPagination) > paginationSlider.  totalPage) {
            paginationSlider.startPage = paginationSlider.totalPage - paginationSlider.  displayPagination;
          }
        }
        // スライダーの表示
        paginationSlider.render = function() {
          var bl, br, bb, pl, pr, pt, bw, cw;
          bw = paginationSlider.bar.width();
          // インジケータの位置
          paginationSlider.indicatorInner
            .text(paginationSlider.currentPage + 1);
          paginationSlider.indicator
            .css("left", Math.round(bw * (paginationSlider.currentPage + .5) / (paginationSlider.  totalPage)) + "px");
          // バーの位置と大きさ
          cw = Math.ceil(bw * (paginationSlider.displayPagination / paginationSlider.totalPage));
          bl = Math.floor(bw * (paginationSlider.startPage / paginationSlider.totalPage));
          paginationSlider.currentBar
            .width(cw)
            .css("left", bl + "px");
          // 破線
          var $pThird = paginationSlider.ul.children("li:nth-child(3)"),
              $pLastThird = paginationSlider.ul.children("li:nth-last-child(3)");
          br = bl + cw;
          bb = paginationSlider.bar.position().top + paginationSlider.bar.outerHeight();
          pl = paginationSlider.ul.position().left + $pThird.position().left;
          pr = paginationSlider.ul.position().left + $pLastThird.position().left + $pLastThird.  outerWidth();
          pt = paginationSlider.ul.position().top - paginationSlider.container.position().top + $pThird  .outerHeight() * .5;
          var lLength = Math.sqrt(Math.pow(pl - bl, 2) + Math.pow(pt - bb, 2));
          var rad = Math.atan2(pt - bb, pl - bl);
          var deg = (180 * rad) / Math.PI;
          paginationSlider.dottedLineLeft
            .width(lLength).height(1)
            .css({
              top: ((pt + bb) * .5) + "px",
              left: ((pl + bl) * .5 - lLength * .5) + "px",
              transform: "rotate(" + (deg + 0) + "deg)"}
            );
          var rLength = Math.sqrt(Math.pow(pr - br, 2) + Math.pow(pt - bb, 2));
          rad = Math.atan2(pt - bb, pr - br);
          deg = (180 * rad) / Math.PI;
          paginationSlider.dottedLineRight
            .width(rLength).height(1)
            .css({
              top: ((pt + bb) * .5) + "px",
              left: ((pr + br) * .5 - rLength * .5) + "px",
              transform: "rotate(" + (deg + 0) + "deg)"}
            );
        }
        $(window).resize(function(){
          paginationSlider.render();
        })
      }
      // 諸元の保持
      var PAGENATION_MAX = 5, PAGENATION_MARGIN = 2;
      // 一度に表示されるレコード数
      var iLength = this.fnPagingInfo().iLength;
      // 総レコード数
      paginationSlider.totalDisplayRecords = this.fnPagingInfo().iFilteredTotal;
      // 総ページ数
      paginationSlider.totalPage = this.fnPagingInfo().iTotalPages;
      // ページネーションの数
      paginationSlider.displayPagination = paginationSlider.totalPage;
      paginationSlider.displayPagination = paginationSlider.displayPagination > PAGENATION_MAX ?   PAGENATION_MAX : paginationSlider.displayPagination;
      // 現在のページ
      var currentPage = Math.floor( this.fnPagingInfo().iStart / iLength );
      paginationSlider.currentPage = currentPage;
      paginationSlider.setPaginationRange();
      // ページネーションのレンダリング
      if (paginationSlider.totalDisplayRecords <= iLength) {
        paginationSlider.pagination.hide();
      } else {
        paginationSlider.pagination.show();
        paginationSlider.render();
      }

      // 設定した PaginationSlider を、テーブルの paginationSlider に設定する
      setting.oInit.paginationSlider = paginationSlider;
    }
  });

  // 表示するデータを指定し初期化
  var allResultsTable = $("#results").DataTable({
    "columns": [
      { "data": "name", "width" : "220px" },
      { "data": "gene_links" },
      { "data": "entry_identifier", "width" : "100px" },
      { "data": "go_links" },
      { "data": "organism_link" },
      { "data": "environment_links" },
      { "data": "phenotype_links" }
    ],
    "paginationSlider" : null
  });

  // 表示するデータを指定し初期化
  var geneResultsTable = $("#gene_results").DataTable({
    "columns": [
      { "data": "gene_links" },
      { "data": "name", "width" : "220px" },
      { "data": "entry_identifier", "width" : "100px" },
      { "data": "go_links" },
      { "data": "organism_link" }
    ],
    "paginationSlider" : null
  });

  $(".csv-export")
    .addClass("result-download-container")
    .append('<a>Download CSV</a>');

  $(".csv-export > a").on('click', function() {
    location.href = $(".csv-export > a").attr("href");
    return false;
  });

  window.query = function() {
    if (drawTable === 'all') {
      return allResultsTable.draw();
    } else if (drawTable === 'gene') {
      return geneResultsTable.draw();
    }
  };

  $("#result_tabs").on('click', function(e) {
    drawTable = $(e.target).data('drawTable');
    // タブ変更時に再度検索をする
    // 上側 Facets 部分の変更した結果で検索するため
    // ここを消すと前の状態を保持できるが、上側は変更されているため、選択している 各絞り込み条件と下の結果が異なるものが描画される
    window.query();
  });
});
