require 'bundler/setup' 
require 'pry'
require 'oga'
require 'wikicloth'
require 'sanitize'
require 'parallel'

return if ARGV.empty?

documents_root = Pathname('documents')

#file = File.open documents_root.join('uncyc.ja.xml')
#wikitexts = Oga.parse_xml(file).xpath('mediawiki/page/revision/text[text()]').map(&:text)

wikitexts = [File.open(documents_root.join(ARGV.first)).read]

texts = Parallel.map(wikitexts[0...10000].to_a.each_slice(1000), in_processes: 4) do |chunk|
  chunk.map do |wikitext|
    Sanitize.fragment WikiCloth::Parser.new(data: wikitext).to_html rescue nil
  end.compact
end.flatten

puts texts.join("\n")
