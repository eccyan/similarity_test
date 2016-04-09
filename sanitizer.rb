require 'bundler/setup' 
require 'pry'
require 'json'
require 'oga'
require 'wikicloth'
require 'sanitize'
require 'parallel'

exit if ARGV.empty?

documents_root = Pathname('documents')

wikitexts = ARGV.map do |filename|
  text = File.open(documents_root.join filename).read
  [filename, text]
end.to_h

texts = Parallel.map(wikitexts.to_a.each_slice(1000), in_processes: 4) do |chunk|
  chunk.map do |pair|
    [pair.first, Sanitize.fragment(WikiCloth::Parser.new(data: pair.last).to_html)] rescue nil
  end.compact
end.first.to_h

jj texts
