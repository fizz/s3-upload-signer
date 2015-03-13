require 'sinatra'
require 'json'

get '/sign' do
  content_type :json
  {:hello => ['world']}.to_json
end


