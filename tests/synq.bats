@test "should display help when no arguments are provided" {
    run ./synq
    [ "$status" -eq 0 ]
    local snapshot="tests/snapshots/help.snapshot"
    echo "$output" | diff -u "$snapshot" -
}

@test "should display help with --help flag" {
    run ./synq --help
    [ "$status" -eq 0 ]
    local snapshot="tests/snapshots/help.snapshot"
    echo "$output" | diff -u "$snapshot" -
}

@test "should display help with -h flag" {
    run ./synq -h
    [ "$status" -eq 0 ]
    local snapshot="tests/snapshots/help.snapshot"
    echo "$output" | diff -u "$snapshot" -
}

@test "should display version with --version flag" {
    run ./synq --version
    [ "$status" -eq 0 ]
    local snapshot="tests/snapshots/version.snapshot"
    # echo "$output" | diff -u "$snapshot" -
    [[ "$output" == "synq version"* ]]
}

@test "should fail with unknown option" {
    run ./synq --unknown
    [ "$status" -eq 1 ]
    [ "${#lines[@]}" -eq 2 ]
    [ "${lines[0]}" = "Error: unknown flag: --unknown" ]
    [ "${lines[1]}" = "unknown flag: --unknown" ]
}

@test "should run with configuration file" {

    local tmp_dir="/tmp"
    setup() {
        # Setup: Create directories and files
        mkdir -p $tmp_dir/test/src1 $tmp_dir/test/dest1 $tmp_dir/test/src2 $tmp_dir/test/dest2
        echo "src1:file1" > $tmp_dir/test/src1/file1.txt
        echo "src1:file2" > $tmp_dir/test/src1/file2.txt
        echo "src2:file1" > $tmp_dir/test/src2/file1.txt
        echo "src2:file2" > $tmp_dir/test/src2/file2.txt

        # Verify setup
        [ -d $tmp_dir/test/src1 ]
        [ -d $tmp_dir/test/src2 ]
        [ -d $tmp_dir/test/dest1 ]
        [ -d $tmp_dir/test/dest2 ]
        [ -f $tmp_dir/test/src1/file1.txt ]
        [ -f $tmp_dir/test/src1/file2.txt ]
        [ -f $tmp_dir/test/src2/file1.txt ]
        [ -f $tmp_dir/test/src2/file2.txt ]
    }

    teardown() {
        # Cleanup: Remove directories and files
        rm -rf $tmp_dir/test
        # Verify cleanup
        [ ! -d $tmp_dir/test ]
    }


    setup
    run ./synq --config tests/synq.test1.yml -y
    [ "$status" -eq 0 ]
    [ -f $tmp_dir/test/dest1/file1.txt ]
    [ -f $tmp_dir/test/dest1/file2.txt ]
    [ -f $tmp_dir/test/dest2/file1.txt ]
    [ -f $tmp_dir/test/dest2/file2.txt ]
    diff $tmp_dir/test/src1/file1.txt $tmp_dir/test/dest1/file1.txt
    diff $tmp_dir/test/src1/file2.txt $tmp_dir/test/dest1/file2.txt
    diff $tmp_dir/test/src2/file1.txt $tmp_dir/test/dest2/file1.txt
    diff $tmp_dir/test/src2/file2.txt $tmp_dir/test/dest2/file2.txt

    teardown
}

@test "should run with configuration file with dry-run" {

    local tmp_dir="/tmp"
    setup() {
        # Setup: Create directories and files
        mkdir -p $tmp_dir/test/src1 $tmp_dir/test/dest1 $tmp_dir/test/src2 $tmp_dir/test/dest2
        echo "src1:file1" > $tmp_dir/test/src1/file1.txt
        echo "src1:file2" > $tmp_dir/test/src1/file2.txt
        echo "src2:file1" > $tmp_dir/test/src2/file1.txt
        echo "src2:file2" > $tmp_dir/test/src2/file2.txt

        # Verify setup
        [ -d $tmp_dir/test/src1 ]
        [ -d $tmp_dir/test/src2 ]
        [ -d $tmp_dir/test/dest1 ]
        [ -d $tmp_dir/test/dest2 ]
        [ -f $tmp_dir/test/src1/file1.txt ]
        [ -f $tmp_dir/test/src1/file2.txt ]
        [ -f $tmp_dir/test/src2/file1.txt ]
        [ -f $tmp_dir/test/src2/file2.txt ]
    }

    teardown() {
        # Cleanup: Remove directories and files
        rm -rf $tmp_dir/test
        # Verify cleanup
        [ ! -d $tmp_dir/test ]
    }


    setup
    run ./synq --config tests/synq.test1.yml -y --dry-run
    [ "$(echo "$output" | grep -c "(DRY RUN)")" -eq 2 ]
    [ "$status" -eq 0 ]
    [ ! -f $tmp_dir/test/dest1/file1.txt ]
    [ ! -f $tmp_dir/test/dest1/file2.txt ]
    [ ! -f $tmp_dir/test/dest2/file1.txt ]
    [ ! -f $tmp_dir/test/dest2/file2.txt ]

    teardown
}

@test "should run with configuration file and specific bucket" {

    local tmp_dir="/tmp"
    setup() {
        # Setup: Create directories and files
        mkdir -p $tmp_dir/test/src1 $tmp_dir/test/dest1 $tmp_dir/test/src2 $tmp_dir/test/dest2
        echo "src1:file1" > $tmp_dir/test/src1/file1.txt
        echo "src1:file2" > $tmp_dir/test/src1/file2.txt
        echo "src2:file1" > $tmp_dir/test/src2/file1.txt
        echo "src2:file2" > $tmp_dir/test/src2/file2.txt

        # Verify setup
        [ -d $tmp_dir/test/src1 ]
        [ -d $tmp_dir/test/src2 ]
        [ -d $tmp_dir/test/dest1 ]
        [ -d $tmp_dir/test/dest2 ]
        [ -f $tmp_dir/test/src1/file1.txt ]
        [ -f $tmp_dir/test/src1/file2.txt ]
        [ -f $tmp_dir/test/src2/file1.txt ]
        [ -f $tmp_dir/test/src2/file2.txt ]
    }

    teardown() {
        # Cleanup: Remove directories and files
        rm -rf $tmp_dir/test
        # Verify cleanup
        [ ! -d $tmp_dir/test ]
    }


    setup
    run ./synq --config tests/synq.test1.yml -y bucket1
    [ "$status" -eq 0 ]

    [ -f $tmp_dir/test/dest1/file1.txt ]
    [ -f $tmp_dir/test/dest1/file2.txt ]
    [ ! -f $tmp_dir/test/dest2/file1.txt ]
    [ ! -f $tmp_dir/test/dest2/file2.txt ]
    diff $tmp_dir/test/src1/file1.txt $tmp_dir/test/dest1/file1.txt
    diff $tmp_dir/test/src1/file2.txt $tmp_dir/test/dest1/file2.txt

    teardown
}

@test "should run with configuration file and specific bucket with dry-run" {

    local tmp_dir="/tmp"
    setup() {
        # Setup: Create directories and files
        mkdir -p $tmp_dir/test/src1 $tmp_dir/test/dest1 $tmp_dir/test/src2 $tmp_dir/test/dest2
        echo "src1:file1" > $tmp_dir/test/src1/file1.txt
        echo "src1:file2" > $tmp_dir/test/src1/file2.txt
        echo "src2:file1" > $tmp_dir/test/src2/file1.txt
        echo "src2:file2" > $tmp_dir/test/src2/file2.txt

        # Verify setup
        [ -d $tmp_dir/test/src1 ]
        [ -d $tmp_dir/test/src2 ]
        [ -d $tmp_dir/test/dest1 ]
        [ -d $tmp_dir/test/dest2 ]
        [ -f $tmp_dir/test/src1/file1.txt ]
        [ -f $tmp_dir/test/src1/file2.txt ]
        [ -f $tmp_dir/test/src2/file1.txt ]
        [ -f $tmp_dir/test/src2/file2.txt ]
    }

    teardown() {
        # Cleanup: Remove directories and files
        rm -rf $tmp_dir/test
        # Verify cleanup
        [ ! -d $tmp_dir/test ]
    }


    setup
    run ./synq --config tests/synq.test1.yml -y --dry-run bucket1 
    [ "$status" -eq 0 ]
    [ "$(echo "$output" | grep -c "(DRY RUN)")" -eq 1 ]

    [ ! -f $tmp_dir/test/dest1/file1.txt ]
    [ ! -f $tmp_dir/test/dest1/file2.txt ]
    [ ! -f $tmp_dir/test/dest2/file1.txt ]
    [ ! -f $tmp_dir/test/dest2/file2.txt ]

    teardown
}

@test "should run with configuration file and specific bucket and unconfigured bucket be ignored" {

    local tmp_dir="/tmp"
    setup() {
        # Setup: Create directories and files
        mkdir -p $tmp_dir/test/src1 $tmp_dir/test/dest1 $tmp_dir/test/src2 $tmp_dir/test/dest2
        echo "src1:file1" > $tmp_dir/test/src1/file1.txt
        echo "src1:file2" > $tmp_dir/test/src1/file2.txt
        echo "src2:file1" > $tmp_dir/test/src2/file1.txt
        echo "src2:file2" > $tmp_dir/test/src2/file2.txt

        # Verify setup
        [ -d $tmp_dir/test/src1 ]
        [ -d $tmp_dir/test/src2 ]
        [ -d $tmp_dir/test/dest1 ]
        [ -d $tmp_dir/test/dest2 ]
        [ -f $tmp_dir/test/src1/file1.txt ]
        [ -f $tmp_dir/test/src1/file2.txt ]
        [ -f $tmp_dir/test/src2/file1.txt ]
        [ -f $tmp_dir/test/src2/file2.txt ]
    }

    teardown() {
        # Cleanup: Remove directories and files
        rm -rf $tmp_dir/test
        # Verify cleanup
        [ ! -d $tmp_dir/test ]
    }

    setup
    run ./synq --config tests/synq.test1.yml -y bucket1 bucket-unknown
    [ "$status" -eq 0 ]
    echo "$output" | grep -q "bucket-unknown is not a valid bucket and will be ignored."
    [ -f $tmp_dir/test/dest1/file1.txt ]
    [ -f $tmp_dir/test/dest1/file2.txt ]
    [ ! -f $tmp_dir/test/dest2/file1.txt ]
    [ ! -f $tmp_dir/test/dest2/file2.txt ]
    diff $tmp_dir/test/src1/file1.txt $tmp_dir/test/dest1/file1.txt
    diff $tmp_dir/test/src1/file2.txt $tmp_dir/test/dest1/file2.txt

    teardown
}

@test "should run with configuration file and specific bucket and unconfigured bucket be ignored with dry-run" {

    local tmp_dir="/tmp"
    setup() {
        # Setup: Create directories and files
        mkdir -p $tmp_dir/test/src1 $tmp_dir/test/dest1 $tmp_dir/test/src2 $tmp_dir/test/dest2
        echo "src1:file1" > $tmp_dir/test/src1/file1.txt
        echo "src1:file2" > $tmp_dir/test/src1/file2.txt
        echo "src2:file1" > $tmp_dir/test/src2/file1.txt
        echo "src2:file2" > $tmp_dir/test/src2/file2.txt

        # Verify setup
        [ -d $tmp_dir/test/src1 ]
        [ -d $tmp_dir/test/src2 ]
        [ -d $tmp_dir/test/dest1 ]
        [ -d $tmp_dir/test/dest2 ]
        [ -f $tmp_dir/test/src1/file1.txt ]
        [ -f $tmp_dir/test/src1/file2.txt ]
        [ -f $tmp_dir/test/src2/file1.txt ]
        [ -f $tmp_dir/test/src2/file2.txt ]
    }

    teardown() {
        # Cleanup: Remove directories and files
        rm -rf $tmp_dir/test
        # Verify cleanup
        [ ! -d $tmp_dir/test ]
    }

    setup
    run ./synq --config tests/synq.test1.yml -y --dry-run bucket1 bucket-unknown
    [ "$status" -eq 0 ]
    [ "$(echo "$output" | grep -c "(DRY RUN)")" -eq 1 ]
    echo "$output" | grep -q "bucket-unknown is not a valid bucket and will be ignored."
    [ ! -f $tmp_dir/test/dest1/file1.txt ]
    [ ! -f $tmp_dir/test/dest1/file2.txt ]
    [ ! -f $tmp_dir/test/dest2/file1.txt ]
    [ ! -f $tmp_dir/test/dest2/file2.txt ]

    teardown
}
