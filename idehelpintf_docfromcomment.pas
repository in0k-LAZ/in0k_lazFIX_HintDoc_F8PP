unit IDEHelpIntf_docFromComment;

{%region ----- УСТАНОВКА ------------------------------------------ /fold}
//  !!! Все действия на свой страх и риск !!!
//  1.  скопировать этот файл в директорию `LazarusDir\components\ideintf`
//  2.  иногда приходится ещё допиливать :-(
//      открыть для редактирования файл `LazarusDir\components\ideintf\IDEHelpIntf.pas`
//  2.1 добавить в раздел `uses` ссылку на ЭТОТ файл `IDEHelpIntf_docFromComment`
{%endregion -------------------------------------------------------------------}

interface

type  // вводимый мною тип, для обработки текста
 THelpIDE_DocFormComments_textToHTML=function(const Text:string; out htmlText:string):boolean;

var   // can be set by a package
  HelpIDE_DocFormComments_textToHTML:THelpIDE_DocFormComments_textToHTML;

implementation

initialization
  HelpIDE_DocFormComments_textToHTML:=nil;
end.
