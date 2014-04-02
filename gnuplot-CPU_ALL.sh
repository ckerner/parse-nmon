#!/bin/bash

PNGFILE=$1
MYHOST=$2
MYDATE=$3
INFILE=$4

GNUPLOT=`which gnuplot 2>/dev/null`
if [ "x${GNUPLOT}" == "x" ] ; then
   echo "GNUPLOT is not installed..."
   exit 1
fi

if [ "x${INFILE}" == "x" ] ; then
   LOGFILE="nmon.out"
else
   LOGFILE="${INFILE}"
fi


${GNUPLOT} <<EOF
set timefmt "%Y-%m-%d:%H:%M"
set xlabel "Time Interval (Minutes)"
set yrange [0:]
set xrange [0:1450]
set ylabel "CPU Usage(Percent)"
set title "CPU Utilization - ${MYHOST} - ${MYDATE}"
set grid
set datafile separator ","
set key left box
set terminal dumb
set xtics out nomirror
plot "${LOGFILE}" using 2 title 'User %' with lines, \
     "${LOGFILE}" using 3 title 'System %' with lines, \
     "${LOGFILE}" using 4 title 'Wait %' with lines, \
     "${LOGFILE}" using 5 title 'Idle %' with lines 
set terminal png size 600,400
set output "${PNGFILE}"
replot
EOF


