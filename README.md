# docker-thunderbird

On Docker hub [thunderbird](https://registry.hub.docker.com/u/yantis/thunderbird)
on Github [thunderbird](https://github.com/yantis/docker-thunderbird)

This is Thunderbird on Docker. It has three modes: Local (no ssh server), remote with ssh server, as
well as an optional script for an instant launch AWS EC2 for quick file transfers with 
storage to EBS volume (Amazon Elastic Block Store). Check out the [aws-thunderbird.sh]
(https://github.com/yantis/docker-thunderbird/blob/master/examples/aws-thunderbird.sh) script for this.
Also, there is a script to auto create and format your EBS volume [aws-ebs-create-volume-and-format.sh]
(https://github.com/yantis/docker-thunderbird/blob/master/examples/aws-ebs-create-volume-and-format.sh)


### Docker Images Structure
>[yantis/archlinux-tiny](https://github.com/yantis/docker-archlinux-tiny)
>>[yantis/archlinux-small](https://github.com/yantis/docker-archlinux-small)
>>>[yantis/archlinux-small-ssh-hpn](https://github.com/yantis/docker-archlinux-ssh-hpn)
>>>>[yantis/ssh-hpn-x](https://github.com/yantis/docker-ssh-hpn-x)
>>>>>[yantis/dynamic-video](https://github.com/yantis/docker-dynamic-video)
>>>>>[yantis/filezilla](https://github.com/yantis/docker-filezilla)
>>>>>[yantis/thunderbird](https://github.com/yantis/docker-thunderbird)
>>>>>>[yantis/virtualgl](https://github.com/yantis/docker-virtualgl)
>>>>>>>[yantis/wine](https://github.com/yantis/docker-wine)


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
        yantis/thunderbird thunderbird
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
           yantis/thunderbird thunderbird
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


## Usage (Remote SSH)

The recommended way to run this container over SSH looks like this. This example launches an high performance SSH
server with X-forwarding enabled. Which you can ssh -X (or -Y) into. Check out the [remote-thunderbird](https://github.com/yantis/docker-thunderbird/blob/master/examples/remote-thunderbird.sh)
and the [aws-thunderbird.sh](https://github.com/yantis/docker-thunderbird/blob/master/examples/aws-thunderbird.sh) script for an example of this.


```bash
docker run \
    -ti \
    --rm \
    -v $HOME/.ssh/authorized_keys:/authorized_keys:ro \
    -p 49158:22 \
    -v ~/docker-data/thunderbird:/home/docker/.thunderbird/ \
    yantis/thunderbird
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
