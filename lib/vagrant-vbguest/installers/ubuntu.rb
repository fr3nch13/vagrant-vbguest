module VagrantVbguest
  module Installers
    class Ubuntu < Debian

      def self.match?(vm)
        :ubuntu == self.distro(vm)
      end

      def install(opts=nil, &block)
        if packaged_additions?
          unload_packaged_additions(opts, &block)
          begin
            remove_packaged_additions(opts, &block)
          rescue
            communicate.sudo('apt-get update', opts, &block)
            remove_packaged_additions(opts, &block)
          end
        end
        super
      end

    protected

      def packaged_additions?
        communicate.test("dpkg --list virtualbox-guest* | grep ^ii")
      end

      def remove_packaged_additions(opts=nil, &block)
        options = (opts || {}).merge(:error_check => false)
        command = "apt-get -y -q purge virtualbox-guest-*"
        communicate.sudo(command, options, &block)
      end

      def unload_packaged_additions(opts=nil, &block)
        commands = [
          "#{systemd_tool[:path]} virtualbox-guest-utils #{systemd_tool[:down]}",
          "umount -a -t vboxsf",
          "rmmod vboxsf",
          "rmmod vboxguest"
        ]
        command = "(" + commands.join("; sleep 1; ") + ")"
        options = (opts || {}).merge(:error_check => false)
        communicate.sudo(command, options, &block)
      end

    end
  end
end
VagrantVbguest::Installer.register(:ubuntu, VagrantVbguest::Installers::Ubuntu, 5)
