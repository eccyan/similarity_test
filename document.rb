require 'bundler/setup' 
require 'pry'
require 'oga'
require 'wikicloth'
require 'sanitize'
require 'parallel'

documents_root = Pathname('documents')

wikitexts = if ARGV.empty?
  file = File.open documents_root.join('uncyc.ja.xml')
  binding.pry
  Oga.parse_xml(file).xpath('mediawiki/page/revision/text[text()]').map(&:text)
else
  [File.open(documents_root.join(ARGV.first)).read]
end

texts = Parallel.map(wikitexts[0...10000].to_a.each_slice(1000), in_processes: 4) do |chunk|
  chunk.map do |wikitext|
    Sanitize.fragment WikiCloth::Parser.new(data: wikitext).to_html rescue nil
  end.compact
end.flatten

puts texts.join("\n")
