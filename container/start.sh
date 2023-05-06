#!/bin/bash
# start dockerd
service docker start > /dev/null 2>&1 || sudo service docker start > /dev/null 2>&1 || true
# start github-runner
./bin/Runner.Listener run --startuptype service
