# Ansible role to customize servers

An ansible role to customize your servers after a fresh install

## Role Variables

* `hosts_ssh_users` - A list of github usernames. We will fetch ssh keys from their github account and add it to the authorized_keys of the ansible user.

``` yaml
# a list of github usernames to get public keys
hosts_ssh_users: []
```

* `hosts_auto` - Run user specific functions on ssh connection. This allow a user to customize his session when connecting to the server, like attaching automaticaly a screen session for example.

``` yaml
# allow to load functions at user connection
hosts_auto: false
```

* `hosts_auto_stuffs` - List of user specific functions to run on ssh connection. Here you can add any function to be called when you connect to the host. Current functions are defined in the /etc/profile.d/functions.sh file.

``` yaml
# list of functions to call at user connection
# hosts_auto_stuffs:
#   when the user connect with ssh, create and/or attach a screen session
#   - { "name": "attach_screen"; "state": "touch" }
```

* `hosts_etc_bashrc` - The location of the /etc/bashrc file on the current distro

``` yaml
# location of /etc/bashrc
hosts_etc_bashrc: /etc/bashrc
```

* `hosts_packages` - A list of packages to install on your servers. This list should be overrided for a specific distro.

``` yaml
# packages specific to a distribution
hosts_packages: []
```

* `hosts_packages_common` - A common list of packages to install on your servers. This list should be common to all distros.

``` yaml
# packages common to all distributions
hosts_packages_common:
  - { "name": "bash", "state": "present" }
  - { "name": "ca-certificates", "state": "present" }
  - { "name": "rsync", "state": "present" }
  - { "name": "screen", "state": "present" }
  - { "name": "tzdata", "state": "present" }
```

## Example

To launch this role on your `hosts` servers, run the default playbook.

``` bash
$ ansible-playbook playbook.yml
```

It will install the following packages : bash, ca-certificates, rsync, screen, tzdata and vim (plus libselinux-python on redhat).

## Common configurations

This example configuration will add the [ssh keys from aya's github user](https://github.com/aya.keys) to your remote ~/.ssh/authorized_keys.
It will create a ~/.rc.d and touch custom_ps1 and attach_screen files into this directory, resulting in a customized PS1 and automaticaly attaching a screen on (re)connection on the remote server.

``` yaml
hosts_ssh_users:
  - aya
hosts_auto: true
hosts_auto_stuffs:
  - { "name": "custom_ps1", "state": "touch" }
  - { "name": "attach_screen", "state": "touch" }
```

## Tests

To test this role on your `hosts` servers, run the tests/playbook.yml playbook.

``` bash
$ ansible-playbook tests/playbook.yml
```

## Authors

* **Yann Autissier** - *Initial work* - [aya](https://github.com/aya)

## License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details

