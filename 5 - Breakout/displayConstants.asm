# Display Hardware Constants
# ------------------------
# Constants for display dimensions, control flags, and input handling

# ------------------------
# Display Dimensions
# ------------------------
    # DO NOT FORMAT START
    .eqv DISPLAY_W        128 # Display width in pixels
    .eqv DISPLAY_H        128 # Display height in pixels
    .eqv DISPLAY_W_SHIFT    7 # Bit shift for display width (2^7 = 128)
    # DO NOT FORMAT END

# ------------------------
# Display Control Modes
# ------------------------
    # DO NOT FORMAT START
    .eqv DISPLAY_MODE_MS_SHIFT  16    # Bit shift for mode settings
    .eqv DISPLAY_MODE_ENHANCED  0x100 # Enhanced display mode flag
    .eqv DISPLAY_MODE_FB_ENABLE 1     # Framebuffer enable flag
    .eqv DISPLAY_MODE_TM_ENABLE 2     # Tilemap enable flag
    # DO NOT FORMAT END

# ------------------------
# Tile Dimensions
# ------------------------
    # DO NOT FORMAT START
    .eqv TILE_W            8 # Tile width in pixels
    .eqv TILE_H            8 # Tile height in pixels
    .eqv BYTES_PER_TILE   64 # Bytes per tile (8 * 8)
    # DO NOT FORMAT END

# ------------------------
# Tilemap Configuration
# ------------------------
    # DO NOT FORMAT START
    .eqv TM_ENTRY_SIZE     2   # Bytes per tilemap entry
    .eqv N_TM_COLUMNS     32   # Number of tilemap columns
    .eqv N_TM_ROWS        32   # Number of tilemap rows
    .eqv N_TM_TILES       1024 # Total tilemap tiles (32 * 32)
    .eqv BYTES_PER_TM_ROW 64   # Bytes per tilemap row (2 * 32)
    # DO NOT FORMAT END

# ------------------------
# Sprite Configuration
# ------------------------
    # DO NOT FORMAT START
    .eqv SPRITE_ENTRY_SIZE   4 # Bytes per sprite entry
    .eqv N_SPRITES         256 # Maximum number of sprites
    # DO NOT FORMAT END

# ------------------------
# Mouse Button Constants
# ------------------------
    # DO NOT FORMAT START
    .eqv MOUSE_LBUTTON    1 # Left mouse button
    .eqv MOUSE_RBUTTON    2 # Right mouse button
    .eqv MOUSE_MBUTTON    4 # Middle mouse button
    # DO NOT FORMAT END

# ------------------------
# Display Attribute Flags
# ------------------------
    # DO NOT FORMAT START
    .eqv BIT_PRIORITY 1 # Priority bit flag
    .eqv BIT_ENABLE   1 # Enable bit flag
    .eqv BIT_VFLIP    2 # Vertical flip bit flag
    .eqv BIT_HFLIP    4 # Horizontal flip bit flag
    .eqv BIT_SIZE     8 # Size bit flag
    # DO NOT FORMAT END

# ------------------------
# Default Palette Color Indexes
# ------------------------
    # DO NOT FORMAT START
    .eqv COLOR_BLACK       64 # Black color index
    .eqv COLOR_RED         65 # Red color index
    .eqv COLOR_ORANGE      66 # Orange color index
    .eqv COLOR_YELLOW      67 # Yellow color index
    .eqv COLOR_GREEN       68 # Green color index
    .eqv COLOR_BLUE        69 # Blue color index
    .eqv COLOR_MAGENTA     70 # Magenta color index
    .eqv COLOR_WHITE       71 # White color index
    .eqv COLOR_DARK_GREY   72 # Dark grey color index
    .eqv COLOR_DARK_GRAY   72 # Dark gray color index (alias)
    .eqv COLOR_BRICK       73 # Brick color index
    .eqv COLOR_BROWN       74 # Brown color index
    .eqv COLOR_TAN         75 # Tan color index
    .eqv COLOR_DARK_GREEN  76 # Dark green color index
    .eqv COLOR_DARK_BLUE   77 # Dark blue color index
    .eqv COLOR_PURPLE      78 # Purple color index
    .eqv COLOR_LIGHT_GREY  79 # Light grey color index
    .eqv COLOR_LIGHT_GRAY  79 # Light gray color index (alias)
    # DO NOT FORMAT END

# ------------------------
# Keyboard Key Constants
# ------------------------
# Note: Values correspond to Java KeyEvent.VK_* constants

    # DO NOT FORMAT START
    # Numeric Keys
    .eqv KEY_0                         48 # Key: 0
    .eqv KEY_1                         49 # Key: 1
    .eqv KEY_2                         50 # Key: 2
    .eqv KEY_3                         51 # Key: 3
    .eqv KEY_4                         52 # Key: 4
    .eqv KEY_5                         53 # Key: 5
    .eqv KEY_6                         54 # Key: 6
    .eqv KEY_7                         55 # Key: 7
    .eqv KEY_8                         56 # Key: 8
    .eqv KEY_9                         57 # Key: 9

    # Alphabetic Keys
    .eqv KEY_A                         65 # Key: A
    .eqv KEY_B                         66 # Key: B
    .eqv KEY_C                         67 # Key: C
    .eqv KEY_D                         68 # Key: D
    .eqv KEY_E                         69 # Key: E
    .eqv KEY_F                         70 # Key: F
    .eqv KEY_G                         71 # Key: G
    .eqv KEY_H                         72 # Key: H
    .eqv KEY_I                         73 # Key: I
    .eqv KEY_J                         74 # Key: J
    .eqv KEY_K                         75 # Key: K
    .eqv KEY_L                         76 # Key: L
    .eqv KEY_M                         77 # Key: M
    .eqv KEY_N                         78 # Key: N
    .eqv KEY_O                         79 # Key: O
    .eqv KEY_P                         80 # Key: P
    .eqv KEY_Q                         81 # Key: Q
    .eqv KEY_R                         82 # Key: R
    .eqv KEY_S                         83 # Key: S
    .eqv KEY_T                         84 # Key: T
    .eqv KEY_U                         85 # Key: U
    .eqv KEY_V                         86 # Key: V
    .eqv KEY_W                         87 # Key: W
    .eqv KEY_X                         88 # Key: X
    .eqv KEY_Y                         89 # Key: Y
    .eqv KEY_Z                         90 # Key: Z

    # Function Keys
    .eqv KEY_F1                        112   # Key: F1
    .eqv KEY_F2                        113   # Key: F2
    .eqv KEY_F3                        114   # Key: F3
    .eqv KEY_F4                        115   # Key: F4
    .eqv KEY_F5                        116   # Key: F5
    .eqv KEY_F6                        117   # Key: F6
    .eqv KEY_F7                        118   # Key: F7
    .eqv KEY_F8                        119   # Key: F8
    .eqv KEY_F9                        120   # Key: F9
    .eqv KEY_F10                       121   # Key: F10
    .eqv KEY_F11                       122   # Key: F11
    .eqv KEY_F12                       123   # Key: F12
    .eqv KEY_F13                       61440 # Key: F13
    .eqv KEY_F14                       61441 # Key: F14
    .eqv KEY_F15                       61442 # Key: F15
    .eqv KEY_F16                       61443 # Key: F16
    .eqv KEY_F17                       61444 # Key: F17
    .eqv KEY_F18                       61445 # Key: F18
    .eqv KEY_F19                       61446 # Key: F19
    .eqv KEY_F20                       61447 # Key: F20
    .eqv KEY_F21                       61448 # Key: F21
    .eqv KEY_F22                       61449 # Key: F22
    .eqv KEY_F23                       61450 # Key: F23
    .eqv KEY_F24                       61451 # Key: F24

    # Navigation Keys
    .eqv KEY_UP                        38 # Key: Up Arrow
    .eqv KEY_DOWN                      40 # Key: Down Arrow
    .eqv KEY_LEFT                      37 # Key: Left Arrow
    .eqv KEY_RIGHT                     39 # Key: Right Arrow
    .eqv KEY_HOME                      36 # Key: Home
    .eqv KEY_END                       35 # Key: End
    .eqv KEY_PAGE_UP                   33 # Key: Page Up
    .eqv KEY_PAGE_DOWN                 34 # Key: Page Down

    # Keypad Navigation
    .eqv KEY_KP_UP                     224 # Key: Keypad Up
    .eqv KEY_KP_DOWN                   225 # Key: Keypad Down
    .eqv KEY_KP_LEFT                   226 # Key: Keypad Left
    .eqv KEY_KP_RIGHT                  227 # Key: Keypad Right

    # Numpad Keys
    .eqv KEY_NUMPAD0                   96  # Key: Numpad 0
    .eqv KEY_NUMPAD1                   97  # Key: Numpad 1
    .eqv KEY_NUMPAD2                   98  # Key: Numpad 2
    .eqv KEY_NUMPAD3                   99  # Key: Numpad 3
    .eqv KEY_NUMPAD4                   100 # Key: Numpad 4
    .eqv KEY_NUMPAD5                   101 # Key: Numpad 5
    .eqv KEY_NUMPAD6                   102 # Key: Numpad 6
    .eqv KEY_NUMPAD7                   103 # Key: Numpad 7
    .eqv KEY_NUMPAD8                   104 # Key: Numpad 8
    .eqv KEY_NUMPAD9                   105 # Key: Numpad 9

    # Numpad Operators
    .eqv KEY_ADD                       107 # Key: Numpad +
    .eqv KEY_SUBTRACT                  109 # Key: Numpad -
    .eqv KEY_MULTIPLY                  106 # Key: Numpad *
    .eqv KEY_DIVIDE                    111 # Key: Numpad /
    .eqv KEY_DECIMAL                   110 # Key: Numpad .
    .eqv KEY_SEPARATOR                 108 # Key: Numpad Separator
    .eqv KEY_SEPARATER                 108 # Key: Numpad Separator (alternate spelling)

    # Control Keys
    .eqv KEY_ENTER                     10  # Key: Enter
    .eqv KEY_BACK_SPACE                8   # Key: Backspace
    .eqv KEY_TAB                       9   # Key: Tab
    .eqv KEY_CANCEL                    3   # Key: Cancel
    .eqv KEY_CLEAR                     12  # Key: Clear
    .eqv KEY_SHIFT                     16  # Key: Shift
    .eqv KEY_CONTROL                   17  # Key: Control
    .eqv KEY_ALT                       18  # Key: Alt
    .eqv KEY_PAUSE                     19  # Key: Pause
    .eqv KEY_CAPS_LOCK                 20  # Key: Caps Lock
    .eqv KEY_ESCAPE                    27  # Key: Escape
    .eqv KEY_SPACE                     32  # Key: Space
    .eqv KEY_DELETE                    127 # Key: Delete
    .eqv KEY_INSERT                    155 # Key: Insert
    .eqv KEY_NUM_LOCK                  144 # Key: Num Lock
    .eqv KEY_SCROLL_LOCK               145 # Key: Scroll Lock
    .eqv KEY_PRINTSCREEN               154 # Key: Print Screen
    .eqv KEY_HELP                      156 # Key: Help
    .eqv KEY_META                      157 # Key: Meta
    .eqv KEY_CONTEXT_MENU              525 # Key: Context Menu
    .eqv KEY_WINDOWS                   524 # Key: Windows

    # Punctuation Keys
    .eqv KEY_COMMA                     44  # Key: ,
    .eqv KEY_MINUS                     45  # Key: -
    .eqv KEY_PERIOD                    46  # Key: .
    .eqv KEY_SLASH                     47  # Key: /
    .eqv KEY_SEMICOLON                 59  # Key: ;
    .eqv KEY_EQUALS                    61  # Key: =
    .eqv KEY_OPEN_BRACKET              91  # Key: [
    .eqv KEY_BACK_SLASH                92  # Key: \
    .eqv KEY_CLOSE_BRACKET             93  # Key: ]
    .eqv KEY_BACK_QUOTE                192 # Key: `
    .eqv KEY_QUOTE                     222 # Key: '

    # Extended Punctuation
    .eqv KEY_AMPERSAND                 150 # Key: &
    .eqv KEY_ASTERISK                  151 # Key: *
    .eqv KEY_QUOTEDBL                  152 # Key: "
    .eqv KEY_LESS                      153 # Key: <
    .eqv KEY_GREATER                   160 # Key: >
    .eqv KEY_BRACELEFT                 161 # Key: {
    .eqv KEY_BRACERIGHT                162 # Key: }
    .eqv KEY_AT                        512 # Key: @
    .eqv KEY_COLON                     513 # Key: :
    .eqv KEY_CIRCUMFLEX                514 # Key: ^
    .eqv KEY_DOLLAR                    515 # Key: $
    .eqv KEY_EURO_SIGN                 516 # Key: €
    .eqv KEY_EXCLAMATION_MARK          517 # Key: !
    .eqv KEY_INVERTED_EXCLAMATION_MARK 518 # Key: ¡
    .eqv KEY_LEFT_PARENTHESIS          519 # Key: (
    .eqv KEY_NUMBER_SIGN               520 # Key: #
    .eqv KEY_PLUS                      521 # Key: +
    .eqv KEY_RIGHT_PARENTHESIS         522 # Key: )
    .eqv KEY_UNDERSCORE                523 # Key: _

    # Editing Keys
    .eqv KEY_COPY                      65485 # Key: Copy
    .eqv KEY_CUT                       65489 # Key: Cut
    .eqv KEY_PASTE                     65487 # Key: Paste
    .eqv KEY_UNDO                      65483 # Key: Undo
    .eqv KEY_AGAIN                     65481 # Key: Again
    .eqv KEY_FIND                      65488 # Key: Find
    .eqv KEY_PROPS                     65482 # Key: Props
    .eqv KEY_STOP                      65480 # Key: Stop

    # International Keys
    .eqv KEY_ACCEPT                    30  # Key: Accept
    .eqv KEY_MODECHANGE                31  # Key: Mode Change
    .eqv KEY_KANA                      21  # Key: Kana
    .eqv KEY_FINAL                     24  # Key: Final
    .eqv KEY_KANJI                     25  # Key: Kanji
    .eqv KEY_CONVERT                   28  # Key: Convert
    .eqv KEY_NONCONVERT                29  # Key: Non-Convert
    .eqv KEY_ALPHANUMERIC              240 # Key: Alphanumeric
    .eqv KEY_KATAKANA                  241 # Key: Katakana
    .eqv KEY_HIRAGANA                  242 # Key: Hiragana
    .eqv KEY_FULL_WIDTH                243 # Key: Full Width
    .eqv KEY_HALF_WIDTH                244 # Key: Half Width
    .eqv KEY_ROMAN_CHARACTERS          245 # Key: Roman Characters
    .eqv KEY_ALL_CANDIDATES            256 # Key: All Candidates
    .eqv KEY_PREVIOUS_CANDIDATE        257 # Key: Previous Candidate
    .eqv KEY_CODE_INPUT                258 # Key: Code Input
    .eqv KEY_JAPANESE_KATAKANA         259 # Key: Japanese Katakana
    .eqv KEY_JAPANESE_HIRAGANA         260 # Key: Japanese Hiragana
    .eqv KEY_JAPANESE_ROMAN            261 # Key: Japanese Roman
    .eqv KEY_KANA_LOCK                 262 # Key: Kana Lock
    .eqv KEY_INPUT_METHOD_ON_OFF       263 # Key: Input Method On/Off

    # Compose and Special Keys
    .eqv KEY_COMPOSE                   65312 # Key: Compose
    .eqv KEY_ALT_GRAPH                 65406 # Key: Alt Graph
    .eqv KEY_BEGIN                     65368 # Key: Begin

    # Dead Keys (combining characters)
    .eqv KEY_DEAD_GRAVE                128 # Dead key: Grave accent
    .eqv KEY_DEAD_ACUTE                129 # Dead key: Acute accent
    .eqv KEY_DEAD_CIRCUMFLEX           130 # Dead key: Circumflex
    .eqv KEY_DEAD_TILDE                131 # Dead key: Tilde
    .eqv KEY_DEAD_MACRON               132 # Dead key: Macron
    .eqv KEY_DEAD_BREVE                133 # Dead key: Breve
    .eqv KEY_DEAD_ABOVEDOT             134 # Dead key: Dot above
    .eqv KEY_DEAD_DIAERESIS            135 # Dead key: Diaeresis
    .eqv KEY_DEAD_ABOVERING            136 # Dead key: Ring above
    .eqv KEY_DEAD_DOUBLEACUTE          137 # Dead key: Double acute
    .eqv KEY_DEAD_CARON                138 # Dead key: Caron
    .eqv KEY_DEAD_CEDILLA              139 # Dead key: Cedilla
    .eqv KEY_DEAD_OGONEK               140 # Dead key: Ogonek
    .eqv KEY_DEAD_IOTA                 141 # Dead key: Iota
    .eqv KEY_DEAD_VOICED_SOUND         142 # Dead key: Voiced sound
    .eqv KEY_DEAD_SEMIVOICED_SOUND     143 # Dead key: Semivoiced sound

    # Special Constants
    .eqv KEY_UNDEFINED                 0 # Key: Undefined
    # DO NOT FORMAT END
