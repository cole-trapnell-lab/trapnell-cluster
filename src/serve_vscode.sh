#!/bin/bash
while getopts "m:c:t:" opt; do
    case ${opt} in
        m )
            MEM=$OPTARG
            ;;
        c )
            CORES=$OPTARG
            ;;
        t )
            TIMELIMIT=$OPTARG
            ;;
        \? )
            echo "Usage: serve_vscode [-m memory] [-c cores] [-t timelimit]"
            echo "Options:"
            echo "  -m memory     Memory to allocate for the job (default: 8G)"
            echo "  -c cores      Number of cores to allocate for the job (default: 1)"
            echo "  -t timelimit  Time limit for the job, formatted as hours:minutes:seconds (default: 48:0:0)"
            exit 1
            ;;
    esac
done

# Set default values if not provided
MEM=${MEM:-8G}
CORES=${CORES:-1}
TIMELIMIT=${TIMELIMIT:-48:0:0}

LOG_FILE=$HOME/nobackup/log/vscode.o
ERR_FILE=$HOME/nobackup/log/vscode.e

# Check for existing vscode tunnel jobs
existing_jobs=$(qstat -u $USER | grep "vscode" | awk '{print $1}')

# If there are existing jobs, ask if user wants to terminate them
if [ ! -z "$existing_jobs" ]; then
    job_count=$(echo "$existing_jobs" | wc -l)
    echo "Found $job_count existing VS Code tunnel job(s)"
    
    read -p "Do you want to terminate all existing VS Code tunnel jobs? [Y/n]: " terminate
    
    if [[ "$terminate" == "y" || "$terminate" == "Y" || "$terminate" == "" ]]; then
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
fi

if [ -f "${LOG_FILE}" ]; then
    rm "${LOG_FILE}"
fi
if [ -f "${ERR_FILE}" ]; then
    rm "${ERR_FILE}"
fi

#cmd="qsub -o ${LOG_FILE} -e ${ERR_FILE} -l mfree=${MEM} -pe serial ${CORES} -l h_rt=${TIMELIMIT} < <(echo \"${SCRIPT}\")"
cmd="qsub -o ${LOG_FILE} -e ${ERR_FILE} -l mfree=${MEM} -pe serial ${CORES} -l h_rt=${TIMELIMIT} -N vscode ${HOME}/sge/serve_vscode.sge"
echo "Submitting a VSCode server with the command:\n\t${cmd}"
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
    
    while [ $attempts -lt $max_attempts ]; do
        # Check if the GitHub login line exists in the log file
        if grep -q "Found token in keyring"; then
            echo ""
            echo "Server is already authenticated. Open VS Code, select 'Connect to Tunnel...' and then 'GitHub' to connect to the server."
            echo ""
            break
        elif grep -q "To grant access to the server, please log into" "${LOG_FILE}"; then
            # Extract and display the line containing the GitHub login URL and code
            github_line=$(grep "To grant access to the server, please log into" "${LOG_FILE}")
            echo ""
            echo "-------------------------------------------------------"
            echo "$github_line"
            echo "-------------------------------------------------------"
            echo ""
            echo "After authenticating, open VS Code, select 'Connect to Tunnel...' and then 'GitHub' to connect to the server."
            echo ""
            break
        fi
        
        # Increment attempts counter
        attempts=$((attempts + 1))
        # Wait for 1 second before checking again
        sleep 1
    done
    
    # If we couldn't find the line after all attempts
    if [ $attempts -eq $max_attempts ]; then
        echo "Could not find GitHub login information after ${max_attempts} seconds."
        echo "Please check the log file manually at: ${LOG_FILE}"
        echo "If you encounter issues, examine the error file at: ${ERR_FILE}"
    fi
else
    echo "Log file not found at ${LOG_FILE} after waiting ${WAIT_TIME} seconds for file creation."
    echo "The job may still be in the queue or there might be an issue."
    echo "You can check job status with 'qstat -u $USER' and examine error output at: ${ERR_FILE}"
fi
