$ ->
  # 表示するデータを指定し初期化
  drawInfo.protein =
    dataTable: $("#protein_results").DataTable(
      ajax:
        url: "/report_type/proteins/search.json"
      columns: [
        {data: "name", width: "220px"}
        {data: "gene_links"}
        {data: "entry_identifier", width: "100px"}
        {data: "go_links"}
        {data: "organism_link"}
        {data: "environment_links"}
        {data: "phenotype_links"}
      ]
    )
    downloadCSV: '/report_type/proteins/search.csv'

  $("#protein_results").parent().find(".result-download-container").append "<a>Download CSV</a>"
  return
