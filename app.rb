require 'sinatra'
require 'json'
require 'openssl'
require 'base64'
require 'active_support/core_ext/numeric/time'
require 'sinatra/cross_origin'

configure do
  enable :cross_origin
end

get '/sign' do
  @expires = 10.hours.from_now
  @bucket = ENV['AWS_BUCKET']
  content_type :json
  {
    acl: 'public-read',
    awsaccesskeyid: ENV['AWS_ACCESS_KEY_ID'],
    bucket: @bucket,
    expires: @expires,
    key: "uploads/#{params[:name]}",
    policy: policy,
    signature: signature,
    success_action_status: '201',
    'Content-Type' => params[:type],
    'Cache-Control' => 'max-age=630720000, public'
  }.to_json
end

def signature
  Base64.strict_encode64(
    OpenSSL::HMAC.digest(
      OpenSSL::Digest::Digest.new('sha1'),
      ENV['AWS_SECRET_ACCESS_KEY'],
      policy({ secret_access_key: ENV['AWS_SECRET_ACCESS_KEY'] })
    )
  )
end

def policy(options={})
  Base64.strict_encode64(
    {
      expiration: @expires,
      conditions: [
        { bucket:  @bucket },
        { acl: 'public-read' },
        { expires: @expires },
        { success_action_status: '201' },
        [ 'starts-with', '$key', '' ],
        [ 'starts-with', '$Content-Type', '' ],
        [ 'starts-with', '$Cache-Control', '' ],
        [ 'content-length-range', 0, 524288000 ]
      ]
    }.to_json
  )
end
