#!/usr/bin/env bash

###############################################################################
#                                                                             #
#  Script to run on a local computer to start a code-server on ShARC and      #
#  connect it with a local browser to it                                      #
#                                                                             #
#  Main author    : Samuel Fux                                                #
#  Contributions  : Andreas Lugmayr                                           #
#  Date           : October 2021                                              #
#  Location       : ETH Zurich                                                #
#  Version        : 0.1                                                       #
#  Change history :                                                           #
#                                                                             #
#  28.10.2021    Initial version of the script based on Jupyter script        #
#  Forked and edited for TUoS by J.Moore                                      #
###############################################################################

###############################################################################
# Configuration options, initalising variables and setting default values     #
###############################################################################

# Version
VSC_VERSION="0.1"

# Script directory
VSC_SCRIPTDIR=$(pwd)

# hostname of the cluster to connect to
VSC_HOSTNAME="sharc.shef.ac.uk"

# order for initializing configuration options
# 1. Defaults values set inside this script
# 2. Command line options overwrite defaults
# 3. Config file options  overwrite command line options

# Configuration file default    : $HOME/.vsc_config
VSC_CONFIG_FILE="$HOME/.vsc_config"

# Username default              : no default
VSC_USERNAME=""

# Number of CPU cores default   : 1 CPU core
VSC_NUM_CPU=1

# Runtime limit default         : 1:00 hour
VSC_RUN_TIME="01:00:00"

# Memory default                : 1024 MB per core
VSC_MEM_PER_CPU_CORE=1024

# Number of GPUs default        : 0 GPUs
VSC_NUM_GPU=0

# Waiting interval default      : 30 seconds
VSC_WAITING_INTERVAL=30

# SSH key location default      : no default
VSC_SSH_KEY_PATH=""

###############################################################################
# Usage instructions                                                          #
###############################################################################

function display_help {
cat <<-EOF
$0: Script to start a VSCode remote server on ShARC from a local computer

Usage: start_vscode.sh [options]

Options:

        -u | --username       USERNAME         TUoS username for SSH connection to ShARC
        -n | --numcores       NUM_CPU          Number of CPU cores to be used on the cluster
        -W | --runtime        RUN_TIME         Run time limit for the code-server in hours and minutes HH:MM
        -m | --memory         MEM_PER_CORE     Memory limit in MB per core

Optional arguments:

        -c | --config         CONFIG_FILE      Configuration file for specifying options
        -g | --numgpu         NUM_GPU          Number of GPUs to be used on the cluster
        -h | --help                            Display help for this script and quit
        -i | --interval       INTERVAL         Time interval for checking if the job on the cluster already started
        -k | --key            SSH_KEY_PATH     Path to SSH key with non-standard name
        -v | --version                         Display version of the script and exit

Examples:

        ./start_vscode.sh -u te1st -n 4 -W 04:00:00 -m 2048

        ./start_vscode.sh --username te1st --numcores 2 --runtime 01:30:00 --memory 2048

        ./start_vscode.sh -c $HOME/.vsc_config

Format of configuration file:

VSC_USERNAME=""             # TUoS username for SSH connection to ShARC
VSC_NUM_CPU=1               # Number of CPU cores to be used on the cluster
VSC_NUM_GPU=0               # Number of GPUs to be used on the cluster
VSC_RUN_TIME="01:00:00"     # Run time limit for the code-server in hours and minutes HH:MM:SS
VSC_MEM_PER_CPU_CORE=1024   # Memory limit in MB per core
VSC_WAITING_INTERVAL=60     # Time interval to check if the job on the cluster already started
VSC_SSH_KEY_PATH=""         # Path to SSH key with non-standard name

EOF
exit 1
}

###############################################################################
# Parse configuration options                                                 #
###############################################################################

while [[ $# -gt 0 ]]
do
        case $1 in
                -h|--help)
                display_help
                ;;
                -v|--version)
                echo -e "start_vscode.sh version: $VSC_VERSION\n"
                exit
                ;;
                -u|--username)
                VSC_USERNAME=$2
                shift
                shift
                ;;
                -n|--numcores)
                VSC_NUM_CPU=$2
                shift
                shift
                ;;
                -W|--runtime)
                VSC_RUN_TIME=$2
                shift
                shift
                ;;
                -m|--memory)
                VSC_MEM_PER_CPU_CORE=$2
                shift
                shift
                ;;
                -c|--config)
                VSC_CONFIG_FILE=$2
                shift
                shift
                ;;
                -g|--numgpu)
                VSC_NUM_GPU=$2
                shift
                shift
                ;;
                -i|--interval)
                VSC_WAITING_INTERVAL=$2
                shift
                shift
                ;;
                -k|--key)
                VSC_SSH_KEY_PATH=$2
                shift
                shift
                ;;
                *)
                echo -e "Warning: ignoring unknown option $1 \n"
                shift
                ;;
        esac
done

###############################################################################
# Check configuration options                                                 #
###############################################################################

# check if user has a configuration file and source it to initialize options
if [ -f "$VSC_CONFIG_FILE" ]; then
        echo -e "Found configuration file $VSC_CONFIG_FILE"
        echo -e "Initializing configuration from file ${VSC_CONFIG_FILE}:"
        cat "$VSC_CONFIG_FILE"
        source "$VSC_CONFIG_FILE"
fi

# check that VSC_USERNAME is not an empty string
if [ -z "$VSC_USERNAME" ]
then
        echo -e "Error: No TUoS username is specified, terminating script\n"
        display_help
else
        echo -e "TUoS username: $VSC_USERNAME"
fi

# check number of CPU cores

# check if VSC_NUM_CPU an integer
if ! [[ "$VSC_NUM_CPU" =~ ^[0-9]+$ ]]; then
        echo -e "Error: $VSC_NUM_CPU -> Incorrect format. Please specify number of CPU cores as an integer and try again\n"
        display_help
fi

# check if VSC_NUM_CPU is <= 16
if [ "$VSC_NUM_CPU" -gt "16" ]; then
        echo -e "Error: $VSC_NUM_CPU -> Larger than 16. No distributed memory supported, therefore the number of CPU cores needs to be smaller or equal to 16\n"
        display_help
fi

if [ "$VSC_NUM_CPU" -gt "0" ]; then
        echo -e "Requesting $VSC_NUM_CPU CPU cores for running the code-server"
fi

# check number of GPUs

# check if VSC_NUM_GPU an integer
if ! [[ "$VSC_NUM_GPU" =~ ^[0-9]+$ ]]; then
        echo -e "Error: $VSC_NUM_GPU -> Incorrect format. Please specify the number of GPU as an integer and try again\n"
        display_help
fi

# check if VSC_NUM_GPU is <= 7
if [ "$VSC_NUM_GPU" -gt "7" ]; then
        echo -e "Error: No distributed memory supported, therefore number of GPUs needs to be smaller or equal to 7\n"
        display_help
fi

if [ "$VSC_NUM_GPU" -gt "0" ]; then
        echo -e "Requesting $VSC_NUM_GPU GPUs for running the code-server"
        VSC_SNUM_GPU="-l gpu=$VSC_NUM_GPU"
else
        VSC_SNUM_GPU=""
fi

if [ ! "$VSC_NUM_CPU" -gt "0" -a ! "$VSC_NUM_GPU" -gt "0" ]; then
        echo -e "Error: No CPU and no GPU resources requested, terminating script"
        display_help
fi

# check if VSC_RUN_TIME is provided in HH:MM:SS format
if ! [[ "$VSC_RUN_TIME" =~ ^[0-9][0-9]:[0-9][0-9]:[0-9][0-9]$ ]]; then
        echo -e "Error: $VSC_RUN_TIME -> Incorrect format. Please specify runtime limit in the format HH:MM:SS and try again\n"
        display_help
else
    echo -e "Run time limit set to $VSC_RUN_TIME"
fi

# check if VSC_MEM_PER_CPU_CORE is an integer
if ! [[ "$VSC_MEM_PER_CPU_CORE" =~ ^[0-9]+$ ]]; then
        echo -e "Error: $VSC_MEM_PER_CPU_CORE -> Memory limit must be an integer, please try again\n"
        display_help
else
    echo -e "Memory per core set to $VSC_MEM_PER_CPU_CORE MB"
fi

# check if VSC_WAITING_INTERVAL is an integer
if ! [[ "$VSC_WAITING_INTERVAL" =~ ^[0-9]+$ ]]; then
        echo -e "Error: $VSC_WAITING_INTERVAL -> Waiting time interval [seconds] must be an integer, please try again\n"
        display_help
else
    echo -e "Setting waiting time interval for checking the start of the job to $VSC_WAITING_INTERVAL seconds"
fi

# set modules
VSC_MODULE_COMMAND="apps/vscode-server/4.2.0/binary dev/git/2.35.2/gcc-4.9.4"

# check if VSC_SSH_KEY_PATH is empty or contains a valid path
if [ -z "$VSC_SSH_KEY_PATH" ]; then
        VSC_SKPATH=""
else
        VSC_SKPATH="-i $VSC_SSH_KEY_PATH"
        echo -e "Using SSH key $VSC_SSH_KEY_PATH"
fi

# put together string for SSH options
VSC_SSH_OPT="$VSC_SKPATH $VSC_USERNAME@$VSC_HOSTNAME"

###############################################################################
# Check for leftover files                                                    #
###############################################################################

# check if some old files are left from a previous session and delete them

# check for reconnect_info in the current directory on the local computer
echo -e "Checking for left over files from previous sessions"
if [ -f $VSC_SCRIPTDIR/reconnect_info ]; then
        echo -e "Found old reconnect_info file, deleting it ..."
        rm $VSC_SCRIPTDIR/reconnect_info
fi

# check for log files from a previous session in the home directory of the cluster
ssh -T $VSC_SSH_OPT <<ENDSSHIP
if [ -f /home/$VSC_USERNAME/vscip ]; then
        echo -e "Found old vscip file, deleting it ..."
        rm /home/$VSC_USERNAME/vscip
fi
ENDSSHIP

ssh -T $VSC_SSH_OPT <<ENDSSHPORT
if [ -f /home/$VSC_USERNAME/vscport ]; then
        echo -e "Found old vscport file, deleting it ..."
        rm /home/$VSC_USERNAME/vscport
fi
ENDSSHPORT

VSCJIDPRESENT=$(ssh $VSC_SSH_OPT "[ -e ~/vscjid ] && echo 1 || echo 0")

if [[ "$VSCJIDPRESENT" == 1 ]] ; then
        echo -e "Found old vscjid file, are you already running a session?  Remove /home/$VSC_USERNAME/vscjid if you are sure this is not a duplicate session and re-run script. Exiting!"
        exit 1
fi

###############################################################################
# Check required SSL certs exist                                              #
###############################################################################

SSLCERT=$(ssh $VSC_SSH_OPT "[ -e ~/.ssl/vscoderemote/vscode_remote_ssl-server-cert.pem ] && echo 1 || echo 0")
SSLCERTKEY=$(ssh $VSC_SSH_OPT "[ -e ~/.ssl/vscoderemote/private/vscode_remote_ssl-server-key.pem ] && echo 1 || echo 0")

if [[ "$SSLCERT" == 0 ]] || [[ "$SSLCERTKEY" == 0 ]] ; then
        echo -e "Missing SSL certificate or key. Exiting! Please 'module load apps/vscode-server/4.2.0/binary' run SSL setup step 'setup_ssl_ca_server_client.sh' first! "
        exit 1
fi

###############################################################################
# Start code-server on the cluster                                            #
###############################################################################

# Make a random password
VSCPASS=$(strings /dev/urandom | grep -o '[[:alnum:]]' | head -n 30 | tr -d '\n'; echo)

# This is being done this way for reasons.
ssh -T $VSC_SSH_OPT "sed -i '/^password:/d' ~/.config/code-server/config.yaml && echo 'password: $VSCPASS' > ~/.config/code-server/config.yaml"

# run the code-server job on ShARC and save the ip of the compute node in the file vscip in the home directory of the user on ShARC
echo -e "Connecting to $VSC_HOSTNAME to start the code-server in a batch job"
# FIXME: save jobid in a variable, that the script can kill the batch job at the end
echo -e "Connection command:"
echo -e "============================================================================================"
echo -e "ssh ${VSC_SSH_OPT} qsub -V -pe smp ${VSC_NUM_CPU} -l h_rt=${VSC_RUN_TIME} -l rmem=${VSC_MEM_PER_CPU_CORE}M ${VSC_SNUM_GPU}"
echo -e "============================================================================================\n"
ssh ${VSC_SSH_OPT} qsub -N VSCodeServer -pe smp ${VSC_NUM_CPU} -l h_rt=${VSC_RUN_TIME} -l rmem=${VSC_MEM_PER_CPU_CORE}M ${VSC_SNUM_GPU} <<ENDQSUB
source \${HOME}/.bashrc
module load $VSC_MODULE_COMMAND
export XDG_RUNTIME_DIR="\$HOME/vsc_runtime"
VSC_IP_REMOTE="\$(hostname)"
VSC_PORT_REMOTE=$(comm -23 <(seq 49152 65535 | sort) <(ss -Htan | awk '{print $4}' | cut -d':' -f2 | sort -u) | shuf | head -n 1)
echo "Remote IP:\$VSC_IP_REMOTE" > /home/$VSC_USERNAME/vscip
echo "Remote PORT:\$VSC_PORT_REMOTE" > /home/$VSC_USERNAME/vscport
echo "Remote JOB ID:\$JOB_ID" > /home/$VSC_USERNAME/vscjid
code-server --cert ~/.ssl/vscoderemote/vscode_remote_ssl-server-cert.pem --cert-key ~/.ssl/vscoderemote/private/vscode_remote_ssl-server-key.pem --bind-addr=\${VSC_IP_REMOTE}:\${VSC_PORT_REMOTE}
ENDQSUB

# wait until batch job has started, poll every $VSC_WAITING_INTERVAL seconds to check if /cluster/home/$VSC_USERNAME/vscip exists
# once the file exists and is not empty the batch job has started
ssh $VSC_SSH_OPT <<ENDSSH
while ! [ -e /home/$VSC_USERNAME/vscip -a -s /home/$VSC_USERNAME/vscip ]; do
        echo 'Waiting for code-server to start, sleep for $VSC_WAITING_INTERVAL sec'
        sleep $VSC_WAITING_INTERVAL
done
ENDSSH


# give the code-server a few seconds to start
sleep 7

# get remote ip, port and token from files stored on ShARC
echo -e "Receiving ip, port and token from the code-server"
VSC_REMOTE_IP=$(ssh $VSC_SSH_OPT "cat /home/$VSC_USERNAME/vscip | grep -m1 'Remote IP' | cut -d ':' -f 2")
VSC_REMOTE_PORT=$(ssh $VSC_SSH_OPT "cat /home/$VSC_USERNAME/vscport | grep -m1 'Remote PORT' | cut -d ':' -f 2")
VSC_REMOTE_JID=$(ssh $VSC_SSH_OPT "cat /home/$VSC_USERNAME/vscjid | grep -m1 'Remote JOB ID' | cut -d ':' -f 2")

# check if the IP, the port and the token are defined
if  [[ "$VSC_REMOTE_IP" == "" ]]; then
cat <<EOF
Error: remote ip is not defined. Terminating script.
* Please check login to the cluster and check with qstat if the batch job on the cluster is running and terminate it with qdel.
EOF
exit 1
fi

# print information about IP, port and token
echo -e "Remote IP address: $VSC_REMOTE_IP"
echo -e "Remote port: $VSC_REMOTE_PORT"
echo -e "Remote Job ID: $VSC_REMOTE_JID"

# get a free port on local computer
echo -e "Determining free port on local computer"
#VSC_LOCAL_PORT=$(python -c 'import socket; s=socket.socket(); s.bind(("",0)); print(s.getsockname()[1]); s.close()')
# FIXME: check if there is a solution that does not require python (as some Windows computers don't have a usable Python installed by default)
# if python is not available, one could use
VSC_LOCAL_PORT=$((3 * 2**14 + RANDOM % 2**14))
#VSC_LOCAL_PORT=$(comm -23 <(seq 49152 65535 | sort) <(ss -Htan | awk '{print $4}' | cut -d':' -f2 | sort -u) | shuf | head -n 1)
# as a replacement. No guarantee that the port is unused, but so far best non-Python solution

echo -e "Using local port: $VSC_LOCAL_PORT"

# write reconnect_info file
cat <<EOF > $VSC_SCRIPTDIR/reconnect_info
Restart file
Remote IP address : $VSC_REMOTE_IP
Remote port       : $VSC_REMOTE_PORT
Local port        : $VSC_LOCAL_PORT
Cluster Job ID    : $VSC_REMOTE_JID
SSH tunnel        : ssh $VSC_SSH_OPT -L $VSC_LOCAL_PORT:$VSC_REMOTE_IP:$VSC_REMOTE_PORT -N &
URL               : http://localhost:$VSC_LOCAL_PORT
EOF

# setup SSH tunnel from local computer to compute node via login node
# FIXME: check if the tunnel can be managed via this script (opening, closing) by using a control socket from SSH
echo -e "Setting up SSH tunnel for connecting the browser to the code-server"
ssh $VSC_SSH_OPT -L $VSC_LOCAL_PORT:$VSC_REMOTE_IP:$VSC_REMOTE_PORT -N &

# Since we want to terminate this tunnel when the session is over grab it now.
SSH_TUNNEL_PID=$!

# SSH tunnel is started in the background, pause 5 seconds to make sure
# it is established before starting the browser
sleep 5

# save url in variable
VSC_URL=https://localhost:$VSC_LOCAL_PORT
echo -e "Starting browser and connecting it to the code-server"
echo -e "Connecting to url $VSC_URL"

# start local browser if possible
if [[ "$OSTYPE" == "linux-gnu" ]]; then
        xdg-open $VSC_URL
elif [[ "$OSTYPE" == "darwin"* ]]; then
        open $VSC_URL
else [[ "$OSTYPE" == "msys" ]]; # Git Bash on Windows 10
        start $VSC_URL
fi

echo -e "==========================================================================================================================\n"
echo -e "This session should now have opened your web browser. If it has failed to do so please open $VSC_URL in your browser."

# Inform user of certificate fingerprints

echo -e "==========================================================================================================================\n"
echo -e "Your server certificate has the following fingerprints: \n"
ssh -T $VSC_SSH_OPT <<GETCERT
openssl x509 -in ~/.ssl/vscoderemote/vscode_remote_ssl-server-cert.pem -fingerprint -sha256 -noout
openssl x509 -in ~/.ssl/vscoderemote/vscode_remote_ssl-server-cert.pem -fingerprint -sha1 -noout
GETCERT
echo -e "==========================================================================================================================\n"
echo -e "Please check your SSL fingerprints match those above, trust the certificate in browser and then login with your VSCode config password.\n"
echo -e "Your VSCode config password is: \n"
echo -e $VSCPASS
echo -e "\n"

###############################################################################
# Stop code-server on the cluster                                             #
###############################################################################

read -p "Please press enter to end the session, disconnect the SSH tunnel and terminate the job on the cluster."

# Kill the tunnel
kill $SSH_TUNNEL_PID

# Terminate the job on ShARC and remove the vscjid file.
ssh -T $VSC_SSH_OPT "qdel $VSC_REMOTE_JID && rm /home/$VSC_USERNAME/vscjid /home/$VSC_USERNAME/vscip /home/$VSC_USERNAME/vscport"
exit
