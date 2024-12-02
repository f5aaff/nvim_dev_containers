# Remote access to nvim

# [neovim-remote](https://github.com/mhinz/neovim-remote)
 ## installation
 - ```pip3 install neovim-remote```
 leverages the fact that nvim always starts as a server, then connects.


## first steps
- ```nvim --listen --headless 127.0.0.1:6666``` start nvim in listening & headless  mode

- ```nvr --servername 127.0.0.1:6666``` use nvr to send commands to this server



# Raw nvim listening mode

- ```nvim --listen 127.0.0.1:6666 --headless ``` start nvim in listening & headless  mode.
- ENSURE THE PORT YOU PICK IS EXPOSED TO YOUR HOST
- ```nvim --server 127.0.0.1:6666 --remote-ui``` this will connect the nvim TUI to the server address, provided the address is valid.
