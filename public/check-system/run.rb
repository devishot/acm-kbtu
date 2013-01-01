#require 'rubygems'
#require 'mongo'
#include Mongo
require 'moped'

session = Moped::Session.new(["127.0.0.1:27017"])
session.use :acm_kbtu_development


submits = session[:submits].find
puts "There are #{submits.count} records. Here they are:"
submits.find.each { |submit| 
  puts submit.inspect
}
