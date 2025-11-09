#!/bin/bash

echo "Enter your number: "
read NUM


if ! [[ "$NUM" =~ ^[0-9]+$ ]] || [ "$NUM" -lt 1 ]; then
  echo "Please enter a positive integer."
  exit 1
fi

> ret.txt  

for (( i = NUM; i >= 1; i-- )); do
  if (( i % 2 == 0 )); then
    continue
  else
    echo "$i" >> ret.txt
  fi
done

echo "Odd numbers from $NUM down to 1 have been written to ret.txt"
