$(function() {
  // 表示するデータを指定し初期化
  dataTables.gene = $("#gene_results").DataTable({
    "ajax" : {
      "url" : "/proteins/gene/search.json",
      "data": function(d) {
        d.taxonomy =           $('#_taxonomy_id').val();
        d.environment =        $('#_environment_id').val();
        d.biological_process = $('#_biological_process_id').val();
        d.molecular_function = $('#_molecular_function_id').val();
        d.cellular_component = $('#_cellular_component_id').val();
        d.phenotype =          $('#_phenotype_id').val();
      },
      "error": function() {
        alert('failing query...');
        return;
      }
    },
    "columns": [
      { "data": "name", "width" : "220px" },
      { "data": "gene_links" },
      { "data": "entry_identifier", "width" : "100px" },
      { "data": "go_links" },
      { "data": "organism_link" },
    ],
    "paginationSlider" : null
  });

  $("#gene_results").parent().find(".result-download-container").append('<a>Download CSV</a>');
})
