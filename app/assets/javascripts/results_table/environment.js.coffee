$ ->
  # 表示するデータを指定し初期化
  drawInfo.environment =
    dataTable: $("#environment_results").DataTable(
      ajax:
        url: "/report_type/environments.json"
      columns: [
        {data: "environment_link"}
        {data: "category"}
        {data: "inhabitants"}
      ]
    )
    downloadCSV: '/report_type/environments.csv'

  $("#environment_results").parent().find(".result-download-container").append "<a>Download CSV</a>"
  return
