unit telegram;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, tgsendertypes, taskworker, tgtypes
  ;

type

  { TTelegramTask }

  TTelegramTask = class(TPersistent)
  private
    FAnswer: String;
    FID: Integer;
    FQuestion: Integer;
  public
    procedure Assign(Source: TPersistent); override;
  published
    property Question: Integer read FQuestion write FQuestion;
    property Answer: String read FAnswer write FAnswer;
    property ID: Integer read FID write FID;
  end;

  TCustomTelegramThread = specialize TgTaskWorkerThread<TTelegramTask>;

  TOnEventCallback = procedure (aClbck: TCallbackQueryObj) of object;
  TOnEventMessage =  procedure (aMsg: TTelegramMessageObj) of object;

  { TReceiverThread }

  TReceiverThread=class(TThread)
  private
    FBot: TTelegramSender;
    FOnDoCallback: TOnEventCallback; 
    FOnDoMessage: TOnEventMessage;
    FLPTimeout: Integer;
    procedure BotReceiveCallbackQuery({%H-}ASender: TObject; {%H-}ACallback: TCallbackQueryObj);
    procedure BotReceiveMessage({%H-}ASender: TObject; {%H-}AMessage: TTelegramMessageObj);
    procedure BotStartCommandHandler({%H-}ASender: TObject; const {%H-}ACommand: String;
      {%H-}AMessage: TTelegramMessageObj);
    procedure SendMsgToMainThreadCallback;  
    procedure SendMsgToMainThreadAnswer;
  public
    constructor Create(const AToken: String);
    destructor Destroy; override;
    procedure Execute; override;
    property Bot: TTelegramSender read FBot write FBot;
    property OnDoCallback: TOnEventCallback read FOnDoCallback write FOnDoCallback;  
    property OnDoMessage: TOnEventMessage read FOnDoMessage write FOnDoMessage;
  end;

implementation

uses
  Graphics, fpjson, eventlog
  ;

resourcestring
  s_StrtMsg='This is a telegram bot for an intellectual tournament';

{ TReceiverThread }

procedure TReceiverThread.BotReceiveCallbackQuery(ASender: TObject; ACallback: TCallbackQueryObj);
begin
  Synchronize(@SendMsgToMainThreadCallback);
end;

procedure TReceiverThread.BotReceiveMessage(ASender: TObject; AMessage: TTelegramMessageObj);
begin
  Synchronize(@SendMsgToMainThreadAnswer);
end;

procedure TReceiverThread.BotStartCommandHandler(ASender: TObject; const ACommand: String;
  AMessage: TTelegramMessageObj);
begin
  FBot.sendMessage(s_StrtMsg);
end;

procedure TReceiverThread.SendMsgToMainThreadCallback;
begin
  if Assigned(FOnDoCallback) then
    FOnDoCallback(FBot.CurrentUpdate.CallbackQuery);
end;

procedure TReceiverThread.SendMsgToMainThreadAnswer;
begin                                               
  if Assigned(FOnDoMessage) then
    FOnDoMessage(FBot.CurrentUpdate.Message);
end;

constructor TReceiverThread.Create(const AToken: String);
begin
  inherited Create(True);
  FreeOnTerminate:=False;
  FBot:=TTelegramSender.Create(AToken);
  FBot.Logger:=TEventLog.Create(nil);
  FBot.Logger.LogType:=ltFile;
  FBot.Logger.FileName:='receiver.log';
  FBot.LogDebug:=True;
  FBot.CommandHandlers['/start']:=@BotStartCommandHandler;
  Fbot.OnReceiveCallbackQuery:=@BotReceiveCallbackQuery;  
  Fbot.OnReceiveMessage:=@BotReceiveMessage;
  FLPTimeout:=6;
end;

destructor TReceiverThread.Destroy;
begin
  FBot.Logger.Free;
  FreeAndNil(FBot);
  inherited Destroy;
end;

procedure TReceiverThread.Execute;
begin
  try
    while not Terminated do
      FBot.getUpdatesEx(0, FLPTimeout);
  except
    on E: Exception do
      FBot.Logger.Error(E.ClassName+': '+ E.Message);
  end;
end;

{ TTelegramTask }


procedure TTelegramTask.Assign(Source: TPersistent);
var
  aSource: TTelegramTask;
begin
  if Source is TTelegramTask then
  begin
    aSource:=TTelegramTask(Source);
    FQuestion:=aSource.Question;
    FAnswer:=aSource.Answer;
    FID:=aSource.ID;
  end else
    inherited Assign(Source);
end;

end.

