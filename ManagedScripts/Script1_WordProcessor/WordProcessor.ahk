#Requires AutoHotkey v2.0
; WordProcessor.ahk - Основной класс обработчика слов
; Кодировка: UTF-8 with BOM
; Версия: 1.0.0

#Include "..\..\Shared\IPCProtocol.ahk"
#Include "..\..\Shared\CommandDefinitions.ahk"
#Include "Logger.ahk"
#Include "ConfigManager.ahk"
#Include "FileManager.ahk"
#Include "HotkeyManager.ahk"

class WordProcessor {
    __New() {
        this.IsRunning := false
        this.IsPaused := false
        this.Logger := Logger()
        this.Config := ConfigManager()
        this.FileMan := FileManager()
        this.HotkeyMan := HotkeyManager()
        this.IPCWindow := ""
        
        this.Logger.Log("WordProcessor инициализирован")
    }
    
    ; Инициализация IPC
    InitializeIPC() {
        try {
            ; Создаем IPC окно
            this.IPCWindow := IPCProtocol.CreateIPCWindow("IPC_WordProcessor")
            
            ; Устанавливаем обработчик сообщений
            OnMessage(IPCProtocol.WM_COPYDATA, (wParam, lParam, msg, hwnd) => this.OnIPCMessage(wParam, lParam, msg, hwnd))
            
            this.Logger.Log("IPC инициализирован")
            
        } catch as e {
            this.Logger.Error("Ошибка инициализации IPC: " . e.Message)
        }
    }
    
    ; Запуск WordProcessor
    Start() {
        try {
            this.IsRunning := true
            
            ; Загружаем конфигурацию
            this.Config.LoadConfig()
            
            ; Инициализируем горячие клавиши
            this.HotkeyMan.Initialize()
            
            this.Logger.Log("WordProcessor запущен")
            
            ; Основной цикл
            while (this.IsRunning) {
                Sleep(100)
                
                ; Проверяем состояние
                if (!this.IsPaused) {
                    ; Здесь может быть логика обработки
                }
            }
            
        } catch as e {
            this.Logger.Error("Ошибка запуска: " . e.Message)
        }
    }
    
    ; Остановка WordProcessor
    Stop() {
        this.IsRunning := false
        this.HotkeyMan.Cleanup()
        this.Logger.Log("WordProcessor остановлен")
        ExitApp()
    }
    
    ; Переключение паузы
    TogglePause() {
        this.IsPaused := !this.IsPaused
        Status := this.IsPaused ? "приостановлен" : "возобновлен"
        this.Logger.Log("WordProcessor " . Status)
    }
    
    ; Получение статуса
    GetStatus() {
        return {
            running: this.IsRunning,
            paused: this.IsPaused,
            version: "1.0.0",
            uptime: A_TickCount
        }
    }
    
    ; Обработчик IPC сообщений
    OnIPCMessage(wParam, lParam, msg, hwnd) {
        try {
            ; Получаем данные
            Result := IPCProtocol.ReceiveData(wParam, lParam)
            
            if (Result.Success) {
                this.ProcessCommand(Result.Data)
            } else {
                this.Logger.Error("Ошибка получения IPC данных: " . Result.Error)
            }
            
        } catch as e {
            this.Logger.Error("Ошибка обработки IPC: " . e.Message)
        }
        
        return 1  ; Сообщение обработано
    }
    
    ; Обработка команд
    ProcessCommand(CommandObj) {
        try {
            this.Logger.Log("Получена команда: " . CommandObj.command)
            
            switch CommandObj.command {
                case CommandDefinitions.SHUTDOWN:
                    this.Stop()
                    
                case CommandDefinitions.GET_STATUS:
                    Status := this.GetStatus()
                    this.Logger.Log("Отправлен статус")
                    
                case CommandDefinitions.TOGGLE_PAUSE:
                    this.TogglePause()
                    
                case CommandDefinitions.START_PROCESSING:
                    this.StartProcessing()
                    
                case CommandDefinitions.RESTORE_FILES:
                    this.RestoreFiles()
                    
                default:
                    this.Logger.Log("Неизвестная команда: " . CommandObj.command)
            }
            
        } catch as e {
            this.Logger.Error("Ошибка обработки команды: " . e.Message)
        }
    }
    
    ; Начать обработку
    StartProcessing() {
        this.Logger.Log("Начата обработка")
        ; Здесь логика обработки
    }
    
    ; Восстановить файлы
    RestoreFiles() {
        this.Logger.Log("Восстановление файлов")
        ; Здесь логика восстановления
    }
}