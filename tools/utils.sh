# logger
#
# provides a logging mechanism for scripts to report progress
#
function logger {
  TS=`date`
  echo "[$TS] $@"
}


# retry
#
# retries a command 3 times after a non-zero exit, waiting 60 seconds
# between attempts. 3 times and 60 seconds are default values which can be
# configured with env vars described below.
#
#   NOTE: source this file to update your bash environment with the settings
#   below. Keep in mind that the calling environment will be modified, so do not
#   set or change the environment here unless the caller expects that.  Also
#   remember that "exit" will exit the calling shell!  Consider rewriting this
#   as a callable script if the functionality below needs to make changes to its
#   environment as a side-effect.
#
# Example usage:
# $ retry conda install cudatoolkit=10.0 rapids=0.12
#
# Configurable options are set using the following env vars:
#
# GPUCI_RETRY_MAX       - set to a positive integer to set the max number of retry
#                         attempts (attempts after the initial try).
#                         Default is 10 retries
#
# GPUCI_RETRY_SLEEP     - set to a positive integer to set the duration, in
#                         seconds, to wait between retries.
#                         Default is a 10 second sleep
#
function retry {
    command=$1
    shift
    args=$*
    max_retries=${GPUCI_RETRY_MAX:=3}
    retries=0
    sleep_interval=${GPUCI_RETRY_SLEEP:=60}

    ${command} ${args}
    retcode=$?
    while (( ${retcode} != 0 )) && \
          (( ${retries} < ${max_retries} )); do
      ((retries++))
      logger "========================================"
      logger "GPUCI_RETRY> ${retries} of ${max_retries}..."
      logger "GPUCI_RETRY> sleeping for ${sleep_interval} seconds..."
      sleep ${sleep_interval}
      logger "GPUCI_RETRY> done sleeping..."
      logger "========================================"

      ${command} ${args}
      retcode=$?
    done
    return ${retcode}
}
