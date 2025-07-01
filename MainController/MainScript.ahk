#Requires AutoHotkey v2.0
; MainScript.ahk - Главный скрипт контроллера
; Кодировка: UTF-8 with BOM
; Версия: 1.0.0

#Include "GUI_Manager.ahk"
#Include "ProcessManager.ahk"
#Include "StatusMonitor.ahk"
#Include "CommandSender.ahk"

; Глобальные переменные
global AppTitle := "AutoHotkey Script Manager v1.0"
global ProcessMan := ""
global StatusMon := ""
global CmdSender := ""
global GuiMan := ""

; Инициализация приложения
InitializeApp()

; Основной цикл
Loop {
    Sleep(100)
    
    ; Проверяем статус мониторинга
    if (StatusMon && StatusMon.IsRunning) {
        StatusMon.CheckStatus()
    }
    
    ; Проверяем команды
    if (CmdSender) {
        CmdSender.ProcessTimeouts()
    }
}

; Функция инициализации
InitializeApp() {
    try {
        ; Создаем менеджеры
        ProcessMan := ProcessManager()
        StatusMon := StatusMonitor()
        CmdSender := CommandSender()
        
        ; Создаем GUI
        GuiMan := GUIManager(ProcessMan, StatusMon, CmdSender)
        GuiMan.CreateGUI()
        
        ; Запускаем мониторинг
        StatusMon.StartMonitoring()
        
        ; Показываем GUI
        GuiMan.ShowGUI()
        
    } catch as e {
        MsgBox("Ошибка инициализации: " . e.Message, "Ошибка", "Icon!")
        ExitApp()
    }
}

; Обработчик закрытия приложения
OnExit(ExitFunc)

ExitFunc(ExitReason, ExitCode) {
    ; Останавливаем мониторинг
    if (StatusMon && StatusMon.IsRunning) {
        StatusMon.StopMonitoring()
    }
    
    ; Останавливаем все скрипты
    if (ProcessMan) {
        ProcessMan.StopAllScripts()
    }
    
    return false  ; Разрешаем выход
}