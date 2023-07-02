# jeopardy-game
 Своя игра в телеграм. 
 
Небольшая утилита, написанная за один вечер для Своей Игры с помощью телеграм. Бот постит вопросы в в группу или канал. Бот определяет первого нажавшего кнопку - сохраняет его в базе и сообщает в чате.

Поскольку используется webhook для работы телеграм бота, то сервер не нужен. Программа запускается на десктопной компьютере (поскольку написан на Lazarus, то кроссплатформенно, но тестировалось и собиралось под Windows)

Переименуйте default.sqlite3.template в default.sqlite3

Завимисости для сборки:

* fp-telegram - для работы телеграм бота
* rxnew, zcomponent (zeos) - DB aware для работы компонентов базы данных под SQLite3

----------------------------

Jeopardy game in telegram.

A small utility written in one evening for Jeopardy game using telegram. The bot posts questions to a group or channel. The bot detects the first gamer (telegram user) who pressed the button - saves it in the database and reports it in the chat.

Since the webhook is used for the operation of the telegram bot, the server is not needed. The program runs on a desktop computer (since it is written in Lazarus, it is cross-platform, but it was tested and built under Windows)

Rename default.sqlite3.template to default.sqlite3

Build Dependencies:

*  fp-telegram - for the work of a telegram bot
*  rx new, component (zeos) - DB aware for the operation of database components under SQLite3