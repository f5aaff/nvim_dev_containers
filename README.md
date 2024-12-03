# nvim docker containers

this repo aims to create a docker container, including your native vim setup,
that can be connected to from the host machine, using built in nvim functionality.

# requirements
- pv
- tar
- nvim
- docker
- docker compose

# obtaining a docker image
- docker pull the image you want, I have included some basic docker files for debian, alpine and fedora.
- or, use the _pull_no_docker.sh_ and specify a tag e.g ```alpine:latest``` and an output dir, e.g ```/tmp/alpine_latest```.

the complete usage should be:


```./_pull_no_docker.sh /tmp/alpine_latest alpine:latest```.
    - then, run ```tar -cC '/tmp/alpine_latest' . | docker load``` to load your local docker image.
    - this script is taken from (here)[https://raw.githubusercontent.com/moby/moby/master/contrib/download-frozen-image-v2.sh].

# installing nvim
- install it via your distros package manager, e.g ```dnf install neovim```.
- or, use (bob)[https://github.com/MordechaiHadad/bob] to install and manage nvim versions, as I have done.

## nvim plugins
- I use packer to manage my plugins, hence the inclusion of ```~/.local/share/nvim``` in the packaging script. This may not work for other means of plugin management.
- The instructions for installing packer can be found on the creators github, (here)[https://github.com/wbthomason/packer.nvim]

# creating the docker image
- run ./package_nvim.sh, you need to include this in your docker container, to be opened and ran from inside.
- use whatever docker image you feel like, and install the following:
    - neovim
    - bash
    - curl
    - git
    - tar
    - pv
- OR if this is intended for offline use, use the script under utils, _getBins.sh_, it accepts a comma seperated list of locally installed binaries, and an output location.

- expose a port, in the example dockerfile, i expose 6666, purely because it's unused.
- clone packer if you use it, ensuring that you're running that as the user you intend to use nvim as.
- extract the tarball of your packaged up nvim instance, if you use bob, this will include the nvim binary.
- run the install script located in the now extracted tarball.
- if you are using bob to manage your nvim version, you'll need to either alias,symlink, or append to $PATH to ensure the path to the binary is on path.
- once everything is installed, if you intend to use another user other than root(for instance, if all your plugins and configs rely on a home directory.) ensure you chmod and chown all the files that the script modifies, namely that user's home directory.
- add the following line at the end:

    ```CMD ["nvim", "--headless", "--listen", "0.0.0.0:6666"]```

    ensuring the given port is the one you exposed previously.


