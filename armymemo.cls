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

\ProvidesClass{armymemo}[2026/03/29 0.3.0 Army Memorandum Class]
\NeedsTeXFormat{LaTeX2e}

\LoadClass[
  12pt,
  oneside,
  headings=small,
  DIV=15
]{scrartcl}

\AtBeginDocument{%
  \ifstrempty{\am@documentmark}{}{%
    \backgroundsetup{opacity=1, scale=1, angle=0,contents={\am@classmark{\am@documentmark}}}\BgThispage
  }
  \am@putlogo%
  \dodheader%
  \vspace*{1\baselineskip}
}

\AtEndDocument{%
  \setlength{\parskip}{0pt}
  \vspace*{\baselineskip}
  \noindent\am@authorityline\\
  \vspace*{4\baselineskip}%
  \begin{tikzpicture}[overlay]
    \node [align=left, anchor=west, inner sep=0, outer sep=0] at (0.5\textwidth,-10pt){% TODO BUG - why a 10pt offset? I don't know.
      {\MakeUppercase \am@author}\\
      \am@rank, \am@branch\\
      \am@title
    };
    \ifbool{am@digsig}{%
      \node [align=left, anchor=south west, inner sep=0, outer sep=0] at (0.5\textwidth,\baselineskip){%
        \begin{Form}\digsigfield{3in}{3\baselineskip}{signature}\end{Form}%
      };
    }{}
  \end{tikzpicture}%
  \am@encls%
  \am@distro%
  \am@cf%
}




% Setting penalties for widows and orphans: broken paragraphs with only one line
% at the top or bottom of the page. This messes up other formatting leaving lots
% of space at the bottom of some pages that requires manual intervention.
%% http://www.tex.ac.uk/cgi-bin/texfaq2html?label=widows
\widowpenalty=10000
\clubpenalty=10000

% required for conditionals (already implied)
\RequirePackage{etoolbox}
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
% required for graphics placement
\RequirePackage{tikz}
% for overlay of classification markings without affecting layout
\RequirePackage[pages=all,color=black]{background}
% required to enable high-depth nested lists, and custom numbering
\RequirePackage{enumitem}
\renewlist{enumerate}{enumerate}{9}
\setlistdepth{9}
% required for \setstretch used in header
\RequirePackage{setspace}



% for margins
\RequirePackage{calc}
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
  % assume two lines for headers
  % TODO: test with longer subject lines, assuming it will break
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
\cofoot[]{\thepage}
\pagestyle{scrheadings}
\setkomafont{pagehead}{\sffamily\upshape}


% process class options
\newbool{am@digsig}
\DeclareOption{digsig}{\booltrue{am@digsig}}
\DeclareOption*{\PassOptionsToClass{\CurrentOption}{scrartcl}}
\ProcessOptions\relax

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
\setlist[1]{labelwidth=12pt,labelsep=4pt,leftmargin=0pt,itemindent=16pt,align=left,
  after={\nopagebreak\@nobreaktrue}}
\setlist[2]{labelwidth=12pt,labelsep=4pt,leftmargin=0pt,itemindent=0.5in,align=left}
\setlist[3]{labelwidth=12pt,labelsep=4pt,leftmargin=0pt,itemindent=0.75in,align=left}
\setlist[4]{labelwidth=12pt,labelsep=4pt,leftmargin=0pt,itemindent=0.75in,align=left}

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
\newcounter{am@memoline@count}
\newcommand{\addmemoline}[1]{\stepcounter{am@memoline@count}\listadd{\am@list@memolines}{#1}}
\newcommand{\mfr}{\addmemoline{MEMORANDUM FOR RECORD}}
\newcommand{\memoline}[1]{\addmemoline{#1}}
\newcommand{\am@domemoline}[1]{\vspace{\baselineskip}\noindent{}#1\\}
\newcounter{am@memothru@count}
\newcommand{\multimemothru}[1]{\stepcounter{am@memothru@count}\listadd{\am@list@memothru}{#1}}
\newcommand{\am@do@memothru}[1]{\noindent{}\hangindent=0.25in{}#1\\}
\newcounter{am@memofor@count}
\newcommand{\multimemofor}[1]{\stepcounter{am@memofor@count}\listadd{\am@list@memofor}{#1}}
\newcommand{\am@do@memofor}[1]{\noindent{}\hangindent=0.25in{}#1\\}

\newcommand{\am@memoline}{%
  % if there is nothing specified, add "memorandum for record"
  \ifnumcomp{\value{am@memoline@count}}{=}{0}{%
    \ifnumcomp{\value{am@memothru@count}}{=}{0}{
      \ifnumcomp{\value{am@memofor@count}}{=}{0}{
        \mfr
      }{}
    }{}
  }{}
  % otherwise, skip a space and begin
  \vspace{\baselineskip}
  % if there are multimemothru lines:
  \ifnumcomp{\value{am@memothru@count}}{>}{0}{%
    \vspace{\baselineskip}
    MEMORANDUM THRU\\
    \vspace{\baselineskip}
    % loop through the thru lines with hanging indent
    \forlistloop{\am@do@memothru}{\am@list@memothru}}
  {}
  \ifnumcomp{\value{am@memofor@count}}{>}{0}{
    \ifnumcomp{\value{am@memothru@count}}{>}{0}{%
      \vspace{\baselineskip}
      FOR\\ % if there is a thru, it should just be for, not memorandum for
      \vspace{\baselineskip}
    }{%
      \vspace{\baselineskip}
      MEMORANDUM FOR\\ % if there is no thru
      \vspace{\baselineskip}
    }
    \forlistloop{\am@do@memofor}{\am@list@memofor}}
  {}
  \ifnumcomp{\value{am@memoline@count}}{>}{0}{
    % after dealing with special cases, add the other lines from \addmemoline or \memoline
    % these lines must begin with any labels such as "MEMORANDUM FOR" or "MEMORANDUM THRU" or "FOR"
    % allow for possibility of no multi lines.
    \forlistloop{\am@domemoline}{\am@list@memolines}
  }
  {}
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
\renewcommand{\author}[1]{\def \am@author{#1}}\author{}
\newcommand{\rank}[1]{\def \am@rank{#1}}\rank{}
\newcommand{\branch}[1]{\def \am@branch{#1}}\branch{}
\renewcommand{\title}[1]{\def \am@title{#1}}\title{}


% add enclosures along with a total count
% use \enclsnocount to print "Encls" without a numeric count (AR 25-50 Figure 4-4)
\newcommand{\am@do@encl}[1]{\item #1 }
\newcounter{am@encl@count}
\newbool{am@encls@nocount}
\newcommand{\enclsnocount}{\booltrue{am@encls@nocount}}
\newcommand{\addencl}[1]{\stepcounter{am@encl@count}\listadd{\am@list@encls}{#1}}
\newcommand{\am@encls}{%
  \ifnumcomp{\value{am@encl@count}}{=}{0}{%
  }{%
    \ifbool{am@encls@nocount}{%
      \noindent{}Encls%
      \begin{enumerate}[topsep=0pt,itemsep=0pt,parsep=0pt,leftmargin=16pt,itemindent=0pt,align=left,label={\arabic*.}]
        \forlistloop{\am@do@encl}{\am@list@encls}
      \end{enumerate}
    }{%
      \ifnumcomp{\value{am@encl@count}}{=}{1}{%
        \noindent{}Encl%
        \begin{enumerate}[topsep=0pt,itemsep=0pt,parsep=0pt,itemindent=0pt,align=left,label={}]
          \forlistloop{\am@do@encl}{\am@list@encls}
        \end{enumerate}
      }{%
        \noindent\theam@encl@count{} Encls%
        \begin{enumerate}[topsep=0pt,itemsep=0pt,parsep=0pt,leftmargin=16pt,itemindent=0pt,align=left,label={\arabic*.}]
          \forlistloop{\am@do@encl}{\am@list@encls}
        \end{enumerate}%
      }%
    }%
  }
}

% add distribution, with an option for continuation on the next page
\newcommand{\am@do}[1]{#1\\}
\newcounter{am@distro@count}
\newcommand{\adddistro}[1]{\stepcounter{am@distro@count}\listadd{\am@list@distro}{#1}}
\newcommand{\am@distro}{%
  \ifnumcomp{\value{am@distro@count}}{>}{0}{%
    \vspace{\baselineskip}%
    \noindent{}DISTRIBUTION:\\%
    \forlistloop{\am@do}{\am@list@distro}}{}}
% insert \continuedistro at the beginning of an \adddistro list in order to push it to the next page
\newcommand{\continuedistro}{\adddistro{(CONTINUED)\clearpage
    DISTRIBUTION:}}

% add cf, with an option for continuation on the next page
\newcounter{am@cf@count}
\newcommand{\addcf}[1]{\stepcounter{am@cf@count}\listadd{\am@list@cf}{#1}}
\newcommand{\am@cf}{%
  \ifnumcomp{\value{am@cf@count}}{>}{0}{%
    \vspace{\baselineskip}%
    \noindent{}CF:\\
    \forlistloop{\am@do}{\am@list@cf}}{}}
% insert \continuecf at the beginning of an \addcf list in order to push it to the next page
\newcommand{\continuecf}{\addcf{(CONTINUED)\clearpage
    CF:}}



\newcommand{\am@classmark}[1]{%
  \begin{tikzpicture}[remember picture, overlay]
    \node[align=center,anchor=north,yshift=-24pt] at (current page.north) {#1};
    \node[align=center,anchor=south,yshift=36pt] at (current page.south) {#1};
  \end{tikzpicture}
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

\newcounter{am@address@count}
\newcommand{\department}[1]{\def\am@department{\ifstrempty{#1}{DEPARTMENT OF THE ARMY}{\MakeUppercase{#1}}}}\department{}
\newcommand{\address}[1]{\stepcounter{am@address@count}\listadd{\am@list@address}{#1}}
\newcommand{\am@do@address}[1]{\fontsize{8pt}{5pt}\selectfont\textbf{\MakeUppercase{#1}}\\}
\newcommand{\dodheader}{%
  \ifnumcomp{\value{am@address@count}}{<}{2}{
    \address{Organizational Name/Title}
	 \address{Standardized Street Address}
	 \address{City, State~~12345-1234}
  }{}
  \thispagestyle{plain}%
  \begin{tikzpicture}[remember picture, overlay]%
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
