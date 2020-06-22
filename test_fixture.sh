#!/bin/sh

set -e

fail () {
    echo "$0[$testcase]: $*" >&2
    exit 10
}

capture_command () {
    local _status=$1 _stdout=$2 _stderr=$3
    shift 3

    local _stdoutf=$(mktemp -t stdout.XXXXXX)
    local _stderrf=$(mktemp -t stderr.XXXXXX)

    set +e
    (
        set -e
        "$@" 1>"$_stdoutf" 2>"$_stderrf"
    )

    eval $_status=\$?
    if [ "x$_stdout" = x- ]; then
        cat "$_stdoutf"
    else
        eval $_stdout="\$(cat "$_stdoutf")"
    fi
    if [ "x$_stderr" = x- ]; then
        cat "$_stderrf" >&2
    else
        eval $_stderr="\$(cat "$_stderrf")"
    fi
    rm -f "$_stdoutf" "$_stderrf"
    set -e
}

expect_fail () {
    local expected=$1
    shift

    local status stdout stderr
    capture_command status stdout stderr "$@"
    if [ $status -eq 0 ]; then
        echo "STDOUT: $stdout"
        echo "STDERR: $stderr"
        fail "expected command to fail, but it succeeded: $*"
    elif [ $status -ne $expected ]; then
        echo "STDOUT: $stdout"
        echo "STDERR: $stderr"
        fail "expected command to fail with $expected, but it failed with $status: $*"
    fi
}

expect_success () {
    local status stdout stderr
    capture_command status stdout stderr "$@"
    if [ $status -ne 0 ]; then
        echo "STDOUT: $stdout"
        echo "STDERR: $stderr"
        fail "command failed with $status: $*"
    fi
}

mock_prog () {
    (
        cat <<EOF
#!${SHELL:-/bin/sh}
set -e
args="\$*"
progname="mock/\$(basename "\$0")"
matched=
checkstatus=0
expect () {
    if [ -n "\$TEST_CHECK_MOCK" ]; then
        if ! egrep -q '^#got '"\$*"'\$' <"\$0"; then
            echo "\$progname: failed expectation: \$*" >&2
            checkstatus=10
        fi
        return
    fi
    matched=
    if echo "\$args" | egrep -q '^'"\$*"'\$'; then
        matched=1
    fi
}
default () {
    [ -n "\$TEST_CHECK_MOCK" ] || matched=1
}
is_matched () {
    [ -n "\$matched" ]
}
stdout () {
    ! is_matched || cat
}
stderr () {
    ! is_matched || cat >&2
}
status () {
    ! is_matched || exit \$1
}
if [ -z "\$TEST_CHECK_MOCK" ]; then
    echo "#got \$*" >>"\$0"
fi
EOF
        cat
        cat <<EOF
if [ -z "\$TEST_CHECK_MOCK" ]; then
    echo "\$progname: uncaught mock case: \$args" >&2
    exit 13
fi
exit \$checkstatus
EOF
    ) >"$tmpd/mockbin/$1"

    chmod 755 "$tmpd/mockbin/$1"
}

check_mock_prog () {
    TEST_CHECK_MOCK=1 "$1"
}

check_mock_progs () {
    local status status2
    for prog in "$tmpd/mockbin"/*; do
        capture_command status - - check_mock_prog "$prog"
        if [ $status -ne 0 ]; then
            status2=$status
        fi
    done

    if [ -n "$status2" ]; then
        return $status2
    fi
}

run_test () {
    local tmpd=$(mktemp -d -t addusergroup_test.XXXXXX)
    trap "rm -fr '$tmpd'" EXIT

    echo "RUN  $1"

    (
        mkdir "$tmpd/mockbin"

        testcase=$1
        export TMPDIR="$tmpd"
        export PATH="$tmpd/mockbin${PATH:+:$PATH}"

        local status
        capture_command status - - "$@"

        if [ $status -eq 0 ]; then
            capture_command status - - check_mock_progs
        fi
        if [ $status -eq 0 ]; then
            echo "OK   $1"
        else
            echo "FAIL $1"
            return 10
        fi
    )
}

run_tests () {
    set -e

    local testcases="$(egrep 'test_.+ \(\) \{' <"$0" | cut -d' ' -f1)"
    local failed status

    cd "$(dirname "$0")"

    for testcase in $testcases; do
        capture_command status - - run_test "$testcase"
        if [ $status -ne 0 ]; then
            failed=1
        fi
    done

    [ -z "$failed" ] || return 10
}
