docker build -t yantis/thunderbird .

xhost +si:localuser:$(whoami) >/dev/null
docker run \
  -d \
  -e DISPLAY \
  -v /tmp/.X11-unix:/tmp/.X11-unix:ro \
  -u docker \
  -v ~/docker-data/thunderbird:/home/docker/.thunderbird/ \
  yantis/thunderbird thunderbird

# Note make sure to create your  ~/docker-data/thunderbird
# directory beforehand or you might have permissions issues 
# if it gets auto created.

