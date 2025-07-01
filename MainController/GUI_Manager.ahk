#Requires AutoHotkey v2.0
; GUI_Manager.ahk - Менеджер графического интерфейса
; Кодировка: UTF-8 with BOM
; Версия: 1.0.0

class GUIManager {
    __New(ProcessManager, StatusMonitor, CommandSender) {
        this.ProcessMan := ProcessManager
        this.StatusMon := StatusMonitor
        this.CmdSender := CommandSender
        this.MainGUI := ""
        this.Controls := Map()
        
        ; Настройки скриптов
        this.Scripts := Map()
        this.Scripts["WordProcessor"] := {
            Name: "WordProcessor",
            Path: A_ScriptDir . "\..\ManagedScripts\Script1_WordProcessor\Main.ahk",
            Description: "Обработчик слов с горячими клавишами"
        }
    }
    
    CreateGUI() {
        ; Создаем главное окно
        this.MainGUI := Gui("+Resize", AppTitle)
        this.MainGUI.OnEvent("Close", (*) => ExitApp())
        
        ; Заголовок
        this.MainGUI.Add("Text", "x10 y10 w400 Center", "Менеджер AutoHotkey скриптов")
        
        ; Группа управления скриптами
        this.MainGUI.Add("GroupBox", "x10 y40 w400 h150", "Управление скриптами")
        
        ; Список скриптов
        this.Controls["ScriptList"] := this.MainGUI.Add("ListBox", "x20 y60 w200 h100")
        
        ; Заполняем список скриптов
        for ScriptName, ScriptInfo in this.Scripts {
            this.Controls["ScriptList"].Add([ScriptName . " - " . ScriptInfo.Description])
        }
        
        ; Кнопки управления
        this.Controls["StartBtn"] := this.MainGUI.Add("Button", "x230 y60 w100 h30", "Запустить")
        this.Controls["StartBtn"].OnEvent("Click", (*) => this.StartWordProcessor())
        
        this.Controls["StopBtn"] := this.MainGUI.Add("Button", "x230 y100 w100 h30", "Остановить")
        this.Controls["StopBtn"].OnEvent("Click", (*) => this.StopWordProcessor())
        
        this.Controls["PauseBtn"] := this.MainGUI.Add("Button", "x230 y140 w100 h30", "Пауза/Возобновить")
        this.Controls["PauseBtn"].OnEvent("Click", (*) => this.PauseResumeWordProcessor())
        
        ; Группа команд
        this.MainGUI.Add("GroupBox", "x10 y200 w400 h120", "Команды")
        
        this.Controls["ProcessBtn"] := this.MainGUI.Add("Button", "x20 y220 w100 h30", "Обработать")
        this.Controls["ProcessBtn"].OnEvent("Click", (*) => this.StartProcessing())
        
        this.Controls["RestoreBtn"] := this.MainGUI.Add("Button", "x130 y220 w100 h30", "Восстановить")
        this.Controls["RestoreBtn"].OnEvent("Click", (*) => this.RestoreFiles())
        
        this.Controls["RefreshBtn"] := this.MainGUI.Add("Button", "x240 y220 w100 h30", "Обновить статус")
        this.Controls["RefreshBtn"].OnEvent("Click", (*) => this.RefreshStatus())
        
        ; Статус
        this.MainGUI.Add("Text", "x20 y260 w100", "Статус:")
        this.Controls["StatusText"] := this.MainGUI.Add("Text", "x80 y260 w300", "Готов")
        
        ; Лог
        this.MainGUI.Add("GroupBox", "x10 y330 w400 h150", "Лог событий")
        this.Controls["LogEdit"] := this.MainGUI.Add("Edit", "x20 y350 w380 h120 ReadOnly VScroll")
        
        return this.MainGUI
    }
    
    ShowGUI() {
        if (this.MainGUI) {
            this.MainGUI.Show("w420 h490")
        }
    }
    
    ; Запуск WordProcessor
    StartWordProcessor() {
        try {
            ScriptInfo := this.Scripts["WordProcessor"]
            Result := this.ProcessMan.StartScript("WordProcessor", ScriptInfo.Path)
            
            if (Result.Success) {
                this.UpdateStatus("WordProcessor запущен (PID: " . Result.PID . ")")
                this.AddLog("Скрипт WordProcessor успешно запущен")
                
                ; Отправляем команду получения статуса
                CmdObj := {command: "GET_STATUS"}
                this.CmdSender.SendCommand("WordProcessor", CmdObj)
                
            } else {
                this.UpdateStatus("Ошибка: " . Result.Error)
                this.AddLog("Не удалось запустить скрипт. " . Result.Error)
            }
            
        } catch as e {
            this.UpdateStatus("Ошибка запуска: " . e.Message)
            this.AddLog("Ошибка: " . e.Message)
        }
    }
    
    ; Остановка WordProcessor
    StopWordProcessor() {
        try {
            Result := this.ProcessMan.StopScript("WordProcessor")
            
            if (Result.Success) {
                this.UpdateStatus("WordProcessor остановлен")
                this.AddLog("Скрипт WordProcessor остановлен")
            } else {
                this.UpdateStatus("Ошибка остановки: " . Result.Error)
                this.AddLog("Ошибка остановки: " . Result.Error)
            }
            
        } catch as e {
            this.UpdateStatus("Ошибка: " . e.Message)
            this.AddLog("Ошибка: " . e.Message)
        }
    }
    
    ; Пауза/Возобновление WordProcessor
    PauseResumeWordProcessor() {
        try {
            if (this.ProcessMan.IsScriptRunning("WordProcessor")) {
                CmdObj := {command: "TOGGLE_PAUSE"}
                this.CmdSender.SendCommand("WordProcessor", CmdObj)
                this.AddLog("Отправлена команда переключения паузы")
            } else {
                this.UpdateStatus("WordProcessor не запущен")
            }
        } catch as e {
            this.AddLog("Ошибка команды паузы: " . e.Message)
        }
    }
    
    ; Начать обработку
    StartProcessing() {
        try {
            if (this.ProcessMan.IsScriptRunning("WordProcessor")) {
                CmdObj := {command: "START_PROCESSING"}
                this.CmdSender.SendCommand("WordProcessor", CmdObj)
                this.AddLog("Отправлена команда начала обработки")
            } else {
                this.UpdateStatus("WordProcessor не запущен")
            }
        } catch as e {
            this.AddLog("Ошибка команды обработки: " . e.Message)
        }
    }
    
    ; Восстановить файлы
    RestoreFiles() {
        try {
            if (this.ProcessMan.IsScriptRunning("WordProcessor")) {
                CmdObj := {command: "RESTORE_FILES"}
                this.CmdSender.SendCommand("WordProcessor", CmdObj)
                this.AddLog("Отправлена команда восстановления файлов")
            } else {
                this.UpdateStatus("WordProcessor не запущен")
            }
        } catch as e {
            this.AddLog("Ошибка команды восстановления: " . e.Message)
        }
    }
    
    ; Обновить статус
    RefreshStatus() {
        try {
            if (this.ProcessMan.IsScriptRunning("WordProcessor")) {
                CmdObj := {command: "GET_STATUS"}
                this.CmdSender.SendCommand("WordProcessor", CmdObj)
                this.AddLog("Запрошен статус скрипта")
            } else {
                this.UpdateStatus("WordProcessor не запущен")
            }
        } catch as e {
            this.AddLog("Ошибка запроса статуса: " . e.Message)
        }
    }
    
    ; Обновление статуса
    UpdateStatus(StatusText) {
        if (this.Controls.Has("StatusText")) {
            this.Controls["StatusText"].Text := StatusText
        }
    }
    
    ; Добавление записи в лог
    AddLog(LogText) {
        if (this.Controls.Has("LogEdit")) {
            CurrentTime := FormatTime(A_Now, "HH:mm:ss")
            NewText := "[" . CurrentTime . "] " . LogText . "`r`n"
            this.Controls["LogEdit"].Text := this.Controls["LogEdit"].Text . NewText
            
            ; Прокручиваем вниз
            this.Controls["LogEdit"].Focus()
            Send("^{End}")
        }
    }
}