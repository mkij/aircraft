# Aircraft

2D side-scrolling aerial shooter zbudowany w **Godot 4.6**.

Gracz pilotuje samolot, który porusza się w dowolnym kierunku na zasadzie obrotu i stałej prędkości do przodu (jak pojazd ze stałym napędem). Na ekranie pojawiają się wrogie samoloty — proste, lecące z prawej na lewą, oraz zaawansowane z AI reagującą na poczynania gracza.

## Wymagania

- [Godot Engine 4.6](https://godotengine.org/) (wersja Mobile renderer)
- Windows (projekt skonfigurowany pod DirectX 12 / D3D12)

## Uruchomienie

1. Otwórz folder projektu w Godot Editor.
2. Scena główna to `Main.tscn` — uruchom ją klawiszem `F5` lub przyciskiem **Play**.

## Sterowanie

| Klawisz | Akcja |
|---|---|
| `←` / `↑` | Obróć samolot w lewo (pod górkę) |
| `→` / `↓` | Obróć samolot w prawo (w dół) |
| `Spacja` | Strzał (kula ze względem na prędkość samolotu) |
| `Ctrl` | Zrzut bomby |
| `Spacja` (Game Over) | Restart gry |

## Rozgrywka

- Samolot zawsze leci do przodu w kierunku obrotu — nie można się zatrzymać.
- Gracz ma **3 punkty życia (HP)**. Kontakt z wrogiem lub jego kulą zadaje 1 dmg.
- Wrogowie pojawiają się co 3 sekundy z prawej strony ekranu.
- Zniszczenie wroga daje punkty (scout: 10, fighter: 30, heavy: 60).
- Wylot poza górną lub dolną krawędź ekranu powoduje chwilowe zniknięcie i powrót po 1 sekundzie.
- Lądowanie (dolna krawędź, tryb `ground`) kończy grę.
- Na ekranie widoczna jest złota linia predykcji trajektorii kuli.

## Struktura projektu

Szczegółowy opis każdego pliku i systemów gry: [`ARCHITECTURE.md`](ARCHITECTURE.md)
