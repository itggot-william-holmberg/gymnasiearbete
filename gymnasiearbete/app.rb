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
    begin
      test.new_virtual_machine(params[:vm_name])
      flash[:vm_created] = "VM was successfully created"
    rescue Libvirt::DefinitionError
      flash[:vm_not_created] = "UUID already exists. Cannot create VM"
    end
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

end

