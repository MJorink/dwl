#define COLOR(hex)    { ((hex >> 24) & 0xFF) / 255.0f, \
                        ((hex >> 16) & 0xFF) / 255.0f, \
                        ((hex >> 8) & 0xFF) / 255.0f, \
                        (hex & 0xFF) / 255.0f }
/* appearance */
static const int sloppyfocus               = 1;  /* focus follows mouse */
static const int bypass_surface_visibility = 0;  /* 1 means idle inhibitors will disable idle tracking even if it's surface isn't visible  */
static const unsigned int borderpx         = 2;  /* border pixel of windows */
static const unsigned int snap             = 32; /* snap pixel */
static const int gappih                    = 5;  /* horizontal inner gap */
static const int gappiv                    = 5;  /* vertical inner gap */
static const int gappoh                    = 10; /* horizontal outer gap */
static const int gappov                    = 10; /* vertical outer gap */
static const float rootcolor[]             = COLOR(0x282828ff);
static const float bordercolor[]           = COLOR(0x665c54ff);
static const float focuscolor[]            = COLOR(0xd65d0eff);
static const float maximizecolor[]         = COLOR(0x98971aff);
static const float urgentcolor[]           = COLOR(0xcc241dff);
/* This conforms to the xdg-protocol. Set the alpha to zero to restore the old behavior */
static const float fullscreen_bg[]         = {0.0f, 0.0f, 0.0f, 1.0f}; /* You can also use glsl colors */

/* cursor */
static const char *cursor_theme            = "Bibata-Modern-Ice";
static const unsigned int cursor_size      = 16;

/* tagging - TAGCOUNT must be no greater than 31 */
#define TAGCOUNT (9)

/* logging */
static int log_level = WLR_ERROR;

static const Rule rules[] = {
	/* app_id             title       tags mask     isfloating   monitor */
	{ "update",          NULL,       0,            1,           -1 },
};

/* monitors */
static const MonitorRule monrules[] = {
	/* name        scale rotate/reflect                x    y     width height refresh */
	{ "HDMI-A-1",  1,    WL_OUTPUT_TRANSFORM_NORMAL,   0,   1080, 2560, 1440,  144 },
	{ "eDP-1",     1,    WL_OUTPUT_TRANSFORM_NORMAL,   0,   0,    1920, 1080,  60 },
	{ NULL,        1,    WL_OUTPUT_TRANSFORM_NORMAL,   -1,  -1,   0,    0,     0 },
	/* default monitor rule: can be changed but cannot be eliminated; at least one monitor rule must exist */
};

/* keyboard */
static const struct xkb_rule_names xkb_rules = {
	.layout = "us",
	.variant = "intl",
};

static const int repeat_rate = 35;
static const int repeat_delay = 200;

/* Trackpad */
static const int tap_to_click = 0;
static const int tap_and_drag = 0;
static const int drag_lock = 0;
static const int natural_scrolling = 0;
static const int disable_while_typing = 1;
static const int left_handed = 0;
static const int middle_button_emulation = 0;
static const enum libinput_config_scroll_method scroll_method = LIBINPUT_CONFIG_SCROLL_2FG;
static const enum libinput_config_click_method click_method = LIBINPUT_CONFIG_CLICK_METHOD_BUTTON_AREAS;
static const uint32_t send_events_mode = LIBINPUT_CONFIG_SEND_EVENTS_ENABLED;
static const enum libinput_config_tap_button_map button_map = LIBINPUT_CONFIG_TAP_MAP_LRM;

/* Pointer acceleration: accel_speed for mice, trackpad_accel_speed for touchpads */
static const enum libinput_config_accel_profile accel_profile = LIBINPUT_CONFIG_ACCEL_PROFILE_FLAT;
static const double accel_speed = -0.5;
static const double trackpad_accel_speed = 0.75;

#define MODKEY WLR_MODIFIER_LOGO
#define SHIFT  WLR_MODIFIER_SHIFT
#define CTRL   WLR_MODIFIER_CTRL

#define TAGKEYS(KEY,TAG) \
	{ MODKEY,       KEY, view, {.ui = 1 << TAG} }, \
	{ MODKEY|SHIFT, KEY, tag,  {.ui = 1 << TAG} }

/* helper for spawning shell commands in the pre dwm-5.0 fashion */
#define SHCMD(cmd) { .v = (const char*[]){ "/bin/sh", "-c", cmd, NULL } }
#define CMD(...)   { .v = (const char*[]){ __VA_ARGS__, NULL } }

static const Key keys[] = {
	/* modifier       key                          function          argument */
	/* Spawn */
	{ MODKEY,         XKB_KEY_Return,              spawn,            CMD("foot") },
	{ MODKEY,         XKB_KEY_e,                   spawn,            CMD("foot", "yazi") },
	{ MODKEY,         XKB_KEY_m,                   spawn,            CMD("spotify") },
	{ MODKEY,         XKB_KEY_u,                   spawn,            CMD("foot", "--hold", "--app-id", "update", "doas", "apk", "upgrade", "-U") },
	{ MODKEY,         XKB_KEY_b,                   spawn,            CMD("librewolf") },

	/* Shell: dwl-cmd lives in scripts/dwl-cmd */
	{ 0,              XKB_KEY_XF86AudioRaiseVolume, spawn,           CMD("dwl-cmd", "vol-up") },
	{ 0,              XKB_KEY_XF86AudioLowerVolume, spawn,           CMD("dwl-cmd", "vol-down") },
	{ 0,              XKB_KEY_XF86AudioMute,       spawn,            CMD("dwl-cmd", "mute") },
	{ 0,              XKB_KEY_XF86AudioMicMute,    spawn,            CMD("dwl-cmd", "mic-mute") },
	{ 0,              XKB_KEY_XF86MonBrightnessUp, spawn,            CMD("dwl-cmd", "bri-up") },
	{ 0,              XKB_KEY_XF86MonBrightnessDown, spawn,          CMD("dwl-cmd", "bri-down") },
	{ MODKEY,         XKB_KEY_space,               spawn,            CMD("fuzzel") },
	{ MODKEY,         XKB_KEY_s,                   spawn,            CMD("dwl-cmd", "control") },
	{ MODKEY|SHIFT,   XKB_KEY_s,                   spawn,            CMD("dwl-cmd", "screenshot") },
	{ MODKEY|SHIFT,   XKB_KEY_p,                   spawn,            CMD("swaylock") },
	{ MODKEY,         XKB_KEY_p,                   spawn,            CMD("dwl-cmd", "session") },
	{ MODKEY,         XKB_KEY_v,                   spawn,            CMD("dwl-cmd", "clipboard") },

	/* Common binds */
	{ MODKEY,         XKB_KEY_q,                   killclient,       {0} },
	{ MODKEY|SHIFT,   XKB_KEY_m,                   quit,             {0} },
	{ MODKEY,         XKB_KEY_i,                   minimize,         {0} },
	{ MODKEY|SHIFT,   XKB_KEY_i,                   restoreminimized, {0} },
	{ MODKEY,         XKB_KEY_backslash,           togglefloating,   {0} },
	{ MODKEY,         XKB_KEY_f,                   togglemaximize,   {0} },
	{ MODKEY|SHIFT,   XKB_KEY_f,                   togglefullscreen, {0} },

	/* Move/Resize */
	{ MODKEY|CTRL,    XKB_KEY_h,                   resizewin,        {.v = (const int[]){ -50, 0 }} },
	{ MODKEY|CTRL,    XKB_KEY_l,                   resizewin,        {.v = (const int[]){ +50, 0 }} },
	{ MODKEY|CTRL,    XKB_KEY_k,                   resizewin,        {.v = (const int[]){ 0, -50 }} },
	{ MODKEY|CTRL,    XKB_KEY_j,                   resizewin,        {.v = (const int[]){ 0, +50 }} },
	{ MODKEY|SHIFT,   XKB_KEY_k,                   tagmon,           {.i = WLR_DIRECTION_UP} },
	{ MODKEY|SHIFT,   XKB_KEY_j,                   tagmon,           {.i = WLR_DIRECTION_DOWN} },
	{ MODKEY|SHIFT,   XKB_KEY_h,                   exchangeclient,   {.i = WLR_DIRECTION_LEFT} },
	{ MODKEY|SHIFT,   XKB_KEY_l,                   exchangeclient,   {.i = WLR_DIRECTION_RIGHT} },

	/* Focus */
	{ WLR_MODIFIER_ALT, XKB_KEY_Tab,               focusstack,       {.i = +1} },
	{ MODKEY,         XKB_KEY_h,                   focusdir,         {.i = WLR_DIRECTION_LEFT} },
	{ MODKEY,         XKB_KEY_l,                   focusdir,         {.i = WLR_DIRECTION_RIGHT} },
	{ MODKEY,         XKB_KEY_k,                   focusdir,         {.i = WLR_DIRECTION_UP} },
	{ MODKEY,         XKB_KEY_j,                   focusdir,         {.i = WLR_DIRECTION_DOWN} },

	/* Tags */
	TAGKEYS(XKB_KEY_1, 0),
	TAGKEYS(XKB_KEY_2, 1),
	TAGKEYS(XKB_KEY_3, 2),
	TAGKEYS(XKB_KEY_4, 3),
	TAGKEYS(XKB_KEY_5, 4),
	TAGKEYS(XKB_KEY_6, 5),
	TAGKEYS(XKB_KEY_7, 6),
	TAGKEYS(XKB_KEY_8, 7),
	TAGKEYS(XKB_KEY_9, 8),

	/* Ctrl-Alt-Fx is used to switch to another VT, if you don't know what a VT is
	 * do not remove them.
	 */
#define CHVT(n) { WLR_MODIFIER_CTRL|WLR_MODIFIER_ALT,XKB_KEY_F##n, chvt, {.ui = (n)} }
	CHVT(1), CHVT(2), CHVT(3), CHVT(4), CHVT(5), CHVT(6),
	CHVT(7), CHVT(8), CHVT(9), CHVT(10), CHVT(11), CHVT(12),
};

static const Button buttons[] = {
	{ MODKEY, BTN_LEFT,   moveresize,     {.ui = CurMove} },
	{ MODKEY, BTN_RIGHT,  moveresize,     {.ui = CurResize} },
};
