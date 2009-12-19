#
#    this is usesthis.com, a sinatra application.
#    it is copyright (c) 2009-2010 daniel bogan (d @ waferbaby, then a dot and a 'com')
#

require 'datamapper'

class Interview
    include DataMapper::Resource
    
    property :slug,         String, :key => true
    property :person,       String
    property :summary,      String, :length => 100
    property :credits,      String, :length => 100
    property :contents,     Text
    property :published_at, DateTime
    
    timestamps :at
    
    validates_is_unique :slug
    validates_present :person, :summary, :contents
    
    has n, :wares, :through => Resource
    
    before :create, :link_wares
    before :update, :link_wares
    
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
        contents.scan(/\[([^\[\(\)]+)\]\[([a-z0-9\.\-]+)?\]/).each do |link|
            ware_slug = link[1] ? link[1] : link[0].downcase

            unless self.wares.first(:slug => ware_slug)
                ware = Ware.first(:slug => ware_slug)
                if ware.nil?
                    ware = Ware.new(
                        :slug           => ware_slug,
                        :title          => ware_slug,
                        :description    => '?',
                        :url            => "/wares/#{ware_slug}/edit"
                    )
                end
                
                self.wares << ware
            end
        end
    end
end