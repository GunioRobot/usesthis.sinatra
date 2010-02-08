#
#    this is usesthis.com, a sinatra application.
#    it is copyright (c) 2009-2010 daniel bogan (d @ waferbaby, then a dot and a 'com')
#

require 'rubygems'
require 'sinatra'
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

    enable :sessions
end

helpers do
    def current_page
        @page = params[:page] && params[:page].match(/\d+/) ? params[:page].to_i : 1
    end
    
    def interview_url(interview)
        development? ? "/interviews/#{interview.slug}/" : "http://#{interview.slug}.usesthis.com/"
    end
    
    def needs_auth
        raise not_found unless has_auth?
    end
    
    def has_auth?
        session[:authorised] == true
    end
end

before do
    response['Cache-Control'] = "public, max-age=600" unless development?
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
    @licenses = License.all
    
    haml :interview_form
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
        haml :interview_form
    end
end

get '/interviews/:slug/edit/?' do |slug|
    needs_auth
    
    @interview = Interview.first(:slug => slug)
    raise not_found unless @interview
    
    @licenses = License.all

    haml :interview_form
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
    end
    
    if @interview.save
        redirect "/interviews/#{@interview.slug}/"
    else
        @licenses = License.all
        haml :interview_form
    end
end

get '/interviews/:slug/?' do |slug|
    @interview = Interview.first(:slug => slug)
    raise not_found unless @interview

    @title = "An interview with #{@interview.person} on "

    haml :interview
end

get '/wares/new/?' do
    needs_auth
    
    @ware = Ware.new(params)
    haml :ware_form
end

post '/wares/new/?' do
    needs_auth

    @ware = Ware.new(params)
    if @ware.save
        redirect '/'
    else
        haml :ware_form
    end
end

get '/wares/:slug/edit/?' do |slug|
    needs_auth
    
    @ware = Ware.first(:slug => slug)
    raise not_found unless @ware

    @title = slug

    haml :ware_form
end

post '/wares/:slug/edit/?' do |slug|
    needs_auth
    
    @ware = Ware.first(:slug => slug)
    raise not_found unless @ware
    
    if @ware.update(params)
        redirect "/"
    else
        haml :ware_form
    end
end