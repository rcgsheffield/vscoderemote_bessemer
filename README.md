
# VSCode Remote HPC

This script can be used to start a batch job on the cluster and then connect Microsoft VSCode to it. The script is inspired by the blog 

https://medium.com/@isaiah.taylor/use-vs-code-on-a-supercomputer-15e4cbbb1bc2

This version has been forked from the (much appreciated) original at https://gitlab.ethz.ch/sfux/VSCode_remote_HPC

## Requirements

### General requirements

The script assumes that you have setup SSH keys for passwordless access to the cluster. Please find some instructions on how to create SSH keys below:

https://www.digitalocean.com/community/tutorials/how-to-set-up-ssh-keys-on-ubuntu-22-04

Currently the script should run on Linux (tested on Ubuntu), Mac OS X (untested) and Windows (using WSL/WSL2  which has been tested with Ubuntu or git bash which is untested). 

When using a Linux computer, please make sure that ```xdg-open``` is available. This package is used to automatically start your default browser. You can install it with the command

CentOS:

```
yum install xdg-utils binutils ssh
```

Ubuntu:

```
apt-get install xdg-utils binutils ssh
```

You can either use the -k option of the script to specify the location of the SSH key, or even better use an SSH config file with the IdentityFile option by adding the following lines in your $HOME/.ssh/config file: 

```
 Host sharc.shef.ac.uk
 IdentityFile ~/.ssh/id_ed25519_sharc
```
or
```
 Host bessemer.shef.ac.uk
 IdentityFile ~/.ssh/id_ed25519_bessemer
```

### WSL requirements

If using WSL you may also need to set your ```DISPLAY``` variable prior to running the script in order to get X11 GUI forwarding working correctly (for automatic browser opening). e.g.

```
export DISPLAY=localhost:0
```

In addition, if you wish to leverage your existing Windows host machine's OpenSSH ssh-agent you can follow the instructions here: https://stuartleeks.com/posts/wsl-ssh-key-forward-to-windows/

## Preparation Steps 

### ShARC preperation (see below for [Bessemer preperation](###bessemer-preperation))

The preparation steps only need to be executed once. You need to carry out those steps to set up the basic configuration for your ShARC account with regards to the code-server.

Login to the ShARC cluster and start an interactive job with:

```
qrshx
```
Load the modules for one of the code-server installations:

```
module load apps/vscode-server/4.2.0/binary
```
[Jump to step Initiate code-server](###initiate-code--server)

### Bessemer preperation

The preparation steps only need to be executed once. You need to carry out those steps to set up the basic configuration for your Bessemer account with regards to the code-server.

Login to the Bessemer cluster and start an interactive job with:

```
srun --pty bash -i
```
Load the modules for one of the code-server installations:

```
module load vscode-server/4.2.0/binary
```
### Initiate code server

Start the code-server once with the command code-server

```
[te1st@bessemer.shef.ac.uk ~]$ code-server
[2022-04-04T10:01:45.407Z] info  code-server 4.2.0
[2022-04-04T10:01:45.409Z] info  Using user-data-dir ~/.local/share/code-server
[2022-04-04T10:01:45.433Z] info  Using config file ~/.config/code-server/config.yaml
[2022-04-04T10:01:45.433Z] info  HTTP server listening on http://127.0.0.1:8080
[2022-04-04T10:01:45.433Z] info    - Authentication is enabled
[2022-04-04T10:01:45.433Z] info      - Using password from ~/.config/code-server/config.yaml
[2022-04-04T10:01:45.433Z] info    - Not serving HTTPS
[te1st@bessemer.shef.ac.uk ~]$ 
```

This will setup the local configuration (including a password for you) and store it in your home directory in $HOME/.config/code-server/config.yaml

After the server has fully started, terminate it by pressing Ctrl+C .

Now you should generate your SSL certificates (these secure the communications between your local device and the endpoint worker node running the vscode server.)

```
setup_ssl_ca_server_client.sh
```



## Usage instructions

### Installation on your local machine

Download the repository with the command

```
git clone git@github.com:rcgsheffield/vscoderemote_sheffield_hpc.git
```

### Starting VSCode Remote server using a batch job on ShARC (see below for [Bessemer instructions](###starting-vscode-remote-server-using-a-batch-job-on-bessmer))

The start_vscode_sharc.sh script needs to be executed on your local computer but will spawn the VS Code remote server on a ShARC worker node. Please find below the list of options that can be used with the script:

```
$ ./start_vscode_sharc.sh --help
./start_vscode_sharc.sh: Script to start a VSCode remote server on ShARC from a local computer

Usage: start_vscode_sharc.sh [options]

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

        ./start_vscode_sharc.sh -u te1st -n 4 -W 04:00:00 -m 2048

        ./start_vscode_sharc.sh --username te1st --numcores 2 --runtime 01:30:00 --memory 2048

        ./start_vscode_sharc.sh -c /home/te1st/.vsc_config

Format of configuration file:

VSC_USERNAME=""             # TUoS username for SSH connection to ShARC
VSC_NUM_CPU=1               # Number of CPU cores to be used on the cluster
VSC_NUM_GPU=0               # Number of GPUs to be used on the cluster
VSC_RUN_TIME="01:00:00"     # Run time limit for the code-server in hours and minutes HH:MM:SS
VSC_MEM_PER_CPU_CORE=1024   # Memory limit in MB per core
VSC_WAITING_INTERVAL=60     # Time interval to check if the job on the cluster already started
VSC_SSH_KEY_PATH=""         # Path to SSH key with non-standard name
```

Once a session starts the code-server password is randomly regenerated and the new password will be supplied to you in the terminal alongside the SSL certificate fingerprints. Before clicking past the SSL warning (as the generated certificates are not trusted by default) check the fingerprints match in browser and in terminal.
[Jump to step - reconnect to a code server session](###-reconnect-to-a-code-server-session)


### Starting VSCode Remote server using a batch job on Bessemer

The start_vscode.sh script needs to be executed on your local computer but will spawn the VS Code remote server on a Bessemer worker node. Please find below the list of options that can be used with the script:

```
$ ./start_vscode_bessemer.sh --help
./start_vscode_bessemer.sh: Script to start a VSCode remote server on Bessemer from a local computer

Usage: start_vscode_bessemer.sh [options]

Options:

        -u | --username       USERNAME                  TUoS username for SSH connection to Bessemer
        -W | --runtime        RUN_TIME                  Run time limit for the code-server in hours and minutes HH:MM
        -n | --numcpus        NUM_CPUS_PER_TASK         Number of CPU cores per task     
        -m | --memory         MEM_PER_NODE              Memory limit in GB per node. (RAM) Ex. 4 cores *4G = 16 

Optional arguments:

        -c | --config         CONFIG_FILE               Configuration file for specifying options
        -g | --numgpu         NUM_GPU                   Number of GPUs to be used on the cluster
        -p | --partition      PARTITION_ID              Partition ID to be used (gpu or gpu-a100-tmp)
        -h | --help                                     Display help for this script and quit
        -i | --interval       INTERVAL                  Time interval for checking if the job on the cluster already started
        -k | --key            SSH_KEY_PATH              Path to SSH key with non-standard name
        -v | --version                                  Display version of the script and exit

Examples:

        ./start_vscode_bessemer.sh -u te1st -n 4 -W 04:00:00 -m 4

        ./start_vscode_bessemer.sh --username te1st --numcpus 2 --runtime 01:30:00 --memory 2

        ./start_vscode_bessemer.sh -c $HOME/.vsc_config

Format of configuration file:

VSC_USERNAME=""             # TUoS username for SSH connection to Bessemer
VSC_CPUS_PER_TASK=1         # Number of cpu cores per task
VSC_NUM_GPU=0               # Number of GPUs to be used on the cluster
VSC_RUN_TIME="01:00:00"     # Run time limit for the code-server in hours and minutes HH:MM:SS
VSC_MEM_PER_NODE=2          # Memory limit in GB per node. (RAM) Ex. 4 cores *4G = 16
VSC_WAITING_INTERVAL=60     # Time interval to check if the job on the cluster already started
VSC_SSH_KEY_PATH=""         # Path to SSH key with non-standard name
```

Once a session starts the code-server password is randomly regenerated and the new password will be supplied to you in the terminal alongside the SSL certificate fingerprints. Before clicking past the SSL warning (as the generated certificates are not trusted by default) check the fingerprints match in browser and in terminal

### Reconnect to a code-server session
When running the script, it creates a local file called reconnect_info in the installation directory, which contains all information regarding the used ports, the remote ip address, the command for the SSH tunnel and the URL for the browser. This information should be sufficient to reconnect to a code-server session if connection was lost.

## Cleanup after the job
Please note that when you finish working with the code-server, you need to terminate on the local machine by pressing the enter key so the script can terminate the job on the cluster as well as stop the SSH tunnel from your local machine.


## Main author
* Samuel Fux

## Contributions
* Andreas Lugmayr
* James Moore
* Nicholas Musembi
* Carl Kennedy
