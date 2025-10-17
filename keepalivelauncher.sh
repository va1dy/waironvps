#!/bin/bash

SCRIPT="keepalive.js"

while true
do
    echo "Запуск скрипта..."
    node "$SCRIPT"
    
    echo "Скрипт завершился. Перезапускаем через 5 секунд..."
    sleep 5
done
