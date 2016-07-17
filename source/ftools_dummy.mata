mata:
mata set matastrict off
transmorphic scalar factor(|a,b,c,d,e,f,g,h,i,j,k)
{
	pragma unused a
	pragma unused b
	pragma unused c
	pragma unused d
	pragma unused e
	pragma unused f
	pragma unused g
	pragma unused h
	pragma unused i
	pragma unused j
	pragma unused k
	printf("{err}{hline 78}\n")
	printf("{err}lftools.mlib file must be compiled after install; ")
	printf("{err}please run {stata ftools compile} !!\n")
	printf("{err}{hline 78}\n")
	_error(601)
}

void store_levels(|a,b,c,d,e,f,g,h,i,j,k)
{
	pragma unused a
	pragma unused b
	pragma unused c
	pragma unused d
	pragma unused e
	pragma unused f
	pragma unused g
	pragma unused h
	pragma unused i
	pragma unused j
	pragma unused k
	printf("{err}{hline 78}\n")
	printf("{err}lftools.mlib file must be compiled after install; ")
	printf("{err}please run {stata ftools compile} !!\n")
	printf("{err}{hline 78}\n")
	_error(601)
}

real ftools_needs_compile()
{
	return(1)
}
end
