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
        ENV['RACK_ENV'] == 'production' ? "http://#{interview.slug}.usesthis.com/" : "/#{interview.slug}/"
    end
    
    def interview_contents(interview)
        result = <<END
### Who are you and what do you do?
#{interview.overview}

### What hardware do you use?
#{interview.hardware}

### And what software?
#{interview.software}

### What would be your dream setup?
#{interview.dream_setup}
END
        
        if interview.wares.length > 0
            result += "\r\n\r\n"
        
            interview.wares.each do |ware|
                result += "[#{ware.slug}]: #{ware.url} \"#{ware.description}\"\n"
            end
        end

        result
    end
    
    def needs_auth
        raise not_found unless has_auth?
    end
    
    def has_auth?
        session[:authorised] == true
    end
end

get '/' do
    @count, @interviews = Interview.paginated(:published_at.not => nil, :page => current_page, :per_page => 10, :order => [:published_at.desc])
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
    
    @interview = Interview.new
    haml :'interviews/new'
end

post '/interviews/new/?' do
    needs_auth
    
    @interview = Interview.new(params)
    if @interview.save
        redirect "/#{@interview.slug}/"
    else
        haml :'interviews/new'
    end
end

get '/wares/new/?' do
    needs_auth
    
    @ware = Ware.new(:slug => params[:slug])
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

get '/:slug/edit/?' do |slug|
    needs_auth
    
    @interview = Interview.first(:slug => slug)
    raise not_found unless @interview

    haml :'interviews/edit'
end

post '/:slug/edit/?' do |slug|
    needs_auth
    
    @interview = Interview.first(:slug => slug)
    raise not_found unless @interview
    
    if @interview.update(params)
        redirect "/#{@interview.slug}/"
    else
        haml :'interviews/edit'
    end
end

get '/:slug.markdown' do |slug|
    @interview = Interview.first(:slug => slug)
    raise not_found unless @interview
    
    content_type 'text/plain; charset=utf-8;'
    interview_contents(@interview)
end

get '/:slug/?' do |slug|
    @interview = Interview.first(:slug => slug)
    raise not_found unless @interview

    haml :'interviews/show'
end

not_found do
    haml :not_found
end

error do
    haml :error
end