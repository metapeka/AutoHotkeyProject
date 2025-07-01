#Requires AutoHotkey v2.0
; JSONHelper.ahk - Помощник для работы с JSON
; Кодировка: UTF-8 with BOM
; Версия: 1.0.0

class JSONHelper {
    ; Преобразование объекта в JSON строку
    static Stringify(obj) {
        if (obj == "") {
            return '""'
        }
        
        if (IsNumber(obj)) {
            return String(obj)
        }
        
        if (Type(obj) == "String") {
            return '"' . JSONHelper.EscapeString(obj) . '"'
        }
        
        if (Type(obj) == "Array") {
            result := "["
            for index, value in obj {
                if (index > 1) {
                    result .= ","
                }
                result .= JSONHelper.Stringify(value)
            }
            result .= "]"
            return result
        }
        
        if (Type(obj) == "Object" || Type(obj) == "Map") {
            result := "{"
            first := true
            
            if (Type(obj) == "Map") {
                for key, value in obj {
                    if (!first) {
                        result .= ","
                    }
                    result .= '"' . JSONHelper.EscapeString(String(key)) . '":' . JSONHelper.Stringify(value)
                    first := false
                }
            } else {
                for key, value in obj.OwnProps() {
                    if (!first) {
                        result .= ","
                    }
                    result .= '"' . JSONHelper.EscapeString(String(key)) . '":' . JSONHelper.Stringify(value)
                    first := false
                }
            }
            
            result .= "}"
            return result
        }
        
        return "null"
    }
    
    ; Парсинг JSON строки в объект
    static Parse(jsonStr) {
        ; Простой парсер JSON
        ; Удаляем пробелы в начале и конце
        jsonStr := Trim(jsonStr)
        
        if (jsonStr == "") {
            return ""
        }
        
        ; Проверяем тип данных
        firstChar := SubStr(jsonStr, 1, 1)
        
        if (firstChar == '"') {
            ; Строка
            return JSONHelper.ParseString(jsonStr)
        }
        
        if (firstChar == "{") {
            ; Объект
            return JSONHelper.ParseObject(jsonStr)
        }
        
        if (firstChar == "[") {
            ; Массив
            return JSONHelper.ParseArray(jsonStr)
        }
        
        if (IsNumber(jsonStr)) {
            ; Число
            return Number(jsonStr)
        }
        
        if (jsonStr == "true") {
            return true
        }
        
        if (jsonStr == "false") {
            return false
        }
        
        if (jsonStr == "null") {
            return ""
        }
        
        return jsonStr
    }
    
    ; Экранирование строки для JSON
    static EscapeString(str) {
        str := StrReplace(str, "\", "\\")
        str := StrReplace(str, '"', '\"')
        str := StrReplace(str, "`n", "\n")
        str := StrReplace(str, "`r", "\r")
        str := StrReplace(str, "`t", "\t")
        return str
    }
    
    ; Парсинг строки
    static ParseString(jsonStr) {
        if (StrLen(jsonStr) < 2) {
            return ""
        }
        
        ; Удаляем кавычки
        str := SubStr(jsonStr, 2, StrLen(jsonStr) - 2)
        
        ; Убираем экранирование
        str := StrReplace(str, "\\", "\")
        str := StrReplace(str, '\"', '"')
        str := StrReplace(str, "\n", "`n")
        str := StrReplace(str, "\r", "`r")
        str := StrReplace(str, "\t", "`t")
        
        return str
    }
    
    ; Парсинг объекта
    static ParseObject(jsonStr) {
        obj := {}
        
        ; Удаляем фигурные скобки
        content := Trim(SubStr(jsonStr, 2, StrLen(jsonStr) - 2))
        
        if (content == "") {
            return obj
        }
        
        ; Простой парсинг пар ключ-значение
        pairs := StrSplit(content, ",")
        
        for pair in pairs {
            pair := Trim(pair)
            colonPos := InStr(pair, ":")
            
            if (colonPos > 0) {
                key := Trim(SubStr(pair, 1, colonPos - 1))
                value := Trim(SubStr(pair, colonPos + 1))
                
                ; Удаляем кавычки с ключа
                if (SubStr(key, 1, 1) == '"' && SubStr(key, -1) == '"') {
                    key := SubStr(key, 2, StrLen(key) - 2)
                }
                
                obj.%key% := JSONHelper.Parse(value)
            }
        }
        
        return obj
    }
    
    ; Парсинг массива
    static ParseArray(jsonStr) {
        arr := []
        
        ; Удаляем квадратные скобки
        content := Trim(SubStr(jsonStr, 2, StrLen(jsonStr) - 2))
        
        if (content == "") {
            return arr
        }
        
        ; Простой парсинг элементов
        elements := StrSplit(content, ",")
        
        for element in elements {
            element := Trim(element)
            arr.Push(JSONHelper.Parse(element))
        }
        
        return arr
    }
}