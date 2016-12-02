class Seeder

  def self.seed!
    self.user
    self.os
    self.order
    self.container
  end

  def self.user
    User.create(:username => "Admin",:password => "admin", :created_at => Time.now)
  end

  def self.container
    Container.create(:name => "TestVM", :created => Time.now, :user_id => 1, :os_id => 1)
  end

  def self.os
    Os.create(:name => "TestOS", :created_at => Time.now, :desc => "This is an example OS")
    Os.create(:name => "Debian 8", :created_at => Time.now, :desc => "Debian 8 with gnome desktop")
  end

  def self.order
    Order.create(:order_date => Time.now, :user => User.first(:id => 1), :container_id => 1)
  end

end