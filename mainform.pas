unit mainform;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, DB, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls, ComCtrls, IniPropStorage, DBCtrls,
  SpinEx, ZConnection, ZDataset, RxDBGrid, rxlookup, telegram, tgtypes, TimerFrame, tgsendertypes,
  frmtournamentform
  ;

type

  { TFrmMain }

  TFrmMain = class(TForm)
    BtnStart: TButton;
    ChckBxAnswertimer: TCheckBox;
    DtSrcTournaments: TDataSource;
    DBNavigator1: TDBNavigator;
    DBNvgtrPlayers: TDBNavigator;
    DtSrcAnswers: TDataSource;
    DtSrcPlayers: TDataSource;
    DtSrcTeams: TDataSource;
    EdtAdminChatID: TLabeledEdit;
    FrmTrnmnt: TFrameTournament;
    FrmTmr: TFrameTimer;
    GroupBox1: TGroupBox;
    GroupBox2: TGroupBox;
    GroupBox3: TGroupBox;
    GroupBox4: TGroupBox;
    GrpBxQuestion: TGroupBox;
    EdtTelegramToken: TLabeledEdit;
    IniPrpStrg: TIniPropStorage;
    Label2: TLabel;
    PgCntrlTables: TPageControl;
    PgCntrl: TPageControl;
    RxDBGrd: TRxDBGrid;
    RxDBGrdPlayers: TRxDBGrid;
    RxLookupEdit1: TRxLookupEdit;
    SpnEdtQuestion: TSpinEditEx;
    Splitter1: TSplitter;
    TbShtTournament: TTabSheet;
    TabShtPlayers: TTabSheet;
    TbShtAnswers: TTabSheet;
    TbShtGame: TTabSheet;
    TbShtOptions: TTabSheet;
    TglBxReceive: TToggleBox;
    ToolBar1: TToolBar;
    ToolBar2: TToolBar;
    TlBtnOnlyAccepted: TToolButton;
    ToolButton2: TToolButton;
    ZCnctn: TZConnection;
    ZQryAnswers: TZQuery;
    ZQryAnswersaccepted: TBooleanField;
    ZQryAnswersquestion: TLargeintField;
    ZQryAnswersTeamTitle: TStringField;
    ZQryAnswerstournament: TLargeintField;
    ZQryAnswersUserTEamID: TLargeintField;
    ZQryAnswersuser_id: TLargeintField;
    ZQryPlayers: TZQuery;
    ZQryAnswersanswer: TStringField;
    ZQryID: TAutoIncField;
    ZQryAnswerssent: TTimeField;
    ZQryPlayersid: TLargeintField;
    ZQryPlayersteam: TLongintField;
    ZQryPlayerstitle: TStringField;
    ZQryTeams: TZReadOnlyQuery;
    ZQryTeamsid: TLargeintField;
    ZQryTeamsname: TStringField;
    ZQryTournaments: TZReadOnlyQuery;
    procedure BtnQuestionSendClick({%H-}Sender: TObject);
    procedure BtnStartClick({%H-}Sender: TObject);
    procedure FormClose({%H-}Sender: TObject; var {%H-}CloseAction: TCloseAction);
    procedure FormCreate({%H-}Sender: TObject);
    procedure FormDestroy({%H-}Sender: TObject);
    procedure FormShow({%H-}Sender: TObject);
    procedure SpnEdtQuestionChange(Sender: TObject);
    procedure TglBxReceiveChange(Sender: TObject);
    procedure TlBtnOnlyAcceptedClick(Sender: TObject);
    procedure ZQryAnswersreplyGetText(Sender: TField; var aText: string; {%H-}DisplayText: Boolean);
    procedure ZQryAnswersTeamTitleGetText({%H-}Sender: TField; var aText: string; {%H-}DisplayText: Boolean);
  private
    FDoUpdateTelegram: Boolean;
    FTelegramFace: TTelegramSender;
    FTelegramReceiver: TReceiverThread;
    procedure FormReceiveMessage(aMsg: TTelegramMessageObj);
    procedure OpenDB;
    procedure ReopenAnswers;
    procedure FrmStopTimer(Sender: TObject);
  public

  end;

var
  FrmMain: TFrmMain;

implementation

uses
  eventlog, tgutils, DateUtils, sql_db
  ;

var
  AppDir: String;

{$R *.lfm}

{ TFrmMain }

procedure TFrmMain.FormCreate(Sender: TObject);
var
  aLogger: TEventLog;
begin
  FTelegramFace:=TTelegramSender.Create(EdtTelegramToken.Text);
  FDoUpdateTelegram:=False;
  aLogger:=TEventLog.Create(nil);
  aLogger.LogType:=ltFile;
  aLogger.Active:=True;
  FTelegramFace.Logger:=aLogger;
  FTelegramFace.LogDebug:=True;
  FrmTmr.StartAudioFile:='min-start.wav';
  FrmTmr.AlertAudioFile:='min-alert.wav';
  FrmTmr.StopAudioFile:='min-stop.wav';
  FrmTmr.StartTime:=Now;
  FrmTmr.AnswerTimer:=ChckBxAnswertimer.Checked;
  FrmTmr.OnStop:=@FrmStopTimer;
  FrmTrnmnt.InitDB;
  OpenDB;
end;

procedure TFrmMain.BtnQuestionSendClick(Sender: TObject);
var
  aChatID: int64;
begin
  if not FDoUpdateTelegram then
    Exit;
  Cursor:=crHourGlass;
  try
    if EdtTelegramToken.Text<>EmptyStr then
      if TryStrToInt64(Trim(EdtAdminChatID.Text), aChatID) then
        FTelegramFace.Token:=EdtTelegramToken.Text;
  finally
    Cursor:=crDefault;
  end;
end;

procedure TFrmMain.BtnStartClick(Sender: TObject);
begin
  SpnEdtQuestion.Value:=SpnEdtQuestion.Value+1;
end;

procedure TFrmMain.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  FrmTrnmnt.ApplyDB;
end;

procedure TFrmMain.FormDestroy(Sender: TObject);
begin
  FTelegramFace.Logger.Free;
  FTelegramFace.Free;

  if Assigned(FTelegramReceiver) then
  begin
    FTelegramReceiver.Terminate;
    FTelegramReceiver.WaitFor;
  end;
end;

procedure TFrmMain.FormShow(Sender: TObject);
begin
  FDoUpdateTelegram:=True;
end;

procedure TFrmMain.SpnEdtQuestionChange(Sender: TObject);
begin
  ReopenAnswers;
end;

procedure TFrmMain.TglBxReceiveChange(Sender: TObject);
begin
  TglBxReceive.Enabled:=False;
  try
    if (Sender as TToggleBox).Checked then
    begin
      FTelegramReceiver:=TReceiverThread.Create(EdtTelegramToken.Text);
      FTelegramReceiver.FreeOnTerminate:=True;
      FTelegramReceiver.OnDoMessage:=@FormReceiveMessage;
      FTelegramReceiver.Start;
    end
    else begin
      FTelegramReceiver.Terminate;
      FTelegramReceiver.WaitFor;
      FTelegramReceiver:=nil;
    end;
  finally
    TglBxReceive.Enabled:=True;
  end;
end;

procedure TFrmMain.TlBtnOnlyAcceptedClick(Sender: TObject);
begin
  ReopenAnswers;
end;

procedure TFrmMain.ZQryAnswersreplyGetText(Sender: TField; var aText: string; DisplayText: Boolean);
begin
  case Sender.AsInteger of
    0: aText:='?';
    1: aText:='Взят';
    2: aText:='Не взят';
  end;
end;

procedure TFrmMain.ZQryAnswersTeamTitleGetText(Sender: TField; var aText: string; DisplayText: Boolean);
var
  aTeamID: LongInt;
begin
  aTeamID:=ZQryAnswersUserTEamID.AsInteger;
  if FrmTrnmnt.ZQryTeams.Locate('id', aTeamID{%H-}, []) then
    aText:=FrmTrnmnt.ZQryTeamsname.AsString
  else
    aText:=' *не задано* ';
end;

procedure TFrmMain.FormReceiveMessage(aMsg: TTelegramMessageObj);
var
  aUser, S: String;
  aAdminChat, aUserID: int64;
  aDT, aTime: TDateTime;
  //aAdminID: int64;
begin
  aUserID:=aMsg.From.id;
  aUser:=CaptionFromUser(aMsg.From);
  aDT:=UnixToDateTime(aMsg.Date, False);
  if (aMsg.Text='/bind') and (EdtAdminChatID.Text=EmptyStr) then
  begin
    S:=Format('Вы хотите установить чат %s в качестве журнала Ведущего?', [CaptionFromChat(aMsg.Chat)]);
    if MessageDlg(Application.Title, S, mtConfirmation, mbYesNo, 0)=mrYes then
      EdtAdminChatID.Text:=aMsg.Chat.ID.ToString;
    Exit;
  end;
  if aMsg.From.ID<>aMsg.Chat.ID then
    Exit;
  aTime:=aDT-FrmTmr.StartTime;
  S:=TimeToStr(aDT-FrmTmr.StartTime);
  if EdtTelegramToken.Text=EmptyStr then
    Exit
  else
    FTelegramFace.Token:=EdtTelegramToken.Text;
  if not TryStrToInt64(Trim(EdtAdminChatID.Text), aAdminChat) then
    aAdminChat:=0;

  if not ZQryPlayers.Locate('id', aUserID{%H-}, []) then
  begin
    ZQryPlayers.Append;
    ZQryPlayersid.AsLargeInt:=aUserID;
    ZQryPlayerstitle.AsString:=aUser;
    ZQryPlayers.Post;
    ZQryPlayers.ApplyUpdates;
  end;
  ZQryAnswers.Append;
  ZQryAnswerstournament.AsInteger:=FrmTrnmnt.ZQryTournamentsid.AsInteger;
  ZQryAnswersquestion.AsInteger:=SpnEdtQuestion.Value;
  ZQryAnswersanswer.AsString:=aMsg.Text;
  ZQryAnswersuser_id.AsLargeInt:=aUserID;
  ZQryAnswerssent.AsDateTime:=aTime;
  ZQryAnswers.Post;
  ZQryAnswers.ApplyUpdates;
  if aAdminChat<>0 then
    FTelegramFace.sendMessage(aAdminChat, 'Ответ сдан '+aUser+' ['+S+']:'+LineEnding+aMsg.Text);
end;

procedure TFrmMain.OpenDB;
begin
  ZCnctn.Disconnect;
  ZCnctn.Database:=AppDir+'default.sqlite';
  ZCnctn.Connect;
  ZCnctn.ExecuteDirect(_sql_players);
  ZCnctn.ExecuteDirect(_sql_answers);

  ZQryTeams.Connection:=FrmTrnmnt.ZCnctn;
  ZQryTeams.Active:=True;
  ZQryTournaments.Connection:=FrmTrnmnt.ZCnctn;
  ZQryTournaments.Active:=True;
  ZQryAnswers.Active:=True;
  ZQryPlayers.Active:=True;
end;

procedure TFrmMain.ReopenAnswers;
var
  s: String;
begin
  if TlBtnOnlyAccepted.Down then
    s:=' and accepted = ''Y'''
  else
    s:=EmptyStr;
  ZQryAnswers.SQL.Text:=format('select * from answers where tournament = %d and question = %d%s',
    [FrmTrnmnt.ZQryTournamentsid.AsInteger, SpnEdtQuestion.Value, s]);
  ZQryAnswers.Open;
end;

procedure TFrmMain.FrmStopTimer(Sender: TObject);
begin
  TlBtnOnlyAccepted.Down:=False;
  ZQryAnswers.First;
  while not ZQryAnswers.EOF do
  begin
    ZQryAnswers.Edit;
    ZQryAnswersaccepted.AsBoolean:=False;
    ZQryAnswers.Post;
    ZQryAnswers.Next;
  end;
  ZQryAnswers.SQL.Text:=format(
    'select *, max(sent) from answers where tournament = %d and question = %d and sent < ''%s'' group by user_id',
    [FrmTrnmnt.ZQryTournamentsid.AsInteger, SpnEdtQuestion.Value, '00:01:15']);
  ZQryAnswers.Open;
  ZQryAnswers.First;
  while not ZQryAnswers.EOF do
  begin
    ZQryAnswers.Edit;
    ZQryAnswersaccepted.AsBoolean:=True;
    ZQryAnswers.Post;
    ZQryAnswers.Next;
  end;     
  ZQryAnswers.ApplyUpdates;
end;

initialization

  AppDir:=IncludeTrailingPathDelimiter(ExtractFileDir(ParamStr(0)));

end.

