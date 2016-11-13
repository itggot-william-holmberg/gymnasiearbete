class Order
  include DataMapper::Resource

  property :id,         Serial
  property :order_date, DateTime

  belongs_to :container
  belongs_to :user
end