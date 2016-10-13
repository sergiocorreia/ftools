{smcl}
{* *! version 1.5.0 08oct2016}{...}
{vieweralsosee "ftools" "help ftools"}{...}
{vieweralsosee "fmerge" "help fmerge"}{...}
{vieweralsosee "[R] merge" "help merge"}{...}
{viewerjumpto "Syntax" "join##syntax"}{...}
{title:Title}

{p2colset 5 13 20 2}{...}
{p2col :{cmd:join} {hline 2}}Merge datasets{p_end}
{p2colreset}{...}

{pstd}
{cmd:join} is an alternative for {help merge},
supporting {it:m:1} and {it:1:1} joins.
{p_end}

{pstd}
It's main advantage is that it uses a different algorithm
(hash+join instead of sort+merge), so it avoids sorting the data.
This is faster than merge on datasets roughly above a million obs.,
and is particularly useful if you often have to sort the data back
after a merge, or if you are merging a dataset with a small number
of categories.
{p_end}


{marker syntax}{...}
{title:Syntax}

INCOMPLETE

{p 8 13 2}
{cmd:fisid}
{varlist}
{ifin}
[{cmd:,}
{opt m:issok}]

{marker description}{...}
{title:Description}

{pstd}
{opt fisid} is an alternative to {help isid}
(which checks whether {it:varlist} uniquely identifies the observations.)


{marker author}{...}
{title:Author}

{pstd}Sergio Correia{break}
Board of Governors of the Federal Reserve System, USA{break}
{browse "mailto:sergio.correia@gmail.com":sergio.correia@gmail.com}{break}
{p_end}


{marker project}{...}
{title:More Information}

{pstd}{break}
To report bugs, contribute, ask for help, etc. please see the project URL in Github:{break}
{browse "https://github.com/sergiocorreia/ftools"}{break}
{p_end}
