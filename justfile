build:
    gcc -O2 -Wall -o write_only write_only.c
    gcc -O2 -Wall -o write_fsync write_fsync.c

trace-write_only:
    echo '' | sudo tee /sys/kernel/debug/tracing/trace
    echo 1 | sudo tee /sys/kernel/debug/tracing/tracing_on
    ./write_only write_only.txt
    echo 0 | sudo tee /sys/kernel/debug/tracing/tracing_on
    sudo cat /sys/kernel/debug/tracing/trace o> ./trace_write_only.txt

trace-write_fsync:
    echo '' | sudo tee /sys/kernel/debug/tracing/trace
    echo 1 | sudo tee /sys/kernel/debug/tracing/tracing_on
    ./write_fsync write_fsync.txt
    echo 0 | sudo tee /sys/kernel/debug/tracing/tracing_on
    sudo cat /sys/kernel/debug/tracing/trace o> ./trace_write_fsync.txt

trace-cat:
    sudo cat /sys/kernel/debug/tracing/trace
