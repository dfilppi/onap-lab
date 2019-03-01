#!/bin/bash

set -e

sudo -i helm deploy lab local/onap --namespace onap

# wait for portal to be available
ctx instance runtime_properties portal_url pending

# expose IP of portal
