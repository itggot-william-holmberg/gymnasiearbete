require 'libvirt'
require 'rack-flash'
class App < Sinatra::Base
  enable :sessions
  use Rack::Flash

  get '/' do
    #only give @conn to user who has access.
    @conn = Test.new.get_connection
  	slim :index
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
    slim :mypanel
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

  get '/container/create' do
    @user = User.get(session[:user]) if session[:user]
    if !@user.nil?
      @os = Os.all
      slim :order
    else
      flash[:failed_login] = "You need to sign in for access to this page."
      slim :login
    end
  end



  post '/container/create' do
    test = Test.new
    conn = test.get_connection
    @user = User.get(session[:user]) if session[:user]
    if !conn.nil?
      if !@user.nil?
        vm_name = params[:vm_name]
        os_id = params[:os_id]
        memory = get_memory(params[:memory])
        begin
          if !test.get_connection.lookup_domain_by_name(vm_name).nil?
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
        container = test.new_virtual_machine(conn, vm_name, "DEBIAN", memory)
        if !container.nil?
          @new_container = Container.create(:name => vm_name, :time_created => Time.now, :user_id => @user.id, :os_id => os_id, :active => true)

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

        if !Container.first(:name => vm_name).nil?
          flash[:warning_flash] = "Cannot create container. Please try a different name"
          redirect back
        end

        new_container = Container.create(:name => vm_name, :time_created => Time.now, :user_id => @user.id, :os_id => os_id, :memory => memory, :cpu => "1", :active => true)

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
        @conn = Test.new.get_connection
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
    @conn = Test.new.get_connection
    begin
      @container = @conn.lookup_domain_by_name(vm)
    rescue
      @container = nil
    end

    if !@container.nil? && !@container.active?
      @container.create
      flash[:successfully_flash] = "VM was sucessfully turned on"
      redirect back
    else
      flash[:warning_flash] = "Could not start the virtual machine. Either you lack access or the domain is already turned on."
      redirect back
    end
  end

  get '/container/:vm/shutoff' do |vm|
    @conn = Test.new.get_connection
    begin
      @container = @conn.lookup_domain_by_name(vm)
    rescue
      @container = nil
    end

    if !@container.nil? && @container.active?
      @container.destroy
      flash[:warning_flash] = "VM was sucessfully turned off"
      redirect back
    else
      flash[:warning_flash] = "Could not shutoff the virtual machine. Either you lack access or the domain is already turned off."
      redirect back
    end
  end

  get '/container/:vm/delete' do |vm|
    @user = User.get(session[:user]) if session[:user]
    db_container = Container.first(:name => vm, :user => @user)
    if !db_container.nil?
      db_container.update(:active => false, :time_deleted => Time.now)
      real_container = Test.new.get_connection
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

  def get_memory(memory)
    if memory == "1"
      return "256000"
    elsif memory == "2"
      return "512000"
    elsif memory == "3"
      return "1024000"
    elsif memory == "4"
      return "2048048"
    end
    return "100000"
  end


end

