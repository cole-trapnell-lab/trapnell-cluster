#!/bin/bash
USAGE="Usage: serve_vscode [-m|--memory memory] [-c|--cores cores] [-t|--timelimit timelimit] [-n|--name server_name] [-r|--r_version r_version] [-p|--python_version python_version]\n\
Options:\n\
  -m, --memory     Memory to allocate for the job (default: 8G)\n\
  -c, --cores      Number of cores to allocate for the job (default: 1)\n\
  -t, --timelimit  Time limit for the job, formatted as hours:minutes:seconds (default: 48:0:0)\n\
  -n, --name       Name of the server, will be appended to the job name as 'vscode_<name>'\n\
  -r, --r_version  R version to use, formatted as 'x.x.x'. Default is to use what is in '~/.bashrc' or equivalent\n\
  -p, --python_version  Python version to use, formatted as 'x.x.x'. Default is to use what is in '~/.bashrc' or equivalent\n\
  -h, --help       Show this help message and exit\n"

# Defaults
MEM="8G"
CORES="1"
TIMELIMIT="48:0:0"
SERVER_NAME="vscode"

while [[ $# -gt 0 ]]; do
    case $1 in
        -m|--memory)
            MEM="$2"
            shift
            shift
            ;;
        -c|--cores)
            CORES="$2"
            shift
            shift
            ;;
        -t|--timelimit)
            TIMELIMIT="$2"
            shift
            shift
            ;;
        -n|--name)
            SERVER_NAME="${SERVER_NAME}_$2"
            shift
            shift
            ;;
        -r|--r_version)
            R_VERSION="$2"
            shift
            shift
            ;;
        -p|--python_version)
            PYTHON_VERSION="$2"
            shift
            shift
            ;;
        -h|--help)
            echo -e "${USAGE}"
            exit 0
            ;;
        -*|--*)
            echo "Unknown option: $1"
            echo -e "${USAGE}"
            exit 1
            ;;
        *)
            echo -e "${USAGE}"
            exit 1
            ;;
    esac
done

LOG_FILE=$HOME/nobackup/log/vscode.o
ERR_FILE=$HOME/nobackup/log/vscode.e

# Check for existing vscode tunnel jobs
existing_jobs=$(qstat -u $USER | grep "vscode" | awk '{print $1}')

# If there are existing jobs, ask if user wants to terminate them
if [ ! -z "$existing_jobs" ]; then
    job_count=$(echo "$existing_jobs" | wc -l)
    echo "Found $job_count existing VS Code tunnel job(s)"
    
    read -p "Do you want to terminate all existing VS Code tunnel jobs? [Y/n]: " terminate
    
    if [ "$terminate" = "y" ] || [ "$terminate" = "Y" ] || [ -z "$terminate" ]; then
        for job_id in $existing_jobs; do
            echo "Terminating job $job_id..."
            qdel $job_id
        done
        # Wait briefly to ensure jobs are terminated
        echo "Waiting for jobs to terminate..."
        sleep 3

    else
        echo "Keeping existing jobs. Note that multiple VS Code tunnel sessions may cause conflicts."
    fi

	echo ""
fi

if [ -f "${LOG_FILE}" ]; then
    rm "${LOG_FILE}"
fi
if [ -f "${ERR_FILE}" ]; then
    rm "${ERR_FILE}"
fi

cmd="qsub -o ${LOG_FILE} -e ${ERR_FILE} -l mfree=${MEM} -pe serial ${CORES} -l h_rt=${TIMELIMIT} -N ${SERVER_NAME} ${HOME}/sge/serve_vscode.sge"
# Add R and Python versions to the command if specified
if [ -n "${R_VERSION}" ]; then
    cmd+=" -r ${R_VERSION}"
fi
if [ -n "${PYTHON_VERSION}" ]; then
    cmd+=" -p ${PYTHON_VERSION}"
fi
echo -e "Submitting a VSCode server with the command:\n\t${cmd}\n\n"
eval "${cmd}"

WAIT_TIME=5
echo "Waiting for ${WAIT_TIME} seconds for the job to start..."
sleep ${WAIT_TIME}

# Check if the log file exists
if [ -f "${LOG_FILE}" ]; then
    # Wait for the GitHub login line to appear (try for up to 10 seconds)
    echo "Looking for GitHub login information..."
    max_attempts=30
    attempts=0
    
    AUTH_MSG=""
    while [ $attempts -lt $max_attempts ]; do
        # Check if the GitHub login line exists in the log file
        if grep -q "Found token in keyring" "${LOG_FILE}"; then
            AUTH_MSG="Server is already authenticated. Open VS Code, select 'Connect to Tunnel...' and then 'GitHub' to connect to the server."
            break
        elif grep -q "To grant access to the server, please log into" "${LOG_FILE}"; then
            # Extract and display the line containing the GitHub login URL and code
            github_line=$(grep "To grant access to the server, please log into" "${LOG_FILE}")
            AUTH_MSG="\n-------------------------------------------------------\n$github_line\n-------------------------------------------------------\n\nAfter authenticating, open VS Code, select 'Connect to Tunnel...' and then 'GitHub' to connect to the server."
            break
        fi
        # Increment attempts counter
        attempts=$((attempts + 1))
        # Wait for 1 second before checking again
        sleep 1
    done
    # If we couldn't find the line after all attempts
    if [ $attempts -eq $max_attempts ]; then
        AUTH_MSG="Could not find GitHub login information after ${max_attempts} seconds.\nPlease check the log file manually at: ${LOG_FILE}\nIf you encounter issues, examine the error file at: ${ERR_FILE}"
    fi
else
    echo "Log file not found at ${LOG_FILE} after waiting ${WAIT_TIME} seconds for file creation."
    echo "The job may still be in the queue or there might be an issue."
    echo "You can check job status with 'qstat -u $USER' and examine error output at: ${ERR_FILE}"
    exit 0
fi

sleep 1

# Check for errors loading modules
module_errors=$(grep "ERROR: Unable to locate a modulefile for" ~/nobackup/log/vscode.e 2>/dev/null)
if [ -n "$module_errors" ]; then
    echo "Error loading modules. Check your module versions are valid. Error message:"
    echo "$module_errors"
    exit 1
fi

# Display the authentication message
echo -e "$AUTH_MSG"
