#!/usr/bin/ruby

require 'rubygems'
require 'builder'
require 'mysql'
require 'time'
require 'builder/xmlmarkup'
require 'open-uri'
require 'optparse'
require 'pp'

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
    options = {}

    optparse = OptionParser.new do |opts|
        opts.banner = "Usage: generate_ghost_sitemap.rb [options]"
        opts.on( '-h', '--help', 'Display this screen' ) do
           puts opts
           exit
        end
        opts.on( '-s', '--site SITE', 'Site base URL. EX: blog.mornati.net' ) do |site|
           options[:site] = site
        end
        opts.on( '-f', '--frequency FREQUENCY', 'Update Frenquency. One of: always,hourly,daily,weekly,monthly,yearly,never' ) do |freq|
           options[:frequency] = freq
        end
        opts.on( '-p', '--priority PRIORITY', 'Update priority. Values beetwen 0.0 et 1.0' ) do |priority|
           options[:priority] = priority
        end
        opts.on( '-d', '--destfile DESTFILE', 'Sitemap destination file. Ex. /usr/share/server/sitemap.xml' ) do |dfile|
           options[:destfile] = dfile
        end
        opts.on( '-t', '--test', 'Do not ping Google after sitemap generation' ) do |v|
           options[:test] = v
        end
        opts.on( '-v', '--verbose', 'Verbose execution' ) do |v|
           options[:verbose] = v
        end
        opts.on( '-m', '--mysql HOSTNAME', 'MySQL hostname' ) do |host|
           options[:hostname] = host
        end
        opts.on( '-u', '--user USERNAME', 'MySQL Username' ) do |user|
           options[:user] = user
        end
        opts.on( '-w', '--password PASSWORD', 'MySQL Password' ) do |password|
           options[:password] = password
        end
        opts.on( '-b', '--dbname DBNAME', 'Database name' ) do |db|
           options[:dbname] = db
        end
    end

    begin
        optparse.parse!
        mandatory = [:site, :priority, :frequency, :destfile, :hostname, :user, :password, :dbname]
        missing = mandatory.select{ |param| options[param].nil? }        
        if not missing.empty?                                            
          puts "Missing options: #{missing.join(', ')}"                  
          puts optparse                                                  
          exit                                                           
        end                                                              
    rescue OptionParser::InvalidOption, OptionParser::MissingArgument      
        puts $!.to_s                                                           
        puts optparse                                                          
        exit                                                                   
    end 

    puts "Options Values:" unless !options[:verbose]
    pp options unless !options[:verbose] 
    
    con = Mysql.new options[:hostname], options[:user], options[:password], options[:dbname]
    rs = con.query "select slug,updated_at from posts where status='published' order by id desc;"
    tot_posts = rs.num_rows
    puts "Number of posts #{tot_posts}"
    xml = MyXmlMarkup.new( :indent => 2 )
    xml.instruct! :xml, :encoding => "ASCII"
    xml.urlset do |urlset|
        urlset.url do |baseurl|
            baseurl.loc 'http://' + options[:site]
            baseurl.lastmod Time.now.strftime("%Y-%m-%dT%H:%M:%S+00:00")
            baseurl.changefreq options[:frequency]
            baseurl.priority options[:priority]
        end
        rs.each_hash do |post|
          urlset.url do |p|
             #TODO: read settings -> permalinks
             #      read blog name
             p.loc 'http://' + options[:site] + '/' + post['slug'] + '/'
             p.lastmod Time.parse(post['updated_at']).strftime("%Y-%m-%dT%H:%M:%S+00:00")
             p.changefreq options[:frequency]
             p.priority options[:priority]
          end
        end
        rs = con.query "select value from settings as s where s.key = 'postsPerPage';"
        postsPerPage=0
        rs.each_hash do |p|
	    postsPerPage = p['value'].to_i
        end
        
        puts "PostsPerPage: #{postsPerPage}" unless !options[:verbose] 
	totalPages = (tot_posts.to_f / postsPerPage.to_f).round
        puts "Total Pages: #{totalPages}" unless !options[:verbose]
	puts "Generating Pages URL..." unless !options[:verbose]
        for n in 1 ... totalPages+1
            urlset.url do |p|
               p.loc 'http://' + options[:site] + "/page/#{n}/"
               p.lastmod Time.now.strftime("%Y-%m-%dT%H:%M:%S+00:00")
               p.changefreq options[:frequency]
               p.priority options[:priority]
            end
        end
    end
    xml_data = xml.target!
    file = File.new(options[:destfile], "wb")
    file.write(xml_data)
    file.close
 
    #Calling Google
    unless options[:test]
    	url_google = "http://www.google.com/webmasters/tools/ping?sitemap=http%3A%2F%2F#{options[:site]}%2Fsitemap.xml"
    	response = open(url_google).read
    	puts response unless !options[:verbose] 
    end
rescue Mysql::Error => e
    puts e.errno
    puts e.error
    
ensure
    con.close if con
end
