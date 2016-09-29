{smcl}
{* *! version 1.1.0 29sep2016}{...}
{vieweralsosee "ftools" "help ftools"}{...}
{vieweralsosee "[R] egen" "help egen"}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "egenmore" "help egenmore"}{...}
{viewerjumpto "Syntax" "sort##syntax"}{...}
{title:Title}

{p2colset 5 18 20 2}{...}
{p2col :{cmd:fegen} {hline 2}}Alternative to egen that optimizes speed{p_end}
{p2colreset}{...}

{marker syntax}{...}
{title:Syntax}

{p 8 16 2}
{cmd:fegen}
{dtype}
{newvar}
{cmd:=}
{it:fcn}{cmd:(}{it:arguments}{cmd:)}
{ifin} 
[{cmd:,} {it:options}]

{title:Included functions}

{synoptset 32 tabbed}{...}
{synopt:{opth max(exp)}}{p_end}
{synopt:{opth group(varlist)}}note: {varlist} cannot have both string and numeric variables{p_end}
{p2colreset}{...}

{title:How to add a new function}

First, create a file named _gf{it:NAME}.ado where {it:NAME} is the name of the function.
Then, inside the file, use the following scaffolding:

{tab}{input}{bf}program define _gf{sf:{it:NAME}}
{tab}syntax [if] [in], type(string) name(string) args(string) [by(varlist)] {it:...}
{tab}{tab}tempvar touse
{tab}{tab}qui {
{tab}{tab}{tab}{it:...}
{tab}{tab}{tab}gen `type' `name' = {it:...} if `touse'==1
{tab}{tab}{tab}{it:...}
{tab}{tab}}
{tab}end{text}{sf}

{title:Author}

{pstd}Sergio Correia{break}
Fuqua School of Business, Duke University{break}
Email: {browse "mailto:sergio.correia@gmail.com":sergio.correia@gmail.com}{break}
Project URL: {browse "https://github.com/sergiocorreia/ftools"}{break}
{p_end}
