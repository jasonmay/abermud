export CATALYST_DEBUG=0
export PERL5LIB="../io-multiplex-intermediary/lib:../mud/lib:lib:$PERL5LIB"
if [ "$*x" == "x" ]
then
    prove -r t
else
    prove $*
fi
