# Set up for the application and database. DO NOT CHANGE. #############################
require "sequel"                                                                      #
connection_string = ENV['DATABASE_URL'] || "sqlite://#{Dir.pwd}/development.sqlite3"  #
DB = Sequel.connect(connection_string)                                                #
#######################################################################################

# Database schema - this should reflect your domain model

# New domain model - adds users
DB.create_table! :offers do
  primary_key :id
  String :name
  String :description, text: true
  String :date
  String :location
end
DB.create_table! :subscribers do
  primary_key :id
  foreign_key :offer_id
  foreign_key :user_id
  Boolean :interested
  String :comments, text: true
end
DB.create_table! :users do
  primary_key :id
  String :name
  String :email
  String :phone
  String :city
  String :password
end

# Insert initial (seed) data
offers_table = DB.from(:offers)

offers_table.insert(name: "Chicago Green Electricity", 
                    description: "Full green renewable electricity guaranteed by our supplier to work towards a sustainable future",
                    date: "April 20",
                    location: "Chicago")

offers_table.insert(name: "San Francisco Wind/Solar Electricity", 
                    description: "Use that SF wind & solar in your benefit!",
                    date: "June 1",
                    location: "San Francisco")

offers_table.insert(name: "New York full renewable energy", 
                    description: "Make those Wall Street profits while working towards a sustainable future",
                    date: "June 19",
                    location: "New York City")
                    
puts "Success!"