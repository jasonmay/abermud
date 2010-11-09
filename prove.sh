export CATALYST_DEBUG=0
export PERL5LIB="dep/mud/dep/iomi/lib:dep/mud/lib:lib:$PERL5LIB"
prove -r t/ $*
