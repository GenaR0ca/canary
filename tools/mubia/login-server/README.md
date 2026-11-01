# login-server de Mubia (crear personajes)

El cliente crea personajes con el pedido HTTP `createcharacter` al login-server
(`C:\Mubia\login\login-server.exe`). Esa funcion no existe en el login-server original,
asi que usamos uno compilado con este parche.

- Base: https://github.com/opentibiabr/login-server commit `2612930de4d97123a397f8f2cd0d5f784094af40`
  (la misma version que tenia instalada Mubia).
- Parche: `0001-mubia-createcharacter.patch`.
- Reglas: maximo 5 personajes por cuenta; nombre de 3 a 20 letras, hasta 3 palabras;
  el personaje nuevo copia al `<Clase> Sample` de su vocacion (nivel 1, en el templo).
  Las stats iniciales las pone el servidor al primer login (Mubia.initPlayer).

## Compilar (Linux o Windows con Go 1.24)

```
git clone https://github.com/opentibiabr/login-server.git
cd login-server
git checkout 2612930de4d97123a397f8f2cd0d5f784094af40
git am ../0001-mubia-createcharacter.patch
cd src
GOOS=windows GOARCH=amd64 CGO_ENABLED=0 go build -trimpath -o login-server.exe .
```
