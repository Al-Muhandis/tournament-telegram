unit stresstest_telegram;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, telegram, tgtypes, tgsendertypes
  ;

type

  { TReceiverThread_StressTest }

  TReceiverThread_StressTest = class(TReceiverThread)
  public
    procedure Execute; override;
  end;

implementation

uses
  fpjson, jsonscanner, jsonparser, mainform, DateUtils
  ;

type
  TUserRec = record
    ID: Int64;
    Name: String;
  end;

const
  _sJSONMessage=
    '{"message_id":0,"from":{"id":0,"is_bot":false,"first_name":"","username":"","language_code":"ru"},"chat":{"id":-1000000000000,"title":"","username":"","type":"private"},"date":0,"text":""}';
  _Users: array of TUserRec = (
      (ID: 0123456789; Name: 'Adam'), (ID: 1234567890; Name: 'Benjamin'), (ID: 2345678901; Name: 'Christopher'),
      (ID: 3456789012; Name: 'Daniel'), (ID: 4567890123; Name: 'Ethan'), (ID: 5678901234; Name: 'Frank'),
      (ID: 6789012345; Name: 'George'), (ID: 7890123456; Name: 'Henry'), (ID: 8901234567; Name: 'Isaac'),
      (ID: 9012345678; Name: 'Jack'), (ID: 110123456789; Name: 'Kevin'), (ID: 220123456789; Name: 'Lucas')
    );

{ TReceiverThread_StressTest }

procedure TReceiverThread_StressTest.Execute;
var
  aMessage: TTelegramMessageObj;
  aOnReceiveMessage: TMessageEvent;
  aJSON: TJSONObject;
  aID: Int64;
  i: Integer;
  aUserRec: TUserRec;
  aName: String;
begin
  Randomize;
  try
    aJSON:=GetJSON(_sJSONMessage) as TJSONObject;
    try
      i:=0;
      aOnReceiveMessage:=Bot.OnReceiveMessage;
      while not Terminated do
      begin
        aUserRec:=_Users[Random(Length(_Users))];
        aID:=aUserRec.ID;
        aName:=Format(aUserRec.Name+' #%d', [aID]);
        aJSON.Int64s['date']:=DateTimeToUnix(Now, False);
        with aJSON.Objects['from'] do
        begin
          Int64s['id']:=aID;
          Strings['first_name']:=aName;
        end;
        with aJSON.Objects['chat'] do
        begin
          Int64s['id']:=aID;
          Strings['first_name']:=aName;
        end;
        Inc(i);
        aJSON.Strings['text']:=Format('Слово %d. Time: %s', [i, TimeToStr(Now)]);
        aMessage:=TTelegramMessageObj.Create(aJSON);
        try
          aOnReceiveMessage(Self, aMessage);
        finally
          aMessage.Free;
        end;
        Sleep(5);
      end;
    finally
      aJSON.Free;
    end;
  except
    on E: Exception do
      Bot.Logger.Error(E.ClassName+': '+ E.Message);
  end;
end;

initialization
  _TourReceiverThreadClass:=TReceiverThread_StressTest;

end.

