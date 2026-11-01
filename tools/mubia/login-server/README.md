# login-server de Mubia (crear personajes)

El cliente crea personajes con el pedido HTTP `createcharacter` al login-server
(`C:\Mubia\login\login-server.exe`). Esa funcion no existe en el login-server original,
asi que usamos uno compilado con este parche.

- Base: https://github.com/opentibiabr/login-server commit `2612930de4d97123a397f8f2cd0d5f784094af40`
  (la misma version que tenia instalada Mubia).
- Parche: `0001-mubia-createcharacter.patch`.
- Pedidos nuevos: `createcharacter` y `deletecharacter` (hay que escribir el nombre exacto).
- Reglas: maximo 5 personajes por cuenta; nombre de 3 a 20 caracteres (letras y numeros,
  empieza con letra, se respetan las mayusculas), hasta 3 palabras.
  El personaje nuevo copia al `<Clase> Sample` de su vocacion (nivel 1).
  Al primer login el servidor lo manda a la ciudad de su clase (Mubia.StartTown), le da los
  items iniciales (Mubia.StarterGear / Mubia.StarterAmmo) y las stats base (Mubia.initPlayer).
- Los nombres de las clases de la lista de personajes salen de este exe (o de VOCATIONS en .env).

## Compilar (Linux o Windows con Go 1.24)

```
git clone https://github.com/opentibiabr/login-server.git
cd login-server
git checkout 2612930de4d97123a397f8f2cd0d5f784094af40
git am ../0001-mubia-createcharacter.patch
cd src
GOOS=windows GOARCH=amd64 CGO_ENABLED=0 go build -trimpath -o login-server.exe .
```
