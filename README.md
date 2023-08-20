# Purpose
A program for playing games with team answers via telegram, like quiz games in a sport format. 
The moderator asks questions and in the allotted time (~ 1 minute) the teams hand over the answers. The answers are given via a telegram bot. The bot token is set in the settings. 
You can additionally keep a log of responses in the telegram, which is sent to the administrator. The administrator chat ID is set via /bind command sent to the bot.
The moderator determines the correct answers and can keep track of the series of games in a separate tab.
 
There are two options: 33 questions in the tournament, divided into 3 rounds or 30 questions in 3 rounds. 

You can select that every n-th question in the rounds will be with bet. 
The number of a question in a round is specifying in the options also. 0 means that there are no such questions.  

The functionality of the scoreboard tables is mainly designed for convenient maintenance and scoring and convenient display on the scoreboard monitor when working with two screens.

Dependencies:
* Using a ready-made timer frame from the project https://github.com/Al-Muhandis/ChGK_Timer
* Ready-made set of tables is used for accounting and game management https://github.com/Al-Muhandis/tournament
* Library is used for telegram bots https://github.com/Al-Muhandis/fp-telegram
* To play audio tracks: playwavepackage package.
* Database Zeos: zcomponent
* RX sets of DB components: rxnew, rx_sort_zeos, rz_dbgrid_export_spreadsheet
* Task worker thread: https://github.com/Al-Muhandis/taskworker/

# Назначение
Программа для ведения игр с ответами команд через телеграм, наподобии игр ЧтоГдеКогда в спортивном формате. 
Ведущий задает вопросы и за отведенное время (~1 минута) команды сдают ответы. Ответы сдаются через телеграм бот. Токен бота прописывается в настройках. 
Можно вести дополнительно журнал ответов в телеграм, который отправляется администратору. Чат администратора задается с помощью команды /bind, отправленной боту.
Ведущий определяет правильные ответы и может вести счет серий игр в отдельной вкладке. 

Есть две опции: 33 вопроса в турнире, разделенные на 3 раунда, или 30 вопросов на 3 раунда. 

Вы можете выбрать, что каждый n-й вопрос в раундах будет со ставкой. 
Номер вопроса n в раунде также указывается в настройках. 0 означает, что таких вопросов нет.

Зависимости:
* Используется готовый фрейм таймера из проекта https://github.com/Al-Muhandis/ChGK_Timer
* Используется готовый набор таблиц для учета и ведения игр https://github.com/Al-Muhandis/tournament
* Используется фреймворк для телеграм ботов https://github.com/Al-Muhandis/fp-telegram
* Для кроссплатформенного воспроизведения звуков: playwavepackage.
* База данных Zeos: zcomponent
* RX наборы компонентов БД: rxnew, rx_sort_zeos, rz_dbgrid_export_spreadsheet
* Task worker thread: https://github.com/Al-Muhandis/taskworker/