class Container
  include DataMapper::Resource

  property :id,             Serial
  property :name,           String
  property :time_created,   Time
  property :disk_size,      String
  property :cpu,            String
  property :memory,         String
  property :active,         Boolean, :default => true     #med active menar jag om den "finns", alltså om användare betalar för servern.
  property :running,        Boolean, :default => true      #med running menar om den är på just nu, antingen är den avständ eller på.
  property :time_deleted,   Time
  property :ip,             String

  belongs_to :user
  belongs_to :os
  has 1, :order

  def hours_active
    if self.time_deleted.nil?
      foo = Time.now - self.time_created
    else
      foo = self.time_deleted - self.time_created
    end
    return (foo/3600).ceil
  end

  def check_real_cpu
    real_container = get_conn
    if !real_container.nil?
      real_cpu = real_container.num_vcpus(0).to_s
      if !real_cpu.nil?
        self.cpu = real_cpu
        return real_cpu
      end
    end
    return self.cpu
  end

  def check_real_memory
    real_container = get_conn
    if !real_container.nil? && real_container.active?
      real_memory = real_container.max_memory.to_s
      if !real_memory.nil?
        self.memory = real_memory
        return real_memory
      end
    end
    return self.memory
  end

  def check_real_running
    real_container = get_conn
    if !real_container.nil?
      real_running = real_container.active?
      if !real_running.nil?
        self.running = real_running
        return real_running
      end
    end
    return self.running
  end

  def get_conn
    begin
      real_container = Test.new.get_connection.lookup_domain_by_name(self.name)
    rescue
      real_container = nil
    end
    return real_container
  end



end