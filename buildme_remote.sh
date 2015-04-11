docker build -t yantis/filezilla .

docker run \
  -ti \
  --rm \
  -v $HOME/.ssh/authorized_keys:/authorized_keys:ro \
  -p 49158:22 \
  -v ~/docker-data/thunderbird:/home/docker/.thunderbird/ \
  yantis/thunderbird

# Note make sure to create your  ~/docker-data/thunderbird
# directory beforehand or you might have permissions issues 
# if it gets auto created.

