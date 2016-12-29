class User
  include DataMapper::Resource

  property :id,            Serial
  property :username,      String
  property :password,      BCryptHash
  property :created_at,    DateTime
  property :mypanel_theme, Integer, :default => 2
  has n, :containers
end