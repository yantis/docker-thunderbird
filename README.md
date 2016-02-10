# docker-thunderbird

On Docker hub [thunderbird](https://registry.hub.docker.com/u/ironicbadger/thunderbird)
on Github [thunderbird](https://github.com/ironicbadger/docker-thunderbird)

This container is a fork of `yantis/docker-thunderbird`. Thanks to him for his work on this.

## Usage (Remote SSH)

I run this on DigitalOcean and connect to Thunderbird from anywhere I have SSH. Totally boss.

```bash
docker run \
    -d \
		--name thunderbird \
    -v $HOME/.ssh/authorized_keys:/authorized_keys:ro \
    -p 49158:22 \
    -v ~/appdata/thunderbird:/home/docker/.thunderbird/ \
    ironicbadger/docker-thunderbird
```

## Breakdown (Remote SSH)

This follows these docker conventions:

* `-ti` will run an interactive session that can be terminated with CTRL+C.
* `--rm` will run a temporary session that will make sure to remove the container on exit.
* `-v $HOME/.ssh/authorized_keys:/authorized_keys:ro` Optionaly share your public keys with the host.
This is particularlly useful when you are running this on another server that already has SSH. Like an
Amazon EC2 instance. WARNING: If you don't use this then it will just default to the user pass of docker/docker
(If you do specify authorized keys it will disable all password logins to keep it secure).
* `-v ~/docker-data/thunderbird:/home/docker/.thunderbird/` This is where to save your config files.
* `yantis/thunderbird` the default mode is SSH so no need to run any commands.

Here is a screenshot of Thunderbird running on Docker.
![](http://yantis-scripts.s3.amazonaws.com/Screenshot_2015-04-10_22-40-50.png)

## Usage (Local)

The recommended way to run this container looks like this. This example launches Thunderbird seamlessly as
if it was another program on your computer.

```bash
xhost +si:localuser:$(whoami)
docker run \
        -d \
        -e DISPLAY \
        -v /tmp/.X11-unix:/tmp/.X11-unix:ro \
        -u docker \
        -v $HOME/docker-data/thunderbird:/home/docker/.thunderbird/ \
        ironicbadger/docker-thunderbird thunderbird
```

## Breakdown (Local)

```bash
$ xhost +si:localuser:yourusername
```

Allows your local user to access the xsocket. Change yourusername or use $(whoami)
or $USER if your shell supports it.


```bash
docker run \
           -d \
           -e DISPLAY \
           -v /tmp/.X11-unix:/tmp/.X11-unix:ro \
           -u docker \
           -v /:/host \
           -v $HOME/docker-data/thunderbird:/home/docker/.thunderbird/ \
           ironicbadger/docker-thunderbird thunderbird
```
This follows these docker conventions:

* `-d` run in daemon mode.
* `-e DISPLAY` sets the host display to the local machines display.
* `-v /tmp/.X11-unix:/tmp/.X11-unix:ro` bind mounts the X11 socks on your local machine
to the containers and makes it read only.
* `-u docker` sets the user to docker. (or you could do root as well)
* `-v ~/docker-data/thunderbird:/home/docker/.thunderbird/` This is where to save your config files.
* `yantis/thunderbird thunderbird` You need to call thunderbird because if you do not it will a launch the ssh
server instead as a default.
