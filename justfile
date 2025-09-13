build:
    gcc -O2 -Wall -o write_only write_only.c
    gcc -O2 -Wall -o write_fsync write_fsync.c

trace-write_only: build
    echo '' | sudo tee /sys/kernel/debug/tracing/trace
    echo 1 | sudo tee /sys/kernel/debug/tracing/tracing_on
    ./write_only arst
    echo 0 | sudo tee /sys/kernel/debug/tracing/tracing_on

trace-write_fsync: build
    echo '' | sudo tee /sys/kernel/debug/tracing/trace
    echo 1 | sudo tee /sys/kernel/debug/tracing/tracing_on
    ./write_fsync arst
    echo 0 | sudo tee /sys/kernel/debug/tracing/tracing_on

trace-cat:
    sudo cat /sys/kernel/debug/tracing/trace
