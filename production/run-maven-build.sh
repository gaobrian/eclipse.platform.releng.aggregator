#!/usr/bin/env bash
#*******************************************************************************
# Copyright (c) 2016 IBM Corporation and others.
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
#
# Contributors:
#     David Williams - initial API and implementation
#*******************************************************************************
#

if [ $# -ne 1 ]; then
  echo USAGE: $0 env_file
  exit 1
fi

if [ ! -r "$1" ]; then
  echo "$1" cannot be read
  echo USAGE: $0 env_file
  exit 1
fi

source "$1"

export SCRIPT_PATH=${SCRIPT_PATH:-$(pwd)}

source $SCRIPT_PATH/build-functions.shsource

cd $BUILD_ROOT

# derived values
gitCache=$( fn-git-cache "$BUILD_ROOT" )
aggDir=$( fn-git-dir "$gitCache" "$AGGREGATOR_REPO" )

if [ -z "$BUILD_ID" ]; then
  BUILD_ID=$(fn-build-id "$BUILD_TYPE" )
fi

fn-maven-build-aggregator "$BUILD_ID" "$aggDir" "$LOCAL_REPO" $MVN_DEBUG $MVN_QUIET $SIGNING $MAVEN_BREE
exitCode=$?

# first make sure exit code is well formed
if [[ -z "${exitCode}" ]]
then
  echo "exitcode was empty"
  exitrc=0
elif [[ "${exitCode}" =~ [0] ]]
then
  echo "exitcode was zero"
  exitrc=0
elif [[ "${exitCode}" =~ ^-?[0-9]+$ ]]
then
  echo "exitcode was a legal, non-zero numeric return code"
  exitrc=$exitCode
  buildDirectory=$( fn-build-dir "$BUILD_ROOT" "$BUILD_ID" "$STREAM" )
  # create as "indicator file" ... gets filled in more once there is a log to grep
  touch  "${buildDirectory}/buildFailed-run-maven-build"
else
  echo "exitode was not numeric, so will force to 1"
  exitrc=1
fi

echo "$( basename $0) exiting with exitrc: $exitrc"
exit $exitrc
