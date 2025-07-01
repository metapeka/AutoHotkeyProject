#Requires AutoHotkey v2.0
; Main.ahk - Главный файл WordProcessor
; Кодировка: UTF-8 with BOM
; Версия: 1.0.0

; Проверяем параметры запуска
if (A_Args.Length > 0 && A_Args[1] == "/IPC") {
    ; Запуск в режиме IPC
    #Include "WordProcessor.ahk"
    
    ; Создаем экземпляр WordProcessor
    global WP := WordProcessor()
    
    ; Инициализируем IPC
    WP.InitializeIPC()
    
    ; Запускаем основной цикл
    WP.Start()
    
} else {
    ; Обычный запуск
    MsgBox("WordProcessor должен запускаться через MainController", "Информация")
    ExitApp()
}