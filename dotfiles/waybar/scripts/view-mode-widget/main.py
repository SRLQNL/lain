import subprocess
active_window_info = str(subprocess.check_output(['hyprctl', 'activewindow']))
is_fullscreen = int(active_window_info.split('fullscreen: ')[1][0])
is_pseudo = int(active_window_info.split('pseudo: ')[1][0])
is_float = int(active_window_info.split('floating: ')[1][0])
if is_fullscreen == 1:
    print("fullscreen view")
if is_pseudo == 1:
    print("pseudo view")
if is_float == 1:
    print("floating view")
