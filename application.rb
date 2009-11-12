#
#    this is usesthis.com, a sinatra application.
#    it is copyright (c) 2009 daniel bogan (d @ waferbaby, then a dot and a 'com')
#

require 'rubygems'
require 'sinatra'
require 'datamapper'
require 'haml'
require 'rdiscount'

Dir.glob('lib/*.rb') do |lib|
    require lib
end

configure do
    @config = YAML.load_file('usesthis.yml')
    DataMapper.setup(:default, @config[:database])
    
    set :admin_username, @config[:admin][:name]
    set :admin_password, @config[:admin][:password]
    set :haml, {:format => :html5}

    enable :sessions
end

helpers do
    def current_page
        @page = params[:page] && params[:page].match(/\d+/) ? params[:page].to_i : 1
    end
    
    def interview_url(interview)
        ENV['RACK_ENV'] == 'production' ? "http://#{interview.slug}.usesthis.com/" : "/interviews/#{interview.slug}/"
    end
    
    def needs_auth
        raise not_found unless has_auth?
    end
    
    def has_auth?
        session[:authorised] == true
    end
end

not_found do
    haml :not_found
end

error do
    haml :error
end

get %r{^/(interviews/?)?$} do
    @interviews = Interview.all(:published_at.not => nil, :order => [:published_at.desc])
    haml :index
end

get '/about/?' do
    haml :about
end

get '/feed/?' do
    content_type 'application/atom+xml', :charset => 'utf-8'

    @interviews = Interview.all(:published_at.not => nil, :order => [:published_at.desc])
    haml :feed, {:format => :xhtml, :layout => false}
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

get '/interviews/new/?' do
    needs_auth
    
    @interview = Interview.new(params)
    haml :'interviews/new'
end

post '/interviews/new/?' do
    needs_auth
    
    @interview = Interview.new(params)
    if @interview.save
        redirect "/interviews/#{@interview.slug}/"
    else
        haml :'interviews/new'
    end
end

get '/interviews/:slug/edit/?' do |slug|
    needs_auth
    
    @interview = Interview.first(:slug => slug)
    raise not_found unless @interview

    haml :'interviews/edit', :layout => !request.xhr?
end

post '/interviews/:slug/edit/?' do |slug|
    needs_auth
    
    @interview = Interview.first(:slug => slug)
    raise not_found unless @interview
    
    if @interview.update(params)
        redirect "/interviews/#{@interview.slug}/"
    else
        haml :'interviews/edit', :layout => !request.xhr?
    end
end

get '/interviews/:slug/?' do |slug|
    @interview = Interview.first(:slug => slug)
    raise not_found unless @interview

    haml :'interviews/show'
end

get '/wares/new/?' do
    needs_auth
    
    @ware = Ware.new(params)
    haml :'wares/new'
end

post '/wares/new/?' do
    needs_auth

    @ware = Ware.new(params)
    if @ware.save
        redirect '/'
    else
        haml :'wares/new'
    end
end

get '/wares/:slug/edit/?' do |slug|
    needs_auth
    
    @ware = Ware.first(:slug => slug)
    raise not_found unless @ware

    haml :'wares/edit', :layout => !request.xhr?
end

post '/wares/:slug/edit/?' do |slug|
    needs_auth
    
    @ware = Ware.first(:slug => slug)
    raise not_found unless @ware
    
    if @ware.update(params)
        redirect "/"
    else
        haml :'wares/edit', :layout => !request.xhr?
    end
end