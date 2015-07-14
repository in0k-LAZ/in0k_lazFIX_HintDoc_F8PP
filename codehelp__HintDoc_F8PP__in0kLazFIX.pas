unit codehelp__HintDoc_F8PP__in0kLazFIX;

{%region ----- УСТАНОВКА ------------------------------------------ /fold}
//  !!! Все действия на свой страх и риск !!!
//  1.  скопировать этот файл в директорию `LazarusDir\ide`
//  2.  открыть для редактирования файл `LazarusDir\ide\CodeHelp.pas`
//  2.1 найти определение `TCodeHelpManager = class(TComponent)`
//  2.2 в нем добавить директиву `virtual` для методов
//          * GetHTMLDeclarationHeader
//          * GetPasDocCommentsAsHTML
//          * SourcePosToFPDocHint
{%endregion -------------------------------------------------------------------}

{%region ----- НАСТРОЙКИ ------------------------------------------ /fold}
// "Ссылка" на указание местоположения в исходном коде.
// использовать тег Таблицы для вывода кусков подсказок





    {$define codehelp__HintDoc_F8PP__in0kLazFIX__useTable}

// выводить отладочную информацию
    {$define codehelp__HintDoc_F8PP__in0kLazFIX__DEBUG}

// тестирование сообщений компилятора при обработке этого файла.
    {.$define codehelp__HintDoc_F8PP__in0kLazFIX__testMessagesOnCOMPILE}
    {$ifdef codehelp__HintDoc_F8PP__in0kLazFIX__testMessagesOnCOMPILE}
    {$hint -- codehelp__HintDoc_F8PP__in0kLazFIX__testMessagesOnCOMPILE -- ON}
    {$endIf}
{%endregion -------------------------------------------------------------------}

{$mode objfpc}{$H+}

interface

uses Classes, sysutils,
    // от лазаря
    CodeTree, FindDeclarationTool, BasicCodeTools, CodeCache, CodeHelp,
    PascalParserTool,
    // от меня
    IDEHelpIntf_docFromComment;

type

 TCodeHelpManager__HintDoc_F8PP__in0kLazIdeFIX=class(TCodeHelpManager)
  //--- внутренние убранство
  protected
    procedure _TXT_res_Tbr_(var resText:string);
    procedure _TXT_res_added_(var resText:string; const addText:string);
    procedure _TXT_added_res_(const addText:string; var resText:string);

  protected
    {$ifdef codehelp__HintDoc_F8PP__in0kLazFIX__DEBUG}
    function  _TXT_make_DBG_txt_(const text:string):string;
    procedure _TXT_res_debug_(var resText:string; const dbgText:string); inline;
    procedure _TXT_debug_res_(const dbgText:string; var resText:string); inline;
    {$endif}

  //--- украшение выводимого HINT`а
  public
    function SourcePosToFPDocHint(const aFilename:string; X,Y:integer; Caption:string=''):string; override;
    function GetHTMLDeclarationHeader(Tool:TFindDeclarationTool; Node:TCodeTreeNode; XYPos:TCodeXYPosition): string; override;

  //--- альтернативное формирование строки HintFromComment
  public
    function GetPasDocCommentsAsHTML(Tool:TFindDeclarationTool; Node:TCodeTreeNode):string; override;
  protected
    function _ink_getComment_TextToHTML_oldMode(const Text:string):string;
    function _ink_getComment_TextToHTML        (const Text:string):string;
  protected
    function _ink_getComment  (const Tool:TFindDeclarationTool; const Node:TCodeTreeNode):string;
    function _ink_getComments (const Tool:TFindDeclarationTool; const NodeInterface,NodeImplementation:TCodeTreeNode):string;
    function _ink_getNodePlace(const Tool:TFindDeclarationTool; const Node:TCodeTreeNode):TCodeTreeNodeDesc;
  end;

implementation

const //< украшение выводимого
 _cTxt_ttlLnkSRC='&#9755;'; //< символ ВМЕСТО полного пути в ссылке на исходник

{%region --- внутренние убранство --------------------------------- /fold}

const
 _cTxt_BrHtmlTAG='<br>';
 _cTxt_BrLineEnd=_cTxt_BrHtmlTAG+LineEnding;

// @ добавить символ "ПереводСтроки".
procedure TCodeHelpManager__HintDoc_F8PP__in0kLazIdeFIX._TXT_res_Tbr_(var resText:string);
begin
    if resText<>'' then resText:=resText+_cTxt_BrLineEnd;
end;

// @ собрать строку.
//   `resText+<br>+addText`
procedure TCodeHelpManager__HintDoc_F8PP__in0kLazIdeFIX._TXT_res_added_(var resText:string; const addText:string);
begin
    if resText='' then resText:=addText
   else
    if addText<>'' then resText:=resText+_cTxt_BrLineEnd+addText;
end;


{$ifdef codehelp__HintDoc_F8PP__in0kLazFIX__DEBUG}

const

 _cTXT_DBG_befo='<font size=-2 color=gray>';
 _cTXT_DBG_afte='</font>';

function TCodeHelpManager__HintDoc_F8PP__in0kLazIdeFIX._TXT_make_DBG_txt_(const text:string):string;
begin
    result:=_cTXT_DBG_befo+text+_cTXT_DBG_afte;
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

procedure TCodeHelpManager__HintDoc_F8PP__in0kLazIdeFIX._TXT_res_debug_(var resText:string; const dbgText:string);
begin
    _TXT_res_added_(resText, _TXT_make_DBG_txt_(dbgText) );
end;

procedure TCodeHelpManager__HintDoc_F8PP__in0kLazIdeFIX._TXT_debug_res_(const dbgText:string; var resText:string);
begin
    _TXT_added_res_( _TXT_make_DBG_txt_(dbgText) ,resText);
end;

{$endif}

// @ собрать строку.
//   `addText+<br>+resText`
procedure TCodeHelpManager__HintDoc_F8PP__in0kLazIdeFIX._TXT_added_res_(const addText:string; var resText:string);
begin
    if resText='' then resText:=addText
   else
    if addText<>'' then resText:=addText+_cTxt_BrLineEnd+resText;
end;

{%endregion}

{%region --- украшение вывоимого HINT ----------------------------- /fold}

// @ Cсылка на МЕСТО в ИсходномКоде.
//  по сути просто добавляем `TITLE=sourcePatch` к тегу `A`.
function TCodeHelpManager__HintDoc_F8PP__in0kLazIdeFIX.SourcePosToFPDocHint(const aFilename:string; X,Y:integer; Caption:string=''):string;
var Link: String;
    Titl: String;
    i   : Integer;
begin
    Result:='';
    if aFilename='' then exit;
    // формируем линк
    Link:=aFilename;
    if Y>=1 then begin
        Link:=Link+'('+IntToStr(Y);
        if X>=1 then Link:=Link+','+IntToStr(X);
        Link:=Link+')';
    end;
    // делаем титл
    Titl:=Link;
    // теперь заголовок
    if Caption='' then begin
        Caption:=Titl;
        // make caption breakable into several lines
        for i:=length(Caption)-1 downto 1 do begin
            if Caption[i]=PathDelim then
            System.Insert('<wbr/>',Caption,i+1);
        end;
    end;
    // вся процедура ради этой строки
    Result:='<a href="source://'+Link+'" title="'+Titl+'">'+Caption+'</a>';
end;

// @ описание ОБЪЕКТА
function TCodeHelpManager__HintDoc_F8PP__in0kLazIdeFIX.GetHTMLDeclarationHeader(Tool:TFindDeclarationTool; Node:TCodeTreeNode; XYPos:TCodeXYPosition):string;
var CTHint:string;
begin
    // add declaration
    CTHint:=Tool.GetSmartHint(Node,XYPos,false);
    result:='<nobr>'+SourceToFPDocHint(CTHint)+'</nobr>';
    // add link to declaration
    if XYPos.Code=nil then Tool.CleanPosToCaret(Node.StartPos,XYPos);
    result:=inherited SourcePosToFPDocHint(XYPos,_cTxt_ttlLnkSRC)+'&nbsp;'+result;
    // decoration
    result:='<div class="header">'+result+'</div>'+LineEnding;
end;

{%endregion}

{%region --- альтернативное формирование строки HintFromComment --- /fold}

function TCodeHelpManager__HintDoc_F8PP__in0kLazIdeFIX._ink_getComment_TextToHTML_oldMode(const Text:string):string;
begin
    result:=trim(Text);
    if result<>'' then result:=self.TextToHTML(result);
    if result<>'' then result:='<span class="comment">'+result+'</span>';
end;

function TCodeHelpManager__HintDoc_F8PP__in0kLazIdeFIX._ink_getComment_TextToHTML(const Text:string):string;
begin
    result:='';
    if NOT (
             Assigned(HelpIDE_DocFormComments_textToHTML)
            and
             HelpIDE_DocFormComments_textToHTML(Text,result)
           )
    then begin //< ф. НЕТ или она выполнилась с FALSE
        result:=_ink_getComment_TextToHTML_oldMode(Text);
    end
end;

// найти и сформировать строку HintFromComment для узла.
// ---
// ворованно из пародителя `GetPasDocCommentsAsHTML`
function TCodeHelpManager__HintDoc_F8PP__in0kLazIdeFIX._ink_getComment(const Tool: TFindDeclarationTool; const Node:TCodeTreeNode):string;
var ListOfPCodeXYPosition:TFPList;
    CodeXYPos            :PCodeXYPosition;
    CommentCode          :TCodeBuffer;
    CommentStart         :integer;
    i                    :integer;
begin
    try result:='';
        if Tool.GetPasDocComments(Node,ListOfPCodeXYPosition) then begin
            if Assigned(ListOfPCodeXYPosition) then begin
                if ListOfPCodeXYPosition.Count>0 then begin
                    //--- вытягиваем комментарий
                    for i:= 0 to ListOfPCodeXYPosition.Count - 1 do begin
                        CodeXYPos  :=PCodeXYPosition(ListOfPCodeXYPosition[i]);
                        CommentCode:=CodeXYPos^.Code;
                        CommentCode.LineColToPosition(CodeXYPos^.Y,CodeXYPos^.X,CommentStart);
                        if (CommentStart<1) or (CommentStart>CommentCode.SourceLength) then continue;
                        //             : оно вырезает IDE символы комментария
                        Result:=Result+ExtractCommentContent(CommentCode.Source,CommentStart, Tool.Scanner.NestedComments,true,true,true)+LineEnding;
                    end;
                    //--- упаковываем
                    if Result<>'' then begin
                         result:=_ink_getComment_TextToHTML(trim(result));
                         {$ifDef codehelp__HintDoc_F8PP__in0kLazFIX__useTable}
                             result:='<table border=0 cellpadding=0 cellspacing=0><tr><td width="1" valign="top" align=left>'+inherited SourcePosToFPDocHint(CodeXYPos^,_cTxt_ttlLnkSRC)+'&nbsp;</td><td width=100% valign="top" align="left">'+result+'</td></tr></table>';
                         {$else}
                             result:=inherited SourcePosToFPDocHint(CodeXYPos^,_cTxt_ttlLnkSRC)+' '+result;
                         {$endif}
                    end;
                end;
                FreeListOfPCodeXYPosition(ListOfPCodeXYPosition);
            end;
        end;
    except
        {$ifDef codehelp__HintDoc_F8PP__in0kLazFIX__DEBUG}
        on E:Exception do _TXT_res_debug_(result,'[dbg]-_ink_getComment: ERR-EXCEPT'+'<br>'+LineEnding+E.ClassName+' : '+E.Message);
        {$endIf}
    end;
end;

// найти и сформировать строку HintFromComment для узлов из раздела из обеих
// секций файла исходного кода (Interface и Implementation)
function TCodeHelpManager__HintDoc_F8PP__in0kLazIdeFIX._ink_getComments(const Tool:TFindDeclarationTool; const NodeInterface,NodeImplementation:TCodeTreeNode):string;
begin
    result:='';
    if Assigned(NodeInterface)      then begin
        {$ifDef codehelp__HintDoc_F8PP__in0kLazFIX__DEBUG}
       _TXT_res_debug_(result,'[dbg]-_ink_getComments:FROM NodeInterface');
        {$endIf}
       _TXT_res_added_(result,_ink_getComment(Tool,NodeInterface));
    end;
    if Assigned(NodeImplementation) then begin
        {$ifDef codehelp__HintDoc_F8PP__in0kLazFIX__DEBUG}
       _TXT_res_debug_(result,'[dbg]-_ink_getComments:FROM NodeImplementation');
        {$endIf}
       _TXT_res_added_(result,_ink_getComment(Tool,NodeImplementation));
    end;
end;

// определить местоположение Узла в разделах Модуля
function TCodeHelpManager__HintDoc_F8PP__in0kLazIdeFIX._ink_getNodePlace(const Tool:TFindDeclarationTool; const Node:TCodeTreeNode):TCodeTreeNodeDesc; //< asdfasdfasdf asdf
begin
    result:=ctnNone;
    if tool.NodeHasParentOfType(Node,ctnInterface) then result:=ctnInterface
   else
    if tool.NodeHasParentOfType(Node,ctnImplementation) then result:=ctnImplementation
end;

//------------------------------------------------------------------------------

// альтернативное формирование строки HintFromComment
function TCodeHelpManager__HintDoc_F8PP__in0kLazIdeFIX.GetPasDocCommentsAsHTML(Tool: TFindDeclarationTool; Node: TCodeTreeNode): string;
{%region --- параметры поиска ПРОЦЕДУР /fold}
const ProcAttr_fndPROCEDURE= [
    phpWithStart,          // proc keyword e.g. 'function', 'class procedure'
    //phpWithoutClassKeyword,// without 'class' proc keyword
    phpAddClassName,       // extract/add 'ClassName.'
    //phpWithoutClassName,   // skip classname
    //phpWithoutName,        // skip function name
    //phpWithoutParamList,   // skip param list
    phpWithVarModifiers,   // extract 'var', 'out', 'const'
    phpWithParameterNames, // extract parameter names
    //phpWithoutParamTypes,  // skip colon, param types and default values
    phpWithHasDefaultValues,// extract the equal sign of default values
    phpWithDefaultValues,  // extract default values
    phpWithResultType,     // extract colon + result type
    //phpWithOfObject,       // extract 'of object'
    //phpWithCallingSpecs,   // extract cdecl; extdecl; popstack;
    //phpWithProcModifiers,  // extract forward; alias; external; ...
    //phpWithComments,       // extract comments and spaces
    phpInUpperCase        // turn to uppercase
    //phpCommentsToSpace,    // replace comments with a single space
                           //  (default is to skip unnecessary space,
                           //    e.g 'Do   ;' normally becomes 'Do;'
                           //    with this option you get 'Do ;')
    //phpWithoutBrackets,    // skip start- and end-bracket of parameter list
    //phpWithoutSemicolon,   // skip semicolon at end
    //phpDoNotAddSemicolon,  // do not add missing semicolon at end
    // search attributes:
    //phpIgnoreForwards     // skip forward procs
    //hpIgnoreProcsWithBody,// skip procs with begin..end
    //phpIgnoreMethods,      // skip method bodies and definitions
    //phpOnlyWithClassname,  // skip procs without the right classname
    // phpFindCleanPosition,  // read til ExtractSearchPos
    // parse attributes:
    //phpCreateNodes         // create nodes during reading
    ];
{%endregion}
begin
    TRY Result:='';
        if (Tool=nil)or(Node=nil) then exit;
        {$ifDef codehelp__HintDoc_F8PP__in0kLazFIX__DEBUG}
          _TXT_res_debug_(result,'[dbg]-fileNAME:'+Tool.MainFilename);
        {$endIf}
        Tool.MainFilename;
        if node.Desc in [ctnProcedure,ctnProcedureHead] then begin //< обработка процедур и функций
             // надо ТОЧНО спозиционироваться на ctnProcedure
             if Node.Desc=ctnProcedureHead then Node:=Node.Parent;
             if Node.Desc=ctnProcedure then begin
                 {$ifDef codehelp__HintDoc_F8PP__in0kLazFIX__DEBUG}
                   _TXT_res_debug_(result,'[dbg]-ProcHead:'+Tool.ExtractProcHead(Node,ProcAttr_fndPROCEDURE));
                 {$endIf}
                 // в зависимости от место положения, исчем HintFromComment
                 case _ink_getNodePlace(Tool,node) of
                    ctnInterface: begin
                            {$ifDef codehelp__HintDoc_F8PP__in0kLazFIX__DEBUG}
                           _TXT_res_debug_(result,'[dbg]-from: ctnInterface');
                            {$endIf}
                           _TXT_res_added_(result,_ink_getComments(Tool,node,Tool.FindCorrespondingProcNode(node,ProcAttr_fndPROCEDURE)));
                        end;
                    ctnImplementation: begin
                            {$ifDef codehelp__HintDoc_F8PP__in0kLazFIX__DEBUG}
                           _TXT_res_debug_(result,'[dbg]-from: ctnImplementation');
                            {$endIf}
                           _TXT_res_added_(result,_ink_getComments(Tool,Tool.FindCorrespondingProcNode(node,ProcAttr_fndPROCEDURE),node));
                        end
                    else begin //< к ТАКОМУ повороту мы не готовы, попросим Папу
                            {$ifDef codehelp__HintDoc_F8PP__in0kLazFIX__DEBUG}
                           _TXT_res_debug_(result,'[dbg]-from: err-wrong _ink_getNodePlace [used&nbsp;inherited&nbsp;GetPasDocCommentsAsHTML]');
                            {$endIf}
                           _TXT_res_added_(result,inherited GetPasDocCommentsAsHTML(Tool,Node));
                        end
                 end;
             end
             else begin //< ошибочка вышла, пусть Папа отвечает
                 {$ifDef codehelp__HintDoc_F8PP__in0kLazFIX__DEBUG}
                _TXT_res_debug_(result,'[dbg]-from: ERR : not found Node.Desc=ctnProcedure [used&nbsp;inherited&nbsp;GetPasDocCommentsAsHTML]');
                 {$endIf}
                 result:=inherited GetPasDocCommentsAsHTML(Tool,Node);
             end;
        end
        else begin //< тут все вопросы к Папе, он за нас ответит.
            {$ifDef codehelp__HintDoc_F8PP__in0kLazFIX__DEBUG}
               _TXT_added_res_('[dbg]-unSupported node.Desc [used&nbsp;inherited&nbsp;GetPasDocCommentsAsHTML]',result);
            {$endIf}
            result:=inherited GetPasDocCommentsAsHTML(Tool,Node);
        end;
    EXCEPT
        {$ifDef codehelp__HintDoc_F8PP__in0kLazFIX__DEBUG}
        on E:Exception do result:='ERROR'+'<br>'+LineEnding+E.ClassName+' : '+E.Message;
        {$else}
        result:=''; //< некрасиво ... но не понятно как ещё
        {$endIf}
    END;
end;

{%endregion}

{$ifdef codehelp__HintDoc_F8PP__in0kLazFIX__testMessagesOnCOMPILE}
{$ERROR -- codehelp__HintDoc_F8PP__in0kLazFIX__testMessagesOnCOMPILE -- ON}
{$endIf}

end.

