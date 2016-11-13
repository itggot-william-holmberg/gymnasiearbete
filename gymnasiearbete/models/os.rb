class Os
  include DataMapper::Resource

  property :id,         Serial
  property :name,       String
  property :created_at, DateTime
  property :desc,       String

  has n, :containers
end