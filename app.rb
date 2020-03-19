# Set up for the application and database. DO NOT CHANGE. #############################
require "sinatra"                                                                     #
require "sinatra/reloader" if development?                                            #
require "sequel"                                                                      #
require "logger"                                                                      #
require "twilio-ruby"                                                                 #
require "bcrypt"                                                                      #
connection_string = ENV['DATABASE_URL'] || "sqlite://#{Dir.pwd}/development.sqlite3"  #
DB ||= Sequel.connect(connection_string)                                              #
DB.loggers << Logger.new($stdout) unless DB.loggers.size > 0                          #
def view(template); erb template.to_sym; end                                          #
use Rack::Session::Cookie, key: 'rack.session', path: '/', secret: 'secret'           #
before { puts; puts "--------------- NEW REQUEST ---------------"; puts }             #
after { puts; }                                                                       #
#######################################################################################

offers_table = DB.from(:offers)
subscribers_table = DB.from(:subscribers)
users_table = DB.from(:users)

before do
    @current_user = users_table.where(id: session["user_id"]).to_a[0]
end

# homepage and list of offers (aka "index")
get "/" do
    puts "params: #{params}"

    @offers = offers_table.all.to_a
    pp @offers

    view "offers"
end

# offer details (aka "show")
get "/offers/:id" do
    puts "params: #{params}"

    @users_table = users_table
    @offer = offers_table.where(id: params[:id]).to_a[0]
    pp @offer

    @subscribers = subscribers_table.where(offer_id: @offer[:id]).to_a
    @interested_count = subscribers_table.where(offer_id: @offer[:id], interested: true).count

    view "offer"
end

# display the subscribe form (aka "new")
get "/offers/:id/subscribers/new" do
    puts "params: #{params}"

    @offer = offers_table.where(id: params[:id]).to_a[0]
    view "new_subscribe"
end

# receive the submitted rsvp form (aka "create")
post "/offers/:id/subscribers/create" do
    puts "params: #{params}"

    # first find the offer that subscrbing for
    @offer = offers_table.where(id: params[:id]).to_a[0]
    # next we want to insert a row in the subscribers table with the subscribe form data
    subscribers_table.insert(
        offer_id: @offer[:id],
        user_id: session["user_id"],
        comments: params["comments"],
        interested: params["interested"]
    )

    redirect "/offers/#{@offer[:id]}"
end

# display the subscribe form (aka "edit")
get "/subscribers/:id/edit" do
    puts "params: #{params}"

    @subscribe = subscribers_table.where(id: params["id"]).to_a[0]
    @offer = offers_table.where(id: @subscribe[:offer_id]).to_a[0]
    view "edit_subscribe"
end

# receive the submitted subscribe form (aka "update")
post "/subscribers/:id/update" do
    puts "params: #{params}"

    # find the rsvp to update
    @subscribe = subscribers_table.where(id: params["id"]).to_a[0]
    # find the rsvp's event
    @offer = offers_table.where(id: @subscribe[:offer_id]).to_a[0]

    if @current_user && @current_user[:id] == @subscribe[:id]
        subscribers_table.where(id: params["id"]).update(
            interested: params["interested"],
            comments: params["comments"]
        )

        redirect "/offers/#{@offer[:id]}"
    else
        view "error"
    end
end

# delete the subscribe (aka "destroy")
get "/subscribers/:id/destroy" do
    puts "params: #{params}"

    subscribe = subscribers_table.where(id: params["id"]).to_a[0]
    @offer = offers_table.where(id: subscribe[:offer_id]).to_a[0]

    subscribers_table.where(id: params["id"]).delete

    redirect "/offers/#{@offer[:id]}"
end

# display the signup form (aka "new")
get "/users/new" do
    view "new_user"
end

# receive the submitted signup form (aka "create")
post "/users/create" do
    puts "params: #{params}"

    # if there's already a user with this email, skip!
    existing_user = users_table.where(email: params["email"]).to_a[0]
    if existing_user
        view "error"
    else
        users_table.insert(
            name: params["name"],
            email: params["email"],
            phone: params["phone"],
            city: params["city"],
            password: BCrypt::Password.create(params["password"])
        )

        redirect "/logins/new"
    end
end

# display the login form (aka "new")
get "/logins/new" do
    view "new_login"
end

# display the login form (aka "new")
get "/logins/new" do
    view "new_login"
end

# receive the submitted login form (aka "create")
post "/logins/create" do
    puts "params: #{params}"

    # step 1: user with the params["email"] ?
    @user = users_table.where(email: params["email"]).to_a[0]

    if @user
        # step 2: if @user, does the encrypted password match?
        if BCrypt::Password.new(@user[:password]) == params["password"]
            # set encrypted cookie for logged in user
            session["user_id"] = @user[:id]
            redirect "/"
        else
            view "create_login_failed"
        end
    else
        view "create_login_failed"
    end
end

# logout user
get "/logout" do
    # remove encrypted cookie for logged out user
    session["user_id"] = nil
    redirect "/logins/new"
end