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

# break

# display the signup form (aka "new")
get "/users/new" do
    view "new_user"
end