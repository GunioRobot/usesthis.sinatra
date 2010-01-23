#
#    this is usesthis.com, a sinatra application.
#    it is copyright (c) 2009-2010 daniel bogan (d @ waferbaby, then a dot and a 'com')
#

require 'datamapper'

class License
    include DataMapper::Resource
    
    property :slug,         String, :key => true
    property :title,       String
    property :url,          String, :length => 150
    
    timestamps :at
    
    has n, :interviews, :through => Resource
end