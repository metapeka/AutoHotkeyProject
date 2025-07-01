#Requires AutoHotkey v2.0
; IPCListener.ahk - Слушатель команд для WordProcessor
; Кодировка: UTF-8 with BOM
; Версия: 1.0.0

class IPCListener {
    __New(ScriptName := "WordProcessor") {
        this.ScriptName := ScriptName
        this.CommandHandler := {}
        this.StatusReporter := {}
        this.IPCWindow := {}
        this.IsListening := false
    }
    
    ; Инициализация слушателя
    Initialize(CommandHandler, StatusReporter) {
        this.CommandHandler := CommandHandler
        this.StatusReporter := StatusReporter
        
        ; Создаем IPC окно
        this.IPCWindow := IPCProtocol.CreateIPCWindow(
            this.ScriptName,
            ObjBindMethod(this, "OnMessage")
        )
        
        this.IsListening := true
        
        ; Отправляем начальный статус
        this.StatusReporter.SendStatus({
            state: Commands.STATE_IDLE,
            message: "Скрипт запущен и готов к работе"
        })
        
        return true
    }
    
    ; Обработчик входящих сообщений
    OnMessage(wParam, lParam, msg, hwnd) {
        ; Проверяем, что это наше окно
        if (hwnd != this.IPCWindow.Hwnd) {
            return
        }
        
        ; Получаем данные
        Result := IPCProtocol.ReceiveData(lParam)
        
        if (!Result.Success) {
            return
        }
        
        ; Обрабатываем в зависимости от типа
        switch Result.Marker {
            case IPCProtocol.MARKER_COMMAND:
                this.ProcessCommand(Result.Data, wParam)
                
            case IPCProtocol.MARKER_STATUS:
                ; Запрос статуса
                this.SendCurrentStatus(wParam)
        }
        
        return true
    }
    
    ; Обработка команды
    ProcessCommand(Command, SenderHwnd) {
        try {
            ; Валидация команды
            if (!CommandValidator.IsValidCommand(Command)) {
                Response := ResponseBuilder.Error(
                    Command.HasProp("id") ? Command.id : "unknown",
                    "Неизвестная команда: " . (Command.HasProp("command") ? Command.command : "")
                )
                this.SendResponse(SenderHwnd, Response)
                return
            }
            
            ; Валидация параметров
            ParamValidation := CommandValidator.ValidateParams(Command)
            if (!ParamValidation.Valid) {
                Response := ResponseBuilder.Error(Command.id, ParamValidation.Error)
                this.SendResponse(SenderHwnd, Response)
                return
            }
            
            ; Выполняем команду
            Result := this.CommandHandler.Execute(Command)
            
            ; Отправляем ответ
            this.SendResponse(SenderHwnd, Result)
            
        } catch as e {
            ; Отправляем ошибку
            Response := ResponseBuilder.Error(
                Command.HasProp("id") ? Command.id : "unknown",
                "Ошибка выполнения: " . e.Message
            )
            this.SendResponse(SenderHwnd, Response)
        }
    }
    
    ; Отправка ответа
    SendResponse(TargetHwnd, Response) {
        IPCProtocol.SendData(TargetHwnd, Response, IPCProtocol.MARKER_RESPONSE)
    }
    
    ; Отправка текущего статуса
    SendCurrentStatus(TargetHwnd) {
        Status := this.CommandHandler.GetCurrentStatus()
        this.StatusReporter.SendStatusTo(TargetHwnd, Status)
    }
    
    ; Остановка слушателя
    Stop() {
        this.IsListening := false
        
        if (this.IPCWindow) {
            this.IPCWindow.Destroy()
        }
    }
}