require 'bundler/setup' 
require 'pry'
require 'json'
require 'oga'
require 'wikicloth'
require 'sanitize'
require 'parallel'

require './buffer'

documents_root = Pathname('documents')

wikitexts = ARGF.read.lines.map(&:strip).map do |filename|
  text = File.open(documents_root.join filename).read
  [filename, text]
end.to_h

texts = Parallel.map(wikitexts.to_a.each_slice(1000), in_processes: 4) do |chunk|
  chunk.map do |pair|
    html = WikiCloth::Parser.new(data: pair.last).to_html
    dev_null $stderr do
      [pair.first, Sanitize.fragment(html)] rescue nil
    end
  end.compact
end.first.to_h

jj texts
