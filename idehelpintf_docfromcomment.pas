unit IDEHelpIntf_docFromComment;

interface

type  //
 THelpIDE_DocFormComments_textToHTML=function(const Text:string; out htmlText:string):boolean;

var   // can be set by a package
  HelpIDE_DocFormComments_textToHTML:THelpIDE_DocFormComments_textToHTML;

implementation

initialization
  HelpIDE_DocFormComments_textToHTML:=nil;
end.
