require 'bundler/setup' 
require 'pry'
require 'net/http'
require 'ruby-progressbar'
require 'zip'

uncyc_xml_name = 'ja-wiki.zip'
tmp_root = Pathname('tmp')
documents_root = Pathname('documents')

Dir.mkdir(tmp_root) unless Dir.exists? tmp_root
Dir.mkdir(documents_root) unless Dir.exists? documents_root

ProgressBar.create(total: nil).tap do |pb|
  xml_path = "/#{uncyc_xml_name}"
  Net::HTTP.start 'download.uncyc.org' do |http|
    response = http.request_head xml_path
    pb.total = response['content-length'].to_i
    open(tmp_root.join(uncyc_xml_name), 'wb') do |f|
      http.get xml_path do |res|
        f.write res
        pb.progress += res.length
      end
    end
  end
  pb.stop
end


Zip::File.open tmp_root.join(uncyc_xml_name) do |zip|
  zip.each do |entry|
    zip.extract(entry, documents_root.join('uncyc.ja.xml')) { true }
  end
end
