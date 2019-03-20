# Kompilator, JFTT 2018/2019
Politechnika Wrocławska, Wydział Podstawowych Problemów Techniki
Kurs Języków formalnych i technik translacji pod kierunkiem [dr. Macieja Gębali](http://ki.pwr.edu.pl/gebala/).

Kompilator prostego języka imperatywnego do kodu maszyn rejestrowej.
Autor: Klaudia Głocka
Nr indeksu: 221525

## Zawartość projektu
- README
- Makefile
- pliki kompilatora

## Wykorzystane narzędzia
|  | Wersja |
| ------ | ------ |
| gcc | 5.4.0 |
| flex | 2.6.0 |
| bison | 3.0.4 |
| make | 4.1 |

# Sposób użycia
W celu skompilowania programu należy użyć polecenia:
```sh
$ make
```
Wywołanie programu powinno wyglądać następująco:
```sh
$ kompilator <nazwa pliku wejściowego> <nazwa pliku wyjściowego>
```
