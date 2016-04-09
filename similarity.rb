require 'bundler/setup' 
require 'pry'
require 'matrix'
require 'tf-idf-similarity' 

return if ARGV.empty?

documents_root = Pathname('documents')
tmp_root = Pathname('tmp')

documents = ARGV.map do |name|
  tokens = File.open(tmp_root.join("#{name}_tokens")).readlines.map(&:chomp)
  TfIdfSimilarity::Document.new File.open(tmp_root.join(name)).read, tokens: tokens
end

model = TfIdfSimilarity::TfIdfModel.new(documents)

# Print the tf*idf values for terms in a document
documents.each.with_index do |document, index|
  puts "document#{index}:"
  document.terms.map do |term|
    [term, model.tfidf(document, term)]
  end.sort_by do |pair|
    -pair.last
  end.take(10).each do |pair|
    puts "  #{pair.first}: #{pair.last.round(4)}"
  end
end

# Find the similarity of two documents in the matrix
matrix = model.similarity_matrix
similarity = matrix[*documents.map { |document| model.document_index document }]

puts "similarity: #{similarity}"
