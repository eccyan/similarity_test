require 'bundler/setup' 
require 'pry'
require 'ruby-progressbar'
require 'okura/serializer'
require 'parallel'

exit if ARGV.empty?

dictionary_root = Pathname('dictionaries')
tagger = Okura::Serializer::FormatInfo.create_tagger dictionary_root.join('uni')

tmp_root = Pathname('tmp')
file = File.open tmp_root.join(ARGV.first)
lines = file.readlines.reject { |x| x.strip == '' }

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

nodes = tagger.parse lines[0..5000].join("\n")

noun_words = nodes.mincost_path.to_a.map(&:word).select { |word| word.left.text.split(',').first == '名詞' }

puts noun_words.map(&:surface)
