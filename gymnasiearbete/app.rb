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
    @orders = Order.all(:user => @user) if !@user.nil?
    @containers = Container.all(:user => @user) if !@user.nil?
    slim :login
  end

  get '/order' do
    @user = User.get(session[:user]) if session[:user]
    if !@user.nil?
      @os = Os.all
      slim :order
    else
      flash[:failed_login] = "You need to sign in for access to this page."
      slim :login
    end
  end



  post '/order/new' do
    @user = User.get(session[:user]) if session[:user]
    if !@user.nil?
      vm_name = params[:vm_name]
      os_id = params[:os_id]

      begin
        if !Container.first(:name => vm_name).nil?  # && if !test.get_connection.lookup_domain_by_name(vm_name).nil?
          flash[:container_not_created] = "Cannot create container. Please try a different name"
          redirect back
          return
        end
      rescue
        flash[:container_not_created] = "Cannot create container. Please try a different name"
        redirect back
      end

      @new_container = Container.create(:name => vm_name, :created_at => Time.now, :user_id => @user.id, :os_id => os_id)

      if !@new_container.nil?
        @new_order = Order.create(:order_date => Time.now, :user => @user, :container_id => @new_container.id)
      else
        flash[:container_not_created] = "Cannot create container. Please try again"
        redirect back
      end

      if !@new_order.nil?
        flash[:container_created] = "Container was succesfully created."
      else
        flash[:container_not_created] = "Cannot create container. Please try again"
        redirect back
      end
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
      flash[:failed_login] = "Wrong username or password."
    else
      session[:user] = @user.id
      flash[:successfull_login] = "You successfully logged in."
    end
    redirect back
  end

  get '/domain/:vm' do |vm|
    #only give @conn to user who has access.
    @conn = Test.new.get_connection
    begin
      @domain = @conn.lookup_domain_by_name(vm)
    rescue
      @domain = nil
    end
    slim :domain
  end

  post '/domain/new' do
    #only give @conn to user who has access.
    test = Test.new
    vm_name = params[:vm_name]
    os_type = params[:select_os]
      begin
        if !test.get_connection.lookup_domain_by_name(vm_name).nil?
          flash[:vm_not_created] = "Cannot create VM. Please try a different name"
          redirect back
          return
        end
      rescue

      end

     # begin
        test.new_virtual_machine(vm_name, os_type)
      #  flash[:vm_created] = "VM was successfully created"
      #rescue Libvirt::DefinitionError
      #  flash[:vm_not_created] = "UUID already exists. Cannot create VM"
      #end
    redirect back
  end

  get '/domain/:vm/start' do |vm|
    @conn = Test.new.get_connection
    begin
      @domain = @conn.lookup_domain_by_name(vm)
    rescue
      @domain = nil
    end

    if !@domain.nil? && !@domain.active?
      @domain.create
      flash[:vm_turned_on] = "VM was sucessfully turned on"
      redirect back
    else
      "Could not start the virtual machine. Either you lack access or the domain is already turned on."
    end
  end

  get '/domain/:vm/shutoff' do |vm|
    @conn = Test.new.get_connection
    begin
      @domain = @conn.lookup_domain_by_name(vm)
    rescue
      @domain = nil
    end

    if !@domain.nil? && @domain.active?
      @domain.destroy
      flash[:vm_turned_off] = "VM was sucessfully turned off"
      redirect back
    else
      "Could not shutoff the virtual machine. Either you lack access or the domain is already turned off."
    end
  end

  get '/domain/:vm/delete' do |vm|
    @conn = Test.new.get_connection
    begin
      @domain = @conn.lookup_domain_by_name(vm)
    rescue
      @domain = nil
    end

    if !@domain.nil?
      @domain.undefine(1)
      @domain.destroy
      flash[:vm_deleted] = "VM was sucessfully deleted"
      redirect '/'
    else
      "Could not delete the virtual machine. Either you lack access or the domain does not exist."
    end
  end




end

