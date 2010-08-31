#
#    this is usesthis.com, a sinatra application.
#    it is copyright (c) 2009-2010 daniel bogan (d @ waferbaby, then a dot and a 'com')
#

require 'datamapper'

class Ware
    include DataMapper::Resource
    
    property :slug,         String, :key => true
    property :title,        String
    property :type,         Discriminator
    property :url,          String, :length => 250
    property :description,  String, :length => 100
    
    timestamps :at
    
    validates_uniqueness_of :slug
    validates_presence_of :title, :url, :description
    
    has n, :interviews, :through => Resource
    has n, :platforms, :through => Resource
    belongs_to :brand
end

class Hardware < Ware
end

class Software < Ware
end