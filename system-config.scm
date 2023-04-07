(use-modules (gnu)
             (guix)
             (guix download)
             (nongnu packages linux)
             (nongnu system linux-initrd))

(use-service-modules networking ssh)

(use-package-modules certs
                     screen
                     ssh
                     tmux
                     vim
                     wget
		     disk
		     version-control)

(operating-system
  (host-name "guix-aarch64")
  (timezone "America/Los_Angeles")
  (locale "en_US.utf8")

  ;; Use non-free Linux and firmware
  ;;(kernel linux)
  ;;(firmware (list linux-firmware))
  ;;(initrd microcode-initrd)

  (bootloader (bootloader-configuration
                (bootloader grub-efi-bootloader)
                (targets '("/boot/efi"))
                (terminal-outputs '(console))))

  ;; 6598-99C8
  (file-systems (append (list (file-system
				(mount-point "/")
				(device (uuid "38af4c98-4cf3-22f4-ad36-132e38af4c98"))
                        	(type "ext4"))
			      (file-system
				(device (uuid "6598-99C8" 'fat))
				(mount-point "/boot/efi")
				(type "vfat")))
		      	%base-file-systems))

  ;; This is where user accounts are specified.  The "root"
  ;; account is implicit, and is initially created with the
  ;; empty password.
  (users (cons (user-account
                (name "handolpark")
                ;; https://www.gnu.org/software/libc/manual/html_node/Passphrase-Storage.html#Passphrase-Storage
                ;; (password (crypt "changeme" "$6$fakesalt"))
                (group "users")

                ;; Adding the account to the "wheel" group
                ;; makes it a sudoer.  Adding it to "audio"
                ;; and "video" allows the user to play sound
                ;; and access the webcam.
                (supplementary-groups
                 '("wheel"
				   "audio" "video")))
               %base-user-accounts))

  (sudoers-file (plain-file "sudoers"
                            "root ALL=(ALL) ALL\n%wheel ALL=NOPASSWD: ALL\n"))

  ;; Globally-installed packages.
  (packages (append (list
                     tmux nss-certs vim wget
		     parted git)
		    %base-packages))

  ;; Add services to the baseline: a DHCP client and
  ;; an SSH server.
  (services
   (append (list (service dhcp-client-service-type)
                 (service openssh-service-type
                          (openssh-configuration
			   (openssh openssh-sans-x)
               (port-number 22)
               (password-authentication? #f)
               (authorized-keys
			    `(("handolpark" ,(local-file "handolpark.pub")))))))
	   %base-services))

  (name-service-switch %mdns-host-lookup-nss))

