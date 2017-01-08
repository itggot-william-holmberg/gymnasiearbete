require 'libvirt'
require 'rack-flash'
class App < Sinatra::Base
  enable :sessions
  use Rack::Flash

  get '/' do
  	redirect '/mypanel'
  end

  get '/login' do
    @user = User.get(session[:user]) if session[:user]
    if @user
      redirect '/mypanel'
    else
      slim :login
    end
  end


  get '/mypanel' do
    @user = User.get(session[:user]) if session[:user]
    if !@user
      redirect '/login'
    end
    @orders = Order.all(:user => @user) if !@user.nil?
    @containers = Container.all(:user => @user) if !@user.nil?
    if @user.mypanel_theme == 1
      slim :mypanel1
    elsif @user.mypanel_theme == 2
      slim :mypanel2
    else
      slim :mypanel2
    end
  end

  get '/orders' do
    @user = User.get(session[:user]) if session[:user]
    if !@user
      redirect '/login'
    end
    @orders = Order.all(:user => @user) if !@user.nil?
    @containers = Container.all(:user => @user) if !@user.nil?
    slim :orders
  end

  get '/order/create' do
    @user = User.get(session[:user]) if session[:user]
    if !@user.nil?
      @os = Os.all
      slim :order
    else
      flash[:failed_login] = "You need to sign in for access to this page."
      slim :login
    end
  end





  post '/order/create' do
    hypervisor = Hypervisor.new
    conn = Hypervisor.get_connection
    @user = User.get(session[:user]) if session[:user]
    if !conn.nil?
      if !@user.nil?
        vm_name = params[:vm_name]
        os_id = params[:os_id]
        memory = get_memory(params[:memory])
        begin
          if !hypervisor.get_connection.lookup_domain_by_name(vm_name).nil?
            flash[:warning_flash] = "Cannot create VM. Please try a different name"
            redirect back
            return
          end
        rescue

        end
        begin
          if !Container.first(:name => vm_name).nil?
            flash[:warning_flash] = "Cannot create container. Please try a different name"
            redirect back
            return
          end
        rescue
          flash[:warning_flash] = "Cannot create container. Please try a different name"
          redirect back
        end
        container = hypervisor.new_virtual_machine(conn, vm_name.upcase, "DEBIAN", memory)
        if !container.nil?
          @new_container = Container.create(:name => vm_name.upcase, :time_created => Time.now, :user_id => @user.id, :os_id => os_id, :active => true, :ip => "127.0.0.1", :running => true)

          if !new_container.nil?
            new_order = Order.create(:order_date => Time.now, :user => @user, :container_id => new_container.id)
          else
            flash[:warning_flash] = "Cannot create container. Please try again"
            redirect back
          end

          if !new_order.nil?
            flash[:successfully_flash] = "Container was succesfully created."
            redirect back
          else
            flash[:warning_flash] = "Cannot create container. Please try again"
            redirect back
          end
        else
          flash[:warning_flash] = "Cannot create container. Please try again"
          redirect back
        end
      else
        flash[:warning_flash] = "Cannot create VM. There is something wrong with the host"
        redirect back
      end
    else
      if !@user.nil? #hela den här sektionen är till för att kunna skapa databasen utan att faktiskt ha igång servenr, väldigt smidigt när jag arbetar på laptopen.
        vm_name = params[:vm_name]
        os_id = params[:os_id]
        memory = get_memory(params[:memory])
        cpu = params[:cpu]
        disk_size = params[:disk_size]


        if !Container.first(:name => vm_name).nil?
          flash[:warning_flash] = "Cannot create container. Please try a different name"
          redirect back
        end

        new_container = Container.create(:name => vm_name.upcase, :time_created => Time.now, :user_id => @user.id, :os_id => os_id, :memory => memory, :cpu => cpu, :disk_size => disk_size, :active => true, :ip => "127.0.0.1", :running => true)

        if !new_container.nil?
          new_order = Order.create(:order_date => Time.now, :user => @user, :container_id => new_container.id)
        else
          flash[:warning_flash] = "Cannot create container, something is wrong with container. Please try again"
          redirect back
        end

        if !new_order.nil?
          flash[:successfully_flash] = "Container was succesfully created."
          redirect back
        else
          flash[:warning_flash] = "Cannot create container, something is wrong with order. Please try again"
          redirect back
        end
      flash[:warning_flash] = "Cannot create real container. Host is probably offline. Created DB object for you"
      redirect back
      end
      flash[:warning_flash] = "You do not have access to this page"
      redirect back
      end
  end

  get '/container/:vm/edit' do |vm|
    @user = User.get(session[:user]) if session[:user]
    if !@user.nil?
      @db_container = Container.first(:user_id => @user.id, :name => vm)
      if !@db_container.nil?
      slim :editcontainer
      end
    else
      flash[:failed_login] = "You need to sign in for access to this page."
      slim :login
    end
  end

  post'/container/:vm/edit' do |vm|
    @user = User.get(session[:user]) if session[:user]
    if !@user.nil?
      db_container = Container.first(:user_id => @user.id, :name => vm)
      if !db_container.nil?
        memory = get_memory(params[:memory])
        cpu = params[:cpu]
        db_container.update(:cpu => cpu, :memory => memory)
        flash[:successfully_flash] = "You successfully updated your container."
        redirect "/container/#{vm}"
      else
        flash[:warning_flash] = "You do not have access to this page"
        redirect 'back'
      end
    else
      flash[:warning_flash] = "Please login."
      redirect '/login'
    end
  end

  get '/vnc' do
    slim :vncviewer
  end

  post '/login' do
    @user = User.first(:username => params[:username])
    if @user.nil? || @user.password != params[:password]
      @user = nil
      session[:user] = nil
      flash[:warning_flash] = "Wrong username or password."
    else
      session[:user] = @user.id
      flash[:successfully_flash] = "You successfully logged in."
    end
    redirect back
  end

  post '/register' do
    @user = User.first(:username => params[:username])
    if @user.nil?
      if User.create(:username => params[:username],:password => params[:password], :created_at => Time.now)
        flash[:successfully_flash] = "You successfully created your account!"
      else
        flash[:warning_flash] = "Something went wrong when creating your account"
      end
    else
      flash[:successfully_flash] = "That name is already taken"
    end
    redirect '/login'
  end

  get '/logout' do
    @user = User.get(session[:user]) if session[:user]
    if !@user.nil?
      @user = nil
      session[:user] = nil
      flash[:successfully_flash] = "You successfully logged out."
    else
      @user = nil
      session[:user] = nil
      flash[:warning_flash] ="You are already logged out."
    end
    redirect '/login'
  end

  get '/container/:vm' do |vm|
    @user = User.get(session[:user]) if session[:user]
    if !@user
      redirect '/login'
    else
      @db_container = Container.first(:user_id => @user.id, :name => vm)
      if !@db_container.nil?
        @conn = Hypervisor.new.get_connection
        begin
          @real_container = @conn.lookup_domain_by_name(vm)
        rescue
          @real_container = nil
        end
        slim :container
      else
        flash[:warning_flash] = "You do not have access to this domain."
        redirect back
        end
      end
  end


  get '/container/:vm/start' do |vm|
    @user = User.get(session[:user]) if session[:user]
    if !@user.nil?
      db_container = Container.first(:name => vm, :user => @user)
      if !db_container.nil?
        db_container.update(:running => true)
        @conn = Hypervisor.new.get_connection
        begin
          @container = @conn.lookup_domain_by_name(vm)
        rescue
          @container = nil
        end

        if !@container.nil? && @container.active?
          @container.create
          flash[:successfully_flash] = "The virtual machine was sucessfully turned on"
          redirect back
        else
          flash[:warning_flash] = "Could not start the virtual machine. The host-server may be offline!"
          redirect back
        end
      end
    end
    flash[:warning_flash] = "You do not have access to this page."
    redirect back
  end

  get '/container/:vm/shutoff' do |vm|
    @user = User.get(session[:user]) if session[:user]
    if !@user.nil?
    db_container = Container.first(:name => vm, :user => @user)
      if !db_container.nil?
        db_container.update(:running => false)
        @conn = Hypervisor.new.get_connection
        begin
          @container = @conn.lookup_domain_by_name(vm)
        rescue
          @container = nil
        end

        if !@container.nil? && @container.active?
          @container.destroy
          flash[:successfully_flash] = "VM was sucessfully turned off"
          redirect back
        else
          flash[:warning_flash] = "Could not shutoff the virtual machine. The host-server may be offline!"
          redirect back
        end
      end
    end
    flash[:warning_flash] = "You do not have access to this page."
    redirect back
  end

  get '/container/:vm/delete' do |vm|
    @user = User.get(session[:user]) if session[:user]
    db_container = Container.first(:name => vm, :user => @user)
    if !db_container.nil?
      db_container.update(:active => false, :time_deleted => Time.now)
      real_container = Hypervisor.new.get_connection
      if !real_container.nil?
        begin
          container = real_container.lookup_domain_by_name(vm)
        rescue
          container = nil
        end

        if !container.nil?
          begin
            container.undefine(1)
            container.destroy
          rescue


          end
          flash[:successfully_flash] = "Container was sucessfully deleted"
          redirect '/'
        else
          flash[:warning_flash] = "Could not delete the virtual machine. Either you lack access or the domain does not exist."
          redirect back
        end
      else
        flash[:successfully_flash] = "Host is not available but database container has been deleted."
        redirect back
      end
    else
      flash[:warning_flash] = "You dont have access to this container"

    end
  end

  get '/settings' do
    @user = User.get(session[:user]) if session[:user]
    if @user
      slim :settings
    else
      slim :login
    end
  end

  post '/settings/update/theme' do
    @user = User.get(session[:user]) if session[:user]
    if @user
      @user.update(:mypanel_theme => params[:mypanel_theme])
      flash[:successfully_flash] = "You successfully updated your profile"
    end
    redirect back
  end

  post '/settings/update/password' do
    @user = User.get(session[:user]) if session[:user]
    if @user && @user.password == params[:current_password]
      @user.update(:password => params[:new_password])
      flash[:successfully_flash] = "You successfully changed password"
    else
      flash[:warning_flash] = "Wrong password. Please try agian."
    end
    redirect back
  end



  def get_memory(memory)
    if memory == "256"
      return "256000"
    elsif memory == "512"
      return "512000"
    elsif memory == "1024"
      return "1024000"
    elsif memory == "2048"
      return "2048048"
    end
    return "100000"
  end


end

