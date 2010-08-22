#
#    this is usesthis.com, a sinatra application.
#    it is copyright (c) 2009-2010 daniel bogan (d @ waferbaby, then a dot and a 'com')
#

require 'datamapper'

class Ware
    include DataMapper::Resource
    
    property :slug,         String, :key => true
    property :title,        String
    property :url,          String, :length => 250
    property :description,  String, :length => 100
    
    timestamps :at
    
    validates_uniqueness_of :slug
    validates_presence_of :title, :url, :description
    
    has n, :interviews, :through => Resource
    has 1, :platform, :through => Resource
end