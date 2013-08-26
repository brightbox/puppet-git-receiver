# Puppet Git Receiver

puppet-git-receiver is a script that handles validating and applying
puppet manifests that are pushed to a git repository.

When installed as a git update hook, it validates any file with the
suffix .pp. If no validation errors are detected, then it runs `puppet
apply` using the manifest `manifests/site.pp`.

It uses the path `modules/` in your repository as the puppet modules
path.

It only considers the master branch, ignoring all other branches. If
the validation or the apply return any errors, the update is rejected
(i.e: the master head is not updated).

    git push srv-30qvg.gb1.brightbox.com
    
    Counting objects: 7, done.
    Delta compression using up to 2 threads.
    Compressing objects: 100% (2/2), done.
    Writing objects: 100% (4/4), 346 bytes, done.
    Total 4 (delta 0), reused 0 (delta 0)
    remote: *** Validating puppet manifests for refs/heads/master
    remote: *** Applying puppet manifests
    remote: notice: /Stage[main]//Package[cowsay]/ensure: ensure changed 'purged' to 'present'
    remote: notice: Finished catalog run in 3.18 seconds
    remote: *** Puppet manifests applied successfully
    To puppet-git@ipv6.srv-30qvg.gb1.brightbox.com:puppet.git
       3ffd7b7..49072b1  master -> master

## Deployment

### Ubuntu deployment

The source includes recipes to build Ubuntu packages which creates a
user named `puppet-git`, with a pre-configured git repository named
`puppet.git` in its home directory (and appropriate sudo privileges).

Pre-built packages for Ubuntu precise are available in the
[Brightbox launchpad ppa](https://launchpad.net/~brightbox/+archive/puppet).

    sudo apt-add-repository ppa:brightbox/puppet
    sudo apt-get update
    sudo apt-get install puppet-git-receiver

Then set a password for the `puppet-git` user, or add your ssh keys to
its home directory `/var/lib/puppet-git-receiver`.

Then you can just add the git repository as a git remote and push to
get your manifests applied.

    git remote add myserver puppet-git@myserver.example.com:puppet.git
	git remote push myserver master

Alternatively, you can just use any user in the `admin` group with
full sudo privileges to access the repo too:

	git remote add myserver ubuntu@myserver.example.com:/var/lib/puppet-git-receiver/puppet.git
	git remote push myserver master

And for (slight) convenience, there is a symlink to the repository at
`/var/lib/puppet-git-receiver.git`:

	git remote add myserver ubuntu@myserver.example.com:/var/lib/puppet-git-receiver.git
	git remote push myserver master

### Ubuntu cloud-init deployment

If you're using an Ubuntu image with the `cloud-init` package
installed on a cloud platform that supports EC2-style user data (like
Amazon EC2 obviously, or [Brightbox Cloud](http://brightbox.com/), you
can script the installation on boot like this:

    #cloud-config
    apt_sources:
     - source: "ppa:brightbox/puppet"
    packages:
     - puppet-git-receiver
    runcmd:
    - cp -ar /home/ubuntu/.ssh /var/lib/puppet-git-receiver/
    - chown -R puppet-git.puppet-git /var/lib/puppet-git-receiver/.ssh

A version of this script is maintained as a Github gist at
https://gist.github.com/3129203 for convenience. You can use it with
a cloud-init `#include` statement, like this:

    $ brightbox-servers create --user-data="#include https://raw.github.com/gist/3129203/puppet-git-receiver-install" img-9h5cv
	
    Creating a nano server with image Ubuntu Precise 12.04 LTS server (img-9h5cv) with 0.10k of user data
    
     id         status    type  zone   created_on  image_id   cloud_ip_ids  name
    -----------------------------------------------------------------------------
     srv-3te8u  creating  nano  gb1-a  2012-07-17  img-9h5cv                    
    -----------------------------------------------------------------------------
	
When this boots, you can immediately push puppet manifests to it and
have them applied. Easy peasy!

### Manual deployment

If you'd prefer not to use the Ubuntu package, just install the script
in your git repository named `.git/hooks/update`. Ensure the user the
script will run as has permission to run `puppet` using sudo with
environment variables. Something like this in `sudoers` should do the
trick:

    puppet-git	ALL=NOPASSWD: SETENV:/usr/bin/puppet

You obviously need git and puppet installed, but also bash, sudo,
find, tar and xargs.

## Configuration

You can disable the full validation step by setting the git config
boolean option `puppet-receiver.skip-validation` to true on the remote
repository:

    git config --bool --add puppet-receiver.skip-validation true

You can set extra arguments passed to `puppet apply` by setting the
git config option `puppet-receiver.args` on the remote repository:

    git config --add puppet-receiver.args "--noop --debug"


## Puppet forge integration

puppet-git-receiver can download and install modules hosted on
[Puppet Forge](http://forge.puppetlabs.com/) prior to applying your
manifests.

Create a file in the root of your repository named
`.puppetforge-modules` and list each module you want installed, one
per line. You can optionally specify the exact module version you want
installed, putting the version number after the module name separated
by a space, otherwise the latest version is installed. Lines starting
with a `#` character and empty lines are ignored. Example:

    brightbox/apt
    brightbox/apache 1.0.0
	brightbox/nagios

The modules are installed on the server into a directory created in
the root named `puppetforge-modules` which is added to the puppet
`modulespath`. Your repository's own `modules/` directory takes
precedence.

Puppet version 2.7.12 is required for installing forge modules.

## Librarian-puppet integration

puppet-git-receiver can alternatively download and install modules using
librarian-puppet. If a `Puppetfile` is found in your repository and
librarian-puppet is installed the modules will be fetched before applying your
manifests.

Options to librarian-puppet can be supplied by setting the
`puppet-receiver.librarian-puppet-args` git config option on the remote
repository:

    git config --add puppet-receiver.librarian-puppet-args "--verbose"

## Yaml-based node classification

You can classify nodes using yaml files placed in the `manifests/`
directory.

`manifests/site.yml` is the default for all nodes, but you can create
files in `manifests/nodes/` with the fqdn of the node you want to
classify and that will be used instead (e.g:
`manifests/nodes/srv-abcde.gb1.brightbox.com.yml`).

The file needs to be formatted as per the puppet
[external node classification output format](http://docs.puppetlabs.com/guides/external_nodes.html#enc-output-format).

For example:

    classes:
      "apt":
      "apache":
      "apache::php":
      "apache::passenger":
        instances_per_app: 8
      "rsyslog":
        remote_servers:
          - "10.0.0.1"
          - "10.0.0.2"


## Code

The code is licensed under the terms of the GPLv3 and is available on
Github at https://github.com/brightbox/puppet-git-receiver

(c) Copyright 2012 John Leach <john@brightbox.co.uk>
