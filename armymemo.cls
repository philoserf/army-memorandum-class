% Army memo class
%
% Original:  https://github.com/glallen01/army-memorandum-class
% This fork: https://github.com/philoserf/army-memorandum-class
%
% Copyright (c) 2011 George Allen, All rights reserved.
%
% This program is free software; you can redistribute it and/or modify it under
% the terms of the GNU General Public License as published by the Free Software
% Foundation; either version 2 of the License, or (at your option) any later
% version.
%
% This program is distributed in the hope that it will be useful, but WITHOUT ANY
% WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
% PARTICULAR PURPOSE.  See the GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License along with
% this program; if not, write to the Free Software Foundation, Inc., 59 Temple
% Place, Suite 330, Boston, MA  02111-1307  USA
%
% The LICENSE file distributed with this class carries the text of GPL version 3,
% which the grant above permits.

% \NeedsTeXFormat comes first: the format check should run before anything else,
% and the dated argument is a real floor, not decoration -- the classification marks
% use \AddToHook{shipout/background}, which the kernel gained on 2020-10-01.
\NeedsTeXFormat{LaTeX2e}[2020/10/01]
\ProvidesClass{armymemo}[2026/03/29 0.3.0 Army Memorandum Class]

% Canonical LaTeX2e order is \ProvidesClass -> \DeclareOption -> \ProcessOptions
% -> \LoadClass. This file used to process options 140 lines after loading the
% class, which made \DeclareOption* dead: it forwarded to a class already loaded.
%
% The fix moves the option block UP rather than moving \LoadClass down. Moving the
% class down would put fourteen \RequirePackage calls ahead of it, including
% scrlayer-scrpage, which requires a KOMA class to already be loaded. etoolbox comes
% along because \newbool needs it; it has no class dependency of its own.
%
% \DeclareOption* is deleted rather than revived. Reviving it would make
% pass-through options reach scrartcl via \PassOptionsToClass *in addition to* the
% kernel's global-option rule, which already delivers them -- potentially twice, or
% in a different order. Deleting leaves the kernel rule doing what it does today.
\RequirePackage{etoolbox}  % required for conditionals (already implied)
\newbool{am@digsig}
\DeclareOption{digsig}{\booltrue{am@digsig}}
\ProcessOptions\relax

% 12pt and oneside are mandated by AR 25-50 and are deliberately not overridable.
% They are passed here rather than exposed as options so that a document cannot
% silently produce a non-compliant memo. headings=small and DIV=15 are layout
% choices this class makes on the author's behalf.
\LoadClass[
  12pt,
  oneside,
  headings=small,
  DIV=15
]{scrartcl}

\AtBeginDocument{%
  \am@putlogo%
  \dodheader%
  \vspace*{1\baselineskip}
}

\AtEndDocument{%
  \setlength{\parskip}{0pt}
  \am@closing%
  \am@distro%
  \am@cf%
}




% Setting penalties for widows and orphans: broken paragraphs with only one line
% at the top or bottom of the page. This messes up other formatting leaving lots
% of space at the bottom of some pages that requires manual intervention.
%% http://www.tex.ac.uk/cgi-bin/texfaq2html?label=widows
\widowpenalty=10000
\clubpenalty=10000

% Setup fonts:
% allow automatic quote expansion
\RequirePackage{csquotes}
\MakeOuterQuote{"}
% for font selection
\RequirePackage{fontspec}
\RequirePackage[english]{babel}
% AR 25-50 allows command direction of font selection, defaulting to Times New Roman
% Both are non-free and ship with no TeX distribution, so an unguarded
% \setmainfont aborts the build entirely on a machine that lacks them -- no PDF
% at all, not a degraded one. Fall back to the metric-compatible TeX Gyre faces,
% but never silently: AR 25-50 is the specification, and a quiet substitution
% hands the author a memo that looks finished and is not compliant.
\IfFontExistsTF{Times New Roman}{%
  \setmainfont{Times New Roman}%
}{%
  \ClassWarningNoLine{armymemo}{%
    Times New Roman not found;\MessageBreak%
    falling back to TeX Gyre Termes.\MessageBreak%
    Metrics match but this is NOT the AR 25-50 font}% chktex 8
  \setmainfont{TeX Gyre Termes}%
}
\IfFontExistsTF{Arial}{%
  \setsansfont{Arial}%
}{%
  \ClassWarningNoLine{armymemo}{%
    Arial not found;\MessageBreak%
    falling back to TeX Gyre Heros.\MessageBreak%
    Metrics match but this is NOT the AR 25-50 letterhead font}% chktex 8
  \setsansfont{TeX Gyre Heros}%
}

% used to change date format
\RequirePackage{datetime}
\newdateformat{mildate}{\twodigit\THEDAY\ \monthname[\THEMONTH] \THEYEAR}
\mildate
% for logo and other includes
\RequirePackage{graphicx}
% for future use of colors in classification markings
\RequirePackage{xcolor}
% required for graphics placement, and for the classification-mark overlay
\RequirePackage{tikz}
% required to enable high-depth nested lists, and custom numbering
\RequirePackage{enumitem}
% AR 25-50 permits four levels of subdivision and no more, so four is what this
% class implements. It previously declared nine while defining labels for four, and
% a fifth level crashed with an enumitem "Undefined label" error that never
% mentioned the regulation and blamed the author's \setlist usage.
%
% Five are declared rather than four, deliberately: at a declared depth of four,
% enumitem refuses a fifth level with its own "Too deeply nested" error -- the same
% unhelpful crash, differently worded. Declaring five lets level 5 exist just long
% enough to say which rule it breaks. Level 6 is still a hard enumitem error, which
% is the right outcome for someone who ignored the warning at 5.
\renewlist{enumerate}{enumerate}{5}
\setlistdepth{5}
% required for \setstretch, which \dodheader relies on to set the letterhead's line
% pitch -- indirectly, and not in the way the source looks like it does. See \dodheader.
\RequirePackage{setspace}



% for margins
\RequirePackage{calc}
% \Needspace keeps a heading with its first entries. The closing block itself is
% held together by box structure, not penalties -- see \am@closing.
\RequirePackage{needspace}
\RequirePackage[letterpaper
  ,margin=1in
  % in order to get 2-line offset between bottom of text and page number
  % (because it looks nicer)
  ,bottom=1in-2\baselineskip
  ,includehead
  % includefoot, but then we manually adjust the bottom margin above, in order
  % to also adjust the overall \textheight
  % also the AR examples show the page number above the classification marking
  ,includefoot
  ,footskip=3\baselineskip
  ,footnotesep=\baselineskip
  % Two lines is the common case: office symbol, then a SUBJECT that fits on one
  % line. A longer subject wraps and needs a third, which \am@fitheadheight
  % measures and asks geometry for -- see it for why growing the head is the
  % regulation-correct direction.
  ,headheight=2\baselineskip
  ,headsep=2\baselineskip
  ]{geometry}
% make sure the paragraph spacing matches the linespacing
\setlength{\parskip}{\baselineskip}

% setup page headers
\RequirePackage{scrlayer-scrpage}
\setlength{\footheight}{2\baselineskip}
\clearpairofpagestyles%
\lohead[]{\am@officesymbol\hspace*{\fill}\\\am@subject}

% AR 25-50 requires the office symbol and the FULL subject on every continuation
% page, and \am@subject is arbitrary user text, so the head is only sometimes two
% lines tall. Declared at a fixed 2\baselineskip, a subject that wraps overflowed
% it -- measured as "Overfull \vbox (14.49998pt too high) while \output is active",
% exactly one line.
%
% The overflow grew the head UPWARD, leaving the body untouched: the office symbol
% moved from 1in below the paper edge to 1in minus one line. That is the wrong
% direction. The head's top sits on the 1in margin AR 25-50 requires, so growing up
% pushes it into that margin (and, with a subject long enough, eventually into the
% classification marking). Growing down is correct: the head keeps its top at 1in
% and the body starts a line lower, which is what a memo with a two-line subject
% genuinely costs.
%
% So measure the head and ask geometry for what it actually needs. This runs at
% \AtEndPreamble, which is still the preamble -- \geometry is legal there and
% recalculates cleanly -- but late enough that \officesymbol and \subject have both
% been set, in either order. Documents whose subject fits on one line measure at or
% below 2\baselineskip and are left completely alone.
\newcommand{\am@fitheadheight}{%
  \setbox\z@=\vbox{%
    \hsize=\textwidth
    % The preamble parks \@nodocument in \everypar, so starting a paragraph here --
    % even sealed inside this box -- would raise "Missing \begin{document}". Clearing
    % it is local to the box group.
    \everypar{}%
    \usekomafont{pagehead}%
    \noindent\am@officesymbol\hspace*{\fill}\\\am@subject\par
  }%
  % Round UP to whole lines. Two reasons: the natural box height is a few points
  % short of what the head actually reserves (measured: it still overflowed by
  % 3.24pt when asked for the exact height), and whole lines are the unit this
  % class lays out in -- headheight and headsep are both declared in \baselineskip.
  \@tempdima=\dimexpr\ht\z@+\dp\z@\relax
  \@tempcnta=\@tempdima
  \@tempcntb=\dimexpr\baselineskip\relax
  \divide\@tempcnta by \@tempcntb
  \advance\@tempcnta by \@ne
  \@tempdimb=\@tempcnta\baselineskip\relax
  \ifdim\@tempdimb>\headheight
    \geometry{headheight=\the\@tempdimb}%
  \fi
}
\AtEndPreamble{\am@fitheadheight}
\cofoot[]{\thepage}
\pagestyle{scrheadings}
\setkomafont{pagehead}{\sffamily\upshape}


% \RaggedRight is a bit more compact, but allows lots of hyphens
% reduce hyphens with a combination of \hypenpenalty and microtype
\RequirePackage{microtype}
% TODO: disable if using xelatex

% do I need this later? https://tex.stackexchange.com/a/64615
\RequirePackage[colorlinks=true,urlcolor=blue,citecolor=blue,breaklinks=true]{hyperref}
\ifbool{am@digsig}{\RequirePackage{digsig}}{}
\urlstyle{same}

\RequirePackage{ragged2e}
\RaggedRight

% AR 25-50 allows for hyphenation (just not across pages per AR 25-50 2-5-c-3)
% and we want less hyphenation than more
\hyphenpenalty=5000
\brokenpenalty=10000




\setlist{topsep=0pt,itemsep=0pt,parsep=\baselineskip,partopsep=0pt}
%% from https://github.com/jschaf/army-memos/blob/master/src/memorandum-for-record.tex
\renewcommand{\theenumi}{\arabic{enumi}}\renewcommand{\labelenumi}{\theenumi.}
\renewcommand{\theenumii}{\alph{enumii}}\renewcommand{\labelenumii}{\theenumii.}
\renewcommand{\theenumiii}{\arabic{enumiii}}\renewcommand{\labelenumiii}{(\theenumiii)}
\renewcommand{\theenumiv}{\alph{enumiv}}\renewcommand{\labelenumiv}{(\theenumiv)}
% these \setlist provide the layout for each indentation level
% the after={} on level[1] prevents orphaned signature-blocks without the preceding final paragraph.
% after={\nopagebreak\@nobreaktrue} enforces the OTHER half of the AR 25-50 page-break
% rule. \am@closing is an unbreakable box, so the closing can never be split; this
% forbids a break immediately after the body list, so the closing can never be pushed
% onto a page of its own either. The regulation requires both: the signature block must
% stay whole AND must be accompanied by at least two lines of the body. Removing this
% would satisfy one half by violating the other.
\setlist[1]{labelwidth=12pt,labelsep=4pt,leftmargin=0pt,itemindent=16pt,align=left,
  after={\nopagebreak\@nobreaktrue}}
\setlist[2]{labelwidth=12pt,labelsep=4pt,leftmargin=0pt,itemindent=0.5in,align=left}
\setlist[3]{labelwidth=12pt,labelsep=4pt,leftmargin=0pt,itemindent=0.75in,align=left}
\setlist[4]{labelwidth=12pt,labelsep=4pt,leftmargin=0pt,itemindent=0.75in,align=left}
% Level 5 is declared only so that it can report itself. AR 25-50 prohibits
% subdividing beyond the third subdivision, so there is no correct rendering to
% fall back to -- the label is a visible marker and the warning names the rule.
%
% This warns once per offending \item, NOT once per document, and that is intended:
% each level-5 item is a separate violation of the regulation. Do not "fix" it with
% the am@reported@ flag used by \am@MissingRequiredArg -- that exists because the
% page header re-expands a single missing field on every page, which is a different
% situation entirely.
\DeclareRobustCommand{\am@toodeep}{%
  \textcolor{red}{[AR 25-50]}% chktex 8
  \ClassWarningNoLine{armymemo}{%
    AR 25-50 prohibits subdivision beyond the third\MessageBreak% chktex 8
    subdivision; level 5 is not supported}%
}
\setlist[5]{labelwidth=12pt,labelsep=4pt,leftmargin=0pt,itemindent=1.0in,align=left,
  label={\am@toodeep}}

% define superscripts for use in unit addresses, etc.
% these may need to be followed by an '\ '
\newcommand{\st}{\textsuperscript{st}}
\newcommand{\nd}{\textsuperscript{nd}}
\newcommand{\rd}{\textsuperscript{rd}}
\newcommand{\thh}{\textsuperscript{th}}

% commands for error/warning messages for missing values
% One diagnostic for a missing required field, with the severity as a parameter so
% the two forms cannot drift apart in wording the way they had.
%
% Each field reports at most once per document. The required fields are expanded in
% \lohead, which runs at every continuation-page shipout, so an unguarded diagnostic
% fires once per page -- a five-page memo with no office symbol stopped five times.
% The flag is set globally because \lohead's content is expanded inside a group.
%
% One flag per field, not one shared flag: \lohead expands two required fields, and
% a shared flag would silently swallow the second field's report once the first had
% fired.
%
%   #1 severity: error or warning   #2 field name   #3 visible placeholder
\newcommand{\am@MissingRequiredArg}[3]{%
  \textcolor{red}{#3}%
  \ifcsdef{am@reported@#2}{}{%
    \csgdef{am@reported@#2}{}%
    \ifstrequal{#1}{error}{%
      \ClassError{armymemo}{%
        #2 is a required field}{%
        Set it in the preamble.\MessageBreak%
        A red placeholder has been substituted in the output.}%
    }{%
      \ClassWarningNoLine{armymemo}{%
        #2 is a required field;\MessageBreak%
        a red placeholder has been substituted in the output}%
    }%
  }%
}

% header info
\newcommand{\signaturedate}[1]{\def \am@signaturedate{#1}}\signaturedate{}
\signaturedate{\am@MissingRequiredArg{warning}{signaturedate}{DRAFT}}
\newcommand{\suspensedate}[1]{\def\am@suspensedate{\ifstrempty{#1}{}{\textbf{S: #1}}}}\suspensedate{}
\newcommand{\officesymbol}[1]{\def \am@officesymbol{#1}}
\officesymbol{\am@MissingRequiredArg{error}{officesymbol}{OFFICE SYMBOL}}
% allow replacing the logo
\newcommand{\logo}[1]{\def\am@logo{\ifstrempty{#1}{DODb1}{#1}}}\logo{}

%%%%% Memolines:-------------------------------------------------------
%
% example 1:
% nothing or just \mfr -- MEMORANDUM FOR RECORD
%
% example 2:
% \addmemoline{MEMORANDUM FOR ...} % this is hopefully what most people need most of the time
%
% example 3:
% \addmemoline{MEMORANDUM THRU ...}
% \addmemoline{FOR ...}
% This is the first method for doing THRU memorandums. It follows the previous pattern.
%
% example 4:
% \multimemothru{....}    % multi line memorandums break after MEMORANDUM THRU and have
% \multimemothru{....}    % hanging indents after each THRU line, without spaces, followed by
% \addmemoline{FOR ...}   % a space and the FOR line. FOR must be specified in the \addmemoline
%
% This method deviates from examples 1-3, as it uses \multimemothru{...} to add multiple thru lines
% with hanging indents per the AR, followed by an \addmemoline{} to complete the "FOR ..."
%
\newcommand{\addmemoline}[1]{\listadd{\am@list@memolines}{#1}}
\newcommand{\mfr}{\addmemoline{MEMORANDUM FOR RECORD}}
\newcommand{\memoline}[1]{\addmemoline{#1}}
\newcommand{\am@domemoline}[1]{\vspace{\baselineskip}\noindent{}#1\\}
\newcommand{\multimemothru}[1]{\listadd{\am@list@memothru}{#1}}
% One hanging-indent line, shared by the THRU and FOR lists, which had byte-identical
% helpers. Not \am@do (below): that one is bare and lacks the hanging indent the AR
% format needs, so it is precedent for the pattern, not a drop-in.
\newcommand{\am@do@hangline}[1]{\noindent{}\hangindent=0.25in{}#1\\}
\newcommand{\multimemofor}[1]{\listadd{\am@list@memofor}{#1}}

\newcommand{\am@memoline}{%
  % if there is nothing specified, add "memorandum for record"
  \ifdefvoid{\am@list@memolines}{%
    \ifdefvoid{\am@list@memothru}{
      \ifdefvoid{\am@list@memofor}{
        \mfr
      }{}
    }{}
  }{}
  % otherwise, skip a space and begin
  \vspace{\baselineskip}
  % if there are multimemothru lines:
  \ifdefvoid{\am@list@memothru}{}{%
    \vspace{\baselineskip}
    MEMORANDUM THRU\\
    \vspace{\baselineskip}
    % loop through the thru lines with hanging indent
    \forlistloop{\am@do@hangline}{\am@list@memothru}}%
  \ifdefvoid{\am@list@memofor}{}{%
    \ifdefvoid{\am@list@memothru}{%
      \vspace{\baselineskip}
      MEMORANDUM FOR\\ % if there is no thru
      \vspace{\baselineskip}
    }{%
      \vspace{\baselineskip}
      FOR\\ % if there is a thru, it should just be for, not memorandum for
      \vspace{\baselineskip}
    }
    \forlistloop{\am@do@hangline}{\am@list@memofor}}%
  \ifdefvoid{\am@list@memolines}{}{%
    % after dealing with special cases, add the other lines from \addmemoline or \memoline
    % these lines must begin with any labels such as "MEMORANDUM FOR" or "MEMORANDUM THRU" or "FOR"
    % allow for possibility of no multi lines.
    \forlistloop{\am@domemoline}{\am@list@memolines}
  }%
}


%%%%% ----------------------------------------------------------------

\renewcommand{\subject}[1]{\def\am@subject{SUBJECT:~~#1}}
\subject{\am@MissingRequiredArg{warning}{subject}{DRAFT}}

% top and bottom of page classification markings
% TODO should be highest of any portion marking (how to track/test)?
\newcommand{\documentmark}[1]{\def \am@documentmark{#1}}\documentmark{}

% authority line
\newcommand{\authority}[1]{\def\am@authorityline{\ifstrempty{#1}{}{\MakeUppercase{#1}:}}}
\authority{}

% signature block
% AR 25-50 requires the signature block; it identifies the memo's author. These
% three follow the same convention as \officesymbol and \subject -- report the
% missing field and substitute something visible -- rather than defaulting to
% empty and rendering a bare comma between two blank lines.
%
% \title stays optional and defaults to empty: a memo may genuinely have no duty
% title, so there is nothing to report.
\renewcommand{\author}[1]{\def \am@author{#1}}
\author{\am@MissingRequiredArg{warning}{author}{AUTHOR NAME}}
\newcommand{\rank}[1]{\def \am@rank{#1}}
\rank{\am@MissingRequiredArg{warning}{rank}{RANK}}
\newcommand{\branch}[1]{\def \am@branch{#1}}
\branch{\am@MissingRequiredArg{warning}{branch}{BRANCH}}
\renewcommand{\title}[1]{\def \am@title{#1}}\title{}


% add enclosures along with a total count
% use \enclsnocount to print "Encls" without a numeric count (AR 25-50 Figure 4-4)
\newcommand{\am@do@encl}[1]{\item #1 }
\newcounter{am@encl@count}
\newbool{am@encls@nocount}
\newcommand{\enclsnocount}{\booltrue{am@encls@nocount}}
\newcommand{\addencl}[1]{\stepcounter{am@encl@count}\listadd{\am@list@encls}{#1}}
% The three cases wrap the same list in the same enumerate, and differ in exactly
% two things: the heading, and the list options. \enclsnocount and the many-case
% share their options outright.
%
% Two details are load-bearing. The nocount test comes FIRST, so \enclsnocount with
% a single enclosure still prints "Encls" with numbered entries -- reordering these
% would change that quietly, and no example covers it. And the one-enclosure case
% genuinely OMITS leftmargin rather than zeroing it, inheriting 0pt from \setlist[1];
% that absence has to be reproduced, not defaulted.
\newcommand{\am@encls@numbered}{leftmargin=16pt,itemindent=0pt,align=left,label={\arabic*.}}
\newcommand{\am@encls@list}[1]{%
  \begin{enumerate}[topsep=0pt,itemsep=0pt,parsep=0pt,#1]
    \forlistloop{\am@do@encl}{\am@list@encls}
  \end{enumerate}%
}
\newcommand{\am@encls}{%
  \ifnumcomp{\value{am@encl@count}}{=}{0}{}{%
    \ifbool{am@encls@nocount}{%
      \def\am@encl@head{Encls}%
      \let\am@encl@opts\am@encls@numbered
    }{%
      \ifnumcomp{\value{am@encl@count}}{=}{1}{%
        \def\am@encl@head{Encl}%
        \def\am@encl@opts{itemindent=0pt,align=left,label={}}%
      }{%
        \def\am@encl@head{\theam@encl@count{} Encls}%
        \let\am@encl@opts\am@encls@numbered
      }%
    }%
    \noindent\am@encl@head%
    % \expandafter, because enumitem's keyval parser does not expand a macro in the
    % optional argument -- it would read the whole of \am@encl@opts as one key name.
    % One expansion step hands it the option text while leaving \arabic* alone.
    \expandafter\am@encls@list\expandafter{\am@encl@opts}%
  }%
}

% The closing block: authority line, the reserved signing space, and a two-column
% row with enclosures left and the signature right.
%
% It is ONE UNBREAKABLE UNIT by construction. The page builder can measure a
% \parbox, so it either fits the whole closing on the page or moves all of it --
% which is what AR 25-50 requires. The previous implementation drew the signature
% as a zero-height tikz overlay at absolute page coordinates; because the overlay
% occupied no vertical space, LaTeX could not break around something it could not
% measure, and the enclosure list flowing at the left margin merely happened to
% land beside it. Issues #1, #6, #25 and #29 were all that one decision.
%
% Both columns are \parbox[t], so their first baselines align: "Encl" sits level
% with the author's name, as AR 25-50 Figure 4-4 shows. With no enclosures the
% left box is empty and has no height, so the row's height comes from the
% signature alone and nothing can slide into the vacant column (#29).
%
% DISTRIBUTION and CF are deliberately left OUT of this box. A \parbox cannot
% break across a page, exactly as a minipage cannot -- an earlier attempt at this
% layout was abandoned for precisely that reason:
%
%     since minipages can't break, and this may happen near the bottom of a page,
%     only encls and signature block go in the first mini-page
%     spacing issues w/ minipage: https://tex.stackexchange.com/q/349178/6648
%
% Enclosures and the signature are short and must not break, so being unbreakable
% is the point there. A distribution list can be arbitrarily long and must be
% allowed to break; boxing it would reproduce the failure that stopped the first
% attempt.
\newcommand{\am@sigblock}{%
  \ifbool{am@digsig}{%
    % A pure overlay on the signing space already reserved above the row, anchored
    % at the left edge of this column. Three details, each load-bearing:
    %   \rlap      -- zero width. Without it the field keeps its 3in width and the
    %                 author's name starts after it and wraps.
    %   [0pt][0pt] -- zero height and depth, so the field does not add a second gap.
    %   \noindent  -- \rlap is an \hbox, and an \hbox in vertical mode joins the
    %                 vertical list as its own box rather than the name's line.
    %                 digsig.sty documents exactly this ("the macro does not change
    %                 TeX's mode").
    \noindent\rlap{\raisebox{\baselineskip}[0pt][0pt]{%
      \begin{Form}\digsigfield{3in}{3\baselineskip}{signature}\end{Form}%
    }}%
  }{}%
  {\MakeUppercase\am@author}\\
  \ifdefempty{\am@branch}{\am@rank}{\am@rank, \am@branch}\\
  \am@title
}
\newcommand{\am@closing}{%
  \vspace*{\baselineskip}%
  \noindent\parbox[t]{\textwidth}{%
    % The signature column sits at exactly 0.5\textwidth, which AR 25-50 fixes.
    % Character protrusion would drag the first glyph of each line a fraction of a
    % point out of that column -- correct for justified prose, wrong for a block
    % aligned to a rule. Off for the closing only.
    \microtypesetup{protrusion=false}%
    \noindent\am@authorityline\par
    \vspace*{4\baselineskip}%
    \noindent
    \parbox[t]{0.5\textwidth}{\am@encls}%
    \parbox[t]{0.5\textwidth}{\am@sigblock}%
  }\par
}

% add distribution
%
% \Needspace* reserves the heading plus two entries, so a list can still break --
% it just cannot leave its heading stranded (#1). \\* after the heading is belt
% and braces: \clubpenalty is set to 10000 by this class and is silently NOT
% applied here (measured: the page builder reports p=0 at the break), so the
% explicit penalty is what actually holds.
\newcommand{\am@do}[1]{#1\\}
\newcommand{\adddistro}[1]{\listadd{\am@list@distro}{#1}}
\newcommand{\am@distro}{%
  \ifdefvoid{\am@list@distro}{}{%
    \vspace{\baselineskip}%
    \Needspace*{3\baselineskip}%
    \noindent{}DISTRIBUTION:\\*%
    \forlistloop{\am@do}{\am@list@distro}}}

% add cf
\newcommand{\addcf}[1]{\listadd{\am@list@cf}{#1}}
\newcommand{\am@cf}{%
  \ifdefvoid{\am@list@cf}{}{%
    \vspace{\baselineskip}%
    \Needspace*{3\baselineskip}%
    \noindent{}CF:\\*%
    \forlistloop{\am@do}{\am@list@cf}}}



% Positioned against the paper directly rather than against TikZ's "current page"
% node. Inside shipout/background the origin IS the top-left corner of the sheet --
% measured, not assumed: a rectangle drawn from (0pt,0pt) to (\paperwidth,-\paperheight)
% emits exactly "0 0" to "612 -792" in the content stream of a letter page. So the
% paper corners are already in hand, and these two nodes need neither
% "remember picture" nor an aux-file round trip.
%
% inner sep=0pt is load-bearing, not tidiness. TikZ's default inner sep is 0.3333em,
% so the padding -- and therefore the mark's distance from the paper edge -- follows
% whatever font size happens to be current where the node is built. That differs
% between the old `background` package context and this hook, which moved both marks
% 4pt inward (top down, bottom up: symmetric, because each is padded away from its
% own anchor edge) while leaving their widths identical. Pinning it to zero makes
% the 24pt and 36pt offsets mean what they say, independent of ambient font size.
\newcommand{\am@classmark}[1]{%
  \begin{tikzpicture}[overlay]
    \node[align=center,anchor=north,inner sep=0pt,yshift=-24pt] at (0.5\paperwidth,0pt) {#1};
    \node[align=center,anchor=south,inner sep=0pt,yshift=36pt] at (0.5\paperwidth,-\paperheight) {#1};
  \end{tikzpicture}%
}

% Classification marks, top and bottom of every page, through the kernel's own
% shipout hook.
%
% This replaces \backgroundsetup{...}\BgThispage from the `background` package,
% which was loaded solely to mean "run this on every page". The kernel has had a
% hook for exactly that since 2020-10-01 (see \NeedsTeXFormat above), and
% \am@classmark already did all the positioning, so the package earned nothing.
% The pair it replaces also documented two contradictory intentions: the package
% option [pages=all] says every page, while \BgThispage means this page only.
%
% \color{black} preserves the package's color=black option: the mark's colour must
% not follow whatever colour happens to be current when the page is shipped out.
%
% The guard sits INSIDE the hook, so it is tested once per page rather than once at
% \begin{document}. \documentmark{} therefore emits nothing on every page, and a
% mark changed mid-document takes effect from that page on.
\AddToHook{shipout/background}{%
  \ifstrempty{\am@documentmark}{}{%
    \color{black}\am@classmark{\am@documentmark}%
  }%
}

\newcommand{\am@putlogo}{%
  \begin{tikzpicture}[remember picture, overlay]%
    \node[anchor=north west,inner sep=0pt,xshift=0.5in, yshift=-0.5in]%
      at (current page.north west) {\includegraphics[width=1in]{\am@logo}};%
  \end{tikzpicture}%
}


% \dodheader alternate implementation possibility:
%    https://www.ntg.nl/maps/31/15.pdf "Exact layout with LaTeX" Siep Kroonenberg
%    uses plain tex and picture environment

\newcommand{\department}[1]{\def\am@department{\ifstrempty{#1}{DEPARTMENT OF THE ARMY}{\MakeUppercase{#1}}}}\department{}
\newcommand{\address}[1]{\listadd{\am@list@address}{#1}}
% The second \fontsize argument is the declared leading, and it does NOT reach the page --
% see the note on \setstretch in \dodheader. It is written equal to the type size, the
% conventional "no special leading" idiom, rather than a specific-looking number that
% would invite someone to tune it. Measured: changing it to 10.11pt, the pitch actually
% observed, produces byte-identical output.
\newcommand{\am@do@address}[1]{\fontsize{8pt}{8pt}\selectfont\textbf{\MakeUppercase{#1}}\\}
\newcommand{\dodheader}{%
  % Defaults apply only when the document supplied no address at all. This used to
  % test {<}{2} on a counter, so a document supplying exactly ONE address fell below
  % the threshold and had all three placeholders appended to its real line -- a
  % four-line letterhead beginning with the truth and continuing with boilerplate.
  \ifdefvoid{\am@list@address}{%
    \address{Organizational Name/Title}
	 \address{Standardized Street Address}
	 \address{City, State~~12345-1234}
  }{}
  \thispagestyle{plain}%
  \begin{tikzpicture}[remember picture, overlay]%
    % \setstretch{0.7} is load-bearing, and by accident (#18). It scales every declared
    % \baselineskip to 0.7x, which puts the letterhead's leading below the height+depth of
    % the lines being set. TeX then abandons \baselineskip entirely and inserts \lineskip
    % glue instead, so the pitch becomes height + depth + \lineskip -- nothing the source
    % declares. That is why the two gaps differ: 11.54pt after the 10pt DEPARTMENT line and
    % 10.11pt between the 8pt address lines, neither of them 5pt, 0.7x anything, or equal.
    %
    % Measured, so it is not guesswork: deleting \setstretch moves the address pitch to
    % 14.45pt (the ambient 12pt \baselineskip), and changing the declared leading with
    % \setstretch in place changes nothing at all.
    %
    % Do not "fix" this by deleting \setstretch or tuning a \fontsize leading. AR 25-50
    % prescribes no letterhead geometry -- 1-16 delegates it to a template on APD's
    % website, and 1-19 only recommends 12pt generally -- so there is no regulation figure
    % to target, and today's geometry is preserved deliberately.
    \setstretch{0.7}\fontfamily\sfdefault\selectfont%
    \node[align=center,anchor=north,inner sep=0pt,yshift=-0.625in] at (current page.north) {%
      \fontsize{10pt}{10pt}\selectfont\textbf{\am@department}\\
      \forlistloop{\am@do@address}{\am@list@address}
    };%%
  \end{tikzpicture}%%
  \par%there must be a \par here, or things break!
  \vspace{-2\baselineskip}
  %conditional block for optional suspense date:
  \ifstrempty{\am@suspensedate}{}{%
    \vspace{-2\baselineskip}
    \noindent\,\hspace*{\fill}\am@suspensedate\\
    \vspace{\baselineskip}}
  \noindent\am@officesymbol\hspace*{\fill}\am@signaturedate\\
  \am@memoline
  \vspace{\baselineskip}
  \noindent\am@subject
  \par
}
