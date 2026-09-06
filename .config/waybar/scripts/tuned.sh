#!/usr/bin/env bash

case "$1" in
    "toggle")
        CURRENT=$(tuned-adm active | awk '{print $NF}')
        if [ "$CURRENT" = "powersave" ]; then
            tuned-adm profile balanced
        elif [ "$CURRENT" = "balanced" ]; then
            tuned-adm profile throughput-performance
        else
            tuned-adm profile powersave
        fi
        ;;
    *)
        PROFILE=$(tuned-adm active | awk '{print $NF}')
        case "$PROFILE" in
            "powersave")
                echo '{"text": "", "tooltip": "Perfil: powersave (Ahorro)", "class": "powersave"}'
                ;;
            "throughput-performance"|"latency-performance")
                echo '{"text": "", "tooltip": "Perfil: rendimiento", "class": "performance"}'
                ;;
            *)
                echo '{"text": "", "tooltip": "Perfil: balanced (Equilibrado)", "class": "balanced"}'
                ;;
        esac
        ;;
esac
