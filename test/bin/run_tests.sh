#!/bin/bash

# Main function to run the container.
# Copy all the files into a new test directory because they will clobber each other in parallel
# Note: Do not add any commands to the end of this method as docker run will return the exit code
# needed to determine the success of the build.
function run_docker {
  echo "Running Docker container for $image"
  echo "Copying the files to a new test directory"
  mkdir -p docker_tests/$image
  rsync -a . docker_tests/$image/ --exclude docker_tests --exclude .idea
  cd docker_tests/$image

  echo "Executing the docker command"
  docker run -e "COVERALLS_REPO_TOKEN=$COVERALLS_REPO_TOKEN" \
      -v $(pwd):/var/simdata/openstudio nrel/openstudio:$image \
      /var/simdata/openstudio/test/bin/docker-run.sh
}


## Script Start ##

bundle install

i=0

# List any tags that you want to test of the Docker image. These must be able to be made into directories
docker_tags=(
    '1.13.0'
    '1.13.2'
)

# Iterate over the tags and put them into groups based on the Circle CI Node Index.
# This effectively chunks up the number of images if greater than CIRCLE_NODE_TOTAL
images=()
for tag in ${docker_tags[@]}
do
  if [ $(($i % $CIRCLE_NODE_TOTAL)) -eq $CIRCLE_NODE_INDEX ]
  then
    images+=${tag}
  fi
  ((i++))
done

for image in ${images[@]}
do
  run_docker; (( exit_status = exit_status || $? )) 
done

exit $exit_status

