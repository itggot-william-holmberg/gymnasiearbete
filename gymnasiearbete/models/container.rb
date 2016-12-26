class Container
  include DataMapper::Resource

  property :id,             Serial
  property :name,           String
  property :time_created,   Time
  property :disk_size,      String
  property :cpu,            String
  property :memory,         String
  property :active,         Boolean
  property :time_deleted,   Time

  belongs_to :user
  belongs_to :os
  has 1, :order

  def hours_active(time_created, time_deleted)
    if time_deleted.nil?
      foo = Time.now - time_created
    else
      foo = time_deleted - time_created
    end
    return (foo/3600).ceil
  end

end