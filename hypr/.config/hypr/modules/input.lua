-- Keyboard layouts (ALT + SHIFT switches US / GR), mouse and touchpad.

hl.config({
    input = {
        kb_layout  = "us,gr",
        kb_variant = "",
        kb_model   = "",
        kb_options = "grp:alt_shift_toggle",
        kb_rules   = "",

        follow_mouse = 1,
        sensitivity  = 0,
        scroll_factor = 1.0,

        touchpad = {
            natural_scroll = true,
        },
    },
})
