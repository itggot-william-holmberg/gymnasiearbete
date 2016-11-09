class Seeder

  def self.seed!
    self.user
  end

  def self.user
    User.create(:username => "Admin",:password => "admin", :created_at => Time.now)
  end

end