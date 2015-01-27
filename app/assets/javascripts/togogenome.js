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
});
