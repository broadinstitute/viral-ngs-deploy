#!/bin/bash

SELF_UPDATE_URL="https://raw.githubusercontent.com/broadinstitute/viral-ngs-deploy/master/easy-dsub/easy-dsub.sh"

STARTING_DIR=$(pwd)

function absolute_path() {
    local SOURCE="$1"
    while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
        DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
        if [[ "$OSTYPE" == "darwin"* ]]; then
            SOURCE="$(readlink "$SOURCE")"
        else
            SOURCE="$(readlink -f "$SOURCE")"
        fi
        [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
    done
    echo "$SOURCE"
}
SOURCE="${BASH_SOURCE[0]}"
SCRIPT=$(absolute_path "$SOURCE")
SCRIPT_DIRNAME="$(dirname "$SOURCE")"
SCRIPTPATH="$(cd -P "$(echo $SCRIPT_DIRNAME)" &> /dev/null && pwd)"
SCRIPT="$SCRIPTPATH/$(basename "$SCRIPT")"

CONDA_PREFIX_LENGTH_LIMIT=250

CONTAINING_DIR="dsub_related"
CONDA_ENV_BASENAME="conda-env"
CONDA_ENV_CACHE="conda-cache"
MINICONDA_DIR="mc3"

INSTALL_PATH="$SCRIPTPATH/$CONTAINING_DIR"
INSTALL_PATH=$(absolute_path "$INSTALL_PATH")

CONDA_ENV_PATH="$INSTALL_PATH/$CONDA_ENV_BASENAME"
MINICONDA_PATH="$INSTALL_PATH/$MINICONDA_DIR"

# determine if this script has been sourced
# via: http://stackoverflow.com/a/28776166/2328433
([[ -n $ZSH_EVAL_CONTEXT && $ZSH_EVAL_CONTEXT =~ :file$ ]] ||
 [[ -n $KSH_VERSION && $(cd "$(dirname -- "$0")" &&
    printf '%s' "${PWD%/}/")$(basename -- "$0") != "${.sh.file}" ]] ||
 [[ -n $BASH_VERSION && $0 != "$BASH_SOURCE" ]]) && sourced=1 || sourced=0

current_prefix_length=$(echo $MINICONDA_PATH | wc -c | sed -n '1h;1!H;${;g;s/^[ \t]*//g;s/[ \t]*$//g;p;}') # sed trims whitespace
if [ $current_prefix_length -ge $CONDA_PREFIX_LENGTH_LIMIT ]; then
    echo "ERROR: The conda path to be created by this script is too long to work with conda ($current_prefix_length characters):"
    echo "$MINICONDA_PATH"
    echo "This is a known bug in conda ($CONDA_PREFIX_LENGTH_LIMIT character limit): "
    echo "https://github.com/conda/conda-build/pull/877"
    echo "To prevent this error, move this script higher in the filesystem hierarchy."
    exit 80
fi

python_check=$(hash python)
if [ $? -ne 0 ]; then
    echo "It looks like Python is not installed. Exiting."
    if [[ $sourced -eq 0 ]]; then
        exit 1
    else
        return 1
    fi
fi

ram_check=$(python -c "bytearray(768000000)" &> /dev/null)
if [ $? -ne 0 ]; then
    echo ""
    echo "Unable to allocate 768MB."
    echo "=============================================================="
    echo "It appears your current system does not have enough free RAM."
    echo "Consider logging in to a machine with more available memory."
    echo "=============================================================="
    echo ""

    if [[ $sourced -eq 0 ]]; then
        exit 1
    else
        return 1
    fi
fi

function prepend_miniconda(){
    if [ -f "$MINICONDA_PATH/bin/conda" ]; then
        echo "Miniconda installed."

        echo "Prepending miniconda to PATH..."
        if [[ "$PATH" != *"$MINICONDA_PATH/bin"* ]]; then
            export PATH="$MINICONDA_PATH/bin:$PATH"
            hash -r
        else
            echo "It appears the dsub miniconda is already on the path."
        fi
    else
        echo "Miniconda directory not found. Have you run \"$0 setup\"?"
        if [[ $sourced -eq 0 ]]; then
            exit 1
        else
            return 1
        fi
    fi
}

function install_and_prepend_miniconda(){
    if [ -d "$MINICONDA_PATH/bin" ]; then
        echo "Miniconda directory exists."
    else
        echo "Downloading and installing Miniconda..."

        mkdir -p "$INSTALL_PATH"

        if [[ "$(python -c 'import os; print(os.uname()[0])')" == "Darwin" ]]; then
            miniconda_url=https://repo.continuum.io/miniconda/Miniconda2-latest-MacOSX-x86_64.sh
            curl -s $miniconda_url -o "$INSTALL_PATH/Miniconda2-latest-x86_64.sh"
        else
            miniconda_url=https://repo.continuum.io/miniconda/Miniconda2-latest-Linux-x86_64.sh
            wget -q $miniconda_url -O "$INSTALL_PATH/Miniconda2-latest-x86_64.sh"
        fi
        chmod +x "$INSTALL_PATH/Miniconda2-latest-x86_64.sh"
        "$INSTALL_PATH/Miniconda2-latest-x86_64.sh" -b -f -p "$MINICONDA_PATH"

        rm "$INSTALL_PATH/Miniconda2-latest-x86_64.sh"
    fi

    if [ -d "$MINICONDA_PATH/bin" ]; then
        prepend_miniconda
    else
        echo "It looks like the Miniconda installation failed"
        if [[ $sourced -eq 0 ]]; then
            exit 1
        else
            return 1
        fi
    fi
}

function activate_env(){
    if [ -d "$INSTALL_PATH" ]; then
        echo "viral-ngs-dsub parent directory found"
    else
        echo "viral-ngs-dsub parent directory not found: $INSTALL_PATH not found."
        echo "Have you run the setup?"
        echo "Usage: $0 setup"
        cd $STARTING_DIR
        return 1
    fi

    if [ -d "$CONDA_ENV_PATH" ]; then
        if [ -z "$CONDA_DEFAULT_ENV" ]; then
            echo "Activating viral-ngs environment..."
            prepend_miniconda

            source activate $CONDA_ENV_PATH

            # unset JAVA_HOME if set, so we can use the conda-supplied version
            if [ ! -z "$JAVA_HOME" ]; then
                unset JAVA_HOME
            fi

            # override $PS1 to have a shorter prompt
            export PS1="(\[\033[1m\]viral-ngs-dsub\[\033[0m\])\s:\h:\w \! \$ "
        else
            if [[ "$CONDA_DEFAULT_ENV" != "$CONDA_ENV_PATH" ]]; then
                echo "It looks like a conda environment is already active,"
                echo "however it is not the viral-ngs environment."
                echo "To use viral-ngs-dsub with your project, deactivate the"
                echo "current environment and then source this file."
                echo "Example: source deactivate && source $(basename $SCRIPT) load"
            else
                echo "The viral-ngs-dsub environment is already active."
            fi
            return 0
        fi
    else
        echo "$CONDA_ENV_PATH/ does not exist. Exiting."
        cd $STARTING_DIR
        if [[ $sourced -eq 0 ]]; then
            exit 1
        else
            return 1
        fi
    fi
}

function updateSelf() {
  # this function overwrites this script with one downloaded from
  # the first argument passed to the funciton, $1

  echo "Performing self-update..."

  cp "$SCRIPT" "$SCRIPT.bak"

  # Download new version
  echo -n "Downloading latest version..."
  if ! wget --quiet --output-document="$SCRIPT.tmp" "$1" ; then
    if ! curl -s "$1" -o "$SCRIPT.tmp" ; then
      echo "Error while trying to wget new version!"
      echo "File requested: $SELF_UPDATE_URL"
      exit 1
    fi
  fi
  echo "done."

  # Copy permissions from old version
  if [[ "$OSTYPE" == "darwin"* ]]; then
      OCTAL_MODE=$(stat -f '%A' $SCRIPT)
  else
      OCTAL_MODE=$(stat -c '%a' $SCRIPT)
  fi
  if ! chmod $OCTAL_MODE "$SCRIPT.tmp" ; then
    echo "Failed: Error while trying to set mode on $SCRIPT.tmp."
    exit 1
  fi

  # Spawn update script
  cat > update-script.sh << EOF
#!/bin/bash
# Overwrite old file with new
if mv "$SCRIPT.tmp" "$SCRIPT"; then
  echo "done."
  echo "Self-update complete."
  rm \$0
else
  echo "Failed!"
fi
EOF

  echo -n "Overwriting old script with new one..."
  exec /bin/bash update-script.sh
}

# =================
# dsub-specific
# =================

DEFAULT_MIN_RAM="16"
DEFAULT_NUM_CORES="4"
DEFAULT_DISK_SIZE="250"

function print_usage(){
    if [[ "$1" == "1" ]]; then
        echo "Usage: $(absolute_path $0) run gs://bucket-name/path/to/project [command and arguments]"
        echo "  The environment variables may be set to avoid prompts:"
        echo "    - 'GATK_BUCKET_PATH' the gs:// path containing GenomeAnalysisTK.jar "
        echo "    - 'NOVOALIGN_BUCKET_PATH' the gs:// path containing novoalign binaries"
        echo "    - 'MIN_RAM' the amount of RAM to be allocated to the compute instance [$DEFAULT_MIN_RAM]GB"
        echo "    - 'NUM_CORES' the number of compute cores on the instance [$DEFAULT_NUM_CORES]"
        echo "    - 'DISK_SIZE' storage allocated to hold the project directory [$DEFAULT_DISK_SIZE]GB"
        echo "    - 'GCLOUD_PROJECT_NAME' the Google Cloud Platform project name under which the job should run"
    elif [[ "$1" == "2" ]]; then
        echo "Usage: $(absolute_path $0) init-project gs://bucket-name/path/to/project"
    elif [[ "$1" == "3" ]]; then
        echo "Usage: $(absolute_path $0) rsync [gs://bucket-name/]source_path [gs://bucket-name/]dest_path"
        echo "  makes the contents under dest_path the same as the contents under source_path, by copying any "
        echo "  missing files/objects (or those whose data has changed). One of the two paths must be a gs:// bucket path."
    else
        echo "Usage: $(absolute_path $0) {run,init-project,rsync,update-self,setup,load}" 
    fi
}

function check_gcloud_auth(){
    if ! gsutil ls > /dev/null; then
        gcloud init
    fi
}

# check if we are running on a dsub host
curl "metadata.google.internal" &> /dev/null
case $? in
    (0) echo "On a GCE instance; running job..."
        echo "Running command... $@"
        echo "Starting time: $(date)"

        #echo "INPUT_PATH:  $INPUT_PATH"
        #echo "OUTPUT_PATH: $OUTPUT_PATH"

        OMIT_UGER_PROJECT_FILES=true
        #SKIP_SELF_UPDATE_CONFIRM=true
        #/opt/viral-ngs/easy-deploy-viral-ngs.sh update-easy-deploy
        /opt/viral-ngs/easy-deploy-viral-ngs.sh create-project $(basename $INPUT_PATH) $(dirname $INPUT_PATH)
        pushd $INPUT_PATH > /dev/null

        $SCRIPT_ARGS
        #snakemake "$SCRIPT_ARGS"

        mv $INPUT_PATH/* $OUTPUT_PATH

        popd > /dev/null
        echo "Completion time: $(date)"
    ;;
    (*) 
        
        if [[ "$1" == "run" ]]; then
            shift

            prepend_miniconda
            activate_env
            which gsutil > /dev/null || echo "gsutil is not available. Have you run \"$0 setup\" and \"$0 load\"?"
            check_gcloud_auth

            if [ $# -lt 1 ]; then
                print_usage 1 && exit 1
            elif [[ "$1" != "gs://"* ]]; then
                echo "First argument must be a GCS bucket in the form 'gs://bucket-name/path/to/project'"
                print_usage 1 && exit 1
            elif [[ "$1" == "gs://"* ]]; then
                PROJECT_BUCKET_PATH="$1"
                shift 1
            else
                print_usage 1 && exit 1
            fi

            while [[ -z "$GATK_BUCKET_PATH" ]] || [[ "$GATK_BUCKET_PATH" != "gs://"* ]]; do 
                read -ep "Required: What is the gs:// path containing GATK? " GATK_BUCKET_PATH
            done

            while [[ -z "$NOVOALIGN_BUCKET_PATH" ]] || [[ "$NOVOALIGN_BUCKET_PATH" != "gs://"* ]]; do 
                read -ep "Required: What is the gs:// path containing the Novoalign binaries? " NOVOALIGN_BUCKET_PATH
            done

            while [[ -z "$GCLOUD_PROJECT_NAME" ]]; do 
                if [ -f ~/.boto ]; then
                    boto_default_proj="$(printf '%s' $(cat ~/.boto | grep -e '^default_project_id' | cut -d\= -f 2))"
                    read -ep "Required: What is the name of the GCloud project to run this under [$boto_default_proj]? " GCLOUD_PROJECT_NAME
                    if [[ ! -z "$boto_default_proj" ]] && [[ -z "$GCLOUD_PROJECT_NAME" ]]; then
                        GCLOUD_PROJECT_NAME=$boto_default_proj
                    fi
                else
                    read -ep "Required: What is the name of the GCloud project to run this under? " GCLOUD_PROJECT_NAME
                fi
            done

            while [[ -z "$MIN_RAM" ]]; do 
                read -ep "How much RAM (in GB) should be allocated to the compute instance? [$DEFAULT_MIN_RAM] " MIN_RAM
                if [[ -z "$MIN_RAM" ]]; then
                    MIN_RAM=$DEFAULT_MIN_RAM
                fi
            done

            while [[ -z "$NUM_CORES" ]]; do 
                read -ep "How many cores should be allocated to the compute instance? [$DEFAULT_NUM_CORES] " NUM_CORES
                if [[ -z "$NUM_CORES" ]]; then
                    NUM_CORES=$DEFAULT_NUM_CORES
                fi
            done

            while [[ -z "$DISK_SIZE" ]]; do 
                read -ep "How much space should be allocated to hold the project directory? [$DEFAULT_DISK_SIZE] " DISK_SIZE
                if [[ -z "$DISK_SIZE" ]]; then
                    DISK_SIZE=$DEFAULT_DISK_SIZE
                fi
            done

            echo "GATK_BUCKET_PATH is: $GATK_BUCKET_PATH"
            echo "NOVOALIGN_BUCKET_PATH is: $NOVOALIGN_BUCKET_PATH"
            echo "GCLOUD_PROJECT_NAME is: $GCLOUD_PROJECT_NAME"
            echo "MIN_RAM is: $MIN_RAM"
            echo "NUM_CORES is: $NUM_CORES"
            echo "DISK_SIZE is: $DISK_SIZE"

            latest_viral_ngs="$(curl -s https://registry.hub.docker.com/v1/repositories/broadinstitute/viral-ngs/tags | sed -e 's/[][]//g' -e 's/\"//g' -e 's/ //g' | tr '}' '\n'  | awk -F: '{print $3}' | grep '.' | tail -n 1)"
            echo "Using viral-ngs version $latest_viral_ngs"
            echo "Called locally; submitting job via dsub"

            if [ $# -gt 0 ]; then
                echo "With arguments: $@"
                script_args="--env SCRIPT_ARGS=\"$@\""
            fi
            dsub --project $GCLOUD_PROJECT_NAME \
                --zones "us-east4-*" \
                --logging $PROJECT_BUCKET_PATH/logs \
                --image broadinstitute/viral-ngs:"$latest_viral_ngs" \
                --input-recursive INPUT_PATH=$PROJECT_BUCKET_PATH \
                --output-recursive OUTPUT_PATH=$PROJECT_BUCKET_PATH \
                --input-recursive GATK_PATH=$GATK_BUCKET_PATH \
                --input-recursive NOVOALIGN_PATH=$NOVOALIGN_BUCKET_PATH \
                --min-ram $MIN_RAM \
                --min-cores $NUM_CORES\
                --disk-size $DISK_SIZE \
                --boot-disk-size 20 \
                --script "$(absolute_path $0)" $script_args

                echo "In order to run dsub commands directly you must \"source $0 load\""
        elif [[ "$1" == "init-project" ]]; then
            shift

            if [ $# -lt 1 ]; then
                print_usage 2 && exit 1
            elif [[ "$1" != "gs://"* ]]; then
                echo "First argument must be a GCS bucket in the form 'gs://bucket-name/path/to/project'"
                print_usage 2 && exit 1
            elif [[ "$1" == "gs://"* ]]; then
                PROJECT_BUCKET_PATH="$1"
                shift 1
            else
                print_usage 2 && exit 1
            fi

            echo "Creating project: $PROJECT_BUCKET_PATH"
            GATK_BUCKET_PATH=$PROJECT_BUCKET_PATH \
                NOVOALIGN_BUCKET_PATH=$PROJECT_BUCKET_PATH \
                MIN_RAM=4 \
                NUM_CORES=2 \
                DISK_SIZE=50 \
                $(absolute_path $0) run $PROJECT_BUCKET_PATH

        elif [[ "$1" == "rsync" ]]; then
            shift

            prepend_miniconda
            activate_env
            which gsutil > /dev/null || echo "gsutil is not available. Have you run \"$0 setup\" and \"$0 load\"?"
            check_gcloud_auth

            if [ $# -ne 2 ]; then
                print_usage 3 && exit 1
            elif [[ "$1" == "gs://"* ]] || [[ "$2" == "gs://"* ]]; then
                gsutil rsync -rc "$1" "$2"
            else 
                echo "The source or destination must be a bucket in the form 'gs://bucket-name/path/to/data'"
                print_usage 3 && exit 1
            fi
        elif [[ "$1" == "update-self" ]]; then
            shift
            if [ $# -eq 0 ]; then
                if [[ $sourced -eq 1 ]]; then
                    echo "ABORTING. $(basename $SCRIPT) must not be sourced during upgrade"
                    echo "Usage: $(basename $SCRIPT) update-self"
                    return 1
                else
                    if [ -z "$CONDA_DEFAULT_ENV" ]; then
                        if [ ! -z "$SKIP_SELF_UPDATE_CONFIRM" ] || $(ask "Are you sure you want to update this script to the latest version?" Y); then
                            updateSelf "$SELF_UPDATE_URL"
                        fi
                    else
                        echo "It looks like a conda environment is active."
                        echo "To update this script, first deactivate the environment"
                        echo "then call update-easy-deploy. Example:"
                        echo "  source deactivate && $(basename $SCRIPT) update-self"
                        exit 1
                    fi

                fi
            else
                echo "Usage: source $(basename $SCRIPT) update-self"
                if [[ $sourced -eq 0 ]]; then
                    exit 1
                else
                    return 1
                fi
            fi
        elif [[ "$1" == "setup" ]]; then
            shift
            install_and_prepend_miniconda


            if [ ! -d "$CONDA_ENV_PATH" ]; then
                conda create -c broad-viral -c r -c bioconda -c conda-forge -c defaults --override-channels -y -p "$CONDA_ENV_PATH" python=2 || exit 1
            fi

            activate_env

            # $(which gsutil)
            conda install -q -y -c broad-viral -c r -c bioconda -c conda-forge -c defaults google-cloud-sdk
            # $(which git)
            conda install -q -y -c broad-viral -c r -c bioconda -c conda-forge -c defaults git

            pushd "$CONTAINING_DIR" > /dev/null
            git clone https://github.com/googlegenomics/dsub
            pushd dsub > /dev/null
            python setup.py install
            popd > /dev/null
            rm -rf dsub/
            hash -r
            popd > /dev/null

        elif [[ "$1" == "load" ]]; then
            shift
            if [ $# -eq 0 ]; then
                if [[ $sourced -eq 0 ]]; then
                    echo "ABORTING. $(basename $SCRIPT) must be sourced."
                    echo "Usage: source $(basename $SCRIPT) load"
                else
                    install_and_prepend_miniconda
                    activate_env
                    return 0
                fi
            else
                echo "Usage: source $(basename $SCRIPT) load"
                if [[ $sourced -eq 0 ]]; then
                    exit 1
                else
                    return 1
                fi
            fi
            
        else
            print_usage
        fi
    ;;
esac
exit
