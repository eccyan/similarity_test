require 'bundler/setup' 
require 'pry'
require 'net/http'
require 'ruby-progressbar'
require 'zip'
require 'oga'

filename = 'ja-wiki.zip'
tmp_root = Pathname('tmp')
documents_root = Pathname('documents')

Dir.mkdir(tmp_root) unless Dir.exists? tmp_root
Dir.mkdir(documents_root) unless Dir.exists? documents_root

unless tmp_root.join(filename).exist?
  ProgressBar.create(title: 'download unsyc ja-wiki.zip', total: nil).tap do |pb|
    incrementor = Thread.new do
      while pb.total.nil? do pb.increment && sleep(1) end
    end

    begin
      xml_path = "/#{filename}"
      Net::HTTP.start 'download.uncyc.org' do |http|
        response = http.request_head xml_path
        pb.total = response['content-length'].to_i
        incrementor.join
        pb.reset
        pb.total = response['content-length'].to_i
        open(tmp_root.join(filename), 'wb') do |file|
          http.get xml_path do |res|
            file.write res
            pb.progress += res.length
          end
        end
      end
    ensure
      incrementor.kill
    end
  end
end

Zip::File.open tmp_root.join(filename) do |zip|
  zip.each do |entry|
    zip.extract(entry, tmp_root.join('uncyc.ja-wiki.xml')) { true }
  end
end

ProgressBar.create(title: 'create markdowns', total: nil).tap do |pb|
  incrementor = Thread.new do
    while pb.total.nil? do pb.increment && sleep(1) end
  end

  begin
    Oga.parse_xml(open tmp_root.join('uncyc.ja-wiki.xml')).tap do |parser|
      name = parser.xpath('mediawiki/page/title[text()]').map(&:text)
      text = parser.xpath('mediawiki/page/revision/text[text()]').map(&:text)
      pb.total = name.count
      incrementor.join
      pb.reset
      pb.total = name.count
      name.zip(text).each do |pair|
        open documents_root.join(pair.first.gsub('/', '_')), 'w' do |file|
          file.write pair.last
        end
        pb.increment
      end
    end
  ensure
    incrementor.kill
  end
end
