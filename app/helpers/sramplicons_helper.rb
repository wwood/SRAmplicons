module SrampliconsHelper
  def scholar_url(sra_obj)
    q = '"'+[
      sra_obj.run_accession,
      sra_obj.sample_accession,
      sra_obj.study_accession,
      sra_obj.experiment_accession,
      sra_obj.submission_accession,
    ].join('" or "')+'"'

    return "http://scholar.google.com.au/scholar?q=#{q}&hl=en&as_sdt=2001&as_sdtp=on"
  end

  def pubmed_fulltext_url(pubmed_id)
    "http://eutils.ncbi.nlm.nih.gov/entrez/eutils/elink.fcgi?dbfrom=pubmed&id=#{pubmed_id}&retmode=ref&cmd=prlinks"
  end
end
