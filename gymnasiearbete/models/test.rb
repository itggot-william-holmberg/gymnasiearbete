require 'libvirt'
class Test

  def get_connection
    begin
      conn = Libvirt::open("qemu:///system")
      return conn
    rescue
      return nil
    end
  end

  def new_virtual_machine(name, os)

    if os == "DEBIAN"
      conn = get_connection
      #@UUID = "95a5c047-6457-2c09-e5ff-927cdf34e17b"
      @MAX_MEMORY = "1048576"
      @MEMORY = "1048576"
      @INSTALLATION_IMAGE = "/iso/debian8gnome.iso"
      #@MAC_ADDRESS = '12:54:01:60:3c:95'
      #<mac address='#{@MAC_ADDRESS}'/>
      @GUEST_DISK = "/var/lib/libvirt/images/#{name}.qcow2"
      # create the guest disk
      `rm -f #{@GUEST_DISK} ; qemu-img create -f qcow2 #{@GUEST_DISK} 5G`
      #  <uuid>#{@UUID}</uuid>
      #Should be random generated in the future.
      new_dom_xml = <<EOF
<domain type='kvm'>
  <name>#{name}</name>
  <memory>#{@MAX_MEMORY}</memory>
  <currentMemory>#{@MEMORY}</currentMemory>
  <vcpu>1</vcpu>
  <os>
    <type arch='x86_64'>hvm</type>
    <boot dev='hd'/>
    <boot dev='cdrom'/>
  </os>
  <features>
    <acpi/>
    <apic/>
    <pae/>
  </features>
  <clock offset='utc'/>
  <on_poweroff>destroy</on_poweroff>
  <on_reboot>restart</on_reboot>
  <on_crash>restart</on_crash>
  <devices>
    <disk type='file' device='cdrom'>
  <driver name='qemu' type='raw'/>
  <source file='#{@INSTALLATION_IMAGE}'/>
  <target dev='hdc' bus='ide'/>
  <readonly/>
  <address type='drive' controller='0' bus='1' unit='0'/>
    </disk>
    <disk type='file' device='disk'>
      <driver name='qemu' type='qcow2'/>
      <source file='#{@GUEST_DISK}'/>
      <target dev='vda' bus='virtio'/>
    </disk>
    <interface type='bridge'>
      <source bridge='br0'/>
      <model type='rtl8139'/>
      <target dev='vnet0'/>
    </interface>
    <serial type='pty'>
      <target port='0'/>
    </serial>
    <console type='pty'>
      <target port='0'/>
    </console>
    <input type='mouse' bus='ps2'/>
    <graphics type='vnc' port='-1' autoport='yes' keymap='en-us'/>
    <video>
      <model type='cirrus' vram='9216' heads='1'/>
    </video>
  </devices>
</domain>
EOF

      # define the domain from the XML above.  Note that defining a domain just
      # makes libvirt aware of the domain as a persistent entity; it does not start
      # or otherwise change the domain
      puts "Defining permanent domain ruby-libvirt-tester"
      dom = conn.define_domain_xml(new_dom_xml)

      # start the domain
      puts "Starting permanent domain ruby-libvirt-tester"
      dom.create

    elsif os == "OSBOT_PREINSTALLED"

      conn = get_connection
      #@UUID = "95a5c047-6457-2c09-e5ff-927cdf34e17b"
      @MAX_MEMORY = "1048576"
      @MEMORY = "1048576"
      #@MAC_ADDRESS = '12:54:01:60:3c:95'
      #<mac address='#{@MAC_ADDRESS}'/>
      @PRE_INSTALLED_DISK = "/var/lib/libvirt/images/preinstall/OSBOT_PREINSTALLED.qcow2"
      @GUEST_DISK = "/var/lib/libvirt/images/#{name}.qcow2"
      # create the guest disk
      #`rm -f #{@GUEST_DISK} ; qemu-img create -f qcow2 #{@GUEST_DISK} 5G`
      FileUtils.cp(@PRE_INSTALLED_DISK,@GUEST_DISK)

      `cp -a #{@PRE_INSTALLED_DISK} #{@GUEST_DISK}`
      #  <uuid>#{@UUID}</uuid>
      #Should be random generated in the future.
      new_dom_xml = <<EOF
<domain type='kvm'>
  <name>#{name}</name>
  <memory>#{@MAX_MEMORY}</memory>
  <currentMemory>#{@MEMORY}</currentMemory>
  <vcpu>1</vcpu>
  <os>
    <type arch='x86_64'>hvm</type>
    <boot dev='hd'/>
    <boot dev='cdrom'/>
  </os>
  <features>
    <acpi/>
    <apic/>
    <pae/>
  </features>
  <clock offset='utc'/>
  <on_poweroff>destroy</on_poweroff>
  <on_reboot>restart</on_reboot>
  <on_crash>restart</on_crash>
  <devices>
    <disk type='file' device='disk'>
      <driver name='qemu' type='qcow2'/>
      <source file='#{@GUEST_DISK}'/>
      <target dev='vda' bus='virtio'/>
    </disk>
    <interface type='bridge'>
      <source bridge='br0'/>
      <model type='rtl8139'/>
      <target dev='vnet0'/>
    </interface>
    <serial type='pty'>
      <target port='0'/>
    </serial>
    <console type='pty'>
      <target port='0'/>
    </console>
    <input type='mouse' bus='ps2'/>
    <graphics type='vnc' port='-1' autoport='yes' keymap='en-us'/>
    <video>
      <model type='cirrus' vram='9216' heads='1'/>
    </video>
  </devices>
</domain>
EOF

      # define the domain from the XML above.  Note that defining a domain just
      # makes libvirt aware of the domain as a persistent entity; it does not start
      # or otherwise change the domain
      puts "Defining permanent domain ruby-libvirt-tester"
      dom = conn.define_domain_xml(new_dom_xml)

      # start the domain
      puts "Starting permanent domain ruby-libvirt-tester"
      dom.create
    end

  end


end

