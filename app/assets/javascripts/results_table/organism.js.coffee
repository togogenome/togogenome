$ ->
  # 表示するデータを指定し初期化
  drawInfo.organism =
    dataTable: $("#organism_results").DataTable(
      ajax:
        url: "/report_type/organisms.json"
      columns: [
        {data: "organism_link"},
        {data: "environment_links"},
        {data: "development_links"},
        {data: "growth_links"},
        {data: "metabolism_links"},
        {data: "morphology_links"},
        {data: "motility_links"},
        {data: "serotype_links"},
        {data: "staining_links"},
      ]
    )
    downloadCSV: '/report_type/organisms.csv'

  $("#organism_results").parent().find(".result-download-container").append "<a>Download CSV</a>"
  return
