#!/bin/sh
#
# Compile the matlab code so we can run it without a matlab license. To create a 
# linux container, we need to compile on a linux machine. That means a VM, if we 
# are working on OS X.
#
# We require on our compilation machine:
#     Matlab 2019a, including compiler, with license
#
# The matlab version matters. If we compile with R2017a, it will only run under 
# the R2017a Runtime.

# We may need to add Matlab to the path on the compilation machine
export PATH=/usr/local/MATLAB/R2019b/bin:${PATH}

mcc -m -C -v ../src/connstats.m \
    -N \
    -a ../src \
    -d ../bin

# We grant lenient execute permissions to the matlab executable and runscript so
# we don't have hiccups later.
chmod go+rx ../bin/connstats
chmod go+rx ../bin/run_connstats.sh
