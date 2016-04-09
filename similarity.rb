require 'bundler/setup' 
require 'pry'
require 'json'
require 'matrix'
require 'tf-idf-similarity' 

exit if ARGF.nil?

documents_root = Pathname('documents')
tmp_root = Pathname('tmp')

file_tokens = JSON.load ARGF.read

documents = file_tokens.map do |filename, tokens|
  document = TfIdfSimilarity::Document.new File.open(documents_root.join(filename)).read, tokens: tokens
  [filename, document]
end.to_h

model = TfIdfSimilarity::TfIdfModel.new(documents.values)

# Print the tf*idf values for terms in a document
documents.each do |name, document|
  puts "#{name}:"
  document.terms.map do |term|
    [term, model.tfidf(document, term)]
  end.sort_by do |pair|
    -pair.last
  end.take(10).each do |pair|
    puts "  #{pair.first}: #{pair.last.round(4)}"
  end
end

# Find the similarity of two documents in the matrix
puts 'similarities:'
documents.values.combination(2).each.with_object(documents.values.map(&:id).zip(documents.keys).to_h) do |comb, names|
  similarity = model.similarity_matrix[*comb.map { |document| model.document_index document }]
  puts "  -"
  puts "    documents:"
  puts "      - #{names[comb.first.id]}"
  puts "      - #{names[comb.last.id]}"
  puts "    value: #{similarity}"
end
