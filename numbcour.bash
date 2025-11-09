#!/bin/bash
echo "Enter your number: "
read NUM
touch ret.txt  
for (( i = NUM; i >= 1; i-- )); do
  if (( i % 2 == 0 )); then
    continue
  else
    echo "$i" >> ret.txt
  fi
done
