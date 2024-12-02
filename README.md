# nvim docker containers

this repo aims to create a docker container, including your native vim setup,
that can be connected to from the host machine, using built in nvim functionality.

# requirements
- pv
- tar
- nvim
- docker
- docker compose


# creating the docker image
- run ./package_nvim.sh, you need to include this in your docker container, to be opened and ran from inside.
- use whatever docker image you feel like, and install the following:
    - neovim
    - bash
    - curl
    - git
    - tar
    - pv

- expose a port, in the example dockerfile, i expose 6666, purely because it's unused.
- clone packer if you use it, ensuring that you're running that as the user you intend to use nvim as.
- extract the tarball of your packaged up nvim instance, if you use bob, this will include the nvim binary.
- run the install script located in the now extracted tarball.
- if you are using bob to manage your nvim version, you'll need to either alias,symlink, or append to $PATH to ensure the path to the binary is on path.

- add the following line at the end:

    ```CMD ["nvim", "--headless", "--listen", "0.0.0.0:6666"]```

    ensuring the given port is the one you exposed previously.


