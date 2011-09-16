if [ "$*x" == "x" ]
then
    prove -r t
else
    prove $*
fi
