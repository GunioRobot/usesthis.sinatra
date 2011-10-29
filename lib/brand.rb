require 'datamapper'

class Brand
    include DataMapper::Resource

    property :slug,         String, :key => true
    property :title,        String
    property :url,          String, :length => 250
    property :description,  String, :length => 100

    timestamps :at

    validates_uniqueness_of :slug
    validates_presence_of :title, :url, :description

    has n, :wares
end