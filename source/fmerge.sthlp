{smcl}
{* *! version 1.5.0 08oct2016}{...}
{vieweralsosee "ftools" "help ftools"}{...}
{vieweralsosee "join" "help join"}{...}
{vieweralsosee "[R] merge" "help merge"}{...}
{viewerjumpto "Syntax" "fmerge##syntax"}{...}
{title:Title}

{p2colset 5 15 20 2}{...}
{p2col :{cmd:fmerge} {hline 2}}Merge datasets{p_end}
{p2colreset}{...}

{pstd}
{cmd:fmerge} is a wrapper for {help join},
supporting {it:m:1} and {it:1:1} joins.
{p_end}

{marker syntax}{...}
{title:Syntax}


INCOMPLETE

{pstd}
One-to-one merge on specified key variables

{p 8 15 2}
{opt mer:ge} {cmd:1:1} {varlist} 
{cmd:using} {it:{help filename}} [{cmd:,} {it:options}]


{pstd}
Many-to-one merge on specified key variables

{p 8 15 2}
{opt mer:ge} {cmd:m:1} {varlist} 
{cmd:using} {it:{help filename}} [{cmd:,} {it:options}]


{pstd}
One-to-many merge on specified key variables 

{p 8 15 2}
{opt mer:ge} {cmd:1:m} {varlist} 
{cmd:using} {it:{help filename}} [{cmd:,} {it:options}]


{pstd}
Many-to-many merge on specified key variables

{p 8 15 2}
{opt mer:ge} {cmd:m:m} {varlist} 
{cmd:using} {it:{help filename}} [{cmd:,} {it:options}]


{pstd}
One-to-one merge by observation

{p 8 15 2}
{opt mer:ge} {cmd:1:1 _n}
{cmd:using} {it:{help filename}} [{cmd:,} {it:options}]


{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{syntab :Options}
{synopt :{opth keepus:ing(varlist)}}variables to keep from using data;
     default is all
{p_end}
{...}
{synopt :{opth gen:erate(newvar)}}name of new variable to mark merge
      results; default is {cmd:_merge}
{p_end}
{...}
{synopt :{opt nogen:erate}}do not create {cmd:_merge} variable
{p_end}
{...}
{synopt :{opt nol:abel}}do not copy value-label definitions from using{p_end}
{...}
{synopt :{opt nonote:s}}do not copy notes from using{p_end}
{...}
{synopt :{opt update}}update missing values of same-named variables in master
     with values from using
{p_end}
{...}
{synopt :{opt replace}}replace all values of same-named variables in master
     with nonmissing values from using (requires {cmd:update})
{p_end}
{...}
{synopt :{opt norep:ort}}do not display match result summary table
{p_end}
{synopt :{opt force}}allow string/numeric variable type mismatch without error
{p_end}

{syntab: Results}
{synopt :{cmd:assert(}{help merge##results:{it:results}}{cmd:)}}specify required match results
{p_end}
{...}
{synopt :{cmd:keep(}{help merge##results:{it:results}}{cmd:)}}specify which match results to keep
{p_end}
{...}

{synopt :{opt sorted}}do not sort; datasets already sorted
{p_end}
{...}
{synoptline}
{p2colreset}{...}
{p 4 6 2}
{opt sorted} does not appear in the dialog box.{p_end}


{marker menu}{...}
{title:Menu}

{phang}
{bf:Data > Combine datasets > Merge two datasets}


{marker description}{...}
{title:Description}

{pstd}
{cmd:merge} joins corresponding observations from the dataset currently in
memory (called the master dataset) with those from
{it:{help filename}}{cmd:.dta}
(called the using dataset), matching on one or more key variables.  {cmd:merge}
can perform match merges (one-to-one, one-to-many, many-to-one, and
many-to-many), which are often called 'joins' by database people. {cmd:merge}
can also perform sequential merges, which have no equivalent in the relational
database world. 

{pstd}
{cmd:merge} is for adding new variables from a second dataset to existing
observations.  You use {cmd:merge}, for instance, when combining hospital
patient and discharge datasets. If you wish to add new observations to existing
variables, then see {bf:{help append:[D] append}}.  You use {cmd:append}, for
instance, when adding current discharges to past discharges.

{pstd}
By default, {cmd:merge} creates a new variable, {cmd:_merge}, containing
numeric codes concerning the source and the contents of each observation in the
merged dataset. These codes are explained below in the
{help merge##results:match results table}.
 
{pstd}
Key variables cannot be {helpb data types:strL}s.

{pstd}
If {it:filename} is specified without an extension, then {cmd:.dta} is assumed. 


{marker options}{...}
{title:Options}

{dlgtab:Options}

{phang}
{opth keepusing(varlist)}
    specifies the variables from the using dataset that are kept
    in the merged dataset. By default, all variables are kept. 
    For example, if your using dataset contains 2,000
    demographic characteristics but you want only
    {cmd:sex} and {cmd:age}, then type {cmd:merge} ...{cmd:,}
    {cmd:keepusing(sex} {cmd:age)} ....

{phang}
{opth generate(newvar)} specifies that the variable containing match
      {help merge##results:results} information should be named {it:newvar}
      rather than {cmd:_merge}.

{phang}
{cmd:nogenerate} specifies that {cmd:_merge} not be created.  This
    would be useful if you also specified {cmd:keep(match)}, because
    {cmd:keep(match)} ensures that all values of {cmd:_merge} would be 3.

{phang}
{cmd:nolabel}
    specifies that value-label definitions from the using file be ignored.
    This option should be rare, because definitions from the master are
    already used.

{phang}
{cmd:nonotes}
    specifies that notes in the using dataset not be added to the 
    merged dataset; see {manhelp notes D:notes}.

{phang}
{cmd:update} and {cmd:replace}
    both perform an update merge rather than a standard merge.
    In a standard merge, the data in the master are
    the authority and inviolable.  For example, if the master
    and using datasets both contain a variable {cmd:age}, then
    matched observations will contain values from the master
    dataset, while unmatched observations will contain values
    from their respective datasets.

{pmore}
    If {cmd:update} is specified, then matched observations will update missing
    values from the master dataset with values from the using dataset.
    Nonmissing values in the master dataset will be unchanged.

{pmore}
    If {cmd:replace} is specified, then matched observations will contain
    values from the using dataset, unless the value in the using dataset
    is missing. 

{pmore}
    Specifying either {cmd:update} or {cmd:replace} affects the meanings of the
    match codes. See
    {mansection D mergeRemarksandexamplesTreatmentofoverlappingvariables:{it:Treatment of overlapping variables}}
    in {bf:[D] merge} for details.

{phang}
{cmd:noreport}
    specifies that {cmd:merge} not present its summary table of
    match results.

{phang}
{opt force} allows string/numeric variable type mismatches, resulting in
missing values from the using dataset.  If omitted, {cmd:merge} issues an
error; if specified, {cmd:merge} issues a warning.

{dlgtab:Results}

{phang}
{cmd:assert(}{it:results}{cmd:)}
    specifies the required match results.  The possible
    {it:results} are 

{marker results}{...}
           numeric    equivalent
            code      word ({it:results})     description
           {hline 67}
              {cmd:1}       {cmdab:mas:ter}             observation appeared in master only
              {cmd:2}       {cmdab:us:ing}              observation appeared in using only
              {cmd:3}       {cmdab:mat:ch}              observation appeared in both

              {cmd:4}       {cmdab:match_up:date}       observation appeared in both,
{col 44}missing values updated
              {cmd:5}       {cmdab:match_con:flict}     observation appeared in both,
{col 44}conflicting nonmissing values
           {hline 67}
           Codes 4 and 5 can arise only if the {cmd:update} option is specified.
           If codes of both 4 and 5 could pertain to an observation, then 5 is
           used.

{pmore}
Numeric codes and words are equivalent when used in the {cmd:assert()}
or {cmd:keep()} options.

{pmore}
The following synonyms are allowed:
{cmd:masters} for {cmd:master}, 
{cmd:usings} for {cmd:using},
{cmd:matches} and {cmd:matched} for {cmd:match},
{cmd:match_updates} for {cmd:match_update}, 
and 
{cmd:match_conflicts} for {cmd:match_conflict}. 

{pmore}
    Using {cmd:assert(match master)} specifies that the merged file is
    required to include only matched master or using 
    observations and unmatched master observations, and may not 
    include unmatched using observations.  Specifying {cmd:assert()}
    results in {cmd:merge} issuing an error if there are match results
    among those observations you allowed.

{pmore}
The order of the words or codes is not important, so all the following
{cmd:assert()} specifications would be the same:

{pmore2}
{cmd:assert(match master)}

{pmore2}
{cmd:assert(master matches)}

{pmore2}
{cmd:assert(1 3)}

{pmore}
    When the match results contain codes other than those allowed,
    return code 9 is returned, and the 
    merged dataset with the unanticipated results is left in memory
    to allow you to investigate.

{phang}
{cmd:keep(}{help merge##results:{it:results}}{cmd:)}
    specifies which observations are to be kept from the merged dataset.
    Using {cmd:keep(match master)} specifies keeping only
    matched observations and unmatched master observations after merging.

{pmore}
    {cmd:keep()} differs from {cmd:assert()} because it selects
    observations from the merged dataset rather than enforcing requirements.
    {cmd:keep()}
    is used to pare the merged dataset to a given set of observations when
    you do not care if there are other observations in the merged dataset.
    {cmd:assert()} is used to verify that only a given set of observations
    is in the merged dataset.

{pmore}
   You can specify both {cmd:assert()} and {cmd:keep()}.  If you require 
   matched observations and unmatched master observations
   but you want only the matched observations, then you could specify
   {cmd:assert(match master)} {cmd:keep(match)}.

{pmore}
    {cmd:assert()} and {cmd:keep()} are convenience options whose functionality
    can be duplicated using {cmd:_merge} directly.

            . {cmd:merge} ...{cmd:, assert(match master) keep(match)}

{pmore}
    is identical to

            . {cmd:merge} ...
            . {cmd:assert _merge==1 | _merge==3}
            . {cmd:keep if _merge==3}

{pstd}
The following option is available with {opt merge} but is not shown in the
dialog box:

{phang}
{cmd:sorted}
    specifies that the master and using datasets are already sorted 
    by {varlist}.  If the datasets are already sorted, then {cmd:merge}
    runs a little more quickly; the difference is hardly detectable,
    so this option is of interest only where speed is of the utmost importance.


{* the following section appears on-line only}{...}
{marker oldsyntax}{...}
{title:Prior syntax}

{pstd}
Prior to Stata 11, {cmd:merge} had a more primitive syntax.
Code using the old syntax will run unmodified.
To assist those attempting to understand or debug out-of-date code, 
the original help file for {cmd:merge} can be found 
{help merge_10:here}.


{marker examples}{...}
{title:Examples}

    {hline}
{pstd}Setup{p_end}
{phang2}{cmd:. webuse autosize}{p_end}
{phang2}{cmd:. list}{p_end}
{phang2}{cmd:. webuse autoexpense}{p_end}
{phang2}{cmd:. list}{p_end}

{pstd}Perform 1:1 match merge{p_end}
{phang2}{cmd:. webuse autosize}{p_end}
{phang2}{cmd:. merge 1:1 make using http://www.stata-press.com/data/r14/autoexpense}{p_end}
{phang2}{cmd:. list}{p_end}

    {hline}
{pstd}Perform 1:1 match merge, requiring there to be only matches{break}
(The {cmd:merge} command intentionally causes an error message.){p_end}
{phang2}{cmd:. webuse autosize, clear}{p_end}
{phang2}{cmd:. merge 1:1 make using http://www.stata-press.com/data/r14/autoexpense, assert(match)}{p_end}
{phang2}{cmd:. tab _merge}{p_end}
{phang2}{cmd:. list}{p_end}

    {hline}
{pstd}Perform 1:1 match merge, keeping only matches and squelching the {cmd:_merge} variable{p_end}
{phang2}{cmd:. webuse autosize, clear}{p_end}
{phang2}{cmd:. merge 1:1 make using http://www.stata-press.com/data/r14/autoexpense, keep(match) nogen}{p_end}
{phang2}{cmd:. list}{p_end}

    {hline}
{pstd}Setup{p_end}
{phang2}{cmd:. webuse dollars, clear}{p_end}
{phang2}{cmd:. list}{p_end}
{phang2}{cmd:. webuse sforce}{p_end}
{phang2}{cmd:. list}{p_end}

{pstd}Perform m:1 match merge with {cmd:sforce} in memory{p_end}
{phang2}{cmd:. merge m:1 region using http://www.stata-press.com/data/r14/dollars}
{p_end}
{phang2}{cmd:. list}{p_end}

    {hline}
{pstd}Setup{p_end}
{phang2}{cmd:. webuse overlap1, clear}{p_end}
{phang2}{cmd:. list, sepby(id)}{p_end}
{phang2}{cmd:. webuse overlap2}{p_end}
{phang2}{cmd:. list}{p_end}

{pstd}Perform m:1 match merge, illustrating update option{p_end}
{phang2}{cmd:. webuse overlap1}{p_end}
{phang2}{cmd:. merge m:1 id using http://www.stata-press.com/data/r14/overlap2, update}{p_end}
{phang2}{cmd:. list}{p_end}

    {hline}
{pstd}Perform m:1 match merge, illustrating update replace option{p_end}
{phang2}{cmd:. webuse overlap1, clear}{p_end}
{phang2}{cmd:. merge m:1 id using http://www.stata-press.com/data/r14/overlap2, update replace}{p_end}
{phang2}{cmd:. list}{p_end}

    {hline}
{pstd}Perform 1:m match merge, illustrating update replace option{p_end}
{phang2}{cmd:. webuse overlap2, clear}{p_end}
{phang2}{cmd:. merge 1:m id using http://www.stata-press.com/data/r14/overlap1, update replace}{p_end}
{phang2}{cmd:. list}{p_end}

    {hline}
{pstd}Perform sequential merge{p_end}
{phang2}{cmd:. webuse sforce, clear}{p_end}
{phang2}{cmd:. merge 1:1 _n using http://www.stata-press.com/data/r14/dollars}{p_end}
{phang2}{cmd:. list}{p_end}

    {hline}
