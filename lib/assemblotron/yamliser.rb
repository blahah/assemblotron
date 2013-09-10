require 'yaml'

d = {
  :input_filetypes => [
    {
      :min => 2,
      :allowed_extensions => [
        '.fastq',
        '.fq',
        '.fasta',
        '.fa'
      ]
    }
  ],
  :output_filetypes => [
    {
      :n => 1,
      :allowed_extensions => [
        '.fa',
        '.fasta',
        '.fas',
        '.scafSeq',
        '.config'
      ]
    }
  ],
  :objectives => [
    'bad_read_mappings',
    'reciprocal_best_annotation',
    'unexpressed_transcripts'
  ]
}

File.open('assemblotron.yml', 'w') do |f|
  f.puts d.to_yaml
end

sd = {
  :input_files => {
    :q1 => 'l.fq',
    :q2 => 'r.fq'
  },
  :output_files => {
    :assembly => 'assembly.scafSeq'
  },
  :parameter_ranges => {
    :K => (21..81).step(2).to_a,
    :M => (0..3).to_a, # def 1, min 0, max 3 #k value
    :d => (0..6).step(2).to_a, # KmerFreqCutoff: delete kmers with frequency no larger than (default 0)
    :D => (0..6).step(2).to_a, # edgeCovCutoff: delete edges with coverage no larger than (default 1)
    :G => (25..150).step(5).to_a, # gapLenDiff(default 50): allowed length difference between estimated and filled gap
    :L => [200], # minLen(default 100): shortest contig for scaffolding
    :e => (2..12).step(5).to_a, # contigCovCutoff: delete contigs with coverage no larger than (default 2)
    :t => (2..12).step(5).to_a # locusMaxOutput: output the number of transcriptome no more than (default 5) in one locus
  },
  :constructor_path => 'soap_denovo_trans.rb'
}



File.open('assemblers/definitions/soap_denovo_trans.yml', 'w') do |f|
  f.puts sd.to_yaml
end