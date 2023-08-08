[//]: # (This is the configuration I used to have for my Lenovo laptop 2023)
[//]: # (Estos archivos están en dotfiles)

## Xorg touchpad y teclado

Xorg ya no crea archivos de configuración en `/etc/X11/xorg.conf.d/`pero sí crea templates en `/usr/share/X11/xorg.conf.d`.

Es necesario copiar esos archivos de configuración porque no nos vamos a quedar con la configuración default, vamos a aplicar nuestros propios cambios:
> `sudo cp -a /usr/share/X11/xorg.conf.d/. /etc/X11/xorg.conf.d/`

En la sección de keyboard añadir lo siguiente:
```bash
Option "XkbLayout" "us"
Option "XkbVariant" "intl"
```

En la sección de touchpad:
```bash
Option "Tapping" "on"
Option "NaturalScrolling" "true"
Option "TappingButtonMap" "lrm"
Option "DisableWhileTyping" "false"
```
