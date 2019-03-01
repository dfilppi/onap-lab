#!/bin/bash

ctx logger info "ASROOT SCRIPT=$SCRIPT"

ctx download-resource resources/oom-master.tgz '@{"target_path": "/tmp/oom-master.tgz"}'
ctx download-resource scripts/${SCRIPT} '@{"target_path": "/tmp/'${SCRIPT}'"}'
sudo chmod +x /tmp/${SCRIPT}
sudo -i /tmp/${SCRIPT} >> /tmp/${SCRIPT}.out 2>> /tmp/${SCRIPT}.err
