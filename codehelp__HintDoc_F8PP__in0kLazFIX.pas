unit codehelp__HintDoc_F8PP__in0kLazFIX;

{$mode objfpc}{$H+}

{----- НАСТРОЙКИ --------------------------------------------------------------}

// "Ссылка" на указание местоположения в исходном коде.
// использовать тег Таблицы для вывода кусков подсказок
    {$define codehelp__HintDoc_F8PP__in0kLazFIX__useTable}

// выводить отладочную информацию
    {.$define codehelp__HintDoc_F8PP__in0kLazFIX__DEBUG}

{------------------------------------------------------------------------------}
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
    procedure _TXT_res_add_(var resText:string; const addText:string);
    procedure _TXT_add_res_(const addText:string; var resText:string);

  //--- украшение выводимого HINT`а
  public
    function SourcePosToFPDocHint(const aFilename:string; X,Y:integer; Caption:string=''):string; override;
    function GetHTMLDeclarationHeader(Tool:TFindDeclarationTool; Node:TCodeTreeNode; XYPos:TCodeXYPosition): string; override;

  //--- альтернативное формирование строки HintFromComment
  public
    function GetPasDocCommentsAsHTML(Tool:TFindDeclarationTool; Node:TCodeTreeNode):string; override;
  protected
    function _ink_getComment_TextToHTML_oldMode(const Text:string):string;
    function _ink_getComment_TextToHTML(const Text:string):string;
    function _ink_getComment(const Tool: TFindDeclarationTool; const Node:TCodeTreeNode):string;
    function _ink_getComments(const Tool:TFindDeclarationTool; const NodeInterface,NodeImplementation:TCodeTreeNode):string;
    function _inc_getNodePlace(const Tool:TFindDeclarationTool; const Node:TCodeTreeNode):TCodeTreeNodeDesc;
  end;

implementation

const //< украшение выводимого
 _cTxt_ttlLnkSRC='&#9755;'; //< символ ВМЕСТО полного пути в ссылке на исходник

{%region --- внутренние убранство --------------------------------- /fold}

const
 _cTxt_BrHtmlTAG='<br>';
 _cTxt_BrLineEnd=_cTxt_BrHtmlTAG+LineEnding;

procedure TCodeHelpManager__HintDoc_F8PP__in0kLazIdeFIX._TXT_res_Tbr_(var resText:string);
begin
    if resText<>'' then resText:=resText+_cTxt_BrLineEnd;
end;

procedure TCodeHelpManager__HintDoc_F8PP__in0kLazIdeFIX._TXT_res_add_(var resText:string; const addText:string);
begin
    if resText='' then resText:=addText
   else
    if addText<>'' then resText:=resText+_cTxt_BrLineEnd+addText;
end;

procedure TCodeHelpManager__HintDoc_F8PP__in0kLazIdeFIX._TXT_add_res_(const addText:string; var resText:string);
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
    //
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
    //---
    if Assigned(HelpIDE_DocFormComments_textToHTML) then begin
        if not HelpIDE_DocFormComments_textToHTML(Text,result) then begin
            result:=_ink_getComment_TextToHTML_oldMode(Text);
        end;
    end
    else result:=_ink_getComment_TextToHTML_oldMode(Text);
end;

// найти и сформировать строку HintFromComment для узла. ворованно из пародителя
function TCodeHelpManager__HintDoc_F8PP__in0kLazIdeFIX._ink_getComment(const Tool: TFindDeclarationTool; const Node:TCodeTreeNode):string;
var ListOfPCodeXYPosition: TFPList;
    NestedComments: Boolean;
    i: Integer;
    CommentCode: TCodeBuffer;
    CommentStart: integer;
    CodeXYPos: PCodeXYPosition;
    CommentStr: String;
begin
    try result:='';
        if not Tool.GetPasDocComments(Node,ListOfPCodeXYPosition) then exit;
        if ListOfPCodeXYPosition=nil then exit;
        NestedComments := Tool.Scanner.NestedComments;

        if ListOfPCodeXYPosition.Count>0 then begin
            //--- вытягиваем комментарий
            for i:= 0 to ListOfPCodeXYPosition.Count - 1 do begin
                CodeXYPos := PCodeXYPosition(ListOfPCodeXYPosition[i]);
                CommentCode := CodeXYPos^.Code;
                CommentCode.LineColToPosition(CodeXYPos^.Y,CodeXYPos^.X,CommentStart);
                if (CommentStart<1) or (CommentStart>CommentCode.SourceLength) then continue;
                Result:=Result+ExtractCommentContent(CommentCode.Source,CommentStart, NestedComments,true,true,true)+LineEnding;
            end;
            //--- упаковываем
            if Result<>'' then begin
                 result:=_ink_getComment_TextToHTML(trim(result));
                 {$ifDef codehelp__HintDoc_F8PP__in0kLazFIX__useTable}
                     result:='<table border=0 cellpadding=0 cellspacing=0><tr><td width="1" valign="top" align=left>'+inherited SourcePosToFPDocHint(CodeXYPos^,_cTxt_ttlLnkSRC)+'&nbsp;</td><td width=100% valign="top" align="left">'+result+'</td></tr>';
                 {$else}
                     result:=inherited SourcePosToFPDocHint(CodeXYPos^,_cTxt_ttlLnkSRC)+' '+result;
                 {$endif}
            end;
        end;
    finally
        FreeListOfPCodeXYPosition(ListOfPCodeXYPosition);
    end;
end;

// найти и сформировать строку HintFromComment для узлов из раздела из обеих
// секций файла исходного кода (Interface и Implementation)
function TCodeHelpManager__HintDoc_F8PP__in0kLazIdeFIX._ink_getComments(const Tool:TFindDeclarationTool; const NodeInterface,NodeImplementation:TCodeTreeNode):string;
begin
    result:='';
    if Assigned(NodeInterface)      then _TXT_res_add_(result,_ink_getComment(Tool,NodeInterface));
    if Assigned(NodeImplementation) then _TXT_res_add_(result,_ink_getComment(Tool,NodeImplementation));
end;

// определить местоположение Узла в разделах Модуля
function TCodeHelpManager__HintDoc_F8PP__in0kLazIdeFIX._inc_getNodePlace(const Tool:TFindDeclarationTool; const Node:TCodeTreeNode):TCodeTreeNodeDesc;
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
    //phpWithStart,          // proc keyword e.g. 'function', 'class procedure'
    //phpWithoutClassKeyword,// without 'class' proc keyword
    phpAddClassName,       // extract/add 'ClassName.'
    //phpWithoutClassName,   // skip classname
    //phpWithoutName,        // skip function name
    //phpWithoutParamList,   // skip param list
    phpWithVarModifiers,   // extract 'var', 'out', 'const'
    phpWithParameterNames, // extract parameter names
    phpWithoutParamTypes,  // skip colon, param types and default values
    //phpWithHasDefaultValues,// extract the equal sign of default values
    phpWithDefaultValues,  // extract default values
    //phpWithResultType,     // extract colon + result type
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
    {$ifDef codehelp__HintDoc_F8PP__in0kLazFIX__DEBUG}
       TRY
    {$endIf}
    Result:='';
    if (Tool=nil)or(Node=nil) then exit;
    if node.Desc in [ctnProcedure,ctnProcedureHead] then begin //< обработка процедур и функций
         // надо ТОЧНО спозиционироваться на ctnProcedure
         if Node.Desc=ctnProcedureHead then Node:=Node.Parent;
         if Node.Desc=ctnProcedure then begin
             {$ifDef codehelp__HintDoc_F8PP__in0kLazFIX__DEBUG}
               _TXT_res_add_(result,'ProcHead:'+Tool.ExtractProcHead(Node,ProcAttr_fndPROCEDURE));
             {$endIf}
             // в зависимости от место положения, исчем HintFromComment
             case _inc_getNodePlace(Tool,node) of
                ctnInterface:
                   _TXT_res_add_(result,_ink_getComments(Tool,node,Tool.FindCorrespondingProcNode(node,ProcAttr_fndPROCEDURE)));
                ctnImplementation:
                   _TXT_res_add_(result,_ink_getComments(Tool,Tool.FindCorrespondingProcNode(node,ProcAttr_fndPROCEDURE),node));
                else begin //< к ТАКОМУ повороту мы не готовы, попросим Папу
                   _TXT_res_add_(result,inherited GetPasDocCommentsAsHTML(Tool,Node));
                    {$ifDef codehelp__HintDoc_F8PP__in0kLazFIX__DEBUG}
                       _TXT_add_res_('err: wrong _inc_getNodePlace [used&nbsp;inherited&nbsp;GetPasDocCommentsAsHTML]',result);
                    {$endIf}
                end
             end;
         end
         else begin //< ошибочка вышла, пусть Папа отвечает
             result:=inherited GetPasDocCommentsAsHTML(Tool,Node);
             {$ifDef codehelp__HintDoc_F8PP__in0kLazFIX__DEBUG}
                _TXT_add_res_('err: not found Node.Desc=ctnProcedure [used&nbsp;inherited&nbsp;GetPasDocCommentsAsHTML]',result);
             {$endIf}
         end;
    end
    else begin //< тут все вопросы к Папе, он за нас ответит.
        result:=inherited GetPasDocCommentsAsHTML(Tool,Node);
        {$ifDef codehelp__HintDoc_F8PP__in0kLazFIX__DEBUG}
           _TXT_add_res_('unSupported node.Desc [used&nbsp;inherited&nbsp;GetPasDocCommentsAsHTML]',result);
        {$endIf}
    end;
    {$ifDef codehelp__HintDoc_F8PP__in0kLazFIX__DEBUG}
        EXCEPT
            on E:Exception do result:='ERROR'+'<br>'+LineEnding+E.ClassName+' : '+E.Message;
        END;
    {$endIf}
end;

{%endregion}

end.

