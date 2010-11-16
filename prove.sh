export CATALYST_DEBUG=0
export PERL5LIB="dep/mud/dep/iomi/lib:dep/mud/lib:lib:$PERL5LIB"
if [ "$*x" == "x" ]
then
    prove -r t
else
    prove $*
fi
