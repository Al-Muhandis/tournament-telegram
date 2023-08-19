unit mainform;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, DB, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls, ComCtrls, IniPropStorage, DBCtrls,
  SpinEx, ZConnection, ZDataset, RxDBGrid, telegram, tgtypes, TimerFrame, tgsendertypes,
  frmtournamentform
  ;

type

  { TFrmMain }

  TFrmMain = class(TForm)
    BtnStart: TButton;
    ChckBxAnswertimer: TCheckBox;
    ChckBxQuestionAutoInc: TCheckBox;
    DBLkpCmbBx: TDBLookupComboBox;
    DtSrcTournaments: TDataSource;
    DBNvgtrAnswers: TDBNavigator;
    DBNvgtrPlayers: TDBNavigator;
    DtSrcAnswers: TDataSource;
    DtSrcPlayers: TDataSource;
    DtSrcTeams: TDataSource;
    EdtAdminChatID: TLabeledEdit;
    FrmTrnmnt: TFrameTournament;
    FrmTmr: TFrameTimer;
    GrpBxTimer: TGroupBox;
    GrpBxGameTables: TGroupBox;
    GrpBxTelegram: TGroupBox;
    GrpBxQuestion: TGroupBox;
    EdtTelegramToken: TLabeledEdit;
    IniPrpStrg: TIniPropStorage;
    LblTournament: TLabel;
    LblAdminChatID: TLabel;
    LblQuestionNumber: TLabel;
    Memo1: TMemo;
    PgCntrlControl: TPageControl;
    PgCntrlTables: TPageControl;
    PgCntrlMain: TPageControl;
    DBGrdAnswers: TRxDBGrid;
    RxDBGrdPlayers: TRxDBGrid;
    SpnEdtQuestion: TSpinEditEx;
    Spltr: TSplitter;
    TbShtAbout: TTabSheet;
    TbShtControlOptions: TTabSheet;
    TbShtControl: TTabSheet;
    TbShtTournament: TTabSheet;
    TabShtPlayers: TTabSheet;
    TbShtAnswers: TTabSheet;
    TbShtGame: TTabSheet;
    TglBxReceive: TToggleBox;
    TlBrAnswers: TToolBar;
    TlBrPlayers: TToolBar;
    TlBtnOnlyAccepted: TToolButton;
    TlBtn1: TToolButton;
    ZCnctn: TZConnection;
    ZQryAnswers: TZQuery;
    ZQryAnswersaccepted: TBooleanField;
    ZQryAnswersBetRound: TBooleanField;
    ZQryAnswersenrolled: TBooleanField;
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
    ZQryPlayersTeamName: TStringField;
    ZQryPlayerstitle: TStringField;
    ZQryTeams: TZReadOnlyQuery;
    ZQryTeamsid: TLargeintField;
    ZQryTeamsname: TStringField;
    ZQryTournaments: TZReadOnlyQuery;
    ZQryTournamentsdate: TDateField;
    ZQryTournamentsid: TLargeintField;
    ZQryTournamentstitle: TStringField;   
    procedure BetChange(Sender: TField; aRoundNum: Byte);
    procedure BtnQuestionSendClick({%H-}Sender: TObject);
    procedure BtnStartClick({%H-}Sender: TObject);
    procedure DBLkpCmbBxChange({%H-}Sender: TObject);
    procedure FormClose({%H-}Sender: TObject; var {%H-}CloseAction: TCloseAction);
    procedure FormCreate({%H-}Sender: TObject);
    procedure FormDestroy({%H-}Sender: TObject);
    procedure FormShow({%H-}Sender: TObject);
    procedure IniPrpStrgRestoringProperties(Sender: TObject);
    procedure IniPrpStrgSavingProperties(Sender: TObject);
    procedure PgCntrlMainChange({%H-}Sender: TObject);
    procedure SpnEdtQuestionChange({%H-}Sender: TObject);
    procedure TglBxReceiveChange(Sender: TObject);
    procedure TlBtnOnlyAcceptedClick({%H-}Sender: TObject);
    procedure ZQryAnswersBetRoundChange(Sender: TField);
    procedure ZQryAnswersCalcFields({%H-}DataSet: TDataSet);
    procedure ZQryAnswersenrolledChange(Sender: TField);
    procedure ZQryAnswersreplyGetText(Sender: TField; var aText: string; {%H-}DisplayText: Boolean);
    procedure ZQryAnswersTeamTitleGetText({%H-}Sender: TField; var aText: string; {%H-}DisplayText: Boolean);
  private
    FDoUpdateTelegram: Boolean;
    FTelegramFace: TTelegramSender;
    FTelegramReceiver: TReceiverThread;
    procedure FormReceiveMessage(aMsg: TTelegramMessageObj);
    procedure FrmStartTimer({%H-}Sender: TObject);
    procedure MainFormBetOptionChanged(aQuestionNum: Integer);
    procedure OpenDB;
    procedure UpdateAnswersTable;
    procedure FrmStopTimer({%H-}Sender: TObject);
  public

  end;

var
  FrmMain: TFrmMain;

implementation

uses
  eventlog, tgutils, DateUtils, sql_db, FileInfo, Variants
  ;

var
  AppDir: String;

{$R *.lfm}

function BuildVersion: String;
var
  FileVerInfo: TFileVersionInfo;
begin
  try
    FileVerInfo:=TFileVersionInfo.Create(nil);
    try
      FileVerInfo.ReadFileInfo;
      if FileVerInfo.VersionStrings.Count>0 then
        Result:=FileVerInfo.VersionStrings.Values['FileVersion']
      else
        Result:=EmptyStr;
    finally
      FileVerInfo.Free;
    end;
  except
    Result := EmptyStr;
  end;
end;

function BuildString: String;
var
  aBuildVersion: String;
begin
  aBuildVersion:=BuildVersion;
  if aBuildVersion.IsEmpty then
    Result := 'Not success getting build resource info'
  else
    Result:='Версия: '+aBuildVersion;
  Result+=LineEnding+'  FPC: '+{$MACRO ON}IntToStr(FPC_FULLVERSION){$MACRO OFF};
end;

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
  FrmTmr.OnStart:=@FrmStartTimer;
  FrmTrnmnt.InitDB;
  FrmTrnmnt.OnBetOptionChanged:=@MainFormBetOptionChanged;
  OpenDB;

  Memo1.Lines.Add(BuildString);
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

procedure TFrmMain.DBLkpCmbBxChange(Sender: TObject);
begin
  UpdateAnswersTable;
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

procedure TFrmMain.IniPrpStrgRestoringProperties(Sender: TObject);
begin
  FrmTrnmnt.Q11InRound:=TIniPropStorage(Sender).ReadBoolean('Q11InRound', False);
  FrmTrnmnt.QuestionWithBet:=TIniPropStorage(Sender).ReadInteger('QWithBet', 0);
end;

procedure TFrmMain.IniPrpStrgSavingProperties(Sender: TObject);
begin
  TIniPropStorage(Sender).WriteBoolean('Q11InRound', FrmTrnmnt.Q11InRound); 
  TIniPropStorage(Sender).WriteInteger('QWithBet',   FrmTrnmnt.QuestionWithBet);
end;

procedure TFrmMain.PgCntrlMainChange(Sender: TObject);
var
  i: Integer;
begin
  i:=DBLkpCmbBx.ItemIndex;
  ZQryTournaments.Refresh;
  ZQryTeams.Refresh;
  if i<>-1 then
    DBLkpCmbBx.ItemIndex:=i;
end;

procedure TFrmMain.SpnEdtQuestionChange(Sender: TObject);
begin
  UpdateAnswersTable;
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
  UpdateAnswersTable;
end;

procedure TFrmMain.ZQryAnswersBetRoundChange(Sender: TField);
var
  aQuestion: Integer;
begin
  aQuestion:=SpnEdtQuestion.Value;
  BetChange(Sender, FrmTrnmnt.RoundFromQuestion(aQuestion));
end;

procedure TFrmMain.ZQryAnswersCalcFields(DataSet: TDataSet);
var
  aTour, aTeam, aQuestion: Integer;
  aAccepted: Boolean;
begin
  if DBLkpCmbBx.KeyValue = Null then
    aTour:=-1
  else
    aTour:=DBLkpCmbBx.KeyValue;
  aTeam:=ZQryAnswersUserTeamID.AsInteger; 
  aQuestion:=SpnEdtQuestion.Value;
  aAccepted:=ZQryAnswersaccepted.AsBoolean;
  if (aTour<>-1) and (aQuestion>0) and aAccepted and
    (FrmTrnmnt.ZQryScoreTable.Locate('tournament; team', VarArrayOf([aTour, aTeam]), [])) then
  begin
    ZQryAnswersenrolled.AsBoolean:=FrmTrnmnt.FieldFromQuestion(aQuestion).AsBoolean;
    ZQryAnswersBetRound.AsBoolean:=FrmTrnmnt.BetFieldFromQuestion(aQuestion).AsBoolean;
  end
  else begin
    ZQryAnswersenrolled.AsBoolean:=False;
    ZQryAnswersBetRound.AsBoolean:=False;
  end;
end;

procedure TFrmMain.ZQryAnswersenrolledChange(Sender: TField);
var
  aTour, aTeam, aQuestion: Integer;
  aAccepted: Boolean;
begin
  if DBLkpCmbBx.KeyValue <> Null then
    aTour:=DBLkpCmbBx.KeyValue
  else
    aTour:=-1;
  if aTour=-1 then
    Exit;
  aTeam:=ZQryAnswersUserTeamID.AsInteger;
  aQuestion:=SpnEdtQuestion.Value;
  aAccepted:=ZQryAnswersaccepted.AsBoolean;
  if aQuestion<=0 then
    Exit;
  if not aAccepted then
    Exit;
  if FrmTrnmnt.ZQryScoreTable.Locate('tournament; team', VarArrayOf([aTour, aTeam]), []) then
  begin
    FrmTrnmnt.ZQryScoreTable.Edit;
    FrmTrnmnt.FieldFromQuestion(aQuestion).AsBoolean:=Sender.AsBoolean;
    FrmTrnmnt.ZQryScoreTable.Post;
    FrmTrnmnt.ZQryScoreTable.ApplyUpdates;
  end;
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
  aTeamID:=ZQryAnswersUserTeamID.AsInteger;
  if FrmTrnmnt.ZQryTeams.Locate('id', aTeamID{%H-}, []) then
    aText:=FrmTrnmnt.ZQryTeamsname.AsString
  else
    aText:=' *не задано* ';
end;

procedure TFrmMain.BetChange(Sender: TField; aRoundNum: Byte);
var
  aTour, aTeam, aQuestion: Integer;
  aAccepted: Boolean;
  aBetROundField: TBooleanField;
begin
  if DBLkpCmbBx.KeyValue <> Null then
    aTour:=DBLkpCmbBx.KeyValue
  else
    aTour:=-1;
  if aTour=-1 then
    Exit;
  aTeam:=ZQryAnswersUserTeamID.AsInteger;
  aQuestion:=SpnEdtQuestion.Value;
  if aQuestion<=0 then
    Exit;
  aAccepted:=ZQryAnswersaccepted.AsBoolean;
  if not aAccepted then
    Exit;
  if FrmTrnmnt.ZQryScoreTable.Locate('tournament; team', VarArrayOf([aTour, aTeam]), []) then
  begin
    case aRoundNum of
      1: aBetROundField:=FrmTrnmnt.ZQryScoreTablebet1round;
      2: aBetROundField:=FrmTrnmnt.ZQryScoreTablebet2round;
      3: aBetROundField:=FrmTrnmnt.ZQryScoreTablebet3round;
    else
      Exit;
    end;
    FrmTrnmnt.ZQryScoreTable.Edit;
    aBetROundField.AsBoolean:=Sender.AsBoolean;
    FrmTrnmnt.ZQryScoreTable.Post;
    FrmTrnmnt.ZQryScoreTable.ApplyUpdates;
  end;
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

procedure TFrmMain.FrmStartTimer(Sender: TObject);
begin
  if ChckBxQuestionAutoInc.Checked then
    SpnEdtQuestion.Value:=SpnEdtQuestion.Value+1;
end;

procedure TFrmMain.MainFormBetOptionChanged(aQuestionNum: Integer);
begin
  ZQryAnswersBetRound.Visible:=aQuestionNum>0;
end;

procedure TFrmMain.OpenDB;
begin
  ZCnctn.Disconnect;
  ZCnctn.Database:=AppDir+'answers.sqlite';
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

procedure TFrmMain.UpdateAnswersTable;
var
  s: String;
  aTour: Integer;
begin
  if TlBtnOnlyAccepted.Down then
    s:=' and accepted = ''Y'''
  else
    s:=EmptyStr;
  if DBLkpCmbBx.KeyValue = Null then
    aTour:=-1
  else
    aTour:=DBLkpCmbBx.KeyValue;
  ZQryAnswers.SQL.Text:=format('select * from answers where tournament = %d and question = %d%s',
      [aTour, SpnEdtQuestion.Value, s]);
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
  end;                                                                { #todo : 00:01:15 - accept time to turn up }
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

