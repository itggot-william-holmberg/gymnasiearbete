class Container
  include DataMapper::Resource

  property :id,         Serial
  property :name,       String
  property :created_at, DateTime

  belongs_to :user
  belongs_to :os
  has 1, :order


end