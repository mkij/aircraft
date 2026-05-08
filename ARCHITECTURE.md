# Architektura projektu Aircraft

## Przegląd

Projekt to klasyczna gra 2D zbudowana na scenie `Main.tscn`. Wszystkie obiekty dynamiczne (wrogowie, pociski, bomby) są tworzone przez skrypty jako instancje scen i dodawane bezpośrednio do `Main` jako dzieci. Kamera jest przyczepiona do gracza i śledzi jego ruch w poziomie.

---

## Hierarchia scen

```
Main.tscn  (main.gd)
├── Background  (background.gd)
├── Player  [instancja Player.tscn]  (player.gd)
│   └── Camera2D
├── EnemySpawner  [Timer, 3s]
└── CanvasLayer
    ├── ScoreLabel
    ├── HPLabel
    └── GameOverLabel
```

Wrogowie, pociski i bomby są dodawane dynamicznie do `Main` w trakcie gry.

---

## Pliki skryptów

### `main.gd` — kontroler gry

Dołączony do węzła `Main` (Node2D). Pełni rolę magistrali komunikacyjnej — inne obiekty wywołują jego metody zamiast bezpośrednio dotykać UI.

| Metoda | Opis |
|---|---|
| `_on_spawn_timer()` | Co 3s tworzy instancję `Enemy.tscn` w losowej pozycji Y po prawej stronie (x=1150) |
| `add_score(points)` | Aktualizuje wynik i etykietę `ScoreLabel` |
| `update_hp(hp)` | Aktualizuje etykietę `HPLabel` |
| `game_over()` | Pauzuje drzewo sceny, pokazuje `GameOverLabel` |
| `_input(event)` | Restart (Spacja) gdy gra jest zapauzowana |

---

### `player.gd` — gracz

Typ węzła: `CharacterBody2D`. Gracz zawsze porusza się do przodu z prędkością `FORWARD_SPEED = 280` — obrót steruje kierunkiem lotu.

**Ważne stałe:**

| Stała | Wartość | Opis |
|---|---|---|
| `FORWARD_SPEED` | 280 | Prędkość lotu |
| `TURN_SPEED` | 2.2 rad/s | Szybkość obrotu |
| `GRAVITY` | 280 | Grawitacja kul (do predykcji trajektorii) |
| `SHOOT_COOLDOWN` | 0.08s | Minimalny odstęp między strzałami |
| `BOMB_COOLDOWN` | 1.0s | Minimalny odstęp między bombami |
| `REENTRY_DELAY` | 1.0s | Czas niewidoczności po wyjściu poza ekran |

**Systemy:**
- **Obrót**: `←/↑` zmniejsza rotację, `→/↓` zwiększa.
- **Granice mapy**: Wyjście górą/dołem → `offscreen = true` → po `REENTRY_DELAY` powrót w bezpiecznym kącie. Wyjście dołem w trybie `map_type == "ground"` → `game_over()`.
- **Strzał** (`shoot()`): Tworzy `Bullet.tscn`, dodaje losowy rozrzut ±0.03 rad, przekazuje prędkość samolotu (fizyka balistyczna).
- **Bomba** (`drop_bomb()`): Tworzy `Bomb.tscn` z bieżącą prędkością samolotu.
- **Predykcja trajektorii** (`_draw()`, `_calculate_trajectory()`): Symuluje 60 kroków lotu kuli (dt=0.05s) i rysuje złotą linię na ekranie.
- **Obrażenia** (`take_damage()`): Odejmuje 1 HP; przy 0 HP wywołuje `game_over()` na rodzicu.

---

### `background.gd` — tło

Typ węzła: `Node2D` (z_index = -10). Rysuje tło proceduralnie w każdej klatce.

- Niebo: niebieski prostokąt od `SKY_TOP=40` w górę.
- Ziemia: zielony prostokąt poniżej `GROUND_Y=580`.
- 15 chmur (losowe pozycje, rozmiary). Śledzą X pozycję gracza — gdy chmura wyjdzie poza lewy ekran, teleportuje się za prawy.
- Brak sprite'ów — całość rysowana przez `draw_rect()`.

---

### `base_enemy.gd` — bazowa klasa wrogów

Typ węzła: `Area2D`. Klasa bazowa dla zaawansowanych wrogów (dziedzicząca przez GDScript `extends "res://base_enemy.gd"`).

| Metoda | Opis |
|---|---|
| `take_hit()` | Odejmuje 1 HP, przy 0 wywołuje `die()` |
| `die()` | Dodaje punkty do `Main`, usuwa węzeł |
| `find_player()` | Szuka gracza przez grupę `"player"` |
| `_on_area_entered(area)` | Reaguje na wejście obiektu z grupy `player_bullet` |

---

### `enemy.gd` — prosty wróg

Typ węzła: `Area2D` (dziedziczy bezpośrednio, nie z `base_enemy.gd`). Używany przez `Enemy.tscn` — spawner w `Main` tworzy tylko ten typ.

Trzy warianty konfigurowane przez `setup(type)`:

| Typ | Prędkość | HP | Punkty | Skala |
|---|---|---|---|---|
| `scout` | 350 | 1 | 10 | 0.8× |
| `fighter` | 200 | 3 | 30 | 1.0× |
| `heavy` | 120 | 6 | 60 | 1.4× |

Leci w lewo ze stałą prędkością, usuwa się gdy `position.x < -100`.

---

### `enemy_fighter.gd` — wróg z AI

Typ węzła: `Area2D` (dziedziczy z `base_enemy.gd`). Zaawansowany przeciwnik z maszyną stanów i systemem osobowości.

**Stany (enum State):**

| Stan | Zachowanie |
|---|---|
| `PATROL` | Leci do przodu; przechodzi do ATTACK gdy gracz w zasięgu 600 |
| `ATTACK` | Kieruje dziób na gracza, strzela gdy kąt < 0.7 rad i dystans < 320 |
| `FLINCH` | Po trafieniu: ucieka w bok ze zwiększoną prędkością (300) przez ~0.6s |
| `EVADE` | Po 2 trafieniach: obraca się spiralnie przez ~1.8s |
| `REPOSITION` | Stara się znaleźć za graczem (x+200); po czasie wraca do ATTACK |
| `DESPERATE` | Last stand AGGRESSIVE: szarżuje na gracza, strzela 2× szybciej |
| `ESCAPE` | Last stand CAUTIOUS: ucieka od gracza z prędkością 320 |
| `LAST_LOOP` | Last stand: wykonuje pętlę (szybka rotacja) przez 3s, potem DESPERATE |

**Osobowości (enum Personality)** — losowane przy spawnie:

| Osobowość | Last stand pool |
|---|---|
| `AGGRESSIVE` | DESPERATE, DESPERATE, LAST_LOOP |
| `CAUTIOUS` | ESCAPE, ESCAPE, LAST_LOOP |
| `BALANCED` | DESPERATE, ESCAPE, LAST_LOOP |

Reaguje na trafienia przez `take_hit()` (nadpisuje bazową) — pierwsze trafienie → FLINCH 0.6s, drugie → FLINCH 0.4s, trzecie → last stand.

Strzela przez `_shoot()` tworząc `EnemyBullet.tscn` z losowym rozrzutem ±0.04 rad.

---

### `bullet.gd` — kula gracza

Typ węzła: `Area2D`, grupa: `"player_bullet"`.

- Prędkość = kierunek × 800 + prędkość_samolotu (balistyka).
- Poddaje się grawitacji (280 px/s²) — tor lotu jest paraboliczny.
- Obraca się zgodnie z kierunkiem lotu (`rotation = velocity.angle()`).
- Znika po wyjściu poza ekran lub po kolizji z wrogiem.

---

### `bomb.gd` — bomba gracza (wariant 1)

Typ węzła: `Area2D`.

- Dziedziczy pełną prędkość samolotu (x i y).
- Grawitacja = 350 px/s².
- Przy kolizji (`explode()`): niszczy wszystkich wrogów w promieniu 80 px, dodaje punkty za każdego, usuwa się.

---

### `enemy_bullet.gd` — kula wroga

Typ węzła: `Area2D`.

- Prędkość stała = 500 px/s w kierunku wystrzelenia, brak grawitacji.
- Przy kolizji z ciałem (`body_entered`): wywołuje `take_damage()` na trafionym obiekcie.

---

## Komunikacja między systemami

```
EnemySpawner (Timer) ──────────────────────> Main._on_spawn_timer()
                                                    │
                                              Enemy.tscn (instance)
                                                    │
Enemy._on_area_entered(area) <─── player_bullet group (Bullet)
Enemy._on_body_entered(body) <─── CharacterBody2D (Player)
        │
        └──> Main.add_score(points)

Player.take_damage() ◄──── EnemyBullet._on_body_entered()
Player.take_damage() ◄──── Enemy._on_body_entered()
        │
        └──> Main.update_hp(hp)
        └──> Main.game_over()  (przy hp <= 0)

Player.shoot() ──────────────> Bullet.tscn (add_child do Main)
Player.drop_bomb() ──────────> Bomb.tscn   (add_child do Main)
EnemyFighter._shoot() ───────> EnemyBullet.tscn (add_child do Main)
```

---

## Grupy Godot

| Grupa | Kto należy | Do czego służy |
|---|---|---|
| `"player"` | Player | `background.gd` i `enemy_fighter.gd` szukają gracza |
| `"enemies"` | Enemy, EnemyFighter | `bomb.gd` szuka celów eksplozji |
| `"player_bullet"` | Bullet | `base_enemy.gd` rozpoznaje co go trafia |
