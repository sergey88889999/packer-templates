#### DEBIAN 13.02 PRESEED - AUTOMATED BASE SYSTEM INSTALLATION ####

### Localization (Installer in English, System in English, but Russian locale will also be available)
d-i debian-installer/locale string en_US.UTF-8
d-i debian-installer/language string en
d-i debian-installer/country string DE
d-i localechooser/supported-locales multiselect en_US.UTF-8, ru_RU.UTF-8

# Keyboard - US primary, RU secondary
d-i console-setup/ask_detect boolean false
d-i keyboard-configuration/xkb-keymap select us
d-i keyboard-configuration/layoutcode string us,ru
d-i keyboard-configuration/variantcode string ,
d-i keyboard-configuration/toggle select alt_shift_toggle
d-i keyboard-configuration/model select pc105

### Network
d-i netcfg/choose_interface select auto
d-i netcfg/get_hostname string debian13
d-i netcfg/get_domain string localdomain
d-i netcfg/wireless_wep string
d-i netcfg/dhcp_timeout string 60

### Repository Mirror
d-i mirror/country string manual
d-i mirror/http/hostname string deb.debian.org
d-i mirror/http/directory string /debian
d-i mirror/http/proxy string

### User Accounts
# Allow root login
d-i passwd/root-login boolean true

# DISABLE creation of a regular user
d-i passwd/make-user boolean false

# Root password (from secrets.auto.pkrvars.hcl)
d-i passwd/root-password password ${root_password}
d-i passwd/root-password-again password ${root_password}

### Timezone
d-i clock-setup/utc boolean true
d-i time/zone string Europe/Berlin
d-i clock-setup/ntp boolean true

### Disk Partitioning (UEFI, GPT, LVM)
##############################################
d-i partman-auto/method string lvm
d-i partman-lvm/device_remove_lvm boolean true
d-i partman-md/device_remove_md boolean true
d-i partman-lvm/confirm boolean true
d-i partman-lvm/confirm_nooverwrite boolean true

# GPT
d-i partman-basicfilesystems/choose_label string gpt
d-i partman-partitioning/choose_label string gpt

d-i partman-auto/choose_recipe select boot-root
d-i partman-auto-lvm/new_vg_name string vg_system

# Custom partitioning recipe using LVM and GPT
d-i partman-auto/expert_recipe string                         \
      boot-root ::                                            \
              512 512 512 fat32                               \
                      $iflabel{ gpt }                         \
                      $primary{ }                             \
                      method{ efi } format{ }                 \
                      mountpoint{ /boot/efi }                 \
              .                                               \
              512 512 512 ext4                                \
                      $primary{ }                             \
                      method{ format } format{ }              \
                      use_filesystem{ } filesystem{ ext4 }    \
                      mountpoint{ /boot }                     \
              .                                               \
              100 1000 -1 lvm                                 \
                      $primary{ }                             \
                      method{ lvm }                           \
                      device{ /dev/sda }                      \
                      vg_name{ vg_system }                    \
              .                                               \
              2048 10000 -1 ext4                              \
                      $lvmok{ }                               \
                      in_vg{ vg_system }                      \
                      lv_name{ root }                         \
                      method{ format } format{ }              \
                      use_filesystem{ } filesystem{ ext4 }    \
                      mountpoint{ / }                         \
              .

# Swap off
d-i partman-basicfilesystems/no_swap boolean false
d-i partman-noswap/confirm boolean true

# Automate confirmation of partition tables and write changes to disk
d-i partman/confirm_write_new_label boolean true
d-i partman/choose_partition select finish
d-i partman/confirm boolean true
d-i partman/confirm_nooverwrite boolean true

### Base System Installation
d-i base-installer/install-recommends boolean true
d-i base-installer/kernel/image string linux-image-amd64

### Package Selection
tasksel tasksel/first multiselect standard, ssh-server
d-i pkgsel/include string locales qemu-guest-agent cloud-init
d-i pkgsel/upgrade select full-upgrade

# Participate in the package popularity contest
popularity-contest popularity-contest/participate boolean false

### GRUB bootloader configuration for UEFI
d-i grub-installer/only_debian boolean true
d-i grub-installer/with_other_os boolean false
# Убираем /dev/sda, для UEFI это критично!
d-i grub-installer/bootdev string default

### Finalizing the installation
d-i finish-install/reboot_in_progress note
d-i debian-installer/exit/poweroff boolean false

### Late commands - configure SSH and locale
d-i preseed/late_command string \
    in-target sed -i 's/^#PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config; \
    in-target sed -i 's/^PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config; \
    in-target systemctl enable ssh; \
    in-target systemctl enable qemu-guest-agent; \
    in-target update-locale LANG=en_US.UTF-8 LC_MESSAGES=en_US.UTF-8
