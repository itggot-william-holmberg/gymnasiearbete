class User
  include DataMapper::Resource

  property :id,         Serial
  property :name,   String
  property :password,   BCryptHash
  property :created_at, DateTime

  has n, :containers
end