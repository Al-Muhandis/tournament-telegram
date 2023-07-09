unit sql_db;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils;

const
  _sql_players='CREATE TABLE IF NOT EXISTS players (id BIGINT PRIMARY KEY, title STRING (128), team  INTEGER);';
  _sql_answers='CREATE TABLE IF NOT EXISTS answers (id INTEGER PRIMARY KEY AUTOINCREMENT, '+
    'tournament INTEGER, question INTEGER, reply INTEGER, answer TEXT, sent TIME, user_id BIGINT);';

implementation

end.

