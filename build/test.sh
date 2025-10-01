#!/bin/bash
rm -rf ./build/target/test
mkdir ./build/target/test

./build/test/test_main.sh > ./build/target/test/test_main.log 2>&1 &
PID1=$! # Capture the Process ID of script1.sh

# Run script2.sh in the background and redirect its output to script2_output.log
./build/test/test_space.sh 20 > ./build/target/test/test_space.log 2>&1 &
PID2=$! # Capture the Process ID of script2.sh

# Wait for both background processes to complete
i=0
while kill -0 $PID1 2>/dev/null; do
  #\|/-\|/-\
  theTick="-"
  tickCount=$((i % 4))
  if [[ $tickCount == 1 ]]; then
    theTick="\\"
  elif [[ $tickCount == 2 ]]; then
    theTick="|"
  elif [[ $tickCount == 3 ]]; then
    theTick="/"
  fi
  printf "\r(${theTick}) Waiting... %d seconds elapsed" $((i++))
  sleep 1
done
while kill -0 $PID2 2>/dev/null; do
  #\|/-\|/-\
  theTick="-"
  tickCount=$((i % 4))
  if [[ $tickCount == 1 ]]; then
    theTick="\\"
  elif [[ $tickCount == 2 ]]; then
    theTick="|"
  elif [[ $tickCount == 3 ]]; then
    theTick="/"
  fi
  printf "\r(${theTick})Waiting... %d seconds elapsed" $((i++))
  sleep 1
done
printf "\rTests finished.\n"
wait $PID1
EXIT_CODE1=$?

wait $PID2
EXIT_CODE2=$?

echo "Script 1 finished with exit code: $EXIT_CODE1"
echo "Script 2 finished with exit code: $EXIT_CODE2"
echo "tests done, please check ./build/target/test for results"

echo "test_main:"
sed -n '/test summary:/,$p' ./build/target/test/test_main.log | sed -e 's/^/  /'
echo "test_space:"
sed -n '/test summary:/,$p' ./build/target/test/test_space.log | sed -e 's/^/  /'

# Check if either script exited with a non-zero code
if [ $EXIT_CODE1 -ne 0 ] || [ $EXIT_CODE2 -ne 0 ]; then
    echo "One or both scripts failed. Exiting."
    exit 1
else
    echo "Both scripts completed successfully."
    exit 0
fi