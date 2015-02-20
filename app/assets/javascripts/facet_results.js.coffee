# 現在開いているタブ
window.drawInfo = {}

$ ->
  currentKey = "gene"

  # DataTable のデフォルト値を設定
  $.extend $.fn.dataTable.defaults,
    processing: true
    serverSide: true
    ordering: false
    searching: true
    pageLength: 25
    dom: "<'span10'<'span5'i><'span5'l>p><'.result-download-container.span2'>rtip"
    pagingType: "custom-bootstrap"
    ajax:
      data: (d) ->
        d.taxonomy = $("#_taxonomy_id").val()
        d.environment = $("#_environment_id").val()
        d.biological_process = $("#_biological_process_id").val()
        d.molecular_function = $("#_molecular_function_id").val()
        d.cellular_component = $("#_cellular_component_id").val()
        d.phenotype = $("#_phenotype_id").val()
        return
      error: ->
        alert "failing query..."
        return
    paginationSlider: null
    drawCallback: (setting) ->
      api = @api()
      pane = @parent()

      # Donwload CSV のリンク生成
      params = {}
      setting.ajax.data params
      url = drawInfo[currentKey].downloadCSV + "?" + $.param(params)
      pane.find(".result-download-container > a").attr "href", url

      # テーブル毎に paginationSlider を持つ
      tmpPaginationSlider = setting.oInit.paginationSlider

      # スライダーの生成
      unless tmpPaginationSlider
        html = """
               <div class='pagination-slider'>
                 <div class='pagination-slider-bar'></div>
                 <div class='pagination-slider-current-bar'></div>
                 <div class='pagination-slider-indicator'>
                   <div class='inner'>0</div>
                 </div>
                 <div class='pagination-slider-dotted-line-left'></div>
                 <div class='pagination-slider-dotted-line-right'></div>
               </div>
               """

        $ul = pane.find(".dataTables_paginate ul")
        $ul.before html
        tmpPaginationSlider =
          ul: $ul
          container: pane.find(".pagination-slider")
          bar: pane.find(".pagination-slider-bar")
          currentBar: pane.find(".pagination-slider-current-bar")
          indicator: pane.find(".pagination-slider-indicator")
          indicatorInner: pane.find(".pagination-slider-indicator > .inner")
          dottedLineLeft: pane.find(".pagination-slider-dotted-line-left")
          dottedLineRight: pane.find(".pagination-slider-dotted-line-right")
          pagination: pane.find(".pagination")

        # スライダーイベント
        tmpPaginationSlider.indicator.mousedown (e) ->
          startX = e.clientX
          originX = tmpPaginationSlider.indicator.position().left
          maxWidth = tmpPaginationSlider.bar.outerWidth()
          unit = maxWidth / tmpPaginationSlider.totalPage
          page = undefined

          # インジケータをマウスに追随して移動

          # インジケータの数字
          $(window).on("mousemove.paginationSlider", (e) ->
            x = originX + e.clientX - startX
            x = (if x < 0 then 0 else x)
            x = (if x > maxWidth then maxWidth else x)
            tmpPaginationSlider.indicator.css "left", x + "px"
            x = (if x < unit * .5 then unit * .5 else x)
            x = (if x > maxWidth - unit * .5 then maxWidth - unit * .5 else x)
            page = Math.floor(x / unit)
            tmpPaginationSlider.currentPage = page
            tmpPaginationSlider.indicatorInner.text page + 1
            tmpPaginationSlider.setPaginationRange()
            tmpPaginationSlider.render()
            return
          ).on "mouseup.paginationSlider", (e) ->
            # イベント削除
            $(window).off "mousemove.paginationSlider mouseup.paginationSlider"
            api.page(page).draw false
            return

          return

        # ページネーションの範囲定義
        tmpPaginationSlider.setPaginationRange = (currentPage) ->
          # ページネーションの開始ページ
          tmpPaginationSlider.startPage = tmpPaginationSlider.currentPage - PAGENATION_MARGIN
          tmpPaginationSlider.startPage = (if tmpPaginationSlider.startPage < 0 then 0 else tmpPaginationSlider.startPage)
          tmpPaginationSlider.startPage = tmpPaginationSlider.totalPage - tmpPaginationSlider.displayPagination  if (tmpPaginationSlider.startPage + tmpPaginationSlider.displayPagination) > tmpPaginationSlider.totalPage
          return

        # スライダーの表示
        tmpPaginationSlider.render = ->
          bw = tmpPaginationSlider.bar.width()

          # インジケータの位置
          tmpPaginationSlider.indicatorInner.text tmpPaginationSlider.currentPage + 1
          tmpPaginationSlider.indicator.css "left", Math.round(bw * (tmpPaginationSlider.currentPage + .5) / (tmpPaginationSlider.totalPage)) + "px"

          # バーの位置と大きさ
          cw = Math.ceil(bw * (tmpPaginationSlider.displayPagination / tmpPaginationSlider.totalPage))
          bl = Math.floor(bw * (tmpPaginationSlider.startPage / tmpPaginationSlider.totalPage))
          tmpPaginationSlider.currentBar.width(cw).css "left", bl + "px"

          # 破線
          $pThird = tmpPaginationSlider.ul.children("li:nth-child(3)")
          $pLastThird = tmpPaginationSlider.ul.children("li:nth-last-child(3)")
          br = bl + cw
          bb = tmpPaginationSlider.bar.position().top + tmpPaginationSlider.bar.outerHeight()
          pl = tmpPaginationSlider.ul.position().left + $pThird.position().left
          pr = tmpPaginationSlider.ul.position().left + $pLastThird.position().left + $pLastThird.outerWidth()
          pt = tmpPaginationSlider.ul.position().top - tmpPaginationSlider.container.position().top + $pThird.outerHeight() * .5
          lLength = Math.sqrt(Math.pow(pl - bl, 2) + Math.pow(pt - bb, 2))
          rad = Math.atan2(pt - bb, pl - bl)
          deg = (180 * rad) / Math.PI
          tmpPaginationSlider.dottedLineLeft.width(lLength).height(1).css
            top: ((pt + bb) * .5) + "px"
            left: ((pl + bl) * .5 - lLength * .5) + "px"
            transform: "rotate(" + (deg + 0) + "deg)"

          rLength = Math.sqrt(Math.pow(pr - br, 2) + Math.pow(pt - bb, 2))
          rad = Math.atan2(pt - bb, pr - br)
          deg = (180 * rad) / Math.PI
          tmpPaginationSlider.dottedLineRight.width(rLength).height(1).css
            top: ((pt + bb) * .5) + "px"
            left: ((pr + br) * .5 - rLength * .5) + "px"
            transform: "rotate(" + (deg + 0) + "deg)"

          return

        $(window).resize ->
          tmpPaginationSlider.render()
          return

      # 諸元の保持
      PAGENATION_MAX = 5
      PAGENATION_MARGIN = 2

      # 一度に表示されるレコード数
      iLength = @fnPagingInfo().iLength

      # 総レコード数
      tmpPaginationSlider.totalDisplayRecords = @fnPagingInfo().iFilteredTotal

      # 総ページ数
      tmpPaginationSlider.totalPage = @fnPagingInfo().iTotalPages

      # ページネーションの数
      tmpPaginationSlider.displayPagination = tmpPaginationSlider.totalPage
      tmpPaginationSlider.displayPagination = (if tmpPaginationSlider.displayPagination > PAGENATION_MAX then PAGENATION_MAX else tmpPaginationSlider.displayPagination)

      # 現在のページ
      currentPage = Math.floor(@fnPagingInfo().iStart / iLength)
      tmpPaginationSlider.currentPage = currentPage
      tmpPaginationSlider.setPaginationRange()

      # ページネーションのレンダリング
      if tmpPaginationSlider.totalDisplayRecords <= iLength
        tmpPaginationSlider.pagination.hide()
      else
        tmpPaginationSlider.pagination.show()
        tmpPaginationSlider.render()

      # 変更した tmpPaginationSlider を、テーブルの paginationSlider に設定する
      setting.oInit.paginationSlider = tmpPaginationSlider
      return

  $(".result-download-container > a").on "click", (e) ->
    location.href = e.target.href
    false

  window.query = ->
    drawInfo[currentKey].dataTable.draw()
    return

  $("#result_tabs").on "click", (e) ->
    currentKey = $(e.target).data("key")

    # タブ変更時に再度検索をする
    # 上側 Facets 部分の変更した結果で検索するため
    # ここを消すと前の状態を保持できるが、上側は変更されているため、選択している 各絞り込み条件と下の結果が異なるものが描画される
    window.query()
    return

  return
