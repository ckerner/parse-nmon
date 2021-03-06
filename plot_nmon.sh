#!/bin/bash

# Initialize variables
AUTHOR='Chad Kerner'
AUTHOR_EMAIL='ckerner@illinois.edu'
VERSION='0.1'


# Print the usage screen
function print_usage {
   PRGNAME=`basename $0`

   cat <<EOHELP

   GNU Plot's of NMON Data - Version ${VERSION}
   Author: ${AUTHOR} (${AUTHOR_EMAIL})

   Usage: ${PRGNAME} [-d] [-h|--help] [-V|--version] OPTIONS

   OPTION          USAGE
   -h|--host       Specify the hostname to use in the title
   -d|--date       Specify the date for the graphed data for the title
   -i|--input      Specify the NMON input file
   -o|--output     Specify the name of the output PNG file
   -k|--key        Specify the key value for the data you want to graph
                   Valid Keys: ${VALID_KEYS}

   --xlabel        Set the label for the X-Axis
   --ylabel        Set the label for the Y-Axis
   --title         Set the title for the graph 
   -D|--debug      Turn on debugging for this script.  This is very detailed(set -x).

   -?|--help       This help screen
   -V|--version    Print the program version.

EOHELP
}

function init_routine {
   LOGFILE="/tmp/nmon.log.$$"
   GNUFILE="/tmp/gnuplot.input.$$"
   DEBUG=0
   VALID_KEYS=`ls gnuplot.* | sed -e 's/gnuplot\.//g'`
}

function print_error {
   MSG=$@
   printf "\n\tERROR: %s\n" "${MSG}"
   exit 1
}

# Validate the options that were specified
function validate_options {
   [[ ${DEBUG:=0} ]]

   # Assumes HOSTNAME.CCYYMMDD for the filename
   if [ "x${INFILE}" == "x" ] ; then
      print_error "No input file specified..."
   fi

   if [ "x${MYHOST}" == "x" ] ; then
      MYHOST=`basename ${INFILE} | sed -e 's/\./ /g' | awk '{print($1)}'`
   fi

   # Assumes HOSTNAME.CCYYMMDD for the filename
   if [ "x${MYDATE}" == "x" ] ; then
      MYDATE=`basename ${INFILE} | sed -e 's/\./ /g' | awk '{print($2)}'`
   fi

   if [ ! -f ${INFILE} ] ; then
      print_error "The input file: ${INFILE} does not exist..."
   fi

   if [ "x${PNGFILE}" == "x" ] ; then
      print_error "No output file specified..."
   fi

   # Lets verify the scan key
   KEYCNT=`echo ${VALID_KEYS} | grep ${SCANKEY} | wc -l`
   if [ ${KEYCNT} -eq 0 ] ; then
      print_error "${SCANKEY} is an invalid search key."
   fi

   if [ "x${PLOTFILE}" == "x" ] ; then
      PLOTFILE="gnuplot.${SCANKEY}"
   fi

   if [ ! -f ${PLOTFILE} ] ; then
      print_error "The report file: ${PLOTFILE} does not exist..."
   fi

   # Lets see if gnuplot is even installed in the path
   GNUPLOT=`which gnuplot 2>/dev/null`
   if [ "x${GNUPLOT}" == "x" ] ; then
      print_error "GNUPLOT is not installed, or not in the default path..."
   fi

}

# Process the command line options ( I hate getopt...)
function process_options {
   while [ $# -gt 0 ]
      do case $1 in
         -h|--host)    shift ; MYHOST=$1 ;;
         -d|--date)    shift ; MYDATE=$1 ;;
         -i|--input)   shift ; INFILE=$1 ;;
         -o|--output)  shift ; PNGFILE=$1 ;;
         -k|--key)     shift ; SCANKEY=$1 ;;
         -r|--report)  shift ; PLOTFILE=$1 ;;
         --xlabel)     shift ; XLABEL=$1 ;;
         --ylabel)     shift ; YLABEL=$1 ;;
         --title)      shift ; TITLE=$1 ;;
         -D|--debug)   DEBUG=1 ;;
         -?|--help)    print_usage ; exit 0 ;;
         -v|--version) print_version ; exit 0 ;;
      esac
      shift
   done
}

function plot_graph {
   cat ${PLOTFILE} | \
       sed -e s/###TITLE###/${TITLE}/g | \
       sed -e s/###XLABEL###/${XLABEL}/g | \
       sed -e s/###YLABEL###/${YLABEL}/g | \
       sed -e s/###MYHOST###/${MYHOST}/g | \
       sed -e s/###MYDATE###/${MYDATE}/g | \
       sed -e s_###LOGFILE###_${LOGFILE}_g | \
       sed -e s_###PNGFILE###_${PNGFILE}_g > ${GNUFILE}

   ${GNUPLOT} ${GNUFILE}
}

# Main Code Block
{
   # Do some basic initialization
   init_routine

   # Process the command line options
   process_options $*

   # Perform some sanity checks
   validate_options

   # Turn on debugging if specified
   if [ ${DEBUG} -eq 1 ] ; then
      set -x
   fi

   # Get the data, discard the headers
   grep -E "${SCANKEY},T" ${INFILE} > ${LOGFILE}
   LINECT=`wc -l ${LOGFILE} | awk '{print($1)}'` 
   if [ ${LINECT} -eq 0 ] ; then
      print_error "There is no output to graph."
   fi

   # We have some data, now lets plot it
   plot_graph

   rm -f ${LOGFILE} >/dev/null 2>&1
   rm -f ${GNUFILE} >/dev/null 2>&1
}

# Exit gracefully
exit 0

