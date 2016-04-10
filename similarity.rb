require 'bundler/setup' 
require 'pry'
require 'json'
require 'matrix'
require 'tf-idf-similarity' 

documents_root = Pathname('documents')
tmp_root = Pathname('tmp')

file_tokens = JSON.load ARGF.read

documents = file_tokens.map do |filename, tokens|
  document = TfIdfSimilarity::Document.new File.open(documents_root.join(filename)).read, tokens: tokens
  [filename, document]
end.to_h

model = TfIdfSimilarity::TfIdfModel.new(documents.values)

# Print the tf*idf values for terms in a document
tfidfs = documents.map do |name, document|
  tfidf = document.terms.map do |term|
    [term, model.tfidf(document, term)]
  end.sort_by do |pair|
    -pair.last
  end.to_h
  [name, tfidf]
end.to_h

# Find the similarity of two documents in the matrix
names = documents.values.map(&:id).zip(documents.keys).to_h
similarities = documents.values.combination(2).map do |comb|
  { documents: [names.fetch(comb.first.id), names.fetch(comb.last.id)],
    similarity: model.similarity_matrix[*comb.map { |document| model.document_index document }] }
end.sort_by do |hash|
  -hash.fetch(:similarity)
end

jj tfidfs: tfidfs, similarities: similarities
