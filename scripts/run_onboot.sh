# 如果 /scripts/scripts.d 目录不为空，则循环执行该目录下的脚本
run_onboot(){
    if [ -d /scripts/scripts.d ]; then
        for script in /scripts/scripts.d/*; do
            echo "Running $script"
            bash "$script"
        done
    fi
}