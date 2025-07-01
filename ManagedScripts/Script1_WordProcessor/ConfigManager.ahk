#Requires AutoHotkey v2.0
; ConfigManager.ahk - Менеджер конфигурации
; Кодировка: UTF-8 with BOM
; Версия: 1.0.0

class ConfigManager {
    __New() {
        this.ConfigFile := A_ScriptDir . "\settings.ini"
        this.Config := Map()
        this.LoadDefaultConfig()
    }
    
    LoadDefaultConfig() {
        ; Настройки по умолчанию
        this.Config["General"] := Map()
        this.Config["General"]["AutoStart"] := true
        this.Config["General"]["LogLevel"] := "INFO"
        
        this.Config["Hotkeys"] := Map()
        this.Config["Hotkeys"]["ProcessKey"] := "F1"
        this.Config["Hotkeys"]["RestoreKey"] := "F2"
    }
    
    LoadConfig() {
        try {
            if (FileExist(this.ConfigFile)) {
                ; Читаем настройки из файла
                ; Простая реализация чтения INI
                this.ReadINIFile()
            } else {
                ; Создаем файл с настройками по умолчанию
                this.SaveConfig()
            }
        } catch as e {
            ; Используем настройки по умолчанию
        }
    }
    
    SaveConfig() {
        try {
            ConfigText := ""
            
            for Section, Settings in this.Config {
                ConfigText .= "[" . Section . "]`n"
                
                for Key, Value in Settings {
                    ConfigText .= Key . "=" . String(Value) . "`n"
                }
                
                ConfigText .= "`n"
            }
            
            FileDelete(this.ConfigFile)
            FileAppend(ConfigText, this.ConfigFile, "UTF-8")
            
        } catch {
            ; Игнорируем ошибки сохранения
        }
    }
    
    GetValue(Section, Key, Default := "") {
        if (this.Config.Has(Section) && this.Config[Section].Has(Key)) {
            return this.Config[Section][Key]
        }
        return Default
    }
    
    SetValue(Section, Key, Value) {
        if (!this.Config.Has(Section)) {
            this.Config[Section] := Map()
        }
        this.Config[Section][Key] := Value
    }
    
    ReadINIFile() {
        ; Простое чтение INI файла
        Content := FileRead(this.ConfigFile, "UTF-8")
        Lines := StrSplit(Content, "`n")
        
        CurrentSection := ""
        
        for Line in Lines {
            Line := Trim(Line)
            
            if (Line == "" || SubStr(Line, 1, 1) == ";") {
                continue
            }
            
            if (SubStr(Line, 1, 1) == "[" && SubStr(Line, -1) == "]") {
                CurrentSection := SubStr(Line, 2, StrLen(Line) - 2)
                if (!this.Config.Has(CurrentSection)) {
                    this.Config[CurrentSection] := Map()
                }
                continue
            }
            
            if (CurrentSection != "" && InStr(Line, "=")) {
                EqualPos := InStr(Line, "=")
                Key := Trim(SubStr(Line, 1, EqualPos - 1))
                Value := Trim(SubStr(Line, EqualPos + 1))
                
                ; Преобразуем значения
                if (Value == "true") {
                    Value := true
                } else if (Value == "false") {
                    Value := false
                } else if (IsNumber(Value)) {
                    Value := Number(Value)
                }
                
                this.Config[CurrentSection][Key] := Value
            }
        }
    }
}