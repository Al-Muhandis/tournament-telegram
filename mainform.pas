unit mainform;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, DB, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls, ComCtrls, IniPropStorage, DBCtrls,
  SpinEx, ZConnection, ZDataset, RxDBGrid, telegram, tgtypes, TimerFrame, tgsendertypes
  ;

type

  { TFrmMain }

  TFrmMain = class(TForm)
    BtnStart: TButton;
    ChckBxAnswertimer: TCheckBox;
    DBNavigator1: TDBNavigator;
    DBNvgtrPlayers: TDBNavigator;
    DBNvgtrPlayers1: TDBNavigator;
    DtSrcAnswers: TDataSource;
    DtSrcPlayers: TDataSource;
    DtSrcTeams: TDataSource;
    EdtAdminChatID: TLabeledEdit;
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
    RxDBGrdPlayers1: TRxDBGrid;
    SpnEdtQuestion: TSpinEditEx;
    Splitter1: TSplitter;
    TbShtTeams: TTabSheet;
    TabShtPlayers: TTabSheet;
    TbShtAnswers: TTabSheet;
    TbShtGame: TTabSheet;
    TbShtOptions: TTabSheet;
    TglBxReceive: TToggleBox;
    ToolBar1: TToolBar;
    ToolBar2: TToolBar;
    ToolBar3: TToolBar;
    ZCnctn: TZConnection;
    ZQryAnswers: TZQuery;
    ZQryAnswersTeamTitle: TStringField;
    ZQryAnswersuserteamid: TLargeintField;
    ZQryAnswersuser_id: TLargeintField;
    ZQryPlayers: TZQuery;
    ZQryAnswersanswer: TStringField;
    ZQryID: TAutoIncField;
    ZQryAnswersquestion: TStringField;
    ZQryAnswersreply: TLargeintField;
    ZQryAnswerssent: TTimeField;
    ZQryTeams: TZQuery;
    ZQryPlayersid: TLargeintField;
    ZQryPlayersteam: TLongintField;
    ZQryPlayerstitle: TStringField;
    ZQryTeamsid: TLargeintField;
    ZQryTeamstitle: TStringField;
    ZQryTeamTitle: TStringField;
    procedure BtnQuestionSendClick({%H-}Sender: TObject);
    procedure BtnStartClick({%H-}Sender: TObject);
    procedure FormCreate({%H-}Sender: TObject);
    procedure FormDestroy({%H-}Sender: TObject);
    procedure FormShow({%H-}Sender: TObject);
    procedure TglBxReceiveChange(Sender: TObject);
    procedure ZQryAnswersCalcFields({%H-}DataSet: TDataSet);
    procedure ZQryAnswersreplyGetText(Sender: TField; var aText: string; {%H-}DisplayText: Boolean);
    procedure ZQryAnswersTeamTitleGetText({%H-}Sender: TField; var aText: string; {%H-}DisplayText: Boolean);
  private
    FDoUpdateTelegram: Boolean;
    FTelegramFace: TTelegramSender;
    FTelegramReceiver: TReceiverThread;
    procedure FormAppendMessage(aMsg: TTelegramMessageObj);
    procedure OpenDB;
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

procedure TFrmMain.TglBxReceiveChange(Sender: TObject);
begin
  TglBxReceive.Enabled:=False;
  try
    if (Sender as TToggleBox).Checked then
    begin
      FTelegramReceiver:=TReceiverThread.Create(EdtTelegramToken.Text);
      FTelegramReceiver.FreeOnTerminate:=True;
      FTelegramReceiver.OnDoMessage:=@FormAppendMessage;
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

procedure TFrmMain.ZQryAnswersCalcFields(DataSet: TDataSet);
begin

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
  aTeamID:=ZQryAnswersuserteamid.AsInteger;
  if ZQryTeams.Locate('id', aTeamID{%H-}, []) then
    aText:=ZQryTeamstitle.AsString
  else
    aText:=' *не задано* ';
end;

procedure TFrmMain.FormAppendMessage(aMsg: TTelegramMessageObj);
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
  aTime:=aDT-FrmTmr.StartTime;
  S:=TimeToStr(aDT-FrmTmr.StartTime);
  if (EdtTelegramToken.Text=EmptyStr) or
    not TryStrToInt64(Trim(EdtAdminChatID.Text), aAdminChat) then
    Exit
  else
    FTelegramFace.Token:=EdtTelegramToken.Text;

  if not ZQryPlayers.Locate('id', aUserID{%H-}, []) then
  begin
    ZQryPlayers.Append;
    ZQryPlayersid.AsLargeInt:=aUserID;
    ZQryPlayerstitle.AsString:=aUser;
    ZQryPlayers.Post;
    ZQryPlayers.ApplyUpdates;
  end;
  ZQryAnswers.Append;
  ZQryAnswersquestion.AsInteger:=SpnEdtQuestion.Value;
  ZQryAnswersanswer.AsString:=aMsg.Text;
  ZQryAnswersuser_id.AsLargeInt:=aUserID;
  ZQryAnswerssent.AsDateTime:=aTime;
  ZQryAnswers.Post;
  ZQryAnswers.ApplyUpdates;
  FTelegramFace.sendMessage(aAdminChat, 'Ответ сдан '+aUser+' ['+S+']:'+LineEnding+aMsg.Text);
end;

procedure TFrmMain.OpenDB;
begin
  ZCnctn.Disconnect;
  ZCnctn.Database:=AppDir+'default.sqlite3';
  ZCnctn.Connect;
  ZCnctn.ExecuteDirect(_sql_players);
  ZCnctn.ExecuteDirect(_sql_teams);
  ZCnctn.ExecuteDirect(_sql_rounds);

  ZQryAnswers.Active:=True;
  ZQryPlayers.Active:=True;
  ZQryTeams.Active:=True;
end;

initialization

  AppDir:=IncludeTrailingPathDelimiter(ExtractFileDir(ParamStr(0)));

end.

