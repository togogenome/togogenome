$ ->
  # 表示するデータを指定し初期化
  drawInfo.gene =
    dataTable: $("#gene_results").DataTable(
      ajax:
        url: "/report_type/genes.json"
      columns: [
        {data: "gene_link"}
        {data: "protein_links", width: "100px"}
        {data: "protein_names", width: "220px"}
        {data: "go_links"}
        {data: "organism_link"}
      ]
    )
    downloadCSV: '/report_type/genes.csv'

  $("#gene_results").parent().find(".result-download-container").append "<a>Download CSV</a>"
  return
