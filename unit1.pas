unit Unit1;

(*
  Was ein Scheissdreck mit diesem Lazarus und starten von anderen Programmen:
  TProcess:
  Achtung BatchDatei nur verwenden wenn es Umleitungen mit > gibt!!!

  ShellExeCute hat nicht auf Ende der Ausführung gewartet

  Erst die uralte Delphi function aus dem Netz: WinExecAndWait32
  hat dann die Lösung gebracht! Habs aber wieder mit TProcess versucht ... oh jeh!!!

  zu dem Parameter show siehe
  https://msdn.microsoft.com/en-us/library/windows/desktop/bb762153%28v=vs.85%29.aspx
*)

(*
http://wiki.freepascal.org/Executing_External_Programs/de

//if libc.system(PChar(cmdline)) = -1 then
Process1.CommandLine:=cmdline;
try
Process1.Execute;

except
  on E:Exception do
  showmessage(cmdline + NL + 'konnte NICHT erfolgreich ausgeführt werden!' + NL + NL +
  'Systemmeldung: ''' + E.Message);

end;


To ensure compatibility with previous versions of arj, the "-2d" parameter has to be specified when archiving under UNIX

unter Linux Programm ausführ8ng checken: strace -o logfile.txt  -f yourprogram
It will emit all system calls. Near to the end, there should be one that
fails with 'operation not permitted'.  (assuming your program exits straight
away after the failed command)

*)

{$mode objfpc}{$H+}

interface

uses
  locale_de, Classes, SysUtils, FileUtil, LResources, Forms,
  Controls, Graphics, Dialogs, ComCtrls, StdCtrls, ExtCtrls, FileCtrl,
  ShellCtrls, IniPropStorage, UniqueInstance, Interfaces, process, eventlog,
  Grids, EditBtn, Menus, strutils, LazUtils, LCLIntf,
  {$IFDEF LINUX }
  unix, LCLType, BaseUnix,
  {$ELSE }
  Windows,
  ShellApi,
  Variants,
  comobj,
  {$ENDIF }
  types, PropertyStorage, ComboEx, LazUTF8;

type
  TSearchOption = (soIgnoreCase, soFromStart, soWrap);
  TSearchOptions = set of TSearchOption;


  { TForm1 }

  TForm1 = class(TForm)
    ApplicationProperties1: TApplicationProperties;
    BtnPack: TButton;
    btnSearch: TButton;
    btnExtract: TButton;
    btnSend: TButton;
    btnSend1: TButton;
    BtnShowLog: TButton;
    btnDelChapter: TButton;
    chChapter: TCheckBox;
    ComboBoxExTract: TComboBox;
    DirectoryEdit1: TDirectoryEdit;
    DirectoryEditDest: TDirectoryEdit;
    Edit1: TEdit;
    EditChapter: TEdit;
    EditSearch: TEdit;
    EventLog1: TEventLog;
    FileNameEdit_ARJ: TFileNameEdit;
    FileNameEdit_ARJ_extract: TFileNameEdit;
    GridContent: TStringGrid;
    GroupBox1: TGroupBox;
    GroupBox2: TGroupBox;
    GroupBox3: TGroupBox;
    GroupBox4: TGroupBox;
    GroupBox5: TGroupBox;
    GroupBox6: TGroupBox;
    GroupBoxProtokoll: TGroupBox;
    IniPropStorage1: TIniPropStorage;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    ListBoxArchivHead: TListBox;
    ListBoxDirHistory: TListBox;
    Memo1: TMemo;
    alle_loeschen: TMenuItem;
    LisBoxMemo: TListBox;
    MemoHelpRussia: TMemo;
    MemoHelpUSA: TMemo;
    MemoKommentar: TMemo;
    CopySelected: TMenuItem;
    mnCopySelected: TMenuItem;
    MnDelphiFilter: TMenuItem;
    PopupArchiveHead: TPopupMenu;
    PopupProtokoll: TPopupMenu;
    PopupPackliste: TPopupMenu;
    Selected_clear: TMenuItem;
    PageControl1: TPageControl;
    Panel1: TPanel;
    Panel2: TPanel;
    Panel3: TPanel;
    Panel4: TPanel;
    Panel5: TPanel;
    PopupDirectoryHistory: TPopupMenu;
    Splitter1: TSplitter;
    Splitter2: TSplitter;
    Splitter4: TSplitter;
    StatusBar1: TStatusBar;
    PageEinPacken: TTabSheet;
    PageAuspacken: TTabSheet;
    PageHelp: TTabSheet;
    UniqueInstance1: TUniqueInstance;
    procedure alle_loeschenClick(Sender: TObject);
    procedure AppPropHint(Sender: TObject);
    procedure btnDelChapterClick(Sender: TObject);
    procedure btnExtractClick(Sender: TObject);
    procedure btnSearchClick(Sender: TObject);
    procedure BtnPackClick(Sender: TObject);
    procedure btnSendClick(Sender: TObject);
    procedure BtnShowLogClick(Sender: TObject);
    procedure cbDelphiFilterChange(Sender: TObject);
    procedure chChapterChange(Sender: TObject);
    procedure CopySelectedClick(Sender: TObject);
    procedure DirectoryEdit1AcceptDirectory(Sender: TObject; var Value: string);
    procedure EditSearchEditingDone(Sender: TObject);
    procedure EditSearchKeyDown(Sender: TObject; var Key: word; Shift: TShiftState);
    procedure FileNameEdit_ARJAcceptFileName(Sender: TObject; var Value: string);
    procedure FileNameEdit_ARJ_extractAcceptFileName(Sender: TObject;
      var Value: string);
    procedure FormActivate(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure IniPropStorage1StoredValues0Restore(Sender: TStoredValue;
      var Value: TStoredType);
    procedure IniPropStorage1StoredValues0Save(Sender: TStoredValue;
      var Value: TStoredType);
    procedure ListBoxArchivHeadDrawItem(Control: TWinControl;
      Index: integer; ARect: TRect; State: TOwnerDrawState);
    procedure ListBoxDirHistoryDblClick(Sender: TObject);
    procedure MemoHelpRussiaClick(Sender: TObject);
    procedure mnCopySelectedClick(Sender: TObject);
    procedure PageControl1Change(Sender: TObject);
    procedure PageHelpEnter(Sender: TObject);
    procedure Panel1DblClick(Sender: TObject);
    procedure Selected_clearClick(Sender: TObject);
    procedure UniqueInstance1OtherInstance(Sender: TObject;
      ParamCount: integer; Parameters: array of string);
  private
    { private declarations }
  public
    { public declarations }
    procedure JEi;
    procedure NEi;
    procedure ShowContent(Sender: TObject);
    function CheckSpaces(Val: string): boolean;
    function RemoveDoubleDelimiters(AStr: string; ADelimiter: char = ' '): string;
    procedure ShortenLog(Sender: TObject);

    function SearchText(Control: TCustomEdit; Search: string;
      SearchOptions: TSearchOptions): boolean;

    {$IFDEF windows }
    (* WinExecAndWait32:
    zum Argument visebility siehe:
    https://msdn.microsoft.com/en-us/library/windows/desktop/bb762153%28v=vs.85%29.aspx

    *)
    function WinExecAndWait32(FileName: string; WorkDir: string;
      Visibility: integer): integer;


    {$ENDIF }

    procedure PfadInKommentar;
    procedure SetDelphiFilter;




  end;

var
  Form1: TForm1;
  MyArj, ArchName, ArchNameExtr, StartParam, cmdline, MemoHelp: string;
  ToDelete, worklist, DelphiFilter, lst: TStringList;
  FSize : Int64;
  erg : integer;


const
  GridColumns =
    'Rev/Host OS Original Compressed Ratio DateTime modified FromChapter ToChapter Attributes GUA Ext Name FileName';


  (* wieviele Zeilen darf das LogFile haben, bevor es gekürzt wird mit procedure ShortenLog *)
  MaxLogLines = 500;

implementation

{ TForm1 }

{$R *.lfm}

function GetFileSize(const AFileName: string): Int64;
var
  SearchRec: TSearchRec;
  OldMode: Cardinal;
  Size: int64;
begin
  Result := -1;
  try
    if FindFirst(AFileName, faAnyFile, SearchRec) = 0 then
    begin
      Result := SearchRec.Size;
      SysUtils.FindClose(SearchRec);
    end;
  finally
  end;
end;

function TForm1.SearchText(Control: TCustomEdit; Search: string;
  SearchOptions: TSearchOptions): boolean;
var
  Txt: string;
  Index: integer;
begin
  if soIgnoreCase in SearchOptions then
  begin
    Search := UpperCase(Search);
    Txt := UpperCase(Control.Text);
  end
  else
    Txt := Control.Text;

  Index := 0;
  if not (soFromStart in SearchOptions) then
    Index := PosEx(Search, Txt, Control.SelStart + Control.SelLength + 1);

  if (Index = 0) and ((soFromStart in SearchOptions) or
    (soWrap in SearchOptions)) then
    Index := PosEx(Search, Txt, 1);

  Result := Index > 0;
  if Result then
  begin
    Control.SelStart := Index - 1;
    Control.SelLength := Length(Search);
  end;
end;




procedure TForm1.FormCreate(Sender: TObject);
var
  x: integer;
begin

  ExePath := ExtractFilePath(Application.ExeName);

  EventLog1.FileName := ChangeFileExt(Application.ExeName, '.log');

  EventLog1.Log('***************');

    {$IFDEF Linux}
  EventLog1.Log('Betriebssystem Linux!');
     {$ELSE }
  EventLog1.Log('Betriebssystem Windows!');
     {$ENDIF}

  EventLog1.Log('Anwendung gestarted, Startparmeter war: ' + ParamStr(1));



  (* LogFile ggf. kürzen *)
  ShortenLog(Sender);


  {$IFDEF Linux}
  IniPropStorage1.IniFileName := ChangeFileExt(Application.ExeName, '_lin.ini');
  FileNameEdit_ARJ.InitialDir := '/usr/bin';
  {$ELSE }
  IniPropStorage1.IniFileName := ChangeFileExt(Application.ExeName, '_win.ini');
  FileNameEdit_ARJ.InitialDir := 'C:\';

  {$ENDIF }

  FileNameEdit_ARJ_extract.InitialDir := ExePath;




  ToDelete := TStringList.Create;
  worklist := TStringList.Create;
  lst := TStringList.Create;


  DelphiFilter := TStringList.Create;
  DelphiFilter.Add('*.pas');
  DelphiFilter.Add('*.res');
  DelphiFilter.Add('*.lps');
  DelphiFilter.Add('*.lpr');
  DelphiFilter.Add('*.lpi');
  DelphiFilter.Add('*.dof');
  DelphiFilter.Add('*.dfm');
  DelphiFilter.Add('*.lfm');
  DelphiFilter.Add('*.todo');
  DelphiFilter.Add('*.ico');

  //StartParam := AnsiQuotedStr(ParamStr(0),'"') ;
  StartParam := ParamStr(1);
  (* Pfad/Dateiname mit Leerzeichen gehen nicht *)
  if CheckSpaces(Startparam) then
    exit;
  ArchName := ChangeFileExt(StartParam, '.arj');
  PageControl1.ActivePage := PageEinpacken;
  DirectoryEdit1.Directory := ExtractFilePath(StartParam);

  (* DateiFilter für das Archiv einstellen: *)
  for x := 0 to DelphiFilter.Count - 1 do
  begin
    Memo1.Lines.add(extractFilepath(StartParam) + DelphiFilter[x]);
  end;

  PfadInKommentar;

end;

procedure TForm1.FormDestroy(Sender: TObject);
var
  x: integer;
begin
  for x := 0 to ToDelete.Count - 1 do
  begin
    DeleteFile(PChar(ToDelete[x]));
    EventLog1.Log('Arbeitsdatei ' + ToDelete[x] + ' wurde gelöscht');
  end;

  FreeAndNil(ToDelete);
  FreeAndNil(Worklist);
  FreeAndNil(DelphiFilter);
  FreeAndNil(lst);

end;

procedure TForm1.FormShow(Sender: TObject);
begin
  (* in FormCreate gehts nicht! *)
  Application.Title := Application.MainForm.Caption;

  if ParamCount > 1 then
  begin
    if ((UpperCase(ExtractFileExt(ParamStr(1))) <> '.LPR') or
      (UPPERCASE(ExtractFileExt(ParamStr(1))) <> '.LPI') or
      (UPPERCASE(ExtractFileExt(ParamStr(1))) <> '.ARJ')) then
    begin
      ShowMessage(ParamStr(1) + NL + NL + 'wurde nicht als Startparameter erwartet!');
    end;
  end;
end;

procedure TForm1.IniPropStorage1StoredValues0Restore(Sender: TStoredValue;
  var Value: TStoredType);
var
  comp: TComponent;
begin
  MemoHelp := Value;
  comp := FindComponent(MemoHelp);

  MemoHelpRussiaClick(comp);

end;

procedure TForm1.IniPropStorage1StoredValues0Save(Sender: TStoredValue;
  var Value: TStoredType);
begin
  Value := MemoHelp;
end;

procedure TForm1.ListBoxArchivHeadDrawItem(Control: TWinControl;
  Index: integer; ARect: TRect; State: TOwnerDrawState);
begin
  with (Control as TListbox).Canvas do
  begin
    if pos('Chapter:', (Control as TListbox).Items[Index]) > 0 then
    begin
      FillRect(ARect);
      Font.Color := clRed;
      Font.Style := Font.Style + [fsBold];
      TextOut(ARect.Left, ARect.Top, (Control as TListbox).Items[Index]);
    end
    else
    begin

      (* weisse Schrift wenn ausgewählt *)
      if odSelected in State then
        Font.Color := clwhite
      else
        Font.Color := clDefault;

      FillRect(ARect);
      Font.Style := Font.Style - [fsBold];
      TextOut(ARect.Left, ARect.Top, (Control as TListbox).Items[Index]);

    end;
  end; {* with *}

end;

procedure TForm1.ListBoxDirHistoryDblClick(Sender: TObject);
begin
  DirectoryEdit1.Directory := ListBoxDirHistory.Items[ListBoxDirHistory.ItemIndex];

  Application.ProcessMessages;

  (* Pfad in MemoKommentar neu setzen *)
  PfadInKommentar;

end;

procedure TForm1.MemoHelpRussiaClick(Sender: TObject);
begin
  MemoHelp := (Sender as TMemo).Name;
  btnSearch.Caption := MemoHelp + ' durchsuchen';

  if MemoHelp = 'MemoHelpRussia' then
  begin
    MemoHelpRussia.Color := $008CF1F7;
    MemoHelpUSA.Color := clDefault;
  end
  else if MemoHelp = 'MemoHelpUSA' then
  begin
    MemoHelpRussia.Color := clDefault;
    MemoHelpUSA.Color := $008CF1F7;
  end;

end;

procedure TForm1.mnCopySelectedClick(Sender: TObject);
begin
      (* Anlage in Zwischenablage kopieren *)
    Edit1.Visible := True;
    Edit1.Text := LisBoxMemo.Items[LisBoxMemo.ItemIndex];

    //ShowMessage(Edit1.Text);
    Edit1.SelectAll;
    Edit1.CopyToClipboard;
    Edit1.Visible := False;
end;

procedure TForm1.PageControl1Change(Sender: TObject);
begin
  if (Sender as TPageControl).ActivePage = PageAuspacken then
  begin
    ListBoxArchivHead.ItemIndex := ListBoxArchivHead.Items.Count - 1;
  end;
end;

procedure TForm1.PageHelpEnter(Sender: TObject);
begin
  //EditSearch.SetFocus;
  EditSearch.SelectAll;
end;

procedure TForm1.Panel1DblClick(Sender: TObject);
begin
   ShowMessage(Splitter2.Parent.Name);
   Splitter2.Color:=clred;
   Splitter2.Height:=100;
   Splitter2.Parent.Invalidate;

end;

procedure TForm1.Selected_clearClick(Sender: TObject);
begin
  ListBoxDirHistory.Items.Delete(ListBoxDirHistory.ItemIndex);
end;

procedure TForm1.UniqueInstance1OtherInstance(Sender: TObject;
  ParamCount: integer; Parameters: array of string);
begin
  (* Application anzeigen *)
  if WindowState = wsMinimized then
    Application.Restore
  else
    BringToFront;

end;

procedure TForm1.AppPropHint(Sender: TObject);
begin
  StatusBar1.SimpleText := Application.Hint;
end;

procedure TForm1.btnDelChapterClick(Sender: TObject);
begin

  if not FileExists(MyARJ) then
  begin
    PageControl1.ActivePage := PageEinPacken;
    FileNameEdit_ARJ.SetFocus;
    FileNameEdit_ARJ.SelectAll;
    ShowMessage('Der ARJ-Packer ''' + MyArj +
      ''' wurde nicht gefunden, bitte einstellen!');
    exit;
  end;

         {$IFDEF Linux}
    cmdline := Myarj + ' dc -y ' + ArchName + ' \*';

    (* Logfile schreiben *)
    Eventlog1.Log('Letztes Chapter löschen: ' + cmdline);


    lst.Add(cmdline);
    lst.SaveToFile(ExePath + 'arjrun.sh');
    cmdline := ExePath + 'arjrun.sh';
    fpsystem('chmod +x ' + cmdline);
    if wifsignaled(fpsystem(cmdline)) then
      ShowMessage(cmdline + NL + 'konnte NICHT erfolgreich ausgeführt werden!');
    lst.Clear;

    FSize := GetFileSize(ArchName);
    (* Logfile schreiben *)
    Eventlog1.Log('Archivgrösse = ' + FormatFloat('#,### Byte',FSize));

       {$Else}
    cmdline := Myarj + ' dc -y ' + ArchName + ' *.* ';

    (* Logfile schreiben *)
    Eventlog1.Log('Letztes Chapter löschen: ' + cmdline);

    lst.Add(cmdline);
    lst.SaveToFile(ExePath + 'arjrun.bat');
    lst.Clear;
    cmdline := ExePath + 'arjrun.bat';
    erg := WinExecAndWait32(cmdline, ExePath, 2);
    Eventlog1.Log('Ausführung von arjrun.bat hatte den ExitCode = ' + IntToStr(erg));


    FSize := GetFileSize(ArchName);
    (* Logfile schreiben *)
    Eventlog1.Log('Archivgrösse = ' + FormatFloat('#,### Byte',FSize));



       {$ENDIF }

    ShowContent(Sender);


end;

procedure TForm1.btnExtractClick(Sender: TObject);
var
  jb, Filter: string;
begin
  if CheckSpaces(DirectoryEditDest.Directory) then
    exit;

  (* auspacken ohne Pfad *)

  (* nur das Chapterarchiv ...  *)
  if chChapter.Checked then
    jb := '-jb' + EditChapter.Text
  else
    jb := '';

  (* offensichtlich kein escapen von *.* in bash notwendig *)
  Filter := trim(ComboBoxExTract.Text);

  (* Vorsichtsmassnahme *)
  if (Filter = '') then Filter := '*.*';

  if not FileExists(FileNameEdit_ARJ_extract.FileName) then
  begin
    FileNameEdit_ARJ_extract.SelectAll;
    FileNameEdit_ARJ_extract.SetFocus;
    ShowMessage('Das Archiv ''' + FileNameEdit_ARJ_extract.FileName +
      ''' existiert nicht, bitte ein existierendes Archiv auswählen!');
    exit;
  end;



  // ShowMessage(ArchName + ' auspacken nach ' + DirectoryEditDest.Directory);
   {$IFDEF Linux}

  try

    Jei;
    (* Achtung BatchDatei nur verwenden wenn es Umleitungen mit > gibt!!! *)
    cmdline := MyARJ + ' e -y -i ' + ' ' + jb + ' ' +
      AnsiQuotedStr(FileNameEdit_ARJ_extract.FileName, '"') + ' ' + Filter +
      ' -ht' + AnsiQuotedStr(DirectoryEditDest.Directory, '"');

    (* Logfile schreiben *)
    Eventlog1.Log('auspacken ohne Pfad nach: ' + cmdline);

      (* geht so nicht!!
      ExecuteProcess('/usr/bin/arj',''' e -y -i ' + ' ' + jb + ' ' + AnsiQuotedStr(FileNameEdit_ARJ_extract.FileName,'"') + ' * ' + '-ht' + AnsiQuotedStr(DirectoryEditDest.Directory,'"')+'''');
      exit;
      *)

    lst.Add(cmdline);
    lst.SaveToFile(ExePath + 'arjrun.sh');
    cmdline := ExePath + 'arjrun.sh';
    fpsystem('chmod +x ' + cmdline);
    if wifsignaled(fpsystem(cmdline)) then
      ShowMessage(cmdline + NL + 'konnte NICHT erfolgreich ausgeführt werden!');
    lst.Clear;

    nei;

    cmdline := '';
    if FileExists('/usr/bin/nemo') then
    begin
      if Messagedlg('Soll der Dateimanager in ''' + DirectoryEditDest.Directory +
        ''' geöffnet werden?', mtConfirmation, [mbYes, mbNo], 0) = mrYes then
        cmdline := '/usr/bin/nemo ' + DirectoryEditDest.Directory;
    end
    else if FileExists('/usr/bin/dolphin') then
    begin
      if Messagedlg('Soll der Dateimanager in ''' + DirectoryEditDest.Directory +
        ''' geöffnet werden?', mtConfirmation, [mbYes, mbNo], 0) = mrYes then
        cmdline := '/usr/bin/dolphin ' + DirectoryEditDest.Directory;
    end
    else
    begin
      ShowMessage('Kein Dateimanager gefunden um ''' +
        DirectoryEditDest.Directory + ''' anzuzeigen!');
      exit;
    end;

    (* jetzt ausführen *)
    fpsystem(cmdline);




  finally

    nei;

  end;


   {$ELSE }

  try
    Jei;
    (* Achtung BatchDatei nur verwenden wenn es Umleitungen mit > gibt!!! *)
    cmdline := Myarj + ' e -y -i ' + ' ' + jb + ' ' +
      AnsiQuotedStr(FileNameEdit_ARJ_extract.FileName, '"') + ' ' + Filter +
      ' -ht' + AnsiQuotedStr(DirectoryEditDest.Directory, '"');

    (* Logfile schreiben *)
    Eventlog1.Log('auspacken ohne Pfad nach: ' + cmdline);

      (* zu dem Parameter show siehe
      https://msdn.microsoft.com/en-us/library/windows/desktop/bb762153%28v=vs.85%29.aspx
      *)
    //ShellExeCute(Application.MainForm.Handle,'open',PChar(cmdline),'',PChar(ExePath),1);
    lst.Add(cmdline);
    lst.SaveToFile(ExePath + 'arjrun.bat');
    lst.Clear;
    cmdline := ExePath + 'arjrun.bat';
    erg :=  WinExecAndWait32(cmdline, ExePath, 2);
    Eventlog1.Log('Ausführung von arjrun.bat hatte den ExitCode = ' + IntToStr(erg));


    (* Im Explorer anzeigen? *)
    if Messagedlg('Soll der Dateimanager in ''' + DirectoryEditDest.Directory +
      ''' geöffnet werden?', mtConfirmation, [mbYes, mbNo], 0) = mrYes then
    ShellExeCute(Application.Mainform.handle, nil, PChar('Explorer.exe'),
      PChar('/n,/e,' + DirectoryEditDest.Directory + ',/select,' + DirectoryEditDest.Directory), PChar(DirectoryEditDest.Directory), SW_Normal);






  finally
    nei;
  end;

   {$ENDIF }

end;

procedure TForm1.alle_loeschenClick(Sender: TObject);
begin
  ListBoxDirHistory.Items.Clear;
end;

procedure TForm1.btnSearchClick(Sender: TObject);
begin
  try
    jei;

    if MemoHelp = 'MemoHelpRussia' then
    begin
      (* ab cursor bzw von Beginn an suchen *)
      if ((not SearchText(MemoHelpRussia, EditSearch.Text, [soIgnoreCase])) and
        (not SearchText(MemoHelpRussia, EditSearch.Text, [soIgnoreCase, soFromStart])))
      then
      begin
        ShowMessage('''' + EditSearch.Text + ''' wurde in ''' +
          MemoHelp + ''' nicht gefunden!');
      end;

    end
    else if MemoHelp = 'MemoHelpUSA' then
    begin

      (* ab cursor bzw von Beginn an suchen *)
      if ((not SearchText(MemoHelpUSA, EditSearch.Text, [soIgnoreCase])) and
        (not SearchText(MemoHelpUSA, EditSearch.Text, [soIgnoreCase, soFromStart]))) then
      begin
        ShowMessage('''' + EditSearch.Text + ''' wurde in ''' +
          MemoHelp + ''' nicht gefunden!');
      end;

    end;

  finally
    Nei;
  end;
end;


procedure TForm1.DirectoryEdit1AcceptDirectory(Sender: TObject; var Value: string);
begin
  if ListBoxDirHistory.Items.IndexOf(Value) = -1 then
    ListBoxDirHistory.Items.Add(Value);

  PfadInKommentar;

end;

procedure TForm1.EditSearchEditingDone(Sender: TObject);
begin
  EditSearch.Text := trim(EditSearch.Text);
end;

procedure TForm1.EditSearchKeyDown(Sender: TObject; var Key: word; Shift: TShiftState);
begin
  if Key = VK_RETURN then
    btnSearchClick(Sender);
end;

procedure TForm1.FileNameEdit_ARJAcceptFileName(Sender: TObject; var Value: string);
begin
  MyARJ := Value;
end;

procedure TForm1.FileNameEdit_ARJ_extractAcceptFileName(Sender: TObject;
  var Value: string);
begin
  if CheckSpaces(Value) then
    exit;

  FSize := GetFileSize(Value);


  ArchNameExtr := Value;
  ShowContent(Sender);
end;

procedure TForm1.FormActivate(Sender: TObject);
begin
  if FileExists(FileNameEdit_ARJ.Text) then
    MyARJ := FileNameEdit_ARJ.Text;

  (* Cursor zur Eingabe eines Archivkomentars positionieren *)
  MemoKommentar.SelStart := Length(MemoKommentar.Text) - 1;


  (* wurde ein ARJ-Archiv als Startparameter angegeben? *)
  if UpperCase(ExtractFileExt(StartParam)) = '.ARJ' then
  begin
    FileNameEdit_ARJ_extract.FileName := StartParam;

    ArchName := StartParam;

    FileNameEdit_ARJ_extractAcceptFileName(FileNameEdit_ARJ_extract, StartParam);

    PageControl1.ActivePage := PageAuspacken;
  end;

end;

procedure TForm1.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
    ComboBoxExTract.AddHistoryItem(ComboBoxExTract.Text,8,true,true);
end;



procedure TForm1.JEi;
begin
  screen.cursor := crHourglass;
end;

procedure TForm1.NEi;
begin
  screen.cursor := crDefault;
end;

procedure TForm1.BtnPackClick(Sender: TObject);
var
  jz, packlst, comment: string;
  lst: TStringList;
begin
  if not FileExists(MyARJ) then
  begin
    FileNameEdit_ARJ.SetFocus;
    FileNameEdit_ARJ.SelectAll;
    ShowMessage('Der ARJ-Packer ''' + MyArj +
      ''' wurde nicht gefunden, bitte einstellen!');
    exit;
  end;

  packlst := ExePath + 'packlst.lst';
  ToDelete.Add(packlst);
  comment := ExePath + 'ackommentar.txt';
  ToDelete.Add(comment);
  ArchName := ChangeFileExt(StartParam, '.arj');

  if Memo1.Lines.Count > 0 then
  begin
    Memo1.Lines.savetofile(packlst);
  end
  else
  begin
    ShowMessage('Sie haben keine Dateien/Verzeichnisse ausgewählt, die zu packen wären!');
    exit;
  end;

  {Kommentar zu Chapterarchiv}
  if MemoKommentar.Lines.Count > 0 then
  begin

    MemoKommentar.Lines.saveToFile(comment);

          {$IFDEF Linux}
    jz := ' \-hbc \-jz' + comment;
          {$Else}
    jz := ' -hbc -jz' + comment;
          {$ENDIF }

  end
  else
    jz := ' ';

  //Packoptionen
  {* Achtung: "\" vor special bash characters setzen !! *}
  //if not SetCurrentDirUTF8(ExtractFilePath(ArchName)) { *Konvertiert von SetCurrentDir* } then
  (* AnsiDequotedStr  *)
  if not SetCurrentDir(ExtractFilePath(AnsiDequotedStr(ArchName, '"'))) then
  begin
    ShowMessage('In das Verzeichnis ' + ExtractFilePath(ArchName) +
      ' , Standort für das Chapterarchiv, konnte nicht gewechselt werden!');
    exit;
  end;

  try
    Jei;
    lst := TStringList.Create;
    {* laut Packliste packen
       bei Linux OHNE Pfad!!! also -e  und das -2d für die Unix Kompatibilität(?), siehe ganz oben
    *}
       {$IFDEF Linux}
    cmdline := Myarj + ' ac -e -2d ' + ArchName + ' \!' + packlst;

    (* Logfile schreiben *)
    Eventlog1.Log('Chapter einpacken: ' + cmdline);


    lst.Add(cmdline);
    lst.SaveToFile(ExePath + 'arjrun.sh');
    cmdline := ExePath + 'arjrun.sh';
    fpsystem('chmod +x ' + cmdline);
    if wifsignaled(fpsystem(cmdline)) then
      ShowMessage(cmdline + NL + 'konnte NICHT erfolgreich ausgeführt werden!');
    lst.Clear;

    FSize := GetFileSize(ArchName);
    (* Logfile schreiben *)
    Eventlog1.Log('Archivgrösse = ' + FormatFloat('#,### Byte',FSize));






       {$Else}
    cmdline := Myarj + ' ac ' + ArchName + ' !' + packlst;

    (* Logfile schreiben *)
    Eventlog1.Log('Chapter einpacken: ' + cmdline);


       (* zu dem Parameter show siehe
       https://msdn.microsoft.com/en-us/library/windows/desktop/bb762153%28v=vs.85%29.aspx
       *)
    //ShellExeCute(Application.MainForm.Handle,'open',PChar(cmdline),'',PChar(ExePath),1);
    lst.Add(cmdline);
    lst.SaveToFile(ExePath + 'arjrun.bat');
    lst.Clear;
    cmdline := ExePath + 'arjrun.bat';
    erg := WinExecAndWait32(cmdline, ExePath, 2);
    Eventlog1.Log('Ausführung von arjrun.bat hatte den ExitCode = ' + IntToStr(erg));


    FSize := GetFileSize(ArchName);
    (* Logfile schreiben *)
    Eventlog1.Log('Archivgrösse = ' + FormatFloat('#,### Byte',FSize));



       {$ENDIF }

    //ShowMessage('Jetzt wir ausgeführt: ' + cmdline);



    {* Chapterarchiv kommentieren *}
       {$IFDEF Linux}
    cmdline := Myarj + ' c  ' + ArchName + jz;

    (* Logfile schreiben *)
    Eventlog1.Log('Chapterarchiv kommentieren: ' + cmdline);


    lst.Add(cmdline);
    lst.SaveToFile(ExePath + 'arjrun.sh');
    cmdline := ExePath + 'arjrun.sh';
    fpsystem('chmod +x ' + cmdline);
    if wifsignaled(fpsystem(cmdline)) then
      ShowMessage(cmdline + NL + 'konnte NICHT erfolgreich ausgeführt werden!');
    lst.Clear;



       {$Else}
    cmdline := Myarj + ' c -hy ' + ArchName + jz;

    (* Logfile schreiben *)
    Eventlog1.Log('Chapterarchiv kommentieren: ' + cmdline);

    (* Achtung BatchDatei nur verwenden wenn es Umleitungen mit > gibt!!! *)
    //ShowMessage('Jetzt wir ausgeführt: ' + cmdline);

    (* zu dem Parameter show siehe
    https://msdn.microsoft.com/en-us/library/windows/desktop/bb762153%28v=vs.85%29.aspx
    *)
    //ShellExeCute(Application.MainForm.Handle,'open',PChar(cmdline),'',PChar(ExePath),1);
    lst.Add(cmdline);
    lst.SaveToFile(ExePath + 'arjrun.bat');
    lst.Clear;
    cmdline := ExePath + 'arjrun.bat';
    erg := WinExecAndWait32(cmdline, ExePath, 2);
    Eventlog1.Log('Ausführung von arjrun.bat hatte den ExitCode = ' + IntToStr(erg));


       {$ENDIF }



    (* ********************************** *)
    ShowContent(Sender);
    (* ********************************** *)


  finally
    lst.Free;
    Nei;

  end;
end;


procedure TForm1.btnSendClick(Sender: TObject);
var
  list: TStringList;
  x, ret: integer;
  s : string;
begin
  try
    list := TStringList.Create;



    (* body zusammenstellen *)
    list.Add('Hallo Blödmann,');
    list.Add('');
    list.Add('Packliste des Archivs:');
    list.AddStrings(Memo1.Lines);
    list.Add('');
    list.Add('Kommentar zum Archiv:');
    list.AddStrings(MemoKommentar.Lines);

    //list.SaveToFile(ExePath + 'aaa.txt');


    (* Anlage in Zwischenablage kopieren *)
    Edit1.Visible := True;
    Edit1.Text := ArchName;

    //ShowMessage(Edit1.Text);
    Edit1.SelectAll;
    Edit1.CopyToClipboard;
    Edit1.Visible := False;



 {$IFDEF Linux}
    try
      jei;


      if FileExists('/usr/bin/icedove') then
      begin
        cmdline :=
          '/usr/bin/icedove  -compose "to=''john-landmesser@hlb-online.de'',subject=''Arj-ChapterArchiv: ' + ArchName + ''',body='''
          + list.Text + ''',attachment=''' + ArchName + '''"';

        Eventlog1.Log('Mail wird verschickt mit dem Befehl: ' + cmdline);

      end
      else if FileExists('/usr/bin/thunderbird') then
      begin
        cmdline :=
          '/usr/bin/thunderbird  -compose "to=''john-landmesser@hlb-online.de'',subject=''Arj-ChapterArchiv: '  + ArchName + ''',body='''
          + list.Text + ''',attachment=''' + ArchName + '''"';

        Eventlog1.Log('Mail wird verschickt mit dem Befehl: ' + cmdline);
      end
      else if FileExists('/usr/bin/evolution') then
      begin
        cmdline :=
          '/usr/bin/evolution mailto:jmlandmesser@gmail.com?subject=''Arj-ChapterArchiv: '  + ArchName + '''\&body='''
          + list.Text + '''\&attach=' + ArchName;

        Eventlog1.Log('Mail wird verschickt mit dem Befehl: ' + cmdline);

      (*
      To make it complete, you can do this:

      Code:
      evolution mailto:address@domain.com?subject="type your subject between quotation marks"\&body="type your message between quotation marks"\&attach="/path/to/file/to/attach"

      Remember to put subject and message etc. between quotation marks to enable spaces and characters that otherwise would be interpreted by the shell. If you want a line break in your message body insert %0A (the middle one is a zero, nut o as in opera) like:

      evolution mailto:address@domain.com?subject="type your subject between quotation marks"\&body="type your message between quotation marks %0AThis is on a new line"\&attach="/path/to/file/to/attach"

      If you want more attachments just keep adding \&attach="/path/to/file"
      I haven't figured out how to insert multiple recipients. Anyone?
      Last edited by VCoolio; July 11th, 2009 at 01:29 AM.

      *)

      end

      else
      begin
        ShowMessage('Kein icedove/thunderbird/evolution in /usr/bin gefunden, die Programmausführung endet hier!');
        Eventlog1.Error('Mail konnte nicht versendet werden, kein Mailclient gefunden');
        exit;
      end;



      lst.Add(cmdline);
      lst.SaveToFile(ExePath + 'arjrun.sh');
      cmdline := ExePath + 'arjrun.sh';
      fpsystem('chmod +x ' + cmdline);
      if wifsignaled(fpsystem(cmdline)) then
        ShowMessage(cmdline + NL + 'konnte NICHT erfolgreich ausgeführt werden!');
      lst.Clear;




    finally
      Nei;
    end;
 {$ELSE }
    try

      (* LFN ersetzen: *)
      for x := 0 to list.Count -1 do
      s := s + '%0D%0A' + List[x];

      (* Spaces ersetzen: *)
      s := StringReplace(s,' ','%20',[rfReplaceAll, rfIgnoreCase]);


      (* geht, MIT Umlauts aber ohne attachement
         Der Trick ist wohl : PWideChar(UTF8Decode(
      *)

      ret :=  shellexecute(Application.Mainform.handle, 'open',PWideChar(UTF8Decode('mailto:' + 'jmlandmesser@gmail.com' + '?subject=' + 'ARJ-ChapterArchiv: ' + ArchName + '&body=' + s)),nil, nil, sw_normal);
      if ret < 32 then
      begin
         ShowMessage('Fehlercode: ' + IntToStr(ret) + NL + NL + 'Beim versenden des Mails ist ein Fehler aufgetreten. Evtl nützlich ist es das Protokoll zu lesen!' + NL + NL + 'Befehl war:' + NL + cmdLine);
         Eventlog1.Log(ArchName + ' konnte NICHT per Outlook verschickt werden. Fehlercode von ShellExecute war: ' + IntToStr(ret));
         exit;
      end;


      Eventlog1.Log(ArchName + ' wird per Outlook verschickt.');


    finally

    end;


 {$ENDIF }

  finally
    List.Free;
    Edit1.Visible := False;

  end;

end;

procedure TForm1.BtnShowLogClick(Sender: TObject);
begin
  (* Protokoll in LisBoxMemo laden und anzeigen/verbergen *)

  GroupBoxProtokoll.Visible := not GroupBoxProtokoll.Visible;

  if GroupBoxProtokoll.Visible then
  begin
    EventLog1.Log('Dieses Protokoll wird in ' + ExtractFileName(Application.ExeName) +
      ' angezeigt.');

    (* wichtig, sonst ist log nicht zu öffnen *)
    EventLog1.Active := False;

    LisBoxMemo.Items.LoadFromFile(EventLog1.FileName);
    LisBoxMemo.Items.Add('Dieses Protokoll hat jetzt ' +
      IntToStr(LisBoxMemo.Items.Count) + ' Zeilen von maximal ' +
      IntToStr(MaxLogLines) + ' Zeilen.');

    (* LisBoxMemo ans Ende scrollen *)
    LisBoxMemo.ItemIndex := LisBoxMemo.Items.Count - 1;

    LisBoxMemo.Refresh;
    LisBoxMemo.Invalidate;
    //LisBoxMemo.SetFocus;

  end;
end;

procedure TForm1.cbDelphiFilterChange(Sender: TObject);
begin
  if MnDelphiFilter.Checked then
  begin
    SetDelphiFilter;
  end;
end;

procedure TForm1.chChapterChange(Sender: TObject);
begin
  EditChapter.Enabled := chChapter.Checked;
  if EditChapter.Enabled then
    EditChapter.SetFocus;
end;

procedure TForm1.CopySelectedClick(Sender: TObject);
begin
  (* gewählte Zeile in Edit1 übertragen und kopieren *)
  Edit1.Visible := True;
  Edit1.Caption := ListBoxArchivHead.Items[ListBoxArchivHead.ItemIndex];
  (* wenns ein Pfad ist, alles nach dem Gleichheitszeichen *)
  if pos('=', Edit1.Caption) > 0 then
    EDit1.Caption := Copy(EDit1.Caption, pos('=', Edit1.Caption) +
      1, Length(EDit1.Caption));

  Edit1.SelectAll;
  Edit1.CopyToClipboard;
  Edit1.Visible := False;

end;

function TForm1.RemoveDoubleDelimiters(AStr: string; ADelimiter: char): string;
var
  tmp: string;

  {* BEGIN: Hilfsfunktionen aus JvJCLUtils.pas *}
  function DelBSpace(const S: string): string;
  var
    I, L: integer;
  begin
    L := Length(S);
    I := 1;
    while (I <= L) and (S[I] = ' ') do
      Inc(I);
    Result := Copy(S, I, MaxInt);
  end;

  function Copy2Symb(const S: string; Symb: char): string;
  var
    P: integer;
  begin
    P := Pos(Symb, S);
    if P = 0 then
      P := Length(S) + 1;
    Result := Copy(S, 1, P - 1);
  end;

  function Copy2SymbDel(var S: string; Symb: char): string;
  begin
    Result := Copy2Symb(S, Symb);
    S := DelBSpace(Copy(S, Length(Result) + 1, Length(S)));
  end;

  {* END: Hilfsfunktionen aus JvJCLUtils.pas *}

begin
  AStr := trim(AStr);
  Result := '';{* Result := '' -> komisch,aber notwendig *}
  tmp := Copy2SymbDel(AStr, ADelimiter);
  while tmp <> '' do
  begin
    Result := trim(Result) + ADelimiter + tmp;
    tmp := Copy2SymbDel(AStr, ADelimiter);
  end;

end;

procedure TForm1.ShortenLog(Sender: TObject);
var
  log: TStringList;
  x: integer;
begin
  try
    (* LogFile auf MaxLogLines Zeilen kürzen *)
    log := TStringList.Create;

    if not FileExists(EventLog1.FileName) then
      exit;


    EventLog1.Active := False;

    log.LoadFromFile(EventLog1.FileName);


    if log.Count > MaxLogLines then
    begin

      EventLog1.Log('Dieses Protokoll hat ' + IntToStr(log.Count) +
        ' Zeilen und wird jetzt auf ' + IntToStr(MaxLogLines div 5) + ' Zeilen gekürzt');

      (* damit überhaupt eingelesen werden kann *)
      EventLog1.Active := False;
      log.LoadFromFile(EventLog1.FileName);

      //ShowMessage('jetzt wird gekürzt von ' + IntToStr(log.count) + ' auf ' + IntToStr(MaxLogLines div 5) );

      while log.Count >= MaxLogLines div 5 do
        log.Delete(0);

      log.SaveToFile(EventLog1.FileName);

      EventLog1.Log('Gekürztes Log wurde gespeichert!');

    end;

  finally
    FreeAndNil(log);
  end;

end;

{$IFDEF Windows}

function TForm1.WinExecAndWait32(FileName: string; WorkDir: string;
  Visibility: integer): integer;
var
  zAppName: array[0..512] of char;
  zCurDir: array[0..255] of char;
  StartupInfo: TStartupInfo;
  ProcessInfo: TProcessInformation;
  Result1: DWORD;
begin
  screen.cursor := crHourglass;
  StrPCopy(zAppName, FileName);
  //GetDir(0,WorkDir);
  StrPCopy(zCurDir, WorkDir);
  FillChar(StartupInfo, Sizeof(StartupInfo), #0);
  StartupInfo.cb := Sizeof(StartupInfo);

  StartupInfo.dwFlags := STARTF_USESHOWWINDOW;
  StartupInfo.wShowWindow := word(Visibility);
  if not CreateProcess(nil, zAppName, { pointer to command line string }
    nil, { pointer to process security attributes }
    nil, { pointer to thread security attributes }
    False, { handle inheritance flag }
    CREATE_NEW_CONSOLE or { creation flags }
    NORMAL_PRIORITY_CLASS, nil, { pointer to new environment block }
    zCurDir, { pointer to current directory name }
    StartupInfo, { pointer to STARTUPINFO }
    ProcessInfo) then
    Result := -1 { pointer to PROCESS_INF }

  else
  begin
    WaitforSingleObject(ProcessInfo.hProcess, INFINITE);
    {if WaitforSingleObject(ProcessInfo.hProcess, 20000) = WAIT_TIMEOUT then
    begin
      showmessage(FileName +
        ' konnte nicht gestartet werden Windows Fehlermeldung: ' +
        SysErrorMessage(GetLastError()));
    end;}
    GetExitCodeProcess(ProcessInfo.hProcess, Result1);
    Result := Result1;
  end;
end;

{$ENDIF }



procedure TForm1.PfadInKommentar;
begin
  (* Pfad für Win oder Linux speichern *)
  {$IFDEF LINUX}
  MemoKommentar.Lines[0] := 'Linux=' + DirectoryEdit1.Directory;
  {$ELSE}
  MemoKommentar.Lines[0] := 'Windows=' + DirectoryEdit1.Directory;
  {$ENDIF }

  Application.ProcessMessages;

end;

procedure TForm1.SetDelphiFilter;
var
  Value: string;
  x: integer;
begin
  (* laut Delphi-Filter die Listeneinträge neu einrichten *)
  Value := Memo1.Lines[0];

  Memo1.Lines.Clear;

  for x := 0 to DelphiFilter.Count - 1 do
  begin
    Memo1.Lines.add(IncludeTrailingBackslash(Value) + DelphiFilter[x]);
  end;


  Value := ExtractFilePath(Value);

end;




procedure TForm1.ShowContent(Sender: TObject);
var
  x: integer;
  tmp, oldArchName: string;
  lst: TStringList;
begin
  (* zur Sichereheit 'ArchName'
     mal spieichern, um das am
     Ende wieder herstellen zu können *)
  oldArchName := ArchName;

  if Sender = BtnPack then
  begin
    //ShowMessage(BtnPack.Caption + NL + ArchName);
  end;

  if Sender = btnExtract then
  begin
    //ArchName := AnsiQuotedStr(FileNameEdit_ARJ_extract.FileName,'"');
    ArchName := ArchNameExtr;

    //ShowMessage(btnExtract.Caption + NL + ArchName);

  end;

  if Sender = FileNameEdit_ARJ_extract then
  begin
    //ArchName := AnsiQuotedStr(FileNameEdit_ARJ_extract.FileName,'"');
    ArchName := ArchNameExtr;

    //ShowMessage(FileNameEdit_ARJ_extract.Name + NL + ArchName);

  end;

  StatusBar1.SimpleText := 'Archiv: ' + ArchName + ' / ' + FormatFloat('#,### Byte',FSize);



  {* Archivkopf einlesen *}
  lst := TStringList.Create;

  (* Archivinhalt in Inhalt.txt schreiben *)

  (* Da Umleitungen wie ">" in TProcess nicht funktionieren,
     gehe ich den Weg über *.sh bzw *.bat *)
  {$IFDEF Linux}
  cmdline := Myarj + ' v -jv1 ' + ArchName + ' > ' + ExePath + 'inhalt.txt';

  EventLog1.Log('Archivinhalt anzeigen: ' + cmdline);

  lst.Add(cmdline);
  lst.SaveToFile(ExePath + 'arjrun.sh');
  cmdline := ExePath + 'arjrun.sh';
  fpsystem('chmod +x ' + cmdline);
  if wifsignaled(fpsystem(cmdline)) then
    ShowMessage(cmdline + NL + 'konnte NICHT erfolgreich ausgeführt werden!');
  lst.Clear;


  {$Else}
  cmdline := Myarj + ' v -jv1 ' + ArchName + ' > ' + ExePath + 'inhalt.txt';

  EventLog1.Log('Archivinhalt anzeigen: ' + cmdline);


  (* Achtung BatchDatei nur verwenden wenn es Umleitungen mit > gibt!!! *)
  (* zu dem Parameter show siehe
  https://msdn.microsoft.com/en-us/library/windows/desktop/bb762153%28v=vs.85%29.aspx
  *)
  //ShellExeCute(Application.MainForm.Handle,'open',PChar(cmdline),'',PChar(ExePath),1);
  lst.Add(cmdline);
  lst.SaveToFile(ExePath + 'arjrun.bat');
  lst.Clear;
  cmdline := ExePath + 'arjrun.bat';
  erg :=  WinExecAndWait32(cmdline, ExePath, 2);
  Eventlog1.Log('Ausführung von arjrun.bat hatte den ExitCode = ' + IntToStr(erg));


  {$ENDIF }


  //ShowMessage('ShowContent: ' + cmdline);



  ToDelete.add(ExePath + 'inhalt.txt');
  ToDelete.add(ExePath + 'arjrun.sh');
  ToDelete.add(ExePath + 'arjrun.bat');

  (* Archivkommentare in chaptercomments.txt schreiben  *)
  {$IFDEF Linux}
  cmdline := Myarj + ' v \-jb* ' + ArchName + ' > ' + ExePath + 'chaptercomments.txt';

  EventLog1.Log('Chapterkommentar auslesen: ' + cmdline);


  lst.Add(cmdline);
  lst.SaveToFile(ExePath + 'arjrun.sh');
  cmdline := ExePath + 'arjrun.sh';
  fpsystem('chmod +x ' + cmdline);
  if wifsignaled(fpsystem(cmdline)) then
    ShowMessage(cmdline + NL + 'konnte NICHT erfolgreich ausgeführt werden!');
  lst.Clear;



  {$Else}
  cmdline := Myarj + ' v -jb* ' + ArchName + ' > ' + ExePath + 'chaptercomments.txt';

  EventLog1.Log('Chapterkommentar auslesen: ' + cmdline);


  (* zu dem Parameter show siehe
  https://msdn.microsoft.com/en-us/library/windows/desktop/bb762153%28v=vs.85%29.aspx
  *)
  //ShellExeCute(Application.MainForm.Handle,'open',PChar(cmdline),'',PChar(ExePath),1);
  lst.Add(cmdline);
  lst.SaveToFile(ExePath + 'arjrun.bat');
  lst.Clear;
  cmdline := ExePath + 'arjrun.bat';
  erg := WinExecAndWait32(cmdline, ExePath, 2);
  Eventlog1.Log('Ausführung von arjrun.bat hatte den ExitCode = ' + IntToStr(erg));



  {$ENDIF }

  Application.ProcessMessages;


  worklist.LoadFromFile(ExePath + 'inhalt.txt');
  ListBoxArchivHead.Clear;
  {* erste Zeilen einlesen und gleichzeitig aus Stringlist löschen *}
  if worklist.Count > 5 then
  begin
    for x := 0 to 5 do
    begin
      ListBoxArchivHead.Items.Add(worklist[0]);
      worklist.Delete(0);
    end;

    {* letzte Zeile löschen *}
    worklist.Delete(worklist.Count - 1);

    {* Viel Schweiß: So umformatieren, daß nur 1 Leerzeichen als Trennzeichen
       der Zellwerte übrig bleibt *}
    for x := 0 to worklist.Count - 1 do
      worklist.Strings[x] := RemoveDoubleDelimiters(worklist.Strings[x]);

    {* Spaltentitel aus const GridColumns einfügen *}
    worklist.Insert(0, GridColumns);

    {* Umformatierte Stringliste speichern und in Grid einlesen *}
    worklist.SaveToFile(ExePath + 'inhalt.txt');
    // LoadFromFile(GridContent,ExePath +'inhalt.txt',' ');
    GridContent.LoadFromCSVFile(ExePath + 'inhalt.txt', ' ');

    {* Archivkommentare in ListBoxArchivHead anzeigen *}


    ToDelete.Add(ExePath + 'chaptercomments.txt');

    worklist.LoadFromFile(ExePath + 'chaptercomments.txt');
    for x := 0 to worklist.Count - 1 do
    begin
      {* Ab hier nur noch Chapterkommentare *}
      if pos('<<<', worklist[x]) >= 5 then
        break;
    end;

    for x := x to worklist.Count - 3 do
    begin
      {* Ergebnis z.B. = Chapter: <<<001>>> *}
      if pos('<<<', worklist[x]) >= 5 then
        worklist[x] := 'Chapter: ' + copy(worklist[x], 5, MaxInt);

      ListBoxArchivHead.Items.Add(worklist[x]);
    end;

    {* optimale Spaltenbreite einstellen *}
    for x := 0 to GridContent.ColCount - 1 do
      GridContent.AutoSizeColumn(x);

    PageControl1.ActivePage := PageAuspacken;
  end;

  (* Archname wieder rücksichern *)
  ArchName := oldArchName;

  FreeAndNil(lst);
  Nei;

  EventLog1.Log('Archivinhalt wurde eingelesen aus ' + ExePath + 'inhalt.txt');

  FileNameEdit_ARJ_extract.InitialDir:=ExtractFilePath(Archname);

end;

function TForm1.CheckSpaces(Val: string): boolean;
begin
  Result := False;
  if pos(' ', Val) > 0 then
  begin
    ShowMessage('Pfade/Dateinamen mit Leerzeichen sind nicht möglich!!' +
      NL + NL + '''' + Val + '''' + NL + NL + 'Fortsetzung wird beendet!');
    Result := True;
  end;

  (* EventLog schreiben *)
  if Result then
    EventLog1.Log(Val + ' enthält Leerzeichen.')
  else
    EventLog1.Log(Val + ' enthält KEINE Leerzeichen.');

end;



initialization

end.
