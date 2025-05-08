import pygame
import sys
import threading
import winsound
import serial
import random

pygame.init()

fpga_serial = serial.Serial('COM4', 115200, timeout=0.01)  # Change COM port if needed

WIDTH, HEIGHT = 800, 600
FPS = 60
WHITE = (255, 255, 255)
BLACK = (0, 0, 0)
GREEN = (0, 255, 0)
RED = (255, 60, 60)
SHAKE_DURATION = 10

def beep():
    threading.Thread(target=lambda: winsound.Beep(1000, 100)).start()

screen = pygame.display.set_mode((WIDTH, HEIGHT))
pygame.display.set_caption("Bricks Deluxe")
clock = pygame.time.Clock()

font = pygame.font.SysFont("consolas", 30)
big_font = pygame.font.SysFont("consolas", 70)

player_name = ""
scoreboard = []

paddle = pygame.Rect(WIDTH // 2 - 60, HEIGHT - 30, 120, 15)
ball = pygame.Rect(WIDTH // 2 - 10, HEIGHT // 2, 20, 20)
ball_speed = [4, -4]
multi_balls = []
reverse_controls = False

powerups = []
POWER_TYPES = {
    'expand': GREEN,
    'multi': GREEN,
    'shrink': RED,
    'reverse': RED
}

BRICK_COLORS = [(255, 99, 71), (255, 140, 0), (255, 215, 0), (50, 205, 50), (0, 191, 255)]

def create_bricks(rows, cols):
    bricks = []
    bw, bh = WIDTH // cols, 30
    for r in range(rows):
        for c in range(cols):
            brick = pygame.Rect(c * bw + 2, r * bh + 2, bw - 4, bh - 4)
            typ = 'enemy' if random.random() < 0.1 else 'normal'
            bricks.append((brick, BRICK_COLORS[r % len(BRICK_COLORS)], typ, 255))
    return bricks

def draw_text(text, font, color, surface, x, y, center=True):
    render = font.render(text, True, color)
    rect = render.get_rect()
    if center:
        rect.center = (x, y)
    else:
        rect.topleft = (x, y)
    surface.blit(render, rect)

def name_entry():
    global player_name
    player_name = ""
    current_index = 0
    alphabet = [chr(i) for i in range(65, 91)]  # A-Z
    entering = True
    selected_count = 0
    waiting_for_play = False

    while entering:
        screen.fill(BLACK)
        draw_text("Enter Your Name", font, WHITE, screen, WIDTH//2, HEIGHT//2 - 100)

        display_name = ""
        for i in range(3):
            if i < len(player_name):
                display_name += player_name[i]
            elif i == len(player_name):
                display_name += alphabet[current_index]
            else:
                display_name += "_"

        draw_text(display_name, big_font, WHITE, screen, WIDTH//2, HEIGHT//2)

        if len(player_name) == 3:
            draw_text("Press Play", font, GREEN, screen, WIDTH//2, HEIGHT//2 + 100)

        pygame.display.flip()

        while fpga_serial.in_waiting:
            cmd = fpga_serial.read().decode('utf-8', errors='ignore')
            if cmd == 'U' and len(player_name) < 3:
                current_index = (current_index + 1) % len(alphabet)
            elif cmd == 'D' and len(player_name) < 3:
                current_index = (current_index - 1) % len(alphabet)
            elif cmd == 'S':
                if len(player_name) < 3:
                    player_name += alphabet[current_index]
                    current_index = 0  # Reset for next slot
                elif len(player_name) == 3:
                    entering = False  # Final 'S' starts the game

        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                pygame.quit()
                sys.exit()

def show_scoreboard():
    screen.fill(BLACK)
    draw_text("SCOREBOARD", big_font, WHITE, screen, WIDTH//2, 80)
    top_scores = sorted(scoreboard, key=lambda x: x[1], reverse=True)[:10]
    for i, entry in enumerate(top_scores):
        draw_text(f"{entry[0]}  {entry[1]}", font, WHITE, screen, WIDTH//2, 160 + i * 40)
    draw_text("Press Start to play again", font, WHITE, screen, WIDTH//2, HEIGHT - 60)
    pygame.display.flip()

    waiting = True
    while waiting:
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                pygame.quit()
                sys.exit()
            if event.type == pygame.KEYDOWN and event.key == pygame.K_SPACE:
                waiting = False

        while fpga_serial.in_waiting:
            cmd = fpga_serial.read().decode('utf-8', errors='ignore')
            if cmd == 'S':
                waiting = False

score = 0
level = 1
max_levels = 5
bricks = create_bricks(3, 10)
ball_moving = False
game_active = False
shake_timer = 0

name_entry()
reset_game = lambda: (
    paddle.__setattr__('width', 120),
    paddle.__setattr__('x', WIDTH // 2 - 60),
    ball.__setattr__('x', WIDTH // 2 - 10),
    ball.__setattr__('y', HEIGHT // 2),
    ball_speed.__setitem__(0, 4 * random.choice([-1, 1])),
    ball_speed.__setitem__(1, -4),
    bricks.clear(),
    bricks.extend(create_bricks(3 + level - 1, 10)),
    multi_balls.clear(),
    powerups.clear(),
    globals().__setitem__('ball_moving', False),
    globals().__setitem__('game_active', True),
    globals().__setitem__('reverse_controls', False)
)

reset_game()
paddle_direction = 0  # -1 = left, 1 = right

while True:
    clock.tick(FPS)
    screen.fill((30, 30, 30))
    shake_offset = (random.randint(-5, 5), random.randint(-5, 5)) if shake_timer > 0 else (0, 0)
    if shake_timer > 0:
        shake_timer -= 1

    while fpga_serial.in_waiting:
        cmd = fpga_serial.read().decode('utf-8', errors='ignore')
        if cmd == 'L':
            paddle_direction = -1
        elif cmd == 'R':
            paddle_direction = 1
        elif cmd == 'S':
            ball_moving = True

    if paddle_direction == -1:
        paddle.x -= 7
    elif paddle_direction == 1:
        paddle.x += 7
    paddle.x = max(0, min(WIDTH - paddle.width, paddle.x))

    for event in pygame.event.get():
        if event.type == pygame.QUIT:
            pygame.quit()
            sys.exit()
        if event.type == pygame.KEYDOWN:
            if event.key == pygame.K_r:
                score = 0
                level = 1
                scoreboard.clear()
                name_entry()
                reset_game()

    if not game_active:
        scoreboard.append((player_name, score))
        show_scoreboard()
        score = 0
        name_entry()
        reset_game()
        continue

    if ball_moving:
        ball.x += ball_speed[0]
        ball.y += ball_speed[1]
    for mb in multi_balls:
        mb[0].x += mb[1][0]
        mb[0].y += mb[1][1]

    to_remove = []
    for b, speed in [(ball, ball_speed)] + multi_balls:
        if b.left <= 0 or b.right >= WIDTH:
            speed[0] *= -1
            beep()
        if b.top <= 0:
            speed[1] *= -1
            beep()
        if b.bottom >= HEIGHT:
            to_remove.append((b, speed))
        if b.colliderect(paddle):
            speed[1] *= -1
            beep()

    for b, speed in to_remove:
        if b is ball:
            game_active = False
        else:
            if [b, speed] in multi_balls:
                multi_balls.remove([b, speed])
    if len(multi_balls) == 0 and ball.y > HEIGHT:
        game_active = False

    for b, speed in [(ball, ball_speed)] + multi_balls:
        for i, (brick, color, btype, alpha) in enumerate(bricks):
            if b.colliderect(brick):
                del bricks[i]
                speed[1] *= -1
                beep()
                score += 10
                if random.random() < 0.3:
                    kind = random.choice(list(POWER_TYPES.keys()))
                    powerups.append([pygame.Rect(brick.x, brick.y, 20, 20), kind, POWER_TYPES[kind]])
                if btype == 'enemy':
                    shake_timer = SHAKE_DURATION
                break

    for p in powerups[:]:
        p[0].y += 3
        if p[0].colliderect(paddle):
            kind = p[1]
            if kind == 'expand':
                paddle.width += 30
            elif kind == 'shrink':
                paddle.width = max(60, paddle.width - 30)
            elif kind == 'multi':
                multi_balls.append([ball.copy(), [ball_speed[0], -ball_speed[1]]])
            elif kind == 'reverse':
                reverse_controls = True
            beep()
            powerups.remove(p)

    pygame.draw.rect(screen, WHITE, paddle.move(shake_offset))
    pygame.draw.ellipse(screen, WHITE, ball.move(shake_offset))
    for mb in multi_balls:
        pygame.draw.ellipse(screen, (0, 255, 255), mb[0].move(shake_offset))
    for brick, color, _, alpha in bricks:
        surf = pygame.Surface((brick.width, brick.height), pygame.SRCALPHA)
        surf.fill((*color, alpha))
        screen.blit(surf, brick.topleft)
    for p in powerups:
        pygame.draw.rect(screen, p[2], p[0].move(shake_offset))

    draw_text(f"Score: {score}", font, WHITE, screen, 20, 20, center=False)
    draw_text(f"Balls: {1 + len(multi_balls)}", font, WHITE, screen, 20, 60, center=False)
    draw_text(f"Level: {level}", font, WHITE, screen, WIDTH - 150, 20, center=False)

    if not bricks:
        pygame.display.flip()
        pygame.time.delay(1500)
        level += 1
        if level > max_levels:
            game_active = False
        else:
            reset_game()

    pygame.display.flip()

