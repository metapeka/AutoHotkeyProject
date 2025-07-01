#Requires AutoHotkey v2.0
; CommandHandler.ahk - Обработчик команд для WordProcessor
; Кодировка: UTF-8 with BOM
; Версия: 1.0.0

class CommandHandler {
    __New(WordProc, FileMan, Logger, Config, UI) {
        this.WordProc := WordProc
        this.FileMan := FileMan
        this.Logger := Logger
        this.Config := Config
        this.UI := UI
        
        this.CurrentState := Commands.STATE_IDLE
        this.Statistics := {
            wordsProcessed: 0,
            startTime: 0,
            lastProcessTime: 0
        }
        
        ; Карта обработчиков команд
        this.Handlers := Map(
            Commands.SHUTDOWN, ObjBindMethod(this, "HandleShutdown"),
            Commands.GET_STATUS, ObjBindMethod(this, "HandleGetStatus"),
            Commands.GET_INFO, ObjBindMethod(this, "HandleGetInfo"),
            Commands.PING, ObjBindMethod(this, "HandlePing"),
            Commands.START_PROCESSING, ObjBindMethod(this, "HandleStartProcessing"),
            Commands.STOP_PROCESSING, ObjBindMethod(this, "HandleStopProcessing"),
            Commands.PAUSE_RESUME, ObjBindMethod(this, "HandlePauseResume"),
            Commands.RESTORE_FILES, ObjBindMethod(this, "HandleRestoreFiles"),
            Commands.GET_STATS, ObjBindMethod(this, "HandleGetStats"),
            Commands.RELOAD_CONFIG, ObjBindMethod(this, "HandleReloadConfig"),
            Commands.SET_DELAY, ObjBindMethod(this, "HandleSetDelay")
        )
    }
    
    ; Выполнение команды
    Execute(Command) {
        ; Логируем команду
        this.Logger.Log("Получена команда: " . Command.command)
        
        ; Проверяем наличие обработчика
        if (!this.Handlers.Has(Command.command)) {
            return ResponseBuilder.Error(Command.id, "Команда не поддерживается")
        }
        
        ; Вызываем обработчик
        Handler := this.Handlers[Command.command]
        return Handler.Call(Command)
    }
    
    ; === Обработчики команд ===
    
    HandleShutdown(Command) {
        this.Logger.Log("Получена команда завершения работы")
        
        ; Останавливаем обработку если идет
        if (this.CurrentState = Commands.STATE_PROCESSING) {
            this.WordProc.StopProcessing()
        }
        
        ; Планируем выход
        SetTimer(() => ExitApp(), 100)
        
        return ResponseBuilder.Success(Command.id, "Скрипт будет завершен")
    }
    
    HandleGetStatus(Command) {
        Status := this.GetCurrentStatus()
        return ResponseBuilder.Success(Command.id, "", Status)
    }
    
    HandleGetInfo(Command) {
        Info := {
            name: "WordProcessor",
            version: "1.0.0",
            state: this.CurrentState,
            capabilities: [
                "process_words",
                "restore_files",
                "statistics"
            ]
        }
        
        return ResponseBuilder.Success(Command.id, "", Info)
    }
    
    HandlePing(Command) {
        return ResponseBuilder.Success(Command.id, "pong")
    }
    
    HandleStartProcessing(Command) {
        ; Проверяем состояние
        if (this.CurrentState = Commands.STATE_PROCESSING) {
            return ResponseBuilder.Error(Command.id, "Обработка уже запущена")
        }
        
        ; Получаем параметры
        LoopCount := Command.params.loopCount
        
        ; Запускаем обработку в отдельном потоке
        this.CurrentState := Commands.STATE_PROCESSING
        this.Statistics.startTime := A_TickCount
        
        SetTimer(() => this.RunProcessing(LoopCount), -10)
        
        return ResponseBuilder.Success(Command.id, "Обработка запущена")
    }
    
    HandleStopProcessing(Command) {
        if (this.CurrentState != Commands.STATE_PROCESSING) {
            return ResponseBuilder.Error(Command.id, "Обработка не запущена")
        }
        
        ; Останавливаем обработку
        this.WordProc.StopProcessing()
        this.CurrentState := Commands.STATE_IDLE
        
        return ResponseBuilder.Success(Command.id, "Обработка остановлена")
    }
    
    HandlePauseResume(Command) {
        if (this.CurrentState = Commands.STATE_PAUSED) {
            ; Возобновляем
            Pause(0)
            this.CurrentState := Commands.STATE_PROCESSING
            return ResponseBuilder.Success(Command.id, "Обработка возобновлена")
        } else if (this.CurrentState = Commands.STATE_PROCESSING) {
            ; Ставим на паузу
            Pause(1)
            this.CurrentState := Commands.STATE_PAUSED
            return ResponseBuilder.Success(Command.id, "Обработка приостановлена")
        } else {
            return ResponseBuilder.Error(Command.id, "Нечего ставить на паузу")
        }
    }
    
    HandleRestoreFiles(Command) {
        try {
            Success := this.WordProc.RestoreFiles()
            
            if (Success) {
                this.Logger.Log("Файлы восстановлены через IPC команду")
                return ResponseBuilder.Success(Command.id, "Файлы успешно восстановлены")
            } else {
                return ResponseBuilder.Error(Command.id, "Не удалось восстановить файлы")
            }
            
        } catch as e {
            return ResponseBuilder.Error(Command.id, "Ошибка: " . e.Message)
        }
    }
    
    HandleGetStats(Command) {
        ; Подсчитываем статистику
        WordsArray := this.FileMan.LoadArrayFromFile(this.FileMan.WordFile)
        UsedArray := this.FileMan.LoadArrayFromFile(this.FileMan.UsedWordsFile)
        
        Stats := {
            wordsProcessed: UsedArray.Length,
            wordsRemaining: WordsArray.Length,
            totalWords: WordsArray.Length + UsedArray.Length,
            runTime: this.CurrentState = Commands.STATE_IDLE ? 0 : Round((A_TickCount - this.Statistics.startTime) / 1000)
        }
        
        return ResponseBuilder.Success(Command.id, "", {stats: Stats})
    }
    
    HandleReloadConfig(Command) {
        try {
            this.Config.LoadSettings()
            this.Logger.Log("Конфигурация перезагружена через IPC")
            return ResponseBuilder.Success(Command.id, "Конфигурация перезагружена")
        } catch as e {
            return ResponseBuilder.Error(Command.id, "Ошибка перезагрузки: " . e.Message)
        }
    }
    
    HandleSetDelay(Command) {
        try {
            MinDelay := Command.params.minDelay
            MaxDelay := Command.params.maxDelay
            
            this.Config.SaveSetting("Delays", "MinDelay", MinDelay)
            this.Config.SaveSetting("Delays", "MaxDelay", MaxDelay)
            
            return ResponseBuilder.Success(Command.id, "Задержки обновлены")
        } catch as e {
            return ResponseBuilder.Error(Command.id, "Ошибка: " . e.Message)
        }
    }
    
    ; === Вспомогательные методы ===
    
    RunProcessing(LoopCount) {
        ; Запускаем обработку
        this.WordProc.ProcessWords(LoopCount)
        
        ; После завершения
        this.CurrentState := Commands.STATE_IDLE
        
        ; Отправляем статус завершения
        if (IsObject(StatusReporterObj)) {
            StatusReporterObj.SendEvent("processing_completed", {
                wordsProcessed: this.Statistics.wordsProcessed
            })
        }
    }
    
    ; Получение текущего статуса
    GetCurrentStatus() {
        ; Подсчитываем статистику
        WordsArray := this.FileMan.LoadArrayFromFile(this.FileMan.WordFile)
        UsedArray := this.FileMan.LoadArrayFromFile(this.FileMan.UsedWordsFile)
        
        return {
            state: this.CurrentState,
            wordsRemaining: WordsArray.Length,
            wordsProcessed: UsedArray.Length,
            totalWords: WordsArray.Length + UsedArray.Length,
            runTime: this.CurrentState = Commands.STATE_IDLE ? 0 : Round((A_TickCount - this.Statistics.startTime) / 1000)
        }
    }
}