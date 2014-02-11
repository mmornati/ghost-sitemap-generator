#!/usr/bin/ruby

require 'rubygems'
require 'builder'
require 'mysql'
require 'time'
require 'builder/xmlmarkup'
require 'open-uri'

class MyXmlMarkup < ::Builder::XmlMarkup
  def tag!(sym, *args, &block)
    if @level == 0 # Root element
      args << {"xmlns" => "http://www.sitemaps.org/schemas/sitemap/0.9",
               "xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance",
               "xsi:schemaLocation" => "http://www.sitemaps.org/schemas/sitemap/0.9 http://www.sitemaps.org/schemas/sitemap/0.9/sitemap.xsd"}
    end

    #if args[:nil] = true
    #  args << {"xsi:nil" => true}
    #end

    super(sym, *args, &block)
  end
end


begin
    site_base_url = ARGV[0]
    change_freq = ARGV[1]
    priority = ARGV[2]
    dest_file = ARGV[3]
    con = Mysql.new 'localhost', 'ghost', 'ghostPWD', 'ghost'
    rs = con.query "select slug,updated_at from posts where status='published' order by id desc;"
    puts "Number of posts #{rs.num_rows}"
    xml = MyXmlMarkup.new( :indent => 2 )
    xml.instruct! :xml, :encoding => "ASCII"
    xml.urlset do |urlset|
        urlset.url do |baseurl|
            baseurl.loc 'http://' + site_base_url
            baseurl.lastmod Time.now.strftime("%Y-%m-%dT%H:%M:%S+00:00")
            baseurl.changefreq change_freq
            baseurl.priority priority
        end
        rs.each_hash do |post|
          urlset.url do |p|
             #TODO: read settings -> permalinks
             #      read blog name
             p.loc 'http://' + site_base_url + '/' + post['slug'] + '/'
             p.lastmod Time.parse(post['updated_at']).strftime("%Y-%m-%dT%H:%M:%S+00:00")
             p.changefreq change_freq
             p.priority priority
          end
        end
    end
    xml_data = xml.target!
    file = File.new(dest_file, "wb")
    file.write(xml_data)
    file.close
 
    #Calling Google
    url_google = "http://www.google.com/webmasters/tools/ping?sitemap=http%3A%2F%2F#{site_base_url}%2Fsitemap.xml"
    response = open(url_google).read
    puts response    
rescue Mysql::Error => e
    puts e.errno
    puts e.error
    
ensure
    con.close if con
end
