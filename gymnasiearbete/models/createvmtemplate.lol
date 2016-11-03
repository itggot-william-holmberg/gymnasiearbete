require 'libvirt'

GUEST_DISK = '/var/lib/libvirt/images/example2.qcow2'
# create the guest disk
`rm -f #{GUEST_DISK} ; qemu-img create -f qcow2 #{GUEST_DISK} 5G`

UUID = "93a5c045-6457-2c09-e5ff-927cdf34e17b"

# the XML that describes our guest; note that this is a KVM guest.  For
# additional information about the guest XML, please see the libvirt
# documentation
new_dom_xml = <<EOF
<domain type='kvm'>
  <name>ruby-libvirt-tester</name>
  <uuid>#{UUID}</uuid>
  <memory>1048576</memory>
  <currentMemory>1048576</currentMemory>
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
  <source file='/iso/debian8gnome.iso'/>
  <target dev='hdc' bus='ide'/>
  <readonly/>
  <address type='drive' controller='0' bus='1' unit='0'/>
    </disk>
    <disk type='file' device='disk'>
      <driver name='qemu' type='qcow2'/>
      <source file='#{GUEST_DISK}'/>
      <target dev='vda' bus='virtio'/>
    </disk>
    <interface type='bridge'>
      <mac address='52:54:01:60:3c:95'/>
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

puts "Connecting to libvirt"
conn = Libvirt::open('qemu:///system')

# define the domain from the XML above.  Note that defining a domain just
# makes libvirt aware of the domain as a persistent entity; it does not start
# or otherwise change the domain
puts "Defining permanent domain ruby-libvirt-tester"
dom = conn.define_domain_xml(new_dom_xml)

# start the domain
puts "Starting permanent domain ruby-libvirt-tester"
dom.create




sleep 2


conn.close
