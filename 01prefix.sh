# Show how I'm called
echo Running $0 from `pwd` >  $0.out

# Run all stuff from within another shell
# Log all output

# To run with debugging info:
#/bin/sh -x <<'EOSCR' >> $0.out 2>&1
/bin/sh    <<'EOSCR' >> $0.out 2>&1
# ------------------------------------- #

export ERM_ROOT=`echo $0 | sed -e 's~/\w*$~~'`
