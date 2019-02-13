#!/usr/bin/env bash

set -eo pipefail

function build_rippled_target(){
    if [[ $# -ne 2 ]]; then
        echo "Error: call to ${FUNCNAME[0]} must specify rippled_proj_dir and build_target. Got: ${*}" >&2
        exit 1
    fi

    local rippled_proj_dir=${1}; shift
    local build_target=${1}; shift
    local num_jobs
    num_jobs=$(lscpu -p | grep -v '^#' | sort -u -t, -k 2,4 | wc -l) # pysical cores
    pushd "${rippled_proj_dir}"

    local ccache_arg
    if hash ccache &>/dev/null; then
        # use ccache
        ccache_arg=(-DCMAKE_CXX_COMPILER_LAUNCHER=ccache -DCMAKE_C_COMPILER_LAUNCHER=ccache)
    fi
    local cmake_build_dir=build/${build_target}
    if [[ ! -e ${cmake_build_dir} ]]; then
        # create the directory and run cmake
        mkdir -p ${cmake_build_dir}
        pushd ${cmake_build_dir}
        cmake ${ccache_arg} -DCMAKE_EXPORT_COMPILE_COMMANDS=1 -Dtarget=${build_target} -GNinja ../..
        popd
    fi
    pushd ${cmake_build_dir}
    ninja -j${num_jobs} |& tee compile_log.txt
    local result=${PIPESTATUS[0]}
    popd

    popd
    return ${result}
}

function run_rippled_target(){
    if [[ $# -lt 2 ]]; then
        echo "Error: call to ${FUNCNAME[0]} must specify rippled_proj_dir and build_target. Got: ${*}" >&2
        exit 1
    fi

    local rippled_proj_dir="${1}"; shift
    local build_target="${1}"; shift
    local num_jobs
    pushd "${rippled_proj_dir}"

    local cmake_build_dir=build/${build_target}
    local exe_name="${cmake_build_dir}"/rippled
    if [[ ! -x "${exe_name}" ]]; then
        echo "Error: ${FUNCNAME[0]}: ${exe_name} executable not found" >&2
        exit 1
    fi

    pushd ${cmake_build_dir}
    set +eo pipefail
    ./rippled "${@}" |& tee log_${RANDOM}.txt
    local result=${PIPESTATUS[0]}
    if [[ ${result} != 0 && -n ${core_directory} ]]; then
        cp core* ${core_directory}/.
    fi
    set -eo pipefail
    popd # ${cmake_build_dir}

    popd # ${rippled_proj_dir}
    return ${result}
}

function usage(){
    cat <<EOF >&2
    Usage: ${BASH_SOURCE[0]} [options] <command> <rippled_proj_dir> <build_target>
    Valid commands are: build run
    Valid options are:
     -c core_directory : directory to put cores (so may be saved on a volume)
EOF
}


while getopts ":c:" opt; do
    case ${opt} in
        c)
            core_directory=$(realpath "${OPTARG}")
            shift;shift
            ;;
        \?)
            echo "Invalid option -$OPTARG" >&2
            usage
            exit 1
            ;;
    esac
done

if [[ $# -lt 3 ]]; then
    script_name=$(basename "${BASH_SOURCE[0]}")
    echo "Error: call to ${script_name} must specify command rippled_proj_dir and build_target. Got: ${*}" >&2
    exit 1
fi

command="${1}"; shift
case "${command}" in
    build)
        build_rippled_target "${@}"
        ;;
    run)
        run_rippled_target "${@}"
        ;;
    *)
        echo "Invalid command: ${command}" >&2
        usage
        exit 1
        ;;
esac
