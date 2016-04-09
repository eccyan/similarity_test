require 'bundler/setup' 
require 'pry'
require 'json'
require 'ruby-progressbar'
require 'okura/serializer'
require 'parallel'

exit if ARGF.nil?

def dev_null
  orig_stdout = $stdout.dup # does a dup2() internally
  $stdout.reopen('/dev/null', 'w')
  yield
ensure
  $stdout.reopen(orig_stdout)
end

dictionary_root = Pathname('dictionaries')

tagger = dev_null do
  Okura::Serializer::FormatInfo.create_tagger dictionary_root.join('uni')
end

tmp_root = Pathname('tmp')
texts = JSON.load ARGF.read

module Okura
  class Tagger
    def parse str
      chars = str.split(//)
      nodes = Nodes.new(chars.length + 2, @mat)
      nodes.add(0, Node.mk_bos_eos)
      nodes.add(chars.length + 1, Node.mk_bos_eos)

      Parallel.map(str.length.times.each_slice(1000), in_processes: 4) do |chunk|
        chunk.map do |i|
          [i, @dic.possible_words(str, i).map { |w| Node.new w }]
        end
      end.map(&:to_h).each do |hash|
        hash.each do |key, value|
          value.each { |node| nodes.add key + 1, node }
        end
      end

      nodes
    end
  end
end

file_nodes = texts.map do |filename, text|
  nodes = tagger.parse text.lines.map(&:strip).reject(&:empty?).join("\n")
  [filename, nodes]
end.to_h

file_nouns = file_nodes.map do |filename, nodes|
  nouns = nodes.mincost_path.to_a.map(&:word).select { |word| word.left.text.split(',').first == '名詞' }
  [filename, nouns.map(&:surface)]
end.to_h

jj file_nouns
