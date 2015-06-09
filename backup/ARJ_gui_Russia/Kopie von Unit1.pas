unit Unit1;

{$MODE Delphi}

interface

uses
  SysUtils, Types, Classes, Variants,  Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, ComCtrls,  Buttons,
  Menus, Grids, EditBtn, UniqueInstance, StrUtils, process;

  {* Archiv Inhalt anzeigen:
     arj v \-jv1  arjgui.arj>inhalt.txt  für Das StringGrid
     oder
     arj v \-jb*  für Extraktion der Chapterkommentare

     You can comment the chapter labels as a way of identifying each
           chapter backup.

           ARJ c archive -hbc -jz         comments the last chapter label
           ARJ c archive "<<*" -jz        comments the last chapter label
           ARJ c archive -hbc -jz -jb*    comments all chapter labels
           ARJ c archive -hbc -jz -jb5    comments the label for chapter 5

   *}

type

  { TMainForm1 }

  TMainForm1 = class(TForm)
    Process1: TProcess;
    StatusBar1: TStatusBar;
    PageControl1: TPageControl;
    PageEinpacken: TTabSheet;
    Panel1: TPanel;
    Label2: TLabel;
    Panel2: TPanel;
    Label1: TLabel;
    Memo1: TMemo;
    cbDelphiFilter: TCheckBox;
    Splitter1: TSplitter;
    MemoKommentar: TMemo;
    Panel3: TPanel;
    BtnPack: TBitBtn;
    PageAuspacken: TTabSheet;
    ListBoxArchivHead: TListBox;
    Panel4: TPanel;
    JvFilenameEditArchiv: TFilenameEdit;
    Panel5: TPanel;
    GridContent: TStringGrid;
    JvFileNameAddFile: TFilenameEdit;
    UniqueInstance1: TUniqueInstance;
    procedure FormCreate(Sender: TObject);
    procedure FormLoaded(Sender: TObject);
    procedure cbDelphiFilterClick(Sender: TObject);
    procedure BtnPackClick(Sender: TObject);
    procedure JvFileNameAddFileAcceptFileName(Sender: TObject; var Value: String
      );
    procedure JvFileNameAddFileAfterDialog(Sender: TObject; var Name: String;
      var Action: Boolean);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure JvFilenameEditArchivAcceptFileName(Sender: TObject;
      var Value: String);
    procedure JvFilenameEditArchivBeforeDialog(Sender: TObject;
      var Name: String; var Action: Boolean);
    procedure JvFilenameEditArchivAfterDialog(Sender: TObject;
      var Name: String; var Action: Boolean);
    procedure PageControl1Change(Sender: TObject);
    procedure ListBoxArchivHeadDrawItem(Sender: TObject; Index: Integer;
      Rect: TRect; State: TOwnerDrawState; var Handled: Boolean);
    procedure JvFileNameAddFileBeforeDialog(Sender: TObject;
      var Name: String; var Action: Boolean);
  private
    { Private declarations }
  public
    procedure showHint(Sender: TObject);
    procedure JEi;
    procedure NEi;
    procedure ShowContent;
    function RemoveDoubleDelimiters( AStr : string; ADelimiter : Char = ' ') : string;
  end;

var
  MainForm1: TMainForm1;
  ExePath, JIniFileName,StartParam, cmdline, ArchName : String;
  worklist, ToDelete : TStringList;
  const NL = chr(10) + chr(13);
  const GridColumns = 'Rev/Host OS Original Compressed Ratio DateTime modified FromChapter ToChapter Attributes GUA Ext Name FileName';
  const Maindir = '/usr/local/kylix3/projekte/';


implementation

//uses StringGridUtils;

{$R *.lfm}

{ TMainForm1 }

procedure TMainForm1.JEi;
begin
  screen.cursor := crHourglass;
end;

procedure TMainForm1.NEi;
begin
  screen.cursor := crDefault;
end;

procedure TMainForm1.showHint(Sender: TObject);
begin
  StatusBar1.SimpleText := Application.Hint;
end;

procedure TMainForm1.FormCreate(Sender: TObject);
begin
  ExePath := ExtractFilePath(Application.ExeName);
  Application.OnHint := showHint;
  JIniFileName := ChangeFileExt(Application.ExeName,'.ini');
  worklist := TStringlist.Create;
  ToDelete := TStringlist.Create;
  PageControl1.ActivePage := PageEinpacken;
end;

procedure TMainForm1.FormLoaded(Sender: TObject);
begin
  //Application.BringToFront;
  if ParamStr(1) <> '' then
  begin
    StartParam := ParamStr(1);
    Memo1.Lines.Add(ExtractFilePath(StartParam)+ '*.*');
    cbDelphiFilter.checked := true;
  end;
end;

procedure TMainForm1.cbDelphiFilterClick(Sender: TObject);
var
x : integer;
vz : Tstringlist;
begin
   if Memo1.Lines.count = 0 then exit;
   vz := Tstringlist.create;
   with Memo1 do
   begin
      if cbDelphiFilter.checked then
      begin
         for x := 0 to Lines.count - 1 do
         begin
            {Verzeichnis plus Dateityp erzeugen}
            vz.add(extractFilepath(Lines[x]) + '*.conf');
            vz.add(extractFilepath(Lines[x]) + '*.dpr');
            vz.add(extractFilepath(Lines[x]) + '*.kof');
            vz.add(extractFilepath(Lines[x]) + '*.res');
            vz.add(extractFilepath(Lines[x]) + '*.ddp');
            vz.add(extractFilepath(Lines[x]) + '*.todo');
            vz.add(extractFilepath(Lines[x]) + '*.pas');
            vz.add(extractFilepath(Lines[x]) + '*.xfm');
         end;
         lines.assign(vz);
      end
      else
      begin
         vz.assign(Lines);
         Lines.clear;
         for x := 0 to vz.count - 1 do
         begin
            {Dateityp-Darstellung je Verzeichnis entfernen}
            if lines.indexof(extractFilepath(vz[x]) + '*.*') = - 1 then
            lines.add(extractFilepath(vz[x]) + '*.*');
         end;
      end;
   end;
vz.free;
end;

procedure TMainForm1.BtnPackClick(Sender: TObject);
var jz, packlst, comment : string;
    lst : TStringList;
begin
     packlst := ExePath + 'packlst.lst';
     ToDelete.Add(packlst);
     comment :=  ExePath + 'ackommentar.txt';
     ToDelete.Add(comment);
     ArchName := ChangeFileExt(StartParam,'.arj');

     if Memo1.lines.count > 0 then begin
       Memo1.lines.savetofile(packlst);
     end
     else
     begin
       beep;
       showmessage('Sie haben keine Dateien/Verzeichnisse ausgewählt, die zu packen wären!');
       exit;
     end;

     {Kommentar zu Chapterarchiv}
     if MemoKommentar.Lines.count > 0 then
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
     if not SetCurrentDir(ExtractFilePath(ArchName)) { *Konvertiert von SetCurrentDir* } then
     begin
       showmessage('In das Verzeichnis ' +
         ExtractFilePath(ArchName) + ' , Standort für das Chapterarchiv, konnte nicht gewechselt werden!');
       exit;
     end;
     try
       Jei;
       //lst := TStringLIst.Create;
       {* laut Packliste packen *}
       {$IFDEF Linux}
       cmdline :=  EXEPATH + 'arj.exe ac '  + ArchName + ' \!' + packlst ;
       {$Else}
       cmdline :=  EXEPATH + 'arj.exe ac '  + ArchName + ' !' + packlst ;
       {$ENDIF }

       //ShowMessage(cmdline);

       //if libc.system(PChar(cmdline)) = -1 then
       Process1.CommandLine:=cmdline;
       try
       Process1.Execute;

       except
         on E:Exception do
         showmessage(cmdline + NL + 'konnte NICHT erfolgreich ausgeführt werden!' + NL + NL +
         'Systemmeldung: ''' + E.Message);

       end;
       //lst.Add(cmdline);
       {* Chapterarchiv kommentieren *}
       cmdline :=  EXEPATH + 'arj.exe c '  + ArchName + jz ;
       //ShowMessage(cmdline);

       //   if libc.system(PChar(cmdline)) = -1 then showmessage(cmdline + NL + 'konnte NICHT erfolgreich ausgeführt werden!');
       Process1.CommandLine:=cmdline;
       try
       Process1.Execute;

       except
         on E:Exception do
         showmessage(cmdline + NL + 'konnte NICHT erfolgreich ausgeführt werden!' + NL + NL +
         'Systemmeldung: ''' + E.Message);

       end;

       //lst.Add(cmdline);
       //lst.SaveToFile(ExePath + 'arjrun.sh');
       ShowContent;
     finally
       //lst.Free;
       Nei;
     end;
end;

procedure TMainForm1.JvFileNameAddFileAcceptFileName(Sender: TObject;
  var Value: String);
  var Action : boolean;
begin
  Action := true;
  JvFileNameAddFileAfterDialog(Sender,Value,Action);
end;

procedure TMainForm1.JvFileNameAddFileAfterDialog(Sender: TObject;
  var Name: String; var Action: Boolean);
begin
  if Action then
  begin
    Memo1.Lines.AddStrings(JvFileNameAddFile.DialogFiles);
    StartParam := Name;
  end;
end;

procedure TMainForm1.FormClose(Sender: TObject; var Action: TCloseAction);
var x : integer;
begin
  {* Arbeitsdateien wieder löschen *}
  //  for x := 0 to ToDelete.Count -1 do DeleteFile(ToDelete[x]); { *Konvertiert von DeleteFile* }

  worklist.Free;
  ToDelete.Free;

end;

procedure TMainForm1.JvFilenameEditArchivAcceptFileName(Sender: TObject;
  var Value: String);
begin
  ArchName:=Value;
  ShowContent;
end;

procedure TMainForm1.ShowContent;
var x : integer;
    tmp : string;
begin
  {* Archivkopf einlesen *}
  {$IFDEF Linux}
  cmdline :=  EXEPATH + 'arj.exe v \-jv1 '  + ArchName + ' > ' + ExePath +'inhalt.txt' ;
  {$Else}
  cmdline :=  EXEPATH + 'arj.exe v -jv1 '  + ArchName + ' > ' + ExePath +'inhalt.txt' ;
  {$ENDIF }
  //ShowMessage(cmdline);



  //if libc.system(PChar(cmdline)) = -1 then  showmessage(cmdline + NL + 'konnte NICHT erfolgreich ausgeführt werden!');
  Process1.CommandLine:=cmdline;
  try
  Process1.Execute;

  except
    on E:Exception do
    showmessage(cmdline + NL + 'konnte NICHT erfolgreich ausgeführt werden!' + NL + NL +
    'Systemmeldung: ''' + E.Message);

  end;


  ToDelete.add(ExePath + 'inhalt.txt');
    

  worklist.LoadFromFile(ExePath +'inhalt.txt');
  ListBoxArchivHead.Clear;
  {* erste Zeilen einlesen und gleichzeitig aus Stringlist löschen *}
  if  worklist.Count > 5 then
  begin
    for x := 0 to 5 do
    begin
      ListBoxArchivHead.Items.Add(worklist[0]);
      worklist.Delete(0);
    end;

    {* letzte Zeile löschen *}
    worklist.Delete(worklist.Count-1);

    {* Viel Schweiß: So umformatieren, daß nur 1 Leerzeichen als Trennzeichen
       der Zellwerte übrig bleibt *}
    for x := 0 to worklist.Count -1 do
     worklist.Strings[x] := RemoveDoubleDelimiters(worklist.Strings[x]);

    {* Spaltentitel aus const GridColumns einfügen *}
    worklist.Insert(0,GridColumns);

    {* Umformatierte Stringliste speichern und in Grid einlesen *}
    worklist.SaveToFile(ExePath +'inhalt.txt');
    // LoadFromFile(GridContent,ExePath +'inhalt.txt',' ');
    GridContent.LoadFromCSVFile(ExePath +'inhalt.txt',' ');

    {* Archivkommentare in ListBoxArchivHead anzeigen *}

    {$IFDEF Linux}
    cmdline :=  EXEPATH + 'arj.exe v \-jb* '  + ArchName + ' > ' + ExePath +'chaptercomments.txt' ;
    {$Else}
    cmdline :=  EXEPATH + 'arj.exe v -jb* '  + ArchName + ' > ' + ExePath +'chaptercomments.txt' ;
    {$ENDIF }

    // ShowMessage(cmdline);

    // if libc.system(PChar(cmdline)) = -1 then showmessage(cmdline + NL + 'konnte NICHT erfolgreich ausgeführt werden!');
    Process1.CommandLine:=cmdline;
    try
    Process1.Execute;

    except
      on E:Exception do
      showmessage(cmdline + NL + 'konnte NICHT erfolgreich ausgeführt werden!' + NL + NL +
      'Systemmeldung: ''' + E.Message);

    end;

    ToDelete.Add(ExePath +'chaptercomments.txt');

    worklist.LoadFromFile(ExePath +'chaptercomments.txt');
    for x := 0 to worklist.Count -1 do
    begin
     {* Ab hier nur noch Chapterkommentare *}
     if pos('<<<',worklist[x]) >= 5 then break;
    end;

    for x := x to worklist.Count -3 do
    begin
     {* Ergebnis z.B. = Chapter: <<<001>>> *}
     if pos('<<<',worklist[x]) >= 5 then
       worklist[x] := 'Chapter: ' + copy(worklist[x],5,MaxInt);

     ListBoxArchivHead.Items.Add(worklist[x])
    end;

    {* optimale Spaltenbreite einstellen *}
    for x := 0 to GridContent.ColCount -1 do
     GridContent.AutoSizeColumn(x);

    PageControl1.ActivePage := PageAuspacken;
  end;

end;

procedure TMainForm1.JvFilenameEditArchivBeforeDialog(Sender: TObject;
  var Name: String; var Action: Boolean);
begin
  if StartParam <> '' then
    JvFilenameEditArchiv.InitialDir := ExtractFilePath(StartParam)
  else
    JvFilenameEditArchiv.InitialDir := ExePath;
end;


function TMainForm1.RemoveDoubleDelimiters(AStr: string;
  ADelimiter: Char): string;
  var 
  tmp : string;

  {* BEGIN: Hilfsfunktionen aus JvJCLUtils.pas *}
      function DelBSpace(const S: string): string;
      var
        I, L: Integer;
      begin
        L := Length(S);
        I := 1;
        while (I <= L) and (S[I] = ' ') do
          Inc(I);
        Result := Copy(S, I, MaxInt);
      end;

      function Copy2Symb(const S: string; Symb: Char): string;
      var
        P: Integer;
      begin
        P := Pos(Symb, S);
        if P = 0 then
          P := Length(S) + 1;
        Result := Copy(S, 1, P - 1);
      end;

      function Copy2SymbDel(var S: string; Symb: Char): string;
      begin
        Result := Copy2Symb(S, Symb);
        S := DelBSpace(Copy(S, Length(Result) + 1, Length(S)));
      end;

  {* END: Hilfsfunktionen aus JvJCLUtils.pas *}

begin
  AStr := trim(AStr);
  Result := '';{* Result := '' -> komisch,aber notwendig *}
  tmp := Copy2SymbDel(AStr,ADelimiter);
  while tmp <> '' do
  begin
   Result := trim(Result) + ADelimiter + tmp;
   tmp := Copy2SymbDel(AStr,ADelimiter);
  end;

end;

procedure TMainForm1.JvFilenameEditArchivAfterDialog(Sender: TObject;
  var Name: String; var Action: Boolean);
begin
  if Action then
  begin
    ArchName := Name;
    ShowContent;
  end;
end;

procedure TMainForm1.PageControl1Change(Sender: TObject);
begin
  {* hilft anscheinend, das Control richtig darzustellen *}
  JvFilenameEditArchiv.Parent := JvFilenameEditArchiv.Parent;
  JvFileNameAddFile.Parent := JvFileNameAddFile.Parent;
end;

procedure TMainForm1.ListBoxArchivHeadDrawItem(Sender: TObject;
  Index: Integer; Rect: TRect; State: TOwnerDrawState;
  var Handled: Boolean);
begin
  with (Sender as TListbox).Canvas do
  begin
    if pos('Chapter:',(Sender as TListbox).Items[Index]) > 0 then
    begin
      Handled :=true;
      FillRect(Rect);
      Font.Color := clRed;
      Font.Style := Font.Style + [fsBold];
      TextOut(Rect.Left,Rect.Top,(Sender as TListbox).Items[Index]);
    end
    else
      Handled :=false;
  end; {* with *}
end;

procedure TMainForm1.JvFileNameAddFileBeforeDialog(Sender: TObject;
  var Name: String; var Action: Boolean);
begin
  if Name <> '' then exit;
  if DirectoryExists(Maindir) { *Konvertiert von DirectoryExists* } then
    JvFileNameAddFile.InitialDir := Maindir
  else
    JvFileNameAddFile.InitialDir := ExePath;

end;

end.
