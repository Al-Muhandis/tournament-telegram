unit mainform;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, DB, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls, ComCtrls, IniPropStorage, DBCtrls,
  ZConnection, ZDataset, RxDBGrid, telegram, tgtypes, TimerFrame
  ;

type

  { TFrmMain }

  TFrmMain = class(TForm)
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
    MmQuestion: TMemo;
    PgCntrlTables: TPageControl;
    PgCntrl: TPageControl;
    RxDBGrd: TRxDBGrid;
    RxDBGrdPlayers: TRxDBGrid;
    RxDBGrdPlayers1: TRxDBGrid;
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
    procedure BtnSendButtonClick({%H-}Sender: TObject);
    procedure BtnQuestionSendClick({%H-}Sender: TObject);
    procedure FormCreate({%H-}Sender: TObject);
    procedure FormDestroy({%H-}Sender: TObject);
    procedure FormShow({%H-}Sender: TObject);
    procedure TglBxReceiveChange(Sender: TObject);
    procedure ZQryAnswersCalcFields({%H-}DataSet: TDataSet);
    procedure ZQryAnswersreplyGetText(Sender: TField; var aText: string; {%H-}DisplayText: Boolean);
    procedure ZQryAnswersTeamTitleGetText(Sender: TField; var aText: string; DisplayText: Boolean);
  private
    FDoUpdateTelegram: Boolean;
    FTelegramFace: TTelegramFace;
    FTelegramReceiver: TReceiverThread;
    procedure FormAppendMessage(aMsg: TTelegramMessageObj);
    procedure OpenDB;
  public

  end;

var
  FrmMain: TFrmMain;

implementation

uses
  eventlog, tgutils, DateUtils
  ;

var
  AppDir: String;

{$R *.lfm}

{ TFrmMain }

procedure TFrmMain.FormCreate(Sender: TObject);
var
  aLogger: TEventLog;
begin
  FTelegramFace:=TTelegramFace.Create;
  FDoUpdateTelegram:=False;
  aLogger:=TEventLog.Create(nil);
  aLogger.LogType:=ltFile;
  aLogger.Active:=True;
  FTelegramFace.Bot.Logger:=aLogger;
  FTelegramFace.Bot.LogDebug:=True;
  FTelegramFace.ReSendInsteadEdit:=False;
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
      begin
        FTelegramFace.Chat:=aChatID;
        FTelegramFace.Bot.Token:=EdtTelegramToken.Text;
        FTelegramFace.UpdateQuestion(MmQuestion.Text);
      end;
  finally
    Cursor:=crDefault;
  end;
end;

procedure TFrmMain.BtnSendButtonClick(Sender: TObject);
var
  aChatID: int64;
begin
  if not FDoUpdateTelegram then
    Exit;
  Cursor:=crHourGlass;
  try
    if EdtTelegramToken.Text<>EmptyStr then
      if TryStrToInt64(Trim(EdtAdminChatID.Text), aChatID) then
      begin
        FTelegramFace.Chat:=aChatID;
        FTelegramFace.Bot.Token:=EdtTelegramToken.Text;
      end;
  finally
    Cursor:=crDefault;
  end;
end;

procedure TFrmMain.FormDestroy(Sender: TObject);
begin
  FTelegramFace.Bot.Logger.Free;
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
      FTelegramReceiver:=TReceiverThread.Create(EmptyStr);
      FTelegramReceiver.FreeOnTerminate:=True;
      FTelegramReceiver.OnDoMessage:=@FormAppendMessage;
      FTelegramReceiver.Bot.Token:=EdtTelegramToken.Text;
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
  aChatID, aUserID: int64;
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
    not TryStrToInt64(Trim(EdtAdminChatID.Text), aChatID) then
    Exit
  else begin
    FTelegramFace.Chat:=aChatID;
    FTelegramFace.Bot.Token:=EdtTelegramToken.Text;
  end;


  FTelegramFace.Bot.sendMessage(FTelegramFace.Chat, 'Игрок '+aUser+' дал ответ {'+S+'}:'+LineEnding+aMsg.Text);
  if not ZQryPlayers.Locate('id', aUserID{%H-}, []) then
  begin
    ZQryPlayers.Append;
    ZQryPlayersid.AsLargeInt:=aUserID;
    ZQryPlayerstitle.AsString:=aUser;
    ZQryPlayers.Post;
    ZQryPlayers.ApplyUpdates;
  end;
  ZQryAnswers.Append;
  ZQryAnswersquestion.AsString:=MmQuestion.Text;
  ZQryAnswersanswer.AsString:=aMsg.Text;
  ZQryAnswersuser_id.AsLargeInt:=aUserID;
  ZQryAnswerssent.AsDateTime:=aTime;
  ZQryAnswers.Post;
  ZQryAnswers.ApplyUpdates;
end;

procedure TFrmMain.OpenDB;
begin
  ZCnctn.Database:=AppDir+'default.sqlite3';
  ZCnctn.Connected:=True;
  ZQryAnswers.Active:=True;
  ZQryPlayers.Active:=True;
  ZQryTeams.Active:=True;
end;

initialization

  AppDir:=IncludeTrailingPathDelimiter(ExtractFileDir(ParamStr(0)));

end.

