#
#    this is usesthis.com, a sinatra application.
#    it is copyright (c) 2009-2010 daniel bogan (d @ waferbaby, then a dot and a 'com')
#

require 'rubygems'
require 'sinatra'
require 'sinatra/cache'
require 'datamapper'
require 'haml'

Dir.glob('lib/*.rb') do |lib|
    require lib
end

configure do
    @config = YAML.load_file(File.join('conf', 'settings.yml'))
    DataMapper.setup(:default, @config[:database])
    
    set :admin_username, @config[:admin][:name]
    set :admin_password, @config[:admin][:password]
    
    set :haml, {:format => :html5}
    
    set :cache_enabled, !development?
    set :cache_output_dir, File.dirname(__FILE__) + '/public/system/cache'

    enable :sessions
end

helpers do
    def current_page
        @page = params[:page] && params[:page].match(/\d+/) ? params[:page].to_i : 1
    end
    
    def interview_url(interview)
        development? ? "/interviews/#{interview.slug}/" : "http://#{interview.slug}.usesthis.com/"
    end
    
    def domain_prefix
        development? ? '' : 'http://usesthis.com'
    end
    
    def needs_auth
        raise not_found unless has_auth?
    end
    
    def has_auth?
        session[:authorised] == true
    end    
end

before do
    response['Cache-Control'] = "public, max-age=600" unless development? || has_auth?
end

not_found do
    haml :not_found, :cache => false
end

error do
    haml :error, :cache => false
end

get %r{^/(interviews/?)?$} do
    @interviews = Interview.all(:published_at.not => nil, :order => [:published_at.desc])
    
    unless @interviews.empty? || development? || has_auth?
        etag(Digest::MD5.hexdigest("index:" + @interviews[0].updated_at.to_s))
        last_modified(@interviews[0].updated_at)
    end
    
    haml :index
end

get '/about/?' do
    haml :about
end

get '/community/?' do
    haml :community
end

get '/feed/?' do
    content_type 'application/atom+xml', :charset => 'utf-8'

    @interviews = Interview.all(:published_at.not => nil, :order => [:published_at.desc])
    
    unless @interviews.empty? || development? || has_auth?
        etag(Digest::MD5.hexdigest("feed:" + @interviews[0].updated_at.to_s))
        last_modified(@interviews[0].updated_at)
    end
    
    haml :feed, {:format => :xhtml, :layout => false, :cache => false}
end

get '/login/?' do
    @auth ||= Rack::Auth::Basic::Request.new(request.env)
    unless @auth.provided? && @auth.basic? && @auth.credentials && @auth.credentials[0] == options.admin_username && OpenSSL::Digest::SHA1.new(@auth.credentials[1]).hexdigest == options.admin_password
        response['WWW-Authenticate'] = %(Basic realm="The Setup")
        throw :halt, [401, "Don't think I don't love you."]
        return
    end
    
    session[:authorised] = true
    redirect '/'
end

get '/logout/?' do
    session[:authorised] = false
    redirect '/'
end

# Brands

get '/brands/new/?' do
    needs_auth
    
    @brand = Brand.new(params)
    haml :brand_form, :cache => false
end

post '/brands/new/?' do
    needs_auth

    @brand = Brand.new(params)
    if @brand.save
        redirect '/'
    else
        haml :brand_form, :cache => false
    end
end

get '/brands/:slug/edit/?' do |slug|
    needs_auth
    
    @brand = Brand.first(:slug => slug)
    raise not_found unless @brand

    @title = slug

    haml :brand_form, :cache => false
end

post '/brands/:slug/edit/?' do |slug|
    needs_auth
    
    @brand = Brand.first(:slug => slug)
    raise not_found unless @brand
    
    if @brand.update(params)
        redirect "/"
    else
        haml :brand_form, :cache => false
    end
end

# Interviews

get '/interviews/new/?' do
    needs_auth
    
    @interview = Interview.new(params)
    @licenses = License.all
    
    haml :interview_form, :cache => false
end

post '/interviews/new/?' do
    needs_auth
    
    @interview = Interview.new(
        :slug       => params["slug"],
        :person     => params["person"],
        :summary    => params["summary"],
        :credits    => params["credits"],
        :contents   => params["contents"]
    )
    
    @interview.license = License.first(:slug => params["license"])
    
    if @interview.save
        redirect "/interviews/#{@interview.slug}/"
    else
        @licenses = License.all
        haml :interview_form, :cache => false
    end
end

get '/interviews/:slug/edit/?' do |slug|
    needs_auth
    
    @interview = Interview.first(:slug => slug)
    raise not_found unless @interview
    
    @licenses = License.all

    haml :interview_form, :cache => false
end

post '/interviews/:slug/edit/?' do |slug|
    needs_auth
    
    @interview = Interview.first(:slug => slug)
    raise not_found unless @interview
    
    @interview.attributes = {
        :slug       => params["slug"],
        :person     => params["person"],
        :summary    => params["summary"],
        :credits    => params["credits"],
        :contents   => params["contents"]
    }
    
    @interview.license = License.first(:slug => params["license"])
    
    case params["status"]
        when 'draft':
            @interview.published_at = nil unless @interview.published_at.nil?
        when 'published':
            @interview.published_at = Time.now if @interview.published_at.nil?
            cache_expire("/")
    end
    
    if @interview.save
        cache_expire("/interviews/#{@interview.slug}/")
        redirect "/interviews/#{@interview.slug}/"
    else
        @licenses = License.all
        haml :interview_form, :cache => false
    end
end

get '/interviews/:slug/?' do |slug|
    @interview = Interview.first(:slug => slug)
    raise not_found unless @interview
    
    unless development? || has_auth?
        etag(Digest::MD5.hexdigest(@interview.slug + ':' + @interview.updated_at.to_s))
        last_modified(@interview.updated_at)
    end

    @title = "An interview with #{@interview.person}"

    haml :interview
end

# Wares

get '/wares/new/?' do
    needs_auth
    
    @ware = Ware.new(params)
    @brands = Brand.all
    
    haml :ware_form, :cache => false
end

post '/wares/new/?' do
    needs_auth

    @ware = Ware.new(params)
    @ware.brand = Brand.first(:slug => params["brand"])
    
    if @ware.save
        redirect '/'
    else
        @brands = Brand.all
        haml :ware_form, :cache => false
    end
end

get '/wares/:slug/edit/?' do |slug|
    needs_auth
    
    @ware = Ware.first(:slug => slug)
    raise not_found unless @ware

    @title = slug
    @brands = Brand.all

    haml :ware_form, :cache => false
end

post '/wares/:slug/edit/?' do |slug|
    needs_auth
    
    @ware = Ware.first(:slug => slug)
    raise not_found unless @ware
    
    @ware.attributes = {
        :slug           => params["slug"],
        :title          => params["title"],
        :url            => params["url"],
        :description    => params["description"],
    }
    
    @ware.brand = Brand.first(:slug => params["brand"])
        
    if @ware.save
        redirect "/"
    else
        @brands = Brand.all
        haml :ware_form, :cache => false
    end
end

get %r{^/(hardware|software)/?$} do |type|
    
    @wares = eval(type.capitalize).all(:order => :title)

    haml :wares
end