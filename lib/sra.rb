require 'bio-sra'

class Bio::SRA::Tables::SRA
  def search_string
    # run or sample or study or experiment or submission
    search_terms = [
      run_accession,
      sample_accession,
      study_accession,
      experiment_accession,
      submission_accession,
    ]
    return '"'+search_terms.join('" or "')+'"'
  end
end
