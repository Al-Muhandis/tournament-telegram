unit sql_db;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils;

const
  _sql_players='CREATE TABLE IF NOT EXISTS players (id BIGINT PRIMARY KEY, title STRING (128), team  INTEGER);';
  _sql_rounds='CREATE TABLE IF NOT EXISTS rounds (id INTEGER PRIMARY KEY AUTOINCREMENT, '+
    'question TEXT, reply INTEGER, answer TEXT, sent TIME, user_id BIGINT);';
  _sql_teams='CREATE TABLE IF NOT EXISTS teams (id INTEGER PRIMARY KEY AUTOINCREMENT, title STRING (128));';

implementation

end.

