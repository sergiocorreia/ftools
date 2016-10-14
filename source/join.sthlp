{smcl}
{* *! version 1.5.0 08oct2016}{...}
{vieweralsosee "ftools" "help ftools"}{...}
{vieweralsosee "fmerge" "help fmerge"}{...}
{vieweralsosee "[R] merge" "help merge"}{...}
{viewerjumpto "Syntax" "join##syntax"}{...}
{viewerjumpto "description" "join##description"}{...}
{viewerjumpto "options" "join##options"}{...}
{viewerjumpto "examples" "join##examples"}{...}
{viewerjumpto "about" "join##about"}{...}
{title:Title}

{p2colset 5 13 20 2}{...}
{p2col :{cmd:join} {hline 2}}Join/merge datasets{p_end}
{p2colreset}{...}

{marker syntax}{...}
{title:Syntax}

{pstd}
Many-to-one join/merge on specified key variables

{p 8 13 2}
{cmd:join}
[{varlist}]{cmd:,}
{opth from(filename)}
{opth by(varlist)}
[{it:options}]

{pstd}
As above, but with the "using" dataset currently open instead of the "master".

{p 8 13 2}
{cmd:join}
[{varlist}]{cmd:,}
{opth into(filename)}
{opth by(varlist)}
[{it:options}]


{synoptset 24 tabbed}{...}
{synopthdr}
{synoptline}
{p2coldent:+ {cmd:from(}{help filename} [{cmd:,} {help if}]{cmd:)}}filename of the {it:using} datasetm, where the keys are unique{p_end}
{...}
{p2coldent:+ {cmd:into(}{help filename} [{cmd:,} {help if}]{cmd:)}}filename of the {it:master} dataset{p_end}
{...}
{p2coldent:* {opth by(varlist)}}key variables; {it:master_var=using_var} is also allowed in case the variable names differ between datasets{p_end}
{...}
{synopt :{opt uniq:uemaster}}assert that the merge will be 1:1
{p_end}
{...}
{synopt :{cmd:keep(}{help join##results:{it:results}}{cmd:)}}specify which match results to keep
{p_end}
{...}
{synopt :{cmd:assert(}{help join##results:{it:results}}{cmd:)}}specify required match results
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
{synopt :{opt v:erbose}}show internal debug info
{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}+ you must include either {opt from()} or {opt from()} but not both.{p_end}
{p 4 6 2}* {opt by(varlist)} is required.{p_end}


{marker description}{...}
{title:Description}

{pstd}
{cmd:join} is an alternative for {help merge},
supporting {it:m:1} and {it:1:1} joins.
{p_end}

{pstd}
{cmd:join} works by hashing the keys, instead of sorting the data like {cmd:merge} does
(see 
{browse "https://my.vertica.com/docs/7.1.x/HTML/Content/Authoring/AnalyzingData/Optimizations/HashJoinsVs.MergeJoins.htm":[1]}
and
{browse "http://support.sas.com/resources/papers/proceedings09/071-2009.pdf":[2]}
for a comparison of the hash+join and sort+merge algorithms).
As a result, {cmd:join} performs better if the datasets are not
already sorted by the {it:by()} variables, and for datasets
above 100,000 observations (due to Mata's overhead).
One limitation of {cmd:join} is that it doesn't support merging string variables.
Even though this limitation can be lifted in future updates, using strings
in large datasets is not really recommended so this is not a priority.
{p_end}


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


{marker examples}{...}
{title:Examples}

{pstd}Perform m:1 merge with {cmd:sforce} in memory{p_end}

{inp}
    {hline 60}
    webuse sforce
    join, by(region) from(http://www.stata-press.com/data/r14/dollars)
    {hline 60}
{txt}









{marker about}{...}
{title:Author}

{pstd}Sergio Correia{break}
Board of Governors of the Federal Reserve System, USA{break}
{browse "mailto:sergio.correia@gmail.com":sergio.correia@gmail.com}{break}
{p_end}


{title:More Information}

{pstd}{break}
To report bugs, contribute, ask for help, etc. please see the project URL in Github:{break}
{browse "https://github.com/sergiocorreia/ftools"}{break}
{p_end}
