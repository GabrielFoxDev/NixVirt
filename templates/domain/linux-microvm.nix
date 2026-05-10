stuff@{ packages, ... }:
{ name
, uuid
, vcpu ? { count = 2; }
, memory ? { count = 2; unit = "GiB"; }
, kernel
, initrd ? null
, cmdline ? null
, storage_vol ? null
, backing_vol ? null
, bridge_name ? "virbr0"
, net_iface_mac ? null
, ...
}:
let
  base = import ./base.nix stuff;
  inherit (base) mkstorage;
in
{
  type = "kvm";
  inherit name uuid vcpu memory;

  os =
    {
      type = "hvm";
      arch = "x86_64";
      machine = "microvm";
      kernel = { path = builtins.toString kernel; };
      initrd = if builtins.isNull initrd then null else { path = builtins.toString initrd; };
      cmdline = if builtins.isNull cmdline then null else { options = cmdline; };
    };
  features =
    {
      apic = { };
    };
  cpu = { mode = "host-passthrough"; };
  clock =
    {
      offset = "utc";
      timer =
        [
          { name = "rtc"; tickpolicy = "catchup"; }
          { name = "pit"; tickpolicy = "delay"; }
          { name = "hpet"; present = false; }
        ];
    };
  devices =
    {
      emulator = "${packages.qemu}/bin/qemu-system-x86_64";
      disk =
        (if builtins.isNull storage_vol then [ ] else [ (mkstorage true storage_vol backing_vol) ]);
      interface =
        {
          type = "bridge";
          model = { type = "virtio"; };
          mac = if builtins.isNull net_iface_mac then null else { address = net_iface_mac; };
          source = { bridge = bridge_name; };
        };
      serial = { type = "pty"; };
      console = { type = "pty"; target = { type = "serial"; }; };
      rng =
        {
          model = "virtio";
          backend = { model = "random"; source = /dev/urandom; };
        };
    };
}