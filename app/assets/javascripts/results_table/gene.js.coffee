$ ->
  # 表示するデータを指定し初期化
  drawInfo.gene =
    dataTable: $("#gene_results").DataTable(
      ajax:
        url: "/report_type/genes/search.json"
      columns: [
        {data: "name", width: "220px"}
        {data: "gene_links"}
        {data: "entry_identifier", width: "100px"}
        {data: "go_links"}
        {data: "organism_link"}
      ]
    )
    downloadCSV: '/report_type/genes/search.csv'

  $("#gene_results").parent().find(".result-download-container").append "<a>Download CSV</a>"
  return
