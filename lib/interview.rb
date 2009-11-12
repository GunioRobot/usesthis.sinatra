#
#    this is usesthis.com, a sinatra application.
#    it is copyright (c) 2009 daniel bogan (d @ waferbaby, then a dot and a 'com')
#

require 'datamapper'

class Interview
    include DataMapper::Resource
    
    property :slug,         String, :key => true
    property :person,       String
    property :summary,      String, :length => 100
    property :credits,      String, :length => 80
    property :contents,     Text
    property :published_at, DateTime
    
    timestamps :at
    
    validates_is_unique :slug
    validates_present :person, :summary, :contents
    validates_with_method :contents, :method => :link_wares
    
    has n, :wares, :through => Resource
    
    before :create, :link_wares
    before :update, :link_wares
    
    attr_accessor :unknown_wares

    def contents_with_links
        result = attribute_get(:contents)
        if self.wares.length > 0
            result += "\r\n\r\n"

            self.wares.each do |ware|
                result += "[#{ware.slug}]: #{ware.url} \"#{ware.description}\"\n"
            end
        end

        result
    end
    
    def link_wares
        @unknown_wares = []
        
        contents.scan(/\[([^\[\(\)]+)\]\[([a-z0-9\.\-]+)?\]/).each do |link|
            slug = link[1] ? link[1] : link[0].downcase
        
            unless self.wares.first(:slug => slug)
                ware = Ware.first(:slug => slug)
                if ware.nil?
                    @unknown_wares << slug
                else
                    self.wares << ware
                end
            end
        end

        if @unknown_wares.empty?
            true
        else
            [false, "Contents include unknown wares"]
        end
    end
end