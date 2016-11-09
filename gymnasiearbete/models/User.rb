class User
  include DataMapper::Resource

  property :id,         Serial
  property :username,   String
  property :password,   BCryptHash
  property :created_at, DateTime
end