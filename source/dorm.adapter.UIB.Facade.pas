{ *******************************************************************************
  Copyright 2010-2013 Daniele Teti

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

  http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
  ******************************************************************************** }

unit dorm.adapter.UIB.Facade;

interface

uses
  UIB,
  superobject, uiblib;

type
  TUIBFacade = class
  private
    FCharSet: string;
  protected
  var
    FUIBDatabase: TUIBDatabase;

  protected
    FCurrentTransaction: TUIBTransaction;
    FDatabaseConnectionString: string;
    FUsername: string;
    FPassword: string;
    FLibraryName: string;
    function NewStatement: TUIBStatement;
    function NewQuery: TUIBQuery;
    function GetCharsetFromString(const Charset: String): TCharacterSet;
  public
    constructor Create(const LibraryName: string;
      AUserName, APassword, AConnectionString, ACharSet: string);
    destructor Destroy; override;
    function GetConnection: TUIBDatabase;
    function GetCurrentTransaction: TUIBTransaction;
    procedure StartTransaction;
    procedure CommitTransaction;
    procedure RollbackTransaction;
    function Execute(ASQL: string): Int64; overload;
    function Execute(ASQLCommand: TUIBStatement): Int64; overload;
    function ExecuteQuery(ASQLCommand: TUIBQuery): TUIBQuery; overload;
    function Prepare(ASQL: string): TUIBQuery;
  end;

implementation

uses
  sysutils,
  dorm.Commons;

{ Factory }

procedure TUIBFacade.StartTransaction;
begin
  GetConnection;
  FCurrentTransaction.StartTransaction;
end;

procedure TUIBFacade.CommitTransaction;
begin
  FCurrentTransaction.Commit;
end;

procedure TUIBFacade.RollbackTransaction;
begin
  FCurrentTransaction.RollBack;
end;

function TUIBFacade.Execute(ASQL: string): Int64;
var
  Cmd: TUIBStatement;
begin
  Cmd := NewStatement;
  try
    Cmd.SQL.Text := ASQL;
    Cmd.Execute;
    Result := Cmd.RowsAffected;
  finally
    Cmd.Free;
  end;
end;

function TUIBFacade.Prepare(ASQL: string): TUIBQuery;
var
  Cmd: TUIBQuery;
begin
  Cmd := NewQuery;
  try
    Cmd.FetchBlobs := True;
    Cmd.SQL.Text := ASQL;
    Cmd.Prepare;
  except
    FreeAndNil(Cmd);
    raise;
  end;
  Result := Cmd;
end;

constructor TUIBFacade.Create(const LibraryName: string;
  AUserName, APassword, AConnectionString, ACharSet: string);
begin
  inherited Create;
  FLibraryName := LibraryName;
  FDatabaseConnectionString := AConnectionString;
  FUsername := AUserName;
  FPassword := APassword;
  FCharSet := ACharSet;
end;

destructor TUIBFacade.Destroy;
begin
  if assigned(FUIBDatabase) then
  begin
    if assigned(FCurrentTransaction) and (FCurrentTransaction.InTransaction) then
      FCurrentTransaction.RollBack;

    FUIBDatabase.Connected := False;
    FCurrentTransaction.Free;
    FUIBDatabase.Free;
  end;
  inherited;
end;

function TUIBFacade.Execute(ASQLCommand: TUIBStatement): Int64;
begin
  ASQLCommand.OnError := TEndTransMode.etmStayIn; // always!!!
  ASQLCommand.Execute;
  Result := ASQLCommand.RowsAffected;
end;

function TUIBFacade.ExecuteQuery(ASQLCommand: TUIBQuery): TUIBQuery;
begin
  raise EdormException.Create('Not implemented');
end;

function TUIBFacade.GetCharsetFromString(const Charset: String): TCharacterSet;
begin
  if (Charset = '') or (Charset = 'utf8') then
    Exit(csUTF8);
  if Charset = 'none' then
    Exit(csNONE);
  if Charset = 'ascii' then
    Exit(csASCII);
  if Charset = 'utf8' then
    Exit(csUTF8);
  if Charset = 'iso8859_1' then
    Exit(csISO8859_1);
  if Charset = 'iso8859_2' then
    Exit(csISO8859_2);
  if Charset = 'win1250' then
    Exit(csWIN1250);
  if Charset = 'win1251' then
    Exit(csWIN1251);
  if Charset = 'win1252' then
    Exit(csWIN1252);
  if Charset = 'win1253' then
    Exit(csWIN1253);
  if Charset = 'win1254' then
    Exit(csWIN1254);
  raise EdormException.Create('Invalid charset ' + Charset);
end;

function TUIBFacade.GetConnection: TUIBDatabase;
begin
  if FUIBDatabase = nil then
  begin
    FUIBDatabase := TUIBDatabase.Create(nil);
    FUIBDatabase.LibraryName := FLibraryName;
    FUIBDatabase.DatabaseName := FDatabaseConnectionString;
    FUIBDatabase.username := FUsername;
    FUIBDatabase.password := FPassword;
    FUIBDatabase.CharacterSet := GetCharsetFromString(FCharSet); // always unicode
    FUIBDatabase.Connected := True;
    FCurrentTransaction := TUIBTransaction.Create(nil);
    // daniele 30/08/2013
    FCurrentTransaction.Options := FCurrentTransaction.Options + [tpWait];
    FCurrentTransaction.DataBase := GetConnection;
  end;
  Result := FUIBDatabase;
end;

function TUIBFacade.GetCurrentTransaction: TUIBTransaction;
begin
  Result := FCurrentTransaction
end;

function TUIBFacade.NewStatement: TUIBStatement;
begin
  Result := TUIBStatement.Create(nil);
  Result.DataBase := GetConnection;
  Result.Transaction := FCurrentTransaction;
  Result.OnError := TEndTransMode.etmStayIn;
end;

function TUIBFacade.NewQuery: TUIBQuery;
begin
  Result := TUIBQuery.Create(nil);
  Result.DataBase := GetConnection;
  Result.Transaction := FCurrentTransaction;
  Result.OnError := TEndTransMode.etmStayIn;
end;

end.
